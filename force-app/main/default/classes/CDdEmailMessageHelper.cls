/**
* @date 07/28/2021
*
* @group Trigger Handler
*
* @description Trigger handler helper methods for emailmessage object
**/

public class CDdEmailMessageHelper{

    /*** constants ***/
     public static final String CLASS_INFO = 'Class Name: CDdEmailMessageHelper';
     public static final String UPDATE_EMAIL_COUNT_MTHD  = 'updateEmailCountonCases';
     public static final String REOPEN_CASE_EMAIL_MTHD  = 'reopenCaseFromEmailMessage';
     public static final Id SUPPORT_RECORDTYPEID = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support').getRecordTypeId();
     public static final String M_ESCALATIONS_TO_ADDRESS  = 'm-escalations';
     public static final String M_ESCALATIONS_BGC_TO_ADDRESS  = 'm-escalations-bgc';
     public static final String M_ESCALATIONS_BGC_QUEUE_NAME  = 'M-Escalations Dx BGC Compliance';
     public static final String CAVIAR_RESTAURANTS_ROUTING_EMAIL = 'restaurantaccounts@trycaviar.com';
     public static final String CASE_PLATFORM_CAVIAR = 'Caviar';
     public static final String MAILER_DAEMON_PREFIX = 'mailer-daemon@';
     public static final String UNDER_REVIEW_STATUS = System.Label.Under_Review_Statuses;
     public static Support_Settings__c SUPPORT_SETTINGS = Support_Settings__c.getInstance();
     public static Auto_Create_Case_Setting__mdt defaultACCS;
     public static Set<String> recordTypesToExcludeSet = new Set<String>{
             CDdSupportConstants.RECORDTYPE_NAME_CAVIRA_SUPPORT,
             CDdSupportConstants.RECORDTYPE_NAME_CFC_CATERING,
             CDdSupportConstants.RECORDTYPE_NAME_DRIVE_API
         };

     public static Set<String> caseStatusOptInExcludeSet = new Set<String>{
             CDdSupportConstants.OPEN_STATUS,
             CDdSupportConstants.CLOSED_STATUS,
             CDdSupportConstants.REOPEN_STATUS };
     public static Set<String> caseStatusOptOutExcludeSet = new Set<String>{
             CDdSupportConstants.OPEN_STATUS,
             CDdSupportConstants.REOPEN_STATUS };
    public static Set<String> caseStatusReopenProactiveOutreach = new Set<String>{
                CDdSupportConstants.SOLVED_STATUS,
                CDdSupportConstants.PENDING_STATUS,
                CDdSupportConstants.WAITING_DD_TEAM_STATUS };
    public static Set<String> caseStatusExcludeENTCOORescue = new Set<String>{
            CDdSupportConstants.IN_PROGRESS,
            CDdSupportConstants.CLOSED_STATUS,
            CDdSupportConstants.WAITING_DD_TEAM_STATUS,
            CDdSupportConstants.OPEN_STATUS,
            CDdSupportConstants.NEW_STATUS};


    public static Set<String> caseAccountDeckRankExcludeSet = new Set<String>{
            CDdSupportConstants.JACK_RANK,
            CDdSupportConstants.JOKER_RANK,
            CDdSupportConstants.QUEEN_RANK,
            CDdSupportConstants.PENDING_RANK };

    public static Set<String> caseFields = new Set<String>{'Id','Recordtype.Name','InboundEmailCount__c','OutboundEmailCount__c',
        'Case_Record_Type__c','Reopen_Opt_in__c','Status','IsClosed','Insufficient_Information__c','PB_WF_Flow_Ran__c','RecordTypeId',
        'Last_Email_to_Customer__c','Last_Email_from_Customer__c','Subject','BusinessHoursId','Contactid','OwnerId','Initial_Queue__c',
        'Initial_Queue_Name__c','Case_Routing_Override__c','Previous_Queue__c','Previous_Queue_ID__c','AccountId','Account_Deck_Rank__c',
        'To_Email_Address__c', 'ClosedDate','Customer_Type__c'};

    public static Boolean isChildCaseAutoCreated = false;

