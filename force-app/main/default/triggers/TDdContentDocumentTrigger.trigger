/**
 * @description       : ContentDocument Trigger
 * @author            : Jose Vega
 * @last modified on  : 10-28-2022
 * @last modified by  : Jose Vega
**/
trigger TDdContentDocumentTrigger on ContentDocument (before delete) {

    if (!CDdExperimentSvc.canRun('ContentDocument__c')) {
        return;
    }

    if (Trigger.isBefore && Trigger.isDelete) {
        CDdContentDocumentTriggerHandler contentDocumentTriggerHandler = new CDdContentDocumentTriggerHandler();
        contentDocumentTriggerHandler.beforeDelete(Trigger.old);
    }
}