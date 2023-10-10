trigger TDdMerchantCategoryTrigger on Merchant_Category__c (before insert, before update, after insert, after update, before delete, after delete) {

	//if (! CDdRecursionUtils.isRunnable('')) return;

    CDdMerchantCategoryTriggerHandler handler = new CDdMerchantCategoryTriggerHandler();

    if(Trigger.isBefore){
        if(Trigger.isInsert) {
            handler.beforeInsert(Trigger.new);
        } else if(Trigger.isUpdate){
            handler.beforeUpdate(Trigger.newMap,Trigger.oldMap);
        } else if(Trigger.isDelete) {
            handler.beforeDelete(Trigger.oldMap);
        }
    } else if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            // handler.afterInsert(Trigger.new);
        } else if(Trigger.isUpdate){
            // handler.afterUpdate(Trigger.newMap,Trigger.oldMap);
        } else if (Trigger.isDelete) {
            // handler.afterDelete(Trigger.oldMap);
        }
    }  
}