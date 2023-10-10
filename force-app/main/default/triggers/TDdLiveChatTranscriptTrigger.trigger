trigger TDdLiveChatTranscriptTrigger on LiveChatTranscript (before insert, before update, after insert, after update) {
    Boolean runV2Trigger = CDdExperimentSvc.getCustomSettingFeatureFlag('Enable_LCT_Trigger_Optimization__c');
    if (runV2Trigger) {
        CDdLiveChatTransTriggerHandlerV2 handler = new CDdLiveChatTransTriggerHandlerV2(trigger.new);
        if(Trigger.isAfter) {
            if(Trigger.isInsert) {
                handler.afterInsert(Trigger.newMap);
            } else if(Trigger.isUpdate) {
                handler.afterUpdate(Trigger.newMap, Trigger.oldMap);
            }
        } else if (Trigger.isBefore){
            if(Trigger.isInsert) {
                handler.beforeInsert(Trigger.new);
            } else if(Trigger.isUpdate){
                handler.beforeUpdate(Trigger.newMap,Trigger.oldMap);
            }
        }
    } else {
        CDdLiveChatTranscriptTriggerHandler handler = new CDdLiveChatTranscriptTriggerHandler();
        if(Trigger.isAfter) {
            if(Trigger.isInsert) {
                handler.afterInsert(Trigger.newMap);
            } else if(Trigger.isUpdate) {
                handler.afterUpdate(Trigger.newMap, Trigger.oldMap);
            }
        } else if (Trigger.isBefore){
            if(Trigger.isInsert) {
                handler.beforeInsert(Trigger.new);
            } else if(Trigger.isUpdate){
                handler.beforeUpdate(Trigger.newMap,Trigger.oldMap);
            }
        }
    }
}