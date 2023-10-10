/********************************************************************************************************************
* @author Venkat D
* @date 07/29/2022
*
*
* @description This trigger is a subscriber to the 'SSMO Opportunity Attribution Events' platform event
* 
*********************************************************************************************************************/
trigger TDdSSMOOpportunityAttributionEventTrigger on SSMO_Opportunity_Attribution_Event__e (after insert) {
    CDdSSMOOpportunityEventHandler handler = new CDdSSMOOpportunityEventHandler();
    if (Trigger.isAfter){
        if (Trigger.isInsert) {
            handler.afterInsert(Trigger.new);
        }
    }
}