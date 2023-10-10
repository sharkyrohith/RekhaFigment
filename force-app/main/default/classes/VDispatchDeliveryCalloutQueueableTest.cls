@isTest
public with sharing class VDispatchDeliveryCalloutQueueableTest {
	private static VDispatchdeliveryCalloutMock m;
	private static Case cse;
	private static Account testAccount;
    private static vCS__c s;
    // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
    private static Dispatch_Settings__c setting;

	static void testSetup(Integer statusCode, String status, Boolean useERS) {
		s = VTestUtil.createVeltigSettings();
        insert s;

        // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
        setting = VTestUtil.createDispatchSettings();
        setting.Use_ERS_API__c = useERS;
        insert setting;

		Trigger_Control_Panel__c tcp = VTestUtil.createTCPSettings();
		insert tcp;
        
        String msg = VTestUtil.DISPATCH_DELIVERY_MESSAGE;
        if (useERS){
            msg = VTestUtil.ERS_DISPATCH_DELIVERY_MESSAGE;
        }

		m = new VDispatchdeliveryCalloutMock(
			statusCode,
			status,
			msg
		);

		Test.setMock(HttpCalloutMock.class, m);

		
	}

	@isTest
	static void testExecuteWithDeliveryNoCustomer() {
		testSetup(200, 'OK', false);

		cse = VTestUtil.createCase();
		cse.Customer_Type__c = 'Consumer';
		insert cse;

		VDispatchDeliveryCalloutQueueable q = new VDispatchDeliveryCalloutQueueable(new List<Case> { cse }, true, true, true);
		q.execute(null);

	}

	@isTest
	static void testExecuteWithDeliveryNoDasher() {
		testSetup(200, 'OK', false);

		cse = VTestUtil.createCase();
		cse.Customer_Type__c = 'Dasher';
		insert cse;

		Test.startTest();
		VDispatchDeliveryCalloutQueueable q = new VDispatchDeliveryCalloutQueueable(new List<Case> { cse }, true, true, true);
		q.execute(null);
		Test.stopTest();

	}

	@isTest
	static void testExecuteWithDeliveryNoMerchant() {
		testSetup(200, 'OK', true);

		cse = VTestUtil.createCase();
		cse.Customer_Type__c = 'Merchant';
		insert cse;

		Test.startTest();
		VDispatchDeliveryCalloutQueueable q = new VDispatchDeliveryCalloutQueueable(new List<Case> { cse }, true, true, true);
		q.execute(null);
		Test.stopTest();

	}

	@isTest
	static void testExecuteWithoutDeliveryNo() {
		testSetup(200, 'OK', false);

		cse = VTestUtil.createCase();
        cse.DeliveryNo__c = null;
        // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
        cse.DeliveryUUID__c = null;
		cse.Customer_Type__c = 'Merchant';
		cse.ChatKey__c = 'Test';
		insert cse;

		Test.startTest();
		VDispatchDeliveryCalloutQueueable q = new VDispatchDeliveryCalloutQueueable(new List<Case> { cse }, true, true, true);
		q.execute(null);
		Test.stopTest();
	}

	@isTest
	static void testWithException() {
		testSetup(200, 'OK', false);

		cse = VTestUtil.createCase();
		cse.Customer_Type__c = 'Merchant';
		insert cse;

		Test.startTest();
		VDispatchDeliveryCalloutQueueable q = new VDispatchDeliveryCalloutQueueable(new List<Case> { cse }, true, true, true);
		q.throwTestException = true;
		q.execute(null);
		Test.stopTest();
	}
	@isTest
    static void testExecuteDisPatchUpdateAPICustomer() {
		testSetup(200, 'OK', true);

		Account acct = VTestUtil.createAccount('Test Account', true);
        acct.Deck_Rank__c = 'Queen';
        insert acct; 

		Contact ctc = VTestUtil.createContact('Test', 'tst', acct);
        insert ctc;

		cse = VTestUtil.createCase();
        cse.Customer_Type__c = 'Consumer';
        cse.DeliveryUUID__c =null;
        cse.DeliveryNo__c=null;
        cse.contactId=ctc.Id;
		
		insert cse;

		Case c=[select id,Customer_Type__c,ContactEmail,ContactPhone,DeliveryUUID__c,DeliveryNo__c, Origin, Platform__c , Description, Subject from case where id =:cse.Id limit 1];
		Test.startTest();
        VDispatchDeliveryCalloutQueueable q = new VDispatchDeliveryCalloutQueueable(new List<Case> { c }, true, true, true);
		q.execute(null);
		Test.stopTest();
		Case clist = [select Id, accountid, contactid from case where Id =: c.Id];
		System.assert(String.isnotBlank(clist.accountid) == true, 'account populated via Dispatch upsert');
	}
}