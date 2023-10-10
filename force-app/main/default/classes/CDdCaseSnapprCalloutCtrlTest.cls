@isTest
public class CDdCaseSnapprCalloutCtrlTest {
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
    static void testSnapprCalloutCtrl (){
        System.runAs(getTestRunUser()){
            testSetup();

            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('mockResponse_Snappr_Success');
            mock.setStatusCode(201);
            mock.setHeader('Content-Type', 'application/json');
            Test.setMock(HttpCalloutMock.class, mock);

            Test.startTest();
            Account testAcc = VTestUtil.createAccount('Test Acc', true);
            testAcc.BillingCountryCode = 'US';
            insert testAcc;
            Contact testCnt = VTestUtil.createContact('Test First', 'Test Last', testAcc);
            testCnt.Phone = '(213) 555-1234';
            insert testCnt;
            // create Snappr_API_Setting__mdt instance for US

            Snappr_API_Setting__mdt snpmdt = new Snappr_API_Setting__mdt(MasterLabel='US',DeveloperName='US', Region__c= 'US', Named_Credential__c='Snappr_US',Bookings_EndPoint__c='/bookings/',
                                                                         Shoot_Type__c='food',Duration__c=60,Gallery_URL_PostFix__c='/gallery?downloadingGallery=true',Bookings_URL_Prefix__c='https://app.snappr.co/partner/doordash-ca/bookings/',
                                                                         Photoshoot_Provider__c='Snappr',Merchant_Email_Template_Id__c='00X2L0000015y9w',Snappr_Email_Template_Id__c='00X2L0000015y9x',
                                                                         Org_Wide_Email_Address_Id__c='0D21a00000007BK',Snappr_Support_Contact_Id__c=testCnt.Id);
            Map<string,Snappr_API_Setting__mdt> regionKeyDataMap = new Map<string,Snappr_API_Setting__mdt>();
            regionKeyDataMap.put(snpmdt.Region__c, snpmdt);
            CDdSnapprAPIHandler.regionKeyMap = regionKeyDataMap;
            CDdSnapprAPIHandler.regionalSetting = snpmdt;

            Id photoRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Photoshoot Processing').getRecordTypeId();
            Case testCase = new Case(RecordTypeId = photoRecTypeId,
                                     Subject = 'Test Case for Snappr',
                                     Status = 'New',
                                     Origin = 'Photoshoot Request',
                                     Address_Latitude__c = 1.000000,
                                     Address_Longitude__c = 2.000000,
                                     Address_UTC_Offset__c = -11,
                                     Photoshoot_Date__c = Date.today(),
                                     Photoshoot_Time__c = '5:00 PM',
                                     ContactId = testCnt.Id,
                                     AccountId = testAcc.Id,
                                     OwnerId = Label.User_DoorDash_ApexAdmin,
                                     Photo_Provider__c = 'Snappr');
            insert testCase;

            Test.setCurrentPageReference(new PageReference('Page.PDdCaseSnapprCallout'));
            System.currentPageReference().getParameters().put('id', testCase.Id);
            ApexPages.StandardController controller = new ApexPages.StandardController(testCase);
            CDdCaseSnapprCalloutCtrl ctrl = new CDdCaseSnapprCalloutCtrl(controller);
            PageReference pg = ctrl.makeSnapprCallout();

            testCase.Kodakit_Error__c = 'ERR';
            update testCase;
            ctrl.makeSnapprCallout();
            Test.stopTest();

            Case updatedCase = (Case) [SELECT Id, Kodakit_Event__c FROM Case WHERE Id =: testCase.Id];
            System.assertEquals('Booking Created', updatedCase.Kodakit_Event__c , 'Kodakit Event expected to be Booking Created');
        }
    }

