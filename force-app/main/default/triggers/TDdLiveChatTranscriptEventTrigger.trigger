trigger TDdLiveChatTranscriptEventTrigger on LiveChatTranscriptEvent (before insert, before update, after insert, after update, before delete) {
    CDdLiveChatTransEventTriggerHandler handler = new CDdLiveChatTransEventTriggerHandler();
    if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            handler.afterInsert(Trigger.newMap);
        } else if(Trigger.isUpdate) {
            handler.afterUpdate(Trigger.newMap, Trigger.oldMap);
        }
    } else if (Trigger.isBefore){
        if(Trigger.isInsert) {
            system.debug(Trigger.new);
            handler.beforeInsert(Trigger.new);
        } else if(Trigger.isUpdate){
            handler.beforeUpdate(Trigger.newMap, Trigger.oldMap);
        }else if(Trigger.isDelete){
            handler.beforeDelete(Trigger.oldMap);
        }
    }
}