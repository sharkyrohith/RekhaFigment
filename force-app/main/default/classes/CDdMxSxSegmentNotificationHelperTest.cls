/********************************************************************************************************************
* @author Veera
* @date 06/29/2022
*
* @group Merchant Services
*
* @description Test Segment Notification Helper
*
**************************************************************************************************************************************/
@isTest
public class CDdMxSxSegmentNotificationHelperTest {

    private static vCS__c testSettings;
    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    public static final String TEST_OPPORTUNITY_NAME_FOR_CPQ = 'MxSx_Test_Opp_123';
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

    /**
    * @description Prepare test data
    */
    @TestSetup
    static void setup() {
        System.runAs(getTestRunUser()){

            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
            validation.Bypass_Opportunity_Validations__c = true;
            validation.Bypass_Account_Validations__c = true;
            validation.Bypass_Case_Validations__c = true;
            validation.Bypass_Milestone_Validations__c  = true;
            insert validation;

            Support_Feature_Flag__c featureFlag = Support_Feature_Flag__c.getOrgDefaults();
            featureFlag.Enable_Qualtrics_Surveys__c = false;
            featureFlag.EnableReopen__c = true;
            featureFlag.EnableMXPAgentReopens__c = true;
            featureFlag.Enable_Tasks_on_Case_Feed__c = true;
            featureFlag.MXP_Support_E2C_Linking__c = true;
            featureFlag.Enable_Sendbird_API_Callouts__c = true;
            upsert featureFlag;

            Feature_Flags__c ftrFlag = Feature_Flags__c.getOrgDefaults();
            ftrFlag.Enable_Case_Trigger_Optimization__c = true;
            insert ftrFlag;

            testSettings = VTestUtil.createVeltigSettings();
            insert testSettings ;

            Test.startTest();
            //Insert Milestone Templates
            CDdMilestoneTemplate.insertMilestoneTemplates();

            Submarket__c submarket = TDdCPQTestDataFactory.createSubmarket('New York', 'NEW YORK', 10, null, true);
            RealZip__RealZips__c realZip = TDdCPQTestDataFactory.createRealZip(submarket, false);
            realZip.Alcohol_Eligibility__c = 'Pickup';
            insert realZip;

            Account account = TDdAccountFactory.createAccounts('Account', 1)[0];
            account.RealZip__RealZip__c = realZip.Id;
            account.Business_ID__c = 1234567;
            insert account;

            Contact contact = TDdAccountFactory.createContacts(1, account.Id)[0];
            insert contact;


            Opportunity opp = TDdOpportunityFactory.createOpportunityByDevRT(TEST_OPPORTUNITY_NAME_FOR_CPQ, account.Id, contact.Id, 'Open', 'ML_Inside_Sales');
            opp.Commission__c = 15;
            opp.In_App_Pickup_Commission__c = 15;
            opp.DashPass_Only_Commission__c = 15;
            opp.Referred_Delivery_Commission__c = 15;
            opp.Referred_Pickup_Commission__c = 15;
            opp.Weekly_Printer_Subscription_Fee__c = '$0';
            opp.Activation_Fee__c = '$0';
            opp.Weekly_Tablet_Subscription_Fee__c = '$3';
            opp.Order_Protocol__c = 'Tablet (DoorDash Owns)';
            opp.StageName = CDdOpportunityConstants.OPPORTUNITY_STAGE_CLOSED_WON;
            opp.Menu_Setup_Method__c = 'Create New Menu(s) using Menu Source';
            opp.Region_Type__c = CDdMxSxConstants.OPPORTUNITY_LIVE_REGION;
            insert opp;

            List<Case> cases = TDdCaseFactory.createCases(1, account.Id, opp.Id, CDdSchemaUtils.CASE_RT.tabletRequestsId());
            for (Case cas : cases) {
                cas.Tablet_Shipment_Status__c = 'Shipped';
                cas.Request_Type__c = 'Ship to Merchant (New Tablet)';
                cas.Tablet_Ship_Date2__c = System.today().addDays(-1);
                cas.Tablet_Received_Date_2__c = System.today();
                cas.Tablet_Tracking_UPS__c = '123456789';
                cas.Tablet_Serial_Number__c = '123456789';
                cas.Return_Shipping_Address_State__c = 'Florida';
            }
            insert cases;
            Test.stopTest();
            List<Segment_Logs__c> segmentlogs = [SELECT Id FROM Segment_Logs__c WHERE sObject_Id__c =:opp.Id AND Event__c = :CDdMxSxConstants.MXSX_SEGMENT_NOTIFICATION_EVENTS.OPPORTUNITY_CLOSED_WON.name()];
            System.assert(segmentlogs.size() > 0);
       }
    }

