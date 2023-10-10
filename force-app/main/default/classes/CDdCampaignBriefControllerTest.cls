@isTest
public class CDdCampaignBriefControllerTest {

    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_ACCOUNT_PARENT_IDENTIFIERS = 'TestDDAccountParent%';
    public static final String TEST_DD_ACCOUNT_CHILD_IDENTIFIERS = 'TestDDAccountChild%';
    public static final String TEST_DD_OPPORTUNITY_0 = 'TestOpportunity0';
    public static final String TEST_DD_OPPORTUNITY_1 = 'TestOpportunity1';
    public static final String TEST_DD_OPPORTUNITY_2 = 'TestOpportunity2';
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    public static final Decimal TEST_DD_ACCOUNT_PARENT_BUSINESS_ID_1 = 122222;
    public static final Decimal TEST_DD_ACCOUNT_PARENT_BUSINESS_ID_2 = 122223;
    public static final Decimal TEST_DD_ACCOUNT_PARENT_BUSINESS_ID_3 = 122224;
    public static final Id SYSTEM_ADMIN_PROFILE_ID;
    public static final Map<String, Object> PRODUCT_NAME_AND_FAMILY = TDdOpportunityLineItemFactory.PRODUCT_NAME_AND_FAMILY;
    public static final Map<String, Object> DEFAULT_PRODUCT_VALUES = TDdOpportunityLineItemFactory.DEFAULT_PRODUCT_VALUES;
    public static final Map<String, Object> DEFAULT_PRICEBOOK_ENTRY_VALUES = TDdOpportunityLineItemFactory.DEFAULT_PRICEBOOK_ENTRY_VALUES;
    public static final String PRODUCT_NAME_MARKETPLACE_CATERING = 'Marketplace Catering';
    public static final String PRODUCT_NAME_DDFB_GROUP_CART = 'DDfB Group Cart';
    public static final String PRODUCT_NAME_DOORDASH_GIFT_CARDS = 'DoorDash Gift Cards';

