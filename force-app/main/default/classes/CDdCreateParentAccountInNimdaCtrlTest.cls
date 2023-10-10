@isTest
public class CDdCreateParentAccountInNimdaCtrlTest {    
    
    public static void setup() {
        vCS__c s = VTestUtil.createVeltigSettings();
		insert s;
    }
    
    static testMethod void testBusinessEndpointSuccess() {
        setup();
        Account acct = VTestUtil.createAccount('Test Account');
        acct.Description = 'This is a test opportunity moving from SFDC to ddware';
        upsert acct;
        String acctId = acct.Id;
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('mockResponse_DSJ_business_success');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        
        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.startTest();
        Test.setCurrentPageReference(new PageReference('Page.PDdCreateParentAccountInNimda')); 
		System.currentPageReference().getParameters().put('id', acctId);
        ApexPages.StandardController controller = new ApexPages.StandardController(acct);
        CDdCreateParentAccountInNimdaCtrl ctrl = new CDdCreateParentAccountInNimdaCtrl(controller);
        PageReference pg = ctrl.createBusiness();
        System.assert(String.isBlank(ctrl.errorMsg));
        Test.stopTest();
    }
    
    static testMethod void testBusinessEndpointFailure() {
        setup();
        Account acct = new Account();
        String acctId = acct.Id;
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('mockResponse_DSJ_business_failure');
        mock.setStatusCode(400);
        mock.setHeader('Content-Type', 'application/json');
        
        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.startTest();
        Test.setCurrentPageReference(new PageReference('Page.PDdCreateParentAccountInNimda')); 
		System.currentPageReference().getParameters().put('id', acctId);
        ApexPages.StandardController controller = new ApexPages.StandardController(acct);
        CDdCreateParentAccountInNimdaCtrl ctrl = new CDdCreateParentAccountInNimdaCtrl(controller);
	    PageReference pg = ctrl.createBusiness();
        
        System.assert(ctrl.errorMsg.equals('ERROR: Account passed is not valid! Make sure you pass a valid Account id!'));
        Test.stopTest();
    }
}