@isTest
public class CDdQuoteTriggerHelperTest {
    private static final String QUOTE_QUERY =
        'SELECT Id,SBQQ__Status__c,{0} FROM SBQQ__Quote__c';
    private static final String STATUS_IN_REVIEW = 'In Review';
    private static final String APPROVAL_STATUS_PENDING = 'Pending';

   @testSetup
   static void setup(){
       Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
       validation.Bypass_Opportunity_Validations__c = true;
       validation.Bypass_Account_Validations__c = true;
       validation.Bypass_Quote_Validations__c = true;
       insert validation;

       List<Account> accounts = TDdAccountFactory.createAccounts('Test Acount', 2);
       insert accounts;

       CDdContactTriggerHelper.insertCampaign();
       TDdCPQTestDataFactory.createContact(true);

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
       insert testOpp;

       Test.StartTest();

       pactsafe1__PactSafeRequest__c testRequest = new pactsafe1__PactSafeRequest__c();
       insert testRequest;

       SBQQ__Quote__c quote = TDdCPQTestDataFactory.createQuote(testOpp, accounts[0], null, false); 
       quote.put(PSExtensionMainSettings.getRequestFieldName, testRequest.Id);
       insert quote;
     
       SBQQ__QuoteLine__c quoteLine = TDdCPQTestDataFactory.createQuoteLine(product, quote, true);
       Test.StopTest();
   }

    private static List<SBQQ__Quote__c> getQuotes(){
        // BZAP-13135: in order to successfully make the API request in processVoidedContracts() we need to
        //  query the configured relationship field on the quote.
        String quoteQuery = String.format(QUOTE_QUERY, new List<String>{PSExtensionMainSettings.getRequestFieldName});

        return Database.query(quoteQuery);
    }

    private static Opportunity getOpportunity(){
        return [SELECT Id,Number_of_Quotes__c, CloseDate FROM Opportunity LIMIT 1];
    }

    private static Contact getContact(){
        return [SELECT Id FROM Contact LIMIT 1];
    }

    private static Account getAccount(){
        return [SELECT Id FROM Account LIMIT 1];
    }

    private static List<Account> getAccounts(){
        return [SELECT Id FROM Account];
    }

    private static Opportunity requeryOpportunity(Id opportunityId){
        return [SELECT Id,Number_of_Quotes__c FROM Opportunity WHERE Id = :opportunityId];
    }

   @isTest
   static void testGenerateOrder(){
       SBQQ__Quote__c quote = [SELECT Id, SBQQ__Status__c, PactSafe_Contract_Type__c FROM SBQQ__Quote__c LIMIT 1];
      
       SBQQ.TriggerControl.disable();
       quote.SBQQ__Status__c = 'Contract Signed';
       update quote;
      
       SBQQ.TriggerControl.enable();
       SBQQ__Quote__c quoteAfter = [SELECT SBQQ__Ordered__c FROM SBQQ__Quote__c LIMIT 1];
       System.assertEquals(true, quoteAfter.SBQQ__Ordered__c);
   }

   @isTest
   static void processContractSignature_mockNoOpportunity_expectNotOrdered(){
    Opportunity testOpportunity = getOpportunity();
    testOpportunity.SBQQ__PrimaryQuote__c = null;
    update testOpportunity;

    SBQQ__Quote__c quote = [SELECT Id, SBQQ__Status__c, PactSafe_Contract_Type__c FROM SBQQ__Quote__c LIMIT 1];
    quote.SBQQ__Status__c = 'Contract Signed';
    quote.SBQQ__Opportunity2__c = null;
    quote.Migrated_Record__c = false;

    SBQQ.TriggerControl.disable();
    update quote;
    SBQQ.TriggerControl.enable();

    SBQQ__Quote__c quoteAfter = [SELECT SBQQ__Ordered__c FROM SBQQ__Quote__c LIMIT 1];
    System.assertEquals(false, quoteAfter.SBQQ__Ordered__c,
        'Expected a non-migrated quote with no related Opportunity to NOT generate an order.');
   }

   @isTest
   static void processContractSignature_mockMigratedQuote_mockNoOpportunity_expectOrdered(){
    Opportunity testOpportunity = getOpportunity();
    testOpportunity.SBQQ__PrimaryQuote__c = null;
    update testOpportunity;

    SBQQ__Quote__c quote = [SELECT Id, SBQQ__Status__c, PactSafe_Contract_Type__c FROM SBQQ__Quote__c LIMIT 1];
    quote.SBQQ__Status__c = 'Contract Signed';
    quote.SBQQ__Opportunity2__c = null;
    quote.Migrated_Record__c = true;

    SBQQ.TriggerControl.disable();
    update quote;
    SBQQ.TriggerControl.enable();

    SBQQ__Quote__c quoteAfter = [SELECT SBQQ__Ordered__c FROM SBQQ__Quote__c LIMIT 1];
    System.assertEquals(true, quoteAfter.SBQQ__Ordered__c,
        'Expected a migrated quote -- even with no related Opportunity -- to generate an order.');
   }
 
   @isTest
   static void testUpdateQuoteRecordTypeFromStatus(){
       Test.startTest();
       SBQQ.TriggerControl.disable();
       SBQQ__Quote__c quote = [SELECT Id, RecordTypeId, SBQQ__Status__c, ApprovalStatus__c FROM SBQQ__Quote__c LIMIT 1];
       System.assertEquals(quote.RecordTypeId, CDdSchemaUtils.QUOTE_RT.draftId(), 'An inserted quote should have the draft record type');
       System.assertEquals(quote.SBQQ__Status__c, 'Draft', 'An Inserted quote should be in draft status');
       quote.ApprovalStatus__c = 'Pending';
       update quote;
 
       SBQQ__Quote__c quote2 = [SELECT Id, RecordTypeId, SBQQ__Status__c, ApprovalStatus__c FROM SBQQ__Quote__c LIMIT 1];
       System.assertEquals(quote2.RecordTypeId, CDdSchemaUtils.QUOTE_RT.inProgressId(), 'When approvals are pending the record type should be "In Progress"');
       System.assertEquals(quote2.SBQQ__Status__c, CDdCpqBillingConstants.QUOTE_STATUS_IN_REVIEW, 'When approvals are pending the quote status should be "In Review"');
       quote2.ApprovalStatus__c = CDdCpqBillingConstants.QUOTE_STATUS_APPROVED;
       update quote2;
 
       SBQQ__Quote__c quote3 = [SELECT Id, RecordTypeId, SBQQ__Status__c, ApprovalStatus__c FROM SBQQ__Quote__c LIMIT 1];
       System.assertEquals(quote3.RecordTypeId, CDdSchemaUtils.QUOTE_RT.approvedId(), 'When approvals are approved the record type should be "Approved"');
       System.assertEquals(quote3.SBQQ__Status__c, CDdCpqBillingConstants.QUOTE_STATUS_APPROVED, 'When approvals are approved the quote status should be "Approved"');
       quote3.ApprovalStatus__c = 'Rejected';
       update quote3;
 
       SBQQ__Quote__c quote4 = [SELECT Id, RecordTypeId, SBQQ__Status__c, ApprovalStatus__c FROM SBQQ__Quote__c LIMIT 1];
       System.assertEquals(quote4.RecordTypeId, CDdSchemaUtils.QUOTE_RT.draftId(), 'When approvals are rejected the record type should be "Draft"');
       System.assertEquals(quote4.SBQQ__Status__c, 'Denied', 'When approvals are rejected the quote status should be "Denied"');
       quote4.ApprovalStatus__c = 'Recalled';
       update quote4;
 
       SBQQ__Quote__c quote5 = [SELECT Id, RecordTypeId, SBQQ__Status__c, ApprovalStatus__c FROM SBQQ__Quote__c LIMIT 1];
       System.assertEquals(quote5.RecordTypeId, CDdSchemaUtils.QUOTE_RT.draftId(), 'When approvals are recalled the record type should be "Draft"');
       System.assertEquals(quote5.SBQQ__Status__c, 'Draft', 'When approvals are recalled the quote status should be "Draft"');
       Test.stopTest();
       SBQQ.TriggerControl.enable();
   }
 
