trigger CDdCampaignMemberTrigger on CampaignMember (before insert, after insert, after delete) {
    if(Trigger.isBefore){
        if(Trigger.isInsert) {
            CDdCampaignMemberTriggerHandler.beforeInsert(Trigger.new);
        }
    } else if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            CDdCampaignMemberTriggerHandler.afterInsert(Trigger.new);
        } else if (Trigger.isDelete) {
            CDdCampaignMemberTriggerHandler.afterDeleteOrUndelete(Trigger.oldMap.values());
        }
    }
}