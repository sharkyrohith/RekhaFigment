/**
* @author: Cory Bartholomew (ATG)
* @date: 2021-04
* @Logic to clone a CPQ Opportunity and quote for a realted number of child stores under a parent.
*/
public class CDdCloneOppAndQuote {

    public static string STATUS_ERROR = 'Error';
    public static string STATUS_OK = 'Success';
    public static Integer BATCH_SIZE = CDdCustomMetadata.getBatchSize('CDdCloneOppAndQuote');
    public static string CANNOT_CLONE_ERROR = 'Clone Opp and Quote can only be used on Opportunities that are in Stage Closed Won';
    public static string PRIMARY_QUOTE_ERROR = 'You cannot clone from this opportunity as there is no Primary Quote attached';
    public static String MARKETPLACE_RT = CDdSchemaUtils.OPPORTUNITY_RT.mlInsideSalesId();
    public static String ENT_MARKETPLACE_RT = CDdSchemaUtils.OPPORTUNITY_RT.enterpriseMarketplaceId();
    public static Map<String, Schema.SObjectType> SOBJECT_TYPES = Schema.getGlobalDescribe();

    public static Set<String> ACCOUNT_PRIMARY_MERCHANT_CATEGORY = new Set<String>{'Grocery', 'Hot & Prepared (NV)'};
    // BZAP-16247; deprecated price basis values we need to check for when cloning old records
    @testVisible private static final String DEPRECATED_COMMISSION_BASED = 'Commission-based';
    @testVisible private static final String DEPRECATED_CURRENCY_BASED = 'Currency-based';
    @testVisible private static final String DEPRECATED_CURRENCY_PLUS_UNIT = 'Currency + Unit';

    /**
     * Sub Class that is used to pass the state of apex execution back to UI
     */
    public class CloneResult{
        @AuraEnabled public String status = STATUS_OK;
        @AuraEnabled public List<String> messages = new List<String>();
    }

    public class BatchContext{
        public Opportunity sourceOpp;
        public List<OpportunityLineItem> sourceOppLineItems;
        public List<Account> accounts;
        public SBQQ__Quote__c sourceQuote;
        public List<SBQQ__QuoteLine__c> sourceQuoteLines;
        public List<Opportunity> oppsToClone;
        public List<Opportunity> clonedOpps;
        public List<Opportunity> oppAccCurrencyMismatch;
        public List<Opportunity> failedOpps;
        public List<SBQQ__Quote__c> clonedQuotes;
        public List<SBQQ__QuoteLine__c> clonedQuoteLines;
        public Map<Id, List<SBQQ__QuoteLine__c>> quoteToClonedLineMap;
        public List<OpportunityLineItem> clonedOppLineItems;
        public String emailBody;
        public String stageName;
        public Integer startTime;

        public BatchContext(){
            this.startTime = DateTime.now().millisecond();
            this.accounts = new List<Account>();
            this.sourceOppLineItems = new List<OpportunityLineItem>();
            this.sourceQuoteLines = new List<SBQQ__QuoteLine__c>();
            this.oppsToClone = new List<Opportunity>();
            this.clonedOpps = new List<Opportunity>();
            this.failedOpps = new List<Opportunity>();
            this.clonedQuotes = new List<SBQQ__Quote__c>();
            this.oppAccCurrencyMismatch = new List<Opportunity>();
            this.clonedQuoteLines = new List<SBQQ__QuoteLine__c>();
            this.quoteToClonedLineMap = new Map<Id,List<SBQQ__QuoteLine__c>>();
            this.clonedOppLineItems = new List<OpportunityLineItem>();
            this.stageName = 'Contract Signed';
        }
    }

    public class AccountReturn{
        @AuraEnabled public String Id;
        @AuraEnabled public String Name;
        @AuraEnabled public String RestaurantId;
        @AuraEnabled public String Child;
        @AuraEnabled public String PreviouslyCloned;
        @AuraEnabled public String CurrentlyActive;
        @AuraEnabled public String IsPartnerNimda;
        @AuraEnabled public String UltimateParentAccount;

        public AccountReturn(Account basis, String child, String previouslyCloned) {
            this.Id = String.valueOf(basis.Id);
            this.Name = basis.Name;
            this.RestaurantId = basis.Restaurant_ID__c == null ? '' : basis.Restaurant_ID__c;
            this.Child = child;
            this.PreviouslyCloned = previouslyCloned;
            this.CurrentlyActive = basis.Currently_Active__c == null ? 'False' : basis.Currently_Active__c;
            this.IsPartnerNimda = basis.Is_Partner__c == null ? 'False' : basis.Is_Partner__c;
            this.UltimateParentAccount =
                basis.Ultimate_Parent_Account__c == null ? '' : String.valueOf(basis.Ultimate_Parent_Account__c);
        }
    }

