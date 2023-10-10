trigger VTask on Task (before insert, before update) {
    
    VTaskTriggerHandler vHandler = new VTaskTriggerHandler();
    
    if (Trigger.isBefore){
        if (Trigger.isInsert){
            //vHandler.onBeforeInsert(Trigger.new);
        } else if(Trigger.isUpdate){
            //vHandler.onBeforeUpdate(Trigger.newMap,Trigger.oldMap);
        }
    }
    
}