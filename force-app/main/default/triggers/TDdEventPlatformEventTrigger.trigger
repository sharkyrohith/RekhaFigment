/********************************************************************************************************************
* @author Venkat D
* @date 08/02/2022
*
*
* @description This trigger is a subscriber to the 'Event' platform event
* 
*********************************************************************************************************************/
trigger TDdEventPlatformEventTrigger on Event_Trigger_Platform_Event__e (after insert) {
    CDdEventPlatformEventHandler handler = new CDdEventPlatformEventHandler();
    if (Trigger.isAfter){
        if (Trigger.isInsert) {
            handler.afterInsert(Trigger.new);
        }
    }
}