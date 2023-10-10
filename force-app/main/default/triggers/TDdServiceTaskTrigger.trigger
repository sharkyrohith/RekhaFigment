trigger TDdServiceTaskTrigger on Service_Task__c (before update, after update, before insert) {
    if(Trigger.isBefore) {
        if(Trigger.isInsert) {
            CDdServiceTaskHandler.handleBeforeInsert(Trigger.new);
        }
        if(Trigger.isUpdate) {
            CDdServiceTaskHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
        } 
    }
    if(Trigger.isAfter) {
        if(Trigger.isUpdate) {
            CDdServiceTaskHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        } 
    }

}