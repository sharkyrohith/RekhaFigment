/**
 * @description Unit tests for CDdCloneOppAndQuoteBatch. First implemented to verify the bug BZAP-14903.
 */
@isTest
private class CDdCloneOppAndQuoteBatchTest {
    // 24 characters so Salesforce id's can't possibly contain it -- we're asserting against 'contains', after all
    private static final String RESTAURANT_ID = '4242424242424242424242424242';

    @testSetup
    static void makeData(){
        Validation_Bypass__c validation =
            new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
        validation.Bypass_Opportunity_Validations__c = true;
        validation.Bypass_Account_Validations__c = true;
        validation.Bypass_Quote_Validations__c = true;
        insert validation;

        Account testAccount = TDdCpqTestDataFactory.createAccount(false);
        testAccount.Restaurant_ID__c = RESTAURANT_ID;
        insert testAccount;

        TDdCpqTestDataFactory.createOpportunity(testAccount.Id, true);
    }

    private static Opportunity getTestOpportunity(){
        return [SELECT Id,RecordTypeId,AccountId,Platform__c, CurrencyISOCode, Account_Billing_Country__c FROM Opportunity LIMIT 1];
    }

    /*
     * @description Queries for account using the CDdCloneOppAndQuote.queryAccounts method to ensure we query for the same values.
     */
    private static List<Account> getTestAccounts(Id accountId){
        return CDdCloneOppAndQuote.queryAccounts(
            new List<String>{String.valueOf(accountId)}
        );
    }

    @isTest
    private static void buildHTMLForFailuresTable_clonedOpp_withRestaurantId_expectPopulated(){
        Opportunity testOpportunity = getTestOpportunity();
        List<Account> testAccounts = getTestAccounts(testOpportunity.AccountId);
        testOpportunity.Account = testAccounts[0];

        List<Opportunity> testOpportunities = CDdCloneOppAndQuote.cloneOpportunity(testOpportunity, testAccounts);

        CDdCloneOppAndQuote.BatchContext testContext = new CDdCloneOppAndQuote.BatchContext();
        testContext.failedOpps = testOpportunities;

        CDdCloneOppAndQuoteBatch testBatch = new CDdCloneOppAndQuoteBatch(testContext);

        Test.startTest();
        String failureTable = testBatch.buildHTMLForFailuresTable(testBatch.context);
        Test.stopTest();

        System.assert(!String.isEmpty(failureTable), 'Expected a non-null, non-empty result.');
        System.assert(
            failureTable.contains(RESTAURANT_ID),
            'Expected the mocked restaurant id to be in the generated HTML: ' + failureTable
        );
    }

    @isTest
    private static void buildHTMLForFailuresTable_clonedOpp_withNullRestaurantId_expectTableBuilt(){
        Opportunity testOpportunity = getTestOpportunity();
        List<Account> testAccounts = getTestAccounts(testOpportunity.AccountId);
        testAccounts[0].Restaurant_ID__c = null;
        testOpportunity.Account = testAccounts[0];

        update testAccounts[0]; // BZAP-17747: the HTML building code now requeries for accounts

        List<Opportunity> testOpportunities = CDdCloneOppAndQuote.cloneOpportunity(testOpportunity, testAccounts);

        CDdCloneOppAndQuote.BatchContext testContext = new CDdCloneOppAndQuote.BatchContext();
        testContext.failedOpps = testOpportunities;

        CDdCloneOppAndQuoteBatch testBatch = new CDdCloneOppAndQuoteBatch(testContext);

        Test.startTest();
        String failureTable = testBatch.buildHTMLForFailuresTable(testBatch.context);
        Test.stopTest();

        System.assert(!String.isEmpty(failureTable), 'Expected a non-null, non-empty result.');
        System.assert(
            !failureTable.contains(RESTAURANT_ID),
            'Expected the mocked restaurant id to NOT be in the generated HTML: ' + failureTable
        );    }

