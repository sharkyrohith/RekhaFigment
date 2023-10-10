/**
 * CDdProcessLRIBatch
 *
 * @author     Sahil (sahil.chaudhry@doordash.com)
 * @date       2022-05-17
 * @decription process LRI staging records in batches
 */
global class CDdProcessLRIBatch implements Database.Batchable<SObject> {   
    /*****************************************************************************************************************************
    *
    * Constants & Private Variables
    *
    *****************************************************************************************************************************/
    private static Map<Id,Load_Request_Item__c> stagingRecToUpdate = new Map<Id,Load_Request_Item__c>();
    private String operationType {get;set;}
    private static Support_Settings__c SUPPORT_SETTINGS = Support_Settings__c.getInstance() == null ? 
                                                                new Support_Settings__c() : Support_Settings__c.getInstance();
    private static List<String> EMAIL_LIST = SUPPORT_SETTINGS.Case_Update_App_Recipients__c != null ?                                   
                                                SUPPORT_SETTINGS.Case_Update_App_Recipients__c.split(CDdCoreConstants.DELIMITER_COMMA)
                                                : new List<String>{UserInfo.getUserEmail()};
    /*****************************************************************************************************************************
    *
    * Constructors
    *
    *****************************************************************************************************************************/
     /**
     * @author      Sahil Chaudhry
     * @date        05/2022
     * @decription  constructor
     * @param       
     * @return      
    */
    global CDdProcessLRIBatch(String operationType) {
        this.operationType = operationType;
    }

    /*****************************************************************************************************************************
    *
    * Public Methods
    *
    *****************************************************************************************************************************/
     /**
     * @author      Sahil Chaudhry
     * @date        05/2022
     * @decription  start method to collect records from database
     * @param       batchable context
     * @return      query locator
    */
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT Id,UUID__c,Issue_Type__c,Email_Body__c,
                                            Issue__c,Resolution_Category__c,Resolution__c,
                                            Send_Email__c,Payload__c,Case_Status__c
                                            FROM Load_Request_Item__c
                                            WHERE Status__c = 'New'
                                            AND Operation__c =:operationType]);
    }

    /**
     * @author      Sahil Chaudhry
     * @date        05/2022
     * @decription  update cases
     * @param       batchable context, list of staging object records
     * @return      
    */
    global void execute(Database.BatchableContext info, List<Load_Request_Item__c> lRIList) {
        List<Case> casesToUpdate = new List<Case>();
        Map<Id,String> caseIdToErrMsgMap = new Map<Id,String>();
        Set<Id> successCaseIds = new Set<Id>();
        Map<Id,String> casesWithEmailBody = getCaseWithEmailBody(lRIList);
        for (Load_Request_Item__c lRIVar : lRIList) {
            if (isValidCaseFromLRI(lRIVar)) {
                Id validUUID = CDdUtilities.returnValidId(lRIVar.UUID__c);
                Case caseObj = new Case();
                caseObj.Id = validUUID;
                caseObj.Issue_Type__c = lRIVar.Issue_Type__c;
                caseObj.Issue__c = lRIVar.Issue__c;
                caseObj.Resolution_Type__c = lRIVar.Resolution_Category__c;
                caseObj.Resolution__c = lRIVar.Resolution__c;
                caseObj.Send_Email_Today__c = lRIVar.Send_Email__c;
                caseObj.Status = lRIVar.Case_Status__c;
                if (!casesWithEmailBody.isEmpty() && casesWithEmailBody.containsKey(caseObj.Id)) {
                    caseObj.Email_Body__c = casesWithEmailBody.get(caseObj.Id);
                }
                casesToUpdate.add(caseObj);
            }
        }
        //now update cases
        if (!casesToUpdate.isEmpty()) {
            List<Database.SaveResult> caseUpdateResult = Database.update(casesToUpdate, false);
             //loop through database results and populate caseId to error mesg map
             for (Database.SaveResult resVar : caseUpdateResult) {
                if (!resVar.isSuccess()) {
                    for (Database.Error err : resVar.getErrors()) {
                        caseIdToErrMsgMap.put(resVar.getId(),err.getMessage());
                    }
                } else {
                    successCaseIds.add(resVar.getId());
                }
            }
        }
        
        for (Load_Request_Item__c lRIVar : lRIList) {
            Id validUUID = CDdUtilities.returnValidId(lRIVar.UUID__c);
            
            if (!caseIdToErrMsgMap.isEmpty() && caseIdToErrMsgMap.containsKey(validUUID)) {
                addErrorToStagingRecord(lRIVar, caseIdToErrMsgMap.get(validUUID));
            }
            if (!successCaseIds.isEmpty() && successCaseIds.contains(validUUID)) {
                addSuccessToStagingRecord(lRIVar);
            }
        }

        //update staging records
        if (!stagingRecToUpdate.isEmpty()) {
            List<Database.SaveResult> lriUpdateResult = Database.update(stagingRecToUpdate.values(), false);
            List<String> errorMessages = CDdErrorUtilities.processSaveResults(lriUpdateResult);
            if (!errorMessages.isEmpty()) {
                CDdErrorUtilities.createApexLogs(errorMessages,'CDdProcessLRIBatch','Update Staging records',LoggingLevel.ERROR);
            }
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
                                                    AND Operation__c =: CDdSupportConstants.OPERATION_CASE_UPDATES
                                                    LIMIT 1];

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(EMAIL_LIST);
        mail.setSenderDisplayName('Bulk Case Updates Hub');
        mail.setSubject('Batch Processing Result');
        if (mxpLRIList.isEmpty()) {
            mail.setPlainTextBody('Case Updates Batch Processed Successfully!');
        } else {
            mail.setPlainTextBody('Link to Case Bulk Updates Error Report:'
                                +CDdCoreConstants.NEW_LINE+CDdCoreConstants.DELIMITER_SPACE
                                +CDdNameValuePairHelper.getTextValue(CDdNameValuePairConstants.CASE_UPDATE_REPORT_URL));
        }
        //send email with report link to the user who started the batch
        Messaging.sendEmail(new Messaging.Singleemailmessage [] {mail});
    }

     /*****************************************************************************************************************************
    *
    * Private Methods
    *
    *****************************************************************************************************************************/
     /**
     * @author      Sahil Chaudhry
     * @date        05/2022
     * @decription  is the case valid
     * @param       staging record
     * @return      true if valid
    */
    private Boolean isValidCaseFromLRI(Load_Request_Item__c lRIObj) {
        Boolean retVal = false;
        if (lRIObj != null && String.isNotBlank(lRIObj.Case_Status__c)
            && String.isNotBlank(lRIObj.Issue_Type__c) && String.isNotBlank(lRIObj.Issue__c)
            && String.isNotBlank(lRIObj.Resolution_Category__c) && String.isNotBlank(lRIObj.Resolution__c)
            && String.isNotBlank(lRIObj.UUID__c)) {
            retVal = true;
        }
        return retVal;
    }

      /**
     * @author      Sahil Chaudhry
     * @date        05/2022
     * @decription  prepare map of staging records to update errors
     * @param       staging record, error message
     * @return      
    */
    private static void addErrorToStagingRecord(Load_Request_Item__c lriRec, String errorMessage) {
        lriRec.Exception_Details__c = errorMessage;
        lriRec.Error__c = true;
        lriRec.Status__c = 'Error';
        stagingRecToUpdate.put(lriRec.Id,lriRec);
    }

     /**
     * @author      Sahil Chaudhry
     * @date        05/2022
     * @decription  prepare map of staging records to update success
     * @param       staging record
     * @return      
    */
    private static void addSuccessToStagingRecord(Load_Request_Item__c lriRec) {
        lriRec.Exception_Details__c = null;
        lriRec.Error__c = false;
        lriRec.Status__c = 'Completed';
        stagingRecToUpdate.put(lriRec.Id,lriRec);
    }

    /**
     * @author      Sahil Chaudhry
     * @date        05/2022
     * @decription  process email body
     * @param       list of staging records
     * @return      map of case Ids to processed email bodies
    */
    private static Map<Id,String> getCaseWithEmailBody(List<Load_Request_Item__c> lRIList) {
        Map<Id,String> caseIdToEmailBodyMap = new Map<Id,String>();    
        if (!lRIList.isEmpty()) {
            for (Load_Request_Item__c lriVar : lRIList) {
                if (String.isNotBlank(lriVar.UUID__c) && String.isNotBlank(lriVar.Email_Body__c)) {
                    caseIdToEmailBodyMap.put(CDdUtilities.returnValidId(lriVar.UUID__c), lriVar.Email_Body__c);
                }
            }
            for (Case c : [SELECT Id,Contact.Name FROM Case WHERE Id IN :caseIdToEmailBodyMap.keySet()]) {
                if (!caseIdToEmailBodyMap.isEmpty() && caseIdToEmailBodyMap.containsKey(c.Id)
                        && String.isNotBlank(caseIdToEmailBodyMap.get(c.Id))) {
                    String processedBody = caseIdToEmailBodyMap.get(c.Id)
                                            .replaceFirst(CDdCoreConstants.DELIMITER_UNDERSCORE,CDdCoreConstants.DELIMITER_DOT);
                    processedBody = CDdUtilities.replaceMergeFields(c, 'Case', processedBody);
                    caseIdToEmailBodyMap.put(c.Id, processedBody);
                }
            }
        }
        return caseIdToEmailBodyMap;
    }
}