/**
 * @description       : Helper methods for the Zkmulti MCShipment trigger handler
 * @author            : Jose Vega
 * @group             : 
 * @last modified on  : 04-25-2022
 * @last modified by  : Jose Vega
**/
public with sharing class CDdZkmultiMCShipmentTriggerHelper {

   public static void deliveredCaseUpdate(List<zkmulti__MCShipment__c> newList, Map<Id,zkmulti__MCShipment__c> oldMap) {
        List<Case> casesToUpdate = new List<Case>();

        for (zkmulti__MCShipment__c shipmentRec : newList){
            if (
                shipmentRec.Case__c != null && 
                shipmentRec.zkmulti__Delivered__c && 
                shipmentRec.Case__r.Tablet_Received_Date_2__c == null && 
                shipmentRec.Date_returned_to_sender__c == null) {
                    casesToUpdate.add(new Case(Id = shipmentRec.Case__c, Status = determineStatus(shipmentRec), Tablet_Received_Date_2__c = shipmentRec.zkmulti__Actual_Delivery_Date__c));
            }
        }

        if (!casesToUpdate.isEmpty()) {
            update casesToUpdate;
        }
   }

   private static String determineStatus(zkmulti__MCShipment__c shipmentRec) {
       if (shipmentRec.Case__r.Status != CDdSupportConstants.CLOSED_STATUS && shipmentRec.Case__r.Status != CDdSupportConstants.ACTIVATED_STATUS) {
           return CDdSupportConstants.RECEIVED_STATUS;
       } else {
           return shipmentRec.Case__r.Status;
       }
   }
}