/********************************************************************************************************************
* @author Sriram
* @date 11/08/2021
*
* @group Merchant Services
*
* @description Apex class that publishes Merchant Services events
*
**************************************************************************************************************************************/
public class CDdMxSxEventPublisher {
    /**
     * @description Publish events - opportunity closed won
     * @param Set<Id> opportunityIds
     * @return Boolean
    */
    public static Boolean publishEventsOpportunityClosedWon(Set<Id> opportunityIds) {
        if (opportunityIds == null || opportunityIds.isEmpty() ) { return false; }
        List<MxSx_Event__e> events = new List<MxSx_Event__e>();
        for (Id opportunityId : opportunityIds){
            events.add(getNewInstanceMxSxEvent(CDdMxSxConstants.MXSX_EVENT.OPPORTUNITY_CLOSED_WON, CDdMxSxConstants.SOBJECT_TYPE_OPPORTUNITY, opportunityId));
        }
        Eventbus.publish(events);
        return true;
    }
    /**
     * @description Publish events - opportunity related case updates
     * @param Set<Id> opportunityIds
     * @return Boolean
    */
    public static Boolean publishEventsOpportunityRelatedCaseUpdates(Set<Id> opportunityIds) {
        if (opportunityIds == null || opportunityIds.isEmpty() ) { return false; }
        List<MxSx_Event__e> events = new List<MxSx_Event__e>();
        for (Id opportunityId : opportunityIds){
            events.add(getNewInstanceMxSxEvent(CDdMxSxConstants.MXSX_EVENT.OPPORTUNITY_RELATED_CASE_UPDATES, CDdMxSxConstants.SOBJECT_TYPE_OPPORTUNITY, opportunityId));
        }
        Eventbus.publish(events);
        return true;
    }
    /**
     * @description Publish events - store active
     * @param Set<Id> parentAccountIds
     * @return Boolean
    */
    public static Boolean publishEventsStoreActive(Set<Id> parentAccountIds) {
        if (parentAccountIds == null || parentAccountIds.isEmpty() ) { return false; }
        List<MxSx_Event__e> events = new List<MxSx_Event__e>();
        for (Id parentAccountId : parentAccountIds){
            events.add(getNewInstanceMxSxEvent(CDdMxSxConstants.MXSX_EVENT.STORE_ACTIVE, CDdMxSxConstants.SOBJECT_TYPE_ACCOUNT, parentAccountId));
        }
        Eventbus.publish(events);
        return true;
    }
    /**
     * @description Publish events - milestones blocked
     * @param Set<Id> milestoneIds
     * @return Boolean
    */
    public static Boolean publishEventsMilestonesBlocked(Set<Id> milestoneIds) {
        if ( milestoneIds == null || milestoneIds.isEmpty() ) { return false; }
        List<MxSx_Event__e> events = new List<MxSx_Event__e>();
        for (Id milestoneId : milestoneIds){
            events.add(getNewInstanceMxSxEvent(CDdMxSxConstants.MXSX_EVENT.MILESTONE_BLOCKED, CDdMxSxSegmentConstants.SOBJECT_TYPE_MILESTONE, milestoneId));
        }
        Eventbus.publish(events);
        return true;
    }
    /**
     * @description Publish events - milestones complete
     * @param Set<Id> milestoneIds
     * @return Boolean
    */
    public static Boolean publishEventsMilestonesComplete(Set<Id> milestoneIds) {
        if ( milestoneIds == null || milestoneIds.isEmpty() ) { return false; }
        List<MxSx_Event__e> events = new List<MxSx_Event__e>();
        for (Id milestoneId : milestoneIds){
            events.add(getNewInstanceMxSxEvent(CDdMxSxConstants.MXSX_EVENT.MILESTONE_COMPLETE, CDdMxSxConstants.SOBJECT_TYPE_MILESTONE, milestoneId));
        }
        Eventbus.publish(events);
        return true;
    }
    /**
     * @description Publish events - milestones In Progress
     * @param Set<Id> milestoneIds
     * @return Boolean
    */
    public static Boolean publishEventsMilestonesInProgress(Set<Id> milestoneIds) {
        if ( milestoneIds == null || milestoneIds.isEmpty() ) { return false; }
        List<MxSx_Event__e> events = new List<MxSx_Event__e>();
        for (Id milestoneId : milestoneIds){
            events.add(getNewInstanceMxSxEvent(CDdMxSxConstants.MXSX_EVENT.MILESTONE_IN_PROGRESS, CDdMxSxConstants.SOBJECT_TYPE_MILESTONE, milestoneId));
        }
        Eventbus.publish(events);
        return true;
    }
    /**
     * @description Publish events - milestones In Dead
     * @param Set<Id> milestoneIds
     * @return Boolean
    */
    public static Boolean publishEventsMilestonesInDead(Set<Id> milestoneIds) {
        if ( milestoneIds == null || milestoneIds.isEmpty() ) { return false; }
        List<MxSx_Event__e> events = new List<MxSx_Event__e>();
        for (Id milestoneId : milestoneIds){
            events.add(getNewInstanceMxSxEvent(CDdMxSxConstants.MXSX_EVENT.MILESTONE_IN_DEAD, CDdMxSxConstants.SOBJECT_TYPE_MILESTONE, milestoneId));
        }
        Eventbus.publish(events);
        return true;
    }
    /**
     * @description Publish events - Send Mx Order to Vendor
     * @param Set<Id> milestoneIds
     * @return Boolean
    */
    public static Boolean publishEventsSendMxOrderToVendor(String sObjectType, Set<Id> sObjectIds) {
        if ( sObjectIds == null || sObjectIds.isEmpty() ) { return false; }
        List<MxSx_Event__e> events = new List<MxSx_Event__e>();
        for (Id sObjectId : sObjectIds){
            events.add(getNewInstanceMxSxEvent(CDdMxSxConstants.MXSX_EVENT.SEND_MX_ORDER_TO_VENDOR, sObjectType, sObjectId));
        }
        Eventbus.publish(events);
        return true;
    }
    /**
     * @description Publish events - Tablet Case Shipped
     * @param Set<Id> CaseIds
     * @return Boolean
    */
    public static Boolean publishEventsTabletCaseShipped(String sObjectType, Set<Id> sObjectIds) {
        if ( sObjectIds == null || sObjectIds.isEmpty() ) { return false; }
        List<MxSx_Event__e> events = new List<MxSx_Event__e>();
        for (Id sObjectId : sObjectIds){
            events.add(getNewInstanceMxSxEvent(CDdMxSxConstants.MXSX_EVENT.TABLET_CASE_SHIPPED, sObjectType, sObjectId));
        }
        Eventbus.publish(events);
        return true;
    }
    /**
     * @description Publish events - Tablet Case Received
     * @param Set<Id> CaseIds
     * @return Boolean
    */
    public static Boolean publishEventsTabletCaseReceived(String sObjectType, Set<Id> sObjectIds) {
        if ( sObjectIds == null || sObjectIds.isEmpty() ) { return false; }
        List<MxSx_Event__e> events = new List<MxSx_Event__e>();
        for (Id sObjectId : sObjectIds){
            events.add(getNewInstanceMxSxEvent(CDdMxSxConstants.MXSX_EVENT.TABLET_CASE_RECEIVED, sObjectType, sObjectId));
        }
        Eventbus.publish(events);
        return true;
    }

