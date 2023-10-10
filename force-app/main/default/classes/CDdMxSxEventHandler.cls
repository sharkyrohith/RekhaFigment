/********************************************************************************************************************
* @author Sriram
* @date 11/07/2021
*
* @group Merchant Services
*
* @description Apex class that handles Merchant Services events
*
**************************************************************************************************************************************/
public class CDdMxSxEventHandler {
    /**
     * @description Handle events - opportunity closed won
     * @param Set<Id> opportunityIds
     * @return
    */
    public static void handleEventsOpportunityClosedWon(Set<Id> opportunityIds) {
        CDdMxSxParentAccountHelper.createParentAccountsForOpportunityIds(opportunityIds);
        CDdMxSxOpportunityCaseHelper helper = new CDdMxSxOpportunityCaseHelper(opportunityIds);
        helper.createStorefrontOnboardingCases();
        helper.createPosActivationCases();
        CDdMxSxSegmentNotificationHelper.handleSegmentNotificationForOpportunityClosedWonEvents(opportunityIds);
        CDdMxOnboardingMxSxEventHandler.handleOpportunityUpdates(opportunityIds);
    }
    /**
     * @description Handle events - opportunity related case updates
     * @param Set<Id> opportunityIds
     * @return
    */
    public static void handleEventsOpportunityRelatedCaseUpdates(Set<Id> opportunityIds) {
        CDdMxSxOpportunityCaseHelper helper = new CDdMxSxOpportunityCaseHelper(opportunityIds);
        helper.updateCases();
    }
    /**
     * @description Handle events - store active
     * @param Set<Id> parentAccountIds
     * @return
    */
    public static void handleEventsStoreActive(Set<Id> parentAccountIds) {
        CDdMxSxCaseHelper.updateStorefrontOnboardingCaseToActiveQueue(parentAccountIds);
    }
    /**
     * @description Handle events - Setup Banking Blocked, Setup Menu Blocked
     * @param Set<Id> mileStoneIds
     * @param String eventName
     * @return
    */
    public static void handleEventsMileStoneBlocked(Set<Id> mileStoneIds, String eventName) {
        CDdMxSxSegmentNotificationHelper.handleSegmentNotificationForMilestoneBlockedEvents(mileStoneIds);
        CDdMxOrderMxSxEventHandler.handleMilestoneEvent(mileStoneIds);
        CDdMxOnboardingMxSxEventHandler.handleMilestoneEvent(mileStoneIds);
    }
    /**
     * @description Handle events - Milestone Complete
     * @param Set<Id> mileStoneIds
     * @return
    */
    public static void handleEventsMileStoneComplete(Set<Id> mileStoneIds) {
        CDdMxOrderMxSxEventHandler.handleMilestoneEvent(mileStoneIds);
        CDdMxOnboardingMxSxEventHandler.handleMilestoneEvent(mileStoneIds);
        CDdMxSxProductLineItemHandler.handleMilestoneCompletedForProductLineItemUpdates(mileStoneIds);
        CDdMxSxSegmentNotificationHelper.handleSegmentNotificationForMilestoneCompletedEvents(mileStoneIds);
    }
     /**
     * @description Handle events - Milestone In Progress
     * @param Set<Id> mileStoneIds
     * @return
    */
    public static void handleEventsMileStoneInProgress(Set<Id> mileStoneIds) {
        CDdMxOnboardingMxSxEventHandler.handleMilestoneEvent(mileStoneIds);
    }
    /**
     * @description Handle events - Milestone In Dead
     * @param Set<Id> mileStoneIds
     * @return
    */
    public static void handleEventsMileStoneInDead(Set<Id> mileStoneIds) {
        CDdMxOnboardingMxSxEventHandler.handleMilestoneEvent(mileStoneIds);
    }
    /**
     * @description Handle events - Table Case Shipped
     * @param Set<Id> CaseIds
     * @return
    */
    public static void handleEventsTabletCaseShipped(Set<Id> CaseIds) {
        CDdMxSxSegmentNotificationHelper.handleSegmentNotificationForTabletCaseShipped(CaseIds);
    }

    /**
     * @description Handle events - Table Case Received
     * @param Set<Id> CaseIds
     * @return
    */
    public static void handleEventsTabletCaseReceived(Set<Id> CaseIds) {
        CDdMxSxSegmentNotificationHelper.handleSegmentNotificationForTabletCaseReceived(CaseIds);
    }
    /**
     * @description Handle events - Send Mx Order to Vendor
     * @param String sObjectType - valid values are 'Case', 'Mx_Order__c'
     * @param Set<Id> sObjectIds
     * @return
    */
    public static void handleEventsSendMxOrderToVendor(String sObjectType, Set<Id> sObjectIds) {
        CDdMxOrderMxSxEventHandler.handleSendMxOrderToVendorEvent(sObjectType, sObjectIds);
    }

    /**
        @author: Dan Thoreson
        @date: 09-Dec-2022
        @description: Handles Events triggered by POS Integrations Cases when its Status is changed.
    **/
    public static void handleEventsPosIntegrationStatusUpdate(Set<Id> caseIds) {
        CDdMxSxCaseHelper.handlePosIntegrationCaseStatusUpdate(caseIds);
    }

    /**
    * @description Handle events - UpdateType = 'Inbound' on MxOnboarding Records (Update happening from MxPortal)
    * @param Set<Id> sObjectIds
    * @return
   */
   public static void handleEventsMxOnboardingStatusEvent(Set<Id> sObjectIds) {
        CDdMxOnboardingProcessor mxOnbPro = new CDdMxOnboardingProcessor(sObjectIds);
        mxOnbPro.execute();
   }
    /**
     * @description Handle events - Update order from Account
     * @param Set<Id> AccountIds
     * @return
   */
   public static void handleOrderUpdatesFromAccount(Set<Id> accountids) {
    CDdMxOrderAccountHelper.handleOrderUpdatesFromAccount(accountids);
   }
   /**
    * @description BZAP-18321 Handle events: Marketplace Onboarding Cases Insert
    * @param Set<Id> caseids
    * @return
   */
    public static void handleEventsForMarketplaceOnboardingCaseInsert(Set<Id> caseIds) {
        CDdMxOnboardingMxSxEventHandler.handleEventsForMarketplaceOnboardingCaseInsert(caseIds);
    }
    /**
    * @description: Handles the MxSx Events of Type POS_INTEGRATION_REQUEST_FROM_BAT.
    * @param Set<Id> posIntegrationRequestsIds
    * @return
    **/
    public static void handleEventsForPosIntegrationRequestsFromBat(Set<String> onboardingIds) {
        CDdMxPosIntegrationRequestProcessor processPosRequests = new CDdMxPosIntegrationRequestProcessor(onboardingIds);
        processPosRequests.execute();
    }
    /**
    * @description BZAP-19069 Handle events: Caviar Onboarding Case Update
    * @param Set<Id> caseids
    * @return
    */
    public static void handleEventsForCaviarOnboardingCaseUpdate(Set<Id> caseIds) {
        CDdMxSxTurboChargeHandler mxSxTurboChargeHandler = new CDdMxSxTurboChargeHandler(caseIds);
        mxSxTurboChargeHandler.performUpdates();
    }

    /**
        @author: Dan Thoreson
        @date: 22-Dec-2022
        @description: Handles the MxSx Events of Type POS_INTEGRATION_REQUEST.
    **/
    public static void handleEventsForPosRequests(List<MxSx_Event__e> mxSxEvents) {
        CDdMxPosRequestEventHandler.unpackPosRequestEvents(mxSxEvents);
    }
}