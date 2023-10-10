trigger TDdSocialPostTrigger on SocialPost (before insert, before update, after insert, after update) {
    CDdSocialPostTriggerHandler handler = new CDdSocialPostTriggerHandler();
    
    if(Trigger.isBefore) {
		if(Trigger.isInsert) {
			handler.beforeInsert(Trigger.new);
		} else if (Trigger.isUpdate) {
			handler.beforeUpdate(Trigger.new, Trigger.oldMap);
		}
	} else if(Trigger.isAfter) {
		if(Trigger.isInsert) {
			handler.afterInsert(Trigger.new);
		} else if (Trigger.isUpdate) {
			handler.afterUpdate(Trigger.new, Trigger.oldMap);
		}
	}
}