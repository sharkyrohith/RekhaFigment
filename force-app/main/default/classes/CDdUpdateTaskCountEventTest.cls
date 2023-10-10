/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 08/05/2019
*
* @group Update Task Count Event
*
* @description Purpose is to test the Update Task Count platform event handler
* 
**************************************************************************************************************************************/
@isTest
public class CDdUpdateTaskCountEventTest {
    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_LEAD_0 = 'TestDDLead0';   
    public static final String TEST_DD_ACCOUNT_PARENT_IDENTIFIERS = 'TestDDAccountParent%';
    public static final String TEST_DD_ACCOUNT_CHILD_IDENTIFIERS = 'TestDDAccountChild%';
    public static final String TEST_DD_ACCOUNT_PARENT_0 = 'TestDDAccountParent0';
    public static final String TEST_DD_ACCOUNT_CHILD_0 = 'TestDDAccountChild0';    
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    public static final Decimal TEST_BUSINESS_ID = 111111;
    public static final Decimal TEST_DD_ACCOUNT_PARENT_BUSINESS_ID_1 = 122222;
    public static final Decimal TEST_DD_ACCOUNT_PARENT_BUSINESS_ID_2 = 122223;
    public static final Decimal TEST_DD_ACCOUNT_PARENT_BUSINESS_ID_3 = 122224;
    public static final Id PARENT_ACCOUNT_RECORD_TYPE_ID;
    public static final Id SYSTEM_ADMIN_PROFILE_ID;
    static {
        TEST_ROLE_ID = [SELECT Id FROM UserRole WHERE DeveloperName = 'COO'].Id;
        PARENT_ACCOUNT_RECORD_TYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Parent Account').getRecordTypeId();
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

            E2F__FindApi_Triggers_Settings__c findAPISettings = new E2F__FindApi_Triggers_Settings__c(
                                                                SetupOwnerId = SYSTEM_ADMIN_PROFILE_ID
                                                                , Name = 'System Administrator'
                                                                , E2F__Bypass_Trigger__c = true
                                                            );
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
            testAcct3.RecordTypeId = PARENT_ACCOUNT_RECORD_TYPE_ID;
            testAcct3.Business_Id__c = TEST_DD_ACCOUNT_PARENT_BUSINESS_ID_1;
            Account testAcct4 = testAccounts[4];
            testAcct4.Name = 'TestDDAccountParent1';
            testAcct4.RecordTypeId = PARENT_ACCOUNT_RECORD_TYPE_ID;
            testAcct4.Business_Id__c = TEST_DD_ACCOUNT_PARENT_BUSINESS_ID_2;
            Account testAcct5 = testAccounts[5];
            testAcct5.Name = 'TestDDAccountParent2';
            testAcct5.RecordTypeId = PARENT_ACCOUNT_RECORD_TYPE_ID;
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
            // Create Test Lead
            CDdLeadTriggerHelper.matchLeadMissingParentAccountFlag = false;
            List<Lead> testLeads = TDdLeadFactory.createLeads(TEST_DD_LEAD_0, 1, 'Master Lead', false);
            Lead testLead = testLeads[0];
            testLead.Business_ID__c = TEST_BUSINESS_ID;
            testLead.Type__c = null;
            testLead.Deck_Rank__c = null;
            testLead.Amount__c = null;
            insert testLeads;            
            
            Test.getEventBus().deliver();
            Test.stopTest();
        }
    } 
    /** 
    * @description Test update task count for Accounts
    */        
    @isTest
    static void testUpdateTaskCountForAccounts() {
        Integer TASK_COUNT = 2;
        List<User> testUsers = TDdAccountFactory.createUsers(2);
        insert testUsers;
        User runUser = testUsers[0];
        System.runAs (runUser) {        
            Test.startTest();
            Account childAccount = [SELECT Id, Name, ParentId FROM Account WHERE Name = :TEST_DD_ACCOUNT_CHILD_0 LIMIT 1];
            Account parentAccount = [SELECT Id, Name FROM Account WHERE Id = :childAccount.ParentId LIMIT 1];
            List<Account> accounts = new List<Account>{childAccount, parentAccount};
            List<Task> tasks = new List<Task>();
            tasks.addAll(TDdTaskFactory.createTaskForAccounts(accounts, TASK_COUNT, 'Call'));
            tasks.addAll(TDdTaskFactory.createTaskForAccounts(accounts, TASK_COUNT, 'Email'));  
            insert tasks; 
            parentAccount.OwnerId = testUsers[1].Id;
            childAccount.OwnerId = testUsers[1].Id;
            update accounts;
            Test.getEventBus().deliver();      
            Test.stopTest();
            List<Account> accountsWithTaskCount = [SELECT Id, Task_Call_Count__c, Task_Call_Owner_Count__c, Task_Email_Count__c, Task_Email_Owner_Count__c 
                                                    FROM Account 
                                                    WHERE Id IN : accounts];
            System.assertEquals(true, accountsWithTaskCount[0].Task_Call_Count__c > 0, 'Expecting count greater than 0');
            System.assertEquals(0, accountsWithTaskCount[0].Task_Call_Owner_Count__c, 'Expecting count ' + 0);
            System.assertEquals(true, accountsWithTaskCount[0].Task_Email_Count__c > 0, 'Expecting count greater than zero');
            System.assertEquals(0, accountsWithTaskCount[0].Task_Email_Owner_Count__c, 'Expecting count ' + 0);
        }
    }
    /** 
    * @description Test update task count for Leads
    */        
    @isTest
    static void testUpdateTaskCountForLeads() {
        Integer TASK_COUNT = 2;
        String TEST_LEAD_IDENTIFIER = TEST_DD_LEAD_0 + '%';
        List<User> testUsers = TDdAccountFactory.createUsers(2);
        insert testUsers;
        User runUser = testUsers[0];
        System.runAs (runUser) {        
            Test.startTest();
            List<Lead> testLeads = [SELECT Id, Name FROM Lead WHERE LastName LIKE :TEST_LEAD_IDENTIFIER];
            List<Task> tasks = new List<Task>();
            tasks.addAll(TDdTaskFactory.createTaskForLeads(testLeads, TASK_COUNT, 'Call'));
            tasks.addAll(TDdTaskFactory.createTaskForLeads(testLeads, TASK_COUNT, 'Email'));  
            insert tasks;
            testLeads[0].OwnerId = testUsers[1].Id;
            update testLeads;
            Test.getEventBus().deliver();         
            Test.stopTest();
            List<Lead> leadsWithTaskCount = [SELECT Id, Task_Call_Count__c, Task_Call_Owner_Count__c, Task_Email_Count__c, Task_Email_Owner_Count__c 
                                                    FROM Lead 
                                                    WHERE Id IN :testLeads];
            System.assertEquals(TASK_COUNT, leadsWithTaskCount[0].Task_Call_Count__c, 'Expecting count ' + TASK_COUNT);
            System.assertEquals(0, leadsWithTaskCount[0].Task_Call_Owner_Count__c, 'Expecting count ' + 0);
            System.assertEquals(TASK_COUNT, leadsWithTaskCount[0].Task_Email_Count__c, 'Expecting count ' + TASK_COUNT);
            System.assertEquals(0, leadsWithTaskCount[0].Task_Email_Owner_Count__c, 'Expecting count ' + 0);
        }
    }                  
}