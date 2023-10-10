/**
 * @author: Raju Lakshman
 * @date: Feb 2021
 * @description Example of a single handler for a trigger approach.
 *              trigger calls this with: new CTrAbcTriggerHandler().run('abc__c');
 */

public without sharing class CTrAbcTriggerHandler extends CDdTriggerHandler{

    // Best practice: Have these class level variables so that we dont have to send these in method arguments
    private List<abc__c> triggerList;
    private Map<Id, abc__c> triggerMapOld;

    /**
     * @description Constructor that sets class variables based on Trigger context vars
     */
    public CTrAbcTriggerHandler() {
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

    public override void afterInsert() {
        createNewRecord();
    }

    public override void beforeUpdate() {
        updateName();
    }

    public override void afterUpdate() {
        createNewRecord();
    }

    public override void beforeDelete() {
        validateDelete();
    }

    public override void afterDelete() {
        createNewRecord();
    }

    public override void afterUndelete() {
        createNewRecord();
    }

    /**
     * @description Business logic will go here in private methods.
     *
     * This can also go in helper classes, but one loses the ability to use boilerplate code in CDdTriggerHandler.
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

    private void validateDelete() {
        if (!Test.isRunningTest()) { // running this only for test class execution to give max coverage on CDdTriggerHandler Framework
            return;
        }
        for (abc__c rec : triggerList) {
            if (rec.New_Field__c) {
                rec.addError('you cannot delete this record');
            }
        }
    }

    private void createNewRecord() {
        if (!Test.isRunningTest()) { // running this only for test class execution to give max coverage on CDdTriggerHandler Framework
            return;
        }
        List<abc__c> toInsert = new List<abc__c>();
        for (abc__c rec : triggerList) {
            if (isNewOrFieldUpdated(rec,'New_Field__c') && rec.New_Field__c) {
                toInsert.add(new abc__c());
            }
        }
        insert toInsert;
    }

}