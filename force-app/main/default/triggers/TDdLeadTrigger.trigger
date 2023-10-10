trigger TDdLeadTrigger on Lead (before insert, before update, before delete, after insert, after update, after delete) {

    if (! CDdRecursionUtils.isRunnable('TDdLeadTrigger')) return;

    CDdLeadTriggerHandler handler = new CDdLeadTriggerHandler();

    if (Trigger.isBefore){
        if (Trigger.isInsert) {
            handler.beforeInsert(Trigger.new);
        } else if(Trigger.isUpdate) {
            handler.beforeUpdate(Trigger.newMap,Trigger.oldMap);
        } else if (Trigger.isDelete) {
            handler.beforeDelete(Trigger.oldMap);
        }
    }
    
    if (Trigger.isAfter){
        if (Trigger.isInsert) {
            handler.afterInsert(Trigger.new);
        } else if(Trigger.isUpdate) {
            handler.afterUpdate(Trigger.newMap,Trigger.oldMap);
        } else if(Trigger.isDelete) {
            handler.afterDelete(Trigger.newMap,Trigger.oldMap);
        } 
    }
}