@isTest
public class CDdCheckrClientStatusResultCtrlTest {
    public static void setup() {
        vCS__c s = VTestUtil.createVeltigSettings();
        insert s;
    }
    
    static testMethod void testResultSuccess() {
        setup();
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('mockResponse_checkr_status_success');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.startTest();
        PageReference pageRef = Page.PDdCheckrClientStatusResult;
		Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('email', 'bcolvin22@gmail.com');
        CDdCheckrClientStatusResultCtrl ctrl = new CDdCheckrClientStatusResultCtrl();
		ctrl.getCheckrStatus();
        
        System.assert(!ctrl.hasError);
        System.assertEquals('clear', ctrl.bgStatus);
        Test.stopTest();
    }
    
    static testMethod void testResultFailure() {
        setup();
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('mockResponse_checkr_status_failure');
        mock.setStatusCode(400);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.startTest();
        PageReference pageRef = Page.PDdCheckrClientStatusResult;
		Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('email', 'bcolvin22@gmail.com');
        CDdCheckrClientStatusResultCtrl ctrl = new CDdCheckrClientStatusResultCtrl();
		ctrl.getCheckrStatus();
        
        System.assertEquals('Dasher cannot be found with that email address', ctrl.errorMsg);
        System.assert(ctrl.hasError);
        Test.stopTest();
    }
    
}