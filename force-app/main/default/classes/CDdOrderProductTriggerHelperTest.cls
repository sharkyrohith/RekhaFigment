@isTest
public class CDdOrderProductTriggerHelperTest {

    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';

    static {
        TEST_ROLE_ID = TDdUserFactory.getUserRole('COO');
    }
    
    /** 
     * @description Prepare and return the test running user with System Admin Profile
     * @return User
     */
    private static User getTestRunUser() {
        User testRunUser = null;
        for(User u : [ SELECT Id FROM User WHERE UserName = :TEST_DD_RUN_USERNAME]){
            testRunUser = u;
        }
        if(testRunUser == null){
            testRunUser = TDdUserFactory.createUsers(1, null, TEST_ROLE_ID, false)[0];
            testRunUser.Username = TEST_DD_RUN_USERNAME;
        }
        return testRunUser;
    }
    @testSetup
    static void setup(){
        System.runAs(getTestRunUser()){
            CDdContactTriggerHelper.insertCampaign();
            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
            validation.Bypass_Opportunity_Validations__c = true; 
            validation.Bypass_Account_Validations__c = true;
            validation.Bypass_Quote_Validations__c = true;
            insert validation;   
            
            //BusinessHours bizHours = TDdCPQTestDatFactory.createDefaultBizHours(true);
            PriceBook2 pricebook = new Pricebook2(Id = Test.getStandardPricebookId(), isActive = true);
            update pricebook;
            List<Account> accounts = TDdAccountFactory.createAccounts('Test Acount', 1);
            insert accounts;
            Contact contact = TDdCPQTestDataFactory.createContact(true);
            Product2 product1 = TDdCPQTestDataFactory.createProduct(false);
            product1.Create_Post_Sale_Activation_Case__c = true;
            Product2 product2 = TDdCPQTestDataFactory.createProduct(false);        
            product2.Create_Post_Sale_Activation_Case__c = true;
            List<Product2> products = new List<Product2>{product1, product2};
            insert products;
            PricebookEntry pbe1 = TDdCPQTestDataFactory.createPriceBookEntry(product1, 'USD', false);
            PricebookEntry pbe2 = TDdCPQTestDataFactory.createPriceBookEntry(product2, 'USD', false);
            List<PricebookEntry> pbes = new List<PricebookEntry>{pbe1,pbe2};
            insert pbes;
            String testOppName = 'TestDDOpportunity1';
            Opportunity testOpp = TDdCPQTestDataFactory.createOpportunityByDevRT('TestCPQOpp', accounts[0].Id, null, 'Closed Won', 'Post_Sale', false);
            testOpp.Decision_Maker__c = contact.Id;
            insert testOpp;
            Test.startTest();
            SBQQ.TriggerControl.disable();  
            SBQQ__Quote__c quote = TDdCPQTestDataFactory.createQuote(testOpp, accounts[0], null, false);
            quote.Pactsafe_Contract_Type__c = '';
            quote.SBQQ__StartDate__c = Date.today().addDays(-30); 
            quote.Contract_Signed_Date__c = Date.today().addDays(-15);     
            insert quote;  
            SBQQ__QuoteLine__c quoteLine1 = TDdCPQTestDataFactory.createQuoteLine(product1, quote, false);
            quoteLine1.SBQQ__PriceBookEntryId__c = pbe1.Id;
            insert quoteLine1;
            SBQQ__QuoteLine__c quoteLine2 = TDdCPQTestDataFactory.createQuoteLine(product2, quote, false);
            quoteLine2.SBQQ__PriceBookEntryId__c = pbe2.Id;
            quoteLine2.SBQQ__RequiredBy__c = quoteLine1.Id;
            insert quoteLine2;

            Order order = TDdCPQTestDataFactory.createOrder(accounts[0], testOpp, quote, false);
            order.EffectiveDate = Date.today();
            order.EndDate = null;
            insert order;
            SBQQ.TriggerControl.enable();  
            Test.stopTest();
        }
    }

