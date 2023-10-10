@IsTest
public with sharing class CDdS2NBypassToolUploaderHelperTest {

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
    static void testValidHelperFlow(){
        CDdS2NBypassToolUploaderContext ctxUpload;
        String msSyncStage = MS_SYNC_STAGE;
        String reason = TEST_REASON;
        Boolean overwrite = TEST_OVERWRITE;
        String filename = TEST_FILENAME;
        System.runAs(getTestRunUser()){
            setupData();
            Test.startTest();
            Account acct = [SELECT Id, Restaurant_ID__c FROM Account LIMIT 1];
            String csv = 'accountId,store_id\n';
            csv += acct.Id + ',' + acct.Restaurant_ID__c;

            CDdS2NBypassToolUploaderContext ctx = 
                new CDdS2NBypassToolUploaderContext(
                    csv, UserInfo.getUserId(), msSyncStage,
                    reason, overwrite, filename);

            CDdS2NBypassToolUploaderHelper uploaderHelper = 
                new CDdS2NBypassToolUploaderHelper();

            ctxUpload = uploaderHelper.uploadCsv(ctx);
            Test.stopTest();
        }

        System.assert(ctxUpload != null, 'Controller uploadCsv not returning context');
    }

    @IsTest
    static void testConvertToObjectBoolean(){
        List<Map<String, String>> avaiableFields = new List<Map<String, String>>();
        Map<String, String> field = new Map<String, String> {
            'apiType' => 'Boolean',
            'displayType' => 'Boolean',
            'displayName' => 'Offers Delivery',
            'property' => 'offers_delivery'
        };

        avaiableFields.add(field);

        Test.startTest();
        Object convertedObject = CDdS2NBypassToolUploaderHelper.convertToObject('offers_delivery','true', avaiableFields);
        Test.stopTest();

        System.assert(convertedObject instanceof Boolean, 'ConvertToObject not returning Boolean value');
    }

    @IsTest
    static void testConvertToObjectString(){
        List<Map<String, String>> avaiableFields = new List<Map<String, String>>();
        Map<String, String> field = new Map<String, String> {
            'apiType' => 'String',
            'displayType' => 'Boolean',
            'displayName' => 'Fulfills Own Deliveries',
            'property' => 'fulfills_own_deliveries'
        };

        avaiableFields.add(field);

        Test.startTest();
        Object convertedObject = CDdS2NBypassToolUploaderHelper.convertToObject('offers_delivery','true', avaiableFields);
        Test.stopTest();

        System.assert(convertedObject instanceof String, 'ConvertToObject not returning Boolean value');
    }

    /** 
    * @description Set up account, contact and opportunity
    */
    private static void setupData(){
        Account parentAcct = TDdAccountFactory.createAccounts('Parent Account', 1)[0];
        parentAcct.Business_ID__c = 143611;
        //parentAcct.Requesting_Account_Management__c = 'Unmanaged';
        
        Account childAcct = TDdAccountFactory.createAccounts('Child Account', 1)[0];
        childAcct.BillingCountry = 'United States';
        childAcct.Legal_Business_Name__c = 'Test Entity Business';
        childAcct.Restaurant_Id__c = '12345';
        Contact contact = VTestUtil.createContact('Test', 'Contact', childAcct);
        // store accounts     
        
        List<Account> accounts = new List<Account>();
        accounts.add(parentAcct);
        accounts.add(childAcct);
        upsert accounts;       
    }                  
}