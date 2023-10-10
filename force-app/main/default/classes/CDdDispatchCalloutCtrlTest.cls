/**
 * 
 * @author: Tia Xuan
 * @date: 2019-05
 * @description Test class for CDdDispatchCalloutCtrl
 * 
 */
@isTest
public class CDdDispatchCalloutCtrlTest {
	private static Case cse;
	private static Account testAccount;
    private static vCS__c s;
    private static Dispatch_Settings__c setting;
    private static Country_Phone_Format_Mapping__c countryPhoneMapping;
    @TestSetup
    static void makeData(){

        List<Country_Phone_Format_Mapping__c> countryPhoneMappingList = new List<Country_Phone_Format_Mapping__c>(); 

        countryPhoneMapping = new Country_Phone_Format_Mapping__c();
        countryPhoneMapping.name = CDdSupportConstants.COUNTRY_NAME_GERMANY;
        countryPhoneMapping.Country_Short_Name__c = CDdSupportConstants.COUNTRY_SHORT_NAME_GERMANY;
        countryPhoneMapping.Phone_Format__c = CDdSupportConstants.FORMATTED_INTERNATIONAL_NUMBER;
        countryPhoneMappingList.add(countryPhoneMapping);
        
        countryPhoneMapping = new Country_Phone_Format_Mapping__c();
        countryPhoneMapping.name = CDdSupportConstants.COUNTRY_NAME_JAPAN;
        countryPhoneMapping.Country_Short_Name__c = CDdSupportConstants.COUNTRY_SHORT_NAME_JAPAN;
        countryPhoneMapping.Phone_Format__c = CDdSupportConstants.NATIONAL_NUMBER;
        countryPhoneMappingList.add(countryPhoneMapping);
        
        countryPhoneMapping = new Country_Phone_Format_Mapping__c();
        countryPhoneMapping.name = CDdSupportConstants.COUNTRY_NAME_USA;
        countryPhoneMapping.Country_Short_Name__c = CDdSupportConstants.COUNTRY_SHORT_NAME_USA;
        countryPhoneMapping.Phone_Format__c = CDdSupportConstants.INTERNATIONAL_NUMBER;
        countryPhoneMappingList.add(countryPhoneMapping);
        
        countryPhoneMapping = new Country_Phone_Format_Mapping__c();
        countryPhoneMapping.name = CDdSupportConstants.COUNTRY_NAME_AUSTRALIA;
        countryPhoneMapping.Country_Short_Name__c = CDdSupportConstants.COUNTRY_SHORT_NAME_AUSTRALIA;
        countryPhoneMapping.Phone_Format__c = CDdSupportConstants.FORMATTED_NATIONAL_NUMBER;
        countryPhoneMappingList.add(countryPhoneMapping);

        insert countryPhoneMappingList;

    }
    /**
     * @description setting up settings and mock call out
     */
	static void testSetup(Integer statusCode, String status, Boolean useERS) {
		s = VTestUtil.createVeltigSettings();
        insert s;

        // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
        setting = VTestUtil.createDispatchSettings();
        setting.Use_ERS_API__c = useERS;
        setting.Dispatch_ERS_Endpoint__c = 'test';
        setting.Dispatch_ERS_Token__c = 'test';
		insert setting;

		Trigger_Control_Panel__c tcp = VTestUtil.createTCPSettings();
		insert tcp;

        String msg = VTestUtil.DISPATCH_DELIVERY_MESSAGE;
        if (useERS){
            msg = VTestUtil.ERS_DISPATCH_DELIVERY_MESSAGE;
        }

        VDispatchdeliveryCalloutMock mock = new VDispatchdeliveryCalloutMock(
			statusCode,
			status,
			msg
		);
        Test.setMock(HttpCalloutMock.class, mock);
	}

    /**
     * @description positive scenario test
     */
	@isTest
	static void testExecute() {
		testSetup(200,'OK', true);

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
        try{
			CDdDispatchCalloutCtrl.makeDeliveryCallout(cse.Id);
        } catch(Exception e) {
            System.Assert(e.getMessage() == 'Test');
        }
		Test.stopTest();
	}

     /**
     * @description failure scenario test
     */
	@isTest
	static void testFailure() {
        testSetup(401,'OK', false);

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
		try{
			CDdDispatchCalloutCtrl.makeDeliveryCallout(cse.Id);
        } catch(Exception e) {
            System.Assert(e.getTypeName() == 'System.AuraHandledException','An exception was not thrown');
        }		
        Test.stopTest();
	}
    
    /**
     * @description failure scenario test 2
     */
	@isTest
	static void testFailure2() {
        testSetup(401,'OK', false);

		cse = VTestUtil.createCase();
		cse.Customer_Type__c = 'Consumer';
        cse.Issue__c = 'Other';
        cse.Issue_Type__c = 'Other - CX';
		insert cse;
		cse.Status = 'Solved';
        cse.Resolution__c = 'Other';
        cse.Resolution_Type__c = 'Other - CX';
        cse.DeliveryNo__c = null;
        // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
        cse.DeliveryUUID__c = null;
		update cse;

		Test.startTest();
		try{
			CDdDispatchCalloutCtrl.makeDeliveryCallout(cse.Id);
        } catch(Exception e) {
            System.Assert(e.getTypeName() == 'System.AuraHandledException','An exception was not thrown');
        }	
        
        try{
			CDdDispatchCalloutCtrl.makeDeliveryCallout('12534352');
        } catch(Exception e) {
            System.Assert(e.getTypeName() == 'System.AuraHandledException','An exception was not thrown');
        }	
        Test.stopTest();
	}

