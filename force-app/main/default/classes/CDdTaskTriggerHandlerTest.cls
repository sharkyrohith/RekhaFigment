/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 08/02/2019
*
* @group Trigger Handler Test
*
* @description Test for Task Trigger Hanlder
**************************************************************************************************************************************/
@isTest
public class CDdTaskTriggerHandlerTest {
    private static final Decimal TEST_BUSINESS_ID = 7678900.0;
    public static final Map<String, Schema.RecordTypeInfo> ACCOUNT_RECORD_TYPE_INFO_BY_DEV_NAME
                                                = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();
    public static final String RECORD_TYPE_DEV_NAME_PARENT_ACCOUNT = 'Parent_Account';
    /**
    * @description Prepare test data
    */
    @testSetup
    static void setup() {
        String sysAdminProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        vCS__c s = VTestUtil.createVeltigSettings();
        s.parentAccMatchFlag__c = true;
        s.copyFieldsFromParent__c = true;
        s.SetupOwnerId = sysAdminProfileId;
        insert s;

        E2F__FindApi_Triggers_Settings__c findAPISettings = new E2F__FindApi_Triggers_Settings__c(
                                                            SetupOwnerId = sysAdminProfileId
                                                            , Name = 'System Administrator'
                                                            , E2F__Bypass_Trigger__c = true
                                                        );
        insert findAPISettings;
        // insert parent account
        String parentAccountName = 'Test Parent Account';
        Decimal businessId = TEST_BUSINESS_ID;
        Account parentAccount = TDdAccountFactory.createAccounts(parentAccountName, 1, 'Parent Account')[0];
        parentAccount.BillingCountry = 'United States';
        parentAccount.Business_Id__c = businessId;
        insert parentAccount;
    }