    @isTest 
    static void testCreatePostSaleCases(){
        List<SBQQ__QuoteLine__c> quoteLines = [
            SELECT Id, SBQQ__RequiredBy__c, SBQQ__PriceBookEntryId__c, SBQQ__Product__c, 
                SBQQ__ChargeType__c, SBQQ__BillingFrequency__c, SBQQ__BillingType__c, SBQQ__Quantity__c, 
                SBQQ__ListPrice__c, SBQQ__SubscriptionPricing__c, SBQQ__SubscriptionTerm__c, SBQQ__NetPrice__c 
            FROM SBQQ__QuoteLine__c LIMIT 2
        ];
        Order order = [SELECT Id FROM Order LIMIT 1];
        SBQQ__QuoteLine__c parentQL;
        SBQQ__QuoteLine__c childQL;

        for(SBQQ__QuoteLine__c line : quoteLines){
            if(line.SBQQ__RequiredBy__c != null){
                childQL = line;
            } else {
                parentQL = line;
            }
        }

        OrderItem parentOrderProduct = TDdCPQTestDataFactory.createOrderItem(order, parentQL, parentQL.SBQQ__PriceBookEntryId__c, false);
        OrderItem childOrderProduct = TDdCPQTestDataFactory.createOrderItem(order, childQL, childQL.SBQQ__PriceBookEntryId__c, false);
        List<OrderItem> orderProducts = new List<Orderitem>{parentOrderProduct, childOrderProduct};
        Test.startTest();
        insert orderProducts;
        Test.stopTest();
        Case caseAfter = [SELECT Id, RecordTypeId, Decision_Maker__c, Order_Product__c, Due_Date__c FROM Case WHERE Order_Product__c = :parentOrderProduct.Id LIMIT 1];
        Opportunity opp = [SELECT Id, Decision_Maker__c FROM Opportunity LIMIT 1];
        System.assertNotEquals(null, caseAfter, 'There was no case created when the order product was inserted');
        System.assertEquals(parentOrderProduct.Id, caseAfter.Order_Product__c, 'The order product was not mapped to the case correctly');
        System.assertEquals(opp.Decision_Maker__c, caseAfter.Decision_Maker__c, 'The decision maker was not mapped to the case from Opportunity');
        System.assertEquals(CDdSchemaUtils.CASE_RT.postSaleActivationsId(),caseAfter.RecordTypeId, 'The Case has the incorrect record type');
        System.assertEquals(Date.today().addDays(2),caseAfter.Due_Date__c, 'The Case has the incorrect Due Date');
    }

    @isTest 
    static void testCreatePostSaleCasesNegative(){
        List<Account> accounts = [SELECT Id, RecordTypeId FROM Account LIMIT 1];
        System.assertEquals(CDdOrderProductTriggerHelper.ACCOUNT_MARKETPLACE_RT, accounts[0].RecordTypeId, 'Account should be Marketplace');
        Id businessDevRT= CDdSchemaUtils.ACCOUNT_RT.businessDevelopmentId();
        accounts[0].RecordTypeId = businessDevRT;
        update accounts[0];

        List<SBQQ__QuoteLine__c> quoteLines = [
            SELECT Id, SBQQ__RequiredBy__c, SBQQ__PriceBookEntryId__c, SBQQ__Product__c, 
                SBQQ__ChargeType__c, SBQQ__BillingFrequency__c, SBQQ__BillingType__c, SBQQ__Quantity__c, 
                SBQQ__ListPrice__c, SBQQ__SubscriptionPricing__c, SBQQ__SubscriptionTerm__c, SBQQ__NetPrice__c 
            FROM SBQQ__QuoteLine__c LIMIT 2
        ];
        Order order = [SELECT Id FROM Order LIMIT 1];
        SBQQ__QuoteLine__c parentQL;
        SBQQ__QuoteLine__c childQL;

        for(SBQQ__QuoteLine__c line : quoteLines){
            if(line.SBQQ__RequiredBy__c != null){
                childQL = line;
            } else {
                parentQL = line;
            }
        }

        OrderItem parentOrderProduct = TDdCPQTestDataFactory.createOrderItem(order, parentQL, parentQL.SBQQ__PriceBookEntryId__c, false);
        OrderItem childOrderProduct = TDdCPQTestDataFactory.createOrderItem(order, childQL, childQL.SBQQ__PriceBookEntryId__c, false);
        List<OrderItem> orderProducts = new List<Orderitem>{parentOrderProduct, childOrderProduct};
        
        Test.startTest();
        insert orderProducts;
        Test.stopTest();

        List<Case> caseAfterList = [SELECT Id, RecordTypeId, Decision_Maker__c, Order_Product__c, Due_Date__c FROM Case WHERE Order_Product__c = :parentOrderProduct.Id];

        System.assertEquals(0, caseAfterList.size(), 'There should be no cases created for this Account Record Type');
    }

