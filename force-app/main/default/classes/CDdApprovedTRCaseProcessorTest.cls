/**
 * CDdApprovedTRCaseProcessorTest
**/
@isTest
public with sharing class CDdApprovedTRCaseProcessorTest {
    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
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
     * @description Test execution for Apex Classes that will soon be deprecated
     * This test class may be deprecated once the following Apex Class are deprecated
     * 1. IDdGenericQueueHandler (Interface)
     * 2. CDdGenericQueueHandler (Class)
     * 3. CDdApprovedTRCaseProcessor (Class)
     */    
    @isTest
    public static void testClassesToDeprecate() {
        System.runAs (getTestRunUser()) {
            Test.startTest();
            System.assert((Object)new GenericQueueHandler() instanceof GenericQueueHandler);
            System.assert((Object)new CDdGenericQueueHandler() instanceof CDdGenericQueueHandler);
            System.assert((Object)new CDdApprovedTRCaseProcessor() instanceof CDdApprovedTRCaseProcessor);
            Test.stopTest(); 
        }        
    }
    public class GenericQueueHandler implements IDdGenericQueueHandler {
        public GenericQueueHandler() {}
    }
}