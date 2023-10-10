@isTest
private class CDdOnBoardingCaseOpptyLineItemsCtrlTest {

    private static Integer intRecCount = 5;
    @isTest
    public static void getOpportunityLineItemsTest(){
        
        //insert product
        Product2 recProduct = new Product2(Name = ' Test Product ',Description='Test Product Entry For Product',
        						  productCode = 'SFDCPanther-123', isActive = true);
        insert recProduct;
        
        // insert pricebook entry for the product
        PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(),
        Product2Id = recProduct.Id,UnitPrice = 100,IsActive = true,UseStandardPrice = false);
        insert standardPrice ;
        
        // insert account
        Account recAcc = new Account(Name = 'SFDCPanther.com',Rating = 'Hot',Industry = 'Banking',Phone = '9087654321');
        insert recAcc;
        
        // Create Opportunity
        Opportunity recOpp = new Opportunity(AccountId = recAcc.Id,Name = 'Test Opportunity',CloseDate= System.Today(),
                                          StageName='Prospecting',Pricebook2Id = Test.getStandardPricebookId());
        insert recOpp;
        
        // Add product and Pricebook to the particular opportunity using OpportunityLineItem 
        OpportunityLineItem oppLineItem = new OpportunityLineItem(OpportunityId = recOpp.Id, PricebookEntryId = standardPrice.Id,
                                                                  UnitPrice = 7000,Quantity = 5);
        insert oppLineItem;
        
        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Marketplace Onboarding').getRecordTypeId();

        Case recCase = new Case(AccountId = recAcc.Id, RecordTypeId = recordTypeId, Type='My Type', 
                                Origin='My Origin', Status='My Status', Opportunity_Name__c = recOpp.Id);
        insert recCase;
        
        Test.startTest();
        
        CDdOnBoardingCaseOpptyLineItemsCtrl.Response result;
        result = CDdOnBoardingCaseOpptyLineItemsCtrl.getOpportunityLineItems(recCase.Id);
        System.assert(result.isSuccess);
        
        result = CDdOnBoardingCaseOpptyLineItemsCtrl.getOpportunityLineItems('');
        System.assert(result.isSuccess==FALSE);
        Test.stopTest();
    }
}