    /**
     * @description  Get accounts related to the parent account from the source opportunity to let a user select which ones to clone the Opp to. Used via LWC wire
     * @param opportunityId the source Opportunity Id
     */
    @AuraEnabled(cacheable=true)
    public static List<AccountReturn> getRelatedAccounts(String opportunityId){
        List<AccountReturn> accountsReturned = new List<AccountReturn>();
        Opportunity sourceOpp = [
            SELECT Id, AccountId, Store_ID__c, SBQQ__PrimaryQuote__c,SBQQ__PrimaryQuote__r.SBQQ__Source__c, Account.ParentId, StageName,
            Account_Billing_Country__c, Account.Ultimate_Parent_Id__c, Account.Ultimate_Parent_Account__c,
            Account.Primary_Merchant_Categories__c FROM Opportunity
            WHERE Id =: opportunityId
            ];

        //BZAP-11881, BASD-49447: Clone tool only allowed on Closed Won Opportunities or when Opportunity is contract signed and PMC= Alcohol
        if (!ACCOUNT_PRIMARY_MERCHANT_CATEGORY.contains(sourceOpp.Account.Primary_Merchant_Categories__c) && sourceOpp.StageName != CDdCpqBillingConstants.OPP_STAGENAME_CLOSED_WON){

            if(sourceOpp.StageName != CDdCpqBillingConstants.OPP_STAGENAME_CONTRACT_SIGNED){
                //Throwing this exception will disply the error in the LWC
                throw new AuraHandledException(CANNOT_CLONE_ERROR);
            }else If(sourceOpp.Account.Primary_Merchant_Categories__c != 'Alcohol'){
                throw new AuraHandledException(CANNOT_CLONE_ERROR);
            }
        }

        //BZAP-14099
        if (sourceOpp.SBQQ__PrimaryQuote__c == null) {
            //Clone tool only allowed for opportunites having primary quote.
            //Throwing this exception will disply the error in the LWC
            throw new AuraHandledException(PRIMARY_QUOTE_ERROR);
        }

        if (sourceOpp.Account.Ultimate_Parent_Id__c != null) {
            //Filter the returned clones so we dont allow cloning of the same location again
            String primarySource = sourceOpp.SBQQ__PrimaryQuote__c;
            String whereClause = ' SBQQ__PrimaryQuote__r.SBQQ__Source__c =:primarySource';

            List<Opportunity> previousClonedOpps  = Database.query('Select Id, Store_ID__c, AccountId, Account.ParentId FROM Opportunity WHERE ' + whereClause);
            Set<Id> previouslyClonedAccounts = new Set<Id>();
            if(!previousClonedOpps.isEmpty()){
                for(Opportunity opp : previousClonedOpps){
                    previouslyClonedAccounts.add(opp.AccountId);
                }
            }

            Id accountToSearch = sourceOpp.Account.Ultimate_Parent_Account__c == null ? sourceOpp.AccountId : sourceOpp.Account.Ultimate_Parent_Account__c;

            List<Account> allRelatedAccounts = [
                                SELECT Id, Name, Restaurant_ID__c, ParentId, Currently_Active__c, Is_Partner__c, Ultimate_Parent_Account__c, Ultimate_Parent_Id__c
                                FROM Account
                                WHERE Ultimate_Parent_Account__c = :accountToSearch AND
                                      Id != :sourceOpp.AccountId AND
                                      RecordTypeId = :CDdSchemaUtils.ACCOUNT_RT.prospectId()];

            for (Account acc: allRelatedAccounts) {
                String child = 'false';
                String previouslyCloned = 'false';
                if (acc.ParentId == sourceOpp.AccountId) {
                    child = 'true';
                }
                if (previouslyClonedAccounts.contains(acc.Id)) {
                    previouslyCloned = 'true';
                }
                AccountReturn accRet = new AccountReturn(acc, child, previouslyCloned);
                accountsReturned.add(accRet);
            }
        }
        return accountsReturned;
    }

