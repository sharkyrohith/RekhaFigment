/**
 * @description       : Handler for the zkfedex shipment object
 * @author            : Jose Vega
 * @last modified on  : 05-14-2022
 * @last modified by  : Jose Vega
**/
public with sharing class CDdZKFedexShipmentHandler {
    public void beforeInsert(List<zkfedex__Shipment__c> newList){
        CDdZKFedexShipmentHelper.updateTabletReceivedDate(newList, null);
        CDdZKFedexShipmentHelper.fillInFedExTrackingNumberWhenShipmentCreated(newList, null);
    }
    
    public void beforeUpdate(Map<Id, zkfedex__Shipment__c> newMap, Map<Id, zkfedex__Shipment__c> oldMap){
        CDdZKFedexShipmentHelper.updateTabletReceivedDate(newMap.values(), oldMap);
        CDdZKFedexShipmentHelper.fillInFedExTrackingNumberWhenShipmentCreated(newMap.values(), oldMap);
    }
}