    @isTest
    static void testOCUSCalloutMethod(){
        Case testCase = createOCUSTestData()[0];
        String responseBody = '{"data":{"type":"mission","id":"53f96fba-40e6-11ec-b9e5-0eb76324be16","attributes":{"reference_id":"53f96fba-40e6-11ec-b9e5-0eb76324be16"}}}';
        CDdRestJSONObj.OCUSMissionResponse res = (CDdRestJSONObj.OCUSMissionResponse)JSON.deserialize(responseBody, CDdRestJSONObj.OCUSMissionResponse.class);
        res.data.attributes.internal_reference = testCase.Id;
        CDdMockHttpResponse mock = new CDdMockHttpResponse(JSON.serialize(res));
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        Test.setCurrentPageReference(new PageReference('Page.PDdCaseSnapprCallout'));
		System.currentPageReference().getParameters().put('id', testCase.Id);
        ApexPages.StandardController controller = new ApexPages.StandardController(testCase);
        CDdCaseSnapprCalloutCtrl ctrl = new CDdCaseSnapprCalloutCtrl(controller);
        PageReference pg = ctrl.makeSnapprCallout();
        Test.stopTest();

        Case updatedCase = [SELECT Id, Kodakit_Job_Id__c FROM Case WHERE Id =: testCase.Id];
        System.assertEquals('53f96fba-40e6-11ec-b9e5-0eb76324be16', updatedCase.Kodakit_Job_Id__c , 'OCUS Id should be updated on case');
    }

    @isTest
    static void testOCUSCalloutMethodError(){
        Case testCase = createOCUSTestData()[0];
        Test.startTest();
        Test.setCurrentPageReference(new PageReference('Page.PDdCaseSnapprCallout'));
		System.currentPageReference().getParameters().put('id', testCase.Id);
        ApexPages.StandardController controller = new ApexPages.StandardController(testCase);
        CDdCaseSnapprCalloutCtrl ctrl = new CDdCaseSnapprCalloutCtrl(controller);
        testCase.Kodakit_Job_Id__c = 'ID';
        update testCase;
        ctrl.makeSnapprCallout();
        Test.stopTest();
        List<Apexpages.Message> msgs = ApexPages.getMessages();
        boolean b = false;
        for(Apexpages.Message msg:msgs){
            if (msg.getDetail().contains('You do not need to schedule another photoshoot')) b = true;
        }
        system.assert(b);//Assert the Page Message was Properly Displayed
    }

    private static List<Case> createOCUSTestData(){
        CDdContactTriggerHelper.insertCampaign();
        List<Account> accountsToInsert = new List<Account>();

        Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
        validation.Bypass_Opportunity_Validations__c = true;
        validation.Bypass_Case_Validations__c = true;
        insert validation;

        List<Account> acclist = CDdTestDataFactory.createSObjectList('Account', 1, false);
        for (Integer i = 0; i < acclist.size(); i++) {
            acclist[i].Name = 'Test Acc';
            acclist[i].BillingStreet = 'Rotebühlstraße 121';
            acclist[i].BillingCity = 'Stuttgart';
            acclist[i].BillingPostalCode = '70178';
            acclist[i].BillingCountryCode = 'DE';
            acclist[i].BillingCountry = 'Germany';
            acclist[i].Legal_Business_Name__c = 'German';
            acclist[i].Market_Area__c = 'Northern California - East Bay';
            acclist[i].Business_ID__c = 123456;
            acclist[i].Language__c = 'German';
            acclist[i].RecordTypeId = CDdRecordTypeAccount.prospect();
            accountsToInsert.add(acclist[i]);
        }
        insert accountsToInsert;

        Contact con1 = (Contact)CDdTestDataFactory.createSObject('Contact', new Map<String,Object>{
            'AccountId' => accountsToInsert[0].Id
                }, false);
        insert con1;

        Opportunity opp2 = TDdOpportunityFactory.createOpportunity('CloseWonOpp', con1.AccountId, con1.id, 'Closed Won');
        opp2.Tablet_Received_Date__c = null;
        opp2.recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('ML_Inside_Sales').getRecordTypeId();
        insert opp2;

        List<Case> cslist1 = CDdTestDataFactory.createSObjectList('Case', 1, false);
        for(Integer i = 0; i < 1; i++){
            cslist1[i].Store_ID__c = '' +i;
            cslist1[i].BusinessHours =null;
            cslist1[i].Subject = 'setAccountIdUpdateTest'+i;
            cslist1[i].RecordTypeId = CDdRecordTypeCase.photoshootProcessing();
            cslist1[i].Photo_Provider__c = 'OCUS';
            cslist1[i].Photo_Review_Notes__c = 'OCUS';
            cslist1[i].Language__c = 'German';
            cslist1[i].Menu_Preview_Links__c = 'Menu preview links';
            cslist1[i].AccountId = accountsToInsert[0].Id;
            cslist1[i].Opportunity_Name__c = opp2.Id;
        }
        insert cslist1;
        return cslist1;
    }
}