/********************************************************************************************************************
* @author Sriram
* @date 03/21/2022
*
* @group Merchant Services
*
* @description Trigger on object Mx_Order__c
*
**************************************************************************************************************************************/
trigger TDdMxOrderTrigger on Mx_Order__c (before insert, before update, after insert, after update) {
    
    if (!CDdExperimentSvc.canRun('Mx_Order__c')) {
        return;
    }

    CDdMxOrderTriggerHandler handler = new CDdMxOrderTriggerHandler();
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