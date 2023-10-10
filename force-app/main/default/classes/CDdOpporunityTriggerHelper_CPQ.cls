public with sharing class CDdOpporunityTriggerHelper_CPQ {    
    public static Id CORPORATE_RT_ID = CDdSchemaUtils.OPPORTUNITY_RT.corporateId();
    public static Id CORPORATEAPPROVED_RT_ID = CDdSchemaUtils.OPPORTUNITY_RT.corporateApprovedId();

    @testVisible private static final String CUSTOM_PARTNERSHIP_EXCLUSIVE = 'Exclusive';
    @testVisible private static final String CUSTOM_PARTNERSHIP_PREFERRED = 'Preferred';
    private static final List<String> VALID_CUSTOM_PARTNERSHIPS = new List<String>{
        CUSTOM_PARTNERSHIP_EXCLUSIVE,
        CUSTOM_PARTNERSHIP_PREFERRED
    };

     /**
     * @description Update the cpq order start date if there is a primary quote and the opp activation date is populated on a Marketplace opp
     * @param opps Trigger.new
     * @param oldMap Trigger.oldMap
     */
    public static void updateOrderStartOnActivation(List<Opportunity> opps, Map<Id,Opportunity> oldMap){
        if(!CDdRecursionUtils.isRunnable('CDdOpportunityTrigger_updateOrderStart')){
            return;
        }
        Map<Id, Date> quoteActivationDateMap = new Map<Id, Date>();
        for(Opportunity opp : opps){
            if(
                (opp.StageName == 'Closed Won' || opp.StageName == 'Contract Signed') &&
                opp.RecordTypeId == CDdSchemaUtils.OPPORTUNITY_RT.mlInsideSalesId() &&
                opp.SBQQ__PrimaryQuote__c != null &&
                opp.Activation_Date__c != null &&
                oldMap.get(opp.Id).Activation_Date__c == null
            ){
                quoteActivationDateMap.put(opp.SBQQ__PrimaryQuote__c, opp.Activation_Date__c);
            }
        }
        if(!quoteActivationDateMap.keySet().isEmpty()){
            List<Order> ordersToUpdate = queryRelatedOrders(quoteActivationDateMap.keySet());
            if(ordersToUpdate != null){
                for(Order order : ordersToUpdate){
                    if(quoteActivationDateMap.containsKey(order.SBQQ__Quote__c)){
                        order.EffectiveDate = quoteActivationDateMap.get(order.SBQQ__Quote__c);
                        order.Ready_for_Activation__c = true;
                    }
                }
                update ordersToUpdate;
            }
        }
    }

    /**
     * @description BZAP-15464; Updates Custom_Partnership_Status__c on the Account the Opportunity
     *  was created from when an opportunity reaches a Closed/Won stage and has a Quote with the
     *  a non-null Custom_Partnership_Type__c field value.
     * @param opportunities Trigger.new
     * @param oldOpportunitiesById Trigger.oldMap
     */
    public static void updateAccountCustomPartnershipStatus(List<Opportunity> opportunities, Map<Id,Opportunity> oldOpportunitiesById){
        List<Opportunity> closedWonOpportunities = new List<Opportunity>();
        for(Opportunity currentOpportunity : opportunities){
            Opportunity oldOpportunity = oldOpportunitiesById.get(currentOpportunity.Id);
            if(
                currentOpportunity.StageName == CDdOpportunityConstants.OPPORTUNITY_STAGE_CLOSED_WON &&
                currentOpportunity.StageName != oldOpportunity.StageName
            ){
                closedWonOpportunities.add(currentOpportunity);
            }
        }

        if(closedWonOpportunities.isEmpty()){
            return;
        }

        Map<Id,Opportunity> closedWonOpportunitiesById = new Map<Id,Opportunity>(closedWonOpportunities);
        List<SBQQ__Quote__c> quotesWithCustomPartnerships = [
            SELECT Id,Custom_Partnership_Type__c,SBQQ__Opportunity2__c
            FROM SBQQ__Quote__c
            WHERE
                Custom_Partnership_Type__c != null AND
                Custom_Partnership_Type__c IN :VALID_CUSTOM_PARTNERSHIPS AND
                SBQQ__Opportunity2__c IN :closedWonOpportunitiesById.keySet()
        ];

        if(quotesWithCustomPartnerships.isEmpty()){
            return;
        }

        List<Account> accountsToUpdate = new List<Account>();
        for(SBQQ__Quote__c currentQuote : quotesWithCustomPartnerships){
            Opportunity matchingOpportunity = closedWonOpportunitiesById.get(currentQuote.SBQQ__Opportunity2__c);
            if(matchingOpportunity.AccountId == null){
                continue;
            }

            accountsToUpdate.add(
                new Account(
                    Id = matchingOpportunity.AccountId,
                    Custom_Partnership_Status__c = currentQuote.Custom_Partnership_Type__c
                )
            );
        }

        if(accountsToUpdate.isEmpty()){
            return;
        }

        update accountsToUpdate;
    }

    public static List<Order> queryRelatedOrders(Set<Id> quoteIds){
        List<Order> orders = 
        [
            SELECT Id, SBQQ__Quote__c, EffectiveDate, Status, Ready_for_Activation__c 
            FROM Order 
            WHERE SBQQ__Quote__c IN :quoteIds
            AND Status != 'Activated'
        ];
        return orders;
    }
  
     /** BZAP-12880,BZAP-11903
     * @description this function automates updating the opportunity stage to either Out for Signature or Ready for Signature whether enterprise approvals are
     * needed or not when the submit for approval button is clicked
     */
    public static void updateOpportunityStage (List<Opportunity> opps , Map<Id,Opportunity> oldMap){

        //need recursion check
        if(!CDdRecursionUtils.isRunnable('CDdOpportunityTrigger_updateOppStage')){
            return;
        }

        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();

        for(Opportunity opp : opps){
            Opportunity oldOpp = (oldMap == null) ? null : oldMap.get(opp.Id);

            if((opp.RecordTypeId == CORPORATE_RT_ID || opp.RecordTypeId == CORPORATEAPPROVED_RT_ID) 
                && oldOpp !=null && (opp.sbaa__ApprovalStatus__c != oldOpp.sbaa__ApprovalStatus__c)){
                switch on opp.sbaa__ApprovalStatus__c{
                    when 'Approved'{
                        opp.RecordTypeId = CORPORATEAPPROVED_RT_ID;
                        opp.StageName = 'Ready for Signature';
                    }
                    when 'Pending'{
                        opp.RecordTypeId = CORPORATE_RT_ID;
                        opp.StageName = 'Out for Approvals';
                    }
                    when 'Recalled'{
                    	opp.RecordTypeId = CORPORATE_RT_ID;
                        opp.StageName = 'Negotiating';
                    }
                    when 'Rejected'{
                        opp.RecordTypeId = CORPORATE_RT_ID;
                        opp.StageName = 'Negotiating';
                    }
                }
            }
        }
	}
    
    /*
     * @description Validate that an opportunity has a quote in contract signed status before it can be closed won
     * @param opps Trigger.new
     * @param oldMap Trigger.oldMap
     */
    public static void validateContractSignedOnClosedWon(List<Opportunity> opps){
        if(!CDdRecursionUtils.isRunnable('CDdOpptyTrigger_validateQuoteStatusOnCW')){
            return;
        }
        
        Set<Id> quoteIds = new Set<Id>();         
        for(Opportunity opp : opps){
            if(
                opp.SBQQ__PrimaryQuote__c != null &&
                (opp.RecordTypeId == CDdSchemaUtils.OPPORTUNITY_RT.mlInsideSalesId() || opp.RecordTypeId == CDdSchemaUtils.OPPORTUNITY_RT.postSaleId()) &&
                opp.StageName == 'Closed Won'
            ){
                quoteIds.add(opp.SBQQ__PrimaryQuote__c);
            }
        }

        if(!quoteIds.isEmpty()){
            Map<Id,SBQQ__Quote__c> quotes = new Map<Id,SBQQ__Quote__c>([SELECT Id, SBQQ__Status__c FROM SBQQ__Quote__c WHERE Id IN :quoteIds]);
            for(Opportunity opp : opps){
                if(opp.SBQQ__PrimaryQuote__c != null && quotes.containsKey(opp.SBQQ__PrimaryQuote__c)){
                    SBQQ__Quote__c quote = quotes.get(opp.SBQQ__PrimaryQuote__c);
                    if(quote.SBQQ__Status__c != 'Contract Signed' && String.isBlank(opp.Pickup_Inflation_Opp__c) && String.isBlank(opp.Delivery_Inflation_Opp__c)){
                        opp.addError(Label.CW_Must_Have_Signed_Contract_on_Quote);
                    }
                }
            }
        }    
    }
     /**
     * @description this function populates the currency, legal entity on the opportunity depending on the Account Billing Country on insert/update
     * @param opps Trigger.new
     * @param AccMap AccountMap
     * @param Boolean for insert/Update
     * [Q2C-870]
     */
    public static void populateLegalEntityOrCurrencyCode(List<Opportunity> opps,Boolean isUpdate,Map<Id, Account> accMap){
        
        if(!CDdRecursionUtils.isRunnable('CDdOpportunityTrigger_populateLegalEnt')){
            return;
        }
        if(accMap.isEmpty()){
            return;
        }
        //Custom metadata
        Map<String,OpportunityLegalEntity__mdt> mapBillingCountryToMdt = new Map<String,OpportunityLegalEntity__mdt>();
        Map<String, OpportunityCurrency__mdt> mapOppCurrency = OpportunityCurrency__mdt.getAll();
        Map<String, OpportunityLegalEntity__mdt> mapOppLegalEnt = OpportunityLegalEntity__mdt.getAll();
        Set<String> primaryMerchCategories = new Set<String>();

        for(OpportunityLegalEntity__mdt legalEntity : mapOppLegalEnt.values()){
            String key = String.isBlank(legalEntity.Primary_Merchant_Category__c) ? legalEntity.BillingCountry__c : legalEntity.BillingCountry__c + legalEntity.Primary_Merchant_Category__c;
            if(String.isNotBlank(legalEntity.Primary_Merchant_Category__c)){
                primaryMerchCategories.add(legalEntity.Primary_Merchant_Category__c);
            }
            mapBillingCountryToMdt.put(key, legalEntity);                                          
        }

        for(Opportunity opp : opps){
            if(
                (opp.RecordTypeId == CDdSchemaUtils.OPPORTUNITY_RT.mlInsideSalesId() || opp.RecordTypeId == CDdSchemaUtils.OPPORTUNITY_RT.postSaleId())
                && opp.AccountId != null
            ){
                Account acc = new Account(); 
                if (accMap.containsKey(opp.AccountId)){
                    acc = accMap.get(opp.AccountId);
                }

                //If the primary merchant category on the account isnt in the set to check, leave it as empty.  Otherwise its needed as a key
                String billingCountry = String.isNotBlank(acc.BillingCountry)? acc.BillingCountry : '';
                String merchantCategory = '';
                if(String.isNotBlank(acc.Primary_Merchant_Category__c) && primaryMerchCategories.contains(acc.Primary_Merchant_Category__c)){
                    merchantCategory = acc.Primary_Merchant_Category__c;
                }
                String key = billingCountry;
                //BZAP-12579 if the billing country is US and there is no merchant category default to US legal ENT
                if(isUpdate && opp.SBQQ__PrimaryQuote__c != null) {             
                    if(billingCountry == CDdCpqBillingConstants.US_BILLING_COUNTRY){
                        //BZAP-12684 The merhant category should only apply to US LE mapping
                        key += merchantCategory;
                        if(String.isBlank(acc.Primary_Merchant_Category__c)){
                            opp.Legal_Entity__c = CDdCpqBillingConstants.US_LEGAL_ENT;
                        } else if(String.isNotBlank(acc.Primary_Merchant_Category__c) && !primaryMerchCategories.contains(acc.Primary_Merchant_Category__c)){
                            //If there is a merchant category but it isnt in the set of US merchant categories, use US - G&C because the key wont match a value in the table
                            opp.Legal_Entity__c = CDdCpqBillingConstants.US_LEGAL_ENT_GC;      
                        } else {
                            opp.Legal_Entity__c = mapBillingCountryToMdt.get(key).LegalEntity__c; 
                        }           
                    } else {
                        if(String.isNotBlank(billingCountry) && mapBillingCountryToMdt?.containsKey(key)){
                            //All other scenarios will match on the key
                            opp.Legal_Entity__c = mapBillingCountryToMdt.get(key).LegalEntity__c; 
                        }
                    }
                }

                //BZAP-12684 if the bill country has a space the custom metadata developer name will have _ in the key
                String currencyKey = billingCountry.replace(' ', '_');
                //Currency mapping
                if(String.isNotBlank(billingCountry) && mapOppCurrency?.containsKey(currencyKey) && !isUpdate){
                    opp.CurrencyIsoCode = mapOppCurrency.get(currencyKey).Currency_Code__c;
                }
                
            }
        }
    }
}