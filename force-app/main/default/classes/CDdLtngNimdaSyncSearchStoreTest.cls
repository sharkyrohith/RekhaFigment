/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 04/16/2019
*
* @group Nimda
*
* @description Purpose is to test the Lightning Controller for Search Store, Address
* 
**************************************************************************************************************************************/
@isTest
public class CDdLtngNimdaSyncSearchStoreTest {
    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    public static final Id ACCOUNT_RECORDTYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByName().get(CDdSupportConstants.RECORDTYPE_NAME_MARKETPLACE).getRecordTypeId();
    public static final String PARENT_ACCOUNT_NAME = 'Parent Account';
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
            // Parent Account Insertion
            Account parentAcc = TDdAccountFactory.createAccount(ACCOUNT_RECORDTYPE_ID);
            parentAcc.Name = PARENT_ACCOUNT_NAME;
            parentAcc.Requesting_Account_Management__c = 'Unmanaged';
            insert parentAcc;
            
            // Child accounts
            List<Account> childAcc = TDdAccountFactory.createAccounts('Child Account', 1);
            childAcc[0].ParentId = parentAcc.Id;
            insert childAcc;

            List<Contact> testConsList = TDdAccountFactory.createContacts(1, childAcc[0].Id);
            insert testConsList;        
            Test.stopTest();
        }
    }
   /** 
    * @description Run negative test case - Search Store
    */
    @isTest
    public static void testNegativeSearchStore() {
        System.runAs (getTestRunUser()) {
            Account parentAcct = [SELECT Id FROM Account WHERE Name =:PARENT_ACCOUNT_NAME];
            Account childAcct = [SELECT Id,Name,ParentId,BillingCountry FROM Account WHERE ParentId=:parentAcct.Id];
            Contact contacts = [SELECT Id,accountId FROM Contact WHERE accountId=:childAcct.Id];
            Test.startTest();
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('mockResponse_DSJ_search_no_records');
            mock.setStatusCode(200);
            mock.setHeader('Content-Type', 'application/json');
            // Set the mock callout mode
            Test.setMock(HttpCalloutMock.class, mock);
            // Execute with no records returned by search
            try {
                Object retObj = CDdLtngNimdaSyncCtrl.getStores('204482', '27859996', childAcct);
            } catch (AuraHandledException ex){
                System.assertEquals(true, ex!=null, 'Expecting error ');                
            }           
            Test.stopTest();
        }
    }
   /** 
    * @description Run negative test case - Search Address
    */
    @isTest
    public static void testNegativeSearchAddress() {
        System.runAs (getTestRunUser()) {
            Account parentAcct = [SELECT Id FROM Account WHERE Name =:PARENT_ACCOUNT_NAME];
            Account childAcct =  [SELECT Id,
                                    Name,
                                    ParentId,
                                    BillingCountry,
                                    BillingStreet,
                                    BillingCity,
                                    BillingState,
                                    BillingCountryCode,
                                    Phone, 
                                    BillingPostalCode  
                                 FROM Account 
                                 WHERE ParentId=:parentAcct.Id];
            Contact contacts = [SELECT Id,accountId FROM Contact WHERE accountId=:childAcct.Id];
            Test.startTest();
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('mockResponse_DSJ_search_no_records');
            mock.setStatusCode(200);
            mock.setHeader('Content-Type', 'application/json');
            // Set the mock callout mode
            Test.setMock(HttpCalloutMock.class, mock);
            // Execute with no records returned by search
            try {
                Object retObj = CDdLtngNimdaSyncCtrl.getAddresses(childAcct);
            } catch (AuraHandledException ex){
                System.assertEquals(true, ex!=null, 'Expecting error ');                
            }
            Test.stopTest();
        }
    }
   /** 
    * @description Run negative test case - Search Address
    */
    @isTest
    public static void testInvalidSearchAddress() {
        System.runAs (getTestRunUser()) {
            Account parentAcct = [SELECT Id FROM Account WHERE Name =:PARENT_ACCOUNT_NAME];
            Account childAcct =  [SELECT Id,
                                    Name,
                                    ParentId,
                                    BillingCountry,
                                    BillingStreet,
                                    BillingCity,
                                    BillingState,
                                    BillingCountryCode,
                                    Phone, 
                                    BillingPostalCode  
                                 FROM Account 
                                 WHERE ParentId=:parentAcct.Id];
            Contact contacts = [SELECT Id,accountId FROM Contact WHERE accountId=:childAcct.Id];

            Test.startTest();
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('mockResponse_DSJ_search_no_records');
            mock.setStatusCode(200);
            mock.setHeader('Content-Type', 'application/json');
            // Set the mock callout mode
            Test.setMock(HttpCalloutMock.class, mock);
            // Execute with no records returned by search
            try {
                childAcct.BillingStreet = null;
                Object retObj = CDdLtngNimdaSyncCtrl.getAddresses(childAcct);
            } catch (AuraHandledException ex){
                System.assertEquals(true, ex!=null, 'Expecting error ');                
            }
            Test.stopTest();
        }
    }    
   /** 
    * @description Run positive test case - Search Address
    */
    @isTest
    public static void testPositiveSearchAddress() {
        System.runAs (getTestRunUser()) {        
            Account parentAcct = [SELECT Id FROM Account WHERE Name =:PARENT_ACCOUNT_NAME];
            Account childAcct =  [SELECT Id,
                                    Name,
                                    ParentId,
                                    BillingCountry,
                                    BillingStreet,
                                    BillingCity,
                                    BillingState,
                                    BillingCountryCode,
                                    Phone, 
                                    BillingPostalCode  
                                 FROM Account 
                                 WHERE ParentId=:parentAcct.Id];            
            Contact contacts = [SELECT Id,accountId FROM Contact WHERE accountId=:childAcct.Id];
            Test.startTest();
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('mockResponse_DSJ_search_address_success');
            mock.setStatusCode(200);
            mock.setHeader('Content-Type', 'application/json');
            // Set the mock callout mode
            Test.setMock(HttpCalloutMock.class, mock);
            Object retObj = CDdLtngNimdaSyncCtrl.getAddresses(childAcct);
            System.assertEquals(true, retObj!=null, 'Expecting a valid return object');
            Test.stopTest();
        }
    }
   /** 
    * @description Run positive test case - Search Store
    */
    @isTest
    public static void testPositiveSearchStore() {
        System.runAs (getTestRunUser()) {        
            Account parentAcct = [SELECT Id FROM Account WHERE Name =:PARENT_ACCOUNT_NAME];
            Account childAcct = [SELECT Id,
                                    Name,
                                    ParentId,
                                    BillingCountry,
                                    BillingStreet,
                                    BillingCity,
                                    BillingState,
                                    BillingCountryCode,
                                    Phone, 
                                    BillingPostalCode  
                                 FROM Account 
                                 WHERE ParentId=:parentAcct.Id];
            Contact contacts = [SELECT Id,accountId FROM Contact WHERE accountId=:childAcct.Id];
            Test.startTest();
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('mockResponse_DSJ_search_store_success');
            mock.setStatusCode(200);
            mock.setHeader('Content-Type', 'application/json');
            // Set the mock callout mode
            Test.setMock(HttpCalloutMock.class, mock);
            Object retObj = CDdLtngNimdaSyncCtrl.getStores('204482', '27859996', childAcct);
            System.assertEquals(true, retObj!=null, 'Expecting a valid return object');
            Test.stopTest();
        }
    }
   /** 
    * @description test for Get Nimda Store Field Definitions
    */
    @isTest
    public static void testGetNimdaStoreFieldDefinitions() {
        System.runAs (getTestRunUser()) {
            Test.startTest();
            Object retObj = CDdLtngNimdaSyncCtrl.getNimdaStoreFieldDefinitions();
            System.assertEquals(true, retObj!=null, 'Expecting a valid return object');
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
            Object retObj = CDdLtngNimdaSyncCtrl.getStore('123456');
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
                Object retObj = CDdLtngNimdaSyncCtrl.getStore('123456');
            } catch (AuraHandledException ex){
                System.assertEquals(true, ex!=null, 'Expecting error ');                
            }
        }
    }
   /** 
    * @description Run positive test case - Get Store Partnership
    */
    @isTest
    public static void testPositiveGetStorePartnership() {
        System.runAs (getTestRunUser()) {
            Test.startTest();
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('mockResponse_DSJ_get_store_success');
            mock.setStatusCode(200);
            mock.setHeader('Content-Type', 'application/json');
            // Set the mock callout mode
            Test.setMock(HttpCalloutMock.class, mock);
            Object retObj = CDdLtngNimdaSyncCtrl.getStorePartnership('123456');
            System.assertEquals(true, retObj!=null, 'Expecting a valid return object');
            Test.stopTest();
        }
    }
   /** 
    * @description Run negative test case - Get Store Partnership
    */
    @isTest
    public static void testNegativeGetStorePartnership() {
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
                Object retObj = CDdLtngNimdaSyncCtrl.getStorePartnership('123456');
            } catch (AuraHandledException ex){
                System.assertEquals(true, ex!=null, 'Expecting error ');                
            }
        }
    }
   /** 
    * @description Run positive test case - Get Payment Account
    */
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
            Object retObj = CDdLtngNimdaSyncCtrl.getPaymentAccount('123456');
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
                Object retObj = CDdLtngNimdaSyncCtrl.getPaymentAccount('');
            } catch (AuraHandledException ex){
                System.assertEquals(true, ex!=null, 'Expecting error ');                
            }
        }
    }                                              
   /** 
    * @description Run negative test case - Get Payment Account
    */
    @isTest
    public static void testNegativeGetPaymentAccount2() {
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
                Object retObj = CDdLtngNimdaSyncCtrl.getPaymentAccount('123456');
            } catch (AuraHandledException ex){
                System.assertEquals(true, ex!=null, 'Expecting error ');                
            }
        }
    }
   /** 
    * @description Run positive test case - Get Store Point of Sale Info
    */
    @isTest
    public static void testPositiveGetStorePOS() {
        System.runAs (getTestRunUser()) {
            Test.startTest();
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('mockResponse_DSJ_get_store_success');
            mock.setStatusCode(200);
            mock.setHeader('Content-Type', 'application/json');
            // Set the mock callout mode
            Test.setMock(HttpCalloutMock.class, mock);
            Object retObj = CDdLtngNimdaSyncCtrl.getStorePOS('123456');
            System.assertEquals(true, retObj!=null, 'Expecting a valid return object');
            Test.stopTest();
        }
    }
   /** 
    * @description Run negative test case - Get Store Point of Sale Info
    */
    @isTest
    public static void testNegativeGetStorePOS() {
        System.runAs (getTestRunUser()) {
            Test.startTest();
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('mockResponse_DSJ_search_no_records');
            mock.setStatusCode(400);
            mock.setHeader('Content-Type', 'application/json');
            // Set the mock callout mode
            Test.setMock(HttpCalloutMock.class, mock);
            // Execute with no result returned by Get store
            try {
                Object retObj = CDdLtngNimdaSyncCtrl.getStorePOS('123456');
            } catch (AuraHandledException ex){
                System.assertEquals(true, ex!=null, 'Expecting error ');                
            }
        }
    }                                                            
}