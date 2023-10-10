@isTest
public with sharing class CDdQuoteStatusCheckBatchTest {
    static final String STATUS_APPROVED = 'Approved';
    static final string STATUS_CONTRACT_SIGNED = 'Contract Signed';

    @testSetup
   static void setup(){
       Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
       validation.Bypass_Opportunity_Validations__c = true;
       validation.Bypass_Account_Validations__c = true;
       validation.Bypass_Quote_Validations__c = true;
       insert validation;

       Id userProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;

       User u = new User(
          ProfileId = userProfileId,
          LastName = 'Mulesoft Integration User',
          Email = 'puser0003@doordash.com',
          Username = 'puser0005@doordash.com',
          CompanyName = 'TEST',
          Title = 'TestTitle',
          Alias = 'alias658',
          TimeZoneSidKey = 'America/Los_Angeles',
          EmailEncodingKey = 'UTF-8',
          LanguageLocaleKey = 'en_US',
          LocaleSidKey = 'en_US'
        );

       List<Account> accounts = TDdAccountFactory.createAccounts('Test Acount', 2);
       insert accounts;

       Product2 product = TDdCPQTestDataFactory.createProduct(true);
       Pricebook2 pricebook2 = new Pricebook2();
       pricebook2.Id = Test.getStandardPricebookId();
       pricebook2.IsActive = true;
       update pricebook2;
       PricebookEntry pbe = TDdCPQTestDataFactory.createPriceBookEntry(product, pricebook2, 'USD', true);
       Opportunity testOpp = TDdCPQTestDataFactory.createOpportunityByDevRT(
           'TestCPQOpp',
           accounts[0].Id,
           null,
           'Meeting Ran / Negotiated',
           'ML_Inside_Sales',
           false
        );
        testOpp.Integration_Auto_Close__c = true;
       insert testOpp;

       Test.StartTest();
        System.runAs(u) {
            SBQQ__Quote__c quote = TDdCPQTestDataFactory.createQuote(testOpp, accounts[0], null, false);
            quote.SBQQ__Status__c = STATUS_APPROVED;
            quote.ApprovalStatus__c = STATUS_APPROVED;
            quote.SBQQ__Primary__c = true;
            quote.Integration_Trial__c = false;
            insert quote;

            SBQQ__QuoteLine__c quoteLine = TDdCPQTestDataFactory.createQuoteLine(product, quote, true);
        }
        Test.StopTest();
    }

    @isTest
    static void testCallBatchMethod(){
        CDdQuoteStatusCheckBatch bat = new CDdQuoteStatusCheckBatch();
        Database.executeBatch(bat);
        SBQQ__Quote__c quote = [SELECT Id,Integration_Trial__c FROM SBQQ__Quote__c WHERE SBQQ__Status__c =: STATUS_APPROVED];
        System.assertEquals(quote.Integration_Trial__c, false, 'Batch failed.');
        System.schedule('CDdQuoteStatusCheckBatch '+System.now(), '0 00 05 ? * 2', new CDdQuoteStatusCheckBatch());
    }
}