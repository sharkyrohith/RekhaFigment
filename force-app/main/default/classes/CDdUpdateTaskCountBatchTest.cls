/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 08/05/2019
*
* @group Update Task Count Event
*
* @description Purpose is to test the Update Task Count batch
*
**************************************************************************************************************************************/
@isTest
public class CDdUpdateTaskCountBatchTest {
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
        Test.startTest();
        // insert parent account
        String parentAccountName = 'Test Parent Account';
        Decimal businessId = TEST_BUSINESS_ID;
        Account parentAccount = TDdAccountFactory.createAccounts(parentAccountName, 1, 'Parent Account')[0];
        parentAccount.BillingCountry = 'United States';
        parentAccount.Business_Id__c = businessId;
        insert parentAccount;
        Test.stopTest();
    }
    /**
    * @description Test update task count for Accounts
    */
    @isTest
    static void testUpdateTaskCountForAccounts() {
        Integer TASK_COUNT = 2;
        String childAccountName = 'Home Run Pizza (Artesia Blvd)';
        String parentAccountName = 'Home Run Pizza [Parent-1234567]';
        Decimal businessId = 1234567.0;
        List<User> testUsers = TDdAccountFactory.createUsers(2);
        insert testUsers;
        User runUser = testUsers[0];
        System.runAs (runUser) {
            Test.startTest();
            Account childAccount = TDdAccountFactory.createAccounts('childAccountName', 1, 'Marketplace')[0];
            childAccount.BillingCountry = 'United States';
            childAccount.Name = 'Home Run Pizza (Artesia Blvd)';
            childAccount.Business_Id__c = businessId;
            insert childAccount;
            Account childAccountFromDB = [SELECT Id, Name, Business_Id__c, ParentId FROM Account WHERE Id = :childAccount.Id];
            Account parentAccountFromDB = [SELECT Id, Name, Business_Id__c FROM Account WHERE Id = :childAccountFromDB.ParentId];
            List<Account> accounts = new List<Account>{parentAccountFromDB, childAccountFromDB};
            List<Task> tasks = new List<Task>();
            tasks.addAll(TDdTaskFactory.createTaskForAccounts(accounts, TASK_COUNT, 'Call'));
            tasks.addAll(TDdTaskFactory.createTaskForAccounts(accounts, TASK_COUNT, 'Email'));
            insert tasks;
            parentAccountFromDB.Task_Call_Count__c = 0;
            parentAccountFromDB.Task_Call_Owner_Count__c = 0;
            parentAccountFromDB.Task_Email_Count__c = 0;
            parentAccountFromDB.Task_Email_Owner_Count__c = 0;
            update parentAccountFromDB;
            ID batchProcessdId = Database.executeBatch(new CDdUpdateTaskCountBatch(CDdUpdateTaskCountBatch.SOBJECT_TYPE_ACCOUNT));
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
    * @description Test update task count for Leads
    */
    @isTest
    static void testUpdateTaskCountForLeads() {
        Integer TASK_COUNT = 2;
        List<User> testUsers = TDdAccountFactory.createUsers(2);
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
            tasks.addAll(TDdTaskFactory.createTaskForLeads(testLeads, TASK_COUNT, 'Call'));
            tasks.addAll(TDdTaskFactory.createTaskForLeads(testLeads, TASK_COUNT, 'Email'));
            insert tasks;
            testLead.Task_Call_Count__c = 0;
            testLead.Task_Call_Owner_Count__c = 0;
            testLead.Task_Email_Count__c = 0;
            testLead.Task_Email_Owner_Count__c = 0;
            update testLead;
            ID batchProcessdId = Database.executeBatch(new CDdUpdateTaskCountBatch(CDdUpdateTaskCountBatch.SOBJECT_TYPE_LEAD));
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
    * @description Test update task count for Leads - batch scheduler
    */
    @isTest
    static void testUpdateTaskCountForLeadsBatchSchedPositive() {
        Integer TASK_COUNT = 2;
        String CRON_EXP = '0 0 0 15 3 ? 2033';
        List<User> testUsers = TDdAccountFactory.createUsers(2);
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
            tasks.addAll(TDdTaskFactory.createTaskForLeads(testLeads, TASK_COUNT, 'Call'));
            tasks.addAll(TDdTaskFactory.createTaskForLeads(testLeads, TASK_COUNT, 'Email'));
            insert tasks;
            testLead.Task_Call_Count__c = 0;
            testLead.Task_Call_Owner_Count__c = 0;
            testLead.Task_Email_Count__c = 0;
            testLead.Task_Email_Owner_Count__c = 0;
            update testLead;
            String jobId = System.schedule('ScheduledApexTest', CRON_EXP, new CDdUpdateTaskCountBatchSched(0));
            Test.stopTest();
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
            System.assertEquals(CRON_EXP, ct.CronExpression);
            System.assertEquals(0, ct.TimesTriggered);
        }
    }
    /**
    * @description Test update task count for Leads - batch scheduler
    */
    @isTest
    static void testUpdateTaskCountForLeadsBatchSchedNegative() {
        Integer TASK_COUNT = 2;
        String CRON_EXP = '0 0 0 15 3 ? 2033';
        List<User> testUsers = TDdAccountFactory.createUsers(2);
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
            tasks.addAll(TDdTaskFactory.createTaskForLeads(testLeads, TASK_COUNT, 'Call'));
            tasks.addAll(TDdTaskFactory.createTaskForLeads(testLeads, TASK_COUNT, 'Email'));
            insert tasks;
            testLead.Task_Call_Count__c = 0;
            testLead.Task_Call_Owner_Count__c = 0;
            testLead.Task_Email_Count__c = 0;
            testLead.Task_Email_Owner_Count__c = 0;
            update testLead;
            try {
                String jobId = System.schedule('ScheduledApexTest', CRON_EXP, new CDdUpdateTaskCountBatchSched(-1));
            } catch(Exception e){
                System.assertEquals(CDdUpdateTaskCountBatchSched.ERROR_MSG_INVALID_SOBJECT_TYPE_OPTION, e.getMessage());
            }
            Test.stopTest();
        }
    }
}