/********************************************************************************************************************
* @author Ganesh
* @date 10/27/2022
*
* @group Trigger
*
* @description Trigger for Campaign Item object
**************************************************************************************************************************************/
trigger TDdCampaigntemTrigger on Campaign_Item__c (before insert, before update, before delete, after insert, after update, after delete) {
  CDdCampaignItemTriggerHandler handler = new CDdCampaignItemTriggerHandler();
    if (Trigger.isAfter){
        if (Trigger.isInsert) {
            handler.afterInsert(Trigger.newMap);
        } else if(Trigger.isUpdate) {
            handler.afterUpdate(Trigger.newMap, Trigger.oldMap);
        } else if(Trigger.isDelete){
            handler.afterDelete(Trigger.oldMap);
        }
    }
    if (Trigger.isBefore){
        if (Trigger.isInsert) {
            handler.beforeInsert(Trigger.new);
        } else if(Trigger.isUpdate) {
            handler.beforeUpdate(Trigger.newMap, Trigger.oldMap);
        } else if(Trigger.isDelete){
            handler.beforeDelete(Trigger.oldMap);
        }
    }
}