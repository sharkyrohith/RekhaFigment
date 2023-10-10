@isTest
public class CDdCaseTriggerHelper_CPQTest {
    @TestSetup
    static void makeData(){
        CDdContactTriggerHelper.insertCampaign();
        Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
        validation.Bypass_Opportunity_Validations__c = true; 
        validation.Bypass_Account_Validations__c = true;
        insert validation;   

        vCS__c vcs = VTestUtil.createVeltigSettings();
        insert vcs;
        //BusinessHours bizHours = TDdCPQTestDatFactory.createDefaultBizHours(true);
        PriceBook2 pricebook = new Pricebook2(Id = Test.getStandardPricebookId(), isActive = true);
        update pricebook;
        List<Account> accounts = TDdAccountFactory.createAccounts('Test Acount', 1);
        insert accounts;
        Contact contact = TDdCPQTestDataFactory.createContact(true);
        Product2 product1 = TDdCPQTestDataFactory.createProduct(false);
        Product2 product2 = TDdCPQTestDataFactory.createProduct(false);
        product1.Create_Post_Sale_Activation_Case__c = true;
        List<Product2> products = new List<Product2>{product1, product2};
        insert products;
        PricebookEntry pbe1 = TDdCPQTestDataFactory.createPriceBookEntry(product1, 'USD', false);
        PricebookEntry pbe2 = TDdCPQTestDataFactory.createPriceBookEntry(product2, 'USD', false);
        List<PricebookEntry> pbes = new List<PricebookEntry>{pbe1,pbe2};
        insert pbes;
        String testOppName = 'TestDDOpportunity1';
        Opportunity testOpp = TDdOpportunityFactory.createOpportunityByDevRT('TestCPQOpp', accounts[0].Id, null, 'Closed Won', 'Post_Sale');
        testOpp.Decision_Maker__c = contact.Id;
        insert testOpp;
        Test.startTest();
        SBQQ.TriggerControl.disable();  
        SBQQ__Quote__c quote = TDdCPQTestDataFactory.createQuote(testOpp, accounts[0], null, false);
        quote.SBQQ__StartDate__c = Date.today().addDays(-30);
        quote.PactSafe_Contract_Type__c = '';         
        insert quote;  
        SBQQ__QuoteLine__c quoteLine1 = TDdCPQTestDataFactory.createQuoteLine(product1, quote, false);
        SBQQ__QuoteLine__c quoteLine2 = TDdCPQTestDataFactory.createQuoteLine(product2, quote, false);
        quoteLine1.SBQQ__PriceBookEntryId__c = pbe1.Id;
        quoteLine2.SBQQ__PriceBookEntryId__c = pbe2.Id;
        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>{quoteLine1, quoteLine2};
        insert quoteLines;
        quoteLine2.SBQQ__RequiredBy__c = quoteLine1.Id;
        update quoteLine2;
        Order order = TDdCPQTestDataFactory.createOrder(accounts[0], testOpp, quote, false);
        order.EffectiveDate = Date.today();
        order.EndDate = null;
        insert order;
        OrderItem orderProduct1 = TDdCPQTestDataFactory.createOrderItem(order, quoteLine1, pbe1.Id, false);
        OrderItem orderProduct2 = TDdCPQTestDataFactory.createOrderItem(order, quoteLine2, pbe2.Id, false);
        List<OrderItem> orderProducts = new List<OrderItem>{orderProduct1,orderProduct2};
        insert orderProducts;
        orderProduct2.SBQQ__RequiredBy__c = orderProduct1.Id;
        update orderProduct2;
        SBQQ.TriggerControl.enable();  
        Test.stopTest();
    }

    @isTest
    static void testPostSaleActivationsCaseClosed(){
        
        //Case should have been generated from order product trigger.
        Case postSaleCase = [SELECT Id, Status, Order_Product__c FROM Case LIMIT 1];
        System.assertNotEquals(null, postSaleCase.Order_Product__c, 'The post sale case is not linked to the order product');
        Test.StartTest();
        postSaleCase.Activation_Date__c = Date.Today().addDays(1);
        update postSaleCase;
        Test.StopTest();
        
        OrderItem orderProduct = [SELECT Id, ServiceDate, SBQQ__Status__c FROM OrderItem WHERE Id =: postSaleCase.Order_Product__c];
        OrderItem childOrderProduct = [SELECT ID, SBQQ__Status__c FROM OrderItem WHERE SBQQ__RequiredBy__c = :orderProduct.Id];
        System.assertEquals('Activated', orderProduct.SBQQ__Status__c, 'The order product should be activated after the case is closed/activated');
        System.assertEquals('Activated', childOrderProduct.SBQQ__Status__c, 'The child order product should be activated after the case related to its parent is closed/activated');
        System.assertEquals(postSaleCase.Activation_Date__c, orderProduct.ServiceDate, 'The order product service date should be the same as the case activation date');
    }
}