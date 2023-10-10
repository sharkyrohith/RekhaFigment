/**
* @author: Cory Bartholomew (ATG)
* @date: 04-2021
* @description Trigger handler for Order Products.
*/ 
public with sharing class CDdOrderProductTriggerHandler {
    
    public void afterInsert(List<OrderItem> newList, Map<Id,OrderItem> oldMap){  
        CDdOrderProductTriggerHelper.postSaleCreateCases(newList);
    }
    
    public void afterUpdate(List<OrderItem> newList, Map<Id,OrderItem> oldMap) {   
        CDdOrderProductTriggerHelper.postSaleActivateOrders(newList, oldMap);
    }
}