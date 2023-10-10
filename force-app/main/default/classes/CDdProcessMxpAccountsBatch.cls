/**
 * CDdProcessMxpAccountsBatch
 *
 * @author     Sahil (sahil.chaudhry@doordash.com)
 * @date       2022-03-08
 * @decription process MXP staging records in batches
 */
global class CDdProcessMxpAccountsBatch implements Database.Batchable<SObject> {
    /*****************************************************************************************************************************
    *
    * Constants & Private Variables
    *
    *****************************************************************************************************************************/
    private static Map<Id,Load_Request_Item__c> stagingRecToUpdate = new Map<Id,Load_Request_Item__c>();
    private static List<AccountTeamMember> atmToInsert = new List<AccountTeamMember>();
    /*****************************************************************************************************************************
    *
    * Constructors
    *
    *****************************************************************************************************************************/
     /**
     * @author      Sahil Chaudhry
     * @date        03/2022
     * @decription  default constructor
     * @param
     * @return
    */
    global CDdProcessMxpAccountsBatch() {
        //check if there is already a batch with this name in progress and throw error
        List<String> batchStatusList = new List<String>();
        batchStatusList.add(CDdCoreConstants.BATCH_HOLDING);
        batchStatusList.add(CDdCoreConstants.BATCH_QUEUED);
        batchStatusList.add(CDdCoreConstants.BATCH_PREPARING);
        batchStatusList.add(CDdCoreConstants.BATCH_PROCESSING);

        Id apexClassId = [SELECT Id FROM ApexClass WHERE Name = 'CDdProcessMxpAccountsBatch' LIMIT 1].id;
        List<AsyncApexJob> batchJobList = [SELECT Id FROM AsyncApexJob
                                            WHERE ApexClassId =:apexClassId
                                            AND JobType = 'BatchApex'
                                            AND Status IN :batchStatusList];
        if (!batchJobList.isEmpty()) {
            throw new CDdProcessMxpAccountsBatchException(CDdNameValuePairHelper.getTextValue(CDdNameValuePairConstants.ERROR_PBATCH_UNFINISHED));
        }
    }

    /*****************************************************************************************************************************
    *
    * Public Methods
    *
    *****************************************************************************************************************************/
     /**
     * @author      Sahil Chaudhry
     * @date        03/2022
     * @decription  start method to collect records from database
     * @param       batchable context
     * @return      query locator
    */
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT Id,Account_ID__c,Status__c,Error__c,
                                            User_ID__c,Exception_Details__c
                                            FROM Load_Request_Item__c
                                            WHERE Status__c = 'New'
                                            AND Operation__c =: CDdSupportConstants.OPERATION_MXP_MAPPING]);
    }

     /**
     * @author      Sahil Chaudhry
     * @date        03/2022
     * @decription  create,update,delete Account team members. Also update parent accounts.
     * @param       batchable context, list of staging object records
     * @return
    */
    global void execute(Database.BatchableContext info, List<Load_Request_Item__c> mxpLRIList) {
        try {
            Boolean hasError = false;
            Set<Id> accIdStagingSet = new Set<Id>();
            Set<Id> userIdStagingSet = new Set<Id>();
            Map<Id,String> accIdToOperation = new Map<Id,String>();
            Map<Id,Account> accToUpdate = new Map<Id,Account>();
            List<AccountTeamMember> atmToDelete = new List<AccountTeamMember>();
            List<Load_Request_Item__c> LRIToInsert = new List<Load_Request_Item__c>();
            Map<Id,Load_Request_Item__c> accIdToStagingMap = new Map<Id,Load_Request_Item__c>();
            Map<Id,String> accIdToErrorMesg = new Map<Id,String>();

            //collect account & user ids from staging payload
            for (Load_Request_Item__c lRIVar : mxpLRIList) {
                Id accIdStaging = CDdUtilities.returnValidId(lRIVar.Account_ID__c);
                Id userIdStaging = CDdUtilities.returnValidId(lRIVar.User_ID__c);
                if (accIdStaging != null) {
                    accIdStagingSet.add(accIdStaging);
                }
                if (userIdStaging != null) {
                    userIdStagingSet.add(userIdStaging);
                }
            }
            //query database to get accounts and their team members
            Map<Id,Account> accDBMap = getAccountFromDB(accIdStagingSet);
            //query user table to check if they match with staging user ids
            Map<Id,User> userDBMap = getUserFromDB(userIdStagingSet);

            for (Load_Request_Item__c lRIVar : mxpLRIList) {
                Id accIdStaging = CDdUtilities.returnValidId(lRIVar.Account_ID__c);
                Id userIdStaging = CDdUtilities.returnValidId(lRIVar.User_ID__c);
                //if database doesnt have userid then add error and continue
                if (String.isNotBlank(lRIVar.User_ID__c) && !userDBMap.containsKey(userIdStaging)) {
                    //no corresponding user found in DB, so stamp an error on the staging record
                    addErrorToStagingRecord(lRIVar, CDdNameValuePairHelper.getTextValue(CDdNameValuePairConstants.ERROR_USER_DOESNT_EXIST));
                    continue;
                }
                if (!accDBMap.isEmpty() && accDBMap.containsKey(accIdStaging)) {
                    //checking if any team members already exist for the account or not
                    //if not, then add ONE account team member using staging record
                    //if yes, then compare the ONE existing team member between staging & database
                    //then update team members in database using staging data
                    List<AccountTeamMember> atmDBList = accDBMap.get(accIdStaging).AccountTeamMembers;
                    /*ideally there should only be one Mxp - but if for some reason we have multiple Mxps - then we need to check
                    * the user id on the LRI against the user ids on all account team members */
                    Set<Id> currAtmUsers = new Set<Id>();
                    for(AccountTeamMember atmRec : atmDBList){
                        currAtmUsers.add(atmRec.UserId);
                    }

                    if (String.isNotBlank(lRIVar.User_ID__c)) {
                        if (atmDBList.isEmpty()) {
                            //insert ATM to DB using staging record
                            insertMXP(accIdStaging,userIdStaging);
                            if (accDBMap.get(accIdStaging).Case_Routing_Override__c != CDdSupportConstants.QUEUE_MX_SUCCESSASSOCIATE) {
                                accIdToOperation.put(accIdStaging, CDdSupportConstants.QUEUE_MX_SUCCESSASSOCIATE);
                            }
                        }  else if (atmDBList.size() > 0 && !currAtmUsers.contains(userIdStaging)) {
                            //userid does not match - candidate for update ATM based on staging data
                            //As salesforce doesn't allow userId update, collect ATMs to delete, then insert them
                            LRIToInsert.add(lRIVar);//atm to insert
                            //collect atms to delete
                            atmToDelete.addAll(atmDBList);
                            //also update flag on parent account
                            if (accDBMap.get(accIdStaging).Case_Routing_Override__c != CDdSupportConstants.QUEUE_MX_SUCCESSASSOCIATE) {
                                accIdToOperation.put(accIdStaging, CDdSupportConstants.QUEUE_MX_SUCCESSASSOCIATE);
                            }
                        } else if (atmDBList.size() > 0 &&currAtmUsers.contains(userIdStaging)) {
                            //staging and DB ATM matches for one user,  update flag on parent account and delete any atm that does not match
                            for(AccountTeamMember atmTemp : atmDBList){
                                if(atmTemp.UserId != userIdStaging){
                                    atmToDelete.add(atmTemp);
                                }
                            }
                            if (accDBMap.get(accIdStaging).Case_Routing_Override__c != CDdSupportConstants.QUEUE_MX_SUCCESSASSOCIATE) {
                                accIdToOperation.put(accIdStaging, CDdSupportConstants.QUEUE_MX_SUCCESSASSOCIATE);
                            }
                        }
                    } else {
                        //userid is blank in staging so delete the ATMs from DB
                        atmToDelete.addAll(atmDBList);
                        //clear out flag on parent account
                        accIdToOperation.put(accIdStaging, null);
                    }
                    if (lRIVar.Error__c) {
                        lRIVar.Exception_Details__c = null;
                        lRIVar.Error__c = false;
                        stagingRecToUpdate.put(lRIVar.Id,lRIVar);
                    }
                } else {
                    //set error message on staging object
                    addErrorToStagingRecord(lRIVar, CDdNameValuePairHelper.getTextValue(CDdNameValuePairConstants.ERROR_ACC_DOESNT_EXIST));
                }
            }

            //prepare list of accounts to update
            if (!accIdToOperation.isEmpty()) {
                for (Load_Request_Item__c lRIVar : mxpLRIList) {
                    Id accIdStaging = CDdUtilities.returnValidId(lRIVar.Account_ID__c);
                    if (accIdToOperation.containsKey(accIdStaging)
                        && !accToUpdate.containsKey(accIdStaging)) {
                        Account accObj = new Account();
                        accObj.Id = accIdStaging;
                        accObj.Case_Routing_Override__c = accIdToOperation.get(accIdStaging);
                        accToUpdate.put(accIdStaging,accObj);
                    }
                }
            }

            //prepare list of account team members to insert
            for (Load_Request_Item__c lRIVar : LRIToInsert) {
                Id accIdStaging = CDdUtilities.returnValidId(lRIVar.Account_ID__c);
                Id userIdStaging = CDdUtilities.returnValidId(lRIVar.User_ID__c);
                insertMXP(accIdStaging,userIdStaging);
            }

            //delete and insert MXPs
            //if any failures in inserting/deleting MXPs, mark all staging records as error
            try {
                List<Database.DeleteResult> atmDeleteResult = Database.delete(atmToDelete, true);
                List<Database.SaveResult> atmInsertResult = Database.insert(atmToInsert, true);
            } catch (Exception e) {
                for (Load_Request_Item__c lRIVar : mxpLRIList) {
                    addErrorToStagingRecord(lRIVar, CDdErrorUtilities.getFormattedException(CDdCoreConstants.BLANK_STRING, e));
                }
                hasError = true;
            }

            //update parent accounts of team members
            if (!hasError && !accToUpdate.isEmpty()) {
                List<Database.SaveResult> accUpdateResult = Database.update(accToUpdate.values(), false);
                //loop through database results and populate accountid to error mesg map
                for (Database.SaveResult resVar : accUpdateResult) {
                    if (!resVar.isSuccess()) {
                        for (Database.Error err : resVar.getErrors()) {
                            accIdToErrorMesg.put(resVar.getId(),err.getMessage());
                        }
                    }
                }
            }

            //set error on staging records
            for (Load_Request_Item__c lRIVar : mxpLRIList) {
                Id accIdStaging = CDdUtilities.returnValidId(lRIVar.Account_ID__c);
                if (accIdToErrorMesg.containsKey(accIdStaging)) {
                    addErrorToStagingRecord(lRIVar, accIdToErrorMesg.get(accIdStaging));
                }
                /*since we wont be adding any more errors - we can set
                the status of those atm that are processed successfully to complete*/
                if(!stagingRecToUpdate.containsKey(lRIVar.Id)){
                    addSuccessToStagingRecord(lRIVar);
                }
            }

            //update staging records
            if (!stagingRecToUpdate.isEmpty()) {
                List<Database.SaveResult> lriUpdateResult = Database.update(stagingRecToUpdate.values(), false);
                List<String> errorMessages = CDdErrorUtilities.processSaveResults(lriUpdateResult);
                if (!errorMessages.isEmpty()) {
                    CDdErrorUtilities.createApexLogs(errorMessages,'CDdProcessMxpAccountsBatch','Update Staging records',LoggingLevel.ERROR);
                }
            }
        } catch (Exception e) {
            List<String> errorMessages = new List<String>();
            errorMessages.add(e.getMessage());
            CDdErrorUtilities.createApexLogs(errorMessages,'CDdProcessMxpAccountsBatch','Execute Batch',LoggingLevel.ERROR);
        }
    }

     /**
     * @author      Sahil Chaudhry
     * @date        03/2022
     * @decription  execute post processing operations
     * @param       batchable context
     * @return
    */
    global void finish(Database.BatchableContext info) {
        //check if there are any errors on staging records
        List<Load_Request_Item__c> mxpLRIList = [SELECT Id FROM Load_Request_Item__c
                                                    WHERE Error__c = TRUE
                                                    AND Operation__c =: CDdSupportConstants.OPERATION_MXP_MAPPING
                                                    LIMIT 1];

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new List<String>{UserInfo.getUserEmail()});
        mail.setSenderDisplayName('MXP Hub');
        mail.setSubject('Batch Processing Result');
        if (mxpLRIList.isEmpty()) {
            mail.setPlainTextBody('MXP Load Processed Successfully!');
        } else {
            mail.setPlainTextBody('Link to MXP Load Error Report:'
                                +CDdCoreConstants.NEW_LINE+CDdCoreConstants.DELIMITER_SPACE
                                +CDdNameValuePairHelper.getTextValue(CDdNameValuePairConstants.MXP_LOAD_REPORT_URL));
        }
        //send email with report link to the user who started the batch
        Messaging.sendEmail(new Messaging.Singleemailmessage [] {mail});

        //clean up of successfully processed records and old error records (anything besides records created yesterday and today)
        String delQuery = 'Select Id from Load_Request_Item__c where (Operation__c =\'' +CDdSupportConstants.OPERATION_MXP_MAPPING+'\' AND Status__c = \'Completed\') OR (Status__c = \'Error\' AND Processed_Date__c != LAST_N_DAYS:1)';
        Database.executeBatch(new CDdBatchDeleteRecords(delQuery,'Load_Request_Item__c'));
    }

    /*****************************************************************************************************************************
    *
    * Private Methods
    *
    *****************************************************************************************************************************/
     /**
     * @author      Sahil Chaudhry
     * @date        03/2022
     * @decription  get accounts from database
     * @param       set of account ids
     * @return      account map
    */
    private static Map<Id,Account> getAccountFromDB(Set<Id> accIdSet) {
        return new Map<Id,Account>([SELECT Id,Case_Routing_Override__c,
                                    (SELECT Id,UserId
                                        FROM AccountTeamMembers
                                        WHERE TeamMemberRole =:CDdSupportConstants.MXP_ROLE_NAME)
                                        FROM Account WHERE Id =:accIdSet]);
    }

     /**
     * @author      Sahil Chaudhry
     * @date        03/2022
     * @decription  get users from database
     * @param       set of user ids
     * @return      user map
    */
    private static Map<Id,User> getUserFromDB(Set<Id> userIdSet) {
        return new Map<Id,User>([SELECT Id FROM User WHERE Id =:userIdSet and isActive = true]);
    }

     /**
     * @author      Sahil Chaudhry
     * @date        03/2022
     * @decription  prepare map of staging records to update errors
     * @param       staging record, error message
     * @return
    */
    private static void addErrorToStagingRecord(Load_Request_Item__c lriRec, String errorMessage) {
        lriRec.Exception_Details__c = errorMessage;
        lriRec.Error__c = true;
        lriRec.Status__c = 'Error';
        lriRec.Processed_Date__c = Date.today();
        stagingRecToUpdate.put(lriRec.Id,lriRec);
    }

     /**
     * @author      Sugan
     * @date        01/2023
     * @decription  set staging records as successfully processed by updating status
     * @param       Set status to Completed for successfully processed staging records
     * @return
    */
    private static void addSuccessToStagingRecord(Load_Request_Item__c lriRec){
        lriRec.Status__c = 'Completed';
        lriRec.Processed_Date__c = Date.today();
        stagingRecToUpdate.put(lriRec.Id,lriRec);
    }

     /**
     * @author      Sahil Chaudhry
     * @date        03/2022
     * @decription  prepare list of account team members to insert
     * @param       accountid and userid
     * @return
    */
    private static void insertMXP(Id accId, Id userId) {
        AccountTeamMember atm = new AccountTeamMember();
        atm.AccountId = accId;
        atm.UserId = userId;
        atm.TeamMemberRole = CDdSupportConstants.MXP_ROLE_NAME;
        atm.Source__c = 'Snowflake';
        atmToInsert.add(atm);
    }

    //Exception class
    public class CDdProcessMxpAccountsBatchException extends Exception{}
}