    /**
    * @description  Get accounts related to the parent account from the souce opportunity to let a user select which ones to clone the Opp to. Used via LWC wire
    * @param accountIds
    */
    @AuraEnabled(cacheable=true)
    public static List<AccountReturn> getSelectedAccounts(List<String> accountIds, string quoteId) {
        //Filter the returned clones so we dont allow cloning of the same location again
        Set<Id> previouslyClonedAccounts = getPreviouslyClonedAccounts(quoteId);

        List<Account> accounts =  [
                SELECT Id, Name, Restaurant_ID__c, Currently_Active__c, Is_Partner__c, Ultimate_Parent_Account__c, Ultimate_Parent_Id__c
                FROM Account
                WHERE Id IN :accountIds
                ORDER BY Name ASC];

        return buildAccountsReturnedList(accounts, previouslyClonedAccounts);
    }

    /**
    * @description  BZAP-13831 Get accounts for Cloning based off of StoreId. Used from LWC
    * @param storeIds
    */
    @AuraEnabled(cacheable=true)
    public static List<AccountReturn> getSelectedStoreIds(List<String> storeIds, string quoteId) {
        //Filter the returned clones so we dont allow cloning of the same location again
        Set<Id> previouslyClonedAccounts = getPreviouslyClonedAccounts(quoteId);

        List<Account> accounts =  [
                SELECT Id, Name, Restaurant_ID__c, Currently_Active__c, Is_Partner__c, Ultimate_Parent_Account__c, Ultimate_Parent_Id__c
                FROM Account
                WHERE Restaurant_ID__c IN :storeIds
                ORDER BY Name ASC];

        return buildAccountsReturnedList(accounts, previouslyClonedAccounts);
    }

    //private function to returned previously cloned accounts.
    private static Set<Id> getPreviouslyClonedAccounts(string quoteId) {
        Set<Id> previouslyClonedAccounts = new Set<Id>();
        String whereClause = ' SBQQ__PrimaryQuote__r.SBQQ__Source__c = :quoteId';

        List<Opportunity> previousClonedOpps  = Database.query('Select Id, Store_ID__c, AccountId, Account.ParentId FROM Opportunity WHERE ' + whereClause);
        if(!previousClonedOpps.isEmpty()){
            for(Opportunity opp : previousClonedOpps){
                previouslyClonedAccounts.add(opp.AccountId);
            }
        }
        return previouslyClonedAccounts;
    }

    //private function to returned previously cloned accounts.
    private static List<AccountReturn> buildAccountsReturnedList(List<Account> accounts, Set<Id> previouslyClonedAccounts) {
        List<AccountReturn> accountsReturned = new List<AccountReturn>();
        for (Account acc: accounts) {
            String child = 'false';
            String previouslyCloned = 'false';
            if (previouslyClonedAccounts.contains(acc.Id)) {
                previouslyCloned = 'true';
            }
            AccountReturn accRet = new AccountReturn(acc, child, previouslyCloned);
            accountsReturned.add(accRet);
        }
        return accountsReturned;
    }

     /**
     * @description Clone an opportunity, quote, and quote lines for a number of related accounts keeping the CPQ bundle structure intact.
     * @param oppId The source Opportunity Id
     * @param storeIds The Id of realted account to clone the opportunity to
     * @return CloneResult the CloneResult object containing status and errors if any occurred
     */
    @AuraEnabled()
    public static CloneResult cloneOppandQuote(String oppId, List<String> storeIds, String bulkActivation, String stageName){
        CloneResult result = new CloneResult();
        try{
            //Get the source Opportunity to clone and validate there is also a primary quote to clone
            List<Opportunity> sourceOpps = querySourceSObject(oppId, 'Opportunity', result);
            if (sourceOpps.size() > 0) {
                //BZAP-12091 set bulk activation field if necessary.
                Boolean bulkAct = bulkActivation == 'true' ? true : false;
                if (bulkAct != sourceOpps[0].Bulk_Activation__c) {
                    sourceOpps[0].Bulk_Activation__c = bulkAct;
                    update sourceOpps[0];
                }

                //We query by Id for Opp so there should only be 1 record.
                if(sourceOpps[0].SBQQ__PrimaryQuote__c == null){
                    result.status = STATUS_ERROR;
                    result.messages.add('There is no primary quote to clone.');
                    return result;
                } else {
                    BatchContext context = new BatchContext();
                    context.accounts = queryAccounts(storeIds);
                    context.sourceOpp = sourceOpps[0];
                    context.sourceOppLineItems = querySourceSObject(sourceOpps[0].Id,'OpportunityLineItem', result);
                    context.sourceQuote = (SBQQ__Quote__c) querySourceSObject(sourceOpps[0].SBQQ__PrimaryQuote__c, 'SBQQ__Quote__c', result)[0];
                    context.sourceQuoteLines = querySourceSObject(sourceOpps[0].SBQQ__PrimaryQuote__c, 'SBQQ__QuoteLine__c', result);
                    context.stageName = stageName;
                    //call batch to clone Opps and chain additional batches to clone quote and quote lines
                    Id batchId = Database.executeBatch(new CDdCloneOppAndQuoteBatch(context),BATCH_SIZE);
                }
            } else {
                result.STATUS = STATUS_ERROR;
                result.messages.add('Opportunity not found.');
            }
        } catch (Exception e){
            result.STATUS = STATUS_ERROR;
            result.messages.add('An error occurred when submitting the batch job ' + e.getMessage());
        }

        return result;

    }

