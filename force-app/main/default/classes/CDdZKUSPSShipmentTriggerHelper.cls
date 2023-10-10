/**
 * @description       : Helper for the zkusps__Shipment__c Handler
 * @author            : Jose Vega
 * @last modified on  : 05-14-2022
 * @last modified by  : Jose Vega
**/
public with sharing class CDdZKUSPSShipmentTriggerHelper {

    public static final Feature_Flags__c FEATURE_FLAG = Feature_Flags__c.getInstance();
    
    /**
    * @description BZAP-13704 Convert USPS PB to Code
    * @author Jose Vega | 05-12-2022 
    * @param List<zkusps__Shipment__c> newList 
    * @param Map<Id zkusps__Shipment__c> oldMap 
    **/
    public static void updateCaseDeliveryStatus(List<zkusps__Shipment__c> newList, Map<Id,zkusps__Shipment__c> oldMap) {
        if (FEATURE_FLAG.Disable_USPS_Update_Case_Delivery_Status__c) {
            return;
        }

        List<Case> casesToUpdate = new List<Case>();

        for (zkusps__Shipment__c shipmentRec : newList){
            if (isDelivered(shipmentRec)) {
                Case caseToUpdate = new Case(Id = shipmentRec.Case__c, Tablet_Received_Date_2__c = System.Now());
                if (shipmentRec.Case__r.Status != CDdSupportConstants.CLOSED_STATUS && shipmentRec.Case__r.Status != CDdSupportConstants.ACTIVATED_STATUS) {
                    caseToUpdate.Status = CDdSupportConstants.RECEIVED_STATUS;
                }
                
                casesToUpdate.add(caseToUpdate);
            }else if(isReturnToSender(shipmentRec)) {
                casesToUpdate.add(new Case(Id = shipmentRec.Case__c, Status = CDdSupportConstants.RETURN_TO_SENDER_STATUS, Tablet_Returned__c = System.Now()));
            }
        }

        if (!casesToUpdate.isEmpty()) {
            update casesToUpdate;
        }
   }

    private static Boolean isDelivered(zkusps__Shipment__c shipmentRec) {
        return shipmentRec.Case__c != null && shipmentRec.Case__r.Tablet_Received_Date_2__c == null && shipmentRec.zkusps__isDelivered__c;
    }

    private static Boolean isReturnToSender(zkusps__Shipment__c shipmentRec) {
        return shipmentRec.Case__c != null && shipmentRec.zkusps__ReturnedToSender__c && shipmentRec.zkusps__lastTrackUpdateStatus__c == 'Delivered, To Original Sender';
    }
}