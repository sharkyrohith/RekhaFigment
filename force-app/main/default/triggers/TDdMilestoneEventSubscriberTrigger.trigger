/********************************************************************************************************************
* @author Sriram
* @date 08/09/2021
*
* @group Trigger
*
* @description This trigger is a subscriber to the 'Milestone Event' platform event
* 
**************************************************************************************************************************************/
trigger TDdMilestoneEventSubscriberTrigger on Milestone_Event__e (after insert) {
    CDdMilestoneEventSubscriberHandler handler = new CDdMilestoneEventSubscriberHandler();
    if (Trigger.isAfter){
        if (Trigger.isInsert) {
            handler.afterInsert(Trigger.new);
        }
    }
}