trigger TDdCommunityAlertTrigger on CommunityAlert__c (after insert, after update) {
    CDdCommunityAlertTriggerHandler handler = new CDdCommunityAlertTriggerHandler();
    if (Trigger.isAfter){
        if (Trigger.isInsert){
            handler.afterInsert(Trigger.New);
        } else if (Trigger.isUpdate){
            handler.afterUpdate(Trigger.New, Trigger.oldMap);
        }
    }

}