    static {
        TEST_ROLE_ID = [SELECT Id FROM UserRole WHERE DeveloperName = 'COO'].Id;
        SYSTEM_ADMIN_PROFILE_ID = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
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

    /**
    * @description Create other users
    */
    private static void createOtherUsers() {
        List<User> testUsers = TDdAccountFactory.createUsers(2, null, TEST_ROLE_ID);
        testUsers[0].Username = 'formstack@doordash.com';
        testUsers[1].Username = 'mx-eng-api@doordash.com';
        insert testUsers;
    }

    /**
    * @description Prepare test data
    */
    @testSetup
    static void setup() {
        createOtherUsers();
        System.runAs(getTestRunUser()) {
            Test.startTest();

            User selfServiceUser1 = [SELECT Id from User WHERE UserName = 'formstack@doordash.com'];
            User selfServiceUser2 = [SELECT Id from User WHERE UserName = 'mx-eng-api@doordash.com'];

            List<Self_Serve_Users__c> selfServeUsersSettings = new List<Self_Serve_Users__c>();
            Self_Serve_Users__c ssUser;
            ssUser = new Self_Serve_Users__c();
            ssUser.name = 'formstack@doordash.com';
            ssUser.User_Id__c = selfServiceUser1.id;
            selfServeUsersSettings.add(ssUser);
            ssUser = new Self_Serve_Users__c();
            ssUser.name = 'mx-eng-api@doordash.com';
            ssUser.User_Id__c = selfServiceUser2.id;
            selfServeUsersSettings.add(ssUser);
            insert selfServeUsersSettings;

            E2F__FindApi_Triggers_Settings__c findAPISettings =
                    new E2F__FindApi_Triggers_Settings__c(SetupOwnerId = SYSTEM_ADMIN_PROFILE_ID, Name = 'System Administrator', E2F__Bypass_Trigger__c = true);
            insert findAPISettings;

            Trigger_Control_Panel__c cp = new Trigger_Control_Panel__c();
            cp.Name = 'Main';
            cp.Opportunity_Trigger_Enabled__c = true;
            cp.Account_Trigger_Enabled__c = true;
            upsert cp;

            vCS__c s = VTestUtil.createVeltigSettings();
            s.parentAccMatchFlag__c = true;
            s.copyFieldsFromParent__c = true;
            s.SetupOwnerId = SYSTEM_ADMIN_PROFILE_ID;
            insert s;

            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
            validation.Bypass_Opportunity_Validations__c = true; 
            insert validation;            

            List<Account> testAccounts = TDdAccountFactory.createAccounts('TestDDAccount', 6);
            Account testAcct0 = testAccounts[0];
            testAcct0.Name = 'TestDDAccountChild0';
            Account testAcct1 = testAccounts[1];
            testAcct1.Name = 'TestDDAccountChild1';
            testAcct1.Lead_Type__c = 'Outside';
            testAcct1.Deck_Rank__c = 'Ace';
            Account testAcct2 = testAccounts[2];
            testAcct2.Name = 'TestDDAccountChild2';
            testAcct2.Lead_Type__c = 'Inside';
            testAcct2.Deck_Rank__c = 'Ace';
            // Create Test Parent Accounts
            Account testAcct3 = testAccounts[3];
            testAcct3.Name = 'TestDDAccountParent0';
            testAcct3.RecordTypeId = CDdSchemaUtils.ACCOUNT_RT.parentAccountId();
            testAcct3.Business_Id__c = TEST_DD_ACCOUNT_PARENT_BUSINESS_ID_1;
            Account testAcct4 = testAccounts[4];
            testAcct4.Name = 'TestDDAccountParent1';
            testAcct4.RecordTypeId = CDdSchemaUtils.ACCOUNT_RT.parentAccountId();
            testAcct4.Business_Id__c = TEST_DD_ACCOUNT_PARENT_BUSINESS_ID_2;
            Account testAcct5 = testAccounts[5];
            testAcct5.Name = 'TestDDAccountParent2';
            testAcct5.RecordTypeId = CDdSchemaUtils.ACCOUNT_RT.parentAccountId();
            testAcct5.Business_Id__c = TEST_DD_ACCOUNT_PARENT_BUSINESS_ID_3;
            // Insert Accounts
            insert testAccounts;
            // Perform update for child accounts
            List<Account> parentAccounts = [SELECT Id FROM Account WHERE NAME LIKE :TEST_DD_ACCOUNT_PARENT_IDENTIFIERS];
            List<Account> childAccounts = [SELECT Id FROM Account WHERE NAME LIKE :TEST_DD_ACCOUNT_CHILD_IDENTIFIERS];
            for (Integer i = 0; i < childAccounts.size(); i++) {
                childAccounts[i].ParentId = parentAccounts[i].Id;
                childAccounts[i].Deck_Rank__c = 'Queen';                // A rank of 5
                childAccounts[i].Amount__c = 200.00;
            }
            update childAccounts;

            Contact testContact1 = TDdAccountFactory.createContacts(1, testAcct1.Id)[0];
            testContact1.FirstName = 'TestDDContactFirstName1';
            testContact1.LastName = 'TestDDContactLastName1';
            testContact1.Email = 'TestDDContactEmail1' + '@tes.com';
            Contact testContact2 = TDdAccountFactory.createContacts(1, testAcct2.Id)[0];
            testContact2.FirstName = 'TestDDContactFirstName2';
            testContact2.LastName = 'TestDDContactLastName2';
            testContact2.Email = 'TestDDContactEmail2' + '@tes.com';
            Contact testContact3 = TDdAccountFactory.createContacts(1, testAcct3.Id)[0];
            testContact3.FirstName = 'TestDDContactFirstName3';
            testContact3.LastName = 'TestDDContactLastName3';
            testContact3.Email = 'TestDDContactEmail3' + '@tes.com';
            List<Contact> testContacts = new List<Contact>{testContact1, testContact2, testContact3};
            insert testContacts;

            Opportunity testOpp1 = TDdOpportunityFactory.createOpportunity(TEST_DD_OPPORTUNITY_0, testAcct0.Id, testContact1.Id, 'Closed Won');
            testOpp1.Menu_Completion_Date__c = System.today();
            testOpp1.Commission__c = 20;

            Opportunity testOpp2 = TDdOpportunityFactory.createOpportunity(TEST_DD_OPPORTUNITY_1, testAcct1.Id, testContact1.Id, 'New');
            testOpp2.Menu_Completion_Date__c = System.today();
            testOpp2.Commission__c = 20;

            Opportunity testOpp3 = TDdOpportunityFactory.createOpportunity(TEST_DD_OPPORTUNITY_2, testAcct2.Id, testContact2.Id, 'Pitching');
            testOpp3.Menu_Completion_Date__c = System.today();
            testOpp3.Commission__c = 20;

            List<Opportunity> testOpps = new List<Opportunity>{testOpp1, testOpp2, testOpp3};
            insert testOpps;

            TDdOpportunityLineItemFactory.createProducts();

            Test.getEventBus().deliver();
            Test.stopTest();
        }
    }



    /**
    * @description Create Opportunity Products and test for default values
    */
    @isTest
    static void testOpportunityProductDefaultValues() {
        Map<String, String> prdMap = CDdOpportunityLineItemHelperMethods.getDefaultFieldMap(CDdOpportunityLineItemHelperMethods.PRD_MAP_MDT);
        Map<String, String> pbeMap = CDdOpportunityLineItemHelperMethods.getDefaultFieldMap(CDdOpportunityLineItemHelperMethods.PBE_MAP_MDT);
        Id promotionsId = [select Id from PricebookEntry where Product2.Family = 'Promotions' limit 1].Id;

        System.runAs(getTestRunUser()) {
            Opportunity opp = [SELECT Id, Name FROM Opportunity WHERE Name = :TEST_DD_OPPORTUNITY_0 LIMIT 1];

            Test.StartTest();

                List<OpportunityLineItem> olis = TDdOpportunityLineItemFactory.createOpportunityProducts(opp.Id);
                for (OpportunityLineItem oli : olis) {
                    if (oli.PricebookEntryId.equals(promotionsId)) {
                        oli.Billing_Frequency__c = 'Quarterly';
                        oli.Commission_Rate__c = 1.00;
                        oli.Service_Fee__c = 1.00;
                    }
                }
                insert olis;
                
                CDdCampaignBriefController.createCampaignBrief(opp.Id);
            Test.StopTest();
            
        }
    }
}