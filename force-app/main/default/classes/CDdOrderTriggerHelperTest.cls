@isTest
public class CDdOrderTriggerHelperTest {
    @testSetup
    public static void testSetup() {
        Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
        validation.Bypass_Opportunity_Validations__c = true;
        validation.Bypass_Quote_Validations__c = true;  
        insert validation;

        PriceBook2 pricebook = new Pricebook2(Id = Test.getStandardPricebookId(), isActive = true);
        update pricebook;
        
        SBQQ.TriggerControl.disable();      
        Test.startTest();
        List<Account> accounts = TDdAccountFactory.createAccounts('Test Acount', 1);
        insert accounts;

        Product2 product = TDdCPQTestDataFactory.createProduct(true);
        PricebookEntry pbe = TDdCPQTestDataFactory.createPriceBookEntry(product, 'USD', true);
        String testOppName = 'TestDDOpportunity1';
        Opportunity testOpp = TDdCPQTestDataFactory.createOpportunityByDevRT('TestCPQOpp', accounts[0].Id, null, 'Closed Won', 'ML_Inside_Sales', true);
        SBQQ__Quote__c quote = TDdCPQTestDataFactory.createQuote(testOpp, accounts[0], null, true);        
        SBQQ__QuoteLine__c quoteLine = TDdCPQTestDataFactory.createQuoteLine(product, quote, false);
        quoteLine.Trial_Period__c = '60';
        insert quoteLine;
        Order order = TDdCPQTestDataFactory.createOrder(accounts[0], testOpp, quote, false);
        order.EndDate = null;
        insert order;
        OrderItem orderProduct = TDdCPQTestDataFactory.createOrderItem(order, quoteLine, pbe.Id, true);
        SBQQ.TriggerControl.enable();
        Test.stopTest();
    }

    @isTest 
    static void testGenerateContract(){        
        Batch_and_Trigger_Setting__mdt contractSetting = [
                        SELECT Id, Label, DeveloperName, Batch_Size__c, Custom_Number__c, Disabled__c, Recursion__c
                        FROM Batch_and_Trigger_Setting__mdt
                        WHERE DeveloperName = 'CDdOrderTrigger_generateContracts' LIMIT 1
                    ];

        if(contractSetting.Disabled__c){
            contractSetting.Disabled__c = false;
        }
        
        Order order = [SELECT Id, Status, SBQQ__PriceCalcStatus__c FROM Order LIMIT 1];
        System.assertNotEquals('Completed', order.SBQQ__PriceCalcStatus__c, 'The price calculation status should be Not Started.');
        System.assertNotEquals('Not Needed', order.SBQQ__PriceCalcStatus__c, 'The price calculation status should be Not Started.');
        System.assertEquals('Draft', order.Status, 'The order should not be activated');
        Test.startTest();
        order.Status = 'Activated';
        update order;
        Test.stopTest();
        Order orderAfter = [SELECT Id, Status, SBQQ__PriceCalcStatus__c, SBQQ__Contracted__c FROM Order WHERE Id = :order.Id];
        System.assertEquals('Activated', orderAfter.Status, 'The order should be activated');
        System.assertEquals(true, orderAfter.SBQQ__Contracted__c, 'The order should be Contracted');
    }   
}