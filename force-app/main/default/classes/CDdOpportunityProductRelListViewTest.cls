@isTest
public with sharing class CDdOpportunityProductRelListViewTest {
    @testSetup
    static void setup(){
       
        Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
        validation.Bypass_Opportunity_Validations__c = true; 
        validation.Bypass_Account_Validations__c = true;
        insert validation;      
        
        List<Account> accounts = TDdAccountFactory.createAccounts('Test Acount', 1);
        insert accounts;
		
        Product2 product = TDdCPQTestDataFactory.createProduct(true);
        Pricebook2 pricebook2 = new Pricebook2();
        pricebook2.Id = Test.getStandardPricebookId();
        pricebook2.IsActive = true;
        update pricebook2;
        PricebookEntry pbe = TDdCPQTestDataFactory.createPriceBookEntry(product, pricebook2, 'USD', true);
        Opportunity testOpp = TDdCPQTestDataFactory.createOpportunityByDevRT('TestCPQOpp', accounts[0].Id, null, 'Meeting Ran / Negotiated', 'ML_Inside_Sales', false);
        insert testOpp;
		OpportunityLineItem testOppLine = TDdCPQTestDataFactory.createOpportunityLineItem(testOpp.Id, product.Id, pbe.Id, true);
        SBQQ__Quote__c quote = TDdCPQTestDataFactory.createQuote(testOpp, accounts[0], null, true);     
    }
    @isTest
    static void testGetLimitRecords(){
        Account acct1 = [SELECT Id FROM Account LIMIT 1];
        SBQQ__QuoteLine__c quoteLine1 = [SELECT Id, Final_Commission__c, SBQQ__NetTotal__c, DD_Custom_ID__c FROM SBQQ__QuoteLine__c LIMIT 1];
        Opportunity opp1 = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        CDdOpportunityProductRelListViewClass.getLimitRecords(opp1.Id);
        Test.stopTest();      
        OpportunityLineItem testOppLine = [SELECT Id, Product_Name__c FROM OpportunityLineItem LIMIT 1];
        System.assertEquals (testOppLine.Product_Name__c , 'Test Product');
    }
    
    @isTest
    static void getAllRecords(){
        Account acct1 = [SELECT Id FROM Account LIMIT 1];
        SBQQ__QuoteLine__c quoteLine1 = [SELECT Id, Final_Commission__c, SBQQ__NetTotal__c, DD_Custom_ID__c FROM SBQQ__QuoteLine__c LIMIT 1];
        Opportunity opp1 = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        CDdOpportunityProductRelListViewClass.getAllRecords(opp1.Id);
        Test.stopTest();      
        OpportunityLineItem testOppLine = [SELECT Id, Product_Name__c FROM OpportunityLineItem LIMIT 1];
        System.assertEquals (testOppLine.Product_Name__c , 'Test Product');
    }
}