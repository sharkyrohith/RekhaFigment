/**
 * @description       : Trigger for zkmulti__MCCheckpoint__c object
 * @author            : BizApps Team
 * @description		  : BASD-54056 Tablet Returned to Sender not Applying Correctly
**/ 
trigger zkmultiMCCheckpointTrigger on zkmulti__MCCheckpoint__c (after insert) {
    zkmultiMCCheckpointTriggerHandler handler = new zkmultiMCCheckpointTriggerHandler();
    if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            handler.afterInsert(Trigger.new);
        }
    }
}