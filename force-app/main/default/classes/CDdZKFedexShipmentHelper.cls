/**
 * @description       : Helper for the Handler of zkfedex shipment object
 * @author            : Jose Vega
 * @last modified on  : 05-13-2022
 * @last modified by  : Jose Vega
**/
public with sharing class CDdZKFedexShipmentHelper {

    public static final Feature_Flags__c FEATURE_FLAG = Feature_Flags__c.getInstance();

    /**
    * @description BZAP-13438 - Convert FedEx PB - Update Tablet Received Date
    * @author Jose Vega | 05-13-2022 
    * @param List<zkfedex__Shipment__c> newList 
    * @param Map<Id zkfedex__Shipment__c> oldMap 
    **/
    public static void updateTabletReceivedDate(List<zkfedex__Shipment__c> newList, Map<Id,zkfedex__Shipment__c> oldMap) {
        if (FEATURE_FLAG.Disable_FedEX_Update_Tablet_Received_Da__c) {
            return;
        }

        List<Case> casesToUpdate = new List<Case>();
        for (zkfedex__Shipment__c shipmentRec : newList){
            if (isTabletDelivered(shipmentRec)) {
                Case caseToUpdate = new Case(Id = shipmentRec.Case__c, Tablet_Received_Date_2__c = System.Now());
                if (shipmentRec.Case__r.Status != CDdSupportConstants.CLOSED_STATUS && shipmentRec.Case__r.Status != CDdSupportConstants.ACTIVATED_STATUS && shipmentRec.Case__r.Status != CDdSupportConstants.RETURN_TO_SENDER_STATUS) {
                    caseToUpdate.Status = CDdSupportConstants.RECEIVED_STATUS;
                }
                casesToUpdate.add(caseToUpdate);
            }
        }

        if (!casesToUpdate.isEmpty()) {
            update casesToUpdate;
        }
    }

    /**
    * @description BZAP-13438 - Convert FedEx PB - Fill In FedEx Tracking Number
    * @author Jose Vega | 05-13-2022 
    * @param List<zkfedex__Shipment__c> newList 
    * @param Map<Id zkfedex__Shipment__c> oldMap 
    **/
    public static void fillInFedExTrackingNumberWhenShipmentCreated(List<zkfedex__Shipment__c> newList, Map<Id,zkfedex__Shipment__c> oldMap) {
        if (FEATURE_FLAG.Disable_FedEX_Fill_In_FedEx_Tracking_Num__c) {
            return;
        }

        List<Case> casesToUpdate = new List<Case>();
        for (zkfedex__Shipment__c shipmentRec : newList){
            if (shipmentCreatedOrAddsMaster(shipmentRec)) {
                Case caseToUpdate = new Case(Id = shipmentRec.Case__c, Tablet_Tracking_FedEx__c = shipmentRec.zkfedex__MasterTrackingId__c);
                casesToUpdate.add(caseToUpdate);
            }
        }

        if (!casesToUpdate.isEmpty()) {
            update casesToUpdate;
        }
    }

    private static Boolean isTabletDelivered(zkfedex__Shipment__c shipmentRec) {
        return shipmentRec.zkfedex__Delivered__c && shipmentRec.Case__c != null && shipmentRec.Case__r.Tablet_Received_Date_2__c == null && shipmentRec.Case__r.Status != CDdSupportConstants.RETURN_TO_SENDER_STATUS;
    }

    private static Boolean shipmentCreatedOrAddsMaster(zkfedex__Shipment__c shipmentRec) {
        return shipmentRec.zkfedex__MasterTrackingId__c != null && shipmentRec.Case__c != null && shipmentRec.Case__r.Tablet_Tracking_FedEx__c == null;
    }
}