   @isTest
   static void testUpdateRelatedOpportunities124(){
       Account acct1 = [SELECT Id FROM Account LIMIT 1];
       SBQQ__QuoteLine__c quoteLine1 = [SELECT Id, Final_Commission__c, SBQQ__NetTotal__c, DD_Custom_ID__c FROM SBQQ__QuoteLine__c LIMIT 1];
       Opportunity opp1 = [SELECT
                               Id, Commission__c, DashPass_Flat_Fee__c, DashPass_Only_Commission__c,
                               In_App_Pickup_Commission__c, Referred_Delivery_Commission__c,
                               Referred_Pickup_Commission__c, RecordTypeId, CloseDate, StageName
                               FROM Opportunity
                               LIMIT 1];
       Test.startTest();
       SBQQ.TriggerControl.disable();
       SBQQ__Quote__c quote1 = [SELECT Id, RecordTypeId, SBQQ__Status__c, SBQQ__Opportunity2__c, ApprovalStatus__c, Opportunity_Record_Type__c FROM SBQQ__Quote__c LIMIT 1];  
    
       quoteLine1.DD_Custom_ID__c = 'MKTPL-0000124';  
       quoteLine1.Trial_Commission__c = 5.23;      
       update quoteLine1;
       quote1.Trial_Type__c = 'Promotional Period';
       quote1.SBQQ__Status__c = 'Contract Signed';
       update quote1;
       Test.stopTest();
       SBQQ.TriggerControl.enable();
       Opportunity opp2 = [SELECT
                               Id, Commission__c, DashPass_Flat_Fee__c, DashPass_Only_Commission__c,
                               In_App_Pickup_Commission__c, Referred_Delivery_Commission__c,
                               Referred_Pickup_Commission__c, RecordTypeId, CloseDate
                               FROM Opportunity
                               LIMIT 1];
       System.assertEquals(opp2.Commission__c, quoteline1.Final_Commission__c, 'The commission on the opportunity equals the final commission on the quote line');               
   }
 
   @isTest
   static void testUpdateRelatedOpportunities102(){
       Account acct1 = [SELECT Id FROM Account LIMIT 1];
       SBQQ__QuoteLine__c quoteLine1 = [SELECT Id, Final_Commission__c, SBQQ__NetTotal__c, DD_Custom_ID__c FROM SBQQ__QuoteLine__c LIMIT 1];
       Opportunity opp1 = [SELECT
                               Id, Commission__c, DashPass_Flat_Fee__c, DashPass_Only_Commission__c,
                               In_App_Pickup_Commission__c, Referred_Delivery_Commission__c,
                               Referred_Pickup_Commission__c, RecordTypeId, CloseDate, StageName
                               FROM Opportunity
                               LIMIT 1];
      
       SBQQ__Quote__c quote1 = [SELECT Id, RecordTypeId, SBQQ__Status__c, SBQQ__Opportunity2__c, ApprovalStatus__c, Opportunity_Record_Type__c FROM SBQQ__Quote__c LIMIT 1];
       Test.startTest();
       SBQQ.TriggerControl.disable();  
      
       quoteLine1.DD_Custom_ID__c = 'MKTPL-0000102';  
       quoteLine1.Trial_Commission__c = 5.23;
       update quoteLine1;
       quote1.SBQQ__Status__c = 'Contract Signed';
       update quote1;
       SBQQ.TriggerControl.enable();
       Test.stopTest();
       Opportunity opp2 = [SELECT
                               Id, Commission__c, DashPass_Flat_Fee__c, DashPass_Only_Commission__c,
                               In_App_Pickup_Commission__c, Referred_Delivery_Commission__c,
                               Referred_Pickup_Commission__c, RecordTypeId, CloseDate
                               FROM Opportunity
                               LIMIT 1];
       System.assertEquals(opp2.Commission__c, quoteline1.Final_Commission__c, 'The commission on the opportunity equals the final commission on the quote line');               
   }
  
   @isTest
   static void testUpdateRelatedOpportunities103(){
       Account acct1 = [SELECT Id FROM Account LIMIT 1];
       SBQQ__QuoteLine__c quoteLine1 = [SELECT Id, Final_Commission__c, SBQQ__NetTotal__c, DD_Custom_ID__c FROM SBQQ__QuoteLine__c LIMIT 1];
       Opportunity opp1 = [SELECT
                               Id, Commission__c, DashPass_Flat_Fee__c, DashPass_Only_Commission__c,
                               In_App_Pickup_Commission__c, Referred_Delivery_Commission__c,
                               Referred_Pickup_Commission__c, RecordTypeId, CloseDate, StageName
                               FROM Opportunity
                               LIMIT 1];
       Test.startTest();
       SBQQ.TriggerControl.disable();
       SBQQ__Quote__c quote1 = [SELECT Id, RecordTypeId, SBQQ__Status__c, SBQQ__Opportunity2__c, ApprovalStatus__c, Opportunity_Record_Type__c FROM SBQQ__Quote__c LIMIT 1];
      
       quoteLine1.DD_Custom_ID__c = 'MKTPL-0000103';       
       update quoteLine1;
    
       quote1.SBQQ__Status__c = 'Contract Signed';
       update quote1;
       Test.stopTest();
       SBQQ.TriggerControl.enable();
       Opportunity opp2 = [SELECT
                               Id, Commission__c, DashPass_Flat_Fee__c, DashPass_Only_Commission__c,
                               In_App_Pickup_Commission__c, Referred_Delivery_Commission__c,
                               Referred_Pickup_Commission__c, RecordTypeId, CloseDate
                               FROM Opportunity
                               LIMIT 1];
       System.assertEquals(opp2.Commission__c, quoteline1.Final_Commission__c, 'The commission on the opportunity equals the final commission on the quote line');               
   }
 
