/**
* @author: Cory Bartholomew (ATG)
* @date: 2022-01
* @Logic to update fields in the Commission_Rate__c table when inserted or updated.
*/
public with sharing class CDdCommissionRateTriggerHandler {
    CDdCommissionRateTriggerHelper helper = new CDdCommissionRateTriggerHelper();
    
    public void beforeInsert(List<Commission_Rate__c> newList){
        helper.generateSearchKey(newList);
    }

    public void beforeUpdate(List<Commission_Rate__c> newList){
        helper.generateSearchKey(newList);
    }
}