@isTest
private class AQS_QuoteExtControllerTests {
    @testSetup static void setup() {
        Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
        validation.Bypass_Opportunity_Validations__c = true;
        validation.Bypass_Account_Validations__c = true;
        validation.Bypass_Quote_Validations__c = true;
        insert validation;
        
        List<Account> accounts = TDdAccountFactory.createAccounts('Test Acount', 1);
        Account account = accounts[0];
        account.Restaurant_ID__c = '123456';
        account.BillingCountry = CDdCpqBillingConstants.US_BILLING_COUNTRY;
        insert accounts;

        Product2 product1 = TDdCPQTestDataFactory.createProduct(true);
        PricebookEntry pbe1 = TDdCPQTestDataFactory.createPriceBookEntry(product1, 'USD', true);
    }
    
    testMethod static void testSubmit() {
        PriceBook2 pricebook = new Pricebook2(Id = Test.getStandardPricebookId(), isActive = true);
        update pricebook;
        List<Account> accounts = [Select id from Account Limit 1];
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];

        Opportunity testOpp = TDdCPQTestDataFactory.createOpportunityByDevRT('TestCPQOpp', accounts[0].Id, null, 'Meeting Ran / Negotiated', 'ML_Inside_Sales', false);
        testOpp.Legal_Entity__c = CDdCpqBillingConstants.US_LEGAL_ENT;
        testOpp.No_DashPass_Reason__c = CDdCpqBillingConstants.OPP_NO_DASHPASS_REASON_NOT_INTERESTED;
        insert testOpp;
        SBQQ__Quote__c quote = new SBQQ__Quote__c(SBQQ__Account__c = accounts[0].Id, SBQQ__Opportunity2__c = testOpp.Id);
        insert quote;
        SBQQ__QuoteLine__c quoteLine1 = TDdCPQTestDataFactory.createQuoteLine(product, quote, true);
        
        Test.startTest();
        AQS_QuoteExtController con = new AQS_QuoteExtController(new ApexPages.StandardController(quote));
        con.onSubmit();
        quote = [SELECT ApprovalStatus__c FROM SBQQ__Quote__c WHERE Id = :quote.Id LIMIT 1];
        Test.stopTest();
        
        System.assertEquals('Approved', quote.ApprovalStatus__c);
    }
    
    testMethod static void testErrorSubmit() {
        PriceBook2 pricebook = new Pricebook2(Id = Test.getStandardPricebookId(), isActive = true);
        update pricebook;
        List<Account> accounts = [Select id from Account Limit 1]; 
        Opportunity testOpp = TDdCPQTestDataFactory.createOpportunityByDevRT('TestCPQOpp', accounts[0].Id, null, 'Meeting Ran / Negotiated', 'ML_Inside_Sales', true);
        SBQQ__Quote__c quote = new SBQQ__Quote__c(SBQQ__Account__c = accounts[0].Id, SBQQ__Opportunity2__c = testOpp.Id);
        insert quote;
        
        Test.startTest();
        AQS_QuoteExtController con = new AQS_QuoteExtController(new ApexPages.StandardController(quote));
        
        // Delete the quote in order to throw an error
        delete quote;
        
        con.onSubmit();
        Test.stopTest();
        
        con.onCancel();
    }
    
    testMethod static void testRecall() {
        PriceBook2 pricebook = new Pricebook2(Id = Test.getStandardPricebookId(), isActive = true);
        update pricebook;
        List<Account> accounts = [Select id from Account Limit 1]; 
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        Opportunity testOpp = TDdCPQTestDataFactory.createOpportunityByDevRT('TestCPQOpp', accounts[0].Id, null, 'Meeting Ran / Negotiated', 'ML_Inside_Sales', true);
        SBQQ__Quote__c quote = new SBQQ__Quote__c(SBQQ__Account__c = accounts[0].Id, SBQQ__Opportunity2__c = testOpp.Id);
        insert quote;
        SBQQ__QuoteLine__c quoteLine1 = TDdCPQTestDataFactory.createQuoteLine(product, quote, true);
        Test.startTest();
        AQS_QuoteExtController con = new AQS_QuoteExtController(new ApexPages.StandardController(quote));
        con.onRecall();
        quote = [SELECT ApprovalStatus__c FROM SBQQ__Quote__c WHERE Id = :quote.Id LIMIT 1];
        Test.stopTest();
        
        System.assertEquals('Recalled', quote.ApprovalStatus__c);
    }
    
    testMethod static void testErrorRecall() {
        PriceBook2 pricebook = new Pricebook2(Id = Test.getStandardPricebookId(), isActive = true);
        update pricebook;
        List<Account> accounts = [Select id from Account Limit 1]; 
        Opportunity testOpp = TDdCPQTestDataFactory.createOpportunityByDevRT('TestCPQOpp', accounts[0].Id, null, 'Meeting Ran / Negotiated', 'ML_Inside_Sales', true);
        SBQQ__Quote__c quote = new SBQQ__Quote__c(SBQQ__Account__c = accounts[0].Id, SBQQ__Opportunity2__c = testOpp.Id);
        insert quote;
        
        Test.startTest();
        AQS_QuoteExtController con = new AQS_QuoteExtController(new ApexPages.StandardController(quote));
        
        // Delete the quote in order to throw an error
        delete quote;
        
        con.onRecall();
        Test.stopTest();
              
        con.onCancel();
    }
}