/**
* @author: Pradeep Kumar Reddy Katigari
* @date: 11-2022
* @description: This test class is used to cover CDdVoidPrebotController
*/
@isTest
public class CDdVoidPrebotControllerTest {
    /**
     * @description this function is used as mock callout
     * Ticket BZAP-18510
     */
    public class MockCallOuttoTrayResponseGenerator implements HttpCalloutMock{
        public HttpResponse respond(HTTPRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'text/xml; charset=utf-8');
            res.setStatusCode(200);
            String result='<?xml version="1.0" encoding="UTF-8"?>';
			result += '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">';
    		result += '<soapenv:Body>';
        	result += '<element name="notificationsResponse">';
            result += '<Ack>true</Ack>';
        	result += '</element>';
    		result += '</soapenv:Body>';
			result += '</soapenv:Envelope>';
            res.setBody(result);
            return res;
        }
    }

    @testSetup
    static void setup(){
        Test.StartTest();
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
        Test.StopTest();
    }
    
    private static Opportunity getOpportunity(){
        return [SELECT Id,Number_of_Quotes__c, CloseDate FROM Opportunity LIMIT 1];
    }

    private static Account getAccount(){
        return [SELECT Id FROM Account LIMIT 1];
    }
    
    /**
     * @description this function is used to cover the CDdVoidPrebotController.getSetTimeIntervalValues method
     * Ticket BZAP-18510
     */
    @isTest
    static void getSetTimeIntervalValuesTest(){
        Map<String, Integer> setIntervalMap = CDdVoidPrebotController.getSetTimeIntervalValues();
        System.assertEquals(setIntervalMap.get('Prebot_Total_Waiting_Time_Interval_Sec'), CDdNameValuePairHelper.getIntegerValue('Prebot_Total_Waiting_Time_Interval_Sec'));
        System.assertEquals(setIntervalMap.get('Prebot_Time_Interval_Sec'), CDdNameValuePairHelper.getIntegerValue('Prebot_Time_Interval_Sec'));
    }

    /**
     * @description this function is used to cover the CDdVoidPrebotController.recallApprovalQuote method
     * Ticket BZAP-18510
     */
    @isTest
    static void recallApprovalQuoteTest(){
        SBQQ.TriggerControl.disable();
        Opportunity testOpportunity = getOpportunity();
        Account testAccount = getAccount();
        
	Product2 product = [SELECT Id FROM Product2 LIMIT 1];
	    
        Test.startTest();
        SBQQ__Quote__c testQuote = TDdCPQTestDataFactory.createQuote(testOpportunity, testAccount, null, false);
        testQuote.DD_Id_s__c = 'BBOT-0000001, BBOT-0000002, BBOT-0000007, BBOT-0000011, BBOT-0000012';
        testQuote.Bbot_Additional_Terms__c = null;
        insert testQuote;
        
	SBQQ__QuoteLine__c quoteLine1 = TDdCPQTestDataFactory.createQuoteLine(product, testQuote, true);
	
        Boolean returnvalue = CDdVoidPrebotController.recallApprovalQuote(testQuote.Id);
        System.assertEquals(true, returnvalue);
        Test.stopTest();
    }

    /**
     * @description this function is used to cover the CDdVoidPrebotController.getOpportunity method
     * Ticket BZAP-18510
     */
    @isTest
    static void getOpportunityTest(){
        List<Opportunity> opportunities = new List<Opportunity>();
        Opportunity opportunityFake = (Opportunity)new Fake(Opportunity.class)
            .setFakeId()
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Prebot_Link__c, '')
            .toSObject();

        opportunities.add(opportunityFake);
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IOpportunitiesSelector selectorMock = (IOpportunitiesSelector) mocks.mock(IOpportunitiesSelector.class);
        mocks.startStubbing();
        mocks.when(selectorMock.sObjectType()).thenReturn(Opportunity.SObjectType);
        mocks.when(
            	selectorMock.selectById(new Set<Id>{opportunityFake.Id})
        	)
            .thenReturn(opportunities);
        mocks.stopStubbing();

        Application.SELECTOR.setMock(selectorMock);

        Test.startTest();
        Opportunity opp = CDdVoidPrebotController.getOpportunity(opportunityFake.Id);
        System.assertEquals(opp.Prebot_Link__c, opportunityFake.Prebot_Link__c);
        try{
            Opportunity oppExpection = CDdVoidPrebotController.getOpportunity(null);
        } catch(exception e){}
        Test.stopTest();
    }

    /**
     * @description this function is used to cover the CDdVoidPrebotController.callOuttoTray method
     * Ticket BZAP-18510
     */
    @isTest
    static void callOuttoTrayTest(){
        Id quoteId = Fake.generateId(SBQQ__Quote__c.SObjectType);
        Test.startTest();
        try{
            Test.setMock(HttpCalloutMock.class, new MockCallOuttoTrayResponseGenerator());
            Boolean calloutTryReturnValue = CDdVoidPrebotController.callOuttoTray(quoteId);
            System.assertEquals(calloutTryReturnValue, true);
        } catch(exception e){}
        Test.stopTest();
    }
}