    static {
        String developerName = Test.isRunningTest() ? 'TEST_DO_NOT_DELETE' : 'Default';
        List<Auto_Create_Case_Setting__mdt> accsList = [SELECT Id, Auto_Create_Case_Customer_Type__c, Auto_Create_Case_Email_Address__c,
                                                        Auto_Create_Case_Record_Type__c, Close_Date_Range__c, Parent_Case_Fields__c
                                                        FROM Auto_Create_Case_Setting__mdt
                                                        WHERE DeveloperName = :developerName];
        if(accsList.size() > 0){
            defaultACCS = accsList[0];
        }
    }

     /**@author    | Raja  (Criticalriver)
     * @date       | 2021-07-29
     * @ticket     | BIZS-273
     * @param List<EmailMessage> emailrecordList
     * @return List<case>
     **/

     public List<Case> queryCases(List<EmailMessage> emailRecordList){

         Set<Id> parentIdsSet=new Set<Id>();
         List<Case> caseListToProcess = new List<Case>();

         if (!emailRecordList.isEmpty() && parentIdsSet != null){

             for (emailMessage curEM:emailRecordList){

                 if (curEM.ParentId != null && curEM.ParentId.getSobjectType() == case.SobjectType){

                     parentIdsSet.add(curEM.ParentId);
                 }

             }
             if (!parentIdsSet.isEmpty() && parentIdsSet != null){
                if(String.isNotEmpty(defaultACCS.Parent_Case_Fields__c)){
                    caseFields.addAll(defaultACCS.Parent_Case_Fields__c.split(CDdCoreConstants.DELIMITER_SEMICOLON));
                }
                caseListToProcess = CasesSelector.newInstance().selectByIdExtraFields(parentIdsSet, caseFields);
             }
         }

         return caseListToProcess;
     }

     /**@author    | Raja  (Criticalriver)
     * @date       | 2021-07-29
     * @ticket     | BIZS-273
     * @description| updates inbound and outbound email counter on related case when email messages is created for Support recordtype
     * @param List<EmailMessage> emailrecordList
     * @return List<case>
     **/

     public List<Case> updateEmailCountonCases(List<EmailMessage> emailRecordList,Map<Id,Case> emailMsgCaseMap){

         //instaniate Set/lists/classes/maps
         Map<Id,Integer>  mapCaseInboundEmailList = new Map<Id,Integer>();
         Map<Id,Integer>  mapCaseOutboundEmailList = new Map<Id,Integer>();
         List<Case> caseListToUpdate = new List<Case>();
         Set<Id> parentIdsSet=new Set<Id>();

         try{
             if (!emailRecordList.isEmpty() && emailRecordList  != null){

                 for (EmailMessage curEM:emailRecordList){

                     if (curEM.ParentId != null && curEM.ParentId.getSobjectType() == case.SobjectType){
                         parentIdsSet.add(curEM.ParentId);

                         if (curEM.incoming){

                             if (!mapCaseInboundEmailList.containskey(curEM.ParentId)){

                                 mapCaseInboundEmailList.put(curEM.ParentId,0);
                              }
                                 Integer inboundCount=mapCaseInboundEmailList.get(curEM.ParentId)+1;
                                 mapCaseInboundEmailList.put(curEM.ParentId,inboundCount);

                         }else{

                             if (!mapCaseOutboundEmailList.containskey(curEM.ParentId)){

                                 mapCaseOutboundEmailList.put(curEM.ParentId,0);
                              }
                                 Integer outboundCount=mapCaseOutboundEmailList.get(curEM.ParentId)+1;
                                 mapCaseOutboundEmailList.put(curEM.ParentId,outboundCount);
                         }
                     }
                 }

             }

             if (!parentIdsSet.isEmpty() && parentIdsSet  != null){

                 for(Case c:emailMsgCaseMap.values()){

                     if(c.Recordtype.Name==CDdSupportConstants.RECORDTYPE_NAME_SUPPORT ){

                         if  (mapCaseInboundEmailList.containskey(c.id))
                             c.InboundEmailCount__c= c.InboundEmailCount__c == null ? mapCaseInboundEmailList.get(c.id) : (c.InboundEmailCount__c + mapCaseInboundEmailList.get(c.id));

                         if  (mapCaseOutboundEmailList.containskey(c.id))
                             c.OutboundEmailCount__c= c.OutboundEmailCount__c == null ? mapCaseOutboundEmailList.get(c.id) : (c.OutboundEmailCount__c + mapCaseOutboundEmailList.get(c.id));
                     }
                     caseListToUpdate.add(c);
                 }
             }
         }
         catch(Exception ex){

             //system.debug('Error Message...'+ex.getMessage());
             CDdErrorUtilities.createApexLogs(new List<String>{ex.getMessage()}, CLASS_INFO, UPDATE_EMAIL_COUNT_MTHD, LoggingLevel.ERROR);
         }


         return caseListToUpdate;
     }


