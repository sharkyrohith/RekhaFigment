/**
 * @description       : Trigger for the zkusps__Shipment__c object
 * @author            : Jose Vega
 * @last modified on  : 05-12-2022
 * @last modified by  : Jose Vega
**/
trigger TDdZKUSPSShipmentTrigger on zkusps__Shipment__c (after insert, after update) {
    CDdZKUSPSShipmentTriggerHandler handler = new CDdZKUSPSShipmentTriggerHandler();
    if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            handler.afterInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            handler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}