    /**
     * @description Clone an Opportunity for a list of related accounts and associate it to them
     * @param sourceOpp The opportunity to clone
     * @param accounts The related stores to associate the cloned Opportunities to
     * @return list of cloned opportunitites
     */
    public static List<Opportunity> cloneOpportunity(Opportunity sourceOpp, List<Account> accounts){
        List<Opportunity> clonedOpps = new List<Opportunity>();
        for(Account account : accounts){
            Opportunity opp = sourceOpp.clone(false, true, false, false);
            DateTime dt = System.today();
            // BZAP-14903; need *both* Account and AccountId so we can reference fields on object.
            //  in case of failure we won't be able to requery this,
            //  so formula fields like Opportunity.Store_ID__c won't be
            //  available and Account.Restaurant_ID__c will be needed.
            opp.Account = account;
            opp.AccountId = account.Id;
            opp.SBQQ__PrimaryQuote__c = null;
            //BZAP-12146 removed code that changed the cloned opp name.
            opp.StageName = 'Contract Signed';
            opp.isCloned__c = true;
            //BZAP-18360 - Removed code that was setting Contract Signed Date to null
            opp.Decision_Maker__c = account.Decision_Maker__c;
            opp.Docusign_Sent__c = null;
            opp.Marketplace_Contract_Link__c = null;
            opp.Merchant_Supplied_ID__c = null;
            opp.of_Addressable_Locations__c = null;
            opp.RecordTypeId = sourceOpp.recordTypeId;
            opp.BypassValidationForPB__c = true; // FIX:08132021
            opp.Activation_Date__c = null;

            //Q2C-1080 for Caviar Opps we need to create a caviar onboarding case
            if(
                (opp.RecordTypeId == MARKETPLACE_RT ||
                opp.RecordTypeId == ENT_MARKETPLACE_RT
                ) &&
                (opp.Platform__c == CDdCpqBillingConstants.OPP_PLATFORM_CAVIAR ||
                 opp.Platform__c == CDdCpqBillingConstants.OPP_PLATFORM_CAVIAR_DOORDASH
                )
            ) {
                opp.Caviar_Onboarding_Case_Created__c = false;
            }
            clonedOpps.add(opp);
        }
        return clonedOpps;
    }

    /**
     * @description clone a quote and associated it to the previously cloned Opportunities
     * @param sourceQuote The original quote to clone
     * @param opps The cloned opportunities to associate the new quotes to
     * @return List of cloned quotes
     *
     */
    public static List<SBQQ__Quote__c> cloneQuote(SBQQ__Quote__c sourceQuote, List<Opportunity> opps){
        DateTime dt = System.now();
        List<SBQQ__Quote__c> clonedQuotes = new List<SBQQ__Quote__c>();
        for(Opportunity opp : opps){
            SBQQ__Quote__c quote = sourceQuote.clone(false, true, false, false);
            quote.SBQQ__Account__c = opp.AccountId;
            quote.SBQQ__Opportunity2__c = opp.Id;
            quote.SBQQ__Source__c = sourceQuote.Id;
            quote.SBQQ__LastCalculatedOn__c = dt;
            quote.SBQQ__LastSavedOn__c = dt;
            quote.SBQQ__Ordered__c = false;
            quote.Drawer_Attributes__c = CDdCreateQuoteFromOppCtrl.drawer_attributes;
            clonedQuotes.add(quote);
        }
        return clonedQuotes;
    }