     /**@author    | Raja  (Criticalriver)
     * @date       | 2021-07-29
     * @ticket     | BIZS-273
                   | BIZS-252 - added logic to not create the case when email  ToAddress contains m-escalations-bgc
     * @param List<EmailMessage> emailMessageList
     * @return list<case> **/

     public List<Case> createEscalationcases(List<EmailMessage> emailMessageList,Map<Id,Case> emailmsgCaseMap){

         List<Case> listofCasesToInsert = new List<Case> ();
         for (EmailMessage curEM: emailMessageList){

             if (curEM.ParentId != null && curEM.ParentId.getSobjectType() == case.SobjectType){

                 if (emailmsgCaseMap.containskey(curEM.ParentId) && curEM.toAddress != null ){

                     if(curEM.toAddress.contains(M_ESCALATIONS_TO_ADDRESS) && !curEM.toAddress.contains(M_ESCALATIONS_BGC_TO_ADDRESS)){
                         Case newcase=new Case();
                         newcase.BusinessHoursId=emailmsgCaseMap.get(curEM.ParentId).BusinessHoursId;
                         newcase.Contactid=emailmsgCaseMap.get(curEM.ParentId).contactid;
                         newcase.Ownerid=System.Label.M_Escalations_Queue;
                         newcase.Parentid=curEM.ParentId;
                         newcase.Recordtypeid=SUPPORT_RECORDTYPEID;
                         newcase.Status=CDdSupportConstants.OPEN_STATUS;
                         newcase.Subject=curEM.Subject;

                         listofCasesToInsert.add (newcase);

                     }
                 }
             }
         }
         return listofCasesToInsert;
     }




     /**@author    | Kody Hungenberg
     * @date       | 2021-10-01
     * @ticket     | BIZS-499
     * @description  | Checks cases are valid for reopening
                     |
                     |
     * @param
     * @return List<case>
     **/

     public List<Case> caseReopens(List<EmailMessage> emailMessageList, Map<Id,Case> emailMsgCaseMap){

         List<Case> casesToReturn = new List<Case>();

         for (EmailMessage curEM: emailMessageList){
             //This will to make sure it is for Case Object
             if (curEM.ParentId != null && curEM.ParentId.getSobjectType() == case.SobjectType &&
                 !String.isBlank(curEM.Subject) &&
                 !curEM.Subject.contains('BLOCKED: Alcohol Onboarding')) {
                 //Check if is incoming email and satisfies the check

                 if (curEM.incoming && caseEmailValidator(curEM) && emailmsgCaseMap.containskey(curEM.ParentId)){
                     Case curParentCase = emailmsgCaseMap.get(curEM.ParentId);
                     //Check if is Case satisfies the check to reopen
                     if(caseReopenValidator(curParentCase,curParentCase.Reopen_Opt_in__c)){
                         //For reopen Opt in decide owner based on Initial Queue
                         if(curParentCase.Reopen_Opt_in__c && curParentCase.Initial_Queue_Name__c == M_ESCALATIONS_BGC_QUEUE_NAME){
                             curParentCase.OwnerId = curParentCase.Initial_Queue__c;
                         }
                         //Reopen the case
                         //BASD-46636 Below logic replaces 'Caviar Onboarding - Update Case to Under Review' Workflow. Updating case status to Under Review and Last Email From Merchant fields.
                         if(curParentCase.RecordType.Name == CDdSupportConstants.RECORDTYPE_NAME_CAVIAR_ONBOADING && UNDER_REVIEW_STATUS.contains(curParentCase.Status)){
                            curParentCase.Status = CDdSupportConstants.UNDER_REVIEW_STATUS;
                            curParentCase.Last_Email_from_Merchant__c = System.now();
                        }
                        else{
                            curParentCase.Status = CDdSupportConstants.REOPEN_STATUS;
                        }
                         casesToReturn.add(curParentCase);
                     }
                 }
             }
         }
         return casesToReturn;
     }

