trigger TDdContentVersionTrigger on ContentVersion (before insert, before update, after insert, after update) {

    CDdContentVersionTriggerHandler handler = new CDdContentVersionTriggerHandler();

    if (Trigger.isBefore){
        if (Trigger.isInsert) {
            handler.beforeInsert(Trigger.new);
        }
    }

    if (Trigger.isAfter){
        if (Trigger.isInsert) {
            handler.afterInsert(Trigger.new);
        }
    }
}