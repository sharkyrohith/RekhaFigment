trigger TDdACContactTraceTrigger on amazonconnect__AC_ContactTraceRecord__c (before insert, after insert) {
    CDdACContactTraceTriggerHandler handler = new CDdACContactTraceTriggerHandler();

    if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            handler.afterInsert(Trigger.new);
        } 
    } else if(Trigger.isBefore) {
        if(Trigger.isInsert) {
            handler.beforeInsert(Trigger.new);
        } 
    }
}