     //Checks if an email is incoming, then checks if its valid for reopening
     private Boolean caseEmailValidator(EmailMessage emObj){


         if (emObj.ParentId?.getSObjectType() == Case.SObjectType &&
            caseEmailFromValidator(emObj.FromAddress)
             && emObj.CreatedById != System.Label.Conga_User_ID){
                 return true;
         }
         return false;
     }

     // Checks that the from address is not from a bounce back
     private Boolean caseEmailFromValidator(String fromAddress) {
        List<String> mailerDaemonAddresses = ((System.Label.MAILER_DAEMON_ADDRESS_SALESFORCE).deleteWhitespace()).split(',');
        if (fromAddress.startsWith(MAILER_DAEMON_PREFIX) || mailerDaemonAddresses.contains(fromAddress)) {
            return false;
        }
        return true;
     }

     //Checks that the case is valid for being set to reopen.
      /**@author    | Sharvani Sri
     * @date       | 2023-03-01
     * @ticket     | BASD-43874
     * @decription To extend the case re-open process to caviar onboarding cases
     **/
    private Boolean caseReopenValidator(Case cObj,Boolean reopenOptIn){
        if(cObj.RecordTypeId != null && !recordTypesToExcludeSet.contains(cObj.RecordType.Name)){
            //NK: https://doordash.atlassian.net/browse/BASD-41138
            if(cObj.RecordType.Name == CDdSupportConstants.RECORDTYPE_NAME_PROACTIVE_OUTREACH &&
                    caseStatusReopenProactiveOutreach.contains(cObj.Status)){
                return true;
            }
            if(reopenOptIn && cObj.RecordType.Name == CDdSupportConstants.RECORDTYPE_NAME_ENT_COO_RESCUE &&
                caseStatusExcludeENTCOORescue.contains(cObj.Status)){
                return false;
            }
            if(reopenOptIn && !caseStatusOptInExcludeSet.contains(cObj.Status)){
                return true;
            }else if (!reopenOptIn && !caseStatusOptOutExcludeSet.contains(cObj.Status)){
                if((cObj.Status == CDdSupportConstants.CLOSED_STATUS
                            && caseAccountDeckRankExcludeSet.contains(cObj.Account_Deck_Rank__c)
                                &&  cObj.RecordType.Name == CDdSupportConstants.RECORDTYPE_NAME_MARKETPLACE_ONBOARDING)
                  ||(cObj.RecordType.Name == CDdSupportConstants.RECORDTYPE_NAME_CAVIAR_ONBOADING && !UNDER_REVIEW_STATUS.contains(cObj.Status))){
                        return false;
                } else {
                    return true;
                }
            }
        }
        return false;
     }

     //this method replaces the PB 'Redirect Closed Cases to Web'
     //if the case is closed we want to update the case field 'Redirect_Web_Form__c' to true
     //that field is used to fire workflow rules that send emails to the customer
     //when they have sent an email to a closed case
     //example WFR 'JP_Redirect Web Form - Support'
     public List<Case> redirectCasesToWeb(List<EmailMessage> emailMessageList,Map<Id,Case> emailMsgCaseMap){
         List<Case> casesToReturn = new List<Case>();
         if (!emailMessageList.isEmpty()){
             for (EmailMessage em : emailMessageList){
                 if (em.incoming && caseEmailValidator(em) && emailmsgCaseMap.containskey(em.ParentId)){
                     Case c = emailmsgCaseMap.get(em.ParentId);
                     if (c.Status == CDdSupportConstants.CLOSED_STATUS && c.Reopen_Opt_in__c == true
                         && !isChildCaseAutoCreated){
                         c.Redirect_Web_Form__c = true;
                         casesToReturn.add(c);
                     }
                 }
             }
         }
         return casesToReturn;
     }

