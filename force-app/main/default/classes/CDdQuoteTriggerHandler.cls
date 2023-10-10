/*
* @author: Cory Bartholomew (ATG)
* @date: 05-2021
* @description Trigger handler for Salesforce CPQ Quotes (SBQQ__Quote__c).
*/ 
public with sharing class CDdQuoteTriggerHandler{
    public void beforeInsert(List<SBQQ__Quote__c> newList){
        CDdQuoteTriggerHelper.updateRecordTypeFromStatus(newList);
        CDdQuoteTriggerHelper.setStandardPriceBookBeforeInsert(newList);
        CDdQuoteTriggerHelper.validateBbotOpportunityOnApprovalSubmission(newList, null);
        CDdQuoteTriggerHelper.setDefaultValuesForAdditionalTermField(newList, null);  
    }

    public void beforeUpdate(List<SBQQ__Quote__c> newList, Map<Id,SBQQ__Quote__c> oldMap){
        CDdQuoteTriggerHelper.updateBbotEstimatedActivationDate(newList, oldMap);
        CDdQuoteTriggerHelper.updateBbotSubscriptionEndDate(newList, oldMap);
        CDdQuoteTriggerHelper.validateBbotOpportunityOnApprovalSubmission(newList, oldMap);
        CDdQuoteTriggerHelper.removeDefaultValuesForAdditionalTermFieldForNonBBOT(newList, oldMap);
        CDdQuoteTriggerHelper.validateBbotQuoteApprovalCommentsOnApprovalSubmission(newList, oldMap);
    }

    public void afterUpdate(List<SBQQ__Quote__c> newList, Map<Id,SBQQ__Quote__c> oldMap){
        CDdQuoteTriggerHelper.updateRecordTypeAfterUpdate(newList,oldMap);
        CDdQuoteTriggerHelper.updateRelatedOpportunities(newList, oldMap);
        CDdQuoteTriggerHelper.processContractSignature(newList,oldMap);
        CDdQuoteTriggerHelper.processVoidedContracts(newList,oldMap);
        CDdQuoteTriggerHelper.updateOptyCountAfterUpdate(newList,oldMap);
    }

    public void afterInsert(List<SBQQ__Quote__c> newList, Map<Id,SBQQ__Quote__c> oldMap){
        CDdQuoteTriggerHelper.setOptyPlatformAfterInsert(newList);
        CDdQuoteTriggerHelper.updateOptyCountAfterInsert(newList);
    }

    public void afterDelete(List<SBQQ__Quote__c> oldList){
        CDdQuoteTriggerHelper.updateOptyCountAfterDelete(oldList);
    }
}