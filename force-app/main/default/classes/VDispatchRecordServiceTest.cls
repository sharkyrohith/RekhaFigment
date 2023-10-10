@isTest
public without sharing class VDispatchRecordServiceTest {
	static void testSetup() {
		vCS__c s = VTestUtil.createVeltigSettings();
        insert s;

        // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit 
        Dispatch_Settings__c setting = VTestUtil.createDispatchSettings();
		insert setting;
	}

	@isTest
	static void testAPI() {
		testSetup();

		Case c = VTestUtil.createCase();
		c.RecordTypeId = vCS__c.getInstance().CaseAPIRecordType__c;

		insert c;
	}

	@isTest
	static void testCustomer() {
		testSetup();

		VDeliveryInformation info = VDeliveryInformation.deserialize(VTestUtil.DISPATCH_DELIVERY_MESSAGE);
		info.liveAgentCustomerId = -100;
        info.chatButtonId = '5731a00000005i4';

		VDispatchRecordService svc = new VDispatchRecordService();
		svc.upsertDeliveryInfo(new List<VDeliveryInformation> { info });

		System.assertEquals('Consumer', info.salesforceCase.Customer_Type__c);
	}

	@isTest
	static void testDasher() {
		testSetup();

		VDeliveryInformation info = VDeliveryInformation.deserialize(VTestUtil.DISPATCH_DELIVERY_MESSAGE);
		info.liveAgentDasherId = -100;
        info.chatButtonId = '5731a00000005iJ';

		VDispatchRecordService svc = new VDispatchRecordService();
		svc.upsertDeliveryInfo(new List<VDeliveryInformation> { info });

		System.assertEquals('Dasher', info.salesforceCase.Customer_Type__c);
	}

	@isTest
	static void testMerchant() {
		testSetup();

		VDeliveryInformation info = VDeliveryInformation.deserialize(VTestUtil.DISPATCH_DELIVERY_MESSAGE);
		info.liveAgentMerchantId = -100;
        info.chatButtonId = '5731a00000005iE';

		VDispatchRecordService svc = new VDispatchRecordService();
		svc.upsertDeliveryInfo(new List<VDeliveryInformation> { info });

		System.assertEquals('Merchant', info.salesforceCase.Customer_Type__c);
	}

	@isTest
	static void testNoDeliveryIdCustomer() {
		testSetup();

		Account acc = VTestUtil.createPersonAccount('Test', 'Test');
		acc.CustomerNo__pc = -100;

		insert acc;

		LiveChatTranscript transcript = VTestUtil.createTranscript();
		transcript.CustomerNo__c = -100;
		insert transcript;

		Case c = VTestUtil.createCase();
        c.DeliveryNo__c = null;
        c.DeliveryUUID__c = null;
		c.ChatKey__c = transcript.ChatKey;

		insert c;

		VDispatchRecordService svc = new VDispatchRecordService();
		svc.upsertCasesWithoutDeliveryIds(new Set<String>(new List<String> { c.ChatKey__c }), new List<Case> { c });

		c = [select Id, Customer_Type__c from Case where Id = :c.Id];
		System.assertEquals('Consumer', c.Customer_Type__c);
	}

	@isTest
	static void testNoDeliveryIdDasher() {
		testSetup();

		Account acc = VTestUtil.createPersonAccount('Test', 'Test');
		acc.DasherNo__pc = -100;

		insert acc;

		LiveChatTranscript transcript = VTestUtil.createTranscript();
		transcript.DasherNo__c = -100;
		insert transcript;

		Case c = VTestUtil.createCase();
        c.DeliveryNo__c = null;
        // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit 
        c.DeliveryUUID__c = null;
		c.ChatKey__c = transcript.ChatKey;

		insert c;

		VDispatchRecordService svc = new VDispatchRecordService();
		svc.upsertCasesWithoutDeliveryIds(new Set<String>(new List<String> { c.ChatKey__c }), new List<Case> { c });

		c = [select Id, Customer_Type__c from Case where Id = :c.Id];
		System.assertEquals('Dasher', c.Customer_Type__c);
	}

	@isTest
	static void testNoDeliveryIdMerchant() {
		testSetup();

		Account acc = VTestUtil.createAccount('test');
		acc.Restaurant_ID__c = '-100';

		insert acc;

		LiveChatTranscript transcript = VTestUtil.createTranscript();
		transcript.MerchantNo__c = -100;
		insert transcript;

		Case c = VTestUtil.createCase();
        c.DeliveryNo__c = null;
        // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit 
        c.DeliveryUUID__c = null;
		c.ChatKey__c = transcript.ChatKey;

		insert c;

		VDispatchRecordService svc = new VDispatchRecordService();
		svc.upsertCasesWithoutDeliveryIds(new Set<String>(new List<String> { c.ChatKey__c }), new List<Case> { c });

		c = [select Id, Customer_Type__c from Case where Id = :c.Id];
		System.assertEquals('Merchant', c.Customer_Type__c);
	}

	@isTest
	static void testNoDeliveryIdAllMissing() {
		testSetup();

		LiveChatTranscript transcript = VTestUtil.createTranscript();
		insert transcript;

		Case c = VTestUtil.createCase();
        c.DeliveryNo__c = null;
        // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit 
        c.DeliveryUUID__c = null;
		c.ChatKey__c = transcript.ChatKey;

		insert c;

		VDispatchRecordService svc = new VDispatchRecordService();
		svc.upsertCasesWithoutDeliveryIds(new Set<String>(new List<String> { c.ChatKey__c }), new List<Case> { c });

		c = [select Id, Customer_Type__c from Case where Id = :c.Id];

		// NOTE: The default value for the support record type was set to "None" so that's
		// why I'm checking 'None' here instead of null.
		// JN-NOTE: (09.28.17) Changing this to null now because it is no longer defaulting to 'None'
		System.assertEquals(null, c.Customer_Type__c);
	}


    @isTest
	static void testPhoneNumber() {

        Support_Feature_Flag__c setting = Support_Feature_Flag__c.getInstance();
        setting.Enable_Japan_Dispatch_Phone_Conversion__c = true;
        upsert setting;

		Test.startTest();
        String pNum = VDeliveryInformation.formatPhoneNumber('61123456789', 'AU');
        System.assertEquals('+61 123 456 789', pNum, 'Invalid Australia Phone format');
        pNum = VDeliveryInformation.formatPhoneNumber('611234567890', 'AU');
        System.assertEquals('+61 234 567 890', pNum, 'Invalid Australia Phone format');
        pNum = VDeliveryInformation.formatPhoneNumber('0123456789', 'AU');
        System.assertEquals('+61 123 456 789', pNum, 'Invalid Australia Phone format');


        pNum = VDeliveryInformation.formatPhoneNumber('81120123456', 'JP');
        System.assertEquals('+81 120-123-456', pNum, 'Invalid Japan Phone format');
        pNum = VDeliveryInformation.formatPhoneNumber('81123456789', 'JP');
        System.assertEquals('+81 12-345-6789', pNum, 'Invalid Japan Phone format');
        pNum = VDeliveryInformation.formatPhoneNumber('811234567890', 'JP');
        System.assertEquals('+81 12-3456-7890', pNum, 'Invalid Japan Phone format');
        pNum = VDeliveryInformation.formatPhoneNumber('0120123456', 'JP');
        System.assertEquals('+81 120-123-456', pNum, 'Invalid Japan Phone format');
        pNum = VDeliveryInformation.formatPhoneNumber('0123456789', 'JP');
        System.assertEquals('+81 12-345-6789', pNum, 'Invalid Japan Phone format');
        pNum = VDeliveryInformation.formatPhoneNumber('01234567890', 'JP');
        System.assertEquals('+81 12-3456-7890', pNum, 'Invalid Japan Phone format');

        Test.stopTest();
	}
    
}