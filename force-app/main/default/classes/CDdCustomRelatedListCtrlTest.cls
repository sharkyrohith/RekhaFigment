@isTest
public with sharing class CDdCustomRelatedListCtrlTest {
    @TestSetup
    static void makeData(){
    Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
       validation.Bypass_Opportunity_Validations__c = true;
       validation.Bypass_Account_Validations__c = true;
       validation.Bypass_Quote_Validations__c = true;
       insert validation;     
       Test.StartTest();
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
      
       SBQQ__Quote__c quote = TDdCPQTestDataFactory.createQuote(testOpp, accounts[0], null, true);       
       SBQQ__QuoteLine__c quoteLine = TDdCPQTestDataFactory.createQuoteLine(product, quote, true);
       Test.StopTest();    
    }

    @isTest
    static void getAllRecordsTest() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        List<Custom_Related_List_Fields__mdt> fields = CDdCustomRelatedListCtrl.getFields('SBQQ__QuoteLine__c');
        List<String> queryFields = new List<String>();
        for(Custom_Related_List_Fields__mdt listField : fields){
            //Id already included in query
            if(!queryFields.contains(listField.Field_Name__c)){
                queryFields.add(listField.Field_Name__c);
            }
            if(!String.isBlank(listField.URL_Display_Field__c) && 
                !queryFields.contains(listField.URL_Display_Field__c) 
            ){
                queryFields.add(listField.URL_Display_Field__c);
            }
            if(!String.isBlank(listField.URL_Id__c) &&
                !queryFields.contains(listField.URL_Id__c)
            ){
                queryFields.add(listField.URL_Id__c);
            }           
        }
        System.assertNotEquals(null, fields.size(), 'Quote Line should have custom related list metadata records in the org');

        List<SObject> records = CDdCustomRelatedListCtrl.getAllRecords(quote.Id, 'SBQQ__Quote__c', 'SBQQ__QuoteLine__c', queryFields, 'SBQQ__Number__c');
        System.assertNotEquals(null, records.size(), 'Quote Line should have been returned');
    }

    @isTest
    static void getPluralLabelTest() {
        String pluralLabel = CDdCustomRelatedListCtrl.getPluralLabel('SBQQ__QuoteLine__c');
        System.assertEquals('Quote Lines', pluralLabel, 'The plural label for quote line was not retrived from the schema');
    }
}