/********************************************************************************************************************
* @author Dan Meseroll (atg)
* @date 1/19/2022
*
* @group Trigger
*
* @description Trigger for Commission_Rate__c object
**************************************************************************************************************************************/
trigger TDdCommissionRateTrigger on Commission_Rate__c (before insert, before update) {
    CDdCommissionRateTriggerHandler handler = new CDdCommissionRateTriggerHandler();    
    if(Trigger.isBefore) {
        if(Trigger.isInsert) {
            handler.beforeInsert(Trigger.new);
        }
        
        if (Trigger.isUpdate) {
            handler.beforeUpdate(Trigger.new);
        }
    }
}