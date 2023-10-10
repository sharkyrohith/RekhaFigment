/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 12/21/2020
*
* @group Nimda Bulk Bypass Tool
*
* @description Bypass Bulk Store Update Batch Job Test Class
* 
**************************************************************************************************************************************/
@isTest
public class CDdBypassBulkStoreUpdateBatchTest {
    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    public static final Id SYSTEM_ADMIN_PROFILE_ID;
    private static String SAMPLE_ACCOUNT_RECORD = 'Sample_Account_Record';
    private static String SAMPLE_CONTACT_RECORD = 'Sample_Contact_Record';
    private static String SAMPLE_OPPORTUNITY_RECORD = 'Sample_Opportunity_Record';    
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
    * @description Prepare test data
    */
    @TestSetup
    static void setup() {
        System.runAs(getTestRunUser()){
            Test.startTest();
            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
            validation.Bypass_Opportunity_Validations__c = true; 
            insert validation;            
            Test.stopTest();
        }
    }        
    @isTest 
    public static void testReasonUnavailable(){
        Id batchId = null;
        Boolean hasException = false;
        String expectedErrorMessage = String.format(CDdBypassBulkStoreUpdateConstants.ERROR_MSG_MISSING_PROPERTY, new List<String>{CDdBypassBulkStoreUpdateConstants.PROPERTY_REASON});
        String actualErrorMessage = '';        
        System.runAs (getTestRunUser()) {
            Map<String, SObject> data = setupData();
            Account sampleAccount = (Account)data.get(SAMPLE_ACCOUNT_RECORD);
            String reason = null;
            List<Map<String, Object>> bulkUpdateStoreData = new List<Map<String, Object>>();
            bulkUpdateStoreData.add(new Map<String, String>{
                                        'id' => sampleAccount.Restaurant_Id__c,
                                        'accountId' => sampleAccount.Id
                                    });
            try {                        
                Test.startTest();
                StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
                mock.setStaticResource('mockResponse_DSJ_bulk_update_store_failure');
                mock.setStatusCode(400);
                mock.setHeader('Content-Type', 'application/json');
                Test.setMock(HttpCalloutMock.class, mock);
                batchId = Database.executeBatch(new CDdBypassBulkStoreUpdateBatch(bulkUpdateStoreData, reason));
                Test.stopTest();
            } catch(CDdBypassBulkStoreUpdateBatch.CDdBypassBulkStoreUpdateBatchException e) {
                hasException = true;
                actualErrorMessage = e.getMessage();
            }            
        }
        System.assertEquals(true, batchId!=null, 'Expecting a job id for the executed batch');
        System.assertEquals(true, hasException, 'Expecting exception from batch job');
        System.assertEquals(expectedErrorMessage, actualErrorMessage, expectedErrorMessage);                
    }
    @isTest 
    public static void testStoreIdUnavailable(){
        Id batchId = null;
        Boolean hasException = false;
        String expectedErrorMessage = String.format(CDdBypassBulkStoreUpdateConstants.ERROR_MSG_MISSING_PROPERTY, new List<String>{CDdBypassBulkStoreUpdateConstants.PROPERTY_STORE_ID});
        String actualErrorMessage = '';        
        System.runAs (getTestRunUser()) {
            Map<String, SObject> data = setupData();
            Account sampleAccount = (Account)data.get(SAMPLE_ACCOUNT_RECORD);
            String reason = 'Test Reason';
            List<Map<String, Object>> bulkUpdateStoreData = new List<Map<String, Object>>();
            bulkUpdateStoreData.add(new Map<String, String>{
                                        'accountId' => sampleAccount.Id
                                    });
            try {                        
                Test.startTest();
                StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
                mock.setStaticResource('mockResponse_DSJ_bulk_update_store_failure');
                mock.setStatusCode(400);
                mock.setHeader('Content-Type', 'application/json');
                Test.setMock(HttpCalloutMock.class, mock);
                batchId = Database.executeBatch(new CDdBypassBulkStoreUpdateBatch(bulkUpdateStoreData, reason));
                Test.stopTest();
            } catch(CDdBypassBulkStoreUpdateBatch.CDdBypassBulkStoreUpdateBatchException e) {
                hasException = true;
                actualErrorMessage = e.getMessage();
            }            
        }
        System.assertEquals(true, batchId!=null, 'Expecting a job id for the executed batch');
        System.assertEquals(true, hasException, 'Expecting exception from batch job');
        System.assertEquals(expectedErrorMessage, actualErrorMessage, expectedErrorMessage);                
    }
    @isTest 
    public static void testAccountIdUnavailable(){
        Id batchId = null;
        Boolean hasException = false;
        String expectedErrorMessage = String.format(CDdBypassBulkStoreUpdateConstants.ERROR_MSG_MISSING_PROPERTY, new List<String>{CDdBypassBulkStoreUpdateConstants.PROPERTY_ACCOUNT_ID});
        String actualErrorMessage = '';        
        System.runAs (getTestRunUser()) {
            Map<String, SObject> data = setupData();
            Account sampleAccount = (Account)data.get(SAMPLE_ACCOUNT_RECORD);
            String reason = 'Test Reason';
            List<Map<String, Object>> bulkUpdateStoreData = new List<Map<String, Object>>();
            bulkUpdateStoreData.add(new Map<String, String>{
                                        'id' => sampleAccount.Restaurant_Id__c
                                    });
            try {                        
                Test.startTest();
                StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
                mock.setStaticResource('mockResponse_DSJ_bulk_update_store_failure');
                mock.setStatusCode(400);
                mock.setHeader('Content-Type', 'application/json');
                Test.setMock(HttpCalloutMock.class, mock);
                batchId = Database.executeBatch(new CDdBypassBulkStoreUpdateBatch(bulkUpdateStoreData, reason));
                Test.stopTest();
            } catch(CDdBypassBulkStoreUpdateBatch.CDdBypassBulkStoreUpdateBatchException e) {
                hasException = true;
                actualErrorMessage = e.getMessage();
            }            
        }
        System.assertEquals(true, batchId!=null, 'Expecting a job id for the executed batch');
        System.assertEquals(true, hasException, 'Expecting exception from batch job');
        System.assertEquals(expectedErrorMessage, actualErrorMessage, expectedErrorMessage);                
    }
    @isTest 
    public static void testApi400Error(){
        Id batchId = null;
        Boolean hasException = false;
        System.runAs (getTestRunUser()) {
            Map<String, SObject> data = setupData();
            Account sampleAccount = (Account)data.get(SAMPLE_ACCOUNT_RECORD);
            String reason = 'Test Reason';
            List<Map<String, Object>> bulkUpdateStoreData = new List<Map<String, Object>>();
            bulkUpdateStoreData.add(new Map<String, String>{
                                        'id' => sampleAccount.Restaurant_Id__c,
                                        'accountId' => sampleAccount.Id
                                    });
            try {
                StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
                mock.setStaticResource('mockResponse_DSJ_bulk_update_store_failure');
                mock.setStatusCode(400);
                mock.setHeader('Content-Type', 'application/json');
                CDdBypassBulkStoreUpdateBatch batch = new CDdBypassBulkStoreUpdateBatch(bulkUpdateStoreData, reason);
                batchId = Database.executeBatch(batch);                                                        
                Test.startTest();
                Test.setMock(HttpCalloutMock.class, mock);
                batch.setBatchJobId(batchId);
                batch.handleUpdateToBulkStoreUpdateRequestObj(bulkUpdateStoreData);
                batch.handleCalloutToBulkStoreUpdateApi(bulkUpdateStoreData);
                Test.stopTest();
            } catch(Exception ex) {
                hasException = true;
            }            
        }
        System.assertEquals(true, batchId!=null, 'Expecting a job id for the executed batch');
        System.assertEquals(true, hasException, 'Expecting exception from batch job due to Api Error');
    }
    @isTest 
    public static void testApiSuccess(){
        Id batchId = null;
        Boolean hasException = false;
        System.runAs (getTestRunUser()) {
            Map<String, SObject> data = setupData();
            Account sampleAccount = (Account)data.get(SAMPLE_ACCOUNT_RECORD);
            String reason = 'Test Reason';
            List<Map<String, Object>> bulkUpdateStoreData = new List<Map<String, Object>>();
            bulkUpdateStoreData.add(new Map<String, String>{
                                        'id' => sampleAccount.Restaurant_Id__c,
                                        'accountId' => sampleAccount.Id
                                    });
            try {
                String responseBody = JSON.serialize(new List<Map<String, Object>>{new Map<String, Object>{
                    CDdBypassBulkStoreUpdateConstants.PROPERTY_STORE_ID => sampleAccount.Restaurant_Id__c,
                    CDdBypassBulkStoreUpdateConstants.PROPERTY_ACCOUNT_ID => sampleAccount.Id,
                    'http_status_code' => 400,
                    'status' => 'HTTP POST on resource \'http://api-doorcrawl.us-west-2.aws.ddnw.net:80/v1/stores/747728/\' failed: bad request (400).'
                }});
                MockHttpResponseSuccess mock = new MockHttpResponseSuccess(responseBody);
                CDdBypassBulkStoreUpdateBatch batch = new CDdBypassBulkStoreUpdateBatch(bulkUpdateStoreData, reason);
                batchId = Database.executeBatch(batch);                                                        
                Test.startTest();
                Test.setMock(HttpCalloutMock.class, mock);
                batch.setBatchJobId(batchId);
                batch.setStoreIdToAccountIdMap(bulkUpdateStoreData);
                batch.handleUpdateToBulkStoreUpdateRequestObj(bulkUpdateStoreData);
                batch.handleCalloutToBulkStoreUpdateApi(bulkUpdateStoreData);
                Test.stopTest();
            } catch(CDdNimdaSyncMSService.CDdNimdaSyncMSServiceException msEx) {
                hasException = true;
            }            
        }
        System.assertEquals(true, batchId!=null, 'Expecting a job id for the executed batch');
        System.assertEquals(false, hasException, 'Expecting exception from batch job due to Api Error');
    }   
    @isTest 
    public static void testGetTotalItems(){
        CDdBypassBulkStoreUpdateBatch batch = new CDdBypassBulkStoreUpdateBatch(new List<Map<String, Object>>(), '');
        Integer totalItems = batch.getTotalItems(45);
        System.assertEquals(90, totalItems);
    }
   /** 
    * @description Set up account, contact and opportunity
    */
    private static Map<String, SObject> setupData(){
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
        // store contacts
        List<Contact> contacts = new List<Contact>();
        contacts.add(contact);
        upsert contacts;
        // update child account
        childAcct.ParentId = parentAcct.Id;
        upsert childAcct;           
        // store opportunities
        List<Opportunity> opportunities = new List<Opportunity>();
        Opportunity closedWonOpportunity =createClosedWonOpportunity('Test Closed Opp', childAcct, contact);
        opportunities.add(closedWonOpportunity);
        upsert opportunities;
        return new Map<String, SObject>{
            SAMPLE_ACCOUNT_RECORD => childAcct,
            SAMPLE_CONTACT_RECORD => contact,
            SAMPLE_OPPORTUNITY_RECORD => closedWonOpportunity
        };        
    }                  
   /** 
    * @description Create 'Closed Won' stage opportunity
    */
    private static Opportunity createClosedWonOpportunity(String name, Account account, Contact contact){
        Opportunity closedWonOpportunity = TDdOpportunityFactory.createOpportunity(name, account.Id, contact.Id, 'Closed Won');
        return closedWonOpportunity;        
    }
   /** 
    * @description Create Http Mock Response for successful response from Bulk Store Update API
    */
    public class MockHttpResponseSuccess implements HttpCalloutMock {
        private String body;
        // constructor
        public MockHttpResponseSuccess(String body){
            this.body = body;
        }
        // Implement this interface method
        public HTTPResponse respond(HTTPRequest req) {
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(this.body);
            res.setStatusCode(200);
            return res;
        }        
    }                  
}