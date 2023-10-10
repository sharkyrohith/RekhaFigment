/***********************************************************************************************************
* @author Venkat D
* @date 08/02/2022
*
* @group Trigger
*
* @description Trigger for Event object

*************************************************************************************************************/
trigger TDdEventTrigger on Event (before insert, before update, after insert, after update, before delete,after delete) {
    CDdEventTriggerHandler handler = new CDdEventTriggerHandler();
    if (Trigger.isBefore){
        if (Trigger.isInsert) {
            handler.beforeInsert(Trigger.new);
        } else if(Trigger.isUpdate) {
            handler.beforeUpdate(Trigger.newMap, Trigger.oldMap);
        } else if(Trigger.isDelete){
            handler.beforeDelete(Trigger.oldMap);
        }
    }
    
    if (Trigger.isAfter){
        if (Trigger.isInsert) {
            handler.afterInsert(Trigger.newMap);
        } else if(Trigger.isUpdate) {
            handler.afterUpdate(Trigger.newMap, Trigger.oldMap);
        } else if(Trigger.isDelete){
            handler.afterDelete(Trigger.oldMap);
        }
    }
    
}