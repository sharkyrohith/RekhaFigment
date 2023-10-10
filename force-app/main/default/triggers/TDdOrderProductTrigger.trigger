trigger TDdOrderProductTrigger on OrderItem (after insert, after update) {
    CDdOrderProductTriggerHandler handler = new CDdOrderProductTriggerHandler();
      
    if (Trigger.isAfter){
        if (Trigger.isInsert) {
            handler.afterInsert(Trigger.new, Trigger.oldMap);
        }
        
        if (Trigger.isUpdate) {
            handler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}