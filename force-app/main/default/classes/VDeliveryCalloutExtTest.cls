@isTest
public with sharing class VDeliveryCalloutExtTest {
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

		m = new VDispatchdeliveryCalloutMock(
			statusCode,
			status,
			VTestUtil.DISPATCH_DELIVERY_MESSAGE
		);

		Test.setMock(HttpCalloutMock.class, m);

		
	}

	@isTest
	static void testDoCallout() {
		testSetup(200, 'OK');

		cse = VTestUtil.createCase();
		insert cse;
		VDeliveryCalloutExt controller = new VDeliveryCalloutExt(new ApexPages.StandardController(cse));

		Test.startTest();
		System.assertNotEquals(null, controller.doCallout());
		Test.stopTest();

	}

	@isTest
	static void testException() {
		testSetup(404, 'Not Found');

		cse = VTestUtil.createCase();
		insert cse;
		VDeliveryCalloutExt controller = new VDeliveryCalloutExt(new ApexPages.StandardController(cse));

		Test.startTest();
		System.assertEquals(null, controller.doCallout());
		Test.stopTest();
	}

	@isTest
	static void testControllerException() {
		testSetup(200, 'OK');

		cse = VTestUtil.createCase();
		insert cse;

		VDeliveryCalloutExt controller = new VDeliveryCalloutExt(new ApexPages.StandardController(cse));
		controller.throwTestException = true;
		
		Test.startTest();
		System.assertEquals(null, controller.doCallout());
		Test.stopTest();
	}

	@isTest
	static void testMissingCase() {
		cse = VTestUtil.createCase();
		
		VDeliveryCalloutExt controller = new VDeliveryCalloutExt(new ApexPages.StandardController(cse));

		Test.startTest();
		System.assertEquals(null, controller.doCallout());
		Test.stopTest();
	}
}