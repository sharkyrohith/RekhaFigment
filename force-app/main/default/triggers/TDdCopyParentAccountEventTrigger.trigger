/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 07/22/2019
*
* @group Trigger
*
* @description This trigger is a subscriber to the 'Copy Parent Account' platform event
* 
**************************************************************************************************************************************/
trigger TDdCopyParentAccountEventTrigger on Copy_Parent_Account_Event__e (after insert) {
    CDdCopyParentAccountEventHandler handler = new CDdCopyParentAccountEventHandler();
    if (Trigger.isAfter){
        if (Trigger.isInsert) {
            handler.afterInsert(Trigger.new);
        }
    }
}