    /**
     * @description Publish events - POS Integration Field Changes on POS Inegration Case
     * @param Set<Id> caseIds
     * @return Boolean
    */
    public static Boolean publishEventsPosIntegrationCaseStatusUpdated(CDdMxSxConstants.MXSX_EVENT eventType, String sObjectType, Set<Id> sObjectIds) {
        if ( sObjectIds == null || sObjectIds.isEmpty() ) { return false; }
        List<MxSx_Event__e> events = new List<MxSx_Event__e>();
        for (Id sObjectId : sObjectIds){
            events.add(getNewInstanceMxSxEvent(eventType, sObjectType, sObjectId));
        }
        Eventbus.publish(events);
        return true;
    }
    /**
    * @description Publish events - Mx Onboarding Record, Update Type = Inbound,  (Update Happening from MxPortal)
    * @param Set<Id> caseIds
    * @return Boolean
   */
   public static Boolean publishEventsForMxOnboardingUpdateInbound(Set<Id> mxOnboardingIds) {
        if ( mxOnboardingIds == null || mxOnboardingIds.isEmpty() ) { return false; }
        List<MxSx_Event__e> events = new List<MxSx_Event__e>();
        for (Id sObjectId : mxOnboardingIds){
            events.add(getNewInstanceMxSxEvent(CDdMxSxConstants.MXSX_EVENT.MX_ONBOARDING_UPDATE_INBOUND_EVENT, CDdMxSxConstants.SOBJECT_TYPE_MX_ONBOARDING, sObjectId));
        }
        Eventbus.publish(events);
    return true;
   }
    /**
     * @description Publish events - when account credentials changed.
     * @param Set<Id> accountIds
     * @return Boolean
    */
    public static Boolean publishEventsForAccountToOrderUpdate(String sObjectType, Set<Id> sObjectIds) {
        if ( sObjectIds == null || sObjectIds.isEmpty() ) { return false; }
        List<MxSx_Event__e> events = new List<MxSx_Event__e>();
        for (Id sObjectId : sObjectIds){
            events.add(getNewInstanceMxSxEvent(CDdMxSxConstants.MXSX_EVENT.UPDATE_ORDER_FROM_ACCOUNT, sObjectType, sObjectId));
        }
        Eventbus.publish(events);
        return true;
    }
    /**
    * @description BZAP-18475 Publish events - Marketplace Onboarding Case Insert
    * @param String sObjectType
    * @param Set<Id> sObjectIds
    * @return Boolean
   */
   public static Boolean publishMxSxEventsForMarketplaceOnboardingCaseInsert(String sObjectType, Set<Id> sObjectIds) {
        if ( sObjectIds == null || sObjectIds.isEmpty() ) { return false; }
        List<MxSx_Event__e> events = new List<MxSx_Event__e>();
        for (Id sObjectId : sObjectIds){
            events.add(getNewInstanceMxSxEvent(CDdMxSxConstants.MXSX_EVENT.MARKETPLACE_ONBOARDING_CASE_INSERT_EVENT, sObjectType, sObjectId));
        }
        Eventbus.publish(events);
        return true;
    }
    /**
        * @description BZAP-18475 publish events - Marketplace Onboarding Case Updates
        * @param String sObjectType
        * @param Set<Id> sObjectIds
        * @return Boolean
    */
    public static Boolean publishMxSxEventsForMarketplaceOnboardingCaseUpdate(String sObjectType, Set<Id> sObjectIds) {
        if ( sObjectIds == null || sObjectIds.isEmpty() ) { return false; }
            List<MxSx_Event__e> events = new List<MxSx_Event__e>();
        for (Id sObjectId : sObjectIds){
            events.add(getNewInstanceMxSxEvent(CDdMxSxConstants.MXSX_EVENT.MARKETPLACE_ONBOARDING_CASE_UPDATE_EVENT, sObjectType, sObjectId));
        }
        Eventbus.publish(events);
        return true;
    }