   @isTest
    static void testUpdateRelatedOpportunities111(){
        Product2 prod1 = [SELECT Id, DD_Custom_ID__c, Price_Basis__c FROM Product2 LIMIT 1];
    
        
        Account acct1 = [SELECT Id FROM Account LIMIT 1];
        SBQQ__QuoteLine__c quoteLine1 = [SELECT Id, Final_Commission__c, SBQQ__NetTotal__c, DD_Custom_ID__c FROM SBQQ__QuoteLine__c LIMIT 1];
        Opportunity opp1 = [SELECT 
                                Id, Commission__c, DashPass_Flat_Fee__c, DashPass_Only_Commission__c, 
                                In_App_Pickup_Commission__c, Referred_Delivery_Commission__c, 
                                Referred_Pickup_Commission__c, RecordTypeId, CloseDate, StageName,
                                RecordType.DeveloperName, Order_Protocol__c 
                                FROM Opportunity 
                                LIMIT 1];
        Test.startTest();
        SBQQ.TriggerControl.disable();

        prod1.DD_Custom_ID__c = 'MKTPL-0000111';
        prod1.Price_Basis__c = CDdCpqBillingConstants.PRODUCT_PRICEBASIS_COMMISSION;
        update prod1;

        SBQQ__Quote__c quote1 = [SELECT Id, RecordTypeId, SBQQ__Status__c, SBQQ__Opportunity2__c, Weekly_Tablet_Fee__c, Opportunity_Record_Type__c, CurrencyIsoCode FROM SBQQ__Quote__c LIMIT 1];    
        
        quoteLine1.DD_Custom_ID__c = 'MKTPL-0000111';        
        update quoteLine1;
        
        quote1.SBQQ__Status__c = 'Contract Signed';
        quote1.Weekly_Tablet_Fee__c = 6.00;
        opp1.Order_Protocol__c = 'Tablet and Printer (DoorDash Owns)';
        update opp1;
        update quote1;
        String symbol = CDdQuoteTriggerHelper.getCurrencySymbolFromIso(quote1.CurrencyIsoCode);
        Integer value = Integer.valueOf(quote1.Weekly_Tablet_Fee__c);
        String tabletVal = symbol + String.valueOf(value);
        Test.stopTest();
        SBQQ.TriggerControl.enable();
        Opportunity opp2 = [SELECT 
                                Id, Weekly_Tablet_Subscription_Fee__c, DashPass_Flat_Fee__c, DashPass_Only_Commission__c, 
                                In_App_Pickup_Commission__c, Referred_Delivery_Commission__c, 
                                Referred_Pickup_Commission__c, RecordTypeId, CloseDate 
                                FROM Opportunity 
                                LIMIT 1];
        System.assertEquals(opp2.Weekly_Tablet_Subscription_Fee__c, tabletVal, 'The weekly tablet subscriptuion fee on the opportunity equals the converted version of the quote');                
    }

    @isTest
    static void testUpdateRelatedOpportunities114(){
        Product2 prod1 = [SELECT Id, DD_Custom_ID__c, Price_Basis__c FROM Product2 LIMIT 1];
    
        
        Account acct1 = [SELECT Id FROM Account LIMIT 1];
        SBQQ__QuoteLine__c quoteLine1 = [SELECT Id, Final_Commission__c, SBQQ__NetTotal__c, DD_Custom_ID__c FROM SBQQ__QuoteLine__c LIMIT 1];
        Opportunity opp1 = [SELECT 
                                Id, Commission__c, DashPass_Flat_Fee__c, DashPass_Only_Commission__c, 
                                In_App_Pickup_Commission__c, Referred_Delivery_Commission__c, 
                                Referred_Pickup_Commission__c, RecordTypeId, CloseDate, StageName,
                                RecordType.DeveloperName, Order_Protocol__c 
                                FROM Opportunity 
                                LIMIT 1];
        Test.startTest();
        SBQQ.TriggerControl.disable();

        prod1.DD_Custom_ID__c = 'MKTPL-0000114';
        prod1.Price_Basis__c = CDdCpqBillingConstants.PRODUCT_PRICEBASIS_COMMISSION;
        update prod1;

        SBQQ__Quote__c quote1 = [SELECT Id, RecordTypeId, SBQQ__Status__c, SBQQ__Opportunity2__c, Weekly_Printer_Fee__c, Opportunity_Record_Type__c, CurrencyIsoCode FROM SBQQ__Quote__c LIMIT 1];    
        
        quoteLine1.DD_Custom_ID__c = 'MKTPL-0000114';        
        update quoteLine1;
        
        quote1.SBQQ__Status__c = 'Contract Signed';
        quote1.Weekly_Printer_Fee__c = 3.15;
        opp1.Order_Protocol__c = 'Tablet and Printer (DoorDash Owns)';
        update opp1;
        update quote1;
        String symbol = CDdQuoteTriggerHelper.getCurrencySymbolFromIso(quote1.CurrencyIsoCode);
        String tabletVal = symbol + String.valueOf(quote1.Weekly_Printer_Fee__c);
        Test.stopTest();
        SBQQ.TriggerControl.enable();
        Opportunity opp2 = [SELECT 
                                Id, Weekly_Printer_Subscription_Fee__c, DashPass_Flat_Fee__c, DashPass_Only_Commission__c, 
                                In_App_Pickup_Commission__c, Referred_Delivery_Commission__c, 
                                Referred_Pickup_Commission__c, RecordTypeId, CloseDate 
                                FROM Opportunity 
                                LIMIT 1];
        System.assertEquals(opp2.Weekly_Printer_Subscription_Fee__c, tabletVal, 'The weekly printer subscriptuion fee on the opportunity equals the converted version of the quote');                
    }

    @isTest
    static void testUpdateRelatedOpportunitiesTrialPeriodQuote(){
        Account acct1 = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp1 = [SELECT 
                                Id, Commission__c, DashPass_Flat_Fee__c, DashPass_Only_Commission__c, 
                                In_App_Pickup_Commission__c, Referred_Delivery_Commission__c, 
                                Referred_Pickup_Commission__c, RecordTypeId, CloseDate, StageName 
                                FROM Opportunity 
                                LIMIT 1];

        SBQQ__Quote__c quote1 = [SELECT Id, RecordTypeId, SBQQ__Status__c, SBQQ__Opportunity2__c, Trial_Period_Quote__c, Opportunity_Record_Type__c FROM SBQQ__Quote__c LIMIT 1];
        Test.startTest();
        SBQQ.TriggerControl.disable();   
        quote1.Trial_Type__c = 'Promotional Period';
        quote1.SBQQ__Status__c = 'Contract Signed';
        quote1.User_Group__c = 'USD Inside Presales';
        quote1.Trial_Period_Quote__c = '30';
        update quote1;
        SBQQ.TriggerControl.enable();
        Test.stopTest();
        Opportunity opp2 = [SELECT 
                                Id, Commission__c, DashPass_Flat_Fee__c, DashPass_Only_Commission__c, 
                                Length_of_Trial__c, Referred_Delivery_Commission__c, 
                                Referred_Pickup_Commission__c, RecordTypeId, CloseDate, Trial_Type__c 
                                FROM Opportunity 
                                LIMIT 1];
        System.assertEquals(opp2.Length_of_Trial__c, quote1.Trial_Period_Quote__c + ' Days', 'The Length of trial on the opportunity does not equal the trial period quote field (plus the Days keyword) on the quote');  
        System.assertEquals(opp2.Trial_Type__c, 'Promotional Period', 'The Trial Type on the opportunity should be "Promotional Period"');                 
    }

   @isTest
   static void testUpdateOpportunityStageReady(){
       Account acct1 = [SELECT Id FROM Account LIMIT 1];
       SBQQ__QuoteLine__c quoteLine1 = [SELECT Id, Final_Commission__c, SBQQ__NetTotal__c, DD_Custom_ID__c FROM SBQQ__QuoteLine__c LIMIT 1];
       Opportunity opp1 = [SELECT
                               Id, Commission__c, DashPass_Flat_Fee__c, DashPass_Only_Commission__c,
                               In_App_Pickup_Commission__c, Referred_Delivery_Commission__c,
                               Referred_Pickup_Commission__c, RecordTypeId, CloseDate, StageName
                               FROM Opportunity
                               LIMIT 1];
       Test.startTest();
       SBQQ.TriggerControl.disable();
       SBQQ__Quote__c quote1 = [SELECT Id, RecordTypeId, SBQQ__Status__c, SBQQ__Opportunity2__c, ApprovalStatus__c, Opportunity_Record_Type__c FROM SBQQ__Quote__c LIMIT 1];  
              
       quote1.SBQQ__Status__c = CDdCpqBillingConstants.QUOTE_STATUS_APPROVED;
       update quote1;
       Test.stopTest();
       SBQQ.TriggerControl.enable();
       Opportunity opp2 = [SELECT
                               Id, Commission__c, DashPass_Flat_Fee__c, DashPass_Only_Commission__c,
                               In_App_Pickup_Commission__c, Referred_Delivery_Commission__c,
                               Referred_Pickup_Commission__c, RecordTypeId, StageName
                               FROM Opportunity
                               LIMIT 1];
       System.assertEquals(opp2.StageName, 'Ready for Signature', 'The opportunity stage name has been changed to Ready for Signature');               
   }

