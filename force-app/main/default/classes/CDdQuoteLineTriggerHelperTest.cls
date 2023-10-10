@isTest
public class CDdQuoteLineTriggerHelperTest {
    @testSetup
    static void setup(){
        Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
        validation.Bypass_Opportunity_Validations__c = true; 
        validation.Bypass_Account_Validations__c = true;
        insert validation;      
        Test.startTest();
        List<Account> accounts = TDdAccountFactory.createAccounts('Test Acount', 1);
        insert accounts;

        Product2 product = TDdCPQTestDataFactory.createProduct(true);
        Pricebook2 pricebook2 = new Pricebook2();
        pricebook2.Id = Test.getStandardPricebookId();
        pricebook2.IsActive = true;
        update pricebook2;
        PricebookEntry pbe = TDdCPQTestDataFactory.createPriceBookEntry(product, pricebook2, 'USD', true);
        Opportunity testOpp = TDdCPQTestDataFactory.createOpportunityByDevRT('TestCPQOpp', accounts[0].Id, null, 'Meeting Ran / Negotiated', 'ML_Inside_Sales', true);
		Test.stopTest();
        
        SBQQ__Quote__c quote = TDdCPQTestDataFactory.createQuote(testOpp, accounts[0], null, false);
        quote.SBQQ__Status__c = 'Contract Signed';
        quote.ApprovalStatus__c = 'Approved';
        insert quote;

        SBQQ__QuoteLine__c quoteLine = TDdCPQTestDataFactory.createQuoteLine(product, quote, false);
        
        quoteLine.Original_Commission__c = 0.54;
        insert quoteLine;
    }
    
    @isTest
    static void testUpdateQuoteFields111(){
        Product2 prod1 = [SELECT Id, DD_Custom_ID__c, Price_Basis__c FROM Product2 LIMIT 1];
        Test.startTest();
        SBQQ.TriggerControl.disable();
        
      
        prod1.DD_Custom_ID__c = 'MKTPL-0000111';
        prod1.Price_Basis__c = CDdCpqBillingConstants.PRODUCT_PRICEBASIS_COMMISSION;
        update prod1;
        
        SBQQ__Quote__c quote1 = [SELECT Id, RecordTypeId, SBQQ__Status__c, SBQQ__Opportunity2__c, Weekly_Tablet_Fee__c, Weekly_Printer_Fee__c FROM SBQQ__Quote__c LIMIT 1];
        
        SBQQ__QuoteLine__c quoteLine1 = [SELECT Id, Record_Source__c, SBQQ__Product__c, SBQQ__Quote__c, Original_Commission__c, SBQQ__NetTotal__c FROM SBQQ__QuoteLine__c LIMIT 1];
        quoteLine1.Record_Source__c = 'Manual';
		quoteLine1.DD_Custom_ID__c = 'MKTPL-0000111';        
        update quoteLine1;
        
		Test.stopTest();
        SBQQ.TriggerControl.enable();
        SBQQ__Quote__c quote = [SELECT Id, RecordTypeId, SBQQ__Status__c, SBQQ__Opportunity2__c, Weekly_Tablet_Fee__c, Weekly_Printer_Fee__c FROM SBQQ__Quote__c LIMIT 1];
        System.assertEquals(quote.Weekly_Tablet_Fee__c, quoteLine1.SBQQ__NetTotal__c, 'The Weekly tablet fee has been set to the Net Total');
    }
    
    @isTest
    static void testUpdateQuoteFields114(){
        Product2 prod1 = [SELECT Id, DD_Custom_ID__c, Price_Basis__c FROM Product2 LIMIT 1];

        Test.startTest();
        SBQQ.TriggerControl.disable();
   
        prod1.DD_Custom_ID__c = 'MKTPL-0000114';
        prod1.Price_Basis__c = CDdCpqBillingConstants.PRODUCT_PRICEBASIS_COMMISSION;
        update prod1;
        
        SBQQ__Quote__c quote1 = [SELECT Id, RecordTypeId, SBQQ__Status__c, SBQQ__Opportunity2__c, Weekly_Tablet_Fee__c, Weekly_Printer_Fee__c FROM SBQQ__Quote__c LIMIT 1];
        
        SBQQ__QuoteLine__c quoteLine1 = [SELECT Id, Record_Source__c, SBQQ__Product__c, SBQQ__Quote__c, Original_Commission__c, SBQQ__NetTotal__c FROM SBQQ__QuoteLine__c LIMIT 1];
        quoteLine1.Record_Source__c = 'Manual';
        quoteLine1.DD_Custom_ID__c = 'MKTPL-0000114';
        update quoteLine1;

		Test.stopTest();
        SBQQ.TriggerControl.enable();

		SBQQ__Quote__c quote = [SELECT Id, RecordTypeId, SBQQ__Status__c, SBQQ__Opportunity2__c, Weekly_Tablet_Fee__c, Weekly_Printer_Fee__c FROM SBQQ__Quote__c LIMIT 1];
        System.assertEquals(quote.Weekly_Printer_Fee__c, quoteLine1.SBQQ__NetTotal__c, 'The Weekly printer fee has been set to the Net Total');
    }
    
