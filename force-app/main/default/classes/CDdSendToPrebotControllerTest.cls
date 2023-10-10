/**
* @author: Pradeep Kumar Reddy Katigari
* @date: 11-2022
* @description: This test class is used to cover CDdSendToPrebotController
*/
@isTest
public class CDdSendToPrebotControllerTest {
    /**
     * @description this function is used as mock callout
     * Ticket BZAP-18038
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

    /**
     * @description this function is used to cover the CDdSendToPrebotController.getSetTimeIntervalValues method
     * Ticket BZAP-18038
     */
    @isTest
    static void getSetTimeIntervalValuesTest(){
        Map<String, Integer> setIntervalMap = CDdSendToPrebotController.getSetTimeIntervalValues();
        System.assertEquals(setIntervalMap.get('Prebot_Total_Waiting_Time_Interval_Sec'), CDdNameValuePairHelper.getIntegerValue('Prebot_Total_Waiting_Time_Interval_Sec'));
        System.assertEquals(setIntervalMap.get('Prebot_Time_Interval_Sec'), CDdNameValuePairHelper.getIntegerValue('Prebot_Time_Interval_Sec'));
    }

    /**
     * @description this function is used to cover the CDdSendToPrebotController.getOpportunity method
     * Ticket BZAP-18038
     */
    @isTest
    static void getOpportunityTest(){
        List<Opportunity> opportunities = new List<Opportunity>();
        Opportunity opportunityFake = (Opportunity)new Fake(Opportunity.class)
            .setFakeId()
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Prebot_Link__c, 'https://test.com')
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
            Opportunity oppExpection = CDdSendToPrebotController.getOpportunity(null);
        } catch(exception e){}
        Test.stopTest();
    }

    /**
     * @description this function is used to cover the CDdSendToPrebotController.callOuttoTray method
     * Ticket BZAP-18038
     */
    @isTest
    static void callOuttoTrayTest(){
        Id quoteId = Fake.generateId(SBQQ__Quote__c.SObjectType);
        Test.startTest();
        try{
            Test.setMock(HttpCalloutMock.class, new MockCallOuttoTrayResponseGenerator());
            Boolean calloutTryReturnValue = CDdSendToPrebotController.callOuttoTray(quoteId);
            System.assertEquals(calloutTryReturnValue, true);
        } catch(exception e){}
        Test.stopTest();
    }
}