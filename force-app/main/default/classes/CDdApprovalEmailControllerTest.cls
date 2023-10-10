@isTest
public class CDdApprovalEmailControllerTest {
    @isTest static void testApprovalLines(){
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
		Test.startTest();
        SBQQ__Quote__c quote = TDdCPQTestDataFactory.createQuote(testOpp, accounts[0], null, true);
        SBQQ__QuoteLine__c quoteLine = TDdCPQTestDataFactory.createQuoteLine(product, quote, true);

        
        ApprovalEmailController controller = new ApprovalEmailController();
        controller.quoteId = quote.Id;
        
        List<SBQQ__QuoteLine__c> quoteLinesForEmails = controller.emailTemplateQuoteLines;
        Test.stopTest();
        System.assertEquals(1, quoteLinesForEmails.size(), 'There was 1 quoteline found to be approved for emails');
    }
}