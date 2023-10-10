/**
 * @description       : Test class for AWSCommandCenterController
 * @author            : Jose Vega
 * @last modified on  : 07-31-2023
 * @last modified by  : Jose Vega
**/
@isTest
public with sharing class AWSCommandCenterControllerTest {

    public class MockHttpResponseGenerator implements HttpCalloutMock{
        public HttpResponse respond(HTTPRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('[{"name":"testname", "description":"testdescription", "status":"Enabled", "hoursOfOepration":"All", "tags":"Cx"}]');
            return res;
        }
    }
    @isTest static void hasAccess() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Boolean response = AWSCommandCenterController.hasAccess();
        System.assert(response != null);
    }
    @isTest static void getBlockedNumbers() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        String response = AWSCommandCenterController.getBlockedNumbers();
        System.assert(response != null);
    }

    @isTest static void addBlockedNumber() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        String response = AWSCommandCenterController.addBlockedNumber('+13055104015');
        System.assert(response != null);
    }

    @isTest static void deleteBlockedNumber() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        String response = AWSCommandCenterController.deleteBlockedNumber('+13055104015');
        System.assert(response != null);
    }

    @isTest static void getHoursOfOperation() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        String response = AWSCommandCenterController.getHoursOfOperations();
        System.assert(response != null);
    }

    @isTest static void getPrompts() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        String response = AWSCommandCenterController.getPrompts();
        System.assert(response != null);
    }

    @isTest static void updatePrompt() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        AWSCommandCenterController.customResponse respose = AWSCommandCenterController.awsUpdateRecord('');
        System.assert(respose != null);
    }

    @isTest static void getQueues() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        String response = AWSCommandCenterController.getQueues();
        System.assert(response != null);
    }

    @isTest static void saveQueue() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        String response = AWSCommandCenterController.saveQueue('{"name": "test_queue", "businessHours":"UNIQUEID", "businessHoursName":"All Hours", "description":"testDescription"}');
        System.assert(response != null);
    }
}