    @isTest
    static void testUpdateQuoteFields134(){
        Product2 prod1 = [SELECT Id, DD_Custom_ID__c, Price_Basis__c FROM Product2 LIMIT 1];
        Test.startTest();
        SBQQ.TriggerControl.disable();
        
      
        prod1.DD_Custom_ID__c = 'MKTPL-0000134';
        prod1.Price_Basis__c = CDdCpqBillingConstants.PRODUCT_PRICEBASIS_COMMISSION;
        update prod1;
        
        SBQQ__Quote__c quote1 = [SELECT Id, RecordTypeId, SBQQ__Status__c, SBQQ__Opportunity2__c, Weekly_Tablet_Fee__c, Weekly_Printer_Fee__c, Service_Fee__c FROM SBQQ__Quote__c LIMIT 1];
        
        SBQQ__QuoteLine__c quoteLine1 = [SELECT Id, Record_Source__c, SBQQ__Product__c, SBQQ__Quote__c, Original_Commission__c, Final_Commission__c FROM SBQQ__QuoteLine__c LIMIT 1];
        quoteLine1.Record_Source__c = 'Manual';
        quoteLine1.DD_Custom_ID__c = 'MKTPL-0000134';
        quoteLine1.Final_Commission__c = 0.45;
        update quoteLine1;
		Test.stopTest();
        SBQQ.TriggerControl.enable();
        SBQQ__Quote__c quote = [SELECT Id, RecordTypeId, SBQQ__Status__c, SBQQ__Opportunity2__c, Weekly_Tablet_Fee__c, Service_Fee__c FROM SBQQ__Quote__c LIMIT 1];
        System.assertEquals(quote.Service_Fee__c, quoteLine1.Final_Commission__c, 'The Service fee has been set to the Final Commission');
    }
    
    @isTest
    static void testUpdateQuoteFields119(){
        Product2 prod1 = [SELECT Id, DD_Custom_ID__c, Price_Basis__c FROM Product2 LIMIT 1];
        Test.startTest();
        SBQQ.TriggerControl.disable();
        
      
        prod1.DD_Custom_ID__c = 'MKTPL-0000119';
        prod1.Price_Basis__c = CDdCpqBillingConstants.PRODUCT_PRICEBASIS_COMMISSION;
        update prod1;
        
        SBQQ__Quote__c quote1 = [SELECT Id, RecordTypeId, SBQQ__Status__c, SBQQ__Opportunity2__c, Weekly_Tablet_Fee__c, Weekly_Printer_Fee__c FROM SBQQ__Quote__c LIMIT 1];
        
        SBQQ__QuoteLine__c quoteLine1 = [SELECT Id, Record_Source__c, SBQQ__Product__c, SBQQ__Quote__c, Original_Commission__c, CPQ_Pricing_Tier__c FROM SBQQ__QuoteLine__c LIMIT 1];
        quoteLine1.Record_Source__c = 'Manual';
        quoteLine1.DD_Custom_ID__c = 'MKTPL-0000119';
        update quoteLine1;
		Test.stopTest();
        SBQQ.TriggerControl.enable();
        SBQQ__Quote__c quote = [SELECT Id, RecordTypeId, SBQQ__Status__c, SBQQ__Opportunity2__c, Pricing_Tier__c, Service_Fee__c FROM SBQQ__Quote__c LIMIT 1];
        System.assertEquals(quote.Pricing_Tier__c, quoteLine1.CPQ_Pricing_Tier__c, 'The Pricing tier has been set to the CPQ Pricing Tier');
    }
}