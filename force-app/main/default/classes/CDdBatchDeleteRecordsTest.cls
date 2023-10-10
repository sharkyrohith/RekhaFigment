/*
* 
* @author: Narender Kurapati
* @date: 2021-04-12
* @description : This test class for CDdBatchDeleteRecords 
* 
*/

@isTest
public class CDdBatchDeleteRecordsTest {
    public static final Id TEST_ROLE_ID;
    public static final Id SYSTEM_ADMIN_PROFILE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    static {
        TEST_ROLE_ID = [SELECT Id FROM UserRole WHERE DeveloperName = 'COO'].Id;
        SYSTEM_ADMIN_PROFILE_ID = [SELECT Id FROM Profile WHERE Name =:CDdSupportConstants.PROFILE_SYS_ADM].Id;        
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
    @testSetup
    static void testSetup() {
        System.runAs(getTestRunUser()){
            List<Account> accnt = TDdAccountFactory.createAccounts('AccountIdTest', 10);
            insert accnt;
            DeleteJobController__c dltjob = new DeleteJobController__c();
            dltjob.isRun__c = true;
            dltjob.Object_Api_Name__c = 'Account'; 
            dltjob.Query__c = 'Select Id From Account';
            dltjob.Name = 'Account';
            insert dltjob;
        }
    }
    @isTest
    public static void callScheduleBatch()
    {
        System.runAs(getTestRunUser()){
            String CRON_EXP = '0 0 0 15 3 ? *';
            Test.startTest();
            String jobId = System.schedule('CDdBatchDeleteRecords-Test-'+date.Today(),  CRON_EXP, new CDdBatchDeleteRecords('Select Id From Account','Account'));
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
            System.assertEquals(CRON_EXP, ct.CronExpression);
            Test.stopTest();
        }
    }
    
    
    @isTest
    public static void testBatchClass1()
    {
        System.runAs(getTestRunUser()){
            Test.startTest();
            List<Account> accLst = [Select id from Account where name like 'AccountIdTest%'];
            CDdBatchDeleteRecords bc = new CDdBatchDeleteRecords('Select Id From Account','Account');
            Database.executeBatch(bc);
            Test.stopTest();
            system.assertEquals(0, [select count() From Account where name like 'AccountIdTest%'], 'Expecting zero Account after batch deleting run');
            //system.assertEquals(0, [select count() From Account where name like 'AccountIdTest%']);
            
        }
    }
    
    @isTest
    public static void testBatchClass2()
    {
        System.runAs(getTestRunUser()){
            Test.startTest();
            List<Account> accLst = [Select id from Account where name like 'AccountIdTest%'];
            List<Id> accIds = new List<Id>();
            for(Account acc : accLst){
                accIds.add(acc.Id);
            }
            CDdBatchDeleteRecords bc = new CDdBatchDeleteRecords(accIds,'Account');
            Database.executeBatch(bc);
            Test.stopTest();
            system.assertEquals(0, [select count() From Account where name like 'AccountIdTest%'], 'Expecting zero Account after batch deleting run');
            //system.assertEquals(0, [select count() From Account where name like 'AccountIdTest%']);
            
        }
    }
    
    @isTest
    public static void testErrorMsg()
    {
        System.runAs(getTestRunUser()){
            Test.startTest();
            List<Account> accLst = [Select id from Account where name like 'AccountIdTest%'];
            List<Id> accIds = new List<Id>();
            for(Account acc : accLst){
                accIds.add(acc.Id);
            }
            CDdBatchDeleteRecords bc = new CDdBatchDeleteRecords(accIds,'');
            Database.executeBatch(bc);
            
            Test.stopTest();
            system.assertEquals(10, [select count() From Account where name like 'AccountIdTest%'], 'Object name is blank, then expecting No Account record will be deleted');
            //system.assertEquals(0, [select count() From Account where name like 'AccountIdTest%']);
            
        }
    }
}