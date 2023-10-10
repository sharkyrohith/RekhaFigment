/**
 * @description Handler for the pactsafe1__PactSafeRequest__c trigger.
 *  Introduced by BZAP-13135 to support the PactSafe integration.
 *
 * @see TDdPactSafeRequestTrigger
 * @see CDdPactSafeRequestTriggerHelper
 **/
public with sharing class CDdPactSafeRequestTriggerHandler {
    public void afterInsert(List<pactsafe1__PactSafeRequest__c> newList){
        CDdPactSafeRequestTriggerHelper.linkToQuote(newList);
    }
}