   @isTest
    static void testUpdateOpportunityStageReadyNegative(){
       Account acct1 = [SELECT Id FROM Account LIMIT 1];
       SBQQ__QuoteLine__c quoteLine1 = [SELECT Id, Final_Commission__c, SBQQ__NetTotal__c, DD_Custom_ID__c FROM SBQQ__QuoteLine__c LIMIT 1];
       Opportunity opp1 = [SELECT
                               Id, Commission__c, DashPass_Flat_Fee__c, DashPass_Only_Commission__c,
                               In_App_Pickup_Commission__c, Referred_Delivery_Commission__c,
                               Referred_Pickup_Commission__c, RecordTypeId, CloseDate, StageName
                               FROM Opportunity
                               LIMIT 1];
       Test.startTest();
       SBQQ.TriggerControl.disable();
       SBQQ__Quote__c quote1 = [SELECT
                                Id, RecordTypeId, SBQQ__Status__c, SBQQ__Opportunity2__c, SBQQ__Primary__c, 
                                ApprovalStatus__c, Opportunity_Record_Type__c 
                                FROM SBQQ__Quote__c 
                                LIMIT 1];  
              
       quote1.SBQQ__Status__c = CDdCpqBillingConstants.QUOTE_STATUS_APPROVED;
       quote1.SBQQ__Primary__c=false;
       update quote1;
       Test.stopTest();
       SBQQ.TriggerControl.enable();
       Opportunity opp2 = [SELECT
                               Id, Commission__c, DashPass_Flat_Fee__c, DashPass_Only_Commission__c,
                               In_App_Pickup_Commission__c, Referred_Delivery_Commission__c,
                               Referred_Pickup_Commission__c, RecordTypeId, StageName
                               FROM Opportunity
                               LIMIT 1];
       System.assertNotEquals(opp2.StageName, 'Ready for Signature', 'The opportunity stage name should not be Ready for Signature');               
   }
  
   @isTest
   static void testUpdateOpportunityStageOut(){
       Account acct1 = [SELECT Id FROM Account LIMIT 1];
       SBQQ__QuoteLine__c quoteLine1 = [SELECT Id, Final_Commission__c, SBQQ__NetTotal__c, DD_Custom_ID__c FROM SBQQ__QuoteLine__c LIMIT 1];
       Opportunity opp1 = [SELECT
                               Id, Commission__c, DashPass_Flat_Fee__c, DashPass_Only_Commission__c,
                               In_App_Pickup_Commission__c, Referred_Delivery_Commission__c,
                               Referred_Pickup_Commission__c, RecordTypeId, CloseDate, StageName
                               FROM Opportunity
                               LIMIT 1];
       Test.startTest();
       SBQQ.TriggerControl.disable();
       SBQQ__Quote__c quote1 = [SELECT Id, RecordTypeId, SBQQ__Status__c, SBQQ__Opportunity2__c, ApprovalStatus__c, Opportunity_Record_Type__c FROM SBQQ__Quote__c LIMIT 1];  
              
       quote1.SBQQ__Status__c = CDdCpqBillingConstants.QUOTE_STATUS_OUT_FOR_SIGNATURE;
       update quote1;
       Test.stopTest();
       SBQQ.TriggerControl.enable();
       Opportunity opp2 = [SELECT
                               Id, Commission__c, DashPass_Flat_Fee__c, DashPass_Only_Commission__c,
                               In_App_Pickup_Commission__c, Referred_Delivery_Commission__c,
                               Referred_Pickup_Commission__c, RecordTypeId, StageName
                               FROM Opportunity
                               LIMIT 1];
       System.assertEquals(opp2.StageName, quote1.SBQQ__Status__c, 'The opportunity stage name has been changed to match the quote status');               
   }
 
   @isTest
   static void testSetOptyPlatformDoorDash(){ 
       Account acct1 = [SELECT Id FROM Account LIMIT 1];
       Opportunity opp1 = [SELECT
                               Id, Platform__c, CloseDate
                               FROM Opportunity
                               LIMIT 1];
       Test.startTest();
       SBQQ.TriggerControl.disable();
       SBQQ__Quote__c quote1 = [SELECT Id, RecordTypeId, DoorDash_Products__c, SBQQ__Opportunity2__c, Caviar_Products__c, Opportunity_Record_Type__c, SBQQ__StartDate__c FROM SBQQ__Quote__c LIMIT 1];
       Product2 prod1 = TDdCPQTestDataFactory.createProduct(true);
       PricebookEntry pbe = TDdCPQTestDataFactory.createPriceBookEntry(prod1, 'USD', true);
       SBQQ__QuoteLine__c quoteLine = TDdCPQTestDataFactory.createQuoteLine(prod1, quote1, false);
       quoteLine.platform__c = 'DoorDash';
       insert quoteline;
       Test.stopTest();
       SBQQ.TriggerControl.enable();
       Opportunity opp2 = [SELECT Id, Platform__c, CloseDate FROM Opportunity LIMIT 1];
       System.assertEquals(opp2.Platform__c, 'DoorDash', 'The opportunity platform has been set to DoorDash');
   }
 
   @isTest
   static void testSetOptyPlatform(){
       Account acct1 = [SELECT Id FROM Account LIMIT 1];
       Opportunity opp1 = [SELECT
                               Id, Platform__c, CloseDate
                               FROM Opportunity
                               LIMIT 1];
       List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();
       SBQQ__Quote__c quote1 = [SELECT Id, RecordTypeId, DoorDash_Products__c, SBQQ__Opportunity2__c, Caviar_Products__c, Opportunity_Record_Type__c, SBQQ__StartDate__c FROM SBQQ__Quote__c LIMIT 1];
       Product2 prod1 = TDdCPQTestDataFactory.createProduct(true);
       PricebookEntry pbe1 = TDdCPQTestDataFactory.createPriceBookEntry(prod1, 'USD', true);
       SBQQ__QuoteLine__c quoteLine = TDdCPQTestDataFactory.createQuoteLine(prod1, quote1, false);
       quoteLine.Platform__c = 'Caviar';
       quoteLines.add(quoteLine);
       Product2 prod2 = TDdCPQTestDataFactory.createProduct(true);
       PricebookEntry pbe2 = TDdCPQTestDataFactory.createPriceBookEntry(prod2, 'USD', true);
       Test.startTest();
       SBQQ.TriggerControl.disable();
       SBQQ__QuoteLine__c quoteLine2 = TDdCPQTestDataFactory.createQuoteLine(prod2, quote1, false);
       quoteLine2.Platform__c = 'DoorDash';
       quoteLines.add(quoteLine2);
       insert quoteLines;
       Test.stopTest();
       SBQQ.TriggerControl.enable();
       Opportunity opp2 = [SELECT Id, Platform__c, CloseDate FROM Opportunity LIMIT 1];
       System.assertEquals(opp2.Platform__c, 'Caviar and DoorDash', 'The opportunity platform has been set to Caviar and DoorDash');
   } 
 
