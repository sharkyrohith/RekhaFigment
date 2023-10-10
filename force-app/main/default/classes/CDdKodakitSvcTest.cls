@isTest
public class CDdKodakitSvcTest {
    private static vCS__c testSettings;

    static void testSetup() {
        // TODO Add these fields to VTestUtil 
        testSettings = VTestUtil.createVeltigSettings();
        testSettings.APICalloutToKodakit__c = true;
        testSettings.KodakitAPIToken__c = '';
        testSettings.KodakitAPIEndpointURL__c = '';
        insert testSettings;
	}

    @isTest
    static void checkKodakitAPICalloutPass (){
        // TODO  (both test functions), pull objects through SOQL, assert the fields are as expected
        testSetup();

        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('mockResponse_kodakit_success');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        Account testAcc = VTestUtil.createAccount('Test Acc', true);
        testAcc.BillingCountryCode = 'US';
        insert testAcc;
        Contact testCnt = VTestUtil.createContact('Test First', 'Test Last', testAcc);
        testCnt.Phone = '(213) 555-1234';
        insert testCnt;
        
        Id photoRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Photoshoot Processing').getRecordTypeId();
        Case testCase = new Case(RecordTypeId = photoRecTypeId,
                                 Subject = 'Test Case for Kodakit',
                                 Status = 'New',
                                 Origin = 'Photoshoot Request',
                                 Address_Latitude__c = 1.000000,
                                 Address_Longitude__c = 2.000000,
                                 Address_UTC_Offset__c = -11,
                                 Photoshoot_Date__c = Date.today(),
                                 Photoshoot_Time__c = '5:00 PM',
                                 ContactId = testCnt.Id,
                                 AccountId = testAcc.Id);

        Case testCase2 = new Case(RecordTypeId = photoRecTypeId,
                                 Subject = 'Test Case for Kodakit',
                                 Status = 'New',
                                 Origin = 'Photoshoot Request',
                                 Address_Latitude__c = 1.000000,
                                 Address_Longitude__c = 2.000000,
                                 Address_UTC_Offset__c = -11,
                                 Photoshoot_Date__c = Date.today(),
                                 ContactId = testCnt.Id,
                                 AccountId = testAcc.Id);
        insert new List<Case>{ testCase, testCase2 }; 
        Test.stopTest();
    }

    @isTest
    static void checkKodakitAPICalloutFail (){
        testSetup();

        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('mockResponse_kodakit_fail');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        Account testAcc = VTestUtil.createAccount('Test Acc', true);
        testAcc.BillingCountryCode = 'US';
        insert testAcc;
        Contact testCnt = VTestUtil.createContact('Test First', 'Test Last', testAcc);
        testCnt.Phone = '(213) 555-1234';
        insert testCnt;
        
        Id photoRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Photoshoot Processing').getRecordTypeId();
        Case testCase = new Case(RecordTypeId = photoRecTypeId,
                                 Subject = 'Test Case for Kodakit',
                                 Status = 'New',
                                 Origin = 'Photoshoot Request',
                                 Address_Latitude__c = 1.000000,
                                 Address_Longitude__c = 2.000000,
                                 Address_UTC_Offset__c = -11,
                                 Photoshoot_Date__c = Date.today(),
                                 Photoshoot_Time__c = '5:00 PM',
                                 ContactId = testCnt.Id,
                                 AccountId = testAcc.Id);

        insert testCase; 
        Test.stopTest();
    }
}