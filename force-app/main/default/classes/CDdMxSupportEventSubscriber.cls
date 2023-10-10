/********************************************************************************************************************
* @author Veera
* @date 04/28/2022
*
* @group Merchant Services
*
* @description This Event Subscriber is invoked by TDdMxSupportEventTrigger
*              TDdMxSupportEventTrigger is a subscriber to the 'Mx Support Event' platform event
*
*              In order to optimize the processing, the batch size input to this trigger has been lowered
*              (@see PlatformEventSubscriberConfigs/MxSupportEventPlatformEventTriggerConfig)
*
*              This trigger will set the resume checkpoint to ensure the rest of the platform events (after last successfully processed event)
*              are processed in the next trigger execution cycle, if a limit exception or an uncaught exception occurs
*
*              In order to ensure the 'resume checkpoint' picks up processing from the last successful event processed and does not miss any unprocessed event,
*              it is recommended to set the 'resume checkpoint' right after processing the input batch size of Mx Support Events.
*
*              If there was no resume checkpoint set within the trigger context, it will be assumed a fatal error occurred right at the
*              beginning of the execution. EventBus.RetryableException will be thrown to reprocess the platform events at a later time.
*
**************************************************************************************************************************************/
public class CDdMxSupportEventSubscriber {
    private static final String MX_SUPPORT_EVENT_FIELD_EVENT_NAME = 'Event_Name__c';

     /**
     * @description Apex Class Entry point for Merchant Services Support Event Trigger
     * @param List<Mx_Support_Event__e> newList
     * @return   
    */
    public void afterInsert(List<Mx_Support_Event__e> newList) {
        if (newList.isEmpty()) { return; }
        try {
            Map<CDdMxSupportEventEnum, Set<Id>> eventsByMxSupportEvent = getEventsByMxSupportEvent(newList);          
            for (CDdMxSupportEventEnum event : eventsByMxSupportEvent.keySet()){
                CDdMxSupportEventHandler.handleEvents(event, CDdMxSupportEventConfig.getQuerySObjectType(event), eventsByMxSupportEvent.get(event));
            }          
            // Set the resume check point after the event is processed successfully
            setResumeCheckpoint(newList);            
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'CDdMxSupportEventSubscriber - afterInsert : '+ ex.getMessage());
            if (String.isBlank(EventBus.TriggerContext.currentContext().getResumeCheckpoint())){
                if (EventBus.TriggerContext.currentContext().retries < CDdMxSxConstants.MXSX_PLATFORM_EVENT_RETRY_LIMIT) {
                    throw new EventBus.RetryableException(ex.getMessage());
                }
            }
        }
    }

     /**
     * @description Set the Replay ID of the last successfully processed Merchant Services Event message.
     * @param List<Mx_Support_Event__e> mxSupportEvents
     * @return
     */      
    private void setResumeCheckpoint(List<Mx_Support_Event__e> mxSupportEvents){
        if (mxSupportEvents == null || mxSupportEvents.isEmpty() ) { return; }
        EventBus.TriggerContext.currentContext().setResumeCheckpoint(mxSupportEvents[mxSupportEvents.size()-1].ReplayId);
    }
    /**
     * @description Group the Merchant Services Order Events by type CDdMxSupportEventEnum
     * Note: Only Merchant Orders with Event name that are present as enum in CDdMxSupportEventEnum, will be processed
     * @param List<Mx_Support_Event__e> mxSupportEvents
     * @return Map<String, Set<Id>> Return a Collection of Merchant Services Events grouped by enum CDdMxSupportEventEnum
     */   
    private Map<CDdMxSupportEventEnum, Set<Id>> getEventsByMxSupportEvent(List<Mx_Support_Event__e> mxSupportEvents){
        Map<CDdMxSupportEventEnum, Set<Id>> eventsByMxSupportEvent = new Map<CDdMxSupportEventEnum, Set<Id>>();
        for (Mx_Support_Event__e event : mxSupportEvents){
            String mxSupportEventName = (String)event.get(MX_SUPPORT_EVENT_FIELD_EVENT_NAME);
            CDdMxSupportEventEnum mxSupportEvent = stringToEnum(mxSupportEventName);
            if (mxSupportEvent!=null){  
                if (eventsByMxSupportEvent.containsKey(mxSupportEvent)){
                    eventsByMxSupportEvent.get(mxSupportEvent).add(event.SObjectId__c);
                } else {
                    eventsByMxSupportEvent.put(mxSupportEvent, new Set<Id>{ event.SObjectId__c });
                }
            }
        }
        return eventsByMxSupportEvent;  
    }  

    private static CDdMxSupportEventEnum stringToEnum(String mxSupportEventName){
        for (CDdMxSupportEventEnum eventEnum : CDdMxSupportEventEnum.values()) {
            if (eventEnum.name() == mxSupportEventName) {
               return eventEnum;
            }
        }
        return null;
    }

}