/*
User Trigger
*/
trigger TDdUserTrigger on User(before insert, before update, after insert, after update) {

    if (! CDdRecursionUtils.isRunnable('TDdUserTrigger')) return;

    CDdUserTriggerHandler handler = new CDdUserTriggerHandler();

    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            handler.beforeInsert(Trigger.new);
        }
        if (Trigger.isUpdate) {
            handler.beforeUpdate(Trigger.new, Trigger.oldMap);
        }
    } else if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            handler.afterInsert(Trigger.new);
        }
        if (Trigger.isUpdate) {
            handler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }

}