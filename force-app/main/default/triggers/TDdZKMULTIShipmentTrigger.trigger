/**
 * TDdZKMULTIShipmentTrigger
**/
trigger TDdZKMULTIShipmentTrigger on zkmulti__MCShipment__c (before insert, before update, after insert, after update) {
    CDdZKShipmentHandler handler = new CDdZKShipmentHandler();
    CDdZKMultiShipmentHandler zKHandler = new CDdZKMultiShipmentHandler();
    if(Trigger.isBefore){
       if(Trigger.isInsert){
            zKHandler.beforeInsert(Trigger.new);
       }else if(Trigger.isUpdate){
            handler.beforeUpdate(Trigger.newMap,Trigger.oldMap);
            zKHandler.beforeUpdate(Trigger.newMap,Trigger.oldMap);
       }
    } else if (Trigger.isAfter){
        if(Trigger.isInsert){                                                       
            handler.afterInsert(Trigger.new);
            zKHandler.afterInsert(Trigger.new);
        }    
        else if(Trigger.isUpdate){
            zKHandler.afterUpdate(Trigger.newMap,Trigger.oldMap);
        }    
    } 

}