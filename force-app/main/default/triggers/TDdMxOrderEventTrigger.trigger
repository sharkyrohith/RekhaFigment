/********************************************************************************************************************
* @author Lathika
* @date 03/01/2022
*
* @group Merchant Services
*
* @description This trigger is a subscriber to the 'Mx Order Event' platform event
*
**************************************************************************************************************************************/
trigger TDdMxOrderEventTrigger on Mx_Order_Event__e (after insert) {
    CDdMxOrderEventTriggerHandler handler = new CDdMxOrderEventTriggerHandler();
    if (Trigger.isAfter){
        if (Trigger.isInsert) {
            handler.afterInsert(Trigger.new);
        }
    }
}