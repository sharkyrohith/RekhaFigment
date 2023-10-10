// ===========================================================================
// Component: CDdMerchantBotDispatchCalloutTest
// Author: Nayana Kapse
// Purpose: Test class for CDdMerchantBotDispatchCallout
// ===========================================================================
@isTest
public with sharing class CDdMerchantBotDispatchCalloutTest {
    /**
     * @author      Nayana
     * @date        Jan 2022
     * @description Data setup method
     */
	@testSetup
    static void testSetup() {
        vCS__c s = VTestUtil.createVeltigSettings();
        insert s;

        Dispatch_Settings__c setting = VTestUtil.createDispatchSettings();
        insert setting;

        Trigger_Control_Panel__c tcp = VTestUtil.createTCPSettings();
		insert tcp;

        Merchant_Store_Ids__c mId = new Merchant_Store_Ids__c();
        mId.Name ='testMerchntIds';
        mId.Store_Id_1__c ='12345';
        mId.Store_Id_2__c ='5677';
        mId.Store_Id_3__c ='245';
        insert mId;

        Case cse = VTestUtil.createCase();
		cse.Customer_Type__c = 'Merchant';
		insert cse;

        VDispatchdeliveryCalloutMock mock = new VDispatchdeliveryCalloutMock(
			200,
			'OK',
			VTestUtil.DISPATCH_DELIVERY_MESSAGE
		);
        Test.setMock(HttpCalloutMock.class, mock);
    }

     /**
     * @author      Nayana
     * @date        Jan 2022
     * @description Data will be quried once and can be used in test methods
     */
    public class TestContext
    {
        public List<Case> lstCase;
        public TestContext(){
            lstCase = [SELECT Id,AccountId,OwnerId,DeliveryUUID__c FROM Case];
        }
    }

    
	@isTest
	static void testFetchOrderDetails() {
        TestContext context = new TestContext();
        CDdMerchantBotDispatchCallout.DeliveryIdInput objDeliverId = new CDdMerchantBotDispatchCallout.DeliveryIdInput();
        List <CDdMerchantBotDispatchCallout.DeliveryIdInput> lstDeliveryInput = new List<CDdMerchantBotDispatchCallout.DeliveryIdInput>();
        objDeliverId.merchantId = 12345.0;
        objDeliverId.deliveryUUID = context.lstCase[0].DeliveryUUID__c;
        lstDeliveryInput.add(objDeliverId);
        Test.startTest();
        List <CDdMerchantBotDispatchCallout.DeliveryOutput> lstDeliveryOp = CDdMerchantBotDispatchCallout.fetchOrderDetails(lstDeliveryInput);
        Test.stopTest();
        System.assertEquals(false, lstDeliveryOp[0].isPartOfExperiment, 'As exception isPartOfExperiment should be false');
    }

    @isTest
	static void testFetchOrderDetailsNullUUId() {
        CDdMerchantBotDispatchCallout.DeliveryIdInput objDeliverId = new CDdMerchantBotDispatchCallout.DeliveryIdInput();
        List <CDdMerchantBotDispatchCallout.DeliveryIdInput> lstDeliveryInput = new List<CDdMerchantBotDispatchCallout.DeliveryIdInput>();
        objDeliverId.merchantId = null;
        objDeliverId.deliveryUUID = '';
        lstDeliveryInput.add(objDeliverId);
        Test.startTest();
        List <CDdMerchantBotDispatchCallout.DeliveryOutput> lstDeliveryOp = CDdMerchantBotDispatchCallout.fetchOrderDetails(lstDeliveryInput);
        Test.stopTest();
        System.assertEquals(false, lstDeliveryOp[0].isPartOfExperiment, 'As UUID is blank isPartOfExperiment should be false');
    }

    @isTest
	static void testFormatDispatchInfo() {
        VDeliveryInformation vDeliveryInfo = new VDeliveryInformation();
        vDeliveryInfo.dasherFirstName ='Test Dasher';
        vDeliveryInfo.dasherLastName ='Test Dasher LastName';
        vDeliveryInfo.dasherPhoneNumber ='12334567890';
        vDeliveryInfo.merchantId = 12345.0;
        List<String> lstStoreIds = new List<String> {'12345'};
        Test.startTest();
        CDdMerchantBotDispatchCallout.DeliveryOutput deliveryOp = CDdMerchantBotDispatchCallout.formatDispatchInfo(vDeliveryInfo,lstStoreIds);
        Test.stopTest();
        System.assertEquals(true, deliveryOp.isPartOfExperiment, 'As isPartOfExperiment should be true');
    }
}