    @isTest 
    static void testPostSaleActivateOrders(){
        Test.startTest();
        Batch_and_Trigger_Setting__mdt orderActivationMeta = [SELECT Recursion__c FROM Batch_and_Trigger_Setting__mdt WHERE DeveloperName = 'CDdOrderTrigger_activateOrders'];
        orderActivationMeta.Recursion__c = 4;
        
        List<SBQQ__QuoteLine__c> quoteLines = [
            SELECT Id, SBQQ__RequiredBy__c, SBQQ__PriceBookEntryId__c, SBQQ__Product__c, 
                SBQQ__ChargeType__c, SBQQ__BillingFrequency__c, SBQQ__BillingType__c, SBQQ__Quantity__c, 
                SBQQ__ListPrice__c, SBQQ__SubscriptionPricing__c, SBQQ__SubscriptionTerm__c, SBQQ__NetPrice__c 
            FROM SBQQ__QuoteLine__c LIMIT 1
        ];
        Order order = [SELECT Id FROM Order LIMIT 1];


        OrderItem orderProduct = TDdCPQTestDataFactory.createOrderItem(order, quoteLines[0], quoteLines[0].SBQQ__PriceBookEntryId__c, false);
        insert orderProduct;
          
        
        orderProduct.SBQQ__Status__c = 'Activated';
        update orderProduct;
        Test.stopTest();

        Order orderAfter = [
            SELECT Id, Status
            FROM Order 
            WHERE Id = :order.Id LIMIT 1
        ];

        System.assertEquals('Activated', orderAfter.Status, 'The order was not activated once all order products were activated');
    }

    @isTest 
    static void testDueDateFutureContractSigned(){
        SBQQ__Quote__c quote = [
            SELECT Id, Contract_Signed_Date__c 
            FROM SBQQ__Quote__c LIMIT 1
        ];
        quote.Contract_Signed_Date__c = Date.today().addDays(3);     
        update quote;

        List<SBQQ__QuoteLine__c> quoteLines = [
            SELECT Id, SBQQ__RequiredBy__c, SBQQ__PriceBookEntryId__c, SBQQ__Product__c, 
                SBQQ__ChargeType__c, SBQQ__BillingFrequency__c, SBQQ__BillingType__c, SBQQ__Quantity__c, 
                SBQQ__ListPrice__c, SBQQ__SubscriptionPricing__c, SBQQ__SubscriptionTerm__c, SBQQ__NetPrice__c 
            FROM SBQQ__QuoteLine__c LIMIT 2
        ];

        Order order = [SELECT Id FROM Order LIMIT 1];
        SBQQ__QuoteLine__c parentQL;
        SBQQ__QuoteLine__c childQL;

        for(SBQQ__QuoteLine__c line : quoteLines){
            if(line.SBQQ__RequiredBy__c != null){
                childQL = line;
            } else {
                parentQL = line;
            }
        }
        parentQL.SBQQ__StartDate__c = Date.today().addDays(4);
        childQL.SBQQ__StartDate__c = Date.today().addDays(2);
        
		SBQQ.TriggerControl.disable();  
		List<SBQQ__QuoteLine__c> updatedQuoteLines = new List<SBQQ__QuoteLine__c>{parentQL, childQL};
        update updatedQuoteLines;  
        SBQQ.TriggerControl.enable();  
        
        OrderItem parentOrderProduct = TDdCPQTestDataFactory.createOrderItem(order, parentQL, parentQL.SBQQ__PriceBookEntryId__c, false);
        OrderItem childOrderProduct = TDdCPQTestDataFactory.createOrderItem(order, childQL, childQL.SBQQ__PriceBookEntryId__c, false);
        List<OrderItem> orderProducts = new List<Orderitem>{parentOrderProduct, childOrderProduct};
       	Test.startTest();
        insert orderProducts;
        Test.stopTest();

        Case caseAfter = [SELECT Id, RecordTypeId, Decision_Maker__c, Order_Product__c, Due_Date__c FROM Case WHERE Order_Product__c = :parentOrderProduct.Id LIMIT 1];
        System.assertEquals(quote.Contract_Signed_Date__c.addDays(2), caseAfter.Due_Date__c, 'The Case has the incorrect Due Date');
        Case caseChildAfter = [SELECT Id, RecordTypeId, Decision_Maker__c, Order_Product__c, Due_Date__c FROM Case WHERE Order_Product__c = :childOrderProduct.Id LIMIT 1];
        System.assertEquals(childQL.SBQQ__StartDate__c.addDays(2), caseChildAfter.Due_Date__c, 'The Child Case has the incorrect Due Date');
    }