   @isTest
   static void testSetStandardPriceBook (){
       Account acct1 = [SELECT Id FROM Account LIMIT 1];

       Test.startTest();         
       Opportunity testOpp = TDdCPQTestDataFactory.createOpportunityByDevRT('TestCPQOpp1', acct1.Id, null, 'Meeting Ran / Negotiated', 'ML_Inside_Sales', false);
       testOpp.Pricebook2Id = Test.getStandardPricebookId();
       insert testOpp;
       SBQQ__Quote__c quote = TDdCPQTestDataFactory.createQuote(testOpp, acct1, null, false);
       insert quote;
       Test.stopTest();
       SBQQ__Quote__c quoteCheck = [SELECT
                                    Id, SBQQ__Opportunity2__r.Pricebook2Id, SBQQ__Opportunity2__r.Name,
                                    SBQQ__Opportunity2__c, SBQQ__PricebookId__c
                                    FROM SBQQ__Quote__c
                                    WHERE SBQQ__Opportunity2__r.Name = :testOpp.Name];
       System.assertEquals(Test.getStandardPricebookId(), quoteCheck.SBQQ__PricebookId__c, 'The quote pricebook should be the standard pricebook');
   }
 
   @isTest
   static void testOppPactsafeFieldMapping(){
       SBQQ__Quote__c quote = [SELECT Id, SBQQ__Opportunity2__c, PactSafe_Contract_Type__c, PactSafe_Activity_ID__c, PactSafe_Record__c, Contract_Signed_Date__c FROM SBQQ__Quote__c LIMIT 1];
       Test.startTest();
       quote.PactSafe_Activity_ID__c = 'ActivityId';
       quote.PactSafe_Record__c = 'www.atginfo.com';
       quote.Contract_Signed_Date__c = Date.today();
       update quote;
       Test.stopTest();
 
       Opportunity oppAfter = [SELECT Id, PactSafe_Contract_Type__c, PactSafe_Activity_ID__c, PactSafe_Record__c, Contract_Signed_Date__c FROM Opportunity WHERE Id = :quote.SBQQ__Opportunity2__c];
       System.assertEquals(quote.PactSafe_Activity_ID__c, oppAfter.PactSafe_Activity_ID__c, 'The pactsafe activity id did not map to the opp from quote');
       System.assertEquals(quote.PactSafe_Record__c, oppAfter.PactSafe_Record__c, 'The pactsafe record did not map to the opp from quote');
       System.assertEquals(quote.Contract_Signed_Date__c, oppAfter.Contract_Signed_Date__c, 'The pactsafe contract signed date did not map to the opp from quote');
   }

    @isTest
    static void processVoidedContracts_emptyInputs_expectEmpty(){
        Test.startTest();
        List<SBQQ__Quote__c> results = CDdQuoteTriggerHelper.processVoidedContracts(
            new List<SBQQ__Quote__c>(),
            new Map<Id, SBQQ__Quote__c>()
        );
        Test.stopTest();

        System.assert(results.isEmpty(), 'Expected an empty result for empty inputs.');
    }

    @isTest
    static void processVoidedContracts_wrongStatuses_expectEmpty(){
        // default status is 'Draft'
        Map<Id,SBQQ__Quote__c> oldQuotes = new Map<Id,SBQQ__Quote__c>(getQuotes());

        SBQQ__Quote__c newQuote = oldQuotes.values()[0].clone(true,false,false,false);
        newQuote.SBQQ__Status__c = CDdCpqBillingConstants.QUOTE_STATUS_IN_REVIEW;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CDdQuoteTriggerHelperTestMockPSExpireAPI());
        List<SBQQ__Quote__c> results = CDdQuoteTriggerHelper.processVoidedContracts(
            new List<SBQQ__Quote__c>{newQuote},
            oldQuotes
        );
        Test.stopTest();

