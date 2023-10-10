/**
* @author: Cory Bartholomew (ATG)
* @date: 02-2021
* @description Trigger handler for Order.
*/ 
public with sharing class CDdOrderTriggerHandler {
    public void afterUpdate(List<Order> newList, Map<Id,Order> oldMap){
        CDdOrderTriggerHelper.activateOrders(newList, oldMap); 
        CDdOrderTriggerHelper.generateContractsFromOrders(newList, oldMap);   
    }
}