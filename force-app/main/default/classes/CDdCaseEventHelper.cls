/**
 * @author Nayana
 * @date 12/2021
 * @description This class can be used for method for Platform events on Case
 *
**/
public class CDdCaseEventHelper {
   /*****************************************************************************************************************************
   *
   * Constants & Private Variables
   *
   *****************************************************************************************************************************/
    public static Disaster_Prevention_Setting__mdt defaultDPS = Test.isRunningTest()
        ? Disaster_Prevention_Setting__mdt.getInstance('TEST_DO_NOT_DELETE') : Disaster_Prevention_Setting__mdt.getInstance('Default');
    public static final String DISASTER_ESC_CASE_FEED_TITLE = 'Disaster Escalation Case';
    public static final String DISASTER_ESC_MARKING_CASE_ERROR = 'Marking Case as Disaster Escalation Case \nReason : ';
    public static final String DISASTER_ESC_ADD_CRITERIA_ERROR = 'Disaster Escalation Case - Additional Criteria met \nReason : ';
    public static final String DISASTER_ESC_INBOUND_LIMIT_ERROR = 'Has inbounded {0} times in the past 30 days';
    public static final String DISASTER_ESC_STATUS_CHANGE_LIMIT_ERROR = 'Change status over {0} times';
    public static final String DISASTER_ESC_OWNER_CHANGE_LIMIT_ERROR = 'Case owner - assigned to at least {0} different users (not queues)';
    public static final String DISASTER_ESC_OPEN_DAYS_LIMIT_ERROR = 'Case has been opened (without being solved) for over {0} days';
    public static final String AUTOMATED_PROCESS_USER_ID = CDdNameValuePairHelper.getTextValue(CDdNameValuePairConstants.AUTOMATED_PROCESS_USER_ID);
   /*****************************************************************************************************************************
   *
   * Public Methods
   *
   *****************************************************************************************************************************/
    /**
    * @author      Nayana Kapse
    * @date        Mar 2022
    * @jira        https://doordash.atlassian.net/browse/BIZS-1051
    * @description This is to handle Case Detail Creation
    */
    public static void handleCaseDetailCreationEvent(List<Generic_Platform_Event__e> eventList) {
        List<Id> lstCaseIds = new List<Id>();
        List<Case_Detail__c> lstCaseDetailsToInsert = new List<Case_Detail__c>();
        for (Generic_Platform_Event__e event : eventList){
            if (String.isNotEmpty(event.Payload__c)){
                List<Case_Detail__c> caseDetailLst = (List<Case_Detail__c>) JSON.deserialize(event.Payload__c, List<Case_Detail__c>.class);
                lstCaseDetailsToInsert.addAll(caseDetailLst);
            }
        }
        if (!lstCaseDetailsToInsert.isEmpty()) {
            List<Database.SaveResult> results = Database.insert(lstCaseDetailsToInsert,false);
            CDdErrorUtilities.publishException('CDdCaseEventHelper','handleCaseDetailCreationEvent',results);
        }
    }

    /**
     * @author      Sriram
     * @date        Jan 2021
     * @jira        https://doordash.atlassian.net/browse/BZAP-9015
     * @description POS Case Process Enhancements
     *              Raju L - BZAP-13699 - Moved from CDdCaseTriggerHelper
     */
    public static void handleSendEmailEvents(CDdGenericPlatformEventHelper.PlatformEventType eventType, List<Generic_Platform_Event__e> events){
        Set<Id> caseIds = new Set<Id>();
        for (Generic_Platform_Event__e event : events) {
            caseIds.add(event.sObjectId__c);
        }
        switch on eventType {
            when CASE_SEND_EMAIL_POS_SUPPORT_REDIRECT {
                CDdEmailService.sendEmails('POS_Support_Redirect', CDdCustomMetadata.getIdValueFor('Org_Wide_Email_DoorDash'), 'Case', caseIds, 'ContactId', new Set<String>{'SuppliedEmail'});
            }
            when CASE_SEND_EMAIL_POS_POST_ACTIVATION_MARKETPLACE {
                CDdEmailService.sendEmails('Post_Activation_Going_Live_Marketplace_POS', CDdCustomMetadata.getIdValueFor('Org_Wide_Email_DoorDash'), 'Case', caseIds, 'ContactId', new Set<String>{'SuppliedEmail'});
            }
        }
    }

