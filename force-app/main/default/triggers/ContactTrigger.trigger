trigger ContactTrigger on Contact (before insert, before update, after insert, after update) {
	CDdContactTriggerHandler handler = new CDdContactTriggerHandler();
    //BZAP-13556 - False positive for Logic inside Trigger
    if (CDdContactTriggerHelper.getContactFeatureFlag('Disable_Contact_Trigger__c')) {
            return;
        }
	if(Trigger.isBefore){
		if(Trigger.isInsert) {
			handler.beforeInsert(Trigger.new);
		} else if(Trigger.isUpdate){
			handler.beforeUpdate(Trigger.newMap, Trigger.oldMap);
		}
    } else if (Trigger.isafter){
        if (Trigger.isInsert) {
            handler.afterInsert(Trigger.new);
        } 
		else if (Trigger.isUpdate) {
            handler.afterUpdate(Trigger.newMap, Trigger.oldMap);
        } 
    }
    
}