    @isTest 
    static void testDueDateMarketplace(){
        Product2 product1 =  [
            SELECT Id, Create_Post_Sale_Activation_Case__c 
            FROM Product2
            WHERE Create_Post_Sale_Activation_Case__c = true LIMIT 1
        ];
        product1.Family = CDdOrderProductTriggerHelper.PRODUCT_FAMILY_MARKETPLACE_PROMOTION;
        update product1;


        List<SBQQ__QuoteLine__c> quoteLines = [
            SELECT Id, SBQQ__RequiredBy__c, SBQQ__PriceBookEntryId__c, SBQQ__Product__c, 
                SBQQ__ChargeType__c, SBQQ__BillingFrequency__c, SBQQ__BillingType__c, SBQQ__Quantity__c, 
                SBQQ__ListPrice__c, SBQQ__SubscriptionPricing__c, SBQQ__SubscriptionTerm__c, SBQQ__NetPrice__c 
            FROM SBQQ__QuoteLine__c LIMIT 2
        ];

        Order order = [SELECT Id FROM Order LIMIT 1];
        SBQQ__QuoteLine__c parentQL;
        SBQQ__QuoteLine__c childQL;

        for(SBQQ__QuoteLine__c line : quoteLines){
            if(line.SBQQ__RequiredBy__c != null){
                childQL = line;
            } else {
                parentQL = line;
            }
        }
        System.runAs (getTestRunUser()) {
            OrderItem parentOrderProduct = TDdCPQTestDataFactory.createOrderItem(order, parentQL, parentQL.SBQQ__PriceBookEntryId__c, false);
            OrderItem childOrderProduct = TDdCPQTestDataFactory.createOrderItem(order, childQL, childQL.SBQQ__PriceBookEntryId__c, false);
            List<OrderItem> orderProducts = new List<Orderitem>{parentOrderProduct, childOrderProduct};
            Test.startTest();
            insert orderProducts;
            Test.stopTest();

            Case caseAfter = [SELECT Id, RecordTypeId, Decision_Maker__c, Order_Product__c, Due_Date__c FROM Case WHERE Order_Product__c = :parentOrderProduct.Id LIMIT 1];
            System.assertEquals(Date.today().addDays(2), caseAfter.Due_Date__c, 'The Case has the incorrect Due Date');
        }
    }

    @isTest 
    static void testDueDateMarketplaceTrialDate(){
        List<Product2> productList =  [
            SELECT Id, Create_Post_Sale_Activation_Case__c 
            FROM Product2
            WHERE Create_Post_Sale_Activation_Case__c = true
        ];
        for (Product2 product: productList) {
            product.Family = CDdOrderProductTriggerHelper.PRODUCT_FAMILY_MARKETPLACE_PROMOTION;
        }
        update productList;


        List<SBQQ__QuoteLine__c> quoteLines = [
            SELECT Id, SBQQ__RequiredBy__c, SBQQ__PriceBookEntryId__c, SBQQ__Product__c, 
                SBQQ__ChargeType__c, SBQQ__BillingFrequency__c, SBQQ__BillingType__c, SBQQ__Quantity__c, 
                SBQQ__ListPrice__c, SBQQ__SubscriptionPricing__c, SBQQ__SubscriptionTerm__c, SBQQ__NetPrice__c 
            FROM SBQQ__QuoteLine__c LIMIT 2
        ];

        Order order = [SELECT Id FROM Order LIMIT 1];
        SBQQ__QuoteLine__c parentQL;
        SBQQ__QuoteLine__c childQL;

        System.runAs(getTestRunUser()) {
            for(SBQQ__QuoteLine__c line : quoteLines){
                if(line.SBQQ__RequiredBy__c != null){
                    childQL = line;
                } else {
                    parentQL = line;
                }
            }
            parentQL.Trial_Start_Date__c = Date.today().addDays(5);
            childQL.Trial_Start_Date__c = Date.today().addDays(2);
            SBQQ.TriggerControl.disable();  
            List<SBQQ__QuoteLine__c> updatedQuoteLines = new List<SBQQ__QuoteLine__c>{parentQL, childQL};
            update updatedQuoteLines;
            SBQQ.TriggerControl.enable();  
        
            OrderItem parentOrderProduct = TDdCPQTestDataFactory.createOrderItem(order, parentQL, parentQL.SBQQ__PriceBookEntryId__c, false);
            OrderItem childOrderProduct = TDdCPQTestDataFactory.createOrderItem(order, childQL, childQL.SBQQ__PriceBookEntryId__c, false);
            List<OrderItem> orderProducts = new List<Orderitem>{parentOrderProduct, childOrderProduct};
            Test.startTest();
            insert orderProducts;
            Test.stopTest();
            
            Case caseAfter = [SELECT Id, RecordTypeId, Decision_Maker__c, Order_Product__c, Due_Date__c FROM Case WHERE Order_Product__c = :parentOrderProduct.Id LIMIT 1];
            System.assertEquals(Date.today().addDays(3), caseAfter.Due_Date__c, 'The Case has the incorrect Due Date');
            Case caseChildAfter = [SELECT Id, RecordTypeId, Decision_Maker__c, Order_Product__c, Due_Date__c FROM Case WHERE Order_Product__c = :childOrderProduct.Id LIMIT 1];
            System.assertEquals(childQL.Trial_Start_Date__c, caseChildAfter.Due_Date__c, 'The Child Case has the incorrect Due Date');
        }
    }

