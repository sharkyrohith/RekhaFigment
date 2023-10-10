/*
Case Trigger
*/
trigger TDdCaseTrigger on Case (before insert, before update, after insert, after update, before delete) {
    vCS__c settings = vCS__c.getInstance();

    //False positive for Logic inside Trigger
    if((settings != null && !settings.CaseTrigger__c)
        || CDdTriggerConstantsUtil.skipTriggerExecutionSet.contains(CDdTriggerConstantsUtil.skipCaseTrigger)
        || CDdTriggerConstantsUtil.skipCaseTriggerExecution) {
        return;
    }

    if (! CDdRecursionUtils.isRunnable('TDdCaseTrigger')) return;

    CDdCaseTriggerHandlerV2 handler = new CDdCaseTriggerHandlerV2(Trigger.new);

    if(Trigger.isBefore) {
        if(Trigger.isInsert) {
            handler.beforeInsert(Trigger.new, Trigger.operationType);
        } else if (Trigger.isUpdate) {
            handler.beforeUpdate(Trigger.new, Trigger.oldMap, Trigger.operationType);
        }
        else if(Trigger.isDelete) {
            handler.beforedelete(Trigger.old, Trigger.operationType);
        }
    } else if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            handler.afterInsert(Trigger.new, Trigger.operationType);
        } else if (Trigger.isUpdate) {
            handler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}