    /**
     * @description positive scenario with new ERS endpoint test
     */
	@isTest
	static void testExecuteERS() {
		testSetup(200, 'OK', true);
    
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
        try{
			CDdDispatchCalloutCtrl.makeDeliveryCallout(cse.Id);
        } catch(Exception e) {
            System.Assert(e.getMessage() == 'Test');
        }
		Test.stopTest();
	}

     /**
     * @description failure scenario with new ERS endpoint test
     */
	@isTest
	static void testFailureERS() {
        testSetup(401, 'OK', true);

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
		try{
			CDdDispatchCalloutCtrl.makeDeliveryCallout(cse.Id);
        } catch(Exception e) {
            System.Assert(e.getTypeName() == 'System.AuraHandledException','An exception was not thrown');
        }		
        Test.stopTest();
	}
    
    /**
     * @description failure scenario with new ERS endpoint test 2
     */
	@isTest
	static void testFailureERS2() {
        testSetup(401, 'OK', true);

		cse = VTestUtil.createCase();
		cse.Customer_Type__c = 'Consumer';
        cse.Issue__c = 'Other';
        cse.Issue_Type__c = 'Other - CX';
		insert cse;
		cse.Status = 'Solved';
        cse.Resolution__c = 'Other';
        cse.Resolution_Type__c = 'Other - CX';
        cse.DeliveryNo__c = null;
        // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
        cse.DeliveryUUID__c = null;
		update cse;

		Test.startTest();
		try{
			CDdDispatchCalloutCtrl.makeDeliveryCallout(cse.Id);
        } catch(Exception e) {
            System.Assert(e.getTypeName() == 'System.AuraHandledException','An exception was not thrown');
        }	
        
        try{
			CDdDispatchCalloutCtrl.makeDeliveryCallout('12534352');
        } catch(Exception e) {
            System.Assert(e.getTypeName() == 'System.AuraHandledException','An exception was not thrown');
        }	
        Test.stopTest();
	}

    @isTest
    static void testGetFormatedInternationalNumber() {
        String phoneNumber; 
        CDdDispatchDeliveryInformation.DispatchPhone dispatchPhone = getDispatchPhone((CDdSupportConstants.COUNTRY_SHORT_NAME_GERMANY));
        
        test.startTest();
        phoneNumber = CDdDispatchDeliveryInformation.getPhoneNumber(null, dispatchPhone);
        test.stopTest();

        system.assertEquals('+49 123 45678901', phoneNumber, 'Incorrect format received');

    }
    @isTest
    static void testGetFormattedNationalNumber() {
        String phoneNumber; 
        
        CDdDispatchDeliveryInformation.DispatchPhone dispatchPhone = getDispatchPhone((CDdSupportConstants.COUNTRY_SHORT_NAME_AUSTRALIA));
        
        test.startTest();
        phoneNumber = CDdDispatchDeliveryInformation.getPhoneNumber(null, dispatchPhone);
        test.stopTest();

        system.assertEquals('123 45678901', phoneNumber, 'Incorrect format received');

    }
    @isTest
    static void testGetInternationalNumber() {
        String phoneNumber; 

        CDdDispatchDeliveryInformation.DispatchPhone dispatchPhone = getDispatchPhone((CDdSupportConstants.COUNTRY_SHORT_NAME_USA));
        
        test.startTest();
        phoneNumber = CDdDispatchDeliveryInformation.getPhoneNumber(null, dispatchPhone);
        test.stopTest();

        system.assertEquals('+4912345678901', phoneNumber, 'Incorrect format received');

    }
    @isTest
    static void testGetNationalNumber() {
        String phoneNumber; 
        CDdDispatchDeliveryInformation.DispatchPhone dispatchPhone = getDispatchPhone((CDdSupportConstants.COUNTRY_SHORT_NAME_JAPAN));

        test.startTest();
        phoneNumber = CDdDispatchDeliveryInformation.getPhoneNumber(null, dispatchPhone);
        test.stopTest();

        system.assertEquals('12345678901', phoneNumber, 'Incorrect format received');

    }
    /**
     * @description There are no failures when updating Merchant records dispatch callout happens. BIZS-2692
     */
    @isTest
    static void testDispatchRecordService() {
	testSetup(200,'OK', true);

        VDeliveryInformation info = VDeliveryInformation.deserialize(VTestUtil.DISPATCH_DELIVERY_MESSAGE);
        info.merchantIsPartner = false;

        Test.startTest();
        CDdDispatchRecordService testController = new CDdDispatchRecordService();
        testController.upsertDeliveryInfo( new List<VDeliveryInformation> { info } );
	Test.stopTest();

        List<Apex_Log__c> logList = [SELECT Id, Log__c FROM Apex_Log__c WHERE createddate = today AND object__c = 'CDdDispatchRecordService' LIMIT 1];
        system.assert( logList.isEmpty() );
    }

    public static CDdDispatchDeliveryInformation.DispatchPhone getDispatchPhone(String countryShortName) {
        CDdDispatchDeliveryInformation.DispatchPhone dispatchPhone = new CDdDispatchDeliveryInformation.DispatchPhone();
        dispatchPhone.countryCode = '49';
        dispatchPhone.countryShortname = countryShortName;
        dispatchPhone.formattedInternationalNumber = '+49 123 45678901';
        dispatchPhone.formattedNationalNumber = '123 45678901';
        dispatchPhone.internationalNumber = '+4912345678901';
        dispatchPhone.nationalNumber = '12345678901';

        return dispatchPhone;
    }

}