        System.assert(results.isEmpty(), 'Expected empty result for statuses that don\'t indicate a voided contract.');
    }

    @isTest
    static void processVoidedContracts_alreadyApproved_expectEmpty(){
        Map<Id,SBQQ__Quote__c> oldQuotes = new Map<Id,SBQQ__Quote__c>(getQuotes());
        oldQuotes.values()[0].SBQQ__Status__c = CDdCpqBillingConstants.QUOTE_STATUS_APPROVED;

        SBQQ__Quote__c newQuote = oldQuotes.values()[0].clone(true,false,false,false);
        // leave status as approved

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CDdQuoteTriggerHelperTestMockPSExpireAPI());
        List<SBQQ__Quote__c> results = CDdQuoteTriggerHelper.processVoidedContracts(
            new List<SBQQ__Quote__c>{newQuote},
            oldQuotes
        );
        Test.stopTest();

        System.assert(results.isEmpty(), 'Expected empty result for already approved quotes.');
    }

    @isTest
    static void processVoidedContracts_movedBackToApproved_expectResult(){
        Map<Id,SBQQ__Quote__c> oldQuotes = new Map<Id,SBQQ__Quote__c>(getQuotes());
        oldQuotes.values()[0].SBQQ__Status__c = 'Out for Signature';

        SBQQ__Quote__c newQuote = oldQuotes.values()[0].clone(true,false,false,false);
        newQuote.SBQQ__Status__c = 'Approved';

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CDdQuoteTriggerHelperTestMockPSExpireAPI());
        List<SBQQ__Quote__c> results = CDdQuoteTriggerHelper.processVoidedContracts(
            new List<SBQQ__Quote__c>{newQuote},
            oldQuotes
        );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Expected one quote to be returned as valid.');
    }
    
   @isTest
   static void updateOptyCountAfterInsert_linkedToNewOpportunityWithoutQuotes_expectIncremented(){
       SBQQ.TriggerControl.disable();
       Account testAccount = getAccount();
       Opportunity testOpportunity = TDdCPQTestDataFactory.createOpportunity(testAccount.Id, true);

       SBQQ__Quote__c testQuote = TDdCPQTestDataFactory.createQuote(testOpportunity, testAccount, null, false);

       Test.startTest();
       insert testQuote;
       Test.stopTest();

       Opportunity finalOpportunity = requeryOpportunity(testOpportunity.Id);
       System.assertNotEquals(null, finalOpportunity, 'Expected Opportunity to still exist.');
       System.assertEquals(1, finalOpportunity.Number_of_Quotes__c, 'Expected the number of quotes to be "1".');
       SBQQ.TriggerControl.enable();
   }

   @isTest
   static void updateOptyCountAfterInsert_linkedToOpportunityWithQuotes_expectIncremented(){
       SBQQ.TriggerControl.disable();
       Account testAccount = getAccount();
       Contact testContact = getContact();
       Opportunity testOpportunity = TDdCPQTestDataFactory.createOpportunity(testAccount.Id, true);

       List<SBQQ__Quote__c> existingQuotes = new List<SBQQ__Quote__c>();
       for(Integer numberOfExistingQuotes = 0; numberOfExistingQuotes < 3; numberOfExistingQuotes++){
        existingQuotes.add(
            TDdCPQTestDataFactory.createQuote(testOpportunity, testAccount, testContact, false, false)
        );
       }
       insert existingQuotes;

       SBQQ__Quote__c testQuote = TDdCPQTestDataFactory.createQuote(testOpportunity, testAccount, null, false);

       Test.startTest();
       insert testQuote;
       Test.stopTest();

       Opportunity finalOpportunity = requeryOpportunity(testOpportunity.Id);
       System.assertNotEquals(null, finalOpportunity, 'Expected Opportunity to still exist.');
       System.assertEquals(4, finalOpportunity.Number_of_Quotes__c,
        'Expected the number of quotes to be "4"; 3 existed already, we added one.');
       SBQQ.TriggerControl.enable();
   }

   @isTest
   static void updateOptyCountAfterInsert_linkedToOpportunity_multiple_expectIncremented(){
    SBQQ.TriggerControl.disable();
    Account testAccount = getAccount();
    Opportunity testOpportunity = TDdCPQTestDataFactory.createOpportunity(testAccount.Id, true);
    TDdCPQTestDataFactory.createQuote(testOpportunity, testAccount, null, true); // one existing quote

    List<SBQQ__Quote__c> newQuotes = new List<SBQQ__Quote__c>();
    for(Integer numberOfNewQuotes = 0; numberOfNewQuotes < 4; numberOfNewQuotes++){
        newQuotes.add(
            TDdCPQTestDataFactory.createQuote(testOpportunity, testAccount, null, false, false)
        );
    }

    Test.startTest();
    insert newQuotes;
    Test.stopTest();

    Opportunity finalOpportunity = requeryOpportunity(testOpportunity.Id);
    System.assertNotEquals(null, finalOpportunity, 'Expected Opportunity to still exist.');
    System.assertEquals(5, finalOpportunity.Number_of_Quotes__c,
     'Expected the number of quotes to be "5"; one existed already, we added four.');
    SBQQ.TriggerControl.enable();
   }

   @isTest
   static void updateOptyCountAfterInsert_linkedToAnotherOpportunity_expectNotIncremented(){
    SBQQ.TriggerControl.disable();
    List<Account> allAccounts = getAccounts();
    Account testAccount = allAccounts[0];
    Account otherAccount = allAccounts[1];
    Contact testContact = getContact();
    Opportunity testOpportunity = TDdCPQTestDataFactory.createOpportunity(testAccount.Id, testContact.Id, false);
    Opportunity otherOpportunity = TDdCPQTestDataFactory.createOpportunity(otherAccount.Id, false);
    insert new List<Opportunity>{testOpportunity,otherOpportunity};

    List<SBQQ__Quote__c> existingQuotes = new List<SBQQ__Quote__c>();
    for(Integer numberOfExistingQuotes = 0; numberOfExistingQuotes < 3; numberOfExistingQuotes++){
     existingQuotes.add(
         TDdCPQTestDataFactory.createQuote(testOpportunity, testAccount, testContact, false, false)
     );
    }
    insert existingQuotes;

    // same account and contact, but different opportunity
    SBQQ__Quote__c testQuote = TDdCPQTestDataFactory.createQuote(otherOpportunity, testAccount, testContact, false);

    Test.startTest();
    insert testQuote;
    Test.stopTest();

    Opportunity finalOpportunity = requeryOpportunity(testOpportunity.Id);
    System.assertNotEquals(null, finalOpportunity, 'Expected Opportunity to still exist.');
    System.assertEquals(3, finalOpportunity.Number_of_Quotes__c,
     'Expected the number of quotes to be "3"; 3 existed already, we added one to a DIFFERENT opportunity.');
    SBQQ.TriggerControl.enable();
   }

   @isTest
   static void updateOptyCountAfterUpdate_changeInOpportunity_expectNewOppIncremented_expectOldOppDecremented(){
    SBQQ.TriggerControl.disable();
    Account testAccount = getAccount();
    Opportunity newOpportunity = TDdCPQTestDataFactory.createOpportunity(testAccount.Id, false);
    Opportunity oldOpportunity = TDdCPQTestDataFactory.createOpportunity(testAccount.Id, false);
    insert new List<Opportunity>{newOpportunity,oldOpportunity};

    SBQQ__Quote__c testQuote = TDdCPQTestDataFactory.createQuote(oldOpportunity, testAccount, null, false, true);

    Test.startTest();
    testQuote.SBQQ__Opportunity2__c = newOpportunity.Id;
    update testQuote;
    Test.stopTest();

    Opportunity updatedOldOpportunity = requeryOpportunity(oldOpportunity.Id);
    System.assertNotEquals(null, updatedOldOpportunity, 'Expected Opportunity to still exist.');
    System.assertEquals(0, updatedOldOpportunity.Number_of_Quotes__c,
     'Expected the number of quotes to be "0"; 1 existed already, we updated to refer to a different opportunity.');

    Opportunity updatedNewOpportunity = requeryOpportunity(newOpportunity.Id);
    System.assertNotEquals(null, updatedNewOpportunity, 'Expected Opportunity to still exist.');
    System.assertEquals(1, updatedNewOpportunity.Number_of_Quotes__c,
     'Expected the number of quotes to be "1"; 0 existed already, we updated one refer to this opportunity.');
    SBQQ.TriggerControl.enable();
   }

   @isTest
   static void updateOptyCountAfterUpdate_noChangeInOpportunity_expectNoChange_expectNoDML(){
    SBQQ.TriggerControl.disable();
    Account testAccount = getAccount();
    Opportunity testOpportunity = TDdCPQTestDataFactory.createOpportunity(testAccount.Id, true);
    SBQQ__Quote__c testQuote = TDdCPQTestDataFactory.createQuote(testOpportunity, testAccount, null, true);

    Integer numberOfDMLOperations;
    Test.startTest();
    testQuote.SBQQ__BillingName__c = 'Atreides LLC';
    update testQuote;
    numberOfDMLOperations = Limits.getDmlStatements();
    Test.stopTest();

    Opportunity finalOpportunity = requeryOpportunity(testOpportunity.Id);
    System.assertNotEquals(null, finalOpportunity, 'Expected Opportunity to still exist.');
    System.assertEquals(1, finalOpportunity.Number_of_Quotes__c, 'Expected the number of quotes to be unchanged at "1".');
    System.assertEquals(1, numberOfDMLOperations, 'Expected a single DML operation for the update, no more.');
    SBQQ.TriggerControl.enable();
   }

   @isTest
   static void updateOptyCountAfterUpdate_multipleUpdatesInOpportunity_expectAccurateIncrement_expectAccurateDecrement(){
    SBQQ.TriggerControl.disable();
    Account testAccount = getAccount();
    Opportunity newOpportunity = TDdCPQTestDataFactory.createOpportunity(testAccount.Id, false);
    Opportunity oldOpportunity = TDdCPQTestDataFactory.createOpportunity(testAccount.Id, false);
    insert new List<Opportunity>{newOpportunity,oldOpportunity};

    List<SBQQ__Quote__c> allQuotes = new List<SBQQ__Quote__c>();
    allQuotes.add(TDdCPQTestDataFactory.createQuote(newOpportunity, testAccount, null, false));
    allQuotes.add(TDdCPQTestDataFactory.createQuote(oldOpportunity, testAccount, null, false));

    List<SBQQ__Quote__c> testQuotes = new List<SBQQ__Quote__c>();
    for(Integer numberOfQuotes = 0; numberOfQuotes < 3; numberOfQuotes++){
        testQuotes.add(
            TDdCPQTestDataFactory.createQuote(oldOpportunity, testAccount, null, false, false)
        );
    }
    allQuotes.addAll(testQuotes);
    insert allQuotes;

    Test.startTest();
    for(SBQQ__Quote__c currentQuote : testQuotes){
        currentQuote.SBQQ__Opportunity2__c = newOpportunity.Id;
    }
    update testQuotes;
    Test.stopTest();

    Opportunity updatedOldOpportunity = requeryOpportunity(oldOpportunity.Id);
    System.assertNotEquals(null, updatedOldOpportunity, 'Expected Opportunity to still exist.');
    System.assertEquals(1, updatedOldOpportunity.Number_of_Quotes__c,
     'Expected the number of quotes to be "1"; 4 existed already, we updated 3 of them to refer to a different opportunity.');

    Opportunity updatedNewOpportunity = requeryOpportunity(newOpportunity.Id);
    System.assertNotEquals(null, updatedNewOpportunity, 'Expected Opportunity to still exist.');
    System.assertEquals(4, updatedNewOpportunity.Number_of_Quotes__c,
     'Expected the number of quotes to be "4"; 1 existed already, we updated three others to refer to this opportunity.');
    SBQQ.TriggerControl.enable();
   }

   @isTest
   static void updateOptyCountAfterDelete_noOpportunity_expectNoDML(){
    SBQQ.TriggerControl.disable();
    Account testAccount = getAccount();
    SBQQ__Quote__c testQuote = TDdCPQTestDataFactory.createQuote(null, testAccount, null, true);


    Integer dmlOperations;
    Test.startTest();
    delete testQuote;
    dmlOperations = Limits.getDmlStatements();
    Test.stopTest();

    System.assertEquals(1, dmlOperations, 'Expected only one DML operation for the SBQQ__Quote__c deletion.');
    SBQQ.TriggerControl.enable();
   }

   @isTest
   static void updateOptyCountAfterDelete_linkedOpportunity_expectDecrement(){
    SBQQ.TriggerControl.disable();
    Account testAccount = getAccount();
    Opportunity testOpportunity = TDdCPQTestDataFactory.createOpportunity(testAccount.Id, true);

    List<SBQQ__Quote__c> existingQuotes = new List<SBQQ__Quote__c>();
    for(Integer numberOfExistingQuotes = 0; numberOfExistingQuotes < 3; numberOfExistingQuotes++){
     existingQuotes.add(
         TDdCPQTestDataFactory.createQuote(testOpportunity, testAccount, null, false, false)
     );
    }
    insert existingQuotes;

    Test.startTest();
    delete existingQuotes[0];
    Test.stopTest();

    Opportunity finalOpportunity = requeryOpportunity(testOpportunity.Id);
    System.assertNotEquals(null, finalOpportunity, 'Expected Opportunity to still exist.');
    System.assertEquals(2, finalOpportunity.Number_of_Quotes__c,
     'Expected the number of quotes to be "2"; 3 existed already, we deleted one.');
    SBQQ.TriggerControl.enable();
   }

   @isTest
   static void updateOptyCountAfterDelete_linkedOpportunity_multiple_expectDecrement(){
    SBQQ.TriggerControl.disable();
    Account testAccount = getAccount();
    Opportunity testOpportunity = TDdCPQTestDataFactory.createOpportunity(testAccount.Id, true);

    List<SBQQ__Quote__c> existingQuotes = new List<SBQQ__Quote__c>();
    for(Integer numberOfExistingQuotes = 0; numberOfExistingQuotes < 3; numberOfExistingQuotes++){
     existingQuotes.add(
         TDdCPQTestDataFactory.createQuote(testOpportunity, testAccount, null, false, false)
     );
    }
    insert existingQuotes;

    Test.startTest();
    delete existingQuotes;
    Test.stopTest();

    Opportunity finalOpportunity = requeryOpportunity(testOpportunity.Id);
    System.assertNotEquals(null, finalOpportunity, 'Expected Opportunity to still exist.');
    System.assertEquals(0, finalOpportunity.Number_of_Quotes__c,
     'Expected the number of quotes to be "0"; 3 existed and we deleted them all.');
    SBQQ.TriggerControl.enable();
   }

    @isTest
    static void testUpdateBbotEstimatedActivationDate(){
        SBQQ.TriggerControl.disable();

        Opportunity testOpportunity = getOpportunity();
        Account testAccount = getAccount();
        Test.startTest();
        SBQQ__Quote__c testQuote = TDdCPQTestDataFactory.createQuote(testOpportunity, testAccount, null, false); 
        testQuote.DD_Id_s__c = 'BBOT-0000001, BBOT-0000002, BBOT-0000007, BBOT-0000011, BBOT-0000012';
        insert testQuote;

        testQuote.Bbot_Subscription_Start_Date__c = System.today().addDays(2);
        update testQuote;
        Test.stopTest();
        SBQQ.TriggerControl.enable();

        SBQQ__Quote__c finalQuery = [SELECT Id, Bbot_Subscription_Start_Date__c, Bbot_Estimated_Activation_Date__c FROM SBQQ__Quote__c WHERE Id =: testQuote.Id];
        System.assertEquals(finalQuery.Bbot_Estimated_Activation_Date__c, testQuote.Bbot_Subscription_Start_Date__c.addDays(28));
    }
  
    /**
    *@description BZAP-17460 - Subscription End Date - Automation & Validation
	*@Class Name - CDdQuoteTriggerHelper
	*@Method Name - updateBbotSubscriptionEndDate
    */
    @isTest
    static void testUpdateBbotSubscriptionEndDate(){
        SBQQ.TriggerControl.disable();

        Opportunity testOpportunity = getOpportunity();
        Account testAccount = getAccount();

        Validation_Bypass__c validation = [SELECT id, Bypass_Quote_Validations__c FROM Validation_Bypass__c where SetupOwnerId =: UserInfo.getUserId()];        
        validation.Bypass_Quote_Validations__c = false;
        update validation;

        Test.startTest();
        SBQQ__Quote__c testQuote = TDdCPQTestDataFactory.createQuote(testOpportunity, testAccount, null, false); 
        testQuote.DD_Id_s__c = 'BBOT-0000001, BBOT-0000002, BBOT-0000007, BBOT-0000011, BBOT-0000012';
        insert testQuote;

        testQuote.Bbot_Subscription_Start_Date__c = System.today().addDays(2);
        testQuote.Bbot_Subscription_Term__c = 'Monthly';
        update testQuote;

        SBQQ__Quote__c finalMontlyCheckQuery = [SELECT Id, Bbot_Subscription_Start_Date__c, Bbot_Subscription_End_Date__c FROM SBQQ__Quote__c WHERE Id =: testQuote.Id];
        System.assertEquals(finalMontlyCheckQuery.Bbot_Subscription_End_Date__c, testQuote.Bbot_Subscription_Start_Date__c.addMonths(1).addDays(-1));

        testQuote.Bbot_Subscription_Term__c = '1 Year';
        update testQuote;

        SBQQ__Quote__c finalYearCheckQuery = [SELECT Id, Bbot_Subscription_Start_Date__c, Bbot_Subscription_End_Date__c FROM SBQQ__Quote__c WHERE Id =: testQuote.Id];
        System.assertEquals(finalYearCheckQuery.Bbot_Subscription_End_Date__c, testQuote.Bbot_Subscription_Start_Date__c.addYears(1).addDays(-1));

        testQuote.Bbot_Subscription_Term__c = 'Custom';
        update testQuote;

        SBQQ__Quote__c finalCustomCheckQuery = [SELECT Id, Bbot_Subscription_Start_Date__c, Bbot_Subscription_End_Date__c FROM SBQQ__Quote__c WHERE Id =: testQuote.Id];
        System.assertEquals(finalCustomCheckQuery.Bbot_Subscription_End_Date__c, null);

        testQuote.Bbot_Subscription_Term__c = '';
        update testQuote;

        SBQQ__Quote__c finalQuery = [SELECT Id, Bbot_Subscription_Start_Date__c, Bbot_Subscription_End_Date__c FROM SBQQ__Quote__c WHERE Id =: testQuote.Id];
        System.assertEquals(finalQuery.Bbot_Subscription_End_Date__c, null);

        try{
            testQuote.Bbot_Subscription_End_Date__c = system.today();
            update testQuote;
        } catch(exception e){
            String errorMessage = 'Update failed. First exception on row 0 with id '+testQuote.Id+'; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, ';
            errorMessage = errorMessage + Label.Bbot_Custom_Subscription_End_Date_Error_Message + ': [Bbot_Subscription_End_Date__c]';
            System.assertEquals(errorMessage, e.getMessage());
        }
        Test.stopTest();
        SBQQ.TriggerControl.enable();
    }

    /**
     * Test method for CDdQuoteTriggerHelper.validateBbotOpportunityOnApprovalSubmission
     * BZAP-17701 Nathalie Mendezona
     **/
    @isTest
    static void testValidateBbotOpportunityOnApprovalSubmission(){
        SBQQ.TriggerControl.disable();

        contact testContact = getContact();
        Account testAccount = getAccount();
        Opportunity testOpportunity = TDdCPQTestDataFactory.createOpportunityByDevRT(
           'TestCPQOpp',
           testAccount.Id,
           null,
           'Meeting Ran / Negotiated',
           'DoorDash_for_Business',
           false
        );
        testOpportunity.Decision_Maker__c = testContact.Id;
        testOpportunity.Cuisine_Categories__c = 'Poke';
        testOpportunity.Integrations_Required__c = 'Otter';
        testOpportunity.Payment_Protocol__c = 'Invoicing';
        insert testOpportunity;

        OpportunityContactRole ocr = new OpportunityContactRole();
        ocr.OpportunityId = testOpportunity.Id;
        ocr.IsPrimary = true;
        ocr.Role = 'Primary Onboarding Contact';
        ocr.ContactId = testContact.Id;
        insert ocr;

        contact testContact1 = getContact();
        OpportunityContactRole ocr1 = new OpportunityContactRole();
        ocr1.OpportunityId = testOpportunity.Id;
        ocr1.Role = 'IT POC';
        ocr1.ContactId = testContact1.Id;
        insert ocr1;

        testAccount.POS_System__c = 'Abacus';
        testAccount.Bbot_Category__c = 'Entertainment';
        testAccount.Bbot_Sub_Category__c = 'Entertainment Complex';
        update testAccount;

        Validation_Bypass__c validation = [SELECT id, Bypass_Quote_Validations__c FROM Validation_Bypass__c where SetupOwnerId =: UserInfo.getUserId()];
        validation.Bypass_Quote_Validations__c = false;
        update validation;

        Product2 product = TDdCPQTestDataFactory.createProduct(true);
        Pricebook2 pricebook2 = new Pricebook2();
        pricebook2.Id = Test.getStandardPricebookId();
        pricebook2.IsActive = true;
        update pricebook2;
        PricebookEntry pbe = TDdCPQTestDataFactory.createPriceBookEntry(product, pricebook2, 'USD', true);

        SBQQ__Quote__c testQuote = TDdCPQTestDataFactory.createQuote(testOpportunity, testAccount, null, false);
        testQuote.DD_Id_s__c = 'BBOT-0000001, BBOT-0000002, BBOT-0000007, BBOT-0000011, BBOT-0000012';
        testQuote.Bbot_Subscription_Start_Date__c = Date.today();
        testQuote.Bbot_Subscription_End_Date__c = Date.today().addDays(5);
        testQuote.Bbot_Subscription_Term__c = '1 Year';
        insert testQuote;

        SBQQ__QuoteLine__c quoteLine = TDdCPQTestDataFactory.createQuoteLine(product, testQuote, true);
        Test.startTest();

        testQuote.SBQQ__Status__c = STATUS_IN_REVIEW;
        testQuote.ApprovalStatus__c = APPROVAL_STATUS_PENDING;
        update testQuote;

        Test.stopTest();
        SBQQ.TriggerControl.enable();
    }

    /**
    *@description BZAP-18012 - Code coverage for Default Bbot Additional Terms
	*@Class Name - CDdQuoteTriggerHelper
	*@Method Name - setDefaultValuesForAdditionalTermField
    */
    @isTest
    static void testSetDefaultValuesForAdditionalTermField(){
        SBQQ.TriggerControl.disable();
        Opportunity testOpportunity = getOpportunity();
        Account testAccount = getAccount();
        
        Test.startTest();
        SBQQ__Quote__c testQuote = TDdCPQTestDataFactory.createQuote(testOpportunity, testAccount, null, false);
        testQuote.Bbot_Additional_Terms__c = null;
        insert testQuote;
        
        SBQQ__Quote__c finalQuery = [SELECT Id, Bbot_Additional_Terms__c FROM SBQQ__Quote__c WHERE Id =: testQuote.Id];
        System.assertEquals(true, finalQuery.Bbot_Additional_Terms__c.contains('Full Logo Permission'));
        System.assertEquals(true, finalQuery.Bbot_Additional_Terms__c.contains('Implementation Refund Promo'));
        
        SBQQ__Quote__c testQuote2 = TDdCPQTestDataFactory.createQuote(testOpportunity, testAccount, null, false);
        testQuote.Bbot_Additional_Terms__c = 'Full Logo Permission';
        insert testQuote2;
        
        SBQQ__Quote__c finalQuery2 = [SELECT Id, Bbot_Additional_Terms__c FROM SBQQ__Quote__c WHERE Id =: testQuote2.Id];
        System.assertEquals(true, finalQuery2.Bbot_Additional_Terms__c.contains('Full Logo Permission'));
        System.assertEquals(true, finalQuery2.Bbot_Additional_Terms__c.contains('Implementation Refund Promo'));
        Test.stopTest();
        SBQQ.TriggerControl.enable();
    }
    
    /**
    *@description BZAP-18012 - Code coverage for Default Bbot Additional Terms
	*@Class Name - CDdQuoteTriggerHelper
	*@Method Name - removeDefaultValuesForAdditionalTermFieldForNonBBOT
    */
    @isTest
    static void testRemoveDefaultValuesForAdditionalTermFieldForNonBBOT(){
        SBQQ.TriggerControl.disable();
        Opportunity testOpportunity = getOpportunity();
        Account testAccount = getAccount();
        
        Test.startTest();
        SBQQ__Quote__c testQuote = TDdCPQTestDataFactory.createQuote(testOpportunity, testAccount, null, false);
        testQuote.DD_Id_s__c = 'BBOT-0000001, BBOT-0000002, BBOT-0000007, BBOT-0000011, BBOT-0000012';
        testQuote.Bbot_Additional_Terms__c = null;
        insert testQuote;
        
        testQuote.DD_Id_s__c = '';
        update testQuote;
        
        SBQQ__Quote__c finalQuery = [SELECT Id, Bbot_Additional_Terms__c FROM SBQQ__Quote__c WHERE Id =: testQuote.Id];
        System.assertEquals(finalQuery.Bbot_Additional_Terms__c, null);
        Test.stopTest();
        SBQQ.TriggerControl.enable();
    }
}