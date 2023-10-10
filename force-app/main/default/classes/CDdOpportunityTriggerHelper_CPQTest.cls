@isTest
public with sharing class CDdOpportunityTriggerHelper_CPQTest {
    
    @testSetup
    static void setup(){
        Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
        validation.Bypass_Opportunity_Validations__c = true; 
        insert validation;      
        
        Vertical_Category_Trigger_Setting__c verticalCatFeatureFlags = new Vertical_Category_Trigger_Setting__c(All_Validation_Is_Disabled__c = true);
        insert verticalCatFeatureFlags;

        Test.startTest();
        List<Account> accounts = TDdAccountFactory.createAccounts('Test Acount', 1);
        insert accounts;

        CDdContactTriggerHelper.insertCampaign();
        Contact testContact = TDdCPQTestDataFactory.createContact(false);
        testContact.Email = 'test@test.com';
        insert testContact;

        Product2 product = TDdCPQTestDataFactory.createProduct(true);
        Pricebook2 pricebook2 = new Pricebook2();
        pricebook2.Id = Test.getStandardPricebookId();
        pricebook2.IsActive = true;
        update pricebook2;
        PricebookEntry pbe = TDdCPQTestDataFactory.createPriceBookEntry(product, pricebook2, 'USD', true);
        
        String testOppName = 'TestDDOpportunity1';
        Opportunity testOpp = TDdCPQTestDataFactory.createOpportunityByDevRT('TestCPQOpp', accounts[0].Id, null, 'Closed Won', 'ML_Inside_Sales', false);
        insert testOpp;
        Test.stopTest();
        
        SBQQ__Quote__c quote = TDdCPQTestDataFactory.createQuote(testOpp, accounts[0], null, false);
        quote.SBQQ__Status__c = 'Contract Signed';
        quote.ApprovalStatus__c = 'Approved';
        insert quote; 

        SBQQ__QuoteLine__c quoteLine = TDdCPQTestDataFactory.createQuoteLine(product, quote, true);

        Order order = TDdCPQTestDataFactory.createOrder(accounts[0], testOpp, quote, true);
        OrderItem oi = TDdCPQTestDataFactory.createOrderItem(order, quoteLine,  pbe.Id, true);
        order.EndDate = null;
        update order;
    }
    private static Opportunity getOpportunity(){
        return [
            SELECT 
                Id,
                AccountId,
                Name,
                StageName,
                CurrencyIsoCode,
                Legal_Entity__c,
                Activation_Date__c,
                SBQQ__PrimaryQuote__c
            FROM Opportunity LIMIT 1];
    }

    private static Opportunity getOpportunityByName(String oppName){
        return [
            SELECT Id, CurrencyIsoCode, Legal_Entity__c, Name
            FROM Opportunity WHERE Name = :oppName LIMIT 1];
    }

    private static SBQQ__Quote__c getQuote(){
        return [SELECT Id,Custom_Partnership_Type__c,SBQQ__Opportunity2__c FROM SBQQ__Quote__c LIMIT 1];
    }

    private static Account getAccount(){
        return [SELECT Id,Custom_Partnership_Status__c,Primary_Merchant_Category__c FROM Account LIMIT 1];
    }

    private static Contact getContact(){
        return [SELECT Id, Email FROM Contact LIMIT 1];
    }

    @isTest
    private static void insertMarketplaceOpportunity_mockAccountWithUSLegalEntity_expectLegalEntityUS_expectCurrentCodeUSD(){
        Account acct1 = [SELECT Id, Primary_Merchant_Category__c FROM Account LIMIT 1];
        update acct1;
  
        Test.startTest();
        Opportunity testOpp = TDdCPQTestDataFactory.createOpportunityByDevRT('TestCPQOpp1', acct1.Id, null, 'Meeting Ran / Negotiated', 'ML_Inside_Sales', false);
        testOpp.Legal_Entity__c = '';
        insert testOpp;

        SBQQ__Quote__c quote = TDdCPQTestDataFactory.createQuote(testOpp, acct1, null, true);
        Test.stopTest();

        Opportunity oppCheck = [SELECT Id, CurrencyIsoCode, Legal_Entity__c, Name FROM Opportunity WHERE Name = 'TestCPQOpp1' LIMIT 1];
        System.assertEquals('US', oppCheck.Legal_Entity__c, 'The Legal entity on the opportunity should be set to US');
        System.assertEquals('USD', oppCheck.CurrencyIsoCode, 'The Currency on the opportunity should be set to USD');
    }

    @isTest
    static void insertMarketplaceOpportunity_mockAccountWithNoMatchingLegalEntity_expectLegalEntityUSGC(){
        Account acct1 = [SELECT Id, Primary_Merchant_Category__c FROM Account LIMIT 1];
        //Merchant category can be something other than the three values for US, but we still want US - G&C as the LE.
        acct1.Merchant_Categories__c = 'Flowers';
        acct1.Primary_Merchant_Category__c = 'Flowers';
        update acct1;       
        Test.startTest();
        Opportunity testOpp = TDdCPQTestDataFactory.createOpportunityByDevRT('TestCPQOpp1', acct1.Id, null, 'Meeting Ran / Negotiated', 'ML_Inside_Sales', false);
        testOpp.Legal_Entity__c = '';
        insert testOpp;
        SBQQ__Quote__c quote = TDdCPQTestDataFactory.createQuote(testOpp, acct1, null, true);
        Test.stopTest();
        Opportunity oppCheck = [SELECT Id, CurrencyIsoCode, Legal_Entity__c, Name FROM Opportunity WHERE Name = 'TestCPQOpp1' LIMIT 1];
        System.assertEquals('US - G&C', oppCheck.Legal_Entity__c, 'The Legal entity on the opportunity should be set to US - G&C');
        System.assertEquals('USD', oppCheck.CurrencyIsoCode, 'The Currency on the opportunity should be set to USD');
    }

    @isTest
    static void testPopulateLegalEntityUS_NoMerchant(){
        Account acct1 = [SELECT Id, Primary_Merchant_Category__c FROM Account LIMIT 1];      
        Test.startTest();
        Opportunity testOpp = TDdCPQTestDataFactory.createOpportunityByDevRT('TestCPQOpp1', acct1.Id, null, 'Meeting Ran / Negotiated', 'ML_Inside_Sales', false);
        testOpp.Legal_Entity__c = '';
        insert testOpp;
        SBQQ__Quote__c quote = TDdCPQTestDataFactory.createQuote(testOpp, acct1, null, true);
        Test.stopTest();
        Opportunity oppCheck = [SELECT Id, CurrencyIsoCode, Legal_Entity__c, Name FROM Opportunity WHERE Name = 'TestCPQOpp1' LIMIT 1];
        System.assertEquals('US', oppCheck.Legal_Entity__c, 'The Legal entity on the opportunity should be set to US');
        System.assertEquals('USD', oppCheck.CurrencyIsoCode, 'The Currency on the opportunity should be set to USD');
    }

    @isTest
    private static void insertMarketplaceOpportunity_mockAccountWithCanadaBilling_expectLegalEntityCAD_expectCurrencyCAD(){
        List<Account> lstacct = createAccountsWithDynamicAddress('Test',1,'Marketplace','Canada','CA','AB', '+81 9-9999-9999', '91767');       
        insert lstacct;
        Account acct1  = lstacct[0];

        Test.startTest();
        Opportunity testOpp = TDdCPQTestDataFactory.createOpportunityByDevRT('TestCPQOpp1', acct1.Id, null, 'Meeting Ran / Negotiated', 'ML_Inside_Sales', false);
        insert testOpp;
        SBQQ__Quote__c quote = TDdCPQTestDataFactory.createQuote(testOpp, acct1, null, true);
        Test.stopTest();
        Opportunity oppCheck = [SELECT Id, CurrencyIsoCode, Legal_Entity__c, Name FROM Opportunity WHERE Name = 'TestCPQOpp1' LIMIT 1];
        System.assertEquals('CAD', oppCheck.Legal_Entity__c, 'The Legal entity on the opportunity should be set to CAD');
        System.assertEquals('CAD', oppCheck.CurrencyIsoCode, 'The Currency on the opportunity should be set to CAD');
    }

    @isTest
    private static void insertMarketplaceOpportunity_mockAccountWithAustraliaBilling_expectLegalEntityAUS_expectCurrencyAUD(){        List<Account> lstacct = createAccountsWithDynamicAddress('Test',1,'Marketplace','Australia','AU','Victoria', '+61 999 999 999','3005');
        insert lstacct; 
        Account acct1  = lstacct[0];
        Test.startTest();
        Opportunity testOpp = TDdCPQTestDataFactory.createOpportunityByDevRT('TestCPQOpp1', acct1.Id, null, 'Meeting Ran / Negotiated', 'ML_Inside_Sales', false);
        insert testOpp;
        SBQQ__Quote__c quote = TDdCPQTestDataFactory.createQuote(testOpp, acct1, null, true);
        Test.stopTest();
        Opportunity oppCheck = [SELECT Id, CurrencyIsoCode, Legal_Entity__c, Name, RecordTypeId, RecordType.Name FROM Opportunity WHERE Name = 'TestCPQOpp1' LIMIT 1];
        System.assertEquals('AUS', oppCheck.Legal_Entity__c, 'The Legal entity on the opportunity should be set to AUS');
        System.assertEquals('AUD', oppCheck.CurrencyIsoCode, 'The Currency on the opportunity should be set to AUD');
    }

    @isTest
    private static void insertMarketplaceOpportunity_mockAccountWithJapanBilling_expectLegalEntityJPN_expectCurrencyJPY(){        List<Account> lstacct = createAccountsWithDynamicAddress('Test',1,'Marketplace','Japan','JP','Miyagi', '+81 9-9999-9999','981-1106');
        insert lstacct; 
        Account acct1  = lstacct[0];
        Test.startTest();
        Opportunity testOpp = TDdCPQTestDataFactory.createOpportunityByDevRT('TestCPQOpp1', acct1.Id, null, 'Meeting Ran / Negotiated', 'ML_Inside_Sales', false);
        insert testOpp;
        SBQQ__Quote__c quote = TDdCPQTestDataFactory.createQuote(testOpp, acct1, null, true); 
        Test.stopTest();
        Opportunity oppCheck = [SELECT Id, CurrencyIsoCode, Legal_Entity__c, Name FROM Opportunity WHERE Name = 'TestCPQOpp1' LIMIT 1];
        System.assertEquals('JPN', oppCheck.Legal_Entity__c, 'The Legal entity on the opportunity should be set to JPN');
        System.assertEquals('JPY', oppCheck.CurrencyIsoCode, 'The Currency on the opportunity should be set to JPY');
    }

    @isTest
    private static void insertMarketplaceOpportunity_mockAccountWithGermanBilling_expectLegalEntityDEU_expectCurrencyEUR(){        List<Account> lstacct = createAccountsWithDynamicAddress('DEU Test',1,'Marketplace','Germany','DE','Bavaria', '+49-999-989-999','70176');
        insert lstacct;
        Account acct1  = lstacct[0];
        Test.startTest();
        Opportunity testOpp = TDdCPQTestDataFactory.createOpportunityByDevRT('TestCPQOpp1', acct1.Id, null, 'Meeting Ran / Negotiated', 'ML_Inside_Sales', false);
        insert testOpp;
        SBQQ__Quote__c quote = TDdCPQTestDataFactory.createQuote(testOpp, acct1, null,true);
        Test.stopTest();
        Opportunity oppCheck = [SELECT Id, CurrencyIsoCode, Legal_Entity__c, Name FROM Opportunity WHERE Name = 'TestCPQOpp1' LIMIT 1];
        System.assertEquals('DEU', oppCheck.Legal_Entity__c, 'The Legal entity on the opportunity should be set to DEU');
        System.assertEquals('EUR', oppCheck.CurrencyIsoCode, 'The Currency on the opportunity should be set to EUR');
    }

    @isTest
    static void testUpdateOrderStartDate(){
        Opportunity opp = [SELECT Id, AccountId, SBQQ__PrimaryQuote__c, Activation_Date__c FROM Opportunity LIMIT 1];

        Test.startTest();
        opp.Activation_Date__c = Date.Today().addDays(30);
        opp.Delivery_Inflation_Opp__c = 'Yes & Not POS Blocked'; // bypassing CW_Must_Have_Signed_Contract_on_Quote error
        update opp;
        Test.stopTest();

        Order orderAfter = [SELECT Id, EffectiveDate FROM Order LIMIT 1];
        System.assertEquals(Date.Today().addDays(30), orderAfter.EffectiveDate, 'The Order effective date did not get updated from activation');
    }
    
    public static List<Account> createAccountsWithDynamicAddress(String testAccountName, Integer numberOfAccounts, String recordType,String billingCountry,String billingCountryCode,String state, String phone, String billingPostalCode) {
        List<Account> accountsToBeCreated = new List<Account>();
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
        
        for (Integer i = 0; i < numberOfAccounts; i++){
            Account acct = new Account(BillingStreet = i + ' Mulberry Ln',
                                       BillingCity = 'South San Francisco',
                                       BillingState = state,
                                       BillingCountryCode = billingCountryCode,
                                       BillingCountry = billingCountry,
                                       Phone = phone,                                      
                                       BillingPostalCode = billingPostalCode,
                                       Bank_Account_Number_Encrypted__c = '123456789',
                                       Bank_Routing_Number_Encrypted__c = '123456789',
                                       Legal_Business_Name__c = 'TestAccount',
                                       RecordTypeId = accRecordTypeId);
            if (recordType.equals('Consumer or Dasher')) {
                acct.LastName = testAccountName + ' ' + i;
            } else {
                acct.Name = testAccountName + ' '  + i;
            }
            if(billingCountry == 'Australia')
            {
                acct.Mx_Tax_Id_VAT__c = '123456789';
            }
            else{
                acct.EIN_Encrypted__c = '123456789';
            }
            accountsToBeCreated.add(acct);
        } 
        return accountsToBeCreated;
    }

    @isTest
    static void testValidateContractSignedOnClosedWon(){
        Opportunity opp = [SELECT Id, AccountId, SBQQ__PrimaryQuote__c, Activation_Date__c FROM Opportunity LIMIT 1];
        opp.StageName = 'Closed Won';
        try{
             update opp;
        } catch(Exception e){
           System.assertEquals(true, e.getMessage().contains(Label.CW_Must_Have_Signed_Contract_on_Quote), 'The error message does not indicate the quote should be Contract Signed');
        }      
    }
    @isTest
    public static void testRecall() {
        PriceBook2 pricebook = new Pricebook2(Id = Test.getStandardPricebookId(), isActive = true);
        update pricebook;
        List<Account> accounts = [Select id from Account Limit 1]; 
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        Opportunity testOpp = TDdCPQTestDataFactory.createOpportunityByDevRT('TestCPQOpp', accounts[0].Id, null, 'Negotiating', 'Corporate', false);
        testOpp.sbaa__ApprovalStatus__c = 'Pending';
        insert testOpp;
        SBQQ__Quote__c quote = new SBQQ__Quote__c(SBQQ__Account__c = accounts[0].Id, SBQQ__Opportunity2__c = testOpp.Id);
        insert quote;
        SBQQ__QuoteLine__c quoteLine1 = TDdCPQTestDataFactory.createQuoteLine(product, quote, true);
        Test.startTest();
        testOpp.sbaa__ApprovalStatus__c = 'Recalled';
        update testOpp;
        Test.stopTest();
        testOpp = [SELECT StageName FROM Opportunity WHERE Id = :testOpp.Id LIMIT 1];
        System.assertEquals('Negotiating', testOpp.StageName);
        
    }
    @isTest
    public static void testApproved() {
        PriceBook2 pricebook = new Pricebook2(Id = Test.getStandardPricebookId(), isActive = true);
        update pricebook;
        List<Account> accounts = [Select id from Account Limit 1]; 
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        Opportunity testOpp = TDdCPQTestDataFactory.createOpportunityByDevRT('TestCPQOpp', accounts[0].Id, null, 'Negotiating', 'Corporate', false);
        testOpp.sbaa__ApprovalStatus__c = 'Pending';
        insert testOpp;
        SBQQ__Quote__c quote = new SBQQ__Quote__c(SBQQ__Account__c = accounts[0].Id, SBQQ__Opportunity2__c = testOpp.Id);
        insert quote;
        SBQQ__QuoteLine__c quoteLine1 = TDdCPQTestDataFactory.createQuoteLine(product, quote, true);
        Test.startTest();
        testOpp.sbaa__ApprovalStatus__c = 'Approved';
        update testOpp;
        Test.stopTest();
        testOpp = [SELECT StageName FROM Opportunity WHERE Id = :testOpp.Id LIMIT 1];
        System.assertEquals('Ready for Signature', testOpp.StageName);
        
    }

    @isTest
    private static void updateAccountCustomPartnershipStatus_opportunityNotMovedToClosedWon_expectNoUpdateToAccount(){
        Account testAccount = getAccount();
        Opportunity testOpportunity = TDdCPQTestDataFactory.createOpportunityByDevRT(
            'postSaleOpp123',
            testAccount.Id,
            null,
            'Negotiating',
            'Post_Sale',
            true
        );

        // Validation requires a custom partnership status on the account before we can add a type to the quote
        testAccount.Custom_Partnership_Status__c = CDdOpporunityTriggerHelper_CPQ.CUSTOM_PARTNERSHIP_EXCLUSIVE;
        update testAccount;

        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__Opportunity2__c = testOpportunity.Id,
            Custom_Partnership_Type__c = CDdOpporunityTriggerHelper_CPQ.CUSTOM_PARTNERSHIP_PREFERRED
        );
        insert testQuote;

        List<Opportunity> latestOpportunities = new List<Opportunity> {
            testOpportunity.clone(true, false, false, false)
        };
        latestOpportunities[0].StageName = 'Contacted';

        Map<Id,Opportunity> oldOpportunitiesById = new Map<Id,Opportunity>(
            (new List<Opportunity>{ testOpportunity })
        );

        Test.startTest();
        CDdOpporunityTriggerHelper_CPQ.updateAccountCustomPartnershipStatus(latestOpportunities, oldOpportunitiesById);
        Test.stopTest();

        Account result = getAccount();
        System.assertEquals(
            CDdOpporunityTriggerHelper_CPQ.CUSTOM_PARTNERSHIP_EXCLUSIVE,
            result.Custom_Partnership_Status__c,
            'Expected the account to remain exclusive.'
        );
    }

    @isTest
    private static void updateAccountCustomPartnershipStatus_opportunityAlreadyMovedToClosedWon_expectNoUpdateToAccount(){
        Account testAccount = getAccount();
        Opportunity testOpportunity = TDdCPQTestDataFactory.createOpportunityByDevRT(
            'postSaleOpp123',
            testAccount.Id,
            null,
            CDdOpportunityConstants.OPPORTUNITY_STAGE_CLOSED_WON,
            'Post_Sale',
            true
        );

        // Validation requires a custom partnership status on the account before we can add a type to the quote
        testAccount.Custom_Partnership_Status__c = CDdOpporunityTriggerHelper_CPQ.CUSTOM_PARTNERSHIP_PREFERRED;
        update testAccount;

        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__Opportunity2__c = testOpportunity.Id,
            Custom_Partnership_Type__c = CDdOpporunityTriggerHelper_CPQ.CUSTOM_PARTNERSHIP_EXCLUSIVE
        );
        insert testQuote;

        List<Opportunity> latestOpportunities = new List<Opportunity> {
            testOpportunity.clone(true, false, false, false)
        };
        latestOpportunities[0].StageName = CDdOpportunityConstants.OPPORTUNITY_STAGE_CLOSED_WON;

        Map<Id,Opportunity> oldOpportunitiesById = new Map<Id,Opportunity>(
            (new List<Opportunity>{ testOpportunity })
        );

        Test.startTest();
        CDdOpporunityTriggerHelper_CPQ.updateAccountCustomPartnershipStatus(latestOpportunities, oldOpportunitiesById);
        Test.stopTest();

        Account result = getAccount();
        System.assertEquals(
            CDdOpporunityTriggerHelper_CPQ.CUSTOM_PARTNERSHIP_PREFERRED,
            result.Custom_Partnership_Status__c,
            'Expected the account to remain a preferred partnership.'
        );
    }

    @isTest
    private static void updateAccountCustomPartnershipStatus_opportunityMovedToClosedWon_quoteHasWrongCustomPartnership_expectNoUpdateToAccount(){
        Account testAccount = getAccount();
        Opportunity testOpportunity = TDdCPQTestDataFactory.createOpportunityByDevRT(
            'postSaleOpp123',
            testAccount.Id,
            null,
            'Negotiating',
            'Post_Sale',
            true
        );

        // Validation requires a custom partnership status on the account before we can add a type to the quote
        testAccount.Custom_Partnership_Status__c = CDdOpporunityTriggerHelper_CPQ.CUSTOM_PARTNERSHIP_PREFERRED;
        update testAccount;

        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__Opportunity2__c = testOpportunity.Id,
            Custom_Partnership_Type__c = CDdOpporunityTriggerHelper_CPQ.CUSTOM_PARTNERSHIP_EXCLUSIVE
        );
        insert testQuote;

        List<Opportunity> latestOpportunities = new List<Opportunity> {
            testOpportunity.clone(true, false, false, false)
        };
        latestOpportunities[0].StageName = CDdOpportunityConstants.OPPORTUNITY_STAGE_CLOSED_WON;

        Map<Id,Opportunity> oldOpportunitiesById = new Map<Id,Opportunity>(
            (new List<Opportunity>{ testOpportunity })
        );

        Test.startTest();
        CDdOpporunityTriggerHelper_CPQ.updateAccountCustomPartnershipStatus(latestOpportunities, oldOpportunitiesById);
        Test.stopTest();

        Account result = getAccount();
        System.assertEquals(
            CDdOpporunityTriggerHelper_CPQ.CUSTOM_PARTNERSHIP_EXCLUSIVE,
            result.Custom_Partnership_Status__c,
            'Expected the account to be updated with a preferred partnership.'
        );
    }

    @isTest
    private static void updateAccountCustomPartnershipStatus_opportunityMovedToClosedWon_noQuotes_expectNoUpdateToAccount(){
        Account testAccount = getAccount();
        Opportunity testOpportunity = TDdCPQTestDataFactory.createOpportunityByDevRT(
            'postSaleOpp123',
            testAccount.Id,
            null,
            'Negotiating',
            'Post_Sale',
            true
        );

        // Validation requires a custom partnership status on the account before we can add a type to the quote
        testAccount.Custom_Partnership_Status__c = CDdOpporunityTriggerHelper_CPQ.CUSTOM_PARTNERSHIP_PREFERRED;
        update testAccount;

        List<Opportunity> latestOpportunities = new List<Opportunity> {
            testOpportunity.clone(true, false, false, false)
        };
        latestOpportunities[0].StageName = CDdOpportunityConstants.OPPORTUNITY_STAGE_CLOSED_WON;

        Map<Id,Opportunity> oldOpportunitiesById = new Map<Id,Opportunity>(
            (new List<Opportunity>{ testOpportunity })
        );

        Test.startTest();
        CDdOpporunityTriggerHelper_CPQ.updateAccountCustomPartnershipStatus(latestOpportunities, oldOpportunitiesById);
        Test.stopTest();

        Account result = getAccount();
        System.assertEquals(
            CDdOpporunityTriggerHelper_CPQ.CUSTOM_PARTNERSHIP_PREFERRED,
            result.Custom_Partnership_Status__c,
            'Expected the account to remain preferred.'
        );
    }

    @isTest
    private static void updateAccountCustomPartnershipStatus_opportunityMovedToClosedWon_validQuote_exclusive_expectAccountUpdated(){    
        Account testAccount = getAccount();
        Opportunity testOpportunity = TDdCPQTestDataFactory.createOpportunityByDevRT(
            'postSaleOpp123',
            testAccount.Id,
            null,
            'Negotiating',
            'Post_Sale',
            true
        );

        // Validation requires a custom partnership status on the account before we can add a type to the quote
        testAccount.Custom_Partnership_Status__c = CDdOpporunityTriggerHelper_CPQ.CUSTOM_PARTNERSHIP_PREFERRED;
        update testAccount;

        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__Opportunity2__c = testOpportunity.Id,
            Custom_Partnership_Type__c = CDdOpporunityTriggerHelper_CPQ.CUSTOM_PARTNERSHIP_EXCLUSIVE
        );
        insert testQuote;

        List<Opportunity> latestOpportunities = new List<Opportunity> {
            testOpportunity.clone(true, false, false, false)
        };
        latestOpportunities[0].StageName = CDdOpportunityConstants.OPPORTUNITY_STAGE_CLOSED_WON;

        Map<Id,Opportunity> oldOpportunitiesById = new Map<Id,Opportunity>(
            (new List<Opportunity>{ testOpportunity })
        );

        Test.startTest();
        CDdOpporunityTriggerHelper_CPQ.updateAccountCustomPartnershipStatus(latestOpportunities, oldOpportunitiesById);
        Test.stopTest();

        Account result = getAccount();
        System.assertEquals(
            CDdOpporunityTriggerHelper_CPQ.CUSTOM_PARTNERSHIP_EXCLUSIVE,
            result.Custom_Partnership_Status__c,
            'Expected the account to be updated with a preferred partnership.'
        );
    }

    @isTest
    private static void updateAccountCustomPartnershipStatus_opportunityMovedToClosedWon_validQuote_preferred_expectAccountUpdated(){
        Account testAccount = getAccount();
        Opportunity testOpportunity = TDdCPQTestDataFactory.createOpportunityByDevRT(
            'postSaleOpp123',
            testAccount.Id,
            null,
            'Negotiating',
            'Post_Sale',
            true
        );

        // Validation requires a custom partnership status on the account before we can add a type to the quote
        testAccount.Custom_Partnership_Status__c = CDdOpporunityTriggerHelper_CPQ.CUSTOM_PARTNERSHIP_EXCLUSIVE;
        update testAccount;

        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__Opportunity2__c = testOpportunity.Id,
            Custom_Partnership_Type__c = CDdOpporunityTriggerHelper_CPQ.CUSTOM_PARTNERSHIP_PREFERRED
        );
        insert testQuote;

        List<Opportunity> latestOpportunities = new List<Opportunity> {
            testOpportunity.clone(true, false, false, false)
        };
        latestOpportunities[0].StageName = CDdOpportunityConstants.OPPORTUNITY_STAGE_CLOSED_WON;

        Map<Id,Opportunity> oldOpportunitiesById = new Map<Id,Opportunity>(
            (new List<Opportunity>{ testOpportunity })
        );

        Test.startTest();
        CDdOpporunityTriggerHelper_CPQ.updateAccountCustomPartnershipStatus(latestOpportunities, oldOpportunitiesById);
        Test.stopTest();

        Account result = getAccount();
        System.assertEquals(
            CDdOpporunityTriggerHelper_CPQ.CUSTOM_PARTNERSHIP_PREFERRED,
            result.Custom_Partnership_Status__c,
            'Expected the account to be updated with a preferred partnership.'
        );
    }
}