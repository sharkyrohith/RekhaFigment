/********************************************************************************************************************
* @author Praveen
* @date 1/17/2023
*
* @group Merchant Services
*
* @description test class for CDdMxPosIntegrationRequestProcessor
*
**************************************************************************************************************************************/

@isTest
public with sharing class CDdMxPosIntegrationRequestProcessorTest {
    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    public static final String OPP_NAME_CHILD = 'MxSx_Test_Opp_123';
    public static final String OPP_NAME_PARENT = 'MxSx';
    public static String TEST_MX_ORDER_REQUEST_COUNTRY_CODE = 'US';
    public static String ACCOUNT_RECORD_MARKETPLACE = 'Marketplace';
    public static String ACCOUNT_RECORD_PARENT_ACCOUNT = 'Parent Account';
    public static contact testContact;
    public static final String OPP_OBJECT = 'Opportunity';
    public static final String CONTACT_OBJECT = 'Contact';
    public static final String ORDER_PROTOCOL = CDdMxSxConstants.getEquipmentRequestOrderProtocol();
    public static final String DEFAULT_ORDER_PROTOCOL = 'Tablet (DoorDash Owns)';
    public static final String POS_ORDER_PROTOCOL = 'POS and and Tablet (DoorDash Owns)';
    public static String ACCOUNT_NAME = 'DoorDash';
    public static String POS_INTEGRATION_RECORD_TYPE_ID = CDdMxSxConstants.RECORD_TYPE_ID_CASE_POS_INTEGRATIONS;
    public static String MARKETPLACE_ONBOARDING_RECORDTYPE_ID = CDdMxSxConstants.RECORD_TYPE_ID_CASE_MARKETPLACE_ONBOARDING;
    public static final String TEST_INSTANCE_NAME = 'CDdMxSupportIntegrationRequests';
    public static final String QUERY_LAST_N_DAYS = '10';

    static {
        TEST_ROLE_ID = [SELECT Id FROM UserRole WHERE DeveloperName = 'COO'].Id;
    }
    /**
    * @description Prepare and return the test running user
    */
    private static User getTestRunUser() {
        User testRunUser = null;
        for (User u : [SELECT Id FROM User WHERE UserName = :TEST_DD_RUN_USERNAME]) {
            testRunUser = u;
        }
        if (testRunUser == null) {
            testRunUser = TDdAccountFactory.createUsers(1, null, TEST_ROLE_ID)[0];
            testRunUser.Username = TEST_DD_RUN_USERNAME;
        }
        return testRunUser;
    }
    public static fflib_ApexMocks mocks {get {
        if(mocks == null) {
            mocks = new fflib_ApexMocks();
        }
        return mocks;
    } set;}
    /**
    *@description Initializes the common class MxSxApexMockTestDataFactory to mock mx related object records.
    */
    public static MxSxApexMockTestDataFactory mockTestDataFactory {get {
        if(mockTestDataFactory == null) {
            mockTestDataFactory = new MxSxApexMockTestDataFactory();
        }
        return mockTestDataFactory;
    } set;}

    public static List<Integration_Request__x> posIntegrationRequest{get {
        if(posIntegrationRequest == null) {
            posIntegrationRequest = mockTestDataFactory.posIntegrationRequests;
        }
        return posIntegrationRequest;
    } set;}

    /**
    *@description setup test data.
    */
    @TestSetup
    static void setup() {
        System.runAs(getTestRunUser()) {
            vCS__c testSettings;
            testSettings = VTestUtil.createVeltigSettings();
            testSettings.CaseTrigger__c = true;
            insert testSettings;

            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
            validation.Bypass_Opportunity_Validations__c = true;
            validation.Bypass_Account_Validations__c = true;
            validation.Bypass_Case_Validations__c = true;
            insert validation;

            Test.startTest();
            Feature_Flags__c ftrFlag = Feature_Flags__c.getOrgDefaults();
            ftrFlag.Enable_CPU_Time_Check__c = true;
            ftrFlag.Enable_Debug_Logs__c = true;
            ftrFlag.Enable_Case_Trigger_Optimization__c = true;
            insert ftrFlag;

            Account account = TDdAccountFactory.createAccount(ACCOUNT_RECORD_MARKETPLACE);
            account.Business_ID__c = 1234567;
            account.Restaurant_ID__c = '224455';
            account.Name = ACCOUNT_NAME;
            insert account;
            Account parentAccount = TDdAccountFactory.createAccount(ACCOUNT_RECORD_PARENT_ACCOUNT);
            parentAccount.Business_ID__c = 123456237;
            insert parentAccount;

            Contact contact = TDdAccountFactory.createContacts(1, account.Id)[0];
            insert contact;
        }
    }
    /**
    *@description create new pos integration case if there is no open cases on the account.
    */
    @isTest
    static void testCreateNewPosIntegrationCase(){
        mockPosIntegrationTestData();
        Account act = getaccountbyName(ACCOUNT_NAME);
        test.startTest();
        CDdMxSxIntegrationRequestScheduler process = new CDdMxSxIntegrationRequestScheduler();
        process.execute(null);
        test.stopTest();
        List<Case> cas = [select id from case where AccountId =: act.id and recordtypeId = :POS_INTEGRATION_RECORD_TYPE_ID];
        System.assertEquals(1, cas.size(), 'Pos integration record case count not matching');
    }
    /**
    *@description test If the ob case exist update opportunity order protocol to pos and create new pos integration case.
    */
    @isTest
    static void testUpdateOpportunityToPOS(){
        mockPosIntegrationTestData();
        set<String> onboardingIds = new Set<String>{posIntegrationRequest[0].onboarding_Id__C};
        Account act = getaccountbyName(ACCOUNT_NAME);
        Contact contact = getContactByAccountId(act.Id);
        test.startTest();
        CDdMilestoneTemplate.insertMilestoneTemplates();
        Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
        validation.Bypass_Opportunity_Validations__c = true;
        validation.Bypass_Account_Validations__c = true;
        validation.Bypass_Case_Validations__c = true;
        insert validation;
        Opportunity opp = TDdOpportunityFactory.createOpportunityByDevRT(OPP_NAME_CHILD, act.Id, contact.Id, 'Closed Won', 'ML_Inside_Sales');
        opp.Commission__c = 15;
        opp.In_App_Pickup_Commission__c = 15;
        opp.Order_Protocol__c = DEFAULT_ORDER_PROTOCOL;
        opp.DashPass_Only_Commission__c = 15;
        opp.Referred_Delivery_Commission__c = 15;
        opp.Referred_Pickup_Commission__c = 15;
        opp.Weekly_Printer_Subscription_Fee__c = '$0';
        opp.Activation_Fee__c = '$0';
        opp.Weekly_Tablet_Subscription_Fee__c = '$3';
        opp.Platform__c = 'DoorDash';
        opp.Region_Type__c = 'Live Region';
        opp.Order_Service_Type__c = 'Delivery Only';
        opp.RecordTypeId = CDdSchemaUtils.OPPORTUNITY_RT.enterpriseMarketplaceId();
        insert opp;
        test.stopTest();
        //marekt place onboarding cases are creating but pos cases not getting created.
        CDdMxPosIntegrationRequestProcessor processor = new CDdMxPosIntegrationRequestProcessor(onboardingIds);
        processor.execute();
        List<opportunity> opps = [select id, Order_Protocol__c from opportunity where Id = :opp.Id];
        System.assertEquals(POS_ORDER_PROTOCOL, opps[0].Order_Protocol__c, 'Opportunity pos order protocol is not updated');
        List<Case> cas = [select id from case where AccountId =: act.id and recordtypeId = :POS_INTEGRATION_RECORD_TYPE_ID];
        System.assertEquals(cas.size() , 1 , 'Pos integration record case count not matching');
    }
    /**
    *@description If pos integration case exist and provider type is different, make the existing case as dead and create new pos case.
    */
    @isTest
    static void testUpdateExistingCasetoDead(){
        mockPosIntegrationTestData();
        Account act = getaccountbyName(ACCOUNT_NAME);
        Contact contact = getContactByAccountId(act.Id);
        set<String> onboardingIds = new Set<String>{posIntegrationRequest[0].onboarding_Id__C};

        test.startTest();
        Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
        validation.Bypass_Opportunity_Validations__c = true;
        validation.Bypass_Account_Validations__c = true;
        validation.Bypass_Case_Validations__c = true;
        insert validation;

        Opportunity opp = TDdOpportunityFactory.createOpportunityByDevRT(OPP_NAME_CHILD, act.Id, contact.Id, 'Closed Won', 'ML_Inside_Sales');
        opp.Commission__c = 15;
        opp.In_App_Pickup_Commission__c = 15;
        opp.Order_Protocol__c = POS_ORDER_PROTOCOL;
        opp.DashPass_Only_Commission__c = 15;
        opp.Referred_Delivery_Commission__c = 15;
        opp.Referred_Pickup_Commission__c = 15;
        opp.Activation_Case_Created__c = true;
        opp.Weekly_Printer_Subscription_Fee__c = '$0';
        opp.Activation_Fee__c = '$0';
        opp.Region_Type__c = 'Live Region';
        opp.Weekly_Tablet_Subscription_Fee__c = '$3';
        opp.RecordTypeId = CDdSchemaUtils.OPPORTUNITY_RT.enterpriseMarketplaceId();
        insert opp;
        test.stopTest();
        CDdMxPosIntegrationRequestProcessor processor = new CDdMxPosIntegrationRequestProcessor(onboardingIds);
        processor.execute();
        List<Case> cas = [select id from case where AccountId =: act.id and recordtypeId = :POS_INTEGRATION_RECORD_TYPE_ID];
        System.assertEquals(2 , cas.size() , 'Pos integration record case count matching');
    }
    /**
    *@description mock external post integration object.
    */
    private static void mockPosIntegrationTestData(){
        set<String> onboardingIds = new Set<String>{posIntegrationRequest[0].onboarding_Id__C};
        IIntegrationRequestsSelector mockIntegrationSelector = (IIntegrationRequestsSelector) mocks.mock(IntegrationRequestsSelector.class);
        Set<String> status = new Set<String>{CDdMxSxConstants.POS_INTEGRATION_REQUESTS_STATUS_PENDING};
        Set<String> sfdcOrg = new Set<String>{CDdMxSxConstants.POS_INTEGRATION_REQUESTS_ORG_FIGMENT};
        CDdMxIntegrationObject posRequests = new CDdMxIntegrationObject(posIntegrationRequest);
        mocks.startStubbing();
        mocks.when(mockIntegrationSelector.sObjectType()).thenReturn(Integration_Request__x.SObjectType);
        mocks.when(mockIntegrationSelector.selectIntegrationRequestsByOnboardingIds(onboardingIds)).thenReturn(posRequests);
        mocks.when(mockIntegrationSelector.selectIntegrationRequestsByStatusAndOrg(status, sfdcOrg, 2)).thenReturn(posRequests);
        mocks.stopStubbing();
        Application.Selector.setMock(mockIntegrationSelector);
    }
    /**
    *@description get account by Name
    */
    static Account getaccountbyName(String Name) {
        return [SELECT id,ownerId, ADR_Owner_Actual__c, Owner.userName, BillingCountryCode FROM Account WHERE Name = :Name];
    }
    /**
    *@description get contact by accountId
    */
    static contact getContactByAccountId(Id accountId) {
        return [SELECT id from Contact where Accountid =: accountId];
    }
}