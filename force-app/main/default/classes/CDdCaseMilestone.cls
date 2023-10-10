/**
 * @author Jeremy S. Johnson
 * @date November 2020
 *
 * @description BZAP-9178 Subclass for generating case milestones.
 */
public with sharing class CDdCaseMilestone extends CDdMilestone implements MilestoneInterface {
    /**
     * For each Case, for each applicable Milestone_Template__c, create a
     * Milestone__c.
     *
     * @param caseIds the cases to evaluate for milestones
     */
    public void createMilestones(Set<Id> caseIds) {
        CDdMilestoneGeneratorSetting.createMilestones('Case', caseIds);
    }
    /**
     * BZAP-9351: Update parent Activation_Date__c
     *
     * @param ctx The milestone context object
     */
    public void updateParentStageAndStatus(CDdMilestone.Context ctx) {
        for (Milestone__c m : ctx.newMap.values()) {
            if (m.Milestone_Type__c == 'Activate Store' && m.Status__c == 'Complete' && m.Status__c != ctx.oldMap.get(m.Id).Status__c) {
                Case c = (Case) ctx.parentMap.get(m.ParentId__c);
                c.Activation_Date_2__c = System.now();
            }
        }
    }
    /**
     * BZAP-12228: Create Missing MilesStones when case Origin is updated
     *
     * @param cases : cases being updated,
     *         oldCases : Map of case Id and old case records
     */
    public void createMissingCaseMilestones(List<case> cases, Map<Id, Case> oldCases){
        set<Id> onboardingCases = new set<Id>();
        for(case c: cases){
            if(CDdMxSxConstants.MXSX_MISSING_MILESTONES_UPDATE_RECORDTYPES.contains(c.RecordTypeId) &&
               ((CDdMxSxConstants.MXSX_CASEORIGINS_FOR_MILESTONES.contains(c.Origin) && c.origin != oldCases.get(c.Id).origin) || (c.RecordTypeId != oldCases.get(c.id).RecordTypeid && c.status != CDdSupportConstants.CLOSED_STATUS ))){
                onboardingCases.add(c.Id);
            }
        }
        if(onboardingCases.isEmpty()){
            return;
        }
        createMilestones(onboardingCases);
    }
    /**
     * @description Perform the updates of 'Deliver Tablet' milestones, based on the Status found on the corresponding 'Tablet Request' Case record
     * - Deliver Tablet milestone is one of the child Milestone records, found on the Marketplace Onboarding Case record
     * - Status on the Deliver Tablet milestone is set, based on the Status found on the corresponding 'Tablet Request' Case record for the same Account
     * - Milestone events are published by this method
     *      a) MILESTONE_OPERATION_UPDATE_DELIVER_TABLET is set as the operation in the Milestone Event
     *      a) Case Id of the 'Tablet Request' Case record is set as the Parent SObject Id in the Milestone Event
     * @param List<Case> cases Collection of Case records to process
     * @return
     */
    public static Boolean updateDeliverTabletMilestone(List<Case> cases){
        // It is possible there is more than one instance of tablet request case record for a specific account - unsual occurrence
        Map<Id, List<Case>> tabletRequestCasesForAccountId = new Map<Id, List<Case>>();
        Set<Id> tableRequestCaseAccountIdsToProcess = new Set<Id>();
        List<Milestone_Event__e> milestoneEvents = new List<Milestone_Event__e>();
       	Map<Id, List<Case>> tabletCasesForAccountIdwithOldCases = new Map<Id, List<Case>>();//BASD-35044
        for(Case c : cases){
            if (CDdMxSxConstants.CASE_RECORD_TYPE_ID_TABLET_REQUESTS.equals(c.RecordTypeId)
                    && CDdMxSxConstants.CASE_TABLET_REQUEST_STATUS_TO_PROCESS_FOR_UPDATE_DELIVER_TABLET.contains(c.Status)
                    && String.isNotBlank(c.Request_Type__c) && CDdMxSxConstants.REQUEST_TYPE_FITER_VALUES_UPDATE_DELIVER_TABLET.contains(c.Request_Type__c))
                {
                if (tabletCasesForAccountIdwithOldCases.containsKey(c.AccountId)){
                    tabletCasesForAccountIdwithOldCases.get(c.AccountId).add(c);
                } else {
                    tabletCasesForAccountIdwithOldCases.put(c.AccountId, new List<Case>{c});
                }
            }
        }

        //BASD-35044 added the below logic to find out whether the modified tablet case is the latest created case for the impacted Account
        for(Account a : [Select Id , (Select Id, AccountId, RecordTypeId, Status, Request_Type__c,CreatedDate from Cases
                                        Where RecordTypeId =: CDdMxSxConstants.CASE_RECORD_TYPE_ID_TABLET_REQUESTS
                                        ORDER By CreatedDate DESC Limit 1 ) FROM Account Where Id IN : tabletCasesForAccountIdwithOldCases.keyset()]){
            for(Case exC : tabletCasesForAccountIdwithOldCases.get(a.Id)){
                if(!a.Cases.isEmpty()){
                    if(exC.Id == a.Cases[0].Id){
                        if (tabletRequestCasesForAccountId.containsKey(exC.AccountId)){
                            tabletRequestCasesForAccountId.get(exC.AccountId).add(exC);
                        } else {
                            tabletRequestCasesForAccountId.put(exC.AccountId, new List<Case>{exC});
                        }
                    }
                }
        	}
        }

        // Process Tablet Request Case records for Accounts that meet the criteria within the Milestone records
        for (Milestone__c m: [  SELECT Status__c, Status_Reason__c, Status_Reason_Details__c, Case__r.AccountId, Case__r.Status
                                FROM Milestone__c
                                WHERE RecordTypeId = :CDdMxSxConstants.MILESTONE_RECORD_TYPE_ID_DELIVER_TABLET
                                AND Case__r.RecordTypeId = :CDdMxSxConstants.RECORD_TYPE_ID_CASE_MARKETPLACE_ONBOARDING
                                AND Case__r.AccountId IN :tabletRequestCasesForAccountId.keySet()
                                AND Status__c NOT IN :CDdMxSxConstants.MILESTONE_STATUS_TO_NOT_PROCESS_FOR_UPDATE_DELIVER_TABLET]){
            tableRequestCaseAccountIdsToProcess.add(m.Case__r.AccountId);
        }
        // Prepare Milestone Events for Tablet Request Case records where Account has met the criteria within the Milestone
        // Walkthrough all the Account Ids eligible for processing based on criteria met within the Milestone records
        // Process all input Tablet Request Case records tagged with eligible Account Ids
        // Note - In the Milestone Event, Parent_SObject_Id__c is represented by the Tablet Request Case record Id
        for (Id accountId : tableRequestCaseAccountIdsToProcess){
            for (Case c : tabletRequestCasesForAccountId.get(accountId)){
                milestoneEvents.add(new Milestone_Event__e(Operation__c = CDdMxSxConstants.MILESTONE_EVENT_OPERATION_UPDATE_DELIVER_TABLET, User_Id__c = UserInfo.getUserId(), Parent_SObject_Type__c = CDdMxSxConstants.SOBJECT_TYPE_CASE, Parent_SObject_Id__c = c.Id));
            }
        }
        // Publish the Milestone Events and log any errors
        if (!milestoneEvents.isEmpty()){
            List<Database.SaveResult> sResults = EventBus.publish(milestoneEvents);
            CDdErrorUtilities.publishException(CDdMxSxConstants.SOBJECT_TYPE_CASE , CDdMxSxConstants.MILESTONE_EVENT_OPERATION_UPDATE_DELIVER_TABLET, sResults);
            return true;
        }
        return false;
    }
    /**
     * @description Handle the updates of 'Deliver Tablet' milestones
     * - Deliver Tablet milestone is one of the child Milestone records, found on the Marketplace Onboarding Case record
     * - Status on the Deliver Tablet milestone is set, based on the Status found on the corresponding 'Tablet Request' Case record for the same Account
     * - Parent SObject Id received in the Milestone Event is the Case Id of the 'Tablet Request' Case record
     * @param List<Milestone_Event__e> a Collection of Milestone Events
     * @return
     */
    public static Boolean handleUpdateDeliverTabletMilestoneEvents(List<Milestone_Event__e> milestoneEvents){
        Boolean success = false;
        Set<Id> tabletRequestCaseIdsToProcess = new Set<Id>();
        Map<Id, Case> tabletRequestCaseToProcessForAccountId = new Map<Id, Case>();
        Map<Id, List<Milestone__c>> milestonesToProcessForAccountId = new Map<Id, List<Milestone__c>>();
        List<Milestone__c> milestonesToUpdate = new List<Milestone__c>();
        // Extract the Tablet Request Case record Ids from the Milestone Events
        for (Milestone_Event__e e : milestoneEvents) {
            tabletRequestCaseIdsToProcess.add(e.Parent_SObject_Id__c);
        }
        // Collect all the eligible Tablet Request case records to process along with the corresponding Account Id
        // - Account Ids are collected to retrieve the corresponding Milestone record for Marketplace Onboarding Case from the Milestone Object
        // An Account may have more than one Tablet Request Case. This is considered unusual but needs to be taken into consideration
        //  - more than one instance possible due to opportunity moving in and out of 'Closed Won' stage more than once
        // Retrieve the Tablet Request Case record in descending order of Created Date, to ensure only the most recent Tablet Request Case record
        //   affects the Deliver Tablet milestone record for a specific account
        for(Case c : [  SELECT Id, RecordTypeId, AccountId, Status, Request_Type__c, Rejection_Reason_Details__c
                        FROM Case
                        WHERE Id IN :tabletRequestCaseIdsToProcess
                        AND RecordTypeId = :CDdMxSxConstants.CASE_RECORD_TYPE_ID_TABLET_REQUESTS
                        AND AccountId != NULL
                        AND Status IN :CDdMxSxConstants.CASE_TABLET_REQUEST_STATUS_TO_PROCESS_FOR_UPDATE_DELIVER_TABLET
                        ORDER BY CreatedDate DESC]){
            if (!tabletRequestCaseToProcessForAccountId.containsKey(c.AccountId)){
                tabletRequestCaseToProcessForAccountId.put(c.AccountId, c);
            }
        }
        // An Account may have more than one Marketplace Onboarding Case. This is considered unusual but needs to be taken into consideration
        //  - more than one instance possible due to opportunity moving in and out of 'Closed Won' stage more than once
        // In such a situation, impact Deliver Tablet milestone for all the Marketplace Onboarding Case records for a specific Account,
        //  - ensure the status on the Deliver Tablet milestone (of the Marketplace Onboarding record) qualifies the milestone for processing
        for (Milestone__c m: [  SELECT Status__c, Status_Reason__c, Status_Reason_Details__c, Case__r.AccountId, Case__r.Status
                                FROM Milestone__c
                                WHERE RecordTypeId = :CDdMxSxConstants.MILESTONE_RECORD_TYPE_ID_DELIVER_TABLET
                                AND Case__r.RecordTypeId = :CDdMxSxConstants.RECORD_TYPE_ID_CASE_MARKETPLACE_ONBOARDING
                                AND Case__r.AccountId IN :tabletRequestCaseToProcessForAccountId.keySet()
                                AND Status__c NOT IN :CDdMxSxConstants.MILESTONE_STATUS_TO_NOT_PROCESS_FOR_UPDATE_DELIVER_TABLET]){
            Id accountId = m.Case__r.AccountId;
            if (milestonesToProcessForAccountId.containsKey(accountId)){
                milestonesToProcessForAccountId.get(accountId).add(m);
            } else {
                milestonesToProcessForAccountId.put(accountId, new List<Milestone__c>{m});
            }

        }
        // Prepare Milestones to update
        // 1. Process for each Account Id found in the 'Deliver Tablet' Milestone collection (Milestones to process) with key as Account Id
        // 2. Walkthrough the deliver Tablet milestone records (more than one instance possible) for the specific Account Id
        // 3. Read the corresponding Case record from the 'Tablet Request' Case collection. Use Account Id as key to find the corresponding Tablet Request Case
        // 4. Based on the Status of the 'Tablet Request' Case, set the approproriate Status and Status Reason on the corresponding Milestone record
        // 5. Update the Milestone record, only if the status should be different than what it currently is, exception is Milestone Status 'Blocked'
        //      - exception explained - Status Reason may need to be updated as the Tablet Request status moved from 'Returned to Sender' to 'Dead'
        for (Id accountId : milestonesToProcessForAccountId.keySet()){
            for (Milestone__c m : milestonesToProcessForAccountId.get(accountId)){
                Milestone__c updatedMilestone = getUpdatedDeliverTabletMilestone(tabletRequestCaseToProcessForAccountId.get(accountId), m);
                if (updatedMilestone != null && (!updatedMilestone.Status__c.equals(m.Status__c) || CDdMxSxConstants.MILESTONE_STATUS_BLOCKED.equals(updatedMilestone.Status__c))){
                    milestonesToUpdate.add(updatedMilestone);
                }
            }
        }
        // Perform database update to Deliver Tablet Milestone records and log any errors
        if(!milestonesToUpdate.isEmpty()) {
            List<Database.SaveResult> sResults = Database.update(milestonesToUpdate, false);
            success = CDdErrorUtilities.processSaveResults(sResults).isEmpty();
            CDdErrorUtilities.publishException(CDdMxSxConstants.SOBJECT_TYPE_MILESTONE , CDdMxSxConstants.MILESTONE_EVENT_OPERATION_UPDATE_DELIVER_TABLET, sResults);
        }
        return success;
    }
    /**
     * @description Return an updated instance of the Deliver Tablet milestone record
     * - Based on the Status found on the corresponding 'Tablet Request' Case record for the same Account, following properties are updated on the Milestone record
     * a) Status__c
     * b) Status_Reason__c
     * c) Status_Reason_Details__c
     * @param Case input Tablet Request Case record
     * @param Milestone__c input Deliver Tablet Milestone record
     * @return Milestone__c an updated instance of the Deliver Tablet milestone record
     */
    public static Milestone__c getUpdatedDeliverTabletMilestone(Case tabletRequestCase, Milestone__c deliverTabletMilestone){
        switch on (tabletRequestCase.Status){
            when 'Shipped', 'Approved', 'Opened', 'Reopened' {
                return new Milestone__c(Id = deliverTabletMilestone.Id, Status__c = CDdMxSxConstants.MILESTONE_STATUS_IN_PROGRESS, Status_Reason__c = null);
            }
            when 'Received' {
                return new Milestone__c(Id = deliverTabletMilestone.Id, Status__c = CDdMxSxConstants.MILESTONE_STATUS_COMPLETE, Status_Reason__c = null);
            }
            when 'Returned to Sender' {
                return new Milestone__c(Id = deliverTabletMilestone.Id, Status__c = CDdMxSxConstants.MILESTONE_STATUS_BLOCKED, Status_Reason__c = CDdMxSxConstants.MILESTONE_STATUS_REASON_RETURN_TO_SENDER);
            }
            when 'Dead' {
                return new Milestone__c(Id = deliverTabletMilestone.Id, Status__c = CDdMxSxConstants.MILESTONE_STATUS_BLOCKED, Status_Reason__c = CDdMxSxConstants.MILESTONE_STATUS_REASON_NO_RESPONSE, Status_Reason_Details__c = CDdMxSxConstants.MILESTONE_STATUS_REASON_DETAILS_FOR_NO_RESPONSE);
            }
            when 'Rejected' {
                return new Milestone__c(Id = deliverTabletMilestone.Id, Status__c = CDdMxSxConstants.MILESTONE_STATUS_BLOCKED, Status_Reason__c = CDdMxSxConstants.MILESTONE_STATUS_REASON_TABLET_CASE_REJECTED, Status_Reason_Details__c = tabletRequestCase.Rejection_Reason_Details__c);
            }
            when else { return null; }
        }
    }
}