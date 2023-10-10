/********************************************************************************************************************
* @author Ganesh
* @date
* @group SSMO Mx onboarding
*
* @description Test Merchant Onboarding Case status Updates from MxPortal
*
**************************************************************************************************************************************/
@isTest
public class CDdMxOnBoardingCaseHelperTest {
   public static final Id TEST_ROLE_ID;
   public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
   public static final String TEST_OPP_PACTSAFE_CONTRACT_TYPE = 'English Sign Up Sheet';
   public static final String TEST_OPPORTUNITY_NAME_FOR_MX_ONBOARDING = 'MxSx_Test_Opp_123';
   public static final String TEST_OPPORTUNITY_MX_ONBOARDING_MENU_URL = 'www.testmenu.com';
   public static final String TEST_OPPORTUNITY_MX_ONBOARDING_MENU_URL_UPDATED = 'www.testmenuupdated.com';
   public static final String TEST_OPPORTUNITY_MX_ONBOARDING_MENU_URL_UPDATED_REASON = 'Corrected the MenuURL';
   public static final String TEST_INSTANCE_NAME = 'CDdMxOnboardingMxPortalUpdate';
   public static CDdMxSupportEventEnum testEvent1 = CDdMxSupportEventEnum.MX_ONBOARDING_UPDATE_INBOUND;
   public static final String QUERY_LAST_N_DAYS = '10';
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

            vCS__c testSettings;
            testSettings = VTestUtil.createVeltigSettings();
            testSettings.CaseTrigger__c = true;
            insert testSettings;

            Feature_Flags__c ftrFlag = Feature_Flags__c.getOrgDefaults();
            ftrFlag.Enable_CPU_Time_Check__c = true;
            ftrFlag.Enable_Debug_Logs__c = true;
            insert ftrFlag;

            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
            validation.Bypass_Opportunity_Validations__c = true;
            validation.Bypass_Account_Validations__c = true;
            validation.Bypass_Case_Validations__c = true;
            insert validation;

            CDdMilestoneTemplate.insertMilestoneTemplates();

            TDdAccountFactory.setUpBusinessVerticals();

            Test.startTest();
            PriceBook2 pricebook = new Pricebook2(Id = Test.getStandardPricebookId(), isActive = true);
            update pricebook;

            Submarket__c submarket = TDdCPQTestDataFactory.createSubmarket('New York', 'NEW YORK', 10, null, true);
            RealZip__RealZips__c realZip = TDdCPQTestDataFactory.createRealZip(submarket, false);
            realZip.Alcohol_Eligibility__c = 'Pickup';
            insert realZip;
            List<Account> accountsToInsert = new List<Account>();
            accountsToInsert = TDdAccountFactory.createAccounts('Account', 2);
            accountsToInsert[0].RealZip__RealZip__c = realZip.Id;
            accountsToInsert[0].Business_ID__c = 1234567;
            accountsToInsert[0].Deck_Rank__c = 'Queen';
            accountsToInsert[0].Restaurant_Id__c = '123456';
            accountsToInsert[0].iPad_Username__c = '12345678';
            accountsToInsert[0].iPad_Password__c = '12345678';


            accountsToInsert[1].RealZip__RealZip__c = realZip.Id;
            accountsToInsert[1].Business_ID__c = 8992;
            accountsToInsert[1].Deck_Rank__c = 'King of Spades';
            accountsToInsert[1].Restaurant_Id__c = '8991';
            accountsToInsert[1].iPad_Username__c = '123456789';
            accountsToInsert[1].iPad_Password__c = '123456789';
            insert accountsToInsert;

            Contact contact = TDdAccountFactory.createContacts(1, accountsToInsert[0].Id)[0];
            insert contact;
            String contactId = contact.Id ;

