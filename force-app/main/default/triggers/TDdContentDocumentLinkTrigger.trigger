/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 03/08/2021
*
* @group Trigger
*
* @description Trigger for Content Document Link object
**************************************************************************************************************************************/
trigger TDdContentDocumentLinkTrigger on ContentDocumentLink (before insert, after insert, after delete) {

    if (!CDdExperimentSvc.canRun('ContentDocumentLink__c')) {
        return;
    }

    CDdContentDocumentLinkTriggerHandler handler = new CDdContentDocumentLinkTriggerHandler();
    if (Trigger.isBefore){
        if (Trigger.isInsert) {
            handler.beforeInsert(Trigger.new);
        }
    }
    if (Trigger.isAfter){
        if (Trigger.isInsert) {
            handler.afterInsert(Trigger.new);
        } else if(Trigger.isDelete) {
            handler.afterDelete(Trigger.oldMap);
        } 
    }

}