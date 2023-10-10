/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 06/18/2020
*
* @group Trigger
*
* @description Trigger for Opportunity Line Item object
**************************************************************************************************************************************/
trigger TDdOpportunityLineItemTrigger on OpportunityLineItem (before insert, before update, before delete, after insert, after update, after delete) {
	CDdOpportunityLineItemTriggerHandler handler = new CDdOpportunityLineItemTriggerHandler();
    if (Trigger.isAfter){
        if (Trigger.isInsert) {
            handler.afterInsert(Trigger.newMap);
        } else if(Trigger.isUpdate) {
            handler.afterUpdate(Trigger.newMap, Trigger.oldMap);
        } else if(Trigger.isDelete){
            handler.afterDelete(Trigger.oldMap);
        }
    }
    if (Trigger.isBefore){
        if (Trigger.isInsert) {
            handler.beforeInsert(Trigger.new);
        } else if(Trigger.isUpdate) {
            handler.beforeUpdate(Trigger.newMap, Trigger.oldMap);
        } else if(Trigger.isDelete){
            handler.beforeDelete(Trigger.oldMap);
        }
    }
}