trigger TDdAccountTrigger on Account (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

    if(CDdExperimentSvc.getCustomSettingFeatureFlag('Disable_Account_Trigger__c')) return; 
	if (! CDdRecursionUtils.isRunnable('TDdAccountTrigger')) return;

    CDdAccountTriggerHandler handler = new CDdAccountTriggerHandler();

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
            handler.afterInsert(Trigger.newMap);
        } else if(Trigger.isUpdate){
            handler.afterUpdate(Trigger.newMap,Trigger.oldMap);
        } else if (Trigger.isDelete) {
            handler.afterDeleteOrUndelete(Trigger.oldMap.values());
        } else if (Trigger.isUndelete) {
            handler.afterDeleteOrUndelete(Trigger.new);
        }
    }  
}