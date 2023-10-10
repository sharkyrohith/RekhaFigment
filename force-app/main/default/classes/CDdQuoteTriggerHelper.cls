/**
* @author: Cory Bartholomew (ATG)
* @date: 05-2021    
* @description: Trigger Helper for Salesforce CPQ Quotes          
*/ 
public with sharing class CDdQuoteTriggerHelper {
    public static Id DRAFT_RT_ID = CDdSchemaUtils.QUOTE_RT.draftId();
    public static Id IN_PROGRESS_RT_ID = CDdSchemaUtils.QUOTE_RT.inProgressId();
    public static Id APPROVED_RT_ID = CDdSchemaUtils.QUOTE_RT.approvedId();
    public static String APPROVAL_STATUS_PENDING = 'Pending';
    public static String APPROVAL_STATUS_APPROVED = 'Approved';
    public static final Set<String> DEFAULT_BBOT_VALUES = new Set<String>{'Full Logo Permission', 'Implementation Refund Promo'};

    /**
     * @description BZAP-13135; Voids out contracts that have moved from 'Out for Signature' back to 'Approved'.
     *  Voiding out a contract means calling out to the PactSafe API to "expire" the current request.
     *
     * @param newQuotes (List<SBQQ__Quote__c>)
     * @param oldQuotesById (Map<Id, SBQQ__Quote__c>)
     *
     * @return List<SBQQ__Quote__c>; The expiration API we're calling doesn't throw exceptions or make local updates,
     *  so we need something to verify which quotes are being canceled in testing.
     */
    public static List<SBQQ__Quote__c> processVoidedContracts(List<SBQQ__Quote__c> newQuotes, Map<Id, SBQQ__Quote__c> oldQuotesById){
        List<SBQQ__Quote__c> quotesToVoid = new List<SBQQ__Quote__c>();
        if(newQuotes == null || oldQuotesById == null || newQuotes.isEmpty() || oldQuotesById.isEmpty()){
            return quotesToVoid;
        }

        Set<Id> requestIds = new Set<Id>();
        String requestField = PSExtensionMainSettings.getRequestFieldName;
        for(SBQQ__Quote__c currentQuote: newQuotes){
            SBQQ__Quote__c oldQuote = oldQuotesById.get(currentQuote.Id);

            if(
                (
                    currentQuote.SBQQ__Status__c  == CDdCpqBillingConstants.QUOTE_STATUS_APPROVED &&
                    oldQuote.SBQQ__Status__c  == CDdCpqBillingConstants.QUOTE_STATUS_OUT_FOR_SIGNATURE
                )
            ){
                quotesToVoid.add(currentQuote);

                if(!String.isBlank(requestField)){
                    Id currentRequestId = (Id)currentQuote.get(requestField);
                    requestIds.add(currentRequestId);
                }
            }
        }

        if(quotesToVoid.isEmpty()){
            return quotesToVoid;
        }

        if(!requestIds.isEmpty()){
            List<pactsafe1__PactSafeRequest__c> requests = [
                SELECT Id,pactsafe1__Expired__c
                FROM pactsafe1__PactSafeRequest__c
                WHERE Id IN :requestIds
            ];

            if(!requests.isEmpty()){
                for(pactsafe1__PactSafeRequest__c currentRequest : requests){
                    currentRequest.pactsafe1__Expired__c = true;
                }

                update requests;
            }
        }

        expireQuotes(quotesToVoid);
        return quotesToVoid;
    }
    
     /* @description BZAP-13196; updates the Number_of_Quotes__c on the mapped opportunity field (SBQQ__Opportunity2__c)
     *  for newly created SBQQ__Quote__c records.
     *
     * @param newQuotes (List<SBQQ__Quote__c>)
     */
    public static void updateOptyCountAfterInsert(List<SBQQ__Quote__c> newQuotes){
        if(newQuotes == null || newQuotes.isEmpty()){
            return;
        }

        Map<Id,Integer> numberOfQuotesByOpportunityId = new Map<Id,Integer>();
        for(SBQQ__Quote__c currentQuote: newQuotes){
            if(currentQuote.SBQQ__Opportunity2__c == null){
                continue;
            }

            incrementNumberOfQuotes(
                numberOfQuotesByOpportunityId,
                currentQuote.SBQQ__Opportunity2__c,
                1
            );
        }

        if(numberOfQuotesByOpportunityId.isEmpty()){
            return;
        }

        updateOpportunityQuoteCounts(numberOfQuotesByOpportunityId);
    }

    /**
     * @description BZAP-13196; updates the Number_of_Quotes__c on the mapped opportunity field (SBQQ__Opportunity2__c)
     *  for updated SBQQ__Quote__c records.
     *
     * @param newQuotes (List<SBQQ__Quote__c>)
     */
    public static void updateOptyCountAfterUpdate(List<SBQQ__Quote__c> newQuotes, Map<Id, SBQQ__Quote__c> oldMap){
        if(newQuotes == null || oldMap == null || newQuotes.isEmpty() || oldMap.isEmpty()){
            return;
        }

        Map<Id,Integer> numberOfQuotesByOpportunityId = new Map<Id,Integer>();
        for(SBQQ__Quote__c currentQuote : newQuotes){
            SBQQ__Quote__c oldQuote = oldMap.get(currentQuote.Id);

            if(
                (currentQuote.SBQQ__Opportunity2__c == null && oldQuote.SBQQ__Opportunity2__c == null) ||
                (currentQuote.SBQQ__Opportunity2__c == oldQuote.SBQQ__Opportunity2__c)
            ){
                continue;
            }

            if(currentQuote.SBQQ__Opportunity2__c != null){
                incrementNumberOfQuotes(
                    numberOfQuotesByOpportunityId,
                    currentQuote.SBQQ__Opportunity2__c,
                    1
                );
            }

            if(oldQuote.SBQQ__Opportunity2__c != null){
                incrementNumberOfQuotes(
                    numberOfQuotesByOpportunityId,
                    oldQuote.SBQQ__Opportunity2__c,
                    -1
                );
            }
        }

        if(numberOfQuotesByOpportunityId.isEmpty()){
            return;
        }

        updateOpportunityQuoteCounts(numberOfQuotesByOpportunityId);
    }

    /**
     * @description BZAP-13196; updates the Number_of_Quotes__c on the mapped opportunity field (SBQQ__Opportunity2__c)
     *  for deleted SBQQ__Quote__c records.
     *
     * @param newQuotes (List<SBQQ__Quote__c>)
     */
    public static void updateOptyCountAfterDelete(List<SBQQ__Quote__c> oldQuotes){
        if(oldQuotes == null || oldQuotes.isEmpty()){
            return;
        }

        Map<Id,Integer> numberOfQuotesByOpportunityId = new Map<Id,Integer>();
        for(SBQQ__Quote__c currentQuote: oldQuotes){
            if(currentQuote.SBQQ__Opportunity2__c == null){
                continue;
            }

            incrementNumberOfQuotes(
                numberOfQuotesByOpportunityId,
                currentQuote.SBQQ__Opportunity2__c,
                -1
            );
        }

        if(numberOfQuotesByOpportunityId.isEmpty()){
            return;
        }

        updateOpportunityQuoteCounts(numberOfQuotesByOpportunityId);
    }

    public static void processContractSignature(List<SBQQ__Quote__c> quotes, Map<Id, SBQQ__Quote__c> oldMap){
        List<SBQQ__Quote__c> quotesToProcess = new List<SBQQ__Quote__c>();
        for(SBQQ__Quote__c quote : quotes){
            if(
                (
                    quote.Opportunity_Record_Type__c == 'Marketplace' ||
                    quote.Opportunity_Record_Type__c == 'Post Sale' ||
                    quote.Opportunity_Record_Type__c == 'Merchant Promotion' ||
                    quote.Migrated_Record__c == true // BZAP-12980: opportunity requirements bypassed for migrated records
                ) &&
                (
                    quote.SBQQ__Status__c == 'Contract Signed' &&
                    oldMap.get(quote.Id).SBQQ__Status__c != 'Contract Signed'
                ) &&
                (quote.SBQQ__Primary__c == true)
            ){
                quotesToProcess.add(quote);
            }
        }

        if(!quotesToProcess.isEmpty()){
            generateOrders(quotesToProcess);
        }

    }
    
    public static void generateOrders(List<SBQQ__Quote__c> quotes){
        if(!CDdRecursionUtils.isRunnable('CDdQuoteTrigger_generateOrders')){
            return;
        } 
        List<SBQQ__Quote__c> quotesToUpdate = new List<SBQQ__Quote__c>();       
        for(SBQQ__Quote__c quote : quotes) {
            quotesToUpdate.add(new SBQQ__Quote__c(Id = quote.Id, SBQQ__Ordered__c = true));
        }  
        update quotesToUpdate;
    }

    /**
     * @description update related Opportunities when a quote's status is changed to Contract Signed
     * Ticket Q2C-453
     * @param quotes after update = quotes where status has changed to contract signed
     */
    public static void updateRelatedOpportunities(List<SBQQ__Quote__c> quotes, Map<Id,SBQQ__Quote__c> oldMap){
        List<SBQQ__Quote__c> quotesWithOpps = new List<SBQQ__Quote__c>();
        for(SBQQ__Quote__c quote : quotes){
            if(quote.SBQQ__Opportunity2__c != null){
                quotesWithOpps.add(quote);
            }
        }
        Map<Id,Opportunity> opportunitesToUpdate = new Map<Id,Opportunity>();
        updateOppPricingFields(quotesWithOpps, oldmap, opportunitesToUpdate);
        updateOpportunityStage(quotesWithOpps, oldMap, opportunitesToUpdate);
        setOptyPlatform(quotesWithOpps, opportunitesToUpdate);
        updateOppPactsafeFields(quotesWithOpps, oldMap, opportunitesToUpdate);
        if (!opportunitesToUpdate.values().isEmpty()){
           update opportunitesToUpdate.values();
        }
    }

    public static void updateOppPricingFields(List<SBQQ__Quote__c> quotes, Map<Id,SBQQ__Quote__c> oldMap, Map<Id,Opportunity> oppsToUpdate){
        Set<Id> quoteIds = new Set<Id>();
        for(SBQQ__Quote__c quote : quotes){
            if(
                quote.SBQQ__Status__c == 'Contract Signed' &&
                oldMap.get(quote.Id).SBQQ__Status__c != 'Contract Signed' &&
                quote.SBQQ__Primary__c
            ){
                quoteIds.add(quote.Id);
            }
        }
        
        if(!quoteIds.isEmpty()){
            List<SBQQ__QuoteLine__c> quoteLines = [SELECT
                                                    Id, CPQ_Pricing_Tier__c, Final_Commission__c, SBQQ__ListPrice__c, SBQQ__NetTotal__c,
                                                    SBQQ__Product__c, SBQQ__Product__r.DD_Custom_ID__c, SBQQ__Quote__c,Trial_Commission__c, DD_Custom_ID__c 
                                                    FROM SBQQ__QuoteLine__c
                                                    WHERE SBQQ__Quote__c IN: quoteIds];

            Map<Id, List<SBQQ__QuoteLine__c>> mapOfQuotelines = (Map<Id, List<SBQQ__QuoteLine__c>>)groupById(quoteLines, SBQQ__QuoteLine__c.SBQQ__Quote__c);
            for(SBQQ__Quote__c quote : quotes){
                Opportunity opportunityToAdd = new Opportunity();
                if(oppsToUpdate.containsKey(quote.SBQQ__Opportunity2__c)){
                    opportunityToAdd = oppsToUpdate.get(quote.SBQQ__Opportunity2__c);
                } else{
                    opportunityToAdd.Id = quote.SBQQ__Opportunity2__c;
                }                
                if(mapOfQuotelines.containsKey(quote.Id)){
                    boolean updateOpp = false;
                    List<SBQQ__QuoteLine__c> quoteLinesRelatedToQuote = mapOfQuotelines.get(quote.Id);
                                
                    for(SBQQ__QuoteLine__c quoteLine : quoteLinesRelatedToQuote){
                        if(quoteLine.DD_Custom_ID__c != null){
                            if(quoteLine.DD_Custom_ID__c.equalsIgnoreCase('MKTPL-0000124')){
                                opportunityToAdd.Commission__c = quoteLine.Final_Commission__c;
                                opportunityToAdd.Trial_Commission__c = quoteLine.Trial_Commission__c;
                                updateOpp = true;
                            }
                            if(quoteLine.DD_Custom_ID__c.equalsIgnoreCase('MKTPL-0000102')){
                                opportunityToAdd.In_App_Pickup_Commission__c = quoteLine.Final_Commission__c;
                                updateOpp = true;
                            }
                            if(quoteLine.DD_Custom_ID__c.equalsIgnoreCase('MKTPL-0000103')){
                                if(quoteLine.Final_Commission__c != null){
                                    opportunityToAdd.DashPass_Only_Commission__c = quoteLine.Final_Commission__c;
                                } else{ 
                                    opportunityToAdd.DashPass_Flat_Fee__c = quoteLine.SBQQ__ListPrice__c;
                                }
                                updateOpp = true;
                            }
                            if(quoteLine.DD_Custom_ID__c.equalsIgnoreCase('MKTPL-0000111')){
                                if(quote.Weekly_Tablet_Fee__c != null){
                                    String convertedTabFee = convertFee(quote.CurrencyIsoCode, quote.Weekly_Tablet_Fee__c);
                                    opportunityToAdd.Weekly_Tablet_Subscription_Fee__c = convertedTabFee;
                                    updateOpp = true;
                                }
                            }
                            if(quoteLine.DD_Custom_ID__c.equalsIgnoreCase('MKTPL-0000114')){
                                if(quote.Weekly_Printer_Fee__c != null){
                                    String convertedPrintFee = convertFee(quote.CurrencyIsoCode, quote.Weekly_Printer_Fee__c);
                                	opportunityToAdd.Weekly_Printer_Subscription_Fee__c = convertedPrintFee;
                                    updateOpp = true;
                                }
                            }
                        }
                    }
                    //Q2C-985
                    if(String.isNotBlank(quote.Trial_Period_Quote__c)){
                        opportunityToAdd.Trial_Type__c = 'Promotional Period';
                        opportunityToAdd.Length_of_Trial__c = quote.Trial_Period_Quote__c + ' Days';
                        updateOpp = true;
                    }

                    if(updateOpp == true){
                        oppsToUpdate.put(opportunityToAdd.Id, opportunityToAdd);
                        updateOpp = false;
                    } 
                }
            }            
        }    
    }

    /**
     * @description This method updates the opportunity stage based on the change in the quote status
     * @param quotes after update = quotes where status has changed to contract signed, ready for signature or out for signature
     */
    public static void updateOpportunityStage(List<SBQQ__Quote__c> quotes, Map<Id, SBQQ__Quote__c> oldMap, Map<Id,Opportunity> oppsToUpdate){
        if(!CDdRecursionUtils.isRunnable('CDdQuoteTrigger_updateOpportunityStage')){ 
            return;
        }

        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        for(SBQQ__Quote__c quote : quotes){
            Boolean updateOpp = false;
            Opportunity opportunityToAdd = new Opportunity();
            if(oppsToUpdate.containsKey(quote.SBQQ__Opportunity2__c)){
                opportunityToAdd = oppsToUpdate.get(quote.SBQQ__Opportunity2__c);
            } else{
                opportunityToAdd.Id = quote.SBQQ__Opportunity2__c;
            }           
            
            if(quote.SBQQ__Status__c == 'Contract Signed' && oldMap.get(quote.Id).SBQQ__Status__c != 'Contract Signed'){
                opportunityToAdd.StageName = 'Contract Signed';
                updateOpp = true;
            }
            if(quote.SBQQ__Status__c == 'Approved' && oldMap.get(quote.Id).SBQQ__Status__c != 'Approved' && quote.SBQQ__Primary__c == true){
                opportunityToAdd.StageName = 'Ready for Signature';
                updateOpp = true;
            }
            if(quote.SBQQ__Status__c == 'Out for Signature' && oldMap.get(quote.Id).SBQQ__Status__c != 'Out for Signature'){
                opportunityToAdd.StageName = 'Out for Signature';
                updateOpp = true;
            }
            if(updateOpp){
                oppsToUpdate.put(opportunityToAdd.Id, opportunityToAdd);
            }
        }
        
    }

    /**
     * @description Group a list of SObjects by any field on the SObject
     * This version of the method supports Passing in a reference field and returning a Map using an Id as the key
     * @param items list of SObject
     * @param field Property to get a map by (Lookup, Master-Detail Field, text field which holds a SFID)
     * @return [description]
     */
    public static Map<Id, List<SObject>> groupById(List<SObject> listOfRecords, Schema.SObjectField filterField){
        Map<Id, List<SObject>> mapListSobjectById = new Map<Id, List<SObject>>();
        for(SObject record : listOfRecords){
            Id key = (Id)record.get(filterField);
            List<SObject> tempList;
            if((tempList = mapListSobjectById.get( key )) == null){
                mapListSobjectById.put( key, tempList = new List<SObject>());
            }
            tempList.add ( record );
        }
        return mapListSobjectById;
    }    
    
    public static void setOptyPlatformAfterInsert(List<SBQQ__Quote__c> quotes){
        Map<Id,Opportunity> oppsToUpdate = new Map<Id,Opportunity>();
        setOptyPlatform(quotes, oppsToUpdate);
        if (!oppsToUpdate.values().isEmpty()){
            update oppsToUpdate.values();
         }
    }
    
    /**
     * @description this function is to replace the process builder for setting the opportunity platform field based on quote lines
     * @param quotes after insert = trigger.new.  after update = trigger.new
     */
    public static void setOptyPlatform(List<SBQQ__Quote__c> quotes, Map<Id, Opportunity> oppsToUpdate){
        if(!CDdRecursionUtils.isRunnable('CDdQuoteTrigger_setOptyPlatform')){ 
            return;
        }
        System.debug('Set Oppty Platform Is Runnable = TRUE');
        Set<Id> quoteIds = new Set<Id>();
        for(SBQQ__Quote__c quote : quotes){
            quoteIds.add(quote.Id);
        }

        List<SBQQ__Quote__c> quotesWithOppValues = [SELECT Id, SBQQ__Primary__c, Caviar_Products__c, DoorDash_Products__c, SBQQ__Opportunity2__r.Platform__c FROM SBQQ__Quote__c WHERE Id IN :quoteIds];
        
        for(SBQQ__Quote__c quote : quotesWithOppValues){
            Opportunity opportunityToAdd = new Opportunity();
            if(oppsToUpdate.containsKey(quote.SBQQ__Opportunity2__c)){
                opportunityToAdd = oppsToUpdate.get(quote.SBQQ__Opportunity2__c);
            } else{
                opportunityToAdd.Id = quote.SBQQ__Opportunity2__c;
            }
            boolean updateOpp = false;
            if(quote.SBQQ__Primary__c == true){
                if(quote.Caviar_Products__c == 0 && quote.DoorDash_Products__c > 0 && quote.SBQQ__Opportunity2__r.Platform__c != 'DoorDash'){
                    opportunityToAdd.Platform__c = 'DoorDash';
                    updateOpp = true;
                }
                if(quote.Caviar_Products__c > 0 && quote.DoorDash_Products__c > 0 && quote.SBQQ__Opportunity2__r.Platform__c != 'Caviar and DoorDash'){
                    opportunityToAdd.Platform__c = 'Caviar and DoorDash';
                    updateOpp = true;
                }
                if(quote.Caviar_Products__c > 0 && quote.DoorDash_Products__c == 0 && quote.SBQQ__Opportunity2__r.Platform__c != 'Caviar'){
                    opportunityToAdd.Platform__c = 'Caviar';                
                    updateOpp = true;
                }   
                if(updateOpp == true){
                    System.debug('Updating Oppty Platform :' + opportunityToAdd.Platform__c);
                    oppsToUpdate.put(opportunityToAdd.Id, opportunityToAdd);
                }
            }
        }
    }
    
    public static void updateRecordTypeAfterUpdate(List<SBQQ__Quote__c> quotes, Map<Id,SBQQ__Quote__c> oldMap){
        List<SBQQ__Quote__c> quotesToProcess = new List<SBQQ__Quote__c>();
        for(SBQQ__Quote__c quote : quotes){
            if(quote.ApprovalStatus__c != oldMap.get(quote.Id).ApprovalStatus__c){
                quotesToProcess.add(new SBQQ__Quote__c(
                    Id = quote.Id,
                    SBQQ__Status__c = quote.SBQQ__Status__c,
                    ApprovalStatus__c = quote.ApprovalStatus__c,
                    SBQQ__WatermarkShown__c = quote.SBQQ__WatermarkShown__c
                ));
            }
        }
        if(!quotesToProcess.isEmpty()){
            updateRecordTypeFromStatus(quotesToProcess);
            update quotesToProcess;
        }        
    }
    
    /**
     * Q2C-295 Move recordType process builder into code and add in Pactsafe status logic
     * @param quotes after insert = trigger.new.  after update = quotes where approval status has changed
     */
    public static List<SBQQ__Quote__c> updateRecordTypeFromStatus(List<SBQQ__Quote__c> quotes){
        for(SBQQ__Quote__c quote : quotes){
            switch on quote.ApprovalStatus__c{
                when 'Approved'{
                    quote.RecordTypeId = APPROVED_RT_ID;
                    quote.SBQQ__Status__c = 'Approved';
                    quote.SBQQ__WatermarkShown__c = true; 
                }
                when 'Pending'{
                    quote.RecordTypeId = IN_PROGRESS_RT_ID;
                    quote.SBQQ__Status__c = 'In Review'; 
                    quote.SBQQ__WatermarkShown__c = false;
                }
                when 'Recalled'{
                    quote.RecordTypeId = DRAFT_RT_ID;
                    quote.SBQQ__Status__c = 'Draft';
                    quote.SBQQ__WatermarkShown__c = false; 
                }
                when 'Rejected'{
                    quote.RecordTypeId = DRAFT_RT_ID;
                    quote.SBQQ__Status__c = 'Denied';
                    quote.SBQQ__WatermarkShown__c = false;
                }
            }
        }
        return quotes;
    }
    
    /**
     * @description this function sets the standard price book on the quote
     * @param quotes before insert = trigger.new.
     * Ticket Q2C-332
     */
    public static void setStandardPriceBookBeforeInsert(List<SBQQ__Quote__c> quotes){
        if(!CDdRecursionUtils.isRunnable('CDdQuoteTrigger_standardPriceBook')){ 
            return;
        }
        Pricebook2 pricebook = Test.isRunningTest() ? new Pricebook2(Id = Test.getStandardPricebookId()) : getStandardPricebook();
        for(SBQQ__Quote__c quote : quotes){
            //Field: pricebook2Id Operator: is Null Type: boolean Value: false
            if(quote.SBQQ__Opportunity2__r.Pricebook2Id == null || quote.SBQQ__PricebookId__c != pricebook.Id){
                quote.SBQQ__PricebookId__c = pricebook.Id; 
            }
        }
    }

    /**
     * @description Update the related Opportunity Pactsafe fields when they are changed on the quote.  If the quote has been changed to contract signed in the same transaction, it will be handled in UpdateRelatedOpportunities()
     * @param quotes trigger.new
     * @param oldMap trigger.oldMap
     */
    public static void updateOppPactsafeFields(List<SBQQ__Quote__c> quotes, Map<Id, SBQQ__Quote__c> oldMap, Map<Id,Opportunity> oppsToUpdate){        
        for(SBQQ__Quote__c quote : quotes){
            if(quote.SBQQ__Primary__c){
                Opportunity oppToAdd = new Opportunity();
                if(oppsToUpdate.containsKey(quote.SBQQ__Opportunity2__c)){
                    oppToAdd = oppsToUpdate.get(quote.SBQQ__Opportunity2__c);
                } else{
                    oppToAdd.Id = quote.SBQQ__Opportunity2__c;
                }
                Boolean updateOpp = false;
                if(quote.PactSafe_Contract_Type__c != oldMap.get(quote.Id).PactSafe_Contract_Type__c ){
                    oppToAdd.PactSafe_Contract_Type__c = quote.PactSafe_Contract_Type__c; 
                    updateOpp = true;
                }
                if(quote.PactSafe_Activity_ID__c != oldMap.get(quote.Id).PactSafe_Activity_ID__c){
                    oppToAdd.PactSafe_Activity_ID__c = quote.PactSafe_Activity_ID__c; 
                    updateOpp = true;
                }
                if(quote.PactSafe_Record__c != oldMap.get(quote.Id).PactSafe_Record__c){
                    oppToAdd.PactSafe_Record__c = quote.PactSafe_Record__c; 
                    updateOpp = true;
                }
                if(quote.Contract_Signed_Date__c != oldMap.get(quote.Id).Contract_Signed_Date__c){
                    oppToAdd.Contract_Signed_Date__c = quote.Contract_Signed_Date__c; 
                    updateOpp = true;
                }

                if(updateOpp){
                    oppsToUpdate.put(oppToAdd.Id, oppToAdd);
                }
            }
        }
    }
    
    /**
     * @description Query the Standard pricebook
     * @return Pricebook2 the standard pricebook
     */
    public static Pricebook2 getStandardPricebook(){
        Pricebook2 pricebook = [
            SELECT Id
            FROM Pricebook2
            WHERE IsStandard = true
            LIMIT 1
        ];
        return pricebook;
    }

    /**
    * @description determine the correct currency symbol based on ISO Code
    * @return String the currency symbol
    */
     public static String getCurrencySymbolFromIso(String Iso) {
       Currency_Symbol__mdt currencySymbol = Currency_Symbol__mdt.getinstance(Iso);
       return currencySymbol.Currency_Symbol__c;
    }
    
    public static String convertFee(String currencyCode, Decimal fee){
        String convertedFee = '';
        String symbol = getCurrencySymbolFromIso(currencyCode);
        String feeWithSymbol = symbol + String.valueOf(fee);
        Integer intVersionOfFee = Integer.valueOf(fee);
        if(feeWithSymbol.contains('.00')){
            convertedFee = symbol + String.valueOf(intVersionOfFee);
        }else{
            convertedFee = feeWithSymbol;
        }
        return convertedFee; 
    }

    /**
     * @description Pre-existing expiration code moved in from PSRequestQuoteTrigger as part of BZAP-13135.
     *  Kicks off API calls via the pre-existing PSRequestQuoteTriggerHandler.expireRequest @future method.
     * @param quotesToExpire (List<SBQQ__Quote__c>)
     * @see PSRequestQuoteTriggerHandler.expireRequest
     */
    private static void expireQuotes(List<SBQQ__Quote__c> quotesToExpire){
        Set<Id> psRequestIds = new Set<Id>();
        for(SBQQ__Quote__c aQuote : quotesToExpire){
            if(aQuote != null && aQuote.PactSafe_Request__c != null){
                psRequestIds.add(aQuote.PactSafe_Request__c);
            }
        }

        if(psRequestIds.isEmpty()){
            return;
        }

        Map<Id,pactsafe1__PactSafeRequest__c> psRequestsById = new Map<Id,pactsafe1__PactSafeRequest__c>(
            [SELECT Id,pactsafe1__PactSafeRequestId__c FROM pactsafe1__PactSafeRequest__c WHERE Id IN :psRequestIds]
        );

        // This is pre-existing code that sends out individual API requests. It may not be properly bulkified.
        //  BZAP-13135's only change to it was to use PactSafe_Request__r.pactsafe1__PactSafeRequestId__c off
        //  the quote instead of referencing PSExtensionMainSettings.getRequestFieldName as the existing code
        //  did. this was done at the recommendation of PactSafe.
        for (SBQQ__Quote__c currentQuote : quotesToExpire) {
            if(
                currentQuote != null &&
                currentQuote.PactSafe_Request__c != null
            ){
                pactsafe1__PactSafeRequest__c psRequest = psRequestsById.get(currentQuote.PactSafe_Request__c);
                if(psRequest == null || String.isEmpty(psRequest.pactsafe1__PactSafeRequestId__c)){
                    continue;
                }

                PSRequestQuoteTriggerHandler.expireRequest(psRequest.pactsafe1__PactSafeRequestId__c);
            }
        }
    }
    
    private static Map<Id,Integer> incrementNumberOfQuotes(Map<Id,Integer> numberOfQuotesByOpportunityId, Id opportunityId, Integer incrementBy){
        Integer numberOfQuotes = incrementBy;
        if(numberOfQuotesByOpportunityId.containsKey(opportunityId)){
            numberOfQuotes = numberOfQuotesByOpportunityId.get(opportunityId) + incrementBy;
        }

        numberOfQuotesByOpportunityId.put(opportunityId, numberOfQuotes);
        return numberOfQuotesByOpportunityId;
    }
    private static List<Opportunity> updateOpportunityQuoteCounts(Map<Id,Integer> numberOfQuotesByOpportunityId){
        Map<Id,Opportunity> opportunitiesById = new Map<Id,Opportunity>(
            [
                SELECT Id,Number_of_Quotes__c
                FROM Opportunity
                WHERE Id IN :numberOfQuotesByOpportunityId.keySet()
            ]
        );
        for(Id opportunityId : numberOfQuotesByOpportunityId.keySet()){
            Integer quoteCount = numberOfQuotesByOpportunityId.get(opportunityId);
            Opportunity currentOpportunity = opportunitiesById.get(opportunityId);

            if(currentOpportunity.Number_of_Quotes__c == null){
                currentOpportunity.Number_of_Quotes__c = 0;
            }

            currentOpportunity.Number_of_Quotes__c += quoteCount;

            // could occur for legacy objects that were created before this trigger was active
            if(currentOpportunity.Number_of_Quotes__c < 0){
                currentOpportunity.Number_of_Quotes__c = 0;
            }
        }

        update opportunitiesById.values();
        return opportunitiesById.values();
    }

    /**
     * @description  this function is used to Skip Validation based on Custom Setting
     * @param   String fieldToCheck - 'Bypass_Quote_Validations__c'
     * @return  Boolean
     */
    public static Boolean skipValidation(String fieldToCheck) {
        String userId = UserInfo.getUserId();
        String profileId = UserInfo.getProfileId();
        String queryString = 'SELECT Id, ' + fieldToCheck
                       + ' FROM Validation_Bypass__c'
                       + ' WHERE SetupOwnerId =: userId'
                       + '    OR SetupOwnerId =: profileId';
        List<Sobject> skipValidation = Database.query(queryString);
        if (skipValidation.size() > 0 && skipValidation.get(0).get(fieldToCheck) == true) {
            return true;
        }
        return false;
    }
    
    /**
     * @description this function is to update the Bbot Subscription End Date based on Bbot Subscription Term and Bbot Subscription Start Date,
     * 				if Bbot Subscription Term is Montly add 1 month to Bbot Subscription End Date
     * 				if Bbot Subscription Term is 1 Year add 1 Year to Bbot Subscription End Date
     * 				if Bbot Subscription Term is 2 Years add 2 Years to Bbot Subscription End Date
     * 				if Bbot Subscription Term is 3 Years add 3 Years to Bbot Subscription End Date
     * 				if Bbot Subscription Term is not Custom and Bbot Subscription End Date is changing, then disply error message
     * @param quotes before update = trigger.new and trigger.oldMap
     * Ticket BZAP-17460
     */
    public static void updateBbotSubscriptionEndDate(List<SBQQ__Quote__c> newQuotes, Map<Id, SBQQ__Quote__c> oldMapQuotes){
        for(SBQQ__Quote__c quote: newQuotes){
            if(quote.DD_Id_s__c != null && quote.DD_Id_s__c.contains('BBOT')){
                if((isNewOrFieldUpdated(quote, oldMapQuotes, 'Bbot_Subscription_Term__c') || isNewOrFieldUpdated(quote, oldMapQuotes, 'Bbot_Subscription_Start_Date__c'))){
                    if(String.isBlank(quote.Bbot_Subscription_Term__c) || quote.Bbot_Subscription_Start_Date__c == null){
                        quote.Bbot_Subscription_End_Date__c = null;
                    } else if(quote.Bbot_Subscription_Term__c == 'Monthly'){
                        quote.Bbot_Subscription_End_Date__c = quote.Bbot_Subscription_Start_Date__c.addMonths(1).addDays(-1);
                    } else if(quote.Bbot_Subscription_Term__c.contains('Year')){
                        List<String> tempYearsList = quote.Bbot_Subscription_Term__c.split(' ');
                        if(tempYearsList[0] != null){
                            Integer numberOfYears = Integer.valueOf(tempYearsList[0]);
                            quote.Bbot_Subscription_End_Date__c = quote.Bbot_Subscription_Start_Date__c.addYears(numberOfYears).addDays(-1);
                        }
                    } else if(isNewOrFieldUpdated(quote, oldMapQuotes, 'Bbot_Subscription_Term__c') && quote.Bbot_Subscription_Term__c == 'Custom' &&
                              !isNewOrFieldUpdated(quote, oldMapQuotes, 'Bbot_Subscription_End_Date__c')){
                        quote.Bbot_Subscription_End_Date__c = null;
                    }
                } else if(isNewOrFieldUpdated(quote, oldMapQuotes, 'Bbot_Subscription_End_Date__c') && quote.Bbot_Subscription_Term__c != 'Custom'){
                    if(!skipValidation('Bypass_Quote_Validations__c')){
                        quote.Bbot_Subscription_End_Date__c.addError(Label.Bbot_Custom_Subscription_End_Date_Error_Message);
                    }
                }
            }
        }
    }

    /*
    * Description: Validate the Bbot Opp fields when Quote stage is set to "In Review" as part of clicking on the
    * "Submit for Approval" button of the Quote layou
    * Nathalie Mendezona for BZAP-17701
    */
    public static void validateBbotOpportunityOnApprovalSubmission(List<SBQQ__Quote__c> newList , Map<Id, SBQQ__Quote__c> oldMap) {
        Set<Id> bBotOpptyIdSet = new Set<Id>();
        String errorMessage = '';

        if (skipValidation('Bypass_Quote_Validations__c')) {
            return;
        }

        for (SBQQ__Quote__c quote: newList) {
            if (String.isNotEmpty(quote.SBQQ__Opportunity2__c) &&
                isNewOrFieldUpdated(quote, oldMap, 'ApprovalStatus__c') &&
                (quote.ApprovalStatus__c == APPROVAL_STATUS_PENDING || quote.ApprovalStatus__c == APPROVAL_STATUS_APPROVED)) {
                bBotOpptyIdSet.add(quote.SBQQ__Opportunity2__c);
            }
        }
        if (bBotOpptyIdSet.isEmpty()) {
            return;
        }
        Map<Id, Set<String>> opptyIdToOpptyContactRolesMap = new Map<Id, Set<String>>();
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([SELECT Id,
                                    AccountId, Account.POS_System__c, Account.Bbot_Category__c, Account.Bbot_Sub_Category__c,
                                    Cuisine_Categories__c, Decision_Maker__c, Integrations_Required__c, StageName, RecordTypeId,
                                    IsCloned__c,
                                        (SELECT Id, Role FROM OpportunityContactRoles)
                                    FROM Opportunity
                                    WHERE Id in: bBotOpptyIdSet]);

        for (SBQQ__Quote__c quote: newList) {
            Opportunity opp = oppMap.get(quote.SBQQ__Opportunity2__c );
            if (CDdOpportunityTriggerHelper.bbotRecordTypeIds.contains(opp.recordTypeId) &&
                quote.DD_Id_s__c != null && quote.DD_Id_s__c.contains('BBOT')) {
                Set<String> opptyContactRoles = new Set<String>();
                for (OpportunityContactRole opptyContactRoleRecord: opp.OpportunityContactRoles) {
                    if (!String.isBlank(opptyContactRoleRecord.Role)) {
                        opptyContactRoles.add(opptyContactRoleRecord.Role);
                    }
                }
                opptyIdToOpptyContactRolesMap.put(opp.Id, opptyContactRoles);

                Boolean hasRequiredFieldsBlank = String.isBlank(opp.Decision_Maker__c) || 
                        String.isBlank(opp.Cuisine_Categories__c) || String.isBlank(opp.Integrations_Required__c);
                Boolean isValidOpptyContactRole = opptyIdToOpptyContactRolesMap.get(opp.Id) != null && 
                        opptyIdToOpptyContactRolesMap.get(opp.Id).contains(CDdOpportunityTriggerHelper.OPPORTUNITY_CONTACT_ROLE_PRIMARY_ONBOARDING_CONTACT) &&
                        opptyIdToOpptyContactRolesMap.get(opp.Id).contains(CDdOpportunityTriggerHelper.OPPORTUNITY_CONTACT_ROLE_IT_POC);
                if (hasRequiredFieldsBlank) {
                    errorMessage = errorMessage + Label.Bbot_Quote_Required_Opp_Fields_for_Approval + '\n';
                }
                if (!isValidOpptyContactRole && !opp.IsCloned__c) {
                    errorMessage = errorMessage + Label.Bbot_Quote_Required_Contact_Roles_on_Opp_for_Approval + '\n';
                }

                // For Post Sale Opps and Marketplace opps, we want to check Account fields as well
                if (opp.AccountId != null) {
                    Boolean hasRequiredAccountFieldsBlank = String.isBlank(opp.Account.POS_System__c) || 
                                                    String.isBlank(opp.Account.Bbot_Category__c) || 
                                                    String.isBlank(opp.Account.Bbot_Sub_Category__c);

                    if (hasRequiredAccountFieldsBlank) {
                        errorMessage = errorMessage + Label.Bbot_Quote_Required_Fields_on_Account_for_Quote_Submission + '\n';
                    }
                }
            }
            if (String.isNotBlank(errorMessage)) {
                quote.addError(errorMessage);
            }
        }
    }

    /**
     * @Description : to set default values for Bbot Additional Terms field on Quote object
     * @Ticket : BZAP-17914 Default Bbot Additional Terms
     * @Author : Jitendra Singh
     */
    public static void setDefaultValuesForAdditionalTermField(List<SBQQ__Quote__c> newQuotes, Map<Id, SBQQ__Quote__c> oldMapQuotes) {
        for (SBQQ__Quote__c quote : newQuotes) {
            if (quote.RecordTypeId == DRAFT_RT_ID) {
                if (quote.Bbot_Additional_Terms__c == null) {
                    quote.Bbot_Additional_Terms__c = 'Full Logo Permission;Implementation Refund Promo';
                }
                else {
                    String existingTermValues = quote.Bbot_Additional_Terms__c;

                    // Ensuring that the default Bbot values are part of the Bbot_Additional_Terms__c
                    // on insert or update where there are BBOT products on a Draft Quote
                    for (String defaultBbotValue: DEFAULT_BBOT_VALUES) {
                        if (!quote.Bbot_Additional_Terms__c.contains(defaultBbotValue)) {
                            existingTermValues = existingTermValues + ';' + defaultBbotValue;
                        }
                    }
                    quote.Bbot_Additional_Terms__c = existingTermValues;
                }
            }
        }
    }

    /**
     * @Description : to set default values for Bbot Additional Terms field on Quote object
     * @Ticket : BZAP-17914 Default Bbot Additional Terms
     * @Author : Jitendra Singh
     */
    public static void removeDefaultValuesForAdditionalTermFieldForNonBBOT(List<SBQQ__Quote__c> newQuotes, Map<Id, SBQQ__Quote__c> oldMapQuotes) {
        for (SBQQ__Quote__c quote : newQuotes) {
            if (quote.DD_Id_s__c != null && !quote.DD_Id_s__c.contains('BBOT') && isFieldUpdated(quote, oldMapQuotes, 'DD_Id_s__c')) {
                if (quote.Bbot_Additional_Terms__c != null) {
                    String strPickListValue = quote.Bbot_Additional_Terms__c;
                    List<String> lstPicklistValues = strPickListValue.split(';');

                    // Removing default Bbot values (as identified by the business) from Quotes that are not selling any BBOT product
                    for (String defaultBbotValue: DEFAULT_BBOT_VALUES) {
                        if (lstPicklistValues.contains(defaultBbotValue)) {
                            lstPicklistValues.remove(lstPicklistValues.indexOf(defaultBbotValue));
                        }
                    }
                    quote.Bbot_Additional_Terms__c = String.join(lstPicklistValues,';');
                }
            } 
        }
    } 

     /**
     * @description  Determines if a field has been updated on the record
     * @param   SBQQ__Quote__c newQuote - Quote in trigger.new
     *          Map<Id, SBQQ__Quote__c> oldMap - trigger.oldMap
     *          String fieldName - field to check if it has been updated
     * @return  Boolean
     */
    public static Boolean isFieldUpdated(SBQQ__Quote__c newQuote,Map<Id, SBQQ__Quote__c> oldMap, String fieldName) {
        return (oldMap != null && newQuote.get(fieldName) != oldMap.get(newQuote.Id).get(fieldName));
    }

    /**
     * @description  Determines if the record is a new record or if a field has been updated on the record
     * @param   SBQQ__Quote__c newQuote - Quote in trigger.new
     *          Map<Id, SBQQ__Quote__c> oldMap - trigger.oldMap
     *          String fieldName - field to check if it has been updated
     * @return  Boolean
     */
    public static Boolean isNewOrFieldUpdated(SBQQ__Quote__c newQuote, Map<Id, SBQQ__Quote__c> oldMap, String fieldName) {
        return trigger.isInsert || isFieldUpdated(newQuote, oldMap, fieldName);
    }
    
    /**
     * @description this function is to update the Bbot Estimated Activation Date to 28 days from Bbot Subscription Start Date
       				when Bbot Subscription Start Date is updated
     * @param quotes before update = trigger.new and trigger.oldMap
     * Ticket BZAP-17463
     */
    public static void updateBbotEstimatedActivationDate(List<SBQQ__Quote__c> newQuotes, Map<Id, SBQQ__Quote__c> oldMapQuotes){
        for(SBQQ__Quote__c quote: newQuotes){
            if(quote.DD_Id_s__c != null && quote.DD_Id_s__c.contains('BBOT')){
                if(isNewOrFieldUpdated(quote, oldMapQuotes, 'Bbot_Subscription_Start_Date__c') && quote.Bbot_Subscription_Start_Date__c != null){
                    quote.Bbot_Estimated_Activation_Date__c = quote.Bbot_Subscription_Start_Date__c.addDays(28);
                }
            }             
        }
    }

    /**
     * @description To validate Bbot Quote Approval Comments On Approval Submission
     * @param quotes before update = trigger.new and trigger.oldMap
     * Ticket Jitendra singh BZAP-18745
     */
    public static void validateBbotQuoteApprovalCommentsOnApprovalSubmission(List<SBQQ__Quote__c> newList , Map<Id, SBQQ__Quote__c> oldMap) {
        Set<Id> quoteIdSet = new Set<Id>();
        Map<Id, SBQQ__Quote__c> quoteAndLineMap = new Map<Id, SBQQ__Quote__c>();
        if (skipValidation('Bypass_Quote_Validations__c')) {
            return;
        }
        boolean isValidateQuoteForApprovalComments = false;
        for (SBQQ__Quote__c quote: newList) {
            if (quote.DD_Id_s__c != null && quote.DD_Id_s__c.contains('BBOT') &&
                quote.Approval_Comments__c == null && isNewOrFieldUpdated(quote, oldMap, 'ApprovalStatus__c') &&
                (quote.ApprovalStatus__c == APPROVAL_STATUS_PENDING || quote.ApprovalStatus__c == APPROVAL_STATUS_APPROVED)) {
                quoteIdSet.add(quote.Id);
            }
        }
        if (quoteIdSet.isEmpty()) {
            return;
        }

        quoteAndLineMap = new Map<Id, SBQQ__Quote__c>(
                                [SELECT Id, Bbot_Additional_Terms__c,
                                        (SELECT Id, Requested_Less_Deal_Desk_Commission__c, Parent_Package_Product_Name__c,
                                                SBQQ__SpecialPrice__c, SBQQ__ListPrice__c, Trial_Period__c
                                         FROM SBQQ__LineItems__r)
                                 FROM SBQQ__Quote__c
                                 WHERE id IN: quoteIdSet]);
        for(SBQQ__Quote__c quote : newList)
        {
            isValidateQuoteForApprovalComments = false;
            if (quote.Bbot_Additional_Terms__c != null && !isValidateQuoteForApprovalComments) {
                String strPickListValue = quote.Bbot_Additional_Terms__c;
                List<String> lstPicklistValues = strPickListValue.split(';');

                for (String defaultBbotValue: DEFAULT_BBOT_VALUES) {
                    if (lstPicklistValues.contains(defaultBbotValue)) {
                        lstPicklistValues.remove(lstPicklistValues.indexOf(defaultBbotValue));
                    }
                }
                if(lstPicklistValues.size() > 0)
                {
                    isValidateQuoteForApprovalComments = true;
                }
            }
            SBQQ__Quote__c qt = quoteAndLineMap.get(quote.Id);
            if(qt != null && !isValidateQuoteForApprovalComments && qt.SBQQ__LineItems__r.size() > 0)
            {
                for(SBQQ__QuoteLine__c quoteline: qt.SBQQ__LineItems__r)
                {
                    if(quoteline.Requested_Less_Deal_Desk_Commission__c == 1 ||
                       String.isNotBlank(quoteline.Trial_Period__c) ||
                       (quoteline.Parent_Package_Product_Name__c != null && quoteline.Parent_Package_Product_Name__c.CONTAINS('Hardware') && quoteline.SBQQ__SpecialPrice__c < quoteline.SBQQ__ListPrice__c))
                    {
                        isValidateQuoteForApprovalComments = true;
                    }
                }
            }
            if(isValidateQuoteForApprovalComments)
            {
                quote.addError(Label.Bbot_Approval_Comments_Error_Message);
            }
        }
    }
}