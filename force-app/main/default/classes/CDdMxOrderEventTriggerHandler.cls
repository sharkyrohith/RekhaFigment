/********************************************************************************************************************
* @author Sriram
* @date 03/21/2022
*
* @group Merchant Services
*
* @description This trigger handler is invoked by TDdMxOrderEventTrigger
*              TDdMxOrderEventTrigger is a subscriber to the 'Mx Order Event' platform event
*
*              In order to optimize the processing, the batch size input to this trigger has been lowered
*              (@see PlatformEventSubscriberConfigs/MxOrderEventPlatformEventTriggerConfig)
*
*              This trigger will set the resume checkpoint to ensure the rest of the platform events (after last successfully processed event)
*              are processed in the next trigger execution cycle, if a limit exception or an uncaught exception occurs
*
*              In order to ensure the 'resume checkpoint' picks up processing from the last successful event processed and does not miss any unprocessed event,
*              it is recommended to set the 'resume checkpoint' right after processing the input batch size of Mx Order Events.
*
*              If there was no resume checkpoint set within the trigger context, it will be assumed a fatal error occurred right at the
*              beginning of the execution. EventBus.RetryableException will be thrown to reprocess the platform events at a later time.
*
**************************************************************************************************************************************/
public class CDdMxOrderEventTriggerHandler {
    private static final String MX_ORDER_EVENT_FIELD_EVENT_NAME = 'Event_Name__c';
    /**
     * @description Apex Class Entry point for Merchant Services Order Event Trigger
     * @param List<Mx_Order_Event__e> newList
     * @return   
    */
    public void afterInsert(List<Mx_Order_Event__e> newList) {
        if (newList.isEmpty()) { return; }
        try {
            Map<CDdMxOrderEventEnum, List<Mx_Order_Event__e>> eventsByMxOrderEvent = getEventsByMxOrderEvent(newList);          
            for (CDdMxOrderEventEnum event : eventsByMxOrderEvent.keySet()){
                new CDdMxOrderEventHandler(event, eventsByMxOrderEvent.get(event)).execute();
            }          
            // Set the resume check point after the event is processed successfully
            setResumeCheckpoint(newList);            
        } catch (Exception ex) {
            CDdErrorUtilities.publishException('MxOrderEvent','CDdMxOrderEventTriggerHandler', ex);
            System.debug(LoggingLevel.ERROR, 'CDdMxOrderEventTriggerHandler - afterInsert : '+ ex.getMessage());
            /*if (String.isBlank(EventBus.TriggerContext.currentContext().getResumeCheckpoint())){
                if (EventBus.TriggerContext.currentContext().retries < CDdMxSxConstants.MXSX_PLATFORM_EVENT_RETRY_LIMIT) {
                    throw new EventBus.RetryableException(ex.getMessage());
                }
            }*/
        } finally {
        }
    }
    /**
     * @description Set the Replay ID of the last successfully processed Merchant Services Event message.
     * @param List<Mx_Order_Event__e> mxOrderEvents
     * @return
     */      
    public void setResumeCheckpoint(List<Mx_Order_Event__e> mxOrderEvents){
        if (mxOrderEvents == null || mxOrderEvents.isEmpty() ) { return; }
        EventBus.TriggerContext.currentContext().setResumeCheckpoint(mxOrderEvents[mxOrderEvents.size()-1].ReplayId);
    }
    /**
     * @description Group the Merchant Services Order Events by type CDdMxOrderEventEnum
     * Note: Only Merchant Orders with Event name that are present as enum in CDdMxOrderEventEnum, will be processed
     * @param List<Mx_Order_Event__e> mxOrderEvents
     * @return Map<String, Set<Id>> Return a Collection of Merchant Services Events grouped by enum CDdMxOrderEventEnum
     */   
    public Map<CDdMxOrderEventEnum, List<Mx_Order_Event__e>> getEventsByMxOrderEvent(List<Mx_Order_Event__e> mxOrderEvents){
        Map<CDdMxOrderEventEnum, List<Mx_Order_Event__e>> eventsByMxOrderEvent = new Map<CDdMxOrderEventEnum, List<Mx_Order_Event__e>>();
        for (Mx_Order_Event__e event : mxOrderEvents){
            String mxOrderEventName = (String)event.get(MX_ORDER_EVENT_FIELD_EVENT_NAME);
            CDdMxOrderEventEnum mxOrderEvent = CDdMxOrderEventEnumHelper.toEnum(mxOrderEventName);
            if (mxOrderEvent!=null){  
                if (eventsByMxOrderEvent.containsKey(mxOrderEvent)){
                    eventsByMxOrderEvent.get(mxOrderEvent).add(event);
                } else {
                    eventsByMxOrderEvent.put(mxOrderEvent, new List<Mx_Order_Event__e>{ event });
                }
            }
        }
        return eventsByMxOrderEvent;  
    }  
}