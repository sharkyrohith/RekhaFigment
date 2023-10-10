/********************************************************************************************************************
* @author Lathika
* @date 08/10/2022
*
* @group Merchant Services
*
* @description Test Merchant Onboarding Status Functinality  
* 
**************************************************************************************************************************************/
@isTest
public with sharing class CDdMxOnboardingMxSxEventHandlerTest {
    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    public static final String TEST_OPP_PACTSAFE_CONTRACT_TYPE = 'English Sign Up Sheet';
    public static final String TEST_OPPORTUNITY_NAME_FOR_MX_ONBOARDING = 'MxSx_Test_Opp_123';
    public static final String TEST_OPPORTUNITY_NAME_FOR_MX_ONBOARDING_ENTERPRISE = 'MxSx_Test_Opp_123_ENT';
    public static final String TEST_OPPORTUNITY_MX_ONBOARDING_MENU_URL = 'www.testmenu.com';
    public static final String TEST_OPPORTUNITY_MX_ONBOARDING_UPDATED_MENU_URL = 'www.testmenuupdated.com';
    public static final Id RECORD_TYPE_ID_CASE_TABLET_REQUESTS = CDdSchemaUtils.CASE_RT.tabletRequestsId();

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

            Test.startTest();
            PriceBook2 pricebook = new Pricebook2(Id = Test.getStandardPricebookId(), isActive = true);
            update pricebook;
    
            Submarket__c submarket = TDdCPQTestDataFactory.createSubmarket('New York', 'NEW YORK', 10, null, true);
            RealZip__RealZips__c realZip = TDdCPQTestDataFactory.createRealZip(submarket, false);
            realZip.Alcohol_Eligibility__c = 'Pickup';
            insert realZip; 
            List<Account> acclist = new List<Account>();
            //Marketplace Account
            Account account = TDdAccountFactory.createAccounts('Account', 1)[0];
            account.RealZip__RealZip__c = realZip.Id;
            account.Business_ID__c = 1234567;
            account.Deck_Rank__c = 'Queen';
            account.Restaurant_Id__c = '123456';
            account.iPad_Username__c = '12345678';
            account.iPad_Password__c = '12345678';
            acclist.add(account);

            // Enterprise Marketplace Account
            Account accountEnterprise = TDdAccountFactory.createAccount(CDdMxSxConstants.RECORD_TYPE_ID_ACCOUNT_ENTERPRISE_MARKETPLACE);
            accountEnterprise.RealZip__RealZip__c = realZip.Id;
            accountEnterprise.Business_ID__c = 12345678;
            accountEnterprise.Deck_Rank__c = 'Ace of Spades';
            accountEnterprise.Restaurant_Id__c = '88765';
            accountEnterprise.iPad_Username__c = '123456789';
            accountEnterprise.iPad_Password__c = '123456789';
            acclist.add(accountEnterprise);
            insert acclist;
            Id accountID = [Select id from Account where Restaurant_Id__c = '123456'].id;
            Contact contact = TDdAccountFactory.createContacts(1, accountID)[0];
            insert contact;
            String contactId = contact.Id ;
            createEvent('Storefront Implementation Call', contactId, System.Now().addMinutes(15), System.Now().addMinutes(15), 'Meeting', true);

            List<Opportunity> oppList = new List<Opportunity>();
            Opportunity opp = TDdOpportunityFactory.createOpportunityByDevRT(TEST_OPPORTUNITY_NAME_FOR_MX_ONBOARDING, account.Id, contact.Id, 'Closed Won', 'ML_Inside_Sales');
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
            opp.Proposed_Date_of_Activation__c = System.today().addDays(1);
            oppList.add(opp);

            Opportunity oppEnt = TDdOpportunityFactory.createOpportunityByDevRT(TEST_OPPORTUNITY_NAME_FOR_MX_ONBOARDING_ENTERPRISE, accountEnterprise.Id, contact.Id, 'Closed Won', 'Enterprise_Marketplace');
            oppEnt.Commission__c = 15;
            oppEnt.In_App_Pickup_Commission__c = 15;
            oppEnt.DashPass_Only_Commission__c = 15;
            oppEnt.Referred_Delivery_Commission__c = 15;
            oppEnt.Referred_Pickup_Commission__c = 15;
            oppEnt.Weekly_Printer_Subscription_Fee__c = '$0';
            oppEnt.Activation_Fee__c = '$0';
            oppEnt.Weekly_Tablet_Subscription_Fee__c = '$3';
            oppEnt.PactSafe_Contract_Type__c = TEST_OPP_PACTSAFE_CONTRACT_TYPE;
            oppEnt.Delivery_Inflation_Opp__c = 'Yes & POS Blocked';
            oppEnt.Menu_URL__c = TEST_OPPORTUNITY_MX_ONBOARDING_MENU_URL;
            oppEnt.Proposed_Date_of_Menu__c = System.today().addDays(1);
            oppEnt.Proposed_Date_of_Activation__c = System.today().addDays(1);
            oppList.add(oppEnt);
            insert oppList;
            
            Test.getEventBus().deliver();   
            Test.stopTest();
            }
    }
    /**
     * @description test create Mx Onboarding Record on Case Insert
     */    
    @isTest
    public static void testMxOnboardingInsert() {
        System.runAs (getTestRunUser()) {
            List<Mx_Onboarding__c>  mxOnboardingRecord = [Select id, StoreId__c, Menu_MenuUrl__c, Proposed_Date_of_Activation__c, Tablet_Status__c,
                                                          Tablet_OwnerLastName__c, Tablet_OwnerFirstName__c, Menu_ProposedDateofMenu__c, Case_Stage__c, Case_Status__c,
                                                          SetupStore_Status__c, Tablet_ShippingAddress_Country__c, Tablet_ShippingStatus__c, Tablet_ShippingAddress_City__c,
                                                          Tablet_ShippingAddress_AddressLine1__c, Tablet_ShippingAddress_State__c
                                                          from Mx_Onboarding__c where StoreId__c = '123456'];                                              
             System.assertEquals(mxOnboardingRecord.size(), 1);
        }
    }
     /**
     * @description test create Mx Onboarding Record
     */    
    @isTest
    public static void testMxOnboardingUpdate() {
        System.runAs (getTestRunUser()) {
            Test.startTest();
            Opportunity opportunity = getMxOnboardingOpportunity();
            Case tabletRequestCase = getTableRequestCase(opportunity.Id);
            Map<Id, Case> onboardingCases = new Map<Id, Case>([ SELECT Id, RecordTypeId, RecordType.Name 
                                                                FROM Case 
                                                                WHERE Opportunity_name__c = :opportunity.Id
                                                                AND RecordTypeId = :CDdMxSxConstants.RECORD_TYPE_ID_CASE_MARKETPLACE_ONBOARDING]);
            Map<Id, Milestone__c> milestoneByRecordTypeId = new Map<Id, Milestone__c>();
            for (Milestone__c m : [ SELECT Id, Name, RecordTypeId, Case__c, Status__c, Status_Reason__c 
                                    FROM Milestone__c 
                                    WHERE Case__c IN :onboardingCases.keySet() 
                                    AND Case__r.RecordTypeId = :CDdMxSxConstants.RECORD_TYPE_ID_CASE_MARKETPLACE_ONBOARDING 
                                   ]){
                milestoneByRecordTypeId.put(m.RecordTypeId, m);
            }
            //updating Tablet milestone to complete
            Milestone__c tabletMilestone = milestoneByRecordTypeId.get(CDdMxSxConstants.MILESTONE_RECORD_TYPE_ID_DELIVER_TABLET);
            tabletMilestone.Status__c = CDdMxSxConstants.MILESTONE_STATUS_IN_PROGRESS;
            update tabletMilestone;
            Test.getEventBus().deliver();   
            Test.stopTest();
            // fetching the MxOrder record linked to the Tabletcase
            Mx_Order__c mxOrder = [SELECT Id, Contact_First_Name__c, Contact_Last_Name__c, Country__c, Order_Status__c,
                                   City__c, Address_Line1__c, State__c FROM Mx_Order__c WHERE Case__c = :tabletRequestCase.Id LIMIT 1];
            System.assertEquals(true, mxOrder.Id != null, 'Expecting a Mx Order to be generated/created');
             // fetching the MxOnBoardingrecord record to assert the tabelt related fields
            List<Mx_Onboarding__c>  mxOnboardingRecord = [Select id, StoreId__c, Menu_MenuUrl__c, Proposed_Date_of_Activation__c, Tablet_Status__c,
                                                          Tablet_OwnerLastName__c, Tablet_OwnerFirstName__c, Menu_ProposedDateofMenu__c, Case_Stage__c, Case_Status__c,
                                                          SetupStore_Status__c, Tablet_ShippingAddress_Country__c, Tablet_ShippingStatus__c, Tablet_ShippingAddress_City__c,
                                                          Tablet_ShippingAddress_AddressLine1__c, Tablet_ShippingAddress_State__c
                                                          from Mx_Onboarding__c where StoreId__c = '123456'];                                              
             System.assertEquals(mxOnboardingRecord.size(), 1);
             System.assertEquals('123456', mxOnboardingRecord[0].StoreId__c);
             System.assertEquals(TEST_OPPORTUNITY_MX_ONBOARDING_MENU_URL, mxOnboardingRecord[0].Menu_MenuUrl__c);
             System.assertEquals(System.today().addDays(1), mxOnboardingRecord[0].Proposed_Date_of_Activation__c);
             System.assertEquals(System.today().addDays(1), mxOnboardingRecord[0].Menu_ProposedDateofMenu__c);
             System.assertEquals('Under Review', mxOnboardingRecord[0].Case_Stage__c);
             System.assertEquals('In Progress', mxOnboardingRecord[0].Case_Status__c);
             System.assertEquals('Not Started', mxOnboardingRecord[0].SetupStore_Status__c);
             System.assertEquals('In Progress', mxOnboardingRecord[0].Tablet_Status__c);
             System.assertEquals(mxOrder.Contact_Last_Name__c, mxOnboardingRecord[0].Tablet_OwnerLastName__c);
             System.assertEquals(mxOrder.Contact_First_Name__c, mxOnboardingRecord[0].Tablet_OwnerFirstName__c);
             System.assertEquals(mxOrder.Country__c, mxOnboardingRecord[0].Tablet_ShippingAddress_Country__c);
             System.assertEquals(mxOrder.Order_Status__c, mxOnboardingRecord[0].Tablet_ShippingStatus__c);
             System.assertEquals(mxOrder.City__c, mxOnboardingRecord[0].Tablet_ShippingAddress_City__c);
             System.assertEquals(mxOrder.Address_Line1__c, mxOnboardingRecord[0].Tablet_ShippingAddress_AddressLine1__c);
             System.assertEquals(mxOrder.State__c, mxOnboardingRecord[0].Tablet_ShippingAddress_State__c);
        }
    }
     /**
     * @description test OpportunityUpdates after Closed Won
     */    
    @isTest
    public static void testMxOnboardinghandleOpportunityUpdates() {
        System.runAs (getTestRunUser()) {
            Test.startTest();
            Opportunity opportunity = getMxOnboardingOpportunity();
            opportunity.Menu_URL__c = TEST_OPPORTUNITY_MX_ONBOARDING_UPDATED_MENU_URL;
            opportunity.Proposed_Date_of_Activation__c = System.today().addDays(2);
            update opportunity;
            Test.getEventBus().deliver();   
            Test.stopTest();
            
             // fetching the MxOnBoardingrecord record to assert the tabelt related fields
            List<Mx_Onboarding__c>  mxOnboardingRecord = [Select id, StoreId__c, Menu_MenuUrl__c, Proposed_Date_of_Activation__c, Tablet_Status__c,
                                                          Tablet_OwnerLastName__c, Tablet_OwnerFirstName__c, Menu_ProposedDateofMenu__c, Case_Stage__c, Case_Status__c,
                                                          SetupStore_Status__c, Tablet_ShippingAddress_Country__c, Tablet_ShippingStatus__c, Tablet_ShippingAddress_City__c,
                                                          Tablet_ShippingAddress_AddressLine1__c, Tablet_ShippingAddress_State__c
                                                          from Mx_Onboarding__c where StoreId__c = '123456'];                                              
             System.assertEquals(mxOnboardingRecord.size(), 1);
             System.assertEquals('123456', mxOnboardingRecord[0].StoreId__c);
             System.assertEquals(TEST_OPPORTUNITY_MX_ONBOARDING_UPDATED_MENU_URL, mxOnboardingRecord[0].Menu_MenuUrl__c);
             System.assertEquals(System.today().addDays(2), mxOnboardingRecord[0].Proposed_Date_of_Activation__c);
        }
    }
     /**
     * @description test update Mx Onboarding Record for Milestone dead
     */    
    @isTest
    public static void testMxOnboardingUpdateDead() {
        System.runAs (getTestRunUser()) {
            Test.startTest();
            Opportunity opportunity = getMxOnboardingOpportunity();
            Map<Id, Case> onboardingCases = new Map<Id, Case>([ SELECT Id, RecordTypeId, RecordType.Name 
                                                                FROM Case 
                                                                WHERE Opportunity_name__c = :opportunity.Id
                                                                AND RecordTypeId = :CDdMxSxConstants.RECORD_TYPE_ID_CASE_MARKETPLACE_ONBOARDING]);
            Map<Id, Milestone__c> milestoneByRecordTypeId = new Map<Id, Milestone__c>();
            for (Milestone__c m : [ SELECT Id, Name, RecordTypeId, Case__c, Status__c, Status_Reason__c 
                                    FROM Milestone__c 
                                    WHERE Case__c IN :onboardingCases.keySet() 
                                    AND Case__r.RecordTypeId = :CDdMxSxConstants.RECORD_TYPE_ID_CASE_MARKETPLACE_ONBOARDING 
                                   ]){
                milestoneByRecordTypeId.put(m.RecordTypeId, m);
            }
            //updating Tablet milestone to complete
            Milestone__c reviewAndTriageMilestone = milestoneByRecordTypeId.get(CDdMxSxConstants.MILESTONE_RECORD_TYPE_ID_REVIEW_AND_TRIAGE);
            reviewAndTriageMilestone.Status__c = CDdMxSxConstants.MILESTONE_STATUS_DEAD;
            reviewAndTriageMilestone.Status_Reason__c =  'Duplicate Onboarding Record';
            update reviewAndTriageMilestone;

            Test.getEventBus().deliver();   
            Test.stopTest();
             // fetching the MxOnBoardingrecord record to assert the tabelt related fields
            List<Mx_Onboarding__c>  mxOnboardingRecord = [Select id, StoreId__c, Menu_MenuUrl__c, Proposed_Date_of_Activation__c, Tablet_Status__c,
                                                          Tablet_OwnerLastName__c, Tablet_OwnerFirstName__c, Menu_ProposedDateofMenu__c, Case_Stage__c, Case_Status__c,
                                                          SetupStore_Status__c, Tablet_ShippingAddress_Country__c, Tablet_ShippingStatus__c, Tablet_ShippingAddress_City__c,
                                                          Tablet_ShippingAddress_AddressLine1__c, Tablet_ShippingAddress_State__c
                                                          from Mx_Onboarding__c where StoreId__c = '123456'];                                              
             System.assertEquals(mxOnboardingRecord.size(), 1);
             System.assertEquals('123456', mxOnboardingRecord[0].StoreId__c);
             System.assertEquals('Dead', mxOnboardingRecord[0].Case_Status__c);
        }
    }
     /**
     * @description test for Enterprise Merchant
     */    
    @isTest
    public static void testMxOnboardingEnterprise() {
        System.runAs (getTestRunUser()) {
            Test.startTest();
            Opportunity opportunity = [SELECT Id, AccountId, SBQQ__PrimaryQuote__c FROM Opportunity WHERE Name = :TEST_OPPORTUNITY_NAME_FOR_MX_ONBOARDING_ENTERPRISE LIMIT 1];
            List<Mx_Onboarding__c>  mxOnboardingRecordbeforeDB = [Select id, StoreId__c, Menu_MenuUrl__c, Proposed_Date_of_Activation__c, Tablet_Status__c, Tablet_OwnerFirstName__c,
            Menu_ProposedDateofMenu__c, Case_Stage__c, Case_Status__c, SetupStore_Status__c from Mx_Onboarding__c where StoreId__c = '88765'];  

            System.assertEquals(mxOnboardingRecordbeforeDB.size(), 0);
            Map<Id, Case> onboardingCases = new Map<Id, Case>([ SELECT Id, RecordTypeId, RecordType.Name 
                                                                FROM Case 
                                                                WHERE Opportunity_name__c = :opportunity.Id
                                                                AND RecordTypeId = :CDdMxSxConstants.RECORD_TYPE_ID_CASE_MARKETPLACE_ONBOARDING]);
            Map<Id, Milestone__c> milestoneByRecordTypeId = new Map<Id, Milestone__c>();
            for (Milestone__c m : [ SELECT Id, Name, RecordTypeId, Case__c, Status__c, Status_Reason__c 
                                    FROM Milestone__c 
                                    WHERE Case__c IN :onboardingCases.keySet() 
                                    AND Case__r.RecordTypeId = :CDdMxSxConstants.RECORD_TYPE_ID_CASE_MARKETPLACE_ONBOARDING 
                                   ]){
                milestoneByRecordTypeId.put(m.RecordTypeId, m);
            }
            //updating Tablet milestone to complete
            Milestone__c setUpStoreMilestone = milestoneByRecordTypeId.get(CDdMxSxConstants.MILESTONE_RECORD_TYPE_ID_SETUP_STORE);
            setUpStoreMilestone.Status__c = CDdMxSxConstants.MILESTONE_STATUS_COMPLETE;
            update setUpStoreMilestone;            
            }
            Test.getEventBus().deliver();   
            Test.stopTest();
            List<Mx_Onboarding__c>  mxOnboardingRecord = [Select id, StoreId__c, Menu_MenuUrl__c, Proposed_Date_of_Activation__c, Tablet_Status__c, Tablet_OwnerFirstName__c,
                                                          Menu_ProposedDateofMenu__c, Case_Stage__c, Case_Status__c, SetupStore_Status__c from Mx_Onboarding__c where StoreId__c = '88765'];  
            
            System.assertEquals(mxOnboardingRecord.size(), 0);
        } 
    /**
     * @description Return the test opportunity record created in the setup method
     */      
    private static Opportunity getMxOnboardingOpportunity() {
        return [SELECT Id, AccountId, SBQQ__PrimaryQuote__c FROM Opportunity WHERE Name = :TEST_OPPORTUNITY_NAME_FOR_MX_ONBOARDING LIMIT 1];
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
    private static Case getTableRequestCase(Id opportunityId){
        Case tabletRequestCase = null;
        for (Case c :   [   SELECT Id, RecordTypeId, Status
                            FROM Case
                            WHERE RecordTypeId = :RECORD_TYPE_ID_CASE_TABLET_REQUESTS
                            AND Opportunity_Name__c = :opportunityId]){
            tabletRequestCase = c;
        }
        return tabletRequestCase;
    }
}