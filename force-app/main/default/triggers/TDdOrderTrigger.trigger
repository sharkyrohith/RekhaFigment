trigger TDdOrderTrigger on Order (after update) {
    CDdOrderTriggerHandler handler = new CDdOrderTriggerHandler();
    
    if (Trigger.isBefore){
        if (Trigger.isInsert) {
           
        } else if(Trigger.isUpdate) {
            
        } 
    }
    
    if (Trigger.isAfter){
        if (Trigger.isInsert) {
            
        } else if(Trigger.isUpdate) {
            handler.afterUpdate(Trigger.new,Trigger.oldMap);
        }
    }
}