/********************************************************************************************************************
* @author Venkat D
* @date 08/11/2022
*
* @description Test for Event PlatformEventHandler
*********************************************************************************************************************/
@isTest
public class CDdEventPlatformEventHandlerTest {
	public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser_1@doordash.com';
    public static final Id SYSTEM_ADMIN_PROFILE_ID;

    static {
        TEST_ROLE_ID = [SELECT Id FROM UserRole WHERE DeveloperName = 'COO'].Id;
        SYSTEM_ADMIN_PROFILE_ID = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
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
        System.runAs(getTestRunUser()){
            Test.startTest();
            vCS__c s = VTestUtil.createVeltigSettings();
            s.parentAccMatchFlag__c = true;
            insert s;
            E2F__FindApi_Triggers_Settings__c findAPISettings = new E2F__FindApi_Triggers_Settings__c(
                SetupOwnerId = SYSTEM_ADMIN_PROFILE_ID
                , Name = 'System Administrator'
                , E2F__Bypass_Trigger__c = true
            );
            insert findAPISettings;
            /* Create Serve Users - Begin */
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
            /* Create Serve Users - End */

            List<Account> Accounts = TDdAccountFactory.createAccounts('Account Test', 2);
            List<Account> checkAccounts;
            for (Integer i = 1; i <= Accounts.size(); i++) {    // Associate a lead with each account
                Accounts[i-1].Restaurant_ID__c = '' +i;
            }
            insert Accounts;
            Test.stopTest();
        }
    }
    /**
    * @description testing lead trigger handler coverage
    */
    @isTest
    public static void testPreSaleEventHeldDMPitchInfluencerPitch(){
        System.runAs(getTestRunUser()){
            Test.setMock(HttpCalloutMock.class, new CDdCoverageCheckV2CalloutMock());
            List<Account> accts = TDdAccountFactory.createAccounts('test', 2,'Parent Account');
            accts[0].Business_ID__c = 1;
            accts[0].of_leads_on_parent__c = 4;
            insert accts;

            Test.startTest();
            List<Lead> testLeads = TDdLeadFactory.createLeads('Test Lead 1', 4, 'Master Lead', false);
            for(Lead leadRec:testLeads){
                leadRec.Parent_Account__c = accts[0].Id;
            }
            insert testLeads;
            //List<Lead> updatedLeads = [SELECT Id, In_Coverage__c, Parent_Account__c FROM Lead WHERE Id IN :testLeads];

            Event preSaleEventDMPitch = new Event(WhoId=testLeads[0].Id,Type='Meeting',Event_OutCome__c='Held - DM Pitch',
                                           DurationInMinutes=30,ActivityDateTime=System.today()+10);
            Event preSaleEventInfluencerPitch = new Event(WhoId=testLeads[0].Id,Type='Meeting',Event_OutCome__c='Held - Influencer Pitch',
                                           DurationInMinutes=30,ActivityDateTime=System.today()+10,Parent_Account__c=accts[0].Id);
            insert new List<Event>{preSaleEventDMPitch,preSaleEventInfluencerPitch};

            Test.getEventBus().deliver();
            Test.stopTest();

            Lead updatedLead1 = [SELECT Id, In_Coverage__c, Parent_Account__c,Status,Last_Meeting_Ran__c,Last_Meeting_Set__c FROM Lead WHERE Id = :testLeads[0].Id];
            Account updatedAccount = [SELECT Id,Name,Last_Meeting_Ran__c,Last_Meeting_Set__c FROM Account WHERE Id = :accts[0].Id];
            Lead siblingLead = [SELECT Id, In_Coverage__c, Parent_Account__c,Status,Last_Meeting_Ran__c,Last_Meeting_Set__c FROM Lead WHERE Id != :testLeads[0].Id AND Parent_Account__c = :accts[0].Id Limit 1];
            System.assert(updatedLead1.Status == CDdEventPlatformEventHandler.LEAD_STATUS_MEETING_RAN_NEGOTOATED);
            System.assert(siblingLead.Status == CDdEventPlatformEventHandler.LEAD_STATUS_MEETING_RAN_NEGOTOATED);
            System.assert(updatedAccount.Last_Meeting_Ran__c != null);
        }
    }