     public List<Case> updateLastEmail(List<EmailMessage> emailMessageList,Map<Id,Case> emailMsgCaseMap){
         List<EmailMessage> incomingEmails = new List<EmailMessage>();
         List<EmailMessage> outgoingEmails = new List<EmailMessage>();
         List<Case> casesToReturn = new List<Case>();

         if (!emailMessageList.isEmpty()
         && emailMsgCaseMap != null
         && !emailMsgCaseMap.isEmpty()){
             for(EmailMessage em : emailMessageList){
                 if (em.ParentId?.getSObjectType() == Case.SObjectType && emailMsgCaseMap.containsKey(em.ParentId)){
                     Case c = emailMsgCaseMap.get(em.ParentId);
                     if(c.Status != CDdSupportConstants.NEW_STATUS ){
                         if (em.incoming == true && String.isNotBlank(em.toAddress) &&
                            em.toAddress.containsIgnoreCase((CDdSupportConstants.DOORDASH_DOMAIN))){
                             c.Last_Email_from_Customer__c = DateTime.now();
                         }else if(em.incoming == false && String.isNotBlank(em.fromAddress) &&
                            em.fromAddress.containsIgnoreCase((CDdSupportConstants.DOORDASH_DOMAIN)) &&
                            em.fromAddress !=System.Label.MAILER_DAEMON_ADDRESS_SALESFORCE){
                             c.Last_Email_to_Customer__c = DateTime.now();
                         }
                         casesToReturn.add(c);
                     }
                 }
             }
         }
         return casesToReturn;
     }

     /**@author    | Raja  (Criticalriver)
     * @date       | 2021-07-29
     * @ticket     | BIZS-273
     * @param List<EmailMessage> emailMessageList
     * @return void **/

     public static void preventemailmessageDeletion(List<EmailMessage> emailMessageList){

         Allow_Email_Deletion__c emailDeleteSetting = Allow_Email_Deletion__c.getInstance();

         for (EmailMessage email : emailMessageList) {
             if ((!email.isPrivateDraft)
                 && (!emailDeleteSetting.Allow_All_Email_Deletions__c)) {
                     email.addError(Label.Email_Delete_Not_Allowed);
             }
         }
     }

     /**@author    | Raja  (Criticalriver)
     * @date       | 2021-07-29
     * @ticket     | BIZS-273
     * @param List<Case> recordsToUpdate
     * @return void **/

    public void updateRecords(List<Sobject> recordsToUpdate){
        if (!recordsToUpdate.isEmpty()){
            CDdCaseTransferValidationHelper.BYPASS_CASE_TRANSFER_VALIDATION_FOR_THIS_TXN = true;
            List<Database.SaveResult> sResults = Database.Update(recordsToUpdate,false);
            CDdCaseTransferValidationHelper.BYPASS_CASE_TRANSFER_VALIDATION_FOR_THIS_TXN = false;
            CDdErrorUtilities.publishException('EmailMessage',CLASS_INFO +'.updateRecords ', sResults);
        }
    }

     /**@author    | Raja  (Criticalriver)
     * @date       | 2021-07-29
     * @ticket     | BIZS-273
     * @param List<Case> recordsToUpdate
     * @return void **/

     public void insertRecords(List<Sobject> recordsToInsert){

         if (!recordsToInsert.isEmpty()){
             List<Database.SaveResult> sResults = Database.Insert(recordsToInsert,false);
             CDdErrorUtilities.publishException('EmailMessage',CLASS_INFO +'.insertRecords ', sResults);
         }
     }