    @isTest
    private static void buildHTMLForFailuresTable_clonedOpp_withEmptyRestaurantId_expectTableBuilt(){
        Opportunity testOpportunity = getTestOpportunity();
        List<Account> testAccounts = getTestAccounts(testOpportunity.AccountId);
        testAccounts[0].Restaurant_ID__c = '';
        testOpportunity.Account = testAccounts[0];

        update testAccounts[0]; // BZAP-17747: the HTML building code now requeries for accounts

        List<Opportunity> testOpportunities = CDdCloneOppAndQuote.cloneOpportunity(testOpportunity, testAccounts);

        CDdCloneOppAndQuote.BatchContext testContext = new CDdCloneOppAndQuote.BatchContext();
        testContext.failedOpps = testOpportunities;

        CDdCloneOppAndQuoteBatch testBatch = new CDdCloneOppAndQuoteBatch(testContext);

        Test.startTest();
        String failureTable = testBatch.buildHTMLForFailuresTable(testBatch.context);
        Test.stopTest();

        System.assert(!String.isEmpty(failureTable), 'Expected a non-null, non-empty result.');
        System.assert(
            !failureTable.contains(RESTAURANT_ID),
            'Expected the mocked restaurant id to NOT be in the generated HTML: ' + failureTable
        );
    }

    @isTest
    private static void buildHTMLForFailuresTable_CurrencyMismatch(){
        
        Opportunity testOpportunity = getTestOpportunity();
        List<Account> testAccounts = [
            SELECT Id, Name, Decision_Maker__c, Ultimate_Parent_Account__c, Ultimate_Parent_Id__c,Restaurant_ID__c, CurrencyISOCode, BillingCountry
                FROM Account
                WHERE Id = :testOpportunity.AccountId ];
        
        testAccounts[0].CurrencyISOCode='AUD';
        testOpportunity.CurrencyISOCode='USD';
        testOpportunity.Account = testAccounts[0];

        update testOpportunity;
        update testAccounts[0]; // BZAP-17747: the HTML building code now requeries for accounts

        List<Opportunity> testOpportunities = CDdCloneOppAndQuote.cloneOpportunity(testOpportunity, testAccounts);

        CDdCloneOppAndQuote.BatchContext testContext = new CDdCloneOppAndQuote.BatchContext();
        testContext.failedOpps = testOpportunities;

        CDdCloneOppAndQuoteBatch testBatch = new CDdCloneOppAndQuoteBatch(testContext);

        Test.startTest();
        String failureTable = testBatch.buildHTMLForFailuresTable(testContext);
        Test.stopTest();

        System.Assert(failureTable.contains('AUD'), 'Expected Account Currency IN Table. Instead: ' + failureTable);
    }

    @isTest
    private static void buildHTMLForFailuresTable_emptyContext_expectEmptyTable(){
        CDdCloneOppAndQuote.BatchContext testContext = new CDdCloneOppAndQuote.BatchContext();
        CDdCloneOppAndQuoteBatch testBatch = new CDdCloneOppAndQuoteBatch(testContext);

        Test.startTest();
        String failureTable = testBatch.buildHTMLForFailuresTable(testContext);
        Test.stopTest();

        System.assertNotEquals(null, failureTable, 'Expected a non-null result.');
        System.assertNotEquals('', failureTable, 'Expected a non-empty result.');
        System.Assert(!failureTable.contains('<td>'), 'Expected no cells in an empty table. Instead: ' + failureTable);
    }
    
    @isTest
    private static void buildbuildHTMLForSuccessesTable(){
        
        Opportunity testOpportunity = getTestOpportunity();
        List<Account> testAccounts = [
            SELECT Id, Name, Decision_Maker__c, Ultimate_Parent_Account__c, Ultimate_Parent_Id__c
                FROM Account
                WHERE Id = :testOpportunity.AccountId ];
        
        testAccounts[0].CurrencyISOCode='USD';
        testOpportunity.CurrencyISOCode='USD';
        testOpportunity.Account = testAccounts[0];

        update testAccounts[0]; // BZAP-17747: the HTML building code now requeries for accounts

        List<Opportunity> testOpportunities = CDdCloneOppAndQuote.cloneOpportunity(testOpportunity, testAccounts);

        CDdCloneOppAndQuote.BatchContext testContext = new CDdCloneOppAndQuote.BatchContext();
        testContext.oppAccCurrencyMismatch = testOpportunities;

        CDdCloneOppAndQuoteBatch testBatch = new CDdCloneOppAndQuoteBatch(testContext);

        Test.startTest();
        String successTable = testBatch.buildHTMLForSuccessesTable(testBatch.context);
        Test.stopTest();

        System.Assert(!String.isEmpty(successTable), 'Expected Non-Empty Result');
    }
}