/********************************************************************************************************************
* @author Sriram
* @date 11/07/2021
*
* @group Merchant Services
*
* @description This trigger is a subscriber to the 'MxSx Event' platform event
* 
**************************************************************************************************************************************/
trigger TDdMxSxEventTrigger on MxSx_Event__e (after insert) {
    CDdMxSxEventTriggerHandler handler = new CDdMxSxEventTriggerHandler();
    if (Trigger.isAfter){
        if (Trigger.isInsert) {
            handler.afterInsert(Trigger.new);
        }
    }
}