/**
 * @description       : Trigger for Chatter Post Notes Template object
 * @author            : Jose Vega
 * @last modified on  : 05-14-2022
 * @last modified by  : Jose Vega
**/
trigger TDdChatterPostNotesTemplateTrigger on Chatter_Post_Notes_Template__c (after insert, after update, after delete) {
    CDdCPNTTriggerHandler handler = new CDdCPNTTriggerHandler();
    if (Trigger.isAfter){
        if (Trigger.isInsert){
            handler.afterInsert(Trigger.New);
        } else if (Trigger.isUpdate){
            handler.afterUpdate(Trigger.New, Trigger.oldMap);
        } else if (Trigger.isDelete) {
            handler.afterDelete(Trigger.oldMap);
        }
    }
}