    @isTest
    static void testUpdateLeadOrOpportunityDailyTaskCount(){
        Group testGroup = new Group(Name='Lead Queue Group', Type='Queue');
        insert testGroup;
        QueueSObject testQueue = new QueueSObject(QueueId = testGroup.Id, SObjectType = 'Lead');
        insert testQueue;
        List<User> testUsers = TDdAccountFactory.createUsers(3, null, [SELECT Id FROM UserRole LIMIT 1].ID);
        insert testUsers;

        system.runAs(testUsers[2]){
            List<Lead> leads = new List<Lead>{
                new Lead(LastName = 'Test Lead 1', Street = '1231 Mulberry Ln', City = 'South San Francisco',
                    State = 'CA', PostalCode = '94101', CountryCode = 'US', Phone = '2135551231', Type__c = 'Franchise',
                    Lead_List__c = System.today(), Store_ID__c = '1234561', ARR__c = 1001.00, Amount__c = 1001.00,
                    Starting_Point__c = '101', Starting_Point_ID__c = 101, Deactivation_Code__c = 'Awaiting activation',
                    OwnerId = testUsers[0].Id),
                new Lead(LastName = 'Test Lead 2', Street = '1232 Mulberry Ln', City = 'South San Francisco',
                    State = 'CA', PostalCode = '94102', CountryCode = 'US', Phone = '2135551232', Type__c = 'Franchise',
                    Lead_List__c = System.today(), Store_ID__c = '1234562', ARR__c = 1002.00, Amount__c = 1002.00,
                    Starting_Point__c = '102', Starting_Point_ID__c = 102, Deactivation_Code__c = 'Awaiting activation',
                    OwnerId = testUsers[1].Id),
                new Lead(LastName = 'Test Lead 3', Street = '1233 Mulberry Ln', City = 'South San Francisco',
                    State = 'CA', PostalCode = '94103', CountryCode = 'US', Phone = '2135551233', Type__c = 'Franchise',
                    Lead_List__c = System.today(), Store_ID__c = '1234563', ARR__c = 1003.00, Amount__c = 1003.00,
                    Starting_Point__c = '103', Starting_Point_ID__c = 103, Deactivation_Code__c = 'Awaiting activation',
                    OwnerId = testGroup.Id)
            };
            insert leads;
            Account acc = new Account(
                Name = 'Test Acount', BillingCity = 'South San Francisco',
                BillingState = 'CA', BillingPostalCode = '94108', BillingStreet = '854 Mulberry Ln',
                L30_Total_Sales__c = 50, Phone = '(010) 135-5698');
            insert acc;
            List<Opportunity> opps = new List<Opportunity>{
                new Opportunity(
                    AccountId = acc.Id, Type = 'tmf', Name = 'Test Upsell 1', StageName = 'New', Commission__c = 20,
                    ForecastCategoryName = 'Pipeline', CloseDate = Date.newInstance(2018,6,6),
                    Region_Type__c = 'Live Region', Platform__c = 'DoorDash', OwnerId = testUsers[0].Id,
                    Menu_to_be_completed_by__c = null, Menu_Setup_Method__c =  null, Tablet_Kit_Type__c = null),
                new Opportunity(
                    AccountId = acc.Id, Type = 'tmf', Name = 'Test Upsell 2', StageName = 'New', Commission__c = 20,
                    ForecastCategoryName = 'Pipeline', CloseDate = Date.newInstance(2018,6,6),
                    Region_Type__c = 'Live Region', Platform__c = 'DoorDash', OwnerId = testUsers[1].Id,
                    Menu_to_be_completed_by__c = null, Menu_Setup_Method__c =  null, Tablet_Kit_Type__c = null)
            };
            insert opps;
            Test.startTest();
            List<Task> tasks = new List<Task>{
                new Task(Type = 'Call', WhoId = leads[0].Id, WhatId = null, OwnerId = testUsers[0].Id),
                new Task(Type = 'Call', WhoId = leads[1].Id, WhatId = null, OwnerId = testUsers[0].Id),
                new Task(Type = 'Call', WhoId = leads[2].Id, WhatId = null, OwnerId = testUsers[0].Id),
                new Task(Type = 'Call', WhoId = null, WhatId = opps[0].Id, OwnerId = testUsers[0].Id),
                new Task(Type = 'Call', WhoId = null, WhatId = opps[1].Id, OwnerId = testUsers[0].Id),
                new Task(Type = 'Call', WhoId = null, WhatId = null, OwnerId = testUsers[0].Id),
                new Task(Type = 'Call', WhoId = leads[0].Id, WhatId = null, OwnerId = testUsers[1].Id),
                new Task(Type = 'Call', WhoId = leads[1].Id, WhatId = null, OwnerId = testUsers[1].Id),
                new Task(Type = 'Call', WhoId = leads[2].Id, WhatId = null, OwnerId = testUsers[1].Id),
                new Task(Type = 'Call', WhoId = null, WhatId = opps[0].Id, OwnerId = testUsers[1].Id),
                new Task(Type = 'Call', WhoId = null, WhatId = opps[1].Id, OwnerId = testUsers[1].Id),
                new Task(Type = 'Call', WhoId = null, WhatId = null, OwnerId = testUsers[1].Id)

            };
            insert tasks;
            Test.stopTest();
            Map<Id, Opportunity> queriedOpps = new Map<Id, Opportunity>([SELECT Id, Task_Call_Owner_Count_Today__c,
                Task_Email_Owner_Count_Today__c, OwnerId FROM Opportunity WHERE Id IN :opps]);
            Map<Id, Lead> queriedLeads = new Map<Id, Lead>([SELECT Id, Task_Call_Owner_Count_Today__c,
                Task_Email_Owner_Count_Today__c, OwnerId FROM Lead WHERE Id IN :leads]);
            system.assertEquals(1, queriedLeads.get(leads[0].Id).Task_Call_Owner_Count_Today__c);
            system.assertEquals(1, queriedLeads.get(leads[1].Id).Task_Call_Owner_Count_Today__c);
            system.assertEquals(null, queriedLeads.get(leads[2].Id).Task_Call_Owner_Count_Today__c);
            system.assertEquals(1, queriedOpps.get(opps[0].Id).Task_Call_Owner_Count_Today__c);
            system.assertEquals(1, queriedOpps.get(opps[1].Id).Task_Call_Owner_Count_Today__c);
        }
    }