    @isTest
    public static void testPreSaleEventNoShowUnQualified(){
        System.runAs(getTestRunUser()){
            Test.setMock(HttpCalloutMock.class, new CDdCoverageCheckV2CalloutMock());
            List<Account> accts = TDdAccountFactory.createAccounts('test', 2,'Parent Account');
            accts[0].Business_ID__c = 1;
            accts[0].of_leads_on_parent__c = 4;
            insert accts;

            Test.startTest();
            List<Lead> testLeads = TDdLeadFactory.createLeads('Test Lead 2', 4, 'Master Lead', false);
            for(Lead leadRec:testLeads){
                leadRec.Parent_Account__c = accts[0].Id;
            }
            insert testLeads;

            //List<Lead> updatedLeads = [SELECT Id, In_Coverage__c, Parent_Account__c FROM Lead WHERE Id IN :testLeads];

            Event outcomeNoShowEvent = new Event(WhoId=testLeads[0].Id,Type='Meeting',Event_OutCome__c='No-Show',
                                           DurationInMinutes=30,ActivityDateTime=System.today()+10);
            Event outcomeUnqualifiedEvent = new Event(WhoId=testLeads[0].Id,Type='Meeting',Event_OutCome__c='Unqualified',
                                           DurationInMinutes=30,ActivityDateTime=System.today()+10,Parent_Account__c=accts[0].Id);
            insert new List<Event>{outcomeNoShowEvent,outcomeUnqualifiedEvent};

            Test.getEventBus().deliver();
            Test.stopTest();

            Lead updatedLead1 = [SELECT Id, In_Coverage__c, Parent_Account__c,Status,Last_Meeting_Ran__c,Last_Meeting_Set__c FROM Lead WHERE Id = :testLeads[0].Id];
            Account updatedAccount = [SELECT Id,Name,Last_Meeting_Ran__c,Last_Meeting_Set__c FROM Account WHERE Id = :accts[0].Id];
            Lead siblingLead = [SELECT Id, In_Coverage__c, Parent_Account__c,Status,Last_Meeting_Ran__c,Last_Meeting_Set__c FROM Lead WHERE Id != :testLeads[0].Id AND Parent_Account__c = :accts[0].Id Limit 1];
            System.assert(updatedLead1.Status == CDdEventPlatformEventHandler.LEAD_STATUS_DM_FOUND);
            System.assert(siblingLead.Status == CDdEventPlatformEventHandler.LEAD_STATUS_DM_FOUND);

        }
    }

    @isTest
    public static void testPreSaleEventNoOutCome(){
        System.runAs(getTestRunUser()){
            Test.setMock(HttpCalloutMock.class, new CDdCoverageCheckV2CalloutMock());
            List<Account> accts = TDdAccountFactory.createAccounts('test', 1,'Parent Account');
            accts[0].Business_ID__c = 1;
            accts[0].of_leads_on_parent__c = 4;
            insert accts;

            Test.startTest();
            List<Lead> testLeads = TDdLeadFactory.createLeads('Test Lead 3', 4, 'Master Lead', false);
            for(Lead leadRec:testLeads){
                leadRec.Parent_Account__c = accts[0].Id;
            }
            insert testLeads;

            Event outcomeNullEvent1 = new Event(WhoId=testLeads[0].Id,Type='Meeting',Event_OutCome__c=null,
                                           DurationInMinutes=30,ActivityDateTime=System.today()+10);
            Event outcomeNullEvent2 = new Event(WhoId=testLeads[0].Id,Type='Meeting',Event_OutCome__c=null,
                                           DurationInMinutes=30,ActivityDateTime=System.today()+10,Parent_Account__c=accts[0].Id);
            insert new List<Event>{outcomeNullEvent1,outcomeNullEvent2};

            Test.getEventBus().deliver();
            Test.stopTest();

            Lead updatedLead1 = [SELECT Id, In_Coverage__c, Parent_Account__c,Status,Last_Meeting_Ran__c,Last_Meeting_Set__c FROM Lead WHERE Id = :testLeads[0].Id];
            Account updatedAccount = [SELECT Id,Name,Last_Meeting_Ran__c,Last_Meeting_Set__c FROM Account WHERE Id = :accts[0].Id];
            Lead siblingLead = [SELECT Id, In_Coverage__c, Parent_Account__c,Status,Last_Meeting_Ran__c,Last_Meeting_Set__c FROM Lead WHERE Id != :testLeads[0].Id AND Parent_Account__c = :accts[0].Id Limit 1];
            System.assert(updatedLead1.Status == CDdEventPlatformEventHandler.LEAD_STATUS_MEETING_SET);
            System.assert(siblingLead.Status == CDdEventPlatformEventHandler.LEAD_STATUS_MEETING_SET);
            System.assert(updatedAccount.Last_Meeting_Set__c != null);

        }
    }
}