    /**
    * @author      Nayana Kapse
    * @date        Sept 2022
    * @jira        https://doordash.atlassian.net/browse/BIZS-1886
    * @description This is to handle Proactive Case Info object record Creation
    */
    public static void handleProactiveCaseInfoRecordCreation(List<Generic_Platform_Event__e> eventList) {
        List<Proactive_Case_Info__c> lstProactiveInfoUpsert = new List<Proactive_Case_Info__c>();
        for (Generic_Platform_Event__e event : eventList){
            if (String.isNotEmpty(event.Payload__c)){
                for(CDdProactiveCaseCreationHelper.ProactiveCaseInfo cWrap:(List<CDdProactiveCaseCreationHelper.ProactiveCaseInfo>) JSON.deserialize(event.Payload__c, List<CDdProactiveCaseCreationHelper.ProactiveCaseInfo>.class)){
                    switch on cWrap.caseType {
                        when 'Item Unavailable'{
                            lstProactiveInfoUpsert.addAll(CDdProactiveInfoCaseCreationHelper.handleItemUnavailable(cWrap));
                        }
                    }
                }
            }
        }
        if (!lstProactiveInfoUpsert.isEmpty()) {
            List<Database.UpsertResult> results = Database.upsert(lstProactiveInfoUpsert,false);
            CDdErrorUtilities.publishException('CDdCaseEventHelper','handleProactiveCaseInfoRecordCreation',results);
        }
    }

    /**
    * @author      Nayana Kapse
    * @date        Sept 2022
    * @jira        https://doordash.atlassian.net/browse/BIZS-1886
    * @description This is to handle Proactive Case Info object record Creation
    */
    public static void handleProactiveCaseRecordCreation(List<Generic_Platform_Event__e> eventList) {
        List<Case> lstCaseToInsert = new List<Case>();
        for (Generic_Platform_Event__e event : eventList){
            if (String.isNotEmpty(event.Payload__c)){
                for(CDdProactiveCaseCreationHelper.ProactiveCaseInfo cWrap:(List<CDdProactiveCaseCreationHelper.ProactiveCaseInfo>) JSON.deserialize(event.Payload__c, List<CDdProactiveCaseCreationHelper.ProactiveCaseInfo>.class)){
                    Case c = new Case();
                    c.Customer_Type__c = cWrap.customerType;
                    c.RecordTypeId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeIdByDevName(cWrap.caseRecordType);
                    c.Origin = cWrap.caseOrigin;
                    if(String.isNotBlank(cWrap.fieldsToCopyFromOriginalCase)){
                        for(String fldName : cWrap.fieldsToCopyFromOriginalCase.split(CDdCoreConstants.DELIMITER_SEMICOLON)){
                            c.put(fldName,cWrap.originalCase.get(fldName));
                        }
                    }
                    lstCaseToInsert.add(c);
                }
            }
        }
        if (!lstCaseToInsert.isEmpty()) {
            List<Database.SaveResult> results = Database.insert(lstCaseToInsert,false);
            CDdErrorUtilities.publishException('CDdCaseEventHelper','handleProactiveCaseRecordCreation',results);
        }
    }


