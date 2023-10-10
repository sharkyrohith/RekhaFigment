/**
 * 
 * @author: Tia Xuan
 * @date: 2020-07
 * @description Test class for CDdCommunityPostChatController
 * 
 */
@isTest
public class CDdCommunityPostChatControllerTest {

    public class CDdSalesforceValidMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"records": [{"caseId":"test", "Case": {"OwnerId":"test", "CreatedDate": ' 
                        + '"2012-04-24T10:39:00.000+0000"'
                        + ',"CaseOriginFormatted__c":"Chat" }}]}');
            return res;
        }
    }
  
    @isTest static void testPostchat() {

        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new CDdSalesforceValidMock());

        PageReference pageRef = Page.PDdCommunityPostChat;
        pageRef.getParameters().put('chatKey', 'test');
        pageRef.getParameters().put('language', 'en_US');
        Test.setCurrentPage(pageRef);

        CDdCommunityPostChatController ctrl = new CDdCommunityPostChatController();
        ctrl.goToSurvey();

        Test.stopTest();
        
    }
}