            Opportunity opp = TDdOpportunityFactory.createOpportunityByDevRT(TEST_OPPORTUNITY_NAME_FOR_MX_ONBOARDING, accountsToInsert[0].Id, contact.Id, 'Closed Won', 'ML_Inside_Sales');
            opp.Commission__c = 15;
            opp.In_App_Pickup_Commission__c = 15;
            opp.DashPass_Only_Commission__c = 15;
            opp.Referred_Delivery_Commission__c = 15;
            opp.Referred_Pickup_Commission__c = 15;
            opp.Weekly_Printer_Subscription_Fee__c = '$0';
            opp.Activation_Fee__c = '$0';
            opp.Weekly_Tablet_Subscription_Fee__c = '$3';
            opp.PactSafe_Contract_Type__c = TEST_OPP_PACTSAFE_CONTRACT_TYPE;
            opp.Delivery_Inflation_Opp__c = 'Yes & POS Blocked';
            opp.Menu_URL__c = TEST_OPPORTUNITY_MX_ONBOARDING_MENU_URL;
            opp.Proposed_Date_of_Menu__c = System.today().addDays(1);
            opp.Proposed_Date_of_Activation__c = null;
            opp.POS_Integration_Type__c = 'non_integrated_mx';
            opp.Type = 'New Partner (Create Menu + Nimda)';
            insert opp;
            Mx_Support_Event_Config__c eventConfig = new Mx_Support_Event_Config__c();
            eventConfig.Apex_Class__c = TEST_INSTANCE_NAME;
            eventConfig.Batch_Size__c = 1;
            eventConfig.Event_Name__c = testEvent1.name();
            eventConfig.Is_Active__c = true;
            eventConfig.Query_Last_N_Days__c = Decimal.valueOf(QUERY_LAST_N_DAYS);
            eventConfig.Query_SObject_Type__c = 'Mx_Onboarding__c';
            eventConfig.Sequence__c = 1;
            insert eventConfig;
            Test.getEventBus().deliver();
            Test.stopTest();

           Map<Id, Case> onboardingCases = new Map<Id, Case>([ SELECT Id, RecordTypeId, RecordType.Name
                                                               FROM Case
                                                               WHERE Opportunity_name__c = :opp.Id
                                                               AND RecordTypeId = :CDdMxSxConstants.RECORD_TYPE_ID_CASE_MARKETPLACE_ONBOARDING]);
           Map<Id, Milestone__c> milestoneByRecordTypeId = new Map<Id, Milestone__c>();
           for (Milestone__c m : [ SELECT Id, Name, RecordTypeId, Case__c, Status__c, Status_Reason__c
                                   FROM Milestone__c
                                   WHERE Case__c IN :onboardingCases.keySet()
                                   AND Case__r.RecordTypeId = :CDdMxSxConstants.RECORD_TYPE_ID_CASE_MARKETPLACE_ONBOARDING
                                  ]){
               milestoneByRecordTypeId.put(m.RecordTypeId, m);
           }
           Milestone__c setUpMenuMilestone = milestoneByRecordTypeId.get(CDdMxSxConstants.MILESTONE_RECORD_TYPE_ID_SETUP_MENU);
           setUpMenuMilestone.Status__c = CDdMxSxConstants.MILESTONE_STATUS_BLOCKED;
           setUpMenuMilestone.Status_Reason__c = 'Px Unresponsive';
           update setUpMenuMilestone;
           Test.getEventBus().deliver();
           List<Mx_Onboarding__c>  mxOnboardingRecord = [Select id, StoreId__c, Menu_MenuUrl__c, Proposed_Date_of_Activation__c, Tablet_Status__c, Tablet_OwnerFirstName__c,
                                                         Menu_ProposedDateofMenu__c, Case_Stage__c, Case_Status__c, SetupStore_Status__c from Mx_Onboarding__c Limit 1];