     /**
    * @author      Nayana Kapse
    * @date        Nov 2022
    * @jira        https://doordash.atlassian.net/browse/BASD-38868
    * @description This is to Create Case Feed
    */
    public static void createCaseFeedItem(List<Generic_Platform_Event__e> eventList) {
        List<FeedItem> lstCaseFeedToInsert = new List<FeedItem>();
        for (Generic_Platform_Event__e event : eventList){
            if (String.isNotEmpty(event.Payload__c)){
                List<FeedItem> caseFeedItemLst = (List<FeedItem>) JSON.deserialize(event.Payload__c, List<FeedItem>.class);
                lstCaseFeedToInsert.addAll(caseFeedItemLst);
            }
        }
        if (!lstCaseFeedToInsert.isEmpty()) {
            List<Database.SaveResult> results = Database.insert(lstCaseFeedToInsert,false);
            CDdErrorUtilities.publishException('CDdCaseEventHelper','createCaseFeedItem',results);
        }
    }

    /**
     * @author      Mahesh Chouhan
     * @date        March 2023
     * @jira        https://doordash.atlassian.net/browse/BASD-43689
     * @description check if created case fulfil Disaster Prevention Criteria
     * @param   List<Case_Event__e> caseEvents - Case Event list
     * @return  void
     */
    public static void checkForDisasterPreventionCase(List<Case_Event__e> caseEvents) {
        try {
                fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
                Map<Id,Case> oldCaseMap = new Map<Id,Case>();
                List<Case> newCaseList = new List<Case>();
                for(Case_Event__e caseEvent : caseEvents){
                    oldCaseMap.put(caseEvent.Case_Id__c, (Case) JSON.deserialize(caseEvent.Old_Case_Payload__c, Case.class));
                    newCaseList.add((Case) JSON.deserialize(caseEvent.New_Case_Payload__c, Case.class));
                }

                Set<String> customerTypes = new Set<String>{CDdSupportConstants.CUSTOMER_TYPE_CONSUMER,
                    CDdSupportConstants.CUSTOMER_TYPE_DASHER, CDdSupportConstants.CUSTOMER_TYPE_MERCHANT};
                Set<Id> alreadyEscalatedCaseIds = new Set<Id>();
                Map<Id, List<FeedItem>> caseNoteMap = new Map<Id, List<FeedItem>>();
                for(Case caseRecord : newCaseList){
                    if(caseRecord.Disaster_Escalation_Case__c){
                        alreadyEscalatedCaseIds.add(caseRecord.Id);
                    }
                }

                if(!alreadyEscalatedCaseIds.isEmpty()){
                    List<FeedItem> caseNotes = FeedItemSelector.newInstance().selectTextPostByParentId(alreadyEscalatedCaseIds);
                    for(FeedItem caseNote : caseNotes){
                        if(!caseNoteMap.containsKey(caseNote.ParentId)){
                            caseNoteMap.put(caseNote.ParentId, new List<FeedItem>());
                        }
                        caseNoteMap.get(caseNote.ParentId).add(caseNote);
                    }   
                }
            
                Map<Id,Account> accMap = CDdCaseTriggerOptimizationHelper.getAccountMap();
                Set<Id> caseIds = new Set<Id>();
                Set<String> closeCaseStatus = new Set<String>{CDdSupportConstants.CLOSED_STATUS, CDdSupportConstants.SOLVED_STATUS};
                List<Case> disasterEscalationCases = new List<Case>();
                //Key is CaseId and Value is Indicator for marking case as Disaster Escalation Case
                Map<Id, List<String>> disasterEscIndicator = new Map<Id, List<String>>();
                for(Case caseRecord : newCaseList){
                    caseIds.add(caseRecord.Id);
                }

                Set<String> caseHistoryFields = new Set<String>{'Status', 'Owner'};
                List<CaseHistory> caseHistoryList = CaseHistoriesSelector.newInstance().selectByCaseIdAndFields(caseIds, caseHistoryFields);

                //Key is CaseId and Value is CaseHistory List
                Map<Id, List<CaseHistory>> caseHistoryMap = new Map<Id, List<CaseHistory>>();
                for(CaseHistory csHistory : caseHistoryList){
                    if(!caseHistoryMap.containsKey(csHistory.CaseId)){
                        caseHistoryMap.put(csHistory.CaseId, new List<CaseHistory>());
                    }
                    caseHistoryMap.get(csHistory.CaseId).add(csHistory);
                }

                for(Case caseRecord : newCaseList){
                    Integer statusChangeCounter = 0;
                    Integer ownerChangeCounter = 0;
                    Boolean isAlreadyInboundLimitEsc = false;
                    Boolean isAlreadyStageChangeLimitEsc = false;
                    Boolean isAlreadyOwnerChangeLimitEsc = false;
                    Boolean isAlreadyOpenDaysLimitEsc = false;

                    if(caseNoteMap.containsKey(caseRecord.Id)){
                        for(FeedItem caseNote : caseNoteMap.get(caseRecord.Id)){
                            if(caseNote.Body.contains(String.format(DISASTER_ESC_INBOUND_LIMIT_ERROR, new List<Integer>{Integer.valueOf(defaultDPS.Case_Inbound_Limit__c)}))){
                                isAlreadyInboundLimitEsc = true;
                            }
                            if(caseNote.Body.contains(String.format(DISASTER_ESC_STATUS_CHANGE_LIMIT_ERROR, new List<Integer>{Integer.valueOf(defaultDPS.Case_Status_Change_Limit__c)}))){
                                isAlreadyStageChangeLimitEsc = true;
                            }
                            if(caseNote.Body.contains(String.format(DISASTER_ESC_OWNER_CHANGE_LIMIT_ERROR, new List<Integer>{Integer.valueOf(defaultDPS.Case_Owner_Change_Limit__c)}))){
                                isAlreadyOwnerChangeLimitEsc = true;
                            }
                            if(caseNote.Body.contains(String.format(DISASTER_ESC_OPEN_DAYS_LIMIT_ERROR, new List<Integer>{Integer.valueOf(defaultDPS.No_of_Days_Case_Open_Limit__c)}))){
                                isAlreadyOpenDaysLimitEsc = true;
                            }
                        }
                    }

                    if(isAlreadyInboundLimitEsc && isAlreadyStageChangeLimitEsc && isAlreadyOwnerChangeLimitEsc && isAlreadyOpenDaysLimitEsc){
                        continue;
                    }
                    if(caseHistoryMap.containsKey(caseRecord.Id)){
                        for(CaseHistory csHistory : caseHistoryMap.get(caseRecord.Id)){
                            if(csHistory.Field == 'Status'){
                                statusChangeCounter++;
                            }
                            else if(csHistory.Field == 'Owner' && csHistory.DataType == 'EntityId' && String.isNotBlank(String.valueOf(csHistory.NewValue))
                                    && String.valueOf(csHistory.NewValue).contains('005')){
                                ownerChangeCounter++;
                            }
                        }
                    }

                    Boolean isInboundLimitEsc = !isAlreadyInboundLimitEsc && accMap.containsKey(caseRecord.AccountId) && !caseRecord.Disaster_Escalation_Case__c
                        && accMap.get(caseRecord.AccountId).Inbound_Count__c >= defaultDPS.Case_Inbound_Limit__c;
                    Boolean isStageChangeLimitEsc = !isAlreadyStageChangeLimitEsc && caseRecord.Status != oldCaseMap.get(caseRecord.Id).Status
                        && statusChangeCounter > defaultDPS.Case_Status_Change_Limit__c;
                    Boolean isOwnerChangeLimitEsc = !isAlreadyOwnerChangeLimitEsc && caseRecord.OwnerId != oldCaseMap.get(caseRecord.Id).OwnerId
                        && String.valueOf(caseRecord.OwnerId).contains('005') && ownerChangeCounter > defaultDPS.Case_Owner_Change_Limit__c - 1;
                    Boolean isOpenDaysLimitEsc = !isAlreadyOpenDaysLimitEsc && !closeCaseStatus.contains(caseRecord.Status)
                        && caseRecord.CreatedDate.date().daysBetween(Date.today()) > defaultDPS.No_of_Days_Case_Open_Limit__c
                        && caseRecord.LastModifiedById != AUTOMATED_PROCESS_USER_ID;/* Check if LastModifiedBy User is not AutomatedProcess to prevent recursive updates */

                    if(isInboundLimitEsc || isStageChangeLimitEsc || isOwnerChangeLimitEsc || isOpenDaysLimitEsc){
                        caseRecord.Disaster_Escalation_Case__c = true;
                        uow.registerDirty(new Case(Id = caseRecord.Id, Disaster_Escalation_Case__c = true));
                        disasterEscalationCases.add(caseRecord);
                        List<String> escalationReason = new List<String>();

                        //Add Case Note for each Escalation Indicator
                        if(isInboundLimitEsc){
                            escalationReason.add(String.format(DISASTER_ESC_INBOUND_LIMIT_ERROR, new List<Integer>{Integer.valueOf(defaultDPS.Case_Inbound_Limit__c)}));
                        }
                        if(isStageChangeLimitEsc){
                            escalationReason.add(String.format(DISASTER_ESC_STATUS_CHANGE_LIMIT_ERROR, new List<Integer>{Integer.valueOf(defaultDPS.Case_Status_Change_Limit__c)}));
                        }
                        if(isOwnerChangeLimitEsc){
                            escalationReason.add(String.format(DISASTER_ESC_OWNER_CHANGE_LIMIT_ERROR, new List<Integer>{Integer.valueOf(defaultDPS.Case_Owner_Change_Limit__c)}));
                        }
                        if(isOpenDaysLimitEsc){
                            escalationReason.add(String.format(DISASTER_ESC_OPEN_DAYS_LIMIT_ERROR, new List<Integer>{Integer.valueOf(defaultDPS.No_of_Days_Case_Open_Limit__c)}));
                        }
                        disasterEscIndicator.put(caseRecord.Id, escalationReason);
                    }
                }
                createDisasterEscalationNote(disasterEscalationCases, disasterEscIndicator, oldCaseMap);
                uow.commitWork();
        } catch (Exception e) {
            CDdErrorUtilities.publishException('CDdCaseTriggerHelperV2','checkForDisasterPreventionCase', e);
        }
    }