    /**
     * @description clone all quote lines and associate them to the newly cloned quotes keeping the hierarchy intact
     * @param sourceQuoteLines The original quote lines to clone
     * @param clonedQuotes The cloned quotes to associate the new quote lines to
     * @return List of quote lines
     */
    public static List<SBQQ__QuoteLine__c> cloneQuoteLines(List<SBQQ__QuoteLine__c> sourceQuoteLines, SBQQ__Quote__c clonedQuote){
            List<SBQQ__QuoteLine__c> clonedLines = new List<SBQQ__QuoteLine__c>();
            for(SBQQ__QuoteLine__c sourceLine : sourceQuoteLines){
                // BZAP-16247; update legacy price basis
                if(DEPRECATED_COMMISSION_BASED.equalsIgnoreCase(sourceLine.Price_Basis__c)){
                    sourceLine.Price_Basis__c = CDdCpqBillingConstants.PRODUCT_PRICEBASIS_COMMISSION;
                } else if (DEPRECATED_CURRENCY_BASED.equalsIgnoreCase(sourceLine.Price_Basis__c)){
                    sourceLine.Price_Basis__c = CDdCpqBillingConstants.PRODUCT_PRICEBASIS_FLATCOMMISSION;
                } else if (DEPRECATED_CURRENCY_PLUS_UNIT.equalsIgnoreCase(sourceLine.Price_Basis__c)){
                    sourceLine.Price_Basis__c = CDdCpqBillingConstants.PRODUCT_PRICEBASIS_COMMISSIONPLUSFLAT;
                }

                // BZAP-16774; if final fee not set set it to list price
                if(sourceLine.Final_Fee__c == null){
                    sourceLine.Final_Fee__c = sourceLine.SBQQ__ListPrice__c;
                }

                SBQQ__QuoteLine__c clonedLine = sourceLine.clone(false, true, false, false);
                clonedLine.SBQQ__Quote__c = clonedQuote.Id;
                clonedLine.SBQQ__RequiredBy__c = null; //Remove hierarchy dependency that will be recreated once there are record Ids
                clonedLine.SBQQ__Source__c = sourceLine.Id;
                clonedLines.add(clonedLine);
            }

        return clonedLines;
    }

    /**
     * @description clone all quote lines and associate them to the newly cloned quotes keeping the hierarchy intact
     * @param sourceQuoteLines The original quote lines to clone
     * @param clonedQuotes The cloned quotes to associate the new quote lines to
     * @return List of quote lines
     */
    public static List<OpportunityLineItem> cloneOppLines(List<OpportunityLineItem> sourceOppLines, Opportunity clonedOpp){
        List<OpportunityLineItem> clonedLines = new List<OpportunityLineItem>();
        for(OpportunityLineItem sourceLine : sourceOppLines){
            // BZAP-16247; update legacy price basis
            if(DEPRECATED_COMMISSION_BASED.equalsIgnoreCase(sourceLine.Price_Basis__c)){
                sourceLine.Price_Basis__c = CDdCpqBillingConstants.PRODUCT_PRICEBASIS_COMMISSION;
            } else if (DEPRECATED_CURRENCY_BASED.equalsIgnoreCase(sourceLine.Price_Basis__c)){
                sourceLine.Price_Basis__c = CDdCpqBillingConstants.PRODUCT_PRICEBASIS_FLATCOMMISSION;
            } else if (DEPRECATED_CURRENCY_PLUS_UNIT.equalsIgnoreCase(sourceLine.Price_Basis__c)){
                sourceLine.Price_Basis__c = CDdCpqBillingConstants.PRODUCT_PRICEBASIS_COMMISSIONPLUSFLAT;
            }

            // BZAP-16774; if final fee not set set it to list price
            if(sourceLine.Final_Fee__c == null){
                sourceLine.Final_Fee__c = sourceLine.ListPrice;
            }

            OpportunityLineItem clonedLine = sourceLine.clone(false, true, false, false);
            clonedLine.OpportunityId = clonedOpp.Id;
            clonedLine.SBQQ__ParentId__c = null; //Remove hierarchy dependency that will be recreated once there are record Ids
            clonedLine.TotalPrice = null;
            clonedLines.add(clonedLine);
        }

    return clonedLines;
    }

