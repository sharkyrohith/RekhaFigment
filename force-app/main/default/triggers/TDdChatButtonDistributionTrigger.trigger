trigger TDdChatButtonDistributionTrigger on Chat_Button_Distribution__c (before insert, before update, after insert, after update) {
    CDdChatButtonDistributionTriggerHandler handler = new CDdChatButtonDistributionTriggerHandler();
    if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            handler.afterInsert(Trigger.newMap);
        } else if(Trigger.isUpdate) {
            handler.afterUpdate(Trigger.newMap, Trigger.oldMap);
        }
    } else if (Trigger.isBefore){
        if(Trigger.isInsert) {
            handler.beforeInsert(Trigger.new);
        } else if(Trigger.isUpdate){
            handler.beforeUpdate(Trigger.newMap, Trigger.oldMap);
        }
    }
}