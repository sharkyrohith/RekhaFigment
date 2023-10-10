@IsTest
public with sharing class CDdS2NBypassToolUploaderControllerTest {
    
    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    public static final Id SYSTEM_ADMIN_PROFILE_ID;

    private static String MS_SYNC_STAGE = 'Bulk Store Update';
    private static String TEST_REASON = 'Testing Reason';
    private static Boolean TEST_OVERWRITE = false;
    private static String TEST_FILENAME = 'Test.csv';

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
    
    @TestSetup
    static void setup(){
        System.runAs(getTestRunUser()){
            Test.startTest();
            Test.stopTest();
        }
    }

    @IsTest
    static void testUploadCsv(){
        CDdS2NBypassToolUploaderContext ctx;

        System.runAs(getTestRunUser()){
            setupData();
            Account acct = [SELECT Id, Restaurant_ID__c FROM Account LIMIT 1];
            String csv = 'accountId,store_id\n';
            csv += acct.Id + ',' + acct.Restaurant_ID__c;
            String userId = UserInfo.getUserId();

            Test.startTest();
            ctx = CDdS2NBypassToolUploaderController.uploadCsv(csv, userId, MS_SYNC_STAGE, TEST_REASON, TEST_OVERWRITE, TEST_FILENAME);
            Test.stopTest();
        }

        System.assert(ctx != null, 'Context was not properly set on file upload.');
    }
    
    @IsTest
    static void testImportCsv(){
        String batchId;
        System.runAs(getTestRunUser()){
            setupData();
            Account acct = [SELECT Id, Restaurant_ID__c FROM Account LIMIT 1];
            String csv = 'accountId,store_id\n';
            csv += acct.Id + ',' + acct.Restaurant_ID__c;
            
            String userId = UserInfo.getUserId();

            Test.startTest();
            CDdS2NBypassToolUploaderContext ctx = CDdS2NBypassToolUploaderController.uploadCsv(csv, userId, MS_SYNC_STAGE, TEST_REASON, TEST_OVERWRITE, TEST_FILENAME);
            if (ctx != null) {
                batchId = CDdS2NBypassToolUploaderController.importCsv(userId);
            }
            Test.stopTest();
        }

        System.assert(batchId != null, 'Batch id not properly configured');
    }

    @IsTest
    static void testGetImportMessages(){
        List<String> errors = new List<String>();
        Test.startTest();
        errors = CDdS2NBypassToolUploaderController.getImportMessages();
        Test.stopTest(); 
        
        System.assert(errors.size() == 0, 'Errors should be empty');
    }

    @IsTest
    static void testStandardizeColumnName() {
        System.runAs(getTestRunUser()){
            String accountColumnName = CDdS2NBypassToolUploaderController.standardizeColumnName('accountid');
            String storeColumnName = CDdS2NBypassToolUploaderController.standardizeColumnName('store_id');
            System.assertEquals(accountColumnName, 'accountId');
            System.assertEquals(storeColumnName, 'id');
        }
    }

    /** 
    * @description Set up account, contact and opportunity
    */
    private static void setupData(){
        Account parentAcct = TDdAccountFactory.createAccounts('Parent Account', 1)[0];
        parentAcct.Business_ID__c = 143611;
        parentAcct.Restaurant_Id__c = '56789';

        Account childAcct = TDdAccountFactory.createAccounts('Child Account', 1)[0];
        childAcct.BillingCountry = 'United States';
        childAcct.Legal_Business_Name__c = 'Test Entity Business';
        childAcct.Restaurant_Id__c = '12345';
        Contact contact = VTestUtil.createContact('Test', 'Contact', childAcct);

        List<Account> accounts = new List<Account>();
        accounts.add(parentAcct);
        accounts.add(childAcct);
        upsert accounts;
        
        ContentWorkspace testWorkspace = new ContentWorkspace(
            Name='TEST_Library',
            DeveloperName='TEST_Library'
        );
    	insert testWorkspace;
    }
}