    /**
    * @description Test create tasks for Accounts
    */
    @isTest
    static void testCreateTaskForAccounts() {
        Integer TASK_COUNT = 2;
        String childAccountName = 'Home Run Pizza (Artesia Blvd)';
        String parentAccountName = 'Home Run Pizza [Parent-1234567]';
        Decimal businessId = 1234567.0;
        User testUser = TDdAccountFactory.createUsers(1)[0];
        System.runAs (testUser) {
            Test.startTest();
            Account childAccount = TDdAccountFactory.createAccounts('childAccountName', 1, 'Marketplace')[0];
            childAccount.BillingCountry = 'United States';
            childAccount.Name = 'Home Run Pizza (Artesia Blvd)';
            childAccount.Business_Id__c = businessId;
            insert childAccount;
            Account childAccountFromDB = [SELECT Id, Name, Business_Id__c, ParentId FROM Account WHERE Id = :childAccount.Id];
            Account parentAccountFromDB = [SELECT Id, Name, Business_Id__c FROM Account WHERE Id = :childAccountFromDB.ParentId];
            List<Account> accounts = new List<Account>{childAccountFromDB, parentAccountFromDB};
            List<Task> tasks = new List<Task>();
            tasks.addAll(TDdTaskFactory.createTaskForAccounts(accounts, TASK_COUNT, 'Call'));
            tasks.addAll(TDdTaskFactory.createTaskForAccounts(accounts, TASK_COUNT, 'Email'));
            insert tasks;
            Test.stopTest();
            List<Account> accountsWithTaskCount = [SELECT Id, Task_Call_Count__c, Task_Call_Owner_Count__c, Task_Email_Count__c, Task_Email_Owner_Count__c
                                                    FROM Account
                                                    WHERE Id IN : accounts];
            System.assertEquals(TASK_COUNT, accountsWithTaskCount[0].Task_Call_Count__c, 'Expecting count ' + TASK_COUNT);
            System.assertEquals(TASK_COUNT, accountsWithTaskCount[0].Task_Call_Owner_Count__c, 'Expecting count ' + TASK_COUNT);
            System.assertEquals(TASK_COUNT, accountsWithTaskCount[0].Task_Email_Count__c, 'Expecting count ' + TASK_COUNT);
            System.assertEquals(TASK_COUNT, accountsWithTaskCount[0].Task_Email_Owner_Count__c, 'Expecting count ' + TASK_COUNT);
        }
    }
    /**
    * @description Test create tasks for Leads
    */
    @isTest
    static void testCreateTaskForLeads() {
        Integer TASK_COUNT = 2;
        User testUser = TDdAccountFactory.createUsers(1)[0];
        System.runAs (testUser) {
            Test.setMock(HttpCalloutMock.class, new CDdCoverageCheckV2CalloutMock());
            Test.startTest();
            CDdLeadTriggerHelper.matchLeadMissingParentAccountFlag = false;
            List<Lead> testLeads = TDdLeadFactory.createLeads('Test Lead ', 1, 'Master Lead', false);
            Lead testLead = testLeads[0];
            testLead.Business_ID__c = TEST_BUSINESS_ID;
            testLead.Type__c = null;
            testLead.Deck_Rank__c = null;
            testLead.Amount__c = null;
            insert testLeads;
            List<Task> tasks = new List<Task>();
            tasks.addAll(TDdTaskFactory.createTaskForLeads(testLeads, TASK_COUNT, 'Call'));
            tasks.addAll(TDdTaskFactory.createTaskForLeads(testLeads, TASK_COUNT, 'Email'));
            insert tasks;
            Test.stopTest();
            List<Lead> leadsWithTaskCount = [SELECT Id, Task_Call_Count__c, Task_Call_Owner_Count__c, Task_Email_Count__c, Task_Email_Owner_Count__c
                                                    FROM Lead
                                                    WHERE Id IN : testLeads];
            System.assertEquals(TASK_COUNT, leadsWithTaskCount[0].Task_Call_Count__c, 'Expecting count ' + TASK_COUNT);
            System.assertEquals(TASK_COUNT, leadsWithTaskCount[0].Task_Call_Owner_Count__c, 'Expecting count ' + TASK_COUNT);
            System.assertEquals(TASK_COUNT, leadsWithTaskCount[0].Task_Email_Count__c, 'Expecting count ' + TASK_COUNT);
            System.assertEquals(TASK_COUNT, leadsWithTaskCount[0].Task_Email_Owner_Count__c, 'Expecting count ' + TASK_COUNT);
        }
    }
    /**
    * @description Test create tasks for Cases
    */
    @isTest
    static void testCreateTaskForCases() {
        Integer TASK_COUNT = 2;
        User testUser = TDdAccountFactory.createUsers(1)[0];
        Boolean errorThrown = false;
        System.runAs (testUser) {
            Test.setMock(HttpCalloutMock.class, new CDdCoverageCheckV2CalloutMock());
            List<Case> testCases = TDdCaseFactory.createCaseRecords(1,'Account Management');
            Case testCase = testCases[0];
            insert testCases;
            List<Task> tasks = new List<Task>();
            tasks.addAll(TDdTaskFactory.createTaskForCases(testCases, TASK_COUNT, 'Email'));
            insert tasks;
            Test.startTest();
            try {
                delete tasks;
            } catch (Exception e) {
                System.debug(e);
                if (e.getMessage().contains('You cannot delete this record')) {
                    errorThrown = true;
                }
            }
        Test.stopTest();
        System.assert(errorThrown);
        }
    }
    /**
    * @description Test create tasks for Opportunities
    */
    @isTest
    static void testCreateTaskForOpportunities() {
        Group testGroup = new Group(Name='Lead Queue Group', Type='Queue');
        insert testGroup;
        QueueSObject testQueue = new QueueSObject(QueueId = testGroup.Id, SObjectType = 'Lead');
        insert testQueue;
        User testUser = TDdAccountFactory.createUsers(1)[0];
        system.runAs(testUser){
            Account acc = new Account(
                Name = 'Test Acount', BillingCity = 'South San Francisco',
                BillingState = 'CA', BillingPostalCode = '94108', BillingStreet = '854 Mulberry Ln',
                L30_Total_Sales__c = 50, Phone = '(010) 135-5698');
            insert acc;
            List<Opportunity> opps = new List<Opportunity>{
                new Opportunity(
                    AccountId = acc.Id, Type = 'tmf', Name = 'Test Upsell 1', StageName = 'New', Commission__c = 20,
                    ForecastCategoryName = 'Pipeline', CloseDate = Date.newInstance(2018,6,6),
                    Region_Type__c = 'Live Region', Platform__c = 'DoorDash', OwnerId = testUser.Id,
                    Menu_to_be_completed_by__c = null, Menu_Setup_Method__c =  null, Tablet_Kit_Type__c = null),
                new Opportunity(
                    AccountId = acc.Id, Type = 'tmf', Name = 'Test Upsell 2', StageName = 'New', Commission__c = 20,
                    ForecastCategoryName = 'Pipeline', CloseDate = Date.newInstance(2018,6,6),
                    Region_Type__c = 'Live Region', Platform__c = 'DoorDash', OwnerId = testUser.Id,
                    Menu_to_be_completed_by__c = null, Menu_Setup_Method__c =  null, Tablet_Kit_Type__c = null)
            };
            insert opps;
            Test.startTest();
            List<Task> tasks = new List<Task>{
                new Task(Type = 'Call', WhoId = null, WhatId = opps[0].Id, OwnerId = testUser.Id),
                new Task(Type = 'Call', WhoId = null, WhatId = opps[1].Id, OwnerId = testUser.Id),
                new Task(Type = 'Call', WhoId = null, WhatId = opps[0].Id, OwnerId = testUser.Id),
                new Task(Type = 'Call', WhoId = null, WhatId = opps[1].Id, OwnerId = testUser.Id)
            };
            insert tasks;
            Test.stopTest();
            Map<Id, Opportunity> queriedOpps = new Map<Id, Opportunity>([SELECT Id, Task_Call_Owner_Count__c,OwnerId FROM Opportunity WHERE Id IN :opps]);
            system.assertEquals(2, queriedOpps.get(opps[0].Id).Task_Call_Owner_Count__c);
            system.assertEquals(2, queriedOpps.get(opps[1].Id).Task_Call_Owner_Count__c);
    }
    }
    @isTest
    static void testTaskTriggers() {
        List<RecordType> recordType = new List<RecordType>([Select Id,Name from RecordType where sObjectType=:'Task' and Name =:'Voicemail']);
        List<User> usrs = TDdUserFactory.createUsers(1,null,null,false);
        User runasUser = usrs[0];
        runasUser.TimeZoneSidKey = 'GMT';
        System.runAs (usrs[0]){
            Test.startTest();
            List<Task> tasks = new List<Task>{
                new Task(RecordTypeId= recordType[0].Id, team__c ='Trust and Safety',Description=generateRandomString(300))
            };
            insert tasks;
            Test.stopTest();
            list<Task> queriedTask = new list<Task>([SELECT Id, activitydate FROM Task WHERE team__c = :'Trust and Safety']);
            system.assertEquals(Date.Today().addDays(CDdTaskTriggerContants.DUE_DATE_THRESHOLD),queriedTask[0].activitydate,'Activity Date is not set as expected');
        }
    }
    @isTest
    static void testUpdateLeadStatus() {
        Integer TASK_COUNT = 2;
        List<User> testUsers = TDdAccountFactory.createUsers(1);
        insert testUsers;
        User runUser = testUsers[0];
        System.runAs (runUser) {
            Test.setMock(HttpCalloutMock.class, new CDdCoverageCheckV2CalloutMock());
            Test.startTest();
            CDdLeadTriggerHelper.matchLeadMissingParentAccountFlag = false;
            List<Lead> testLeads = TDdLeadFactory.createLeads('Test Lead ', 1, 'Master Lead', false);
            Lead testLead = testLeads[0];
            testLead.Business_ID__c = TEST_BUSINESS_ID;
            testLead.Type__c = null;
            testLead.Deck_Rank__c = null;
            testLead.Amount__c = null;
            insert testLeads;
            List<Task> tasks = new List<Task>();
            tasks.addAll(TDdTaskFactory.createTaskForLeads(testLeads, TASK_COUNT, 'Duplicate'));
            insert tasks;
            Test.stopTest();
            List<Lead> leadsWithTask = [SELECT Id, Status,Task_Call_Count__c, Task_Call_Owner_Count__c, Task_Email_Count__c, Task_Email_Owner_Count__c
                                                    FROM Lead
                                                    WHERE Id IN : testLeads];
            System.assertEquals('Unqualified',leadsWithTask[0].Status,'Unexpected Status returned');

        }
    }

