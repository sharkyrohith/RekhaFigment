/**
 * @description       : EmailMessage trigger
 * @author            : Jose Vega
 * @last modified on  : 10-28-2022
 * @last modified by  : Jose Vega
**/
trigger TDdEmailMessage on EmailMessage (before insert, after insert, before delete) {

    if (!CDdExperimentSvc.canRun('EmailMessage__c')) {
        return;
    }
        
    if (Trigger.isAfter){
        if (Trigger.IsInsert) {
            CDdEmailMessageTriggerHandler.handleAfterInsertEmailMessage(Trigger.new);
        }
    }
    
    if (Trigger.isBefore){
        if (Trigger.IsDelete) {
            CDdEmailMessageTriggerHandler.handleBeforeDeleteEmailmessage(Trigger.old);
        }
    }
}