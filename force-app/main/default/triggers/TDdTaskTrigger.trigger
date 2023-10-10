/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 07/12/2019
*
* @group Trigger
*
* @description Trigger for task object

**************************************************************************************************************************************/
trigger TDdTaskTrigger on Task (before insert, before update, after insert, after update, before delete) {
	CDdTaskTriggerHandler handler = new CDdTaskTriggerHandler();
    if (Trigger.isAfter){
        if (Trigger.isInsert) {
            handler.afterInsert(Trigger.new);
        } else if(Trigger.isUpdate) {
            handler.afterUpdate(Trigger.newMap, Trigger.oldMap);
        } 
    }
    if (Trigger.isBefore){

        if(Trigger.isInsert || Trigger.isUpdate)
        {
            handler.beforeUpsert(Trigger.new);
        }
        if(Trigger.isInsert)
        {
            handler.beforeInsert(Trigger.new);
        }
        if(Trigger.isDelete){
            handler.beforeDelete(Trigger.old);
        }
    }
}