    public static List<SBQQ__QuoteLine__c> processQuoteLineClone(List<SBQQ__QuoteLine__c> sourceQuoteLines, List<SBQQ__Quote__c> quotes, CloneResult result){
        List<SBQQ__QuoteLine__c> clonedQuoteLines = new List<SBQQ__QuoteLine__c>();
        Map<Id,SBQQ__QuoteLine__c> sourceQuoteLinesMap = new Map<Id,SBQQ__QuoteLine__c>();
        Map<Id, List<SBQQ__QuoteLine__c>> quoteToClonedLineMap = new Map<Id,List<SBQQ__QuoteLine__c>>();
        List<SBQQ__QuoteLine__c> quoteLinesToUpdate = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> quoteLinesToInsert = new List<SBQQ__QuoteLine__c>();
        List<String> quoteLineErrors = new List<String>();

        for(SBQQ__QuoteLine__c quoteLine : sourceQuoteLines){
            if(!sourceQuoteLinesMap.containsKey(quoteLine.Id)){
                sourceQuoteLinesMap.put(quoteLine.Id, quoteLine);
            }
        }
        for(SBQQ__Quote__c quote : quotes){
            quoteToClonedLineMap.put(quote.Id, cloneQuoteLines(sourceQuoteLines, quote));
        }
        //Turn off CPQ Triggers to avoid a calculation on insert
        SBQQ.TriggerControl.disable();
        //insert all or nothing so we dont partially fail quote lines for a given quote
        for(Id quoteId : quoteToClonedLineMap.keySet()){
            quoteLinesToInsert.addAll(quoteToClonedLineMap.get(quoteId));
        }
        List<Database.SaveResult> quoteLineResults = Database.insert(quoteLinesToInsert, false);
        quoteLineErrors = CDdErrorUtilities.processSaveResults(quoteLineResults);
        if(!quoteLineErrors.isEmpty()){
            result.status = CDdCloneOppAndQuote.STATUS_ERROR;
            result.messages.addAll(quoteLineErrors);
            CDdErrorUtilities.createApexLogs(quoteLineErrors,'CDdCloneOppAndQuoteBatch', 'execute > Quote Line Insert',LoggingLevel.INFO);
        }
        if(quoteLineErrors.isEmpty()){
            for(Id quoteId : quoteToClonedLineMap.keySet()){
                List<SBQQ__QuoteLine__c> clonedLines = quoteToClonedLineMap.get(quoteId);
                //If the insert was successful update the hierarchy relationships on the quote lines
                Map<Id,Id> qlCloneReferenceMap = getCloneReferenceIds(clonedLines);
                updateClonedQuoteLineHierarchy(clonedLines, sourceQuoteLinesMap, qlCloneReferenceMap);
                quoteLinesToUpdate.addAll(clonedLines);
            }

            List<Database.SaveResult> quoteLineUpdateResults = Database.update(quoteLinesToUpdate, false);
            quoteLineErrors.addAll(CDdErrorUtilities.processSaveResults(quoteLineUpdateResults));
            if(!quoteLineErrors.isEmpty()){
                result.status = CDdCloneOppAndQuote.STATUS_ERROR;
                result.messages.addAll(quoteLineErrors);
                CDdErrorUtilities.createApexLogs(quoteLineErrors, 'CDdCloneOppAndQuoteBatch', 'execute > Quote Line Update',LoggingLevel.INFO);
            }
        }
        SBQQ.TriggerControl.enable();
        return quoteLinesToUpdate;
    }

    public static List<OpportunityLineItem> processOppLineClone(List<OpportunityLineItem> sourceOppLineItems, List<Opportunity> opps,Map<Id,Id> qlCloneRefMap, CloneResult result){
        Map<Id, OpportunityLineItem> sourceOppLinesMap = new Map<Id,OpportunityLineItem>();
        Map<Id, List<OpportunityLineItem>> oppToClonedLineMap = new Map<Id,List<OpportunityLineItem>>();
        List<OpportunityLineItem> oppLinesToInsert = new List<OpportunityLineItem>();
        List<OpportunityLineItem> oppLinesToUpdate = new List<OpportunityLineItem>();
        List<String> oppLineErrors = new List<String>();
        for(OpportunityLineItem oppLine : sourceOppLineItems){
            if(!sourceOppLinesMap.containsKey(oppLine.Id)){
                sourceOppLinesMap.put(oppLine.Id, oppLine);
            }
        }

        for(Opportunity opp : opps){
                oppToClonedLineMap.put(opp.Id, cloneOppLines(sourceOppLineItems, opp));
        }

        for(Id oppId : oppToClonedLineMap.keySet()){
            oppLinesToInsert.addAll(oppToClonedLineMap.get(oppId));
        }
        List<Database.SaveResult> oppLineResults = Database.insert(oppLinesToInsert, false);
        oppLineErrors.addAll(CDdErrorUtilities.processSaveResults(oppLineResults));
        if(!oppLineErrors.isEmpty()){
            result.status = CDdCloneOppAndQuote.STATUS_ERROR;
            result.messages.addAll(oppLineErrors);
            CDdErrorUtilities.createApexLogs(oppLineErrors,'CDdCloneOppAndQuoteBatch', 'execute > Opp Line Insert',LoggingLevel.INFO);
        }

        if(result.status != STATUS_ERROR){
            for(Id oppId : oppToClonedLineMap.keySet()){
                List<OpportunityLineItem> clonedLines = oppToClonedLineMap.get(oppId);
                //If the insert was successful update the hierarchy relationships on the quote lines
                Map<Id,Id> cloneReferenceMap = getCloneReferenceIds(clonedLines);
                oppLinesToUpdate = updateClonedOppLineHierarchy(clonedLines, sourceOppLinesMap, cloneReferenceMap, qlCloneRefMap);

            }

            List<Database.SaveResult> oppLineUpdateResults = Database.update(oppLinesToUpdate, false);
            oppLineErrors.addAll(CDdErrorUtilities.processSaveResults(oppLineUpdateResults));
            if(!oppLineErrors.isEmpty()){
                result.status = CDdCloneOppAndQuote.STATUS_ERROR;
                result.messages.addAll(oppLineErrors);
                CDdErrorUtilities.createApexLogs(oppLineErrors,'CDdCloneOppAndQuoteBatch', 'execute > Opp Line Update',LoggingLevel.INFO);
            }
        }
        return oppLinesToUpdate;
    }

