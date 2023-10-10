/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 08/05/2019
*
* @group Trigger
*
* @description This trigger is a subscriber to the 'Update Task Count' platform event
* 
**************************************************************************************************************************************/
trigger TDdUpdateTaskCountEventTrigger on Update_Task_Count_Event__e (after insert) {
    CDdUpdateTaskCountEventHandler handler = new CDdUpdateTaskCountEventHandler();
    if (Trigger.isAfter){
        if (Trigger.isInsert) {
            handler.afterInsert(Trigger.new);
        }
    }
}