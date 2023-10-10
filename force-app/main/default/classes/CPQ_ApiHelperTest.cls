@isTest
public class CPQ_ApiHelperTest {   
    @testSetup
    public static void setup(){
       Test.startTest(); 
       Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
       validation.Bypass_Opportunity_Validations__c = true;
       validation.Bypass_Account_Validations__c = true;
       insert validation;
       PriceBook2 pricebook = new Pricebook2(Id = Test.getStandardPricebookId(), isActive = true);
       update pricebook;
       
       Account account = TDdAccountFactory.createAccounts('Account1', 1)[0];
       insert account;

       Contact contact = TDdAccountFactory.createContacts(1, account.Id)[0]; 
       insert contact;
       
       Opportunity opp = TDdCpqTestDataFactory.createOpportunityByDevRT('Opp', account.Id, contact.Id, 'Closed Won', 'ML_Inside_Sales', true);
       Test.stopTest();
       List<Product2> products = new List<Product2>{
       TDdCpqTestDataFactory.createProduct(false),
       TDdCpqTestDataFactory.createProduct(false)
       };
       insert products;

       SBQQ__Quote__c quote = TDdCpqTestDataFactory.createQuote(opp, account, contact, true);
       SBQQ__QuoteLine__c parentQL =  TDdCpqTestDataFactory.createQuoteLine(products[0], quote, true);
       SBQQ__QuoteLine__c childQL =  TDdCpqTestDataFactory.createQuoteLine(products[1], quote, false);
       childQL.SBQQ__RequiredBy__c = parentQL.Id;
       insert childQL;
    }
    
    @IsTest
    public static void testGetQuoteModel() {
       SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
       CPQ_ApiHelper.debug = true;
       CPQ_ApiDataModels.QuoteModel quoteModel = CPQ_ApiHelper.getQuoteModel(quote.Id);
       System.assertNotEquals(null, quoteModel);
    }

    @IsTest
    public static void testLoadProduct() {
       Product2 product = [SELECT Id FROM Product2 LIMIT 1];
       CPQ_ApiDataModels.ProductModel productModel = CPQ_ApiHelper.loadProduct(product.Id, Test.getStandardPricebookId(), 'USD');
       System.assertNotEquals(null, productModel);
    }

    @IsTest
    public static void testAddProductToQuoteAndSaveQuote() {
       SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
       Product2 product = [SELECT Id FROM Product2 LIMIT 1];
       List<SBQQ__QuoteLine__c> initalQuoteLines = [SELECT Id FROM SBQQ__QuoteLine__c];
       CPQ_ApiDataModels.QuoteModel quoteModel = CPQ_ApiHelper.addProductsToQuote(quote.Id, product.Id, Test.getStandardPricebookId(), 'USD', true);
       CPQ_ApiHelper.saveQuote(quoteModel);
       List<SBQQ__QuoteLine__c> additionalQuoteLines = [SELECT Id FROM SBQQ__QuoteLine__c];
       System.assert(additionalQuoteLines.size() > initalQuoteLines.size());
    }

    @IsTest
    public static void testCalculate() {
       SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
       CPQ_ApiDataModels.QuoteModel quoteModel = CPQ_ApiHelper.getQuoteModel(quote.Id);
       // Theses make a callout and will fail, wrapping in try/catch just for code coverage
       // because it is SBQQ code, not our code and we have functionally tested everything needed
       Test.startTest();
       CPQ_ApiHelper.calculateQuote(quoteModel); 
       Test.stopTest();
       System.assertEquals(quoteModel.record.SBQQ__Uncalculated__c, false, 'The quote should have been calculated in the API call');
    }    
}