    @isTest
    static void testUpdateLeadStatusOnTypeUpdate() {
        Integer TASK_COUNT = 1;
        List<User> testUsers = TDdAccountFactory.createUsers(1);
        insert testUsers;
        User runUser = testUsers[0];
        System.runAs (runUser) {
            Test.setMock(HttpCalloutMock.class, new CDdCoverageCheckV2CalloutMock());
            Test.startTest();
            CDdLeadTriggerHelper.matchLeadMissingParentAccountFlag = false;
            List<Lead> testLeads = TDdLeadFactory.createLeads('Test Lead ', 2, 'Master Lead', false);
            Lead testLead = testLeads[0];
            testLead.Business_ID__c = TEST_BUSINESS_ID;
            testLead.Type__c = null;
            testLead.Deck_Rank__c = null;
            testLead.Amount__c = null;
            insert testLeads;
            List<Task> tasks = new List<Task>();
            tasks.addAll(TDdTaskFactory.createTaskForLeads(testLeads, TASK_COUNT, 'Influencer - Got Callback Time'));
            insert tasks;
            Test.getEventBus().deliver();

            testLeads[0].status = 'DM Found';
            testLeads[1].status = 'DM Found';
            update testLeads;

            tasks[1].Type = 'Decision Maker - Appointment set';
            update tasks;
            Test.getEventBus().deliver();

            Lead lead1 = [SELECT Id, Status FROM Lead WHERE Id = :testLeads[0].Id];
            Lead lead2 = [SELECT Id, Status FROM Lead WHERE Id = :testLeads[1].Id];
            System.assertEquals('DM Found',lead1.Status,'Unexpected Status returned');
            System.assertEquals('Meeting Set',lead2.Status,'Unexpected Status returned');

        }
    }

