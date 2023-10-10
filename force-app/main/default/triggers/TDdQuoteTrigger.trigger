trigger TDdQuoteTrigger on SBQQ__Quote__c (before insert, after update, after insert, before update, after delete) {
    CDdQuoteTriggerHandler handler = new CDdQuoteTriggerHandler();

    if (Trigger.isAfter){
        if(Trigger.isUpdate) {
            handler.afterUpdate(Trigger.new,Trigger.oldMap);
        }
        if(Trigger.isInsert){
            handler.afterInsert(Trigger.new, Trigger.oldMap);
        }
        if(Trigger.isDelete){
            handler.afterDelete(Trigger.old);
        }
    }

    if(Trigger.isBefore){
        if(Trigger.isInsert) {
            handler.beforeInsert(Trigger.new);
        }
        if(Trigger.isUpdate){
            handler.beforeUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}