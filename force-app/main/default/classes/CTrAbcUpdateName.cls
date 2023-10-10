/**
 * @author: Raju Lakshman
 * @date: Feb 2021
 * @description Example of a Metadata Trigger - note that the class can be either with or without sharing depending on the requirements.
 */
public with sharing class CTrAbcUpdateName extends CDdTriggerHandler {
    // Best practice: Have these class level variables so that we dont have to send these in method arguments
    private List<abc__c> triggerList;
    private Map<Id, abc__c> triggerMapOld;

    /**
     * @description Constructor that sets class variables based on Trigger context vars
     */
    public CTrAbcUpdateName() {
        Boolean isDelete = getTriggerContext() == CDdTriggerHandler.TriggerContext.BEFORE_DELETE ||
                           getTriggerContext() == CDdTriggerHandler.TriggerContext.AFTER_DELETE;
        this.triggerList = isDelete ? (List<abc__c>)trigger.old : (List<abc__c>)trigger.new;
        this.triggerMapOld = (Map<Id, abc__c>) Trigger.oldMap;
    }

    /**
     * @description Overriden event handlers.
     *
     * The parent CDdTriggerHandler code will take care of calling the correct method
     *
     * Override only those methods you wish to have business logic on.
     */

    public override void beforeInsert() {
        updateName();
    }

    public override void beforeUpdate() {
        updateName();
    }

    /**
     * @description Business logic will go here in private methods.
     *
     */
    private void updateName() {
        if (!Test.isRunningTest()) { // running this only for test class execution to give max coverage on CDdTriggerHandler Framework
            return;
        }
        Boolean isUpdate = getTriggerContext() == CDdTriggerHandler.TriggerContext.BEFORE_UPDATE;
        Boolean isInsert = getTriggerContext() == CDdTriggerHandler.TriggerContext.BEFORE_INSERT;
        for (abc__c rec : triggerList) {
            if (isInsert || (isUpdate && isFieldUpdated(rec,'New_Field__c') && rec.New_Field__c)) {
                rec.Name = 'abc' + System.now().getTime();
            }
        }
    }
}