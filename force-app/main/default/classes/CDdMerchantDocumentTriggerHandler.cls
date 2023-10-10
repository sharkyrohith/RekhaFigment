/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 03/08/2021
*
* @group Trigger Handler
*
* @description Trigger handler method implementation for Merchant Document
**************************************************************************************************************************************/
public class CDdMerchantDocumentTriggerHandler{

    public void afterInsert(List<Merchant_Document__c> newList) {
        CDdMerchantDocumentHelper.handleOpportunityUpdatesForBusinessVerificationDocument(newList);
    }

    public void afterUpdate(Map<Id, Merchant_Document__c> newMap, Map<Id, Merchant_Document__c> oldMap) {
        CDdMerchantDocumentHelper.handleOpportunityUpdatesForBusinessVerificationDocument(newMap.values());
    }
    
    public void afterDelete(Map<Id, Merchant_Document__c> oldMap) {
        CDdMerchantDocumentHelper.handleOpportunityUpdatesForBusinessVerificationDocument(oldMap.values());
    }    
}