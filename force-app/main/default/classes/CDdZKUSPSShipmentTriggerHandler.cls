/**
 * @description       : Handler for the zkusps__Shipment__c object
 * @author            : Jose Vega
 * @last modified on  : 05-12-2022
 * @last modified by  : Jose Vega
**/
public with sharing class CDdZKUSPSShipmentTriggerHandler {
    public void afterInsert(List<zkusps__Shipment__c> newList){
        CDdZKUSPSShipmentTriggerHelper.updateCaseDeliveryStatus(newList,null);
    }
    public void afterUpdate(List<zkusps__Shipment__c> newList,Map<Id, zkusps__Shipment__c> oldMap){
        CDdZKUSPSShipmentTriggerHelper.updateCaseDeliveryStatus(newList, oldMap);       
    }
}