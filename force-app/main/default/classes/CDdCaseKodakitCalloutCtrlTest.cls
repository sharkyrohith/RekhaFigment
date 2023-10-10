@isTest
public class CDdCaseKodakitCalloutCtrlTest {
	private static vCS__c testSettings;
    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';

    static {
        TEST_ROLE_ID = [SELECT Id FROM UserRole WHERE DeveloperName = 'COO'].Id;
    }

    /**
	* @description Prepare and return the test running user
	*/
    private static User getTestRunUser() {
        User testRunUser = null;
        for (User u : [SELECT Id FROM User WHERE UserName = :TEST_DD_RUN_USERNAME]){
            testRunUser = u;
        }
        if (testRunUser == null){
            testRunUser = TDdAccountFactory.createUsers(1, null, TEST_ROLE_ID)[0];
            testRunUser.Username = TEST_DD_RUN_USERNAME;
        }
        return testRunUser;
    }

    static void testSetup() {
        System.runAs(getTestRunUser()){
            testSettings = VTestUtil.createVeltigSettings();
            testSettings.APICalloutToKodakit__c = true;
            insert testSettings;

            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
            validation.Bypass_Case_Validations__c  = true;
            insert validation;
        }
	}

    @isTest
    static void testKodakitCalloutCtrl (){
        System.runAs(getTestRunUser()){
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
                                     AccountId = testAcc.Id,
                                     Photo_Provider__c = 'Kodakit');
            insert testCase;

            Test.setCurrentPageReference(new PageReference('Page.PDdCaseKodakitCallout'));
            System.currentPageReference().getParameters().put('id', testCase.Id);
            ApexPages.StandardController controller = new ApexPages.StandardController(testCase);
            CDdCaseKodakitCalloutCtrl ctrl = new CDdCaseKodakitCalloutCtrl(controller);
            PageReference pg = ctrl.makeKodakitCallout();

            testCase.Kodakit_Error__c = 'ERR';
            update testCase;
            ctrl.makeKodakitCallout();
            Test.stopTest();

            Case updatedCase = (Case) [SELECT Id, Kodakit_Event__c FROM Case WHERE Id =: testCase.Id];
            System.assertEquals('OK', updatedCase.Kodakit_Event__c , 'Kodakit Event expected to be OK');
        }
    }
}