    @isTest 
    static void testDueDateMarketplaceStartDate(){
        List<Product2> productList =  [
            SELECT Id, Create_Post_Sale_Activation_Case__c 
            FROM Product2
            WHERE Create_Post_Sale_Activation_Case__c = true
        ];
        for (Product2 product: productList) {
            product.Family = CDdOrderProductTriggerHelper.PRODUCT_FAMILY_MARKETPLACE_PROMOTION;
        }
        update productList;


        List<SBQQ__QuoteLine__c> quoteLines = [
            SELECT Id, SBQQ__RequiredBy__c, SBQQ__PriceBookEntryId__c, SBQQ__Product__c, 
                SBQQ__ChargeType__c, SBQQ__BillingFrequency__c, SBQQ__BillingType__c, SBQQ__Quantity__c, 
                SBQQ__ListPrice__c, SBQQ__SubscriptionPricing__c, SBQQ__SubscriptionTerm__c, SBQQ__NetPrice__c 
            FROM SBQQ__QuoteLine__c LIMIT 2
        ];

        Order order = [SELECT Id FROM Order LIMIT 1];
        SBQQ__QuoteLine__c parentQL;
        SBQQ__QuoteLine__c childQL;
        System.runAs (getTestRunUser()) {
            for(SBQQ__QuoteLine__c line : quoteLines){
                if(line.SBQQ__RequiredBy__c != null){
                    childQL = line;
                } else {
                    parentQL = line;
                }
            }
            parentQL.SBQQ__StartDate__c = Date.today().addDays(3);
            childQL.SBQQ__StartDate__c = Date.today().addDays(5);
            SBQQ.TriggerControl.disable();  
            List<SBQQ__QuoteLine__c> updatedQuoteLines = new List<SBQQ__QuoteLine__c>{parentQL, childQL};
            update updatedQuoteLines;
            SBQQ.TriggerControl.enable();  
            OrderItem parentOrderProduct = TDdCPQTestDataFactory.createOrderItem(order, parentQL, parentQL.SBQQ__PriceBookEntryId__c, false);
            OrderItem childOrderProduct = TDdCPQTestDataFactory.createOrderItem(order, childQL, childQL.SBQQ__PriceBookEntryId__c, false);
            List<OrderItem> orderProducts = new List<Orderitem>{parentOrderProduct, childOrderProduct};
            Test.startTest();
            insert orderProducts;
            Test.stopTest();

            Case caseAfter = [SELECT Id, RecordTypeId, Decision_Maker__c, Order_Product__c, Due_Date__c FROM Case WHERE Order_Product__c = :parentOrderProduct.Id LIMIT 1];
            System.assertEquals(Date.today().addDays(3), caseAfter.Due_Date__c, 'The Case has the incorrect Due Date');
            Case caseChildAfter = [SELECT Id, RecordTypeId, Decision_Maker__c, Order_Product__c, Due_Date__c FROM Case WHERE Order_Product__c = :childOrderProduct.Id LIMIT 1];
            System.assertEquals(childQL.SBQQ__StartDate__c.addDays(-2), caseChildAfter.Due_Date__c, 'The Child Case has the incorrect Due Date');
        }
    }

