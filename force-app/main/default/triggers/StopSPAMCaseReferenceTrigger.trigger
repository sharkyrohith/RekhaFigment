trigger StopSPAMCaseReferenceTrigger on Stop_Spam_Case_Reference__c (
    after insert,
    after update,
    after delete,
    after undelete) 
{
	StopSPAMcaseTriggerHandler triggerHandler = new StopSPAMcaseTriggerHandler();
    triggerHandler.run('Stop_Spam_Case_Reference__c');
}