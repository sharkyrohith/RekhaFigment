trigger OpportunityTrigger on Opportunity (before insert, before update, after insert, after update, before delete) {

	if (! CDdRecursionUtils.isRunnable('OpportunityTrigger')) return;

	CDdOpportunityTriggerHandler handler = new CDdOpportunityTriggerHandler(Trigger.new);

	if(Trigger.isBefore) {
		if(Trigger.isInsert) {
			handler.beforeInsert(Trigger.new);
		} else if (Trigger.isUpdate) {
			handler.beforeUpdate(Trigger.new, Trigger.oldMap);
		}else if(Trigger.isDelete){
			handler.beforeDelete(Trigger.old);
		}
	} else if(Trigger.isAfter) {
		if(Trigger.isInsert) {
			handler.afterInsert(Trigger.new);
		} else if (Trigger.isUpdate) {
			handler.afterUpdate(Trigger.new, Trigger.oldMap);
		}
	}
}