    /**
     * @author      Mahesh Chouhan
     * @date        June 2023
     * @jira        https://doordash.atlassian.net/browse/BASD-43689
     * @description Create Case Note for Disaster Escalation Case on insert
     */
    public static void createDisasterEscalationNote(List<Case> newCaseList, Map<Id, List<String>> disasterEscIndicator, Map<Id,Case> oldCaseMap){
        List<FeedItem> lstCaseFeedItems = new List<FeedItem>();
        Set<Id> caseIds = new Set<Id>();

        for(Case caseRecord : newCaseList){
            if(caseRecord.Disaster_Escalation_Case__c){
                caseIds.add(caseRecord.Id);
            }
        }

        if(caseIds.isEmpty()){
            return;
        }

        for(Id caseId : caseIds){
            String prefix = oldCaseMap.containsKey(caseId) && oldCaseMap.get(caseId).Disaster_Escalation_Case__c ? DISASTER_ESC_ADD_CRITERIA_ERROR
                : DISASTER_ESC_MARKING_CASE_ERROR;
            FeedItem cFeed = new FeedItem();
            cFeed.Title = DISASTER_ESC_CASE_FEED_TITLE;
            cFeed.ParentId = caseId;
            cFeed.Body = disasterEscIndicator != null && disasterEscIndicator.containsKey(caseId) ? prefix + String.join(disasterEscIndicator.get(caseId), '\n')
                : null;
            lstCaseFeedItems.add(cFeed);
        }

        if(!lstCaseFeedItems.isEmpty()){
            CDdGenericPlatformEventHelper.publishEvents(CDdGenericPlatformEventHelper.PlatformEventType.CREATE_CASE_FEED,
                                                    null,JSON.serialize(lstCaseFeedItems));
        }
    }
}