    @isTest 
    static void testDueDateMarketplaceStartDateBeforeTrial(){
        List<Product2> productList =  [
            SELECT Id, Create_Post_Sale_Activation_Case__c 
            FROM Product2
            WHERE Create_Post_Sale_Activation_Case__c = true
        ];
        for (Product2 product: productList) {
            product.Family = CDdOrderProductTriggerHelper.PRODUCT_FAMILY_MARKETPLACE_PROMOTION;
        }
        update productList;


        List<SBQQ__QuoteLine__c> quoteLines = [
            SELECT Id, SBQQ__RequiredBy__c, SBQQ__PriceBookEntryId__c, SBQQ__Product__c, 
                SBQQ__ChargeType__c, SBQQ__BillingFrequency__c, SBQQ__BillingType__c, SBQQ__Quantity__c, 
                SBQQ__ListPrice__c, SBQQ__SubscriptionPricing__c, SBQQ__SubscriptionTerm__c, SBQQ__NetPrice__c 
            FROM SBQQ__QuoteLine__c LIMIT 2
        ];

        Order order = [SELECT Id FROM Order LIMIT 1];
        SBQQ__QuoteLine__c parentQL;
        SBQQ__QuoteLine__c childQL;
        System.runAs (getTestRunUser()) {
            for(SBQQ__QuoteLine__c line : quoteLines){
                if(line.SBQQ__RequiredBy__c != null){
                    childQL = line;
                } else {
                    parentQL = line;
                }
            }
            parentQL.Trial_Start_Date__c = Date.today().addDays(6);
            parentQL.SBQQ__StartDate__c = Date.today().addDays(5);
            childQL.Trial_Start_Date__c = Date.today().addDays(3);
            childQL.SBQQ__StartDate__c = Date.today().addDays(2);
			SBQQ.TriggerControl.disable();              
            List<SBQQ__QuoteLine__c> updatedQuoteLines = new List<SBQQ__QuoteLine__c>{parentQL, childQL};
            update updatedQuoteLines;
            SBQQ.TriggerControl.enable();  
            OrderItem parentOrderProduct = TDdCPQTestDataFactory.createOrderItem(order, parentQL, parentQL.SBQQ__PriceBookEntryId__c, false);
            OrderItem childOrderProduct = TDdCPQTestDataFactory.createOrderItem(order, childQL, childQL.SBQQ__PriceBookEntryId__c, false);
            List<OrderItem> orderProducts = new List<Orderitem>{parentOrderProduct, childOrderProduct};
            Test.startTest();
            insert orderProducts;
            Test.stopTest();

            Case caseAfter = [SELECT Id, RecordTypeId, Decision_Maker__c, Order_Product__c, Due_Date__c FROM Case WHERE Order_Product__c = :parentOrderProduct.Id LIMIT 1];
            System.assertEquals(parentQL.SBQQ__StartDate__c.addDays(-2), caseAfter.Due_Date__c, 'The Case has the incorrect Due Date');
            Case caseChildAfter = [SELECT Id, RecordTypeId, Decision_Maker__c, Order_Product__c, Due_Date__c FROM Case WHERE Order_Product__c = :childOrderProduct.Id LIMIT 1];
            System.assertEquals(childQL.SBQQ__StartDate__c, caseChildAfter.Due_Date__c, 'The Child Case has the incorrect Due Date');
        }
    }

