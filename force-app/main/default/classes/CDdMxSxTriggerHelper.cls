/********************************************************************************************************************
* @author Sriram
* @date 11/11/2021
*
* @group Merchant Services
*
* @description Apex trigger helper class that determines what Merchant Services events to publish         
* 
**************************************************************************************************************************************/
public class CDdMxSxTriggerHelper {
    public static Boolean ranPublishEventsStoreActive = false;
    public static Boolean ranPublishEventsOpportunityClosedWon = false;
    public static Boolean ranPublishEventsOpportunityRelatedCaseUpdates = false;
    public static Boolean ranPublishEventsForMilestoneUpdate = false;
    public static Boolean ranPublishEventsForMxOnboardingStatusUpdate = false;
    /**
     * @description Process Account records
     * @param List<Account> Trigger.new a list of new Account records
     * @param Map<Id, Account> Trigger.oldMap a Map of old Account records
     * @return    
    */
    public static void processAccounts(List<Account> newList, Map<Id, Account> oldMap) {
        if (!CDdMxSxConstants.ENABLE_MXSX_FRAMEWORK) { return; }
        if (Trigger.isAfter){
            performAfterTriggerEventsForAccounts(newList, oldMap);
        }
    }
    /**
     * @description Process Opportunity records
     * @param List<Opportunity> Trigger.new a list of new Opportunity records
     * @param Map<Id, Opportunity> Trigger.oldMap a Map of old Opportunity records
     * @param Map<Id, Account> Related Accounts on the Opportunity records
     * @return    
    */
    public static void processOpportunities(List<Opportunity> newList, Map<Id, Opportunity> oldMap, Map<Id, Account> accounts) {
        if (!CDdMxSxConstants.ENABLE_MXSX_FRAMEWORK) { return; }
        if (Trigger.isAfter){
            performAfterTriggerEventsForOpportunities(newList, oldMap, accounts);
        }
        if (Trigger.isBefore){
            performBeforeTriggerEventsForOpportunities(newList, oldMap, accounts);
        }
    }
    /**
     * @description Process Milestone records
     * @param List<Milestone__c> Trigger.new a list of new Milestone__c records
     * @param Map<Id, Milestone__c> Trigger.oldMap a Map of old Milestone__c records
     * @return    
    */
    public static void processMilestones(List<Milestone__c> newList, Map<Id, Milestone__c> oldMap) {
        if (!CDdMxSxConstants.ENABLE_MXSX_FRAMEWORK) { return; }
        if (Trigger.isAfter){
            performAfterTriggerEventsForMilestones(newList, oldMap);
        }
    }
    /**
     * @description Perform after trigger events for Account records
     * @param List<Account> Trigger.new a list of new Account records
     * @param Map<Id, Account> Trigger.oldMap a Map of old Account records
     * @return    
    */
    public static void performAfterTriggerEventsForAccounts(List<Account> newList, Map<Id, Account> oldMap) {
        if (Trigger.isAfter){
             Set<Id> storeActiveParentAccountIds = new Set<Id>();
             Set<Id> accountIdsForOrderUpdate = new Set<Id>();
             for (Account newObj : newList){
                if (CDdMxSxConstants.MXSX_STORE_ACCOUNT_RECORD_TYPE_IDS.contains(newObj.RecordTypeId)){
                    if (String.isNotBlank(newObj.ParentId) && 'Yes'.equals(newObj.Currently_Active__c) && 'Yes'.equals(newObj.Is_Partner__c)){
                        storeActiveParentAccountIds.add(newObj.ParentId);
                    }
                    if(oldMap != null && oldMap.containsKey(newObj.Id) && hasFieldValueChanged(newObj,oldMap.get(newObj.Id),CDdMxSxConstants.ACCOUNT_FIELD_API_NAMES_FOR_ORDER_EVENTS)){
                        accountIdsForOrderUpdate.add(newObj.Id);
                    }
                }
        	}
            if (!accountIdsForOrderUpdate.isEmpty()){
            	CDdMxSxEventPublisher.publishEventsForAccountToOrderUpdate(CDdMxSxConstants.SOBJECT_TYPE_ACCOUNT, accountIdsForOrderUpdate);
            }
            if(!storeActiveParentAccountIds.isEmpty()){
            	publishEventsStoreActive(storeActiveParentAccountIds);
            }
        }
    }
    /**
     * @description Perform after trigger events for Opportunity records
     * @param List<Opportunity> Trigger.new a list of new Opportunity records
     * @param Map<Id, Opportunity> Trigger.oldMap a Map of old Opportunity records
     * @param Map<Id, Account> Related Accounts on the Opportunity records
     * @return    
    */
    public static void performAfterTriggerEventsForOpportunities(List<Opportunity> newList, Map<Id, Opportunity> oldMap, Map<Id, Account> accounts) {
        if (Trigger.isAfter){
            publishEventsOpportunityClosedWon(newList, oldMap, accounts);
            if (Trigger.isUpdate){
                publishEventsOpportunityRelatedCaseUpdates(newList, oldMap, accounts);
            }            
        }
    }
    /**
     * @description Perform Before trigger events for Opportunity records
     * @param List<Opportunity> Trigger.new a list of new Opportunity records
     * @param Map<Id, Opportunity> Trigger.oldMap a Map of old Opportunity records
     * @return    
    */
    public static void performBeforeTriggerEventsForOpportunities(List<Opportunity> newList, Map<Id, Opportunity> oldMap, Map<Id, Account> accounts) {
        if (Trigger.isBefore){
            CDdMxSxValidationHelper validationHelper = new CDdMxSxValidationHelper();
            CDdMxSxOpportunityTriggerUpdateHelper opportunityTriggerUpdateHelper = new CDdMxSxOpportunityTriggerUpdateHelper();
            if (Trigger.isInsert){
                opportunityTriggerUpdateHelper.applyUpdates(newList, oldMap, accounts);    
            }
            if (Trigger.isUpdate){
                validationHelper.runMxSxOpportunityValidations(newList, oldMap, accounts);
                opportunityTriggerUpdateHelper.applyUpdates(newList, oldMap, accounts);
            }
        }
    }
    /**
     * @description Perform After trigger events for Milestone records
     * @param List<Milestone__c> Trigger.new a list of new Milestone records
     * @param Map<Id, Milestone__c> Trigger.oldMap a Map of old Milestone records
     * @return    
    */
    public static void performAfterTriggerEventsForMilestones(List<Milestone__c> newList, Map<Id, Milestone__c>  oldMap){
        if (Trigger.isAfter){
            publishEventsForMilestoneUpdate(newList, oldMap);
        }
    }
    /**
     * @description Perform after trigger events for MxOnboarding records
     * @param List<Mx_Onboarding__c> Trigger.new a list of new MxOnboarding records
     * @param Map<Id, Mx_Onboarding__c> Trigger.oldMap a Map of old MxOnboarding records
     * @return    
    */
    public static void performAfterTriggerEventsForMxOnboarding(List<Mx_Onboarding__c> newList, Map<Id, Mx_Onboarding__c> oldMap) {
        if (Trigger.isAfter){
            publishEventsForMxOnboardingUpdateInbound(newList, oldMap);
        }
    }
    /**
     * @description Perform events related to Store Account activated
     * @param List<Account> Trigger.new a list of new Account records
     * @param Map<Id, Account> Trigger.oldMap a Map of old Account records
     * @return    
    */
    public static void publishEventsStoreActive(Set<Id> storeActiveParentAccountIds) {
        if ( ranPublishEventsStoreActive ) { return; }
        Set<Id> parentAccountIdsToProcess = new Set<Id>();
        CDdMxSxParentAccountHelper parentAccountHelper = new CDdMxSxParentAccountHelper(storeActiveParentAccountIds);
        for (Id storeActiveParentAccountId : storeActiveParentAccountIds){
            if (parentAccountHelper.hasActiveStorefrontOnboardingCaseInHoldingQueue(storeActiveParentAccountId, null)){
                parentAccountIdsToProcess.add(storeActiveParentAccountId);
            }
        }
        if (!parentAccountIdsToProcess.isEmpty()){        
            CDdMxSxEventPublisher.publishEventsStoreActive(parentAccountIdsToProcess);
        }
        ranPublishEventsStoreActive = true;
    }
    /**
     * @description Publish events related to Opportunity Closed Won
     * @param List<Opportunity> Trigger.new a list of new Opportunity records
     * @param Map<Id, Opportunity> Trigger.oldMap a Map of old Opportunity records
     * @param Map<Id, Account> Related Accounts on the Opportunity records
     * @return    
    */
    public static void publishEventsOpportunityClosedWon(List<Opportunity> newList, Map<Id, Opportunity> oldMap, Map<Id, Account> accounts) {
        if ( ranPublishEventsOpportunityClosedWon ) { return; }
        Set<Id> closedWonOpportunityIds = new Set<Id>();
        for (Opportunity newObj : newList){
            Account account = String.isNotBlank(newObj.AccountId) ? accounts.get(newObj.AccountId) : null;
            if (account != null 
                && (!account.Is_Test_Store__c)
                && CDdMxSxConstants.MXSX_OPPORTUNITY_RECORD_TYPE_IDS.contains(newObj.RecordTypeId)){
                if (CDdMxSxConstants.OPPORTUNITY_STAGE_CLOSED_WON.equals(newObj.StageName) 
                    && newObj.CloseDate != null 
                    && newObj.CloseDate >= CDdMxSxConstants.OPPORTUNITY_CLOSE_DATE_CUTOVER 
                    && !CDdMxSxConstants.OPPORTUNITY_CLOSED_WON_TYPES_TO_EXCLUDE.contains(newObj.Type)){
                    closedWonOpportunityIds.add(newObj.Id);
                }
            }
        }
        ranPublishEventsOpportunityClosedWon = CDdMxSxEventPublisher.publishEventsOpportunityClosedWon(closedWonOpportunityIds);
    }
    /**
     * @description Publish events opportunity related Case Updates
     * @param List<Opportunity> Trigger.new a list of new Opportunity records
     * @param Map<Id, Opportunity> Trigger.oldMap a Map of old Opportunity records
     * @param Map<Id, Account> Related Accounts on the Opportunity records
     * @return    
    */
    public static void publishEventsOpportunityRelatedCaseUpdates(List<Opportunity> newList, Map<Id, Opportunity> oldMap, Map<Id, Account> accounts) {
        if ( ranPublishEventsOpportunityRelatedCaseUpdates ) { return; }
        Set<Id> opportunityIds = new Set<Id>();
        for (Opportunity newObj : newList){
            Opportunity oldObj = (oldMap != null) ? oldMap.get(newObj.Id) : null;
            if (CDdMxSxConstants.MXSX_OPPORTUNITY_RECORD_TYPE_IDS.contains(newObj.RecordTypeId)){
                if (CDdMxSxConstants.OPPORTUNITY_STAGE_CLOSED_WON.equals(newObj.StageName)
                    && hasFieldValueChanged(newObj, oldObj, CDdMxSxConstants.OPPORTUNITY_RELATED_CASE_UPDATES_API_NAMES)){
                    opportunityIds.add(newObj.Id);
                }
            }
        }
        ranPublishEventsOpportunityRelatedCaseUpdates = CDdMxSxEventPublisher.publishEventsOpportunityRelatedCaseUpdates(opportunityIds);
    }       
    /**
     * @description Perform events related to Milestone Status Change
     * Relevant Status are Blocked, Complete, In Progress, Dead
     * @param List<Milestone__c> Trigger.new a list of new Milestone__c records
     * @param Map<Id, Milestone__c> Trigger.oldMap a Map of old Milestone__c records
     * @return    
    */
    public static void publishEventsForMilestoneUpdate(List<Milestone__c> newList, Map<Id, Milestone__c> oldMap) {
        if ( ranPublishEventsForMilestoneUpdate ) { return; }
        Set<Id> milestoneIdsBlocked = new Set<Id>();
        Set<Id> milestoneIdsComplete = new Set<Id>();
        Set<Id> milestoneIdsInProgress = new Set<Id>();
        Set<Id> milestoneIdsInDead = new Set<Id>();  
        for (Milestone__c newObj : newList){
            Milestone__c oldObj = (oldMap != null) ? oldMap.get(newObj.Id) : null;
            if (hasFieldValueChanged(newObj, oldObj, CDdMxSxConstants.MILESTONE_MXSX_EVENTS_API_NAMES)){
                if (CDdMxSxConstants.MILESTONE_STATUS_BLOCKED.equals(newObj.Status__c)){
                    milestoneIdsBlocked.add(newObj.Id);
                }
                if (CDdMxSxConstants.MILESTONE_STATUS_COMPLETE.equals(newObj.Status__c)){
                    milestoneIdsComplete.add(newObj.Id);
                }
                if (CDdMxSxConstants.MILESTONE_STATUS_IN_PROGRESS.equals(newObj.Status__c)){
                    milestoneIdsInProgress.add(newObj.Id);
                }
                if (CDdMxSxConstants.MILESTONE_STATUS_DEAD.equals(newObj.Status__c)){
                    milestoneIdsInDead.add(newObj.Id);
                }
            }
        }
        CDdMxSxEventPublisher.publishEventsMilestonesBlocked(milestoneIdsBlocked);
        CDdMxSxEventPublisher.publishEventsMilestonesComplete(milestoneIdsComplete);
        CDdMxSxEventPublisher.publishEventsMilestonesInProgress(milestoneIdsInProgress);
        CDdMxSxEventPublisher.publishEventsMilestonesInDead(milestoneIdsInDead);
        ranPublishEventsForMilestoneUpdate = true;
    }          
    /**
     * @description has the field value changed on ANY ONE of the field api names on the Sobject record
     * Note: This method returns true if the old Sobject record is null 
     * i.e. insert trigger event where the old Sobject record does not exist
     * @param Sobject new Sobject record
     * @param Sobject old Sobject record
     * @param Set<String> field api names 
     * @return Boolean has the field value changed on the Sobject record? true or false
     */
    public static Boolean hasFieldValueChanged(Sobject newSobject, Sobject oldSobject, Set<String> fieldApiNames){
        for (String fieldApiName : fieldApiNames){
            if (hasFieldValueChanged(newSobject, oldSobject, fieldApiName)){
                return true;
            }
        }
        return false;
    }
    /**
    * @description Perform events related to Mx_Onboarding__c UpdateType = 'Inbound'
    * Relevant Status are Blocked, Complete, In Progress, Dead
    * @param List<Mx_Onboarding__c> Trigger.new a list of new Mx_Onboarding__c records
    * @param Map<Id, Mx_Onboarding__c> Trigger.oldMap a Map of old Mx_Onboarding__c records
    * @return   
    */
    public static void publishEventsForMxOnboardingUpdateInbound(List<Mx_Onboarding__c> newList, Map<Id, Mx_Onboarding__c> oldMap) {
       if ( ranPublishEventsForMxOnboardingStatusUpdate ) { return; }
       Set<Id> mxOnboardingIDs = new Set<Id>();
       for (Mx_Onboarding__c newObj : newList){
               if (CDdMxSxConstants.MX_ONBOARDING_MX_PORTAL_UPDATE_TYPE_INBOUND.equals(newObj.UpdateType__c)){
                    mxOnboardingIDs.add(newObj.Id);
               }
       }
       CDdMxSxEventPublisher.publishEventsForMxOnboardingUpdateInbound(mxOnboardingIDs);
       ranPublishEventsForMxOnboardingStatusUpdate = true;
    }   
    /**
     * @description has the field value changed on the Sobject record
     * Note: This method returns true if the old Sobject record is null 
     * i.e. insert trigger event where the old Sobject record does not exist
     * @param Sobject new Sobject record
     * @param Sobject old Sobject record
     * @param String field api name 
     * @return Boolean has the field value changed on the Opportunity record? true or false
     */
    public static Boolean hasFieldValueChanged(Sobject newSobject, Sobject oldSobject, String fieldApiName){
        return (oldSobject == null)
            ||
            (newSobject.get(fieldApiName) != null && oldSobject.get(fieldApiName) == null)
            ||
            (newSobject.get(fieldApiName) == null && oldSobject.get(fieldApiName) != null)
            ||
            (newSobject.get(fieldApiName) != oldSobject.get(fieldApiName));
    }        
}