    /**
     * @description Test - Segment notification for Tablet Case Received
    */
    @isTest
    public static void testSegmentNotificationForTabletCaseReceived() {
        System.runAs(getTestRunUser()){
            Opportunity opportunity = getCpqOpportunity();

            List<Case> cases = [SELECT Id FROM Case WHERE Opportunity_Name__c = :opportunity.Id AND RecordTypeId=:CDdSchemaUtils.CASE_RT.tabletRequestsId()];
            cases[0].Status = 'Received';
            cases[0].Tablet_Shipment_Status__c = 'Received';
            cases[0].Request_Type__c = CDdMxSxConstants.CASE_REQUEST_TYPES_SEGMENT_NOTIFICATIONS[0];
            test.startTest();
            update cases;
            Test.getEventBus().deliver();
            test.stopTest();
            Map<Id,Case> caseMap = new Map<Id,Case>(cases);
            List<Segment_Logs__c> segmentlogs = [SELECT Id FROM Segment_Logs__c WHERE sObject_Id__c IN :caseMap.keySet() AND Event__c = :CDdMxSxConstants.MXSX_SEGMENT_NOTIFICATION_EVENTS.TABLET_CASE_RECEIVED.name()];
            System.assert(segmentlogs.size() > 0);
        }
    }

    /**
     * @description Test - Segment notification for Tablet Case Shipped
    */
    @isTest
    public static void testSegmentNotificationForTabletCaseShipped() {
        System.runAs(getTestRunUser()){
            Opportunity opportunity = getCpqOpportunity();

            List<Case> cases = [SELECT Id FROM Case WHERE Opportunity_Name__c = :opportunity.Id AND RecordTypeId=:CDdSchemaUtils.CASE_RT.tabletRequestsId()];
            cases[0].Status = 'Shipped';
            cases[0].Tablet_Shipment_Status__c = 'Shipped';
            test.startTest();
            update cases;
            Test.getEventBus().deliver();
            test.stopTest();
            Map<Id,Case> caseMap = new Map<Id,Case>(cases);
            List<Segment_Logs__c> segmentlogs = [SELECT Id FROM Segment_Logs__c WHERE sObject_Id__c IN :caseMap.keySet() AND Event__c = :CDdMxSxConstants.MXSX_SEGMENT_NOTIFICATION_EVENTS.TABLET_CASE_SHIPPED.name()];
            System.assert(segmentlogs.size() > 0);
        }
    }

    /**
     * @description Test - Segment notification for Milestone Blocked
    */
    @isTest
    static void testSegmentNotificationForMilestoneBlockedEvents() {
        System.runAs(getTestRunUser()){
            Disable_Declarative_Automation__c disableAuto = new Disable_Declarative_Automation__c();
            disableAuto.Case__c = true;
            insert disableAuto;

            Opportunity oppty = getCpqOpportunity();
            Case onboardingCase = [SELECT Id FROM Case WHERE Opportunity_Name__c = :oppty.Id AND RecordTypeId = :CDdSchemaUtils.CASE_RT.marketplaceOnboardingId() LIMIT 1][0];
            onboardingCase.OwnerId = UserInfo.getUserId();
            update onboardingCase;

            List<Milestone__c> mileStones = [SELECT Id,Milestone_Type__c,Status__c FROM Milestone__c WHERE Case__r.Opportunity_Name__c=:oppty.Id AND Case__r.RecordTypeId = :CDdSchemaUtils.CASE_RT.marketplaceOnboardingId() AND Milestone_Type__c = 'Setup Banking'];
            for(Milestone__c m : mileStones){
                m.Status__c = 'Blocked';
                m.Status_Reason__c = 'Invalid EIN; Invalid IBAN Number' ;
            }
            Test.startTest();
            update mileStones;
            Test.stopTest();
            Map<Id,Milestone__c> milestoneMap = new Map<Id,Milestone__c>(mileStones);
            System.assertEquals(true, mileStones.size() > 0);
            List<Segment_Logs__c> segmentlogs = [SELECT Id FROM Segment_Logs__c WHERE sObject_Id__c IN :milestoneMap.keySet() AND Event__c = :CDdMxSxConstants.MXSX_SEGMENT_NOTIFICATION_EVENTS.MILESTONE_BLOCKED.name()];
            System.assert(segmentlogs.size() > 0);
        }
    }

