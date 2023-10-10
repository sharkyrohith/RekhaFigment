/********************************************************************************************************************
* @author Venkat D
* @date 08/31/2022
*
*
* @description This trigger is a subscriber to the 'Campaign Member Platform Events' platform event
* 
*********************************************************************************************************************/
trigger TDdCampaignMemberEventTrigger on Campaign_Member_Platform_Event__e (after insert) {
    CDdCampaignMemberEventHandler handler = new CDdCampaignMemberEventHandler();
    if (Trigger.isAfter){
        if (Trigger.isInsert) {
            handler.afterInsert(Trigger.new);
        }
    }
}