    /**
        @author: Dan Thoreson
        @date: 12-Jan-2023
        @description: Publishes MxSx Events when a Marketplace Onboarding Case is inserted. 
                      Handles the serialization of data and calls the Event Publisher to finalize publishing.
    **/
    public static Boolean publishEventsForPosOpportunities(Set<Id> onboardingCaseIds) {
        if(onboardingCaseIds.isEmpty()) {
            return false;
        }

        Map<Id, CDdMxSxPOSRequestWrappers.POSRequest> opportunityPosRequestInfo = new Map<Id, CDdMxSxPOSRequestWrappers.POSRequest>();

        Set<String> extraFields = new Set<String>{
            'CreatedDate',
            'Origin',
            'Opportunity_Name__r.Order_Protocol__c'
        };

        List<Case> casesEligibleForPos = new List<Case>();

        for(Case thisCase : CasesSelector.newInstance().selectByIdExtraFields(onboardingCaseIds, extraFields)) {
            Boolean createdFromWonOpp = String.isNotBlank(thisCase.Origin) && thisCase.Origin.contains(CDdMxSxConstants.CASE_ORIGIN_OPP_CLOSED_WON);
            Boolean isPos = String.isNotBlank(thisCase.Opportunity_Name__r.Order_Protocol__c) && thisCase.Opportunity_Name__r.Order_Protocol__c.contains('POS');

            if(createdFromWonOpp && isPos) {
                casesEligibleForPos.add(thisCase);
            }
        }

        if(!casesEligibleForPos.isEmpty()) {
            CDdMxSxPOSRequestWrappers.setOpportunityIdsAndMarketplaceCaseIds(casesEligibleForPos);

            for(Case thisCase : casesEligibleForPos) {
                opportunityPosRequestInfo.put(thisCase.Opportunity_Name__c, new CDdMxSxPOSRequestWrappers.POSRequest(thisCase));
            }
        }

        return CDdMxSxEventPublisher.publishEventsForPosOpportunities(opportunityPosRequestInfo);
    }

