/********************************************************************************************************************
* @author Lathika
* @date
* @group Merchant Services
*
* @description Test Merchant Onboarding Status Updates from MxPortal
*
**************************************************************************************************************************************/
@isTest
public class CDdMxOnBoardingTriggerHelperTest {
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
            Disable_Declarative_Automation__c disableAuto = new Disable_Declarative_Automation__c();
            disableAuto.Case__c = true;
            insert disableAuto;

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
            createEvent('Storefront Implementation Call', contactId, System.Now().addMinutes(15), System.Now().addMinutes(15), 'Meeting', true);

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
    * @description test update MxOnboarding record by Mulesoft Integration user(updatng the Menu Url and Proposed date of activation)
    */
   @isTest
   public static void testMxOnboardingUpdatePlatformEvent() {

        System.runAs (getTestRunUser()) {
           Test.startTest();
            // fetching the MxOnBoardingrecord record to assert the opp Menu Url
           CDdMxSxConstants.ENABLE_MX_ONBOARDING_PLATFORMEVENT_UPDATE = True;
           List<Mx_Onboarding__c>  mxOnboardingRecord = [Select id, StoreId__c, Menu_MenuUrl__c, Proposed_Date_of_Activation__c,
                                                         Menu_ProposedDateofMenu__c, Case_Stage__c, Case_Status__c, UpdateType__c
                                                         from Mx_Onboarding__c Limit 1];
            System.assertEquals(mxOnboardingRecord.size(), 1);
            System.assertEquals('123456', mxOnboardingRecord[0].StoreId__c);
            System.assertEquals(TEST_OPPORTUNITY_MX_ONBOARDING_MENU_URL, mxOnboardingRecord[0].Menu_MenuUrl__c);
            mxOnboardingRecord[0].Menu_MenuUrl__c = TEST_OPPORTUNITY_MX_ONBOARDING_MENU_URL_UPDATED;
            mxOnboardingRecord[0].Proposed_Date_of_Activation__c =  System.today().addDays(2);
            mxOnboardingRecord[0].UpdateType__c = 'Inbound';
            mxOnboardingRecord[0].MenuMilestone_Updated_Reason__c = TEST_OPPORTUNITY_MX_ONBOARDING_MENU_URL_UPDATED_REASON;
            update mxOnboardingRecord;
            Test.getEventBus().deliver();
            Test.stopTest();
       }
        Opportunity opportunityFromDBPlatformEvent = getMxOnboardingOpportunity();
        Case mpCaseFromDBPlatformEvent = getMarketPlaceOnboaringCase(opportunityFromDBPlatformEvent.id);
            // fetching the setUpMenu milestone to assert the Status
        Milestone__c setUpMenuMilestoneFromDBPlatformEvent  = [SELECT Id, Name, RecordTypeId, Case__c, Status__c
                                                    FROM Milestone__c where Case__c =: mpCaseFromDBPlatformEvent.ID and RecordTypeId = :CDdMxSxConstants.MILESTONE_RECORD_TYPE_ID_SETUP_MENU];
        System.assertEquals('In Progress', setUpMenuMilestoneFromDBPlatformEvent.Status__c);

        System.assertEquals(TEST_OPPORTUNITY_MX_ONBOARDING_MENU_URL_UPDATED, opportunityFromDBPlatformEvent.Menu_URL__c);
        List<Mx_Onboarding__c>  mxOnboardingRecordFromDBPlatformEvent = [Select id, StoreId__c, Menu_MenuUrl__c, Proposed_Date_of_Activation__c, UpdateType__c
                                                        from Mx_Onboarding__c Limit 1];
        System.assertEquals('Outbound', mxOnboardingRecordFromDBPlatformEvent[0].UpdateType__c);
   }
   /**
    * @description test update MxOnboarding record by Mulesoft Integration user(updatng the Menu Url and Proposed date of activation)
    */
    @isTest
    public static void testMxOnboardingUpdateTrigger() {

        System.runAs (getTestRunUser()) {
            Test.startTest();
             // fetching the MxOnBoardingrecord record to assert the opp Menu Url
             CDdMxSxConstants.ENABLE_MX_ONBOARDING_PLATFORMEVENT_UPDATE = False;
            List<Mx_Onboarding__c>  mxOnboardingRecord = [SELECT id, StoreId__c, Menu_MenuUrl__c, Proposed_Date_of_Activation__c, MenuMilestone_Updated_Reason__c,
                                                          Menu_ProposedDateofMenu__c, UpdateType__c
                                                          from Mx_Onboarding__c Limit 1];
             System.assertEquals(mxOnboardingRecord.size(), 1);
             System.assertEquals('123456', mxOnboardingRecord[0].StoreId__c);
             System.assertEquals(TEST_OPPORTUNITY_MX_ONBOARDING_MENU_URL, mxOnboardingRecord[0].Menu_MenuUrl__c);
             mxOnboardingRecord[0].Menu_MenuUrl__c = TEST_OPPORTUNITY_MX_ONBOARDING_MENU_URL_UPDATED;
             mxOnboardingRecord[0].Proposed_Date_of_Activation__c =  System.today().addDays(2);
             mxOnboardingRecord[0].UpdateType__c = 'Inbound';
             mxOnboardingRecord[0].MenuMilestone_Updated_Reason__c = TEST_OPPORTUNITY_MX_ONBOARDING_MENU_URL_UPDATED_REASON;
             update mxOnboardingRecord;
             Test.stopTest();
        }
        Opportunity opportunityFromDB = getMxOnboardingOpportunity();
        Case mpCaseFromDB = getMarketPlaceOnboaringCase(opportunityFromDB.id);
        // fetching the setUpMenu milestone to assert the Status
        Milestone__c setUpMenuMilestoneFromDB = [SELECT Id, Name, RecordTypeId, Case__c, Status__c, Status_Reason__c
                                                FROM Milestone__c where Case__c =: mpCaseFromDB.ID and RecordTypeId = :CDdMxSxConstants.MILESTONE_RECORD_TYPE_ID_SETUP_MENU];
        System.assertEquals('In Progress', setUpMenuMilestoneFromDB.Status__c);
        System.assertEquals(TEST_OPPORTUNITY_MX_ONBOARDING_MENU_URL_UPDATED, opportunityFromDB.Menu_URL__c);
        List<Mx_Onboarding__c>  mxOnboardingRecordFromDB = [SELECT id, StoreId__c, UpdateType__c
                                                            from Mx_Onboarding__c Limit 1];
        System.assertEquals('Outbound', mxOnboardingRecordFromDB[0].UpdateType__c);

    }
    /**
     * @description: Code coverage for CDdMxOnboardingMxPortalUpdate class
     */
    @isTest
    static void testUpdateMxOnboarding() {
        System.runAs(getTestRunUser()){
            List<Mx_Onboarding__c>  mxOnboardingRecord = [SELECT id, StoreId__c, Menu_MenuUrl__c, Proposed_Date_of_Activation__c, Tablet_Status__c,
                                                         Tablet_OwnerLastName__c, Tablet_OwnerFirstName__c, Menu_ProposedDateofMenu__c, Case_Stage__c, Case_Status__c,
                                                         SetupStore_Status__c, Tablet_ShippingAddress_Country__c, Tablet_ShippingStatus__c, Tablet_ShippingAddress_City__c,
                                                         Tablet_ShippingAddress_AddressLine1__c, Tablet_ShippingAddress_State__c
                                                         from Mx_Onboarding__c Limit 1];
                                                         mxOnboardingRecord[0].Menu_MenuUrl__c = TEST_OPPORTUNITY_MX_ONBOARDING_MENU_URL_UPDATED;
            mxOnboardingRecord[0].Proposed_Date_of_Activation__c =  System.today().addDays(2);
            mxOnboardingRecord[0].UpdateType__c = 'Inbound';
            mxOnboardingRecord[0].MenuMilestone_Updated_Reason__c = TEST_OPPORTUNITY_MX_ONBOARDING_MENU_URL_UPDATED_REASON;
            update mxOnboardingRecord;
            Test.startTest();
            CDdMxSupportEventBatch supportBatch = new CDdMxSupportEventBatch(testEvent1);
            Database.executeBatch(supportBatch, CDdMxSupportEventConfig.getBatchSize(testEvent1));
            Test.stopTest();
            List<Apex_Log__c> errorLogs = [SELECT Id, Operation__c,  Log__c FROM Apex_Log__c WHERE Operation__c = 'handleMxOnboardingUpdate processResultsInt'];
            System.assertEquals(0, errorLogs.size());
        }
    }
    /**
     * @description  BZAP-17940 test PDOA date on SMB Closed WOn Opportunity,if PDOA date is null, PDOA = CloseWon date + 14 (SMB POS )
     */
    @isTest
    public static void testSetPDOAdateonSMBnonCOOopportunitiesonclosedWons() {
        System.runAs (getTestRunUser()) {
            List<Mx_Onboarding__c>  mxOnboardingRecord = [SELECT id, StoreId__c, Menu_MenuUrl__c, Proposed_Date_of_Activation__c
                                                         from Mx_Onboarding__c where StoreId__c = '123456' Limit 1];
            Opportunity testOpp = getMxOnboardingOpportunity();
            Date pDOADATEFromDB = Date.today().addDays(14);
            System.assertEquals(pDOADATEFromDB.format(), testOpp.Proposed_Date_of_Activation__c.format(),'Proposed date of Activation is Incorrect');
            System.assertEquals(pDOADATEFromDB.format(), mxOnboardingRecord[0].Proposed_Date_of_Activation__c.format(),'Proposed date of Activation is Incorrect');
        }
    }
    /**
     * @description  BZAP-17940 test PDOA date on Enterprise Closed WOn Opportunity,PDOA = null after Insert)
     */
    @isTest
    public static void testSetPDOAdateonEnterprisenonCOOopportunitiesonclosedWon() {
        System.runAs (getTestRunUser()) {
            Test.startTest();
            Account acc = [SELECT id from Account where Restaurant_Id__c = '8991'];
            Contact contact = TDdAccountFactory.createContacts(1, acc.Id)[0];
            Opportunity opp = TDdOpportunityFactory.createOpportunityByDevRT(TEST_OPPORTUNITY_NAME_FOR_MX_ONBOARDING, acc.Id, contact.Id, 'Closed Won', 'ML_Inside_Sales');
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
            Test.stopTest();
            Opportunity testOpp = [SELECT Id, AccountId, Proposed_Date_of_Activation__c, Menu_URL__c FROM Opportunity WHERE AccountId =:acc.Id ];
            System.assertEquals(null, testOpp.Proposed_Date_of_Activation__c,'Proposed date of Activation is Incorrect');
        }
    }
    /**
     * @description  BZAP-17940 test PDOA date for Retail Merchants (Business_Vertical (Menu UI Type Field) == Retail)
     * If(Retail) => PDOA = Opportunity Closed Date + 21
     */
    @isTest
    public static void testSetPDOADateForRetailMerchantOopportunitiesOnClosedWon() {
        List<Business_Vertical__c> bvList = [SELECT Id FROM Business_Vertical__c WHERE Menu_UI_Type__c = :CDdMxSxOpportunityTriggerUpdateHelper.MENU_UI_TYPE_RETAIL];
        Account parentAccount = TDdAccountFactory.createAccounts('parentAccountName', 1, 'Parent Account')[0];
        parentAccount.BillingCountry = 'United States';
        parentAccount.Name = 'Parent Account';
        parentAccount.Business_Id__c = 1234;
        parentAccount.Deck_Rank__c = 'Jack';
        parentAccount.Business_Vertical__c = bvList[0].Id;
        insert parentAccount;

        Account acc = [SELECT id from Account where Restaurant_Id__c = '8991'];
        acc.ParentId = parentAccount.Id;
        acc.Deck_Rank__c = 'Jack';
        update acc;

        Contact contact = [SELECT Id FROM Contact LIMIT 1];
        String contactId = contact.Id ;
        createEvent('Storefront Implementation Call', contactId, System.Now().addMinutes(15), System.Now().addMinutes(15), 'Meeting', true);


        System.runAs (getTestRunUser()) {
            String opptyName = TEST_OPPORTUNITY_NAME_FOR_MX_ONBOARDING+'retail';
            Opportunity opp = TDdOpportunityFactory.createOpportunityByDevRT(opptyName, acc.Id, contact.Id, 'Closed Won', 'ML_Inside_Sales');
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

            Opportunity testOpp = [SELECT Id, AccountId, Proposed_Date_of_Activation__c, Menu_URL__c FROM Opportunity WHERE Id = :opp.Id LIMIT 1];
            Date pDOADATEFromDB = Date.today().addDays(21);
            System.assertEquals(pDOADATEFromDB.format(), testOpp.Proposed_Date_of_Activation__c.format(),'Proposed date of Activation is Incorrect');
        }
    }
    /**
    * @description  BZAP-17940 test PDOA date on Enterprise Closed WOn Opportunity,PDOA = null after Insert)
    */
    @isTest
    public static void testSetPDOAAndPDOMdateforChageOfOwnership() {
        System.runAs (getTestRunUser()) {
            Test.startTest();
            Account acc = [SELECT id from Account where Restaurant_Id__c = '8991'];
            Contact contact = TDdAccountFactory.createContacts(1, acc.Id)[0];
            Opportunity opp = TDdOpportunityFactory.createOpportunityByDevRT(TEST_OPPORTUNITY_NAME_FOR_MX_ONBOARDING, acc.Id, contact.Id, 'Closed Won', 'ML_Inside_Sales');
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
            opp.Type = CDdMxSxConstants.OPPORTUNITY_TYPE_CHANGE_OF_OWNERSHIP;
            opp.Platform__c = 'Doordash';
            opp.Change_of_Ownership_Effective_Date__c = System.today().addDays(9);
            insert opp;
            Test.stopTest();
            Opportunity testOpp = [SELECT Id, AccountId, Proposed_Date_of_Activation__c, Menu_URL__c, Change_of_Ownership_Effective_Date__c FROM Opportunity WHERE Id = :opp.Id ];
            System.assertEquals(
                testOpp.Change_of_Ownership_Effective_Date__c.format(),
                testOpp.Proposed_Date_of_Activation__c.format(),
                'Proposed date of Activation is Incorrect'
            );
        }
    }
     /**
    * @description  BZAP-17940 test PDOA date on Enterprise Closed WOn Opportunity,PDOA = null after Insert)
    */
    @isTest
    public static void testSetPDOMdateforEnterpriseOpportunities() {
        System.runAs (getTestRunUser()) {
            Test.startTest();
            Account acc = [SELECT id from Account where Restaurant_Id__c = '8991'];
            Contact contact = TDdAccountFactory.createContacts(1, acc.Id)[0];
            Opportunity opp = TDdOpportunityFactory.createOpportunityByDevRT(TEST_OPPORTUNITY_NAME_FOR_MX_ONBOARDING, acc.Id, contact.Id, 'Closed Won', 'Enterprise_Marketplace');
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
            opp.Proposed_Date_of_Menu__c = null;
            opp.Proposed_Date_of_Activation__c = null;
            opp.POS_Integration_Type__c = 'non_integrated_mx';
            opp.Type = 'New Partner (Create Menu + Nimda)';
            insert opp;
            Test.stopTest();
            Opportunity testOpp = [SELECT Id, AccountId, Proposed_Date_of_Activation__c, Proposed_Date_of_Menu__c,Menu_URL__c FROM Opportunity WHERE AccountId =:acc.Id ];
            System.assertEquals(
                Date.valueOf(CDdMxSxConstants.addBusinessDays(Date.today(), 4)).format(),
                Date.valueOf(testOpp.Proposed_Date_of_Menu__c).format(),
                'Proposed date of Menu is Incorrect'
            );
        }
    }
   /**
    * @description Return the test opportunity record created in the setup method
    */
   private static Opportunity getMxOnboardingOpportunity() {
       return [SELECT Id, AccountId, Proposed_Date_of_Activation__c, Menu_URL__c FROM Opportunity WHERE Name = :TEST_OPPORTUNITY_NAME_FOR_MX_ONBOARDING LIMIT 1];
   }
   /**
    * @description Create and return List of Events for the Decision maker
    */
   public static List<Event> createEvent(String name, String whoId, Datetime startTime, Datetime endTime, String etype, Boolean doInsert){
       List<Event> events = new List<Event>();
       Event e = new Event(Subject = name, WhoId = whoId, Type = etype, StartDateTime = startTime, EndDateTime = endTime);
       events.add(e);
       if(doInsert){
          insert events;
       }
       return events;
   }
   private static Case getMarketPlaceOnboaringCase(Id opportunityId){
    Case marketplaceCase = null;
    for (Case c :   [   SELECT Id, RecordTypeId, Status, Stage__c
                        FROM Case
                        WHERE RecordTypeId = :CDdMxSxConstants.RECORD_TYPE_ID_CASE_MARKETPLACE_ONBOARDING
                        AND Opportunity_Name__c = :opportunityId]){
                            marketplaceCase = c;
    }
    return marketplaceCase;
}
    /**
     * @description BZAP-20210 - Test scenario related Mx SSMO Fraud feature
     * Business Verification Status - Documentation Required
     */
    @isTest
    public static void testBusinessVerificationStatusDocumenationRequired() {
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
            Milestone__c testMilestoneFromDB  = [   SELECT Id, Status__c, Status_Reason__c
                                                    FROM Milestone__c
                                                    WHERE Case__r.Account.Restaurant_Id__c = :TEST_STORE_ID
                                                    AND RecordTypeId = :CDdMxSxConstants.MILESTONE_RECORD_TYPE_ID_REVIEW_AND_TRIAGE];
            System.assert(testMilestoneFromDB != null);
            System.assertEquals('Blocked', testMilestoneFromDB.Status__c);
            System.assertEquals('Fraud', testMilestoneFromDB.Status_Reason__c);
            testOnboardingRecordFromDB = [  SELECT Id, StoreId__c, Business_Verification_Status__c, UpdateType__c
                                            FROM Mx_Onboarding__c
                                            WHERE StoreId__c = :TEST_STORE_ID
                                            LIMIT 1];
            System.assert(!'Inbound'.equals(testOnboardingRecordFromDB.UpdateType__c));
        }
    }
    /**
     * @description BZAP-20210 - Test scenario related Mx SSMO Fraud feature
     * Business Verification Status - Denied
     */
    @isTest
    public static void testBusinessVerificationStatusDenied() {
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
            Milestone__c testMilestoneFromDB  = [   SELECT Id, Status__c, Status_Reason__c
                                                    FROM Milestone__c
                                                    WHERE Case__r.Account.Restaurant_Id__c = :TEST_STORE_ID
                                                    AND RecordTypeId = :CDdMxSxConstants.MILESTONE_RECORD_TYPE_ID_REVIEW_AND_TRIAGE];
            System.assert(testMilestoneFromDB != null);
            System.assertEquals('Dead', testMilestoneFromDB.Status__c);
            System.assertEquals('Fraud', testMilestoneFromDB.Status_Reason__c);
            testOnboardingRecordFromDB = [  SELECT Id, StoreId__c, Business_Verification_Status__c, UpdateType__c
                                            FROM Mx_Onboarding__c
                                            WHERE StoreId__c = :TEST_STORE_ID
                                            LIMIT 1];
            System.assert(!'Inbound'.equals(testOnboardingRecordFromDB.UpdateType__c));
        }
    }
    /**
     * @description BZAP-20210 - Test scenario related Mx SSMO Fraud feature
     * Business Verification Status - Approved
     */
    @isTest
    public static void testBusinessVerificationStatusApproved() {
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
                                        Business_Verification_Status_Reason__c = 'Test Status Reason To Save',
                                        Business_Verification_Status__c = CDdMxOnBoardingMilestoneHelper.BUSINESS_VERIFICATION_STATUS_DOCUMENTATION_APPROVED);
            Test.stopTest();
            Milestone__c testMilestoneFromDB  = [   SELECT Id, Status__c, Status_Reason__c
                                                    FROM Milestone__c
                                                    WHERE Case__r.Account.Restaurant_Id__c = :TEST_STORE_ID
                                                    AND RecordTypeId = :CDdMxSxConstants.MILESTONE_RECORD_TYPE_ID_REVIEW_AND_TRIAGE];
            System.assert(testMilestoneFromDB != null);
            System.assertEquals('Complete', testMilestoneFromDB.Status__c);
            System.assert(testMilestoneFromDB.Status_Reason__c == NULL);
            testOnboardingRecordFromDB = [  SELECT Id, StoreId__c, Business_Verification_Status__c, UpdateType__c
                                            FROM Mx_Onboarding__c
                                            WHERE StoreId__c = :TEST_STORE_ID
                                            LIMIT 1];
            System.assert(!'Inbound'.equals(testOnboardingRecordFromDB.UpdateType__c));

            List<Mx_Business_Verification_Status_Reason__c> reasonsList = [SELECT Id, Status_Reason__c
                                                                            FROM Mx_Business_Verification_Status_Reason__c LIMIT 1];

            system.assert(reasonsList[0].Status_Reason__c == 'Test Status Reason To Save');
        }
    }
}