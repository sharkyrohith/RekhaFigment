/*
    Ticket          : https://doordash.atlassian.net/browse/BZAP-16407
    Author          : Sid Agarwal, 2022
    Test Class For  : JiraConnector.cls
*/

@isTest
public with sharing class JiraConnectorTests
{
    @testSetup
    static void testData()
    {
        list<Admin_Access_Request__c> requests = new Admin_Access_Request__c[]
        {
            new Admin_Access_Request__c(Jira_Ticket_Number__c = 'TEST-1234', Duration_of_Access__c = '1', Reason_for_Access__c = 'Hotfix / Incident')
        };
        insert requests;
    }

    /////////////////////// getTicketByName

    @isTest
    static void test_JIRAConnector_getTicketByName_Success()
    {
        Admin_Access_Request__c newRequest = getRecord();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new test_success_mock());
        JIRAConnector.getTicketByName(newRequest.id, true, false);
        Test.stopTest();

        newRequest = [Select id, Status__c, Error_Message__c from Admin_Access_Request__c Where Id =: newRequest.Id];
        system.assertNotEquals('Failed', newRequest.Status__c);
    }

    @isTest
    static void test_JIRAConnector_getTicketByName_Failure()
    {
        Admin_Access_Request__c newRequest = getRecord();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new test_failure_mock());
        JIRAConnector.getTicketByName(newRequest.id, true, true);
        Test.stopTest();

        newRequest = [Select id, Status__c, Error_Message__c from Admin_Access_Request__c Where Id =: newRequest.Id];
        system.assertEquals('Failed', newRequest.Status__c);
    }

    /////////////////////// createSubTask

    @isTest
    static void test_JIRAConnector_createSubTask_Success()
    {
        Admin_Access_Request__c newRequest = getRecord();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new test_success_mock());
        JIRAConnector.createSubTask(newRequest.id);
        Test.stopTest();

        newRequest = [Select id, Status__c, Error_Message__c, Jira_Sub_Ticket_Number__c from Admin_Access_Request__c Where Id =: newRequest.Id];
        // system.assertNotEquals(null, newRequest.Jira_Sub_Ticket_Number__c); // need updated json mock response
        system.assertNotEquals('Failed', newRequest.Status__c);
    }

    @isTest
    static void test_JIRAConnector_createSubTask_Failure()
    {
        Admin_Access_Request__c newRequest = getRecord();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new test_failure_mock());
        JIRAConnector.createSubTask(newRequest.id);
        Test.stopTest();

        newRequest = [Select id, Status__c, Error_Message__c from Admin_Access_Request__c Where Id =: newRequest.Id];
        system.assertEquals('Failed', newRequest.Status__c);
    }

    /////////////////////// addCommentWithAuditLogs

    @isTest
    static void test_JIRAConnector_addCommentWithAuditLogs_Success()
    {
        Admin_Access_Request__c newRequest = getRecord();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new test_success_mock());
        JIRAConnector.addCommentWithAuditLogs(newRequest.id);
        Test.stopTest();

        newRequest = [Select id, Status__c, Error_Message__c from Admin_Access_Request__c Where Id =: newRequest.Id];
        system.assertNotEquals('Failed', newRequest.Status__c);
    }

    @isTest
    static void test_JIRAConnector_addCommentWithAuditLogs_Failure()
    {
        Admin_Access_Request__c newRequest = getRecord();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new test_failure_mock());
        JIRAConnector.addCommentWithAuditLogs(newRequest.id);
        Test.stopTest();

        newRequest = [Select id, Status__c, Error_Message__c from Admin_Access_Request__c Where Id =: newRequest.Id];
        system.assertEquals('Failed', newRequest.Status__c);
    }

    /////////////////////// updateTicketToComplete

    @isTest
    static void test_JIRAConnector_updateTicketToComplete_Success()
    {
        Admin_Access_Request__c newRequest = getRecord();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new test_success_mock());
        JIRAConnector.updateTicketToComplete(newRequest.id);
        Test.stopTest();

        newRequest = [Select id, Status__c, Error_Message__c from Admin_Access_Request__c Where Id =: newRequest.Id];
        system.assertNotEquals('Failed', newRequest.Status__c);
    }

    @isTest
    static void test_JIRAConnector_updateTicketToComplete_Failure()
    {
        Admin_Access_Request__c newRequest = getRecord();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new test_failure_mock());
        JIRAConnector.updateTicketToComplete(newRequest.id);
        Test.stopTest();

        newRequest = [Select id, Status__c, Error_Message__c from Admin_Access_Request__c Where Id =: newRequest.Id];
        system.assertEquals('Failed', newRequest.Status__c);
    }

    /////////////////////// FirefighterAccessController

    @isTest
    static void test_FirefighterAccessController()
    {
        Admin_Access_Request__c newRequest = getRecord();

        FirefighterAccessController.JiraConnector(test_FirefighterAccessController_helper(newRequest.Id, 'validateTicket'));
        FirefighterAccessController.JiraConnector(test_FirefighterAccessController_helper(newRequest.Id, 'createSubTask'));
        FirefighterAccessController.JiraConnector(test_FirefighterAccessController_helper(newRequest.Id, 'addCommentWithAuditLogs'));
        FirefighterAccessController.JiraConnector(test_FirefighterAccessController_helper(newRequest.Id, 'updateTicketToComplete'));

        newRequest = [Select id, Status__c, Error_Message__c from Admin_Access_Request__c Where Id =: newRequest.Id];
        system.assertNotEquals(null, newRequest.Status__c);
    }

    static List<FirefighterAccessController.flowInput> test_FirefighterAccessController_helper(string recordId, string action)
    {
        FirefighterAccessController.flowInput flowInput = new FirefighterAccessController.flowInput();
        flowInput.recordId = recordId;
        flowInput.action = action;
        return new List<FirefighterAccessController.flowInput>{flowInput};
    }

    // helper classes for mock callout response

    public class test_success_mock implements HttpCalloutMock
    {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            // this sample json covers all required variables to process different jira callouts and parsing
            res.setBody('{"id":"123","key":"TEST-1","fields":{"customfield_15564":{"self":"testUrl","value":"Support","id": "321"},"project":{"id":"222"}}}');
            res.setStatusCode(200);
            return res;
        }
    }

    public class test_failure_mock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setBody('{"error": "testError"}');
            res.setStatusCode(400);
            return res;
        }
    }

    // helper methods

    private static Admin_Access_Request__c getRecord()
    {
        return [Select id from Admin_Access_Request__c Limit 1];
    }

}