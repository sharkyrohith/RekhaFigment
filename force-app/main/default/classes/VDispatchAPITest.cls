@isTest
public with sharing class VDispatchAPITest {
	private static VDispatchdeliveryCalloutMock m;
    private static vCS__c s;
    private static Dispatch_Settings__c setting;

	static void testSetup() {
		s = VTestUtil.createVeltigSettings();
        insert s;

        // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
        setting = VTestUtil.createDispatchSettings();
        insert setting;

		Trigger_Control_Panel__c tcp = VTestUtil.createTCPSettings();
		insert tcp;

		m = new VDispatchdeliveryCalloutMock(
			200,
			'OK',
			VTestUtil.DISPATCH_DELIVERY_MESSAGE
		);

		Test.setMock(HttpCalloutMock.class, m);	
	}

	@isTest
	static void testAPI() {
		testSetup();

		Test.startTest();
		VDispatchAPI api = new VDispatchAPI();
		System.assertNotEquals(null, api.getDeliveryInfo(-100, '-100'));
		System.assertNotEquals(null, api.postCase('data'));
		System.assertNotEquals(null, api.updateCase('data', 'cs'));
		Test.stopTest();
	}
}