    @isTest 
    static void testDueDateMarketplaceStartDateAfterTrial(){
        List<Product2> productList =  [
            SELECT Id, Create_Post_Sale_Activation_Case__c 
            FROM Product2
            WHERE Create_Post_Sale_Activation_Case__c = true
        ];
        for (Product2 product: productList) {
            product.Family = CDdOrderProductTriggerHelper.PRODUCT_FAMILY_MARKETPLACE_PROMOTION;
        }
        update productList;

        List<SBQQ__QuoteLine__c> quoteLines = [
            SELECT Id, SBQQ__RequiredBy__c, SBQQ__PriceBookEntryId__c, SBQQ__Product__c, 
                SBQQ__ChargeType__c, SBQQ__BillingFrequency__c, SBQQ__BillingType__c, SBQQ__Quantity__c, 
                SBQQ__ListPrice__c, SBQQ__SubscriptionPricing__c, SBQQ__SubscriptionTerm__c, SBQQ__NetPrice__c 
            FROM SBQQ__QuoteLine__c LIMIT 2
        ];

        Order order = [SELECT Id FROM Order LIMIT 1];
        SBQQ__QuoteLine__c parentQL;
        SBQQ__QuoteLine__c childQL;
        System.runAs (getTestRunUser()) {

            for(SBQQ__QuoteLine__c line : quoteLines){
                if(line.SBQQ__RequiredBy__c != null){
                    childQL = line;
                } else {
                    parentQL = line;
                }
            }
            parentQL.Trial_Start_Date__c = Date.today().addDays(2);
            parentQL.SBQQ__StartDate__c = Date.today().addDays(3);
            childQL.Trial_Start_Date__c = Date.today().addDays(5);
            childQL.SBQQ__StartDate__c = Date.today().addDays(6);
            SBQQ.TriggerControl.disable();  
            List<SBQQ__QuoteLine__c> updatedQuoteLines = new List<SBQQ__QuoteLine__c>{parentQL, childQL};
            update updatedQuoteLines;
            SBQQ.TriggerControl.enable();  
            OrderItem parentOrderProduct = TDdCPQTestDataFactory.createOrderItem(order, parentQL, parentQL.SBQQ__PriceBookEntryId__c, false);
            OrderItem childOrderProduct = TDdCPQTestDataFactory.createOrderItem(order, childQL, childQL.SBQQ__PriceBookEntryId__c, false);
            List<OrderItem> orderProducts = new List<Orderitem>{parentOrderProduct, childOrderProduct};
            Test.startTest();
            insert orderProducts;
            Test.stopTest();

            Case caseAfter = [SELECT Id, RecordTypeId, Decision_Maker__c, Order_Product__c, Due_Date__c FROM Case WHERE Order_Product__c = :parentOrderProduct.Id LIMIT 1];
            System.assertEquals(parentQL.Trial_Start_Date__c, caseAfter.Due_Date__c, 'The Case has the incorrect Due Date');
            Case caseChildAfter = [SELECT Id, RecordTypeId, Decision_Maker__c, Order_Product__c, Due_Date__c FROM Case WHERE Order_Product__c = :childOrderProduct.Id LIMIT 1];
            System.assertEquals(childQL.Trial_Start_Date__c.addDays(-2), caseChildAfter.Due_Date__c, 'The Child Case has the incorrect Due Date');
        }
    }

    @isTest 
    static void testOppBulkActivation(){
        Opportunity opp = [SELECT Id, Bulk_Activation__c FROM Opportunity LIMIT 1];
        opp.Bulk_Activation__c = true;
        update opp;

        List<SBQQ__QuoteLine__c> quoteLines = [
            SELECT Id, SBQQ__RequiredBy__c, SBQQ__PriceBookEntryId__c, SBQQ__Product__c, 
                SBQQ__ChargeType__c, SBQQ__BillingFrequency__c, SBQQ__BillingType__c, SBQQ__Quantity__c, 
                SBQQ__ListPrice__c, SBQQ__SubscriptionPricing__c, SBQQ__SubscriptionTerm__c, SBQQ__NetPrice__c 
            FROM SBQQ__QuoteLine__c LIMIT 2
        ];
        Order order = [SELECT Id FROM Order LIMIT 1];
        SBQQ__QuoteLine__c parentQL;
        SBQQ__QuoteLine__c childQL;

        System.runAs (getTestRunUser()) {

            for(SBQQ__QuoteLine__c line : quoteLines){
                if(line.SBQQ__RequiredBy__c != null){
                    childQL = line;
                } else {
                    parentQL = line;
                }
            }

            OrderItem parentOrderProduct = TDdCPQTestDataFactory.createOrderItem(order, parentQL, parentQL.SBQQ__PriceBookEntryId__c, false);
            OrderItem childOrderProduct = TDdCPQTestDataFactory.createOrderItem(order, childQL, childQL.SBQQ__PriceBookEntryId__c, false);
            List<OrderItem> orderProducts = new List<Orderitem>{parentOrderProduct, childOrderProduct};
            Test.startTest();
            insert orderProducts;
            Test.stopTest();
            List<Case> caseAfterList = [SELECT Id, RecordTypeId, Decision_Maker__c, Order_Product__c, Due_Date__c FROM Case WHERE Order_Product__c = :parentOrderProduct.Id];

            System.assertEquals(0, caseAfterList.size(), 'Case should not be created becase Opportunity is Bulk Activated = true');
        }
    }
}