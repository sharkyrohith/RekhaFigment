/********************************************************************************************************************
* @author Sriram
* @date 03/29/2022
*
* @group Merchant Services
*
* @description Trigger on object Mx_Order_Queue__c
*
**************************************************************************************************************************************/
trigger TDdMxOrderQueueTrigger on Mx_Order_Queue__c (before insert, before update, after insert, after update) {
    CDdMxOrderQueueTriggerHandler handler = new CDdMxOrderQueueTriggerHandler();
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            handler.beforeInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            handler.beforeUpdate(Trigger.new, Trigger.oldMap);
        }
    } else if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            handler.afterInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            handler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}