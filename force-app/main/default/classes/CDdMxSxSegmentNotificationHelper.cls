/********************************************************************************************************************
* @author Veera
* @date 06/29/2022
*
* @group Merchant Services
*
* @description Apex class to process MX Service events and sends data for Segment Event creation in CDdMxSxSegmentHelper class       
* 
**************************************************************************************************************************************/
public with sharing class CDdMxSxSegmentNotificationHelper {
    
    public static CDdSchemaUtils.MileStoneRT MileStoneRT = new CDdSchemaUtils.MileStoneRT();
    public static CDdMxSxSegmentHelper segmentHelper = new CDdMxSxSegmentHelper();

    public static Set<String> DECK_RANKS_TO_EXCLUDE = new Set<String>{
        CDdMxSxConstants.DECK_RANK_ACE_OF_SPADES,
        CDdMxSxConstants.DECK_RANK_KING_OF_SPADES
    };
    
    public static final List<String> ELIGIBLE_CASE_REQUEST_TYPES = new List<String>{
        'Ship to Merchant (New Tablet)', 
        'Ship to Merchant (New Tablet, Printer)',
        'Ship to Merchant (New Tablet, Printer, Return Label)'
    };     

    /**
     * @description Handle SegmentNotification For Opportunity ClosedWon Events
     * @param Set<Id> opportunityIds
     * @return    
    */
    public static void handleSegmentNotificationForOpportunityClosedWonEvents(Set<Id> opportunityIds){
        Set<Id> opportunityIdsForSegmentNotifications = new Set<Id>();
        for (Opportunity oppty : getOpportunities(opportunityIds)) {
                if (isOpportunityEligibleForSegmentNotification(oppty)){
                        opportunityIdsForSegmentNotifications.add(oppty.Id);
                }
        }
        if (!opportunityIdsForSegmentNotifications.isEmpty()) {
            segmentHelper.handleSegmentEvents(opportunityIdsForSegmentNotifications, CDdMxSxConstants.MXSX_SEGMENT_NOTIFICATION_EVENTS.OPPORTUNITY_CLOSED_WON.name());
        }
        
    }

    /**
     * @description Handle Segment Notification For Milestone Completed Events
     * @param Set<Id> milestoneIds
     * @return    
    */
    public static void handleSegmentNotificationForMilestoneCompletedEvents(Set<Id> milestoneIds){
        Set<Id> notificationEligibleMilestoneIds = new Set<Id>();
        for(Milestone__c milestone : getMilestones(milestoneIds)){
            if (isMilestoneEligibleForSegmentNotification(milestone)) {
                notificationEligibleMilestoneIds.add(milestone.Id);
            }
        }
        if(!notificationEligibleMilestoneIds.isEmpty()){       
            segmentHelper.handleSegmentEvents(notificationEligibleMilestoneIds, CDdMxSxConstants.MXSX_SEGMENT_NOTIFICATION_EVENTS.MILESTONE_COMPLETED.name());
        }
    }

    /**
     * @description Handle Segment Notification For Milestone Blocked Events
     * @param Set<Id> milestoneIds
     * @return    
    */
    public static void handleSegmentNotificationForMilestoneBlockedEvents(Set<Id> milestoneIds){
        Set<Id> notificationEligibleMilestoneIds = new Set<Id>();
        for(Milestone__c milestone : getMilestones(milestoneIds)){
            if (isMilestoneEligibleForSegmentNotification(milestone)) {
                notificationEligibleMilestoneIds.add(milestone.Id);
            }
        }
        if(!notificationEligibleMilestoneIds.isEmpty()){       
            segmentHelper.handleSegmentEvents(notificationEligibleMilestoneIds, CDdMxSxConstants.MXSX_SEGMENT_NOTIFICATION_EVENTS.MILESTONE_BLOCKED.name());
        }
    }

    /**
     * @description Handle Segment Notification For Tablet Case Shipped
     * @param Set<Id> caseIds
     * @return    
    */
    public static void handleSegmentNotificationForTabletCaseShipped(Set<Id> caseIds){
        Set<Id> notificationEligibleCaseIds = new Set<Id>();
        for(Case caseRec : getCases(caseIds)){
            if (isCaseEligibleForSegmentNotification(caseRec)) {
                notificationEligibleCaseIds.add(caseRec.Id);
            }
        }        
        if (!notificationEligibleCaseIds.isEmpty()) {
            segmentHelper.handleSegmentEvents(notificationEligibleCaseIds, CDdMxSxConstants.MXSX_SEGMENT_NOTIFICATION_EVENTS.TABLET_CASE_SHIPPED.name());
        }
        
    }

    /**
     * @description Handle Segment Notification For Tablet Case Received
     * @param Set<Id> milestoneIds
     * @return    
    */
    public static void handleSegmentNotificationForTabletCaseReceived(Set<Id> caseIds){
        Set<Id> notificationEligibleCaseIds = new Set<Id>();
        for(Case caseRec : getCases(caseIds)){
            if (isCaseEligibleForSegmentNotification(caseRec)) {
                notificationEligibleCaseIds.add(caseRec.Id);
            }
        }        
        if (!notificationEligibleCaseIds.isEmpty()) {
            segmentHelper.handleSegmentEvents(notificationEligibleCaseIds,CDdMxSxConstants.MXSX_SEGMENT_NOTIFICATION_EVENTS.TABLET_CASE_RECEIVED.name());
        }  
    }

    /**
     * @description check if Case is meeting criteria to send segment notification
     * @param Case caseRec 
     * @return Boolean
    */
    private static Boolean isCaseEligibleForSegmentNotification(Case caseRec){
        if (caseRec.Opportunity_Name__c != null
            && ELIGIBLE_CASE_REQUEST_TYPES.contains(caseRec.Request_Type__c)
            && (caseRec.Account.Business_ID__c == null || caseRec.Account.Business_ID__c <> 393499)
            && CDdMxSxConstants.RECORD_TYPE_ID_OPPORTUNITY_MARKETPLACE.equals(caseRec.Opportunity_Name__r.RecordTypeId) 
            && !isEnterpriseAccount(caseRec.Account)){
                return true;
        }
        return false;
    }

    /**
     * @description check if Closed Won Opportunity is meeting criteria to send segment notification
     * @param Opportunity oppty 
     * @return Boolean
    */
    public static Boolean isOpportunityEligibleForSegmentNotification(Opportunity opportunity){
        if (CDdMxSxConstants.RECORD_TYPE_ID_OPPORTUNITY_MARKETPLACE.equals(opportunity.RecordTypeId)
            && String.isNotBlank(opportunity.AccountId)
            && CDdMxSxConstants.OPPORTUNITY_LIVE_REGION.equalsIgnoreCase(opportunity.Region_Type__c)
            && !CDdMxSxConstants.OPPORTUNITY_PLATFORM_CAVIER.equals(opportunity.Platform__c)
            && !CDdMxSxConstants.OPPORTUNITY_CLOSED_WON_TYPES_TO_EXCLUDE.contains(opportunity.Type)
            && !CDdMxSxConstants.RECORD_TYPE_ID_ACCOUNT_ENTERPRISE_MARKETPLACE.equals(opportunity.Account.RecordTypeId)
            && !DECK_RANKS_TO_EXCLUDE.contains(opportunity.Account.Deck_Rank__c)
            && !DECK_RANKS_TO_EXCLUDE.contains(opportunity.Account.Launch_Deck_Rank__c)
            && !opportunity.CreatedBy.LastName.contains('Self-Serve')){
                return true;
        }
        return false;
    }

    /**
     * @description check if Milestone is meeting criteria to send segment notification
     * @param Milestone__c milestone 
     * @return Boolean
    */
    private static Boolean isMilestoneEligibleForSegmentNotification(Milestone__c milestone){
        if (CDdMxSxConstants.RECORD_TYPE_ID_OPPORTUNITY_MARKETPLACE.equals(milestone.Case__r?.Opportunity_Name__r?.RecordTypeId) 
            && !isEnterpriseAccount(milestone.Case__r?.Account)){
                return true;
        }
        return false;
    }

    /**
     * @description check if account Is Enterprise Account
     * @param Account acc 
     * @return Boolean
    */
       public static Boolean isEnterpriseAccount(Account acc){
        if (acc.RecordTypeId == CDdMxSxConstants.RECORD_TYPE_ID_ACCOUNT_ENTERPRISE_MARKETPLACE ||
            acc.Deck_Rank__c == CDdMxSxConstants.DECK_RANK_ACE_OF_SPADES || acc.Deck_Rank__c == CDdMxSxConstants.DECK_RANK_KING_OF_SPADES ||
            acc.Launch_Deck_Rank__c == CDdMxSxConstants.DECK_RANK_ACE_OF_SPADES || acc.Launch_Deck_Rank__c == CDdMxSxConstants.DECK_RANK_KING_OF_SPADES){
                return true;
        }
        return false;
}

    /**
     * @description get Opportunities by opportunityIds
     * @param Set<Id> opportunityIds 
     * @return List<Opportunity>
    */
    public static List<Opportunity> getOpportunities(Set<Id> opportunityIds){
        return [SELECT Id, RecordTypeId, Order_Protocol__c, AccountId, Region_Type__c, Platform__c, Type, 
                Account.RecordTypeId, Account.Deck_Rank__c, Account.Launch_Deck_Rank__c, 
                CreatedBy.LastName
                FROM Opportunity
                WHERE Id IN :opportunityIds];
     }

    /**
     * @description get Cases by caseIds
     * @param Set<Id> caseIds 
     * @return List<Case>
    */
    public static List<Case> getCases(Set<Id> caseIds){
        return [SELECT Id, RecordTypeId, Request_Type__c, Opportunity_Name__c, Opportunity_Name__r.RecordTypeId, Status, Language__c,
                Account.BillingCountry, Account.BillingCountryCode, Account.Business_ID__c, Account.Deck_Rank__c, Account.Launch_Deck_Rank__c, Account.RecordTypeId
                FROM Case 
                WHERE Id IN :caseIds];
    }

    /**
     * @description get Milestone by MilestoneIds
     * @param Set<Id> milestoneIds 
     * @return List<Milestone__c>
    */
   public static List<Milestone__c> getMilestones(Set<Id> milestoneIds){
        return [SELECT Id, RecordTypeId, Case__r.Account.Deck_Rank__c, Case__r.Account.Launch_Deck_Rank__c, Case__r.Account.RecordTypeId, Case__r.Opportunity_Name__r.RecordTypeId
                FROM Milestone__c 
                WHERE Id IN :milestoneIds];
    }
}