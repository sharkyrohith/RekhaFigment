trigger TDdAbcTrigger on ABC__c (before insert,before update,after insert,after update,before delete,after delete,after undelete) {
    if (CDdTriggerHandler.TEST_CLASS_USE_METADATA_FRAMEWORK) {
        new CDdMetadataTriggerHandler().run('abc__c');
    } else {
        CTrAbcTriggerHandler triggerHandler = new CTrAbcTriggerHandler();
        if (CDdTriggerHandler.TEST_CLASS_MAX_LOOP_COUNT != null) {
            triggerHandler.setMaxLoopCount(CDdTriggerHandler.TEST_CLASS_MAX_LOOP_COUNT);
        }
        triggerHandler.run('abc__c');
        if (CDdTriggerHandler.TEST_CLASS_MAX_LOOP_COUNT != null) {
            triggerHandler.clearMaxLoopCount();
        }
    }
}