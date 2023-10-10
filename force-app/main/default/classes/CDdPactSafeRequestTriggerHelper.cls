/**
 * @description Helper for the pactsafe1__PactSafeRequest__c trigger/handler.
 *  Introduced by BZAP-13135 to support the PactSafe integration.
 *
 * @see TDdPactSafeRequestTrigger
 * @see CDdPactSafeRequestTriggerHandler
 **/
public with sharing class CDdPactSafeRequestTriggerHelper {
    private static final String QUOTE_QUERY = 'SELECT Id,{0} FROM SBQQ__Quote__c WHERE Id IN :quoteIds';

    /**
     * @description Updates the link from pactsafe1__PactSafeRequest__c to SBQQ__Quote__c records
     *  based on the currently configured field. According to requirements the newest pactsafe1__PactSafeRequest__c
     *  object will always be the relevant one, so we shoud set it on the SBQQ__Quote__c record
     *  when a new request record is inserted regardless of its current value.
     *
     * @param newRequests (List<pactsafe1__PactSafeRequest__c>)
     * @return (SBQQ__Quote__c)
     * @see CDdPactSafeRequestTriggerHandler.afterInsert
     */
    public static List<SBQQ__Quote__c> linkToQuote(List<pactsafe1__PactSafeRequest__c> newRequests){
        if(newRequests == null || newRequests.isEmpty()){
            return new List<SBQQ__Quote__c>();
        }

        Map<Id,pactsafe1__PactSafeRequest__c> requestsByQuoteId = new Map<Id,pactsafe1__PactSafeRequest__c>();
        for(pactsafe1__PactSafeRequest__c currentRequest : newRequests){
            if(currentRequest.Quote__c != null){
                requestsByQuoteId.put(currentRequest.Quote__c, currentRequest);
            }
        }

        String quoteFieldName = PSExtensionMainSettings.getRequestFieldName;
        Set<Id> quoteIds = requestsByQuoteId.keySet();
        String quoteQuery = String.format(
            QUOTE_QUERY,
            new List<String>{quoteFieldName}
        );
        List<SBQQ__Quote__c> relevantQuotes = Database.query(quoteQuery);

        for(SBQQ__Quote__c currentQuote : relevantQuotes){
            pactsafe1__PactSafeRequest__c relevantRequest = requestsByQuoteId.get(currentQuote.Id);
            currentQuote.put(quoteFieldName, relevantRequest.Id);
        }

        if(relevantQuotes.isEmpty()){
            return relevantQuotes;
        }

        update relevantQuotes;
        return relevantQuotes;
    }
}