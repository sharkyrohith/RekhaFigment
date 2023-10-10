/**
 * CDdBatchDeleteSupportTrainingCaseRecTest
 *
 * @author      Ashutosh Anand
 * @date        2021-10-15
 * @decription Test class for CDdBatchDeleteSupportTrainingCaseRec
 */
@isTest
public with sharing class CDdBatchDeleteSupportTrainingCaseRecTest {
    private static final Id TEST_ADMIN_ROLE_ID;
    private static final Id SYSTEM_ADMIN_PROFILE_ID;
    private static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    private static final Id TEST_TRAINERS_ROLE_ID;
    private static final String TEST_TRAINER_RUN_USERNAME = 'test.traineruser@doordash.com';
    private static final String JOB_NAME = 'Case TrainingSupport Delete Job Test';
    private static final String ASSERT_MSG1 = 'Expecting the Batch to be shceduled for tomorrow, excluding the exact timing.';
    private static final String ASSERT_MSG2 = 'Expecting batch to NOT get Scheduled for next day';
    private static final String ASSERT_MSG3 = 'Expecting 12 remaining Case records because, ';
    private static final String ASSERT_MSG4 = 'Expecting 22 Cases because Logic will not Delete Cases in Execute.';
    private static final Integer BATCH_CYCLE_DAYS_LIMIT = Integer.valueOf(System.Label.Support_Training_Records_Deletion_Cycle);
    private static final String USER_ROLE_NAME = String.valueOf(System.Label.Support_Training_Records_User_Role);
    static {
        TEST_ADMIN_ROLE_ID = [
            SELECT Id
            FROM UserRole
            WHERE DeveloperName = 'COO'].Id;
        SYSTEM_ADMIN_PROFILE_ID = [
            SELECT Id
            FROM Profile
            WHERE Name =:CDdSupportConstants.PROFILE_SYS_ADM].Id;
        TEST_TRAINERS_ROLE_ID = [
            SELECT Id
            FROM UserRole
            WHERE Name =: USER_ROLE_NAME].Id;
    }
    
/** 
 * 
 * @description Prepare and return the test running user
 */
    private static User getTestRunUser() {
        User testRunUser = null;
        for (User u : [
            SELECT Id
            FROM User
            WHERE UserName = :TEST_DD_RUN_USERNAME]) {
            testRunUser = u;
        }
        if (testRunUser == null) {
            testRunUser = TDdAccountFactory.createUsers(1, null, TEST_ADMIN_ROLE_ID)[0]; 
            testRunUser.Username = TEST_DD_RUN_USERNAME;
        }
        return testRunUser;
    }
    
/** 
 * 
 * @description Prepare and return the test Trainer user
 */
    private static User getTestTrainerRunUser() {
        User testRunUser = null;
        for (User u : [
            SELECT Id
            FROM User
            WHERE UserName = :TEST_TRAINER_RUN_USERNAME]) {
            testRunUser = u;
        }
        if (testRunUser == null) {
            testRunUser = TDdAccountFactory.createUsers(1, null, TEST_TRAINERS_ROLE_ID)[0]; 
            testRunUser.Username = TEST_TRAINER_RUN_USERNAME;
        }
        return testRunUser;
    } 
    
    @testSetup
    static void testSetup() {
        System.runAs(getTestRunUser()){
            List<Case> supportCasesToInsert = TDdCaseFactory.createCaseRecords(
              10,
              CDdSupportConstants.RECORDTYPE_SUPPORT_TRAINING
            );
            insert supportCasesToInsert;
            
            for (Case caseRec: supportCasesToInsert) {
                Test.setCreatedDate(caseRec.Id, Date.today().addDays(-BATCH_CYCLE_DAYS_LIMIT));
            }
            
            List<Case> cavSupportCasesToInsert = TDdCaseFactory.createCaseRecords(
              2,
              CDdSupportConstants.RECORDTYPE_NAME_CAVIRA_SUPPORT
            );
            insert cavSupportCasesToInsert;
        }
        
        // Case created by Trainer Users
        System.runAs(getTestTrainerRunUser()){
            List<Case> supportCasesToInsert = TDdCaseFactory.createCaseRecords(
              10,
              CDdSupportConstants.RECORDTYPE_SUPPORT_TRAINING
            );
            insert supportCasesToInsert;
            
            for (Case caseRec: supportCasesToInsert) {
                Test.setCreatedDate(caseRec.Id, Date.today().addDays(-BATCH_CYCLE_DAYS_LIMIT));
            }
        }
    }

    @isTest
    public static void testNonSchedulableBatchRunAsTrainer() {
        System.runAs(getTestTrainerRunUser()){
            Test.startTest();
            List<Case> testCases = [SELECT Id FROM CASE];
            system.assertEquals(22, testCases.size());
            
            CDdBatchDeleteSupportTrainingCaseRec deleteBatch = new CDdBatchDeleteSupportTrainingCaseRec(String.valueOf(BATCH_CYCLE_DAYS_LIMIT));
            Database.executeBatch(deleteBatch);
            Test.stopTest();
            
            system.assertEquals(12, [SELECT count() FROM CASE], ASSERT_MSG3 + ' Trainer User records will not be Deleted.');
        }
    } 
    
    @isTest
    public static void testNonSchedulableBatchWithError() {
        System.runAs(getTestRunUser()){
            Test.startTest();
            List<Case> testCases = [SELECT Id FROM CASE];
            system.assertEquals(22, testCases.size());
            
            CDdBatchDeleteSupportTrainingCaseRec deleteBatch = new CDdBatchDeleteSupportTrainingCaseRec('test');
            Database.executeBatch(deleteBatch);
            Test.stopTest();
            
            system.assertEquals(22, [SELECT count() FROM CASE], ASSERT_MSG3 + 'of different RecordType/Created Date/User Role');
        }
    }
    
    @isTest
    public static void testBatchClassForNonSchedulable() {
        System.runAs(getTestRunUser()){
            Test.startTest();
            List<Case> testCases = [SELECT Id FROM CASE];
            system.assertEquals(22, testCases.size());
            
            CDdBatchDeleteSupportTrainingCaseRec deleteBatch = new CDdBatchDeleteSupportTrainingCaseRec(System.today(), BATCH_CYCLE_DAYS_LIMIT, true, false, JOB_NAME);
            Database.executeBatch(deleteBatch);
            Test.stopTest();
            
            system.assertEquals(12, [SELECT count() FROM CASE], ASSERT_MSG3 + 'of different RecordType/Created Date/User Role');

            List<CronTrigger> cronList = [
                SELECT Id,
                CronExpression,
                TimesTriggered,
                NextFireTime
                FROM CronTrigger
                WHERE CronJobDetail.Name =: JOB_NAME
            ];
            system.assertEquals(cronList.size(), 0, ASSERT_MSG2);
        }
    }
    
    @isTest
    public static void testBatchToBeScheduledForTomorrow() {
        System.runAs(getTestRunUser()){
            Test.startTest();
            List<Case> testCases = [SELECT Id FROM CASE];
            system.assertEquals(22, testCases.size());
            
            CDdBatchDeleteSupportTrainingCaseRec deleteBatch = new CDdBatchDeleteSupportTrainingCaseRec(System.today(), BATCH_CYCLE_DAYS_LIMIT, false, true, JOB_NAME);
            Database.executeBatch(deleteBatch);
            Test.stopTest();
            
            CronTrigger ct = [
                SELECT Id,
                CronExpression,
                TimesTriggered,
                NextFireTime
                FROM CronTrigger
                WHERE CronJobDetail.Name =: JOB_NAME
            ];
            DateTime todayDate = System.today();
            DateTime cronDate = ct.NextFireTime;
            system.assert(cronDate.dateGMT() > todayDate.dateGMT(), ASSERT_MSG1);
            system.assertEquals(22, [SELECT count() FROM CASE], ASSERT_MSG4);
        }
    }
    
    @isTest
    public static void testBatchToBeScheduledAndRunForTodayTest() {
        System.runAs(getTestRunUser()){
            Test.startTest();
            List<Case> testCases = [SELECT Id FROM CASE];
            system.assertEquals(22, testCases.size());
            
            CDdBatchDeleteSupportTrainingCaseRec deleteBatch = new CDdBatchDeleteSupportTrainingCaseRec(System.today().addDays(-30), BATCH_CYCLE_DAYS_LIMIT, false, true, JOB_NAME);
            Database.executeBatch(deleteBatch);
            Test.stopTest();
            
            CronTrigger ct = [
                SELECT Id,
                CronExpression,
                TimesTriggered,
                NextFireTime
                FROM CronTrigger
                WHERE CronJobDetail.Name =: JOB_NAME
            ];
            DateTime todayDate = System.today();
            DateTime cronDate = ct.NextFireTime;
            system.assert(cronDate.dateGMT() > todayDate.dateGMT(), ASSERT_MSG1);
            system.assertEquals(12, [SELECT count() FROM CASE], ASSERT_MSG3 + 'of different RecordType/Created Date/User Role & this Confirms the Batch Run.');
        }
    }
    
    @isTest
    public static void testAlreadyScheduledBatchWithNewCycleTime() {
        System.runAs(getTestRunUser()){
            Test.startTest();
            List<Case> testCases = [SELECT Id FROM CASE];
            system.assertEquals(22, testCases.size());
            
            CDdBatchDeleteSupportTrainingCaseRec deleteBatch = new CDdBatchDeleteSupportTrainingCaseRec(System.today().addDays(-10), 20, false, true, JOB_NAME);
            Database.executeBatch(deleteBatch);
            Test.stopTest();
            
            CronTrigger ct = [
                SELECT Id,
                CronExpression,
                TimesTriggered,
                NextFireTime
                FROM CronTrigger
                WHERE CronJobDetail.Name =: JOB_NAME
            ];
            DateTime todayDate = System.today();
            DateTime cronDate = ct.NextFireTime;
            
            system.assert(cronDate.dateGMT() > todayDate.dateGMT(), ASSERT_MSG1);
            system.assertEquals(12, [SELECT count() FROM CASE], ASSERT_MSG3 + 'batch will Run TODAY and 10 Cases will be DELETED.');
            
        }
    }
}