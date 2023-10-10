/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 08/19/2020
*
* @group Nimda
*
* @description Purpose is to perform additional Nimda Sync test for the following classes
* - CDdLtngNimdaSyncHomeCtrl
* - CDdLtngNimdaSyncMSCtrl
* - CDdNimdaSyncMSService
* - CDdNimdaSyncPollingController
* 
**************************************************************************************************************************************/
@isTest
public class CDdNimdaSyncAdditionalTest {
    private static String SAMPLE_ACCOUNT_RECORD = 'Sample_Account_Record';
    private static String SAMPLE_CONTACT_RECORD = 'Sample_Contact_Record';
    private static String SAMPLE_OPPORTUNITY_RECORD = 'Sample_Opportunity_Record';    
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
    * @description Prepare test data
    */
    @testSetup 
    static void setup() {
        System.runAs(getTestRunUser()) {        
            Test.startTest();       
            vCS__c s = VTestUtil.createVeltigSettings();
            s.S2N_Store_Feature_Flag__c = true;
            insert s;
            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
            validation.Bypass_Opportunity_Validations__c = true; 
            insert validation;        
            Test.stopTest();
        }
    }
   /** 
    * @description Run test case - Get S2N single use-case steps
    */
    @isTest
    public static void testGetSendToNimdaSteps() {
        System.runAs (getTestRunUser()) {
            Test.startTest();
            // Execute positive use case
            Map<String, SObject> data = setupData();
            Opportunity sampleOpportunity = (Opportunity)data.get(SAMPLE_OPPORTUNITY_RECORD);
            Object retObj = CDdLtngNimdaSyncHomeCtrl.getSendToNimdaSteps(sampleOpportunity);
            System.assertEquals(true, retObj!=null, 'Expecting a valid return object');
            Test.stopTest();
        }
    }
   /** 
    * @description Run test case - Get S2N bulk use-case steps
    */
    @isTest
    public static void testGetBulkSteps() {
        System.runAs (getTestRunUser()) {
            Test.startTest();
            // Execute positive use case
            Object retObj = CDdLtngNimdaSyncHomeCtrl.getBulkSteps();
            System.assertEquals(true, retObj!=null, 'Expecting a valid return object');
            Test.stopTest();
        }
    }    
   /** 
    * @description Run positive test case - Get Store Request
    */
    @isTest
    public static void testPositiveGetStoreRequest() {
        System.runAs (getTestRunUser()) {
            Map<String, SObject> data = setupData();
            Account sampleAccount = (Account)data.get(SAMPLE_ACCOUNT_RECORD);
            Opportunity sampleOpportunity = (Opportunity)data.get(SAMPLE_OPPORTUNITY_RECORD);
            Contact sampleContact = (Contact)data.get(SAMPLE_CONTACT_RECORD);
            Test.startTest();
            Object retVal = CDdLtngNimdaSyncMSCtrl.getStoreRequest('143611', sampleAccount, sampleOpportunity);
            System.assertEquals(true, retVal!=null, 'Expecting a valid return object');
            Test.stopTest();
        }
    }
   /** 
    * @description Run negative test case - Get Store Request
    */
    @isTest
    public static void testNegativeGetStoreRequest() {
        System.runAs (getTestRunUser()) {
            Map<String, SObject> data = setupData();
            Account sampleAccount = (Account)data.get(SAMPLE_ACCOUNT_RECORD);
            Opportunity sampleOpportunity = (Opportunity)data.get(SAMPLE_OPPORTUNITY_RECORD);
            Contact sampleContact = (Contact)data.get(SAMPLE_CONTACT_RECORD);
            Test.startTest();
            try {
                Object retVal = CDdLtngNimdaSyncMSCtrl.getStoreRequest('143611', null, sampleOpportunity);
            } catch (AuraHandledException ex){
                System.assertEquals(true, ex!=null, 'Expecting error ');                
            }            
            Test.stopTest();
        }
    }
   /** 
    * @description Run positive test case - Get Store
    */
    @isTest
    public static void testPositiveGetStore() {
        System.runAs (getTestRunUser()) {
            Test.startTest();
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('mockResponse_DSJ_get_store_success');
            mock.setStatusCode(200);
            mock.setHeader('Content-Type', 'application/json');
            // Set the mock callout mode
            Test.setMock(HttpCalloutMock.class, mock);
            Object retObj = CDdLtngNimdaSyncMSCtrl.getStore('123456');
            System.assertEquals(true, retObj!=null, 'Expecting a valid return object');
            Test.stopTest();
        }
    }
   /** 
    * @description Run negative test case - Get Store
    */
    @isTest
    public static void testNegativeGetStore() {
        System.runAs (getTestRunUser()) {
            Test.startTest();
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('mockResponse_DSJ_search_no_records');
            mock.setStatusCode(500);
            mock.setHeader('Content-Type', 'application/json');
            // Set the mock callout mode
            Test.setMock(HttpCalloutMock.class, mock);
            // Execute with no result returned by Get store
            try {
                Object retObj = CDdLtngNimdaSyncMSCtrl.getStore('123456');
            } catch (AuraHandledException ex){
                System.assertEquals(true, ex!=null, 'Expecting error ');                
            }
        }
    }
   /** 
    * @description test for Get Nimda Store Field Definitions
    */
    @isTest
    public static void testGetNimdaStoreFieldDefinitions() {
        System.runAs (getTestRunUser()) {
            Test.startTest();
            Object retObj = CDdLtngNimdaSyncMSCtrl.getNimdaStoreFieldDefinitions();
            System.assertEquals(true, retObj!=null, 'Expecting a valid return object');
            Test.stopTest();
        }
    }
   /** 
    * @description Run positive test case - Get Store Request
    */
    @isTest
    public static void testUpdateAccountAndOpportunity() {
        System.runAs (getTestRunUser()) {
            Map<String, SObject> data = setupData();
            Account sampleAccount = (Account)data.get(SAMPLE_ACCOUNT_RECORD);
            Opportunity sampleOpportunity = (Opportunity)data.get(SAMPLE_OPPORTUNITY_RECORD);
            Contact sampleContact = (Contact)data.get(SAMPLE_CONTACT_RECORD);
            Test.startTest();
            Boolean retVal = CDdLtngNimdaSyncMSCtrl.updateAccountAndOpportunity(sampleAccount, sampleOpportunity, sampleContact);
            System.assertEquals(true, retVal, 'Expecting successful update of account and opportunity');
            Test.stopTest();
        }
    }
   /** 
    * @description Run positive test case - Update Store
    */
    @isTest
    public static void testPositiveUpdateStore() {
        System.runAs (getTestRunUser()) {
            Map<String, SObject> data = setupData();
            Account sampleAccount = (Account)data.get(SAMPLE_ACCOUNT_RECORD);
            Opportunity sampleOpportunity = (Opportunity)data.get(SAMPLE_OPPORTUNITY_RECORD);
            Contact sampleContact = (Contact)data.get(SAMPLE_CONTACT_RECORD);            
            Test.startTest();
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('mockResponse_DSJ_get_store_success');
            mock.setStatusCode(200);
            mock.setHeader('Content-Type', 'application/json');
            // Set the mock callout mode
            Test.setMock(HttpCalloutMock.class, mock);
            Object retObj = CDdLtngNimdaSyncMSCtrl.updateStore(sampleAccount.Restaurant_Id__c, sampleOpportunity.Id);
            System.assertEquals(true, retObj!=null, 'Expecting a valid return object');
            Test.stopTest();
        }
    }
   /** 
    * @description Run negative test case - Update Store
    */
    @isTest
    public static void testNegativeUpdateStore() {
        System.runAs (getTestRunUser()) {
            Map<String, SObject> data = setupData();
            Account sampleAccount = (Account)data.get(SAMPLE_ACCOUNT_RECORD);
            Opportunity sampleOpportunity = (Opportunity)data.get(SAMPLE_OPPORTUNITY_RECORD);
            Contact sampleContact = (Contact)data.get(SAMPLE_CONTACT_RECORD);            
            Test.startTest();
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('mockResponse_DSJ_search_no_records');
            mock.setStatusCode(500);
            mock.setHeader('Content-Type', 'application/json');
            // Set the mock callout mode
            Test.setMock(HttpCalloutMock.class, mock);
            // Execute with null store id
            try {
                Object retObj = CDdLtngNimdaSyncMSCtrl.updateStore(null, sampleOpportunity.Id);
            } catch (AuraHandledException ex){
                System.assertEquals(true, ex!=null, 'Expecting error ');                
            }
            // Execute with invalid opportunity id
            try {
                Object retObj = CDdLtngNimdaSyncMSCtrl.updateStore(sampleAccount.Restaurant_Id__c, sampleContact.Id);
            } catch (AuraHandledException ex){
                System.assertEquals(true, ex!=null, 'Expecting error ');                
            }                        
            // Execute with no result returned by Update store
            try {
                Object retObj = CDdLtngNimdaSyncMSCtrl.updateStore(sampleAccount.Restaurant_Id__c, sampleOpportunity.Id);
            } catch (AuraHandledException ex){
                System.assertEquals(true, ex!=null, 'Expecting error ');                
            }
            Test.stopTest();
        }
    }        
   /** 
    * @description Run positive test case - Full Onboard
    */
    @isTest
    public static void testPositiveFullOnboard() {
        System.runAs (getTestRunUser()) {
            Map<String, SObject> data = setupData();
            Account sampleAccount = (Account)data.get(SAMPLE_ACCOUNT_RECORD);
            Opportunity sampleOpportunity = (Opportunity)data.get(SAMPLE_OPPORTUNITY_RECORD);
            Contact sampleContact = (Contact)data.get(SAMPLE_CONTACT_RECORD);            
            Test.startTest();
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('mockResponse_DSJ_get_store_success');
            mock.setStatusCode(200);
            mock.setHeader('Content-Type', 'application/json');
            // Set the mock callout mode
            Test.setMock(HttpCalloutMock.class, mock);
            Object retObj = CDdLtngNimdaSyncMSCtrl.fullOnboard(sampleOpportunity.Id, CDdNimdaSyncConstants.STEP_UPDATE_STORE);
            System.assertEquals(true, retObj!=null, 'Expecting a valid return object');
            Test.stopTest();
        }
    }
   /** 
    * @description Run negative test case - Full Onboard
    */
    @isTest
    public static void testNegativeFullOnboard() {
        System.runAs (getTestRunUser()) {
            Map<String, SObject> data = setupData();
            Account sampleAccount = (Account)data.get(SAMPLE_ACCOUNT_RECORD);
            Opportunity sampleOpportunity = (Opportunity)data.get(SAMPLE_OPPORTUNITY_RECORD);
            Contact sampleContact = (Contact)data.get(SAMPLE_CONTACT_RECORD);            
            Test.startTest();
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('mockResponse_DSJ_search_no_records');
            mock.setStatusCode(500);
            mock.setHeader('Content-Type', 'application/json');
            // Set the mock callout mode
            Test.setMock(HttpCalloutMock.class, mock);
            // Execute with null opportunity id
            try {
                Object retObj = CDdLtngNimdaSyncMSCtrl.fullOnboard(null, CDdNimdaSyncConstants.STEP_UPDATE_STORE);
            } catch (AuraHandledException ex){
                System.assertEquals(true, ex!=null, 'Expecting error ');                
            }
            // Execute with invalid opportunity id
            try {
                Object retObj = CDdLtngNimdaSyncMSCtrl.fullOnboard(sampleContact.Id, CDdNimdaSyncConstants.STEP_UPDATE_STORE);
            } catch (AuraHandledException ex){
                System.assertEquals(true, ex!=null, 'Expecting error ');                
            }                        
            // Execute with no result returned by Full Onboard
            try {
                Object retObj = CDdLtngNimdaSyncMSCtrl.fullOnboard(sampleOpportunity.Id, CDdNimdaSyncConstants.STEP_UPDATE_STORE);
            } catch (AuraHandledException ex){
                System.assertEquals(true, ex!=null, 'Expecting error ');                
            }
            Test.stopTest();
        }
    }
   /** 
    * @description Run positive test case - Bulk Update Store
    */
    @isTest
    public static void testPositiveBulkUpdateStore() {
        System.runAs (getTestRunUser()) {
            Map<String, SObject> data = setupData();
            Account sampleAccount = (Account)data.get(SAMPLE_ACCOUNT_RECORD);
            Opportunity sampleOpportunity = (Opportunity)data.get(SAMPLE_OPPORTUNITY_RECORD);
            Contact sampleContact = (Contact)data.get(SAMPLE_CONTACT_RECORD);
            List<Map<String, String>> bulkUpdateStoreData = new List<Map<String, String>>();
            bulkUpdateStoreData.add(new Map<String, String>{
                                        'id' => sampleAccount.Restaurant_Id__c,
                                        'accountId' => sampleAccount.Id,
                                        'ownerId' => UserInfo.getUserId(),
                                        'origin' => System.Label.Nimda_Origin_Bulk_Uploader,
                                        'reason' => 'test'
                                    });
            Test.startTest();
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('mockResponse_DSJ_bulk_update_store_success');
            mock.setStatusCode(200);
            mock.setHeader('Content-Type', 'application/json');
            Test.setMock(HttpCalloutMock.class, mock);
            Object retObj = new CDdNimdaSyncMSService().bulkUpdateStore(bulkUpdateStoreData);
            System.assertEquals(true, retObj!=null, 'Expecting a valid return object');
            Test.stopTest();
        }
    }
   /** 
    * @description Run negative test case - Bulk Update Store
    */
    @isTest
    public static void testNegativeBulkUpdateStore() {
        System.runAs (getTestRunUser()) {
            Map<String, SObject> data = setupData();
            Account sampleAccount = (Account)data.get(SAMPLE_ACCOUNT_RECORD);
            Opportunity sampleOpportunity = (Opportunity)data.get(SAMPLE_OPPORTUNITY_RECORD);
            Contact sampleContact = (Contact)data.get(SAMPLE_CONTACT_RECORD);
            List<Map<String, Object>> bulkUpdateStoreData = new List<Map<String, Object>>();
            bulkUpdateStoreData.add(new Map<String, String>{
                                        'id' => sampleAccount.Restaurant_Id__c,
                                        'accountId' => sampleAccount.Id,
                                        'ownerId' => UserInfo.getUserId(),
                                        'origin' => System.Label.Nimda_Origin_Bulk_Uploader,
                                        'reason' => 'test'
                                    });
            Test.startTest();
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('mockResponse_DSJ_bulk_update_store_failure');
            mock.setStatusCode(400);
            mock.setHeader('Content-Type', 'application/json');
            Test.setMock(HttpCalloutMock.class, mock);
            Boolean hasException = false;
            try {
                Object retObj = new CDdNimdaSyncMSService().bulkUpdateStore(bulkUpdateStoreData);
            } catch (Exception e){
                hasException = true;
            }
            System.assertEquals(true, hasException, 'Expecting an exception on invocation of Bulk Update Store API');
            Test.stopTest();
        }
    }            
   /** 
    * @description Run test for Nimda sync status update and retrieve
    */
    @isTest
    public static void testNimdaSyncStatus() {
        System.runAs (getTestRunUser()) {
            Map<String, SObject> data = setupData();
            Account sampleAccount = (Account)data.get(SAMPLE_ACCOUNT_RECORD);
            Opportunity sampleOpportunity = (Opportunity)data.get(SAMPLE_OPPORTUNITY_RECORD);
            Contact sampleContact = (Contact)data.get(SAMPLE_CONTACT_RECORD);            
            Test.startTest();
            CDdLtngNimdaSyncMSCtrl.updateNimdaSyncStatus(CDdNimdaSyncConstants.FULL_ONBOARDING_CREATE, sampleOpportunity.Id);
            Opportunity testOpp = CDdLtngNimdaSyncMSCtrl.getNimdaSyncStatus(sampleOpportunity.Id);
            System.assertEquals(CDdNimdaSyncConstants.FULL_ONBOARDING_CREATE, testOpp.Nimda_Sync_Step__c, 'Expecting step ' + CDdNimdaSyncConstants.FULL_ONBOARDING_CREATE);
            Test.stopTest();
        }
    }
   /** 
    * @description Run test for Nimda sync polling controller
    */
    @isTest
    public static void testNimdaSyncPollingController() {
        System.runAs (getTestRunUser()) {
            Map<String, SObject> data = setupData();
            Account sampleAccount = (Account)data.get(SAMPLE_ACCOUNT_RECORD);
            Opportunity sampleOpportunity = (Opportunity)data.get(SAMPLE_OPPORTUNITY_RECORD);
            Contact sampleContact = (Contact)data.get(SAMPLE_CONTACT_RECORD);            
            Test.startTest();
            PageReference pageRef = Page.PDdNimdaSyncPolling;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('Id', sampleOpportunity.Id);
            CDdNimdaSyncPollingController pageController = new CDdNimdaSyncPollingController();
            String pageURL = CDdNimdaSyncPollingController.getNimdaSyncPollingPageURL();
            System.assertEquals(true, pageController.filter.contains(sampleOpportunity.Id));
            Test.stopTest();
        }
    }
   /** 
    * @description Run test for Nimda onboarding step and field configuration
    */
    @isTest
    public static void testNimdaOnboardingStepFieldConfig() {
        System.runAs (getTestRunUser()) {
            Test.startTest();
            System.assertEquals(true, CDdLtngNimdaSyncMSCtrl.getDataModelTemplate(CDdNimdaSyncConstants.STEP_PRODUCT_AND_PRICING_ONBOARDING)!=null);
            System.assertEquals(true, CDdNimdaSyncOnboardingConfigHelper.getAllFieldProperties(CDdNimdaSyncConstants.STEP_PRODUCT_AND_PRICING_ONBOARDING)!=null);
            Test.stopTest();
        }
    }
    @isTest
    public static void testPositiveGetPaymentAccount() {
        System.runAs (getTestRunUser()) {
            Test.startTest();
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('mockResponse_DSJ_payment_acct_success');
            mock.setStatusCode(200);
            mock.setHeader('Content-Type', 'application/json');
            // Set the mock callout mode
            Test.setMock(HttpCalloutMock.class, mock);
            Object retObj = CDdLtngNimdaSyncMSCtrl.getPaymentAccount('123456');
            System.assertEquals(true, retObj!=null, 'Expecting a valid return object');
            Test.stopTest();
        }
    }
   /** 
    * @description Run negative test case - Get Payment Account
    */
    @isTest
    public static void testNegativeGetPaymentAccount1() {
        System.runAs (getTestRunUser()) {
            Test.startTest();
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('mockResponse_DSJ_payment_acct_failure');
            mock.setStatusCode(500);
            mock.setHeader('Content-Type', 'application/json');
            // Set the mock callout mode
            Test.setMock(HttpCalloutMock.class, mock);
            // Execute with no result returned by Get Payment Account
            try {
                Object retObj = CDdLtngNimdaSyncMSCtrl.getPaymentAccount('');
            } catch (AuraHandledException ex){
                System.assertEquals(true, ex!=null, 'Expecting error ');                
            }
        }
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
        childAcct.Merchant_Supplied_ID__c = '12345678';
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
        closedWonOpportunity.Order_Protocol_Email__c = 'test.user@tes.com';
        closedWonOpportunity.Order_Protocol_Fax__c = TDdAccountFactory.getRandom();
        closedWonOpportunity.Custom_Delivery_Radius__c = 1.2;
        closedWonOpportunity.DashPass_Eligible_CW__c = 'Yes';
        return closedWonOpportunity;        
    }            
    /** 
    * @description test method for CDdNimdaSyncStoreHelper.getPaymentProtocol
    */
    @isTest
    public static void testGetPaymentProtocol() {
        System.runAs (getTestRunUser()) {
            Map<String, SObject> data = setupData();
            Account sampleAccount = (Account)data.get(SAMPLE_ACCOUNT_RECORD);
            Opportunity sampleOpportunity = (Opportunity)data.get(SAMPLE_OPPORTUNITY_RECORD);
            sampleOpportunity.Order_Protocol__c = 'POS';
            sampleOpportunity.Shopping_Protocol__c = 'Mx Pick';
            update sampleOpportunity;
            Contact sampleContact = (Contact)data.get(SAMPLE_CONTACT_RECORD);
            Test.startTest();
            Object retVal = CDdLtngNimdaSyncMSCtrl.getStoreRequest('143611', sampleAccount, sampleOpportunity);
            System.assertEquals(true, retVal != null, 'Expecting successful update of account and opportunity');
            Test.stopTest();
        }      
    }
    /** 
    * @description Run positive test case - Get Mx API
    */
    @isTest
    public static void testPositiveGetMFSAPI() {
        System.runAs (getTestRunUser()) {
            Test.startTest();
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('mockResponse_GET_MFS_API');
            mock.setStatusCode(200);
            mock.setHeader('Content-Type', 'application/json');
            // Set the mock callout mode
            Test.setMock(HttpCalloutMock.class, mock);
            Object retObj = CDdLtngNimdaSyncMSCtrl.getmxAffiliateProgram('123456');
            System.assertEquals(true, retObj!=null, 'Expecting a valid return object');
            Test.stopTest();
        }
    }
    /** 
    * @description Run negative test case - Get Mx API
    */
    @isTest
    public static void testNegativeGetMFSAPI() {
        System.runAs (getTestRunUser()) {
            Test.startTest();
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('mockResponse_DSJ_search_no_records');
            mock.setStatusCode(500);
            mock.setHeader('Content-Type', 'application/json');
            // Set the mock callout mode
            Test.setMock(HttpCalloutMock.class, mock);
            // Execute with no result returned by Get store
            try {
                Object retObj = CDdLtngNimdaSyncMSCtrl.getmxAffiliateProgram('123456');
            } catch (AuraHandledException ex){
                System.assertEquals(true, ex!=null, 'No MFS programs for Given store Id');                
            }
        }
    }
}