    public static String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
        Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
        randStr += chars.substring(idx, idx+1);
        }
        return randStr;
        }

    /**
    * @author Swedhaa Sri M
    * @date 2023-01
    *
    * @description: Test method for updateOutreachEHT()
    */

	@isTest
    static void testUpdateOutreachEHT() {
        User testRunUser = TDdAccountFactory.createUsers(1)[0];
        testRunUser.FirstName = 'Outreach';
        testRunUser.LastName = 'Integration User PreSale';
        insert testRunUser;
          System.runAs (testRunUser){
            Test.startTest();
            List<Task> tasks = new List<Task>{
                new Task(Subject = 'Email: Outreach Email', TaskSubType = 'Email')
            };
            Task task2 = new Task(Subject = 'Call: Outreach Call', TaskSubType = 'Call');
            tasks.add(task2);
            insert tasks;
            Test.stopTest();

            list<Task> queriedTask = new list<Task>([SELECT Id, Outreach_EHT__c FROM Task WHERE Id IN:tasks]);
            System.assertEquals(5, queriedTask[0].Outreach_EHT__c , 'Outreach EHT is not assigned according to taskSubtype Email');
            System.assertEquals(15, queriedTask[1].Outreach_EHT__c , 'Outreach EHT is not assigned according to taskSubtype Call');
        }
    }
}