     /**@author     | Mahesh Chouhan  (Criticalriver)
      * @date       | 2021-11-17
      * @ticket     | BIZS-350
      * @description| Update Platform Field on Cases from Caviar Restaurant Success Team Email-to-Case
      * @param List<EmailMessage> emailrecordList
      * @param Map<Id,Case> emailmsgCaseMap
      * @return List<Case>
      */
     public List<Case> populatePlatformOnCaviarMxCases(List<EmailMessage> emailMessageList,Map<Id,Case> emailmsgCaseMap){
         List<Case> caseListToUpdate = new List<Case> ();
         for (EmailMessage curEM: emailMessageList){
             if (curEM.ParentId != null && curEM.ParentId.getSobjectType() == case.SobjectType){
                 if (emailMsgCaseMap.containskey(curEM.ParentId)){
                     if(curEM.toAddress != null && curEM.toAddress.contains(CAVIAR_RESTAURANTS_ROUTING_EMAIL)){
                         Case curParentCase = emailMsgCaseMap.get(curEM.ParentId);
                         curParentCase.Platform__c = CASE_PLATFORM_CAVIAR;
                         caseListToUpdate.add(curParentCase);
                     }
                 }
             }
         }
         return caseListToUpdate;
     }

     /**@author     | Mahesh Chouhan  (Criticalriver)
      * @date       | May 2023
      * @ticket     | BASD-47588
      * @description| Auto Create Child Case when customer responds to Closed Case via Email
      * @param List<EmailMessage> emailrecordList
      * @param Map<Id,Case> emailmsgCaseMap
      * @return List<Case>
      */
     public List<Case> autoCreateClosedCaseResponse(List<EmailMessage> emailMessageList,Map<Id,Case> emailmsgCaseMap){
        List<String> customerTypes = !String.isBlank(defaultACCS.Auto_Create_Case_Customer_Type__c) ?
            defaultACCS.Auto_Create_Case_Customer_Type__c.split(CDdCoreConstants.DELIMITER_SEMICOLON) : new List<String>();
        List<String> recordTypes = !String.isBlank(defaultACCS.Auto_Create_Case_Record_Type__c) ?
            defaultACCS.Auto_Create_Case_Record_Type__c.split(CDdCoreConstants.DELIMITER_SEMICOLON) : new List<String>();
        List<String> emailAddresses = !String.isBlank(defaultACCS.Auto_Create_Case_Email_Address__c) ?
            defaultACCS.Auto_Create_Case_Email_Address__c.split(CDdCoreConstants.DELIMITER_SEMICOLON) : new List<String>();
        List<Case> listofCasesToInsert = new List<Case> ();
        try{
            for (EmailMessage curEM : emailMessageList){
                if (curEM.incoming && curEM.ParentId != null && curEM.ParentId.getSobjectType() == case.SobjectType){
                    if (emailmsgCaseMap.containskey(curEM.ParentId)){
                        Case parentCase = emailmsgCaseMap.get(curEM.ParentId);
                        if(parentCase.Status == CDdSupportConstants.CLOSED_STATUS && customerTypes.contains(parentCase.Customer_Type__c)
                            && recordTypes.contains(parentCase.RecordTypeId) && emailAddresses.contains(parentCase.To_Email_Address__c)
                            && parentCase.ClosedDate.date().daysBetween(Date.today()) < defaultACCS.Close_Date_Range__c){
                            Case newcase = new Case();
                            newcase.ContactId = emailmsgCaseMap.get(curEM.ParentId).ContactId;
                            newcase.OwnerId = parentCase.Previous_Queue_ID__c;
                            newcase.Status = CDdSupportConstants.OPEN_STATUS;
                            newcase.Origin = CDdSupportConstants.ORIGIN_EMAIL_CLOSED_CASE_RESPONSE;
                            newcase.ParentId = curEM.ParentId;
                            if(String.isNotEmpty(defaultACCS.Parent_Case_Fields__c)){
                                for(String field : defaultACCS.Parent_Case_Fields__c.split(CDdCoreConstants.DELIMITER_SEMICOLON)){
                                    newcase.put(field, parentCase.get(field));
                                }
                            }
                            isChildCaseAutoCreated = true;
                            listofCasesToInsert.add(newcase);
                        }
                    }
                }
            }
        } catch(Exception ex){
            CDdErrorUtilities.publishException('CDdEmailMessageHelper','autoCreateClosedCaseResponse', ex);
        }
        return listofCasesToInsert;
    }
 }