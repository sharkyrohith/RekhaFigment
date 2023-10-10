@isTest
public class CDdEmailBatchTest {

    public static final Id TEST_ROLE_ID;
    public static final Id SYSTEM_ADMIN_PROFILE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
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
    @testSetup
    static void testSetup() {
        System.runAs(getTestRunUser()){
            Test.startTest();        
            vCS__c testSettings;
            testSettings = VTestUtil.createVeltigSettings();
            testSettings.CaseTrigger__c = true;
            insert testSettings;
            Test.stopTest();
        }
    }
    @isTest
    static void testPOSCaseActivation() {
        System.runAs(getTestRunUser()){
            Account testAccount = TDdAccountFactory.createAccounts('POSIntegrationAcct', 1, 'Marketplace')[0];
            testAccount.Is_Partner__c = 'Yes';
            insert testAccount; 
            Contact testContact = TDdAccountFactory.createContacts(1, testAccount.Id)[0];
            insert testContact; 
            Case testCase  = TDdCaseFactory.createCaseRecords(1, 'POS Integrations')[0];
            testCase.Status = 'Solved';
            testCase.Last_Email_from_Customer__c = DateTime.now().addDays(-5);
            testCase.Solved_At__c = DateTime.now().addDays(-4);
            testCase.AccountId = testAccount.Id; 
            testCase.ContactId = testContact.Id; 
            insert testCase;

            Test.startTest(); 
            Case testCaseFromDB = [SELECT Id FROM Case WHERE Id =: testCase.Id];
            System.assertEquals(true, testCaseFromDB!=null, 'Expecting a valid Case record');
            Id batchJobId = Database.executeBatch(new CDdEmailBatch('Post_Activation_Going_Live_Marketplace_POS', CDdCustomMetadata.getIdValueFor('Org_Wide_Email_DoorDash'), 'Case', new Set<Id>{testCase.Id}, 'ContactId', new Set<String>{'SuppliedEmail'}), 1);
            Test.stopTest(); 
            System.assertEquals(true, batchJobId!=null, 'Expecting a batch job id');
        }
    }        
}