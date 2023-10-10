/********************************************************************************************************************
* @author Sriram
* @date 11/07/2021
*
* @group Merchant Services
*
* @description This trigger handler is invoked by TDdMxSxEventTrigger
*              TDdMxSxEventTrigger is a subscriber to the 'MxSx Event' platform event
*
*              In order to optimize the processing, the batch size input to this trigger has been set to 50
*              (@see PlatformEventSubscriberConfigs/MxSxEventPlatformEventTriggerConfig)
*
*              This trigger will set the resume checkpoint to ensure the rest of the platform events (after last successfully processed event)
*              are processed in the next trigger execution cycle, if a limit exception or an uncaught exception occurs
*
*              In order to ensure the 'resume checkpoint' picks up processing from the last successful event processed and does not miss any unprocessed event,
*              it is recommended to group the platform events for a specific event name together and then move to the next group of events for another event
*              name etc., prior to publishing the platform events.
*
*              If there was no resume checkpoint set within the trigger context, it will be assumed a fatal error occurred right at the
*              beginning of the execution. EventBus.RetryableException will be thrown to reprocess the platform events at a later time.
*
**************************************************************************************************************************************/
public class CDdMxSxEventTriggerHandler {
    private static final String MXSX_EVENT_FIELD_EVENT_NAME = 'Event_Name__c';
    private static final String MXSX_EVENT_FIELD_SOBJECT_TYPE = 'SObject_Type__c';
    private static Map<String, Integer> MX_EVENT_COUNT_BY_EVENT_NAME = CDdMxSxConfigHelper.MX_EVENT_COUNT_BY_EVENT_NAME;
    /**
     * @description Apex Class Entry point for Merchant Services Event Trigger
     * @param List<MxSx_Event__e> newList
     * @return
    */
    public void afterInsert(List<MxSx_Event__e> newList) {
        if (newList.isEmpty()) { return; }
        try {
            Map<String, List<MxSx_Event__e>> mxSxEventsByEventName = groupMxSxEventsByMxSxEventProperty(MXSX_EVENT_FIELD_EVENT_NAME, newList);
            for (String eventName : mxSxEventsByEventName.keySet()){
                CDdMxSxConstants.MXSX_EVENT event = CDdMxSxConstants.MXSX_EVENTS.get(eventName);
                List<MxSx_Event__e> mxSxEvents = mxSxEventsByEventName.get(eventName);
                switch on (event) {
                    when OPPORTUNITY_CLOSED_WON {
                        CDdMxSxEventHandler.handleEventsOpportunityClosedWon(getSObjectIds(mxSxEvents));
                    }
                    when OPPORTUNITY_RELATED_CASE_UPDATES {
                        CDdMxSxEventHandler.handleEventsOpportunityRelatedCaseUpdates(getSObjectIds(mxSxEvents));
                    }
                    when STORE_ACTIVE {
                        CDdMxSxEventHandler.handleEventsStoreActive(getSObjectIds(mxSxEvents));
                    }
                    when MILESTONE_BLOCKED {
                        CDdMxSxEventHandler.handleEventsMileStoneBlocked(getSObjectIds(mxSxEvents), eventName);
                    }
                    when MILESTONE_COMPLETE {
                        CDdMxSxEventHandler.handleEventsMileStoneComplete(getSObjectIds(mxSxEvents));
                    }
                    when TABLET_CASE_SHIPPED {
                        CDdMxSxEventHandler.handleEventsTabletCaseShipped(getSObjectIds(mxSxEvents));
                    }
                    when TABLET_CASE_RECEIVED {
                        CDdMxSxEventHandler.handleEventsTabletCaseReceived(getSObjectIds(mxSxEvents));
                    }
                    when SEND_MX_ORDER_TO_VENDOR {
                        Map<String, List<MxSx_Event__e>> eventsBySObjectType = groupMxSxEventsByMxSxEventProperty(MXSX_EVENT_FIELD_SOBJECT_TYPE, mxSxEvents);
                        for (String sObjectType : eventsBySObjectType.keySet()){
                            CDdMxSxEventHandler.handleEventsSendMxOrderToVendor(sObjectType, getSObjectIds(eventsBySObjectType.get(sObjectType)));
                        }
                    }
                    when MILESTONE_IN_PROGRESS {
                        CDdMxSxEventHandler.handleEventsMileStoneInProgress(getSObjectIds(mxSxEvents));
                    }
                    when POS_INTEGRATION_CASE_STATUS_CHANGE {
                        CDdMxSxEventHandler.handleEventsPosIntegrationStatusUpdate(getSObjectIds(mxSxEvents));
                    }
                    when MILESTONE_IN_DEAD {
                        CDdMxSxEventHandler.handleEventsMileStoneInDead(getSObjectIds(mxSxEvents));
                    }
                    when MX_ONBOARDING_UPDATE_INBOUND_EVENT {
                        CDdMxSxEventHandler.handleEventsMxOnboardingStatusEvent(getSObjectIds(mxSxEvents));
                    }
                    when UPDATE_ORDER_FROM_ACCOUNT {
                        CDdMxSxEventHandler.handleOrderUpdatesFromAccount(getSObjectIds(mxSxEvents));
                    }
                    when MARKETPLACE_ONBOARDING_CASE_INSERT_EVENT {
                        CDdMxSxEventHandler.handleEventsForMarketplaceOnboardingCaseInsert(getSObjectIds(mxSxEvents));
                    }
                    when POS_INTEGRATION_REQUEST_FROM_BAT {
                        CDdMxSxEventHandler.handleEventsForPosIntegrationRequestsFromBat(getEventObjectIds(mxSxEvents));
                    }
                    when CAVIAR_ONBOARDING_CASE_UPDATE_EVENT {
                        CDdMxSxEventHandler.handleEventsForCaviarOnboardingCaseUpdate(getSObjectIds(mxSxEvents));
                    }
                    when POS_INTEGRATION_REQUEST {
                        CDdMxSxEventHandler.handleEventsForPosRequests(mxSxEvents);
                    }
                    when else {
                    }
                }
                // Set the resume check point after the event is processed successfully
                setResumeCheckpoint(mxSxEvents);
            }
        } catch (Exception ex) {
            if (String.isBlank(EventBus.TriggerContext.currentContext().getResumeCheckpoint())){
                if (EventBus.TriggerContext.currentContext().retries < CDdMxSxConstants.MXSX_PLATFORM_EVENT_RETRY_LIMIT) {
                    throw new EventBus.RetryableException(ex.getMessage());
                }
            }
        } finally {
        }
    }
    /**
     * @description Set the Replay ID of the last successfully processed Merchant Services Event message.
     * @param List<MxSx_Event__e> mxSxEvents
     * @return
     */
    public void setResumeCheckpoint(List<MxSx_Event__e> mxSxEvents){
        if (mxSxEvents==null || mxSxEvents.isEmpty() ) { return; }
        EventBus.TriggerContext.currentContext().setResumeCheckpoint(mxSxEvents[mxSxEvents.size()-1].ReplayId);
    }
    /**
     * @description Group the Merchant Services Events by the Merchant Service Event property - Example: Event_Name__c
     * @param String mxSxEventProperty
     * @param List<MxSx_Event__e> mxSxEvents
     * @return Map<String, Set<Id>> Return a Collection of Merchant Services Events grouped by input mxSxEventProperty
     */
    public Map<String, List<MxSx_Event__e>> groupMxSxEventsByMxSxEventProperty(String mxSxEventProperty, List<MxSx_Event__e> mxSxEvents){
        Map<String, List<MxSx_Event__e>> mxSxEventsBymxSxEventProperty = new Map<String, List<MxSx_Event__e>>();
        String eventName = (String)mxSxEvents[0].get(mxSxEventProperty);
        // if the custom metadata has scope size use it to chunk the transaction with specified number of events per transaction.
        // chunking events into transactions only applicable if the custom metadata exists.
        Boolean chunkTheEventsByNameAndScope = MX_EVENT_COUNT_BY_EVENT_NAME.containsKey(eventName) ? true : false;
        Integer scopeSize = chunkTheEventsByNameAndScope ? MX_EVENT_COUNT_BY_EVENT_NAME.get(eventName) : 200;

        for ( Integer counter = 0; counter < scopeSize && counter < mxSxEvents.size(); counter++ ) {
            MxSx_Event__e eachMxSxEvent = mxSxEvents[counter];
            String value = (String)eachMxSxEvent.get(mxSxEventProperty);
            if (chunkTheEventsByNameAndScope && (eachMxSxEvent == null || value != eventName)) {
                break;
            }
            if (mxSxEventsBymxSxEventProperty.containsKey(value)){
                mxSxEventsBymxSxEventProperty.get(value).add(eachMxSxEvent);
            } else {
                mxSxEventsBymxSxEventProperty.put(value, new List<MxSx_Event__e>{eachMxSxEvent});
            }
            EventBus.TriggerContext.currentContext().setResumeCheckpoint(eachMxSxEvent.ReplayId);
        }
        return mxSxEventsBymxSxEventProperty;
    }
    /**
     * @description Return a Collection of sObject Ids from the Merchant Services Events
     * @param List<MxSx_Event__e> mxSxEvents
     * @return Set<Id> - a Collection of sObject Ids
    */
    public Set<Id> getSObjectIds(List<MxSx_Event__e> mxSxEvents){
        Set<Id> sObjectIds = new Set<Id>();
        for (MxSx_Event__e event : mxSxEvents){
            sObjectIds.add((Id)event.SObject_Id__c);
        }
        return sObjectIds;
    }
    /**
     * @description Return a Collection of eventIds from the Merchant Services Events
     * @param List<MxSx_Event__e> mxSxEvents
     * @return Set<String> - a Collection of eventIds
    */
    public Set<String> getEventObjectIds(List<MxSx_Event__e> mxSxEvents){
        Set<String> eventObjectIds = new Set<String>();
        for (MxSx_Event__e event : mxSxEvents){
            eventObjectIds.add(event.SObject_Id__c);
        }
        return eventObjectIds;
    }
}