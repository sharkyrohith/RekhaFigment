/**
 * @description       : Trigger for zkmulti__MCShipment__c object
 * @author            : Jose Vega
 * @group             : 
 * @last modified on  : 04-25-2022
 * @last modified by  : Jose Vega
**/
trigger TDdZkmultiMCShipmentTrigger on zkmulti__MCShipment__c (after insert, after update) {
    CDdZkmultiMCShipmentTriggerHandler handler = new CDdZkmultiMCShipmentTriggerHandler();
    if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            handler.afterInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            handler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}