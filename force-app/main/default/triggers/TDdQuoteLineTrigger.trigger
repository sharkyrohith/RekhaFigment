trigger TDdQuoteLineTrigger on SBQQ__QuoteLine__c (after update, after insert) {
    CDdQuoteLineTriggerHandler handler = new CDdQuoteLineTriggerHandler();

    if(Trigger.isAfter){
        if(Trigger.isUpdate){
            handler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
        if(Trigger.isInsert){
            handler.afterInsert(Trigger.new, Trigger.oldMap);
        }
    }
}