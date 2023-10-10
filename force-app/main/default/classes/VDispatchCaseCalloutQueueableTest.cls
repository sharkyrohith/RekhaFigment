@isTest
public with sharing class VDispatchCaseCalloutQueueableTest {
	private static VDispatchdeliveryCalloutMock m;
	private static Case cse;
	private static Account testAccount;
    private static vCS__c s;
    private static Dispatch_Settings__c setting;

	static void testSetup(Integer statusCode, String status) {
		s = VTestUtil.createVeltigSettings();
        insert s;
        
        // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
        setting = VTestUtil.createDispatchSettings();
        insert setting;

		Trigger_Control_Panel__c tcp = VTestUtil.createTCPSettings();
		insert tcp;

		m = new VDispatchdeliveryCalloutMock(
			statusCode,
			status,
			VTestUtil.DISPATCH_DELIVERY_MESSAGE
		);

		Test.setMock(HttpCalloutMock.class, m);
	}

	@isTest
	static void testExecute() {
		testSetup(200, 'OK');

		cse = VTestUtil.createCase();
		cse.Customer_Type__c = 'Consumer';
        cse.Issue__c = 'Other';
        cse.Issue_Type__c = 'Other - CX';
		insert cse;
		cse.Status = 'Solved';
        cse.Resolution__c = 'Other';
        cse.Resolution_Type__c = 'Other - CX';
		update cse;

		Test.startTest();
		VDispatchCaseCalloutQueueable q = new VDispatchCaseCalloutQueueable(new Set<ID>(new List<ID> { cse.Id }), true, true);
		q.execute(null);
		Test.stopTest();

	}

	@isTest
	static void testFailure() {
		testSetup(401, 'OK');

		cse = VTestUtil.createCase();
		cse.Customer_Type__c = 'Consumer';
        cse.Issue__c = 'Other';
        cse.Issue_Type__c = 'Other - CX';
		insert cse;
		cse.Status = 'Solved';
        cse.Resolution__c = 'Other';
        cse.Resolution_Type__c = 'Other - CX';
		update cse;

		Test.startTest();
		VDispatchCaseCalloutQueueable q = new VDispatchCaseCalloutQueueable(new Set<ID>(new List<ID> { cse.Id }), true, true);
		q.execute(null);
		Test.stopTest();
	}
}