    /**
     * @description Associate the clone record Id to the original record Id for lookup when neeed
     * @param clonedObjects A list of clone SObjects
     * @return  Map<Id,Id> object Id to clone source Id
     */
    public static Map<Id,Id> getCloneReferenceIds(List<SObject> clonedObjects){
        Map<Id,Id> cloneIdToSourceIdMap = new Map<Id,Id>();
        for(SObject obj : clonedObjects){
            cloneIdToSourceIdMap.put(obj.getCloneSourceId(), obj.Id);
        }
        return cloneIdToSourceIdMap;
    }

    /**
     * @description Rebuild the quote line hierarchy based on the source object Ids
     * @param clonedLines A list of cloned quote lines
     * @param sourceQuoteLinesMap A map of the source quote lines by Id
     * @param qlCloneReferenceMap a map of cloned quote line Ids to their source line Id
     * @return  Map<Id,Id> Cloned object Id to source object Id
     */
    public static void updateClonedQuoteLineHierarchy(List<SBQQ__QuoteLine__c> clonedLines, Map<Id, SBQQ__QuoteLine__c> sourceQuoteLinesMap, Map<Id, Id> qlCloneReferenceMap){

        for(SBQQ__QuoteLine__c clonedQuoteLine : clonedLines){
            Id sourceId = clonedQuoteLine.getCloneSourceId();
            SBQQ__Quoteline__c sourceQuoteLine = sourceQuoteLinesMap.get(sourceId);
            //If this line was a child we need to find the original parent.  Then, find the parent clone and map it to the child clone
            Id sourceParentId;
            if(sourceQuoteLine.SBQQ__RequiredBy__c != null){
                if(sourceQuoteLinesMap.containsKey(sourceQuoteLine.SBQQ__RequiredBy__c)){
                    sourceParentId = sourceQuoteLinesMap.get(sourceQuoteLine.Id).SBQQ__RequiredBy__c;
                }
                if(sourceParentId != null && qlCloneReferenceMap.containsKey(sourceParentId)){
                    Id newParentId = qlCloneReferenceMap.get(sourceParentId);
                    clonedQuoteLine.SBQQ__RequiredBy__c = newParentId;
                }
                sourceId = null;
                sourceParentId = null;
             }
        }
    }

