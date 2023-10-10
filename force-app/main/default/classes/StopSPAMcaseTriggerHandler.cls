/**
 * @author: Schubert Tonarelli
 * @date: 2023-06-21
 * @description Example of a single handler for a trigger approach.
 *              trigger calls this with: new StopSPAMcaseTriggerHandler().run('Stop_Spam_Case_Reference__c');
 */

public class StopSPAMcaseTriggerHandler extends CDdTriggerHandler{
    /**
     * @description Overriden event handlers.
     *
     * The parent CDdTriggerHandler code will take care of calling the correct method
     *
     * Override only those methods you wish to have business logic on.
     */

    public override void afterInsert() {
        CdStopSpamCaseReferenceService.refreshStopSpamCaseReferenceCache(); 
    }

    public override void afterUpdate() {
        CdStopSpamCaseReferenceService.refreshStopSpamCaseReferenceCache(); 
    }

    public override void afterDelete() {
        CdStopSpamCaseReferenceService.refreshStopSpamCaseReferenceCache(); 
    }

    public override void afterUndelete() {
        CdStopSpamCaseReferenceService.refreshStopSpamCaseReferenceCache(); 
    }
}