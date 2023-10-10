trigger TDdPrivacyServiceTrigger on Privacy_Service__c (before insert, after insert, before update, after update) {
    CDdPrivacyServiceTriggerHandler handler = new CDdPrivacyServiceTriggerHandler();
    if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            handler.afterInsert(Trigger.new);
        } else if(Trigger.isUpdate) {
            handler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    } else if (Trigger.isBefore){
        if(Trigger.isInsert) {
            handler.beforeInsert(Trigger.new);
        } else if(Trigger.isUpdate){
            handler.beforeUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}