     /**
     * @description Rebuild the opp line hierarchy based on the source object Ids
     * @param clonedLines A list of cloned Opportunity lines
     * @param sourceOppeLinesMap A map of the source Opp lines by Id
     * @param cloneReferenceMap a map of cloned opp line Ids to their source line Id
     * @return  Map<Id,Id> Cloned object Id to source object Id
     */
    public static List<OpportunityLineItem> updateClonedOppLineHierarchy(
        List<OpportunityLineItem> clonedLines,
        Map<Id, OpportunityLineItem> sourceOppLinesMap,
        Map<Id, Id> cloneReferenceMap,
        Map<Id, Id> quoteLineCloneRefMap
    ){
        List<OpportunityLineItem> linesToUpdate = new List<OpportunityLineItem>();
        for(OpportunityLineItem clonedLine : clonedLines){
            OpportunityLineItem lineToUpdate = new OpportunityLineItem(Id = clonedLine.Id);
            Id sourceId = clonedLine.getCloneSourceId();
            OpportunityLineItem sourceLine = sourceOppLinesMap.get(sourceId);
            //If this line was a child we need to find the original parent.  Then, find the parent clone and map it to the child clone
            Id sourceParentId;
            if(sourceLine.SBQQ__ParentId__c != null){
                if(sourceOppLinesMap.containsKey(sourceLine.SBQQ__ParentId__c)){
                    sourceParentId = sourceOppLinesMap.get(sourceLine.Id).SBQQ__ParentId__c;
                }
                if(sourceParentId != null && cloneReferenceMap.containsKey(sourceParentId)){
                    Id newParentId = cloneReferenceMap.get(sourceParentId);
                    lineToUpdate.SBQQ__ParentId__c = newParentId;
                }
                sourceId = null;
                sourceParentId = null;
            }

            if(sourceLine.SBQQ__QuoteLine__c != null){
                if(quoteLineCloneRefMap.containsKey(sourceLine.SBQQ__QuoteLine__c)){
                    lineToUpdate.SBQQ__QuoteLine__c = quoteLineCloneRefMap.get(sourceLine.SBQQ__QuoteLine__c);
                }
            }

            linesToUpdate.add(lineToUpdate);
        }
        return linesToUpdate;
    }

    public static String buildErrorString(List<String> messages, String objectName){
        String errString = '';
        if(messages.size() > 0) {
            errString += '<h3>Errors</h3>';
            Integer lineNumber = 1;
            for(String error : messages) {
                errString += '<p>' + lineNumber + '. ' + error + '</p>';
                lineNumber++;
            }
        }

        return errString;
    }

    public static void sendEmail(Opportunity opp, String emailBody){
        User user = [select Email from User where Id =: UserInfo.getUserId()];
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.toAddresses = new String[] { user.Email };
        email.subject = 'Cloning for Opportunity ' + opp.Name + ' is complete';
        email.htmlBody = emailBody;
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }

    /**
     * @description query an Sobject and all updateable fields for cloning
     * @param recordId The record Id to use in the soql filter
     * @param objectName The object name string to pivot soql logic on
     * @param result The CloneResult object to pass the status of the query along
     * @return List<Sobject> A list of source object(s)
     */
    public static List<SObject> querySourceSObject(Id recordId, String objectName, CloneResult result){
        List<SObject> sourceRecords = new List<SObject>();
        try{
        //We want to query all quote lines in the same transaction so determine which field to use in the query based on object name
        String queryFilterField = 'Id';
        if(objectName == 'SBQQ__QuoteLine__c'){
            queryFilterField = 'SBQQ__Quote__c';
        } else if( objectName == 'OpportunityLineItem'){
            queryFilterField = 'OpportunityId';
        }

        SObjectType sObjectType = SOBJECT_TYPES.get(objectName);
        Map<String, Schema.SObjectField> fields = sObjectType.getDescribe().fields.getMap();

        //Retrieve all updateable fields
        List<String> fieldNames = new List<String>();
        if(objectName == 'OpportunityLineItem'){
            fieldNames.add('PriceBookEntryId');
            fieldNames.add('ListPrice');
        }

        if(objectName == 'Opportunity'){
            fieldNames.add('Account_Billing_Country__c');
        }

        for (Schema.SObjectField field : fields.values()) {
            DescribeFieldResult describe = field.getDescribe();
            if (describe.isUpdateable()) {
                fieldNames.add(describe.name);
            }
        }
            String soql = 'SELECT ' + String.join(fieldNames, ', ') + ' FROM ' + objectName + ' WHERE ' + queryFilterField + ' =\'' + recordId + '\'';
            sourceRecords = Database.query(soql);
        } catch (Exception e){
            result.status = STATUS_ERROR;
            result.messages.add(e.getMessage() + ' ' + e.getStackTraceString());
        }
        return sourceRecords;
    }

     /**
     * @description query accounts and relevant fields by Id
     * @param accountIds The record Ids to query
     * @return List of Account
     */
    public static List<Account> queryAccounts(List<String> accountIds){
        List<Account> accounts = [
            SELECT Id, Name, Decision_Maker__c, Restaurant_ID__c, Ultimate_Parent_Account__c, Ultimate_Parent_Id__c, CurrencyIsoCode, BillingCountry
            FROM Account
            WHERE Id IN :accountIds
        ];
        return accounts;
    }
}