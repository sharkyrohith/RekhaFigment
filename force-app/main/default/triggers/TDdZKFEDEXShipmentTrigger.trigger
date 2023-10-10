/**
 * @description       : zkfedex__Shipment__c trigger
 * @author            : Jose Vega
 * @last modified on  : 10-28-2022
 * @last modified by  : Jose Vega
**/
trigger TDdZKFEDEXShipmentTrigger on zkfedex__Shipment__c (before insert, after insert, before update) {

    if (!CDdExperimentSvc.canRun('zkfedex_Shipment__c')) {
        return;
    }

    CDdZKShipmentHandler handler = new CDdZKShipmentHandler();
    //FedEx Handler is strictly for zkfedex__Shipment__c object while the CDdZKShipmentHandler handles
    // multiple couriers and uses SObject.
    CDdZKFedexShipmentHandler fedexHandler = new CDdZKFedexShipmentHandler();

    if(Trigger.isBefore){
        if(Trigger.isUpdate) {
            handler.beforeUpdate(Trigger.newMap,Trigger.oldMap);
            fedexHandler.beforeUpdate(Trigger.newMap, Trigger.oldMap);
        }
        if(Trigger.isInsert){
            fedexHandler.beforeInsert(Trigger.new);
        }
     } else if (Trigger.isAfter){
         if(Trigger.isInsert) {
            handler.afterInsert(Trigger.new);
         }
     } 
}