/*
* @author: Gregory Dorsey (Cognizant)
* @date: 05-2021
* @description Trigger handler for Salesforce CPQ Quotes Lines (SBQQ__QuoteLine__c).
*/ 
public with sharing class CDdQuoteLineTriggerHandler {
    public void afterUpdate(List<SBQQ__QuoteLine__c> newList, Map<Id,SBQQ__QuoteLine__c> oldMap){        
        CDdQuoteLineTriggerHelper.updateQuoteFields(newList);
    }
    public void afterInsert(List<SBQQ__QuoteLine__c> newList, Map<Id,SBQQ__QuoteLine__c> oldMap){        
        CDdQuoteLineTriggerHelper.updateQuoteFields(newList);
    }
}