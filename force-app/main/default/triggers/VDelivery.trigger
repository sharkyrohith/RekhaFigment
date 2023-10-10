trigger VDelivery on Delivery__c (before insert, before update) {
	if (! CDdRecursionUtils.isRunnable('VDelivery')) return;
    VDeliveryTriggerHandler vHandler = new VDeliveryTriggerHandler();
    
    if (Trigger.isBefore) {
        If (Trigger.isInsert){
            vHandler.onBeforeInsert(Trigger.new);
        } else if (Trigger.isUpdate){
            vHandler.onBeforeUpdate(Trigger.newMap, Trigger.oldMap);
        }
    }
}