    /**
        @author: Dan Thoreson
        @date: 21-Dec-2022
        @description: Handles the publishing of the POS_INTEGRATION_REQUEST MxSx Events.
    **/
    public static Boolean publishEventsForPosOpportunities(Map<Id, CDdMxSxPOSRequestWrappers.POSRequest> posRequests) {
        List<MxSx_Event__e> events = new List<MxSx_Event__e>();

        if(posRequests != null && !posRequests.isEmpty()) {
            for(Id thisRequestId : posRequests.keySet()) {
                CDdMxSxPOSRequestWrappers.POSRequest thisRequest = posRequests.get(thisRequestId);

                events.add(getNewInstanceMxSxEventWithPayload(CDdMxSxConstants.MXSX_EVENT.POS_INTEGRATION_REQUEST,
                                                                CDdMxSxConstants.SOBJECT_TYPE_OPPORTUNITY,
                                                                thisRequestId,
                                                                thisRequest));
            }

            EventBus.publish(events);
        }

        return !events.isEmpty();
    }

     /**
        * @description BZAP-18475 publish events - Caviar Onboarding Case Updates
        * @param String sObjectType
        * @param Set<Id> sObjectIds
        * @return Boolean
    */
    public static Boolean publishMxSxEventsForCaviarOnboardingCaseUpdate(String sObjectType, Set<Id> sObjectIds) {
        if ( sObjectIds == null || sObjectIds.isEmpty() ) { return false; }
            List<MxSx_Event__e> events = new List<MxSx_Event__e>();
        for (Id sObjectId : sObjectIds){
            events.add(getNewInstanceMxSxEvent(CDdMxSxConstants.MXSX_EVENT.CAVIAR_ONBOARDING_CASE_UPDATE_EVENT, sObjectType, sObjectId));
        }
        Eventbus.publish(events);
        return true;
    }
     /** 
        * @description BZAP-19064 publish events - Process Pos Integration requests from BAT.
        * @param String sObjectType
        * @param Set<Id> onboardingIds
        * @return Boolean
    */
    public static Boolean publishMxSxEventsForPosIntegrationRequestsFromBat(String sObjectType, Set<String> onboardingIds) {
        if ( onboardingIds == null || onboardingIds.isEmpty() ) { return false; }
            List<MxSx_Event__e> events = new List<MxSx_Event__e>();
        for (String onboardingId : onboardingIds){
            events.add(getNewInstanceMxSxEvent(CDdMxSxConstants.MXSX_EVENT.POS_INTEGRATION_REQUEST_FROM_BAT, sObjectType, onboardingId));
        }
        Eventbus.publish(events);
        return true;       
    }
    /**
     * @description Return a new instance of event MxSx_Event__e
     * @param CDdMxSxConstants.MXSX_EVENT - enum event
     * @param String - sObject type
     * @param String - sObject Id
     * @return MxSx_Event__e
    */
    private static MxSx_Event__e getNewInstanceMxSxEvent(CDdMxSxConstants.MXSX_EVENT event, String sObjectType, String sObjectId){
        return new MxSx_Event__e(
            Event_Name__c = String.valueOf(event).toUpperCase(),
            SObject_Type__c = sObjectType,
            SObject_Id__c = sObjectId
        );
    }

    /**
        @author: Dan Thoreson
        @date: 22-Dec-2022
        @description: Overloaded version of getNewInstanceMxSxEvent, permitting the addition of a generic Object whose data
                      we will add to the payload (Payload__c) of the MxSx_Event.
    **/
    private static MxSx_Event__e getNewInstanceMxSxEventWithPayload(CDdMxSxConstants.MXSX_EVENT event,
                                                                    String sObjectType,
                                                                    String sObjectId,
                                                                    Object objData) {

        MxSx_Event__e thisEvent = getNewInstanceMxSxEvent(event, sObjectType, sObjectId);
        thisEvent.Payload__c = (objData != null) ? JSON.serialize(objData) : '{}';
        return thisEvent;
    }
}