    /**
     * @description Test - Segment notification for Milestone Complete
    */
    @isTest
    static void testSegmentNotificationForMilestoneCompleteEvents() {
        System.runAs(getTestRunUser()){
            Opportunity oppty = getCpqOpportunity();
            Case onboardingCase = [SELECT Id FROM Case WHERE Opportunity_Name__c = :oppty.Id AND RecordTypeId = :CDdSchemaUtils.CASE_RT.marketplaceOnboardingId() LIMIT 1][0];

            Account acc = new Account();
            acc.id = oppty.AccountId;
            acc.Restaurant_ID__c = '123';
            acc.iPad_Username__c = 'username';
            acc.iPad_Password__c = 'password';
            update acc;

            List<String> milestoneRTs = new List<String>{
                new CDdSchemaUtils.MileStoneRT().setupMenuId(),
                new CDdSchemaUtils.MileStoneRT().grantPortalAccessId(),
                new CDdSchemaUtils.MileStoneRT().activateStoreId()
            };

            Map<String, Milestone_Template__c> templateByNameMap = listToMap(CDdMilestoneSelector.templatesByParentTypeMap('Case').values(), 'Milestone_Type__c');
            List<Milestone__c> milestoneList = new List<Milestone__c>();
            Milestone__c asMileStone = new CDdMilestone().initializeMilestone(templateByNameMap.get('Activate Store'), 'Case__c', onboardingCase.Id);
            asMileStone.Type__c = 'Rep Activation';
            Milestone__c smMileStone = new CDdMilestone().initializeMilestone(templateByNameMap.get('Setup Menu'), 'Case__c', onboardingCase.Id);
            Milestone__c gpaMileStone = new CDdMilestone().initializeMilestone(templateByNameMap.get('Grant Portal Access'), 'Case__c', onboardingCase.Id);
            milestoneList.add(asMileStone);
            milestoneList.add(smMileStone);
            milestoneList.add(gpaMileStone);

            insert milestoneList;
            Test.startTest();
            onboardingCase.OwnerId = UserInfo.getUserId();
            onboardingCase.Stage__c = 'Ready for Activation';
            update onboardingCase;

            for(Milestone__c m : milestoneList){
                if(m.Milestone_Type__c == 'Activate Store'){
                	m.Status__c = new CDdMilestone().Complete;
                }
            }
            update milestoneList;
            Map<Id,Milestone__c> milestoneMap = new Map<Id,Milestone__c>(milestoneList);
            Test.stopTest();
            List<Segment_Logs__c> segmentlogs = [SELECT Id FROM Segment_Logs__c WHERE sObject_Id__c IN :milestoneMap.keySet() AND Event__c = :CDdMxSxConstants.MXSX_SEGMENT_NOTIFICATION_EVENTS.MILESTONE_COMPLETED.name()];
            System.assert(segmentlogs.size() > 0);
        }
    }

    /**
     * @description Test - Segment notification for Enterprise Accounts
    */
    @isTest
    static void testSegmentNotificationForEnterpriseAccount() {
        System.runAs(getTestRunUser()){
            Opportunity oppty = getCpqOpportunity();
            Case onboardingCase = [SELECT Id FROM Case WHERE Opportunity_Name__c = :oppty.Id AND RecordTypeId = :CDdSchemaUtils.CASE_RT.marketplaceOnboardingId() LIMIT 1][0];

            Account acc = new Account();
            acc.id = oppty.AccountId;
            acc.RecordTypeId = CDdMxSxConstants.RECORD_TYPE_ID_ACCOUNT_ENTERPRISE_MARKETPLACE;
			acc.Restaurant_ID__c = '123';
            acc.iPad_Username__c = 'username';
            acc.iPad_Password__c = 'password';
            update acc;

            Map<String, Milestone_Template__c> templateByNameMap = listToMap(CDdMilestoneSelector.templatesByParentTypeMap('Case').values(), 'Milestone_Type__c');
            List<Milestone__c> milestoneList = new List<Milestone__c>();
            Milestone__c asMileStone = new CDdMilestone().initializeMilestone(templateByNameMap.get('Activate Store'), 'Case__c', onboardingCase.Id);
            asMileStone.Type__c = 'Rep Activation';
            Milestone__c smMileStone = new CDdMilestone().initializeMilestone(templateByNameMap.get('Setup Menu'), 'Case__c', onboardingCase.Id);
            Milestone__c gpaMileStone = new CDdMilestone().initializeMilestone(templateByNameMap.get('Grant Portal Access'), 'Case__c', onboardingCase.Id);
            milestoneList.add(asMileStone);
            milestoneList.add(smMileStone);
            milestoneList.add(gpaMileStone);

            insert milestoneList;
            Test.startTest();
            onboardingCase.OwnerId = UserInfo.getUserId();
            onboardingCase.Stage__c = 'Ready for Activation';
            update onboardingCase;

            for(Milestone__c m : milestoneList){
                if(m.Milestone_Type__c == 'Activate Store'){
                	m.Status__c = new CDdMilestone().Complete;
                }
            }
            update milestoneList;
            Map<Id,Milestone__c> milestoneMap = new Map<Id,Milestone__c>(milestoneList);
            Test.stopTest();
            List<Segment_Logs__c> segmentlogs = [SELECT Id FROM Segment_Logs__c WHERE sObject_Id__c IN :milestoneMap.keySet() AND Event__c = :CDdMxSxConstants.MXSX_SEGMENT_NOTIFICATION_EVENTS.MILESTONE_COMPLETED.name()];
            System.assert(segmentlogs.size() == 0);
        }
    }

    /**
     * @description Return the test cpq opportunity record created in the setup method
    */
    private static Opportunity getCpqOpportunity() {
        return [SELECT Id, AccountId, SBQQ__PrimaryQuote__c FROM Opportunity WHERE Name = :TEST_OPPORTUNITY_NAME_FOR_CPQ LIMIT 1];
    }

    private static Map<String, Milestone_Template__c> listToMap(List<Milestone_Template__c> sobjects, String keyField) {
        Map<String, Milestone_Template__c> sobjectMap = new Map<String, Milestone_Template__c>();
        for (Milestone_Template__c sobj : sobjects) {
            String key = (String) sobj.get(keyField);
            sobjectMap.put(key, sobj);
        }
        return sobjectMap;
    }
}