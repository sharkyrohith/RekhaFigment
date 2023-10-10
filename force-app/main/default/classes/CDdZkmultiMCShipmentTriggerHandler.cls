/**
 * @description       : Handler for the zkmulti__MCShipment__c object
 * @author            : Jose Vega
 * @group             : 
 * @last modified on  : 04-22-2022
 * @last modified by  : Jose Vega
**/
public with sharing class CDdZkmultiMCShipmentTriggerHandler {
    public void afterInsert(List<zkmulti__MCShipment__c> newList){
        CDdZkmultiMCShipmentTriggerHelper.deliveredCaseUpdate(newList,null);
    }
    public void afterUpdate(List<zkmulti__MCShipment__c> newList,Map<Id, zkmulti__MCShipment__c> oldMap){
        CDdZkmultiMCShipmentTriggerHelper.deliveredCaseUpdate(newList, oldMap);       
    }
}