           System.assertEquals(mxOnboardingRecord.size(), 1);
        }
   }
   /**
     * @description BZAP-20577 - Test scenario related Mx SSMO Fraud feature
     * BZAP-20577 - Figment Update Case Owner and Status for Milestone changes
     */
    @isTest
    public static void testBlockedStatus() {
        String TEST_STORE_ID = '123456';
        System.runAs (getTestRunUser()) {
            Test.startTest();
            Mx_Onboarding__c testOnboardingRecordFromDB = [ SELECT Id, StoreId__c, Business_Verification_Status__c, UpdateType__c
                                                            FROM Mx_Onboarding__c
                                                            WHERE StoreId__c = :TEST_STORE_ID
                                                            LIMIT 1];
            System.assert(testOnboardingRecordFromDB != null);
            update new Mx_Onboarding__c(Id = testOnboardingRecordFromDB.Id,
                                        UpdateType__c = 'Inbound',
                                        Business_Verification_Status__c = CDdMxOnBoardingMilestoneHelper.BUSINESS_VERIFICATION_STATUS_DOCUMENTATION_REQUIRED);
            Test.stopTest();
            Milestone__c testMilestoneFromDB  = [   SELECT Id, Case__c, Status__c, Status_Reason__c
                                                    FROM Milestone__c
                                                    WHERE Case__r.Account.Restaurant_Id__c = :TEST_STORE_ID
                                                    AND Case__r.RecordTypeId =:CDdMxSxConstants.RECORD_TYPE_ID_CASE_MARKETPLACE_ONBOARDING
                                                    AND RecordTypeId = :CDdMxSxConstants.MILESTONE_RECORD_TYPE_ID_REVIEW_AND_TRIAGE
                                                    ];
            System.assert(testMilestoneFromDB != null);
            System.assertEquals('Blocked', testMilestoneFromDB.Status__c);
            System.assertEquals('Fraud', testMilestoneFromDB.Status_Reason__c);
            Case objCase = [  SELECT Id, Status, OwnerId
                                            FROM Case
                                            WHERE Id = :testMilestoneFromDB.Case__c
                                            LIMIT 1];

            System.assertEquals(CDdMxOnBoardingCaseHelper.MX_FRAUD_INVESTIGATION_QUEUE_ID, objCase.OwnerId);
        }
    }

    @isTest
    public static void testDeniedStatus() {
        String TEST_STORE_ID = '123456';
        System.runAs (getTestRunUser()) {
            Test.startTest();
            Mx_Onboarding__c testOnboardingRecordFromDB = [ SELECT Id, StoreId__c, Business_Verification_Status__c, UpdateType__c
                                                            FROM Mx_Onboarding__c
                                                            WHERE StoreId__c = :TEST_STORE_ID
                                                            LIMIT 1];
            System.assert(testOnboardingRecordFromDB != null);
            update new Mx_Onboarding__c(Id = testOnboardingRecordFromDB.Id,
                                        UpdateType__c = 'Inbound',
                                        Business_Verification_Status__c = CDdMxOnBoardingMilestoneHelper.BUSINESS_VERIFICATION_STATUS_DOCUMENTATION_DENIED);
            Test.stopTest();
            Milestone__c testMilestoneFromDB  = [   SELECT Id, Case__c, Status__c, Status_Reason__c
                                                    FROM Milestone__c
                                                    WHERE Case__r.Account.Restaurant_Id__c = :TEST_STORE_ID
                                                    AND Case__r.RecordTypeId =:CDdMxSxConstants.RECORD_TYPE_ID_CASE_MARKETPLACE_ONBOARDING
                                                    AND RecordTypeId = :CDdMxSxConstants.MILESTONE_RECORD_TYPE_ID_REVIEW_AND_TRIAGE
                                                    ];
            System.assert(testMilestoneFromDB != null);
            System.assertEquals('Dead', testMilestoneFromDB.Status__c);
            System.assertEquals('Fraud', testMilestoneFromDB.Status_Reason__c);
            Case objCase = [  SELECT Id, Status, OwnerId
                                            FROM Case
                                            WHERE Id = :testMilestoneFromDB.Case__c
                                            LIMIT 1];

            System.assertEquals(CDdMxOnBoardingCaseHelper.ONBOARDING_UNDER_REVIEW_QUEUE_ID, objCase.OwnerId);
        }
    }

    @isTest
    public static void testApprovedStatus() {
        String TEST_STORE_ID = '123456';

        System.runAs (getTestRunUser()) {
            Test.startTest();
            Mx_Onboarding__c testOnboardingRecordFromDB = [ SELECT Id, StoreId__c, Business_Verification_Status__c, UpdateType__c
                                                            FROM Mx_Onboarding__c
                                                            WHERE StoreId__c = :TEST_STORE_ID
                                                            LIMIT 1];
            System.assert(testOnboardingRecordFromDB != null);
            update new Mx_Onboarding__c(Id = testOnboardingRecordFromDB.Id,
                                        UpdateType__c = 'Inbound',
                                        Business_Verification_Status__c = CDdMxOnBoardingMilestoneHelper.BUSINESS_VERIFICATION_STATUS_DOCUMENTATION_APPROVED);
            Test.stopTest();
            Milestone__c testMilestoneFromDB  = [   SELECT Id, Case__c, Status__c, Status_Reason__c
                                                    FROM Milestone__c
                                                    WHERE Case__r.Account.Restaurant_Id__c = :TEST_STORE_ID
                                                    AND Case__r.RecordTypeId =:CDdMxSxConstants.RECORD_TYPE_ID_CASE_MARKETPLACE_ONBOARDING
                                                    AND RecordTypeId = :CDdMxSxConstants.MILESTONE_RECORD_TYPE_ID_REVIEW_AND_TRIAGE];
            System.assert(testMilestoneFromDB != null);
            System.assertEquals('Complete', testMilestoneFromDB.Status__c);

            Case objCase = [  SELECT Id, Status, OwnerId
                                            FROM Case
                                            WHERE Id = :testMilestoneFromDB.Case__c
                                            LIMIT 1];

            System.assertEquals(CDdMxOnBoardingCaseHelper.ONBOARDING_UNDER_REVIEW_QUEUE_ID, objCase.OwnerId);
        }
    }

}