@isTest
public class CDdCampaignItemTriggerHandlerTest {

    public static final Id SYSTEM_ADMIN_PROFILE_ID;
    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    public static final String TEST_DD_OPPORTUNITY_0 = 'TestOpportunity0';

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
    * @description Prepare test data
    */
    @testSetup
    static void setup() {
        System.runAs(getTestRunUser()) {
            Test.startTest();

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

            List<Account> testAccounts = TDdAccountFactory.createAccounts('TestDDAccount', 1);
            Account testAcct = testAccounts[0];
            testAcct.Name = 'TestDDAccount';
            insert testAcct;

            Contact testContact1 = TDdAccountFactory.createContacts(1, testAcct.Id)[0];
            testContact1.FirstName = 'TestDDContactFirstName1';
            testContact1.LastName = 'TestDDContactLastName1';
            testContact1.Email = 'TestDDContactEmail1' + '@tes.com';
            insert testContact1;

            Opportunity testOpp1 = TDdOpportunityFactory.createOpportunity(TEST_DD_OPPORTUNITY_0, testAcct.Id, testContact1.Id, 'Closed Won');
            testOpp1.Menu_Completion_Date__c = System.today();
            testOpp1.Commission__c = 20;
            insert testOpp1;

            TDdOpportunityLineItemFactory.createProducts();

            Id promotionsId = [select Id from PricebookEntry where Product2.Family = 'Promotions' limit 1].Id;

            List<OpportunityLineItem> olis = TDdOpportunityLineItemFactory.createOpportunityProducts(testOpp1.Id);
            for (OpportunityLineItem oli : olis) {
                if (oli.PricebookEntryId.equals(promotionsId)) {
                    oli.Billing_Frequency__c = 'Quarterly';
                    oli.Commission_Rate__c = 1.00;
                    oli.Service_Fee__c = 1.00;
                }
            }
            insert olis;

            CDdCampaignBriefController.createCampaignBrief(testOpp1.Id);

            Test.getEventBus().deliver();
            Test.stopTest();
        }
    }

    /**
    * @description Create Opportunity Products and test for default values
    */
    @isTest
    static void testUpdateCampaignItems() {

        System.runAs(getTestRunUser()) {
            Opportunity opp = [SELECT Id, Name FROM Opportunity WHERE Name = :TEST_DD_OPPORTUNITY_0 LIMIT 1];
            Campaign_Item__c item = [SELECT Id, Name FROM Campaign_Item__c WHERE Salesforce_Opportunity__c = :opp.Id LIMIT 1];

            Campaign_Brief__c brief = new Campaign_Brief__c();
            brief.Salesforce_Opportunity__c = opp.Id;
            brief.Configuration__c = 'Standard (Mx Services)';
            insert brief;

            Group gr = [SELECT id, Name,DeveloperName FROM Group
                        WHERE Type='Queue' AND DeveloperName ='Campaign_Items_Launch_Ops' LIMIT 1];

            Test.StartTest();

                item.Campaign_Brief__c = brief.Id;
                item.Max_Number_of_Redemptions_per_Cx__c = '10';
                update item;

                item = [SELECT Id, Name, OwnerId FROM Campaign_Item__c WHERE Salesforce_Opportunity__c = :opp.Id LIMIT 1];
                System.assertEquals(item.OwnerId, gr.Id);

                delete item;

            Test.StopTest();


        }
    }
}