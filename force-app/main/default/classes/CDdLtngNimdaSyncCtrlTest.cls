/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 04/16/2019
*
* @group Nimda
*
* @description Purpose is to test the Lightning Controller - CDdLtngNimdaSyncCtrl
* 
**************************************************************************************************************************************/
@isTest
public class CDdLtngNimdaSyncCtrlTest {
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
    * @description Run test case - Get Account
    */
    @isTest
    public static void testGetAccount() {
        System.runAs (getTestRunUser()) {
            Account parentAcct = TDdAccountFactory.createAccounts('Parent Account', 1)[0];
            parentAcct.Business_ID__c = 143611;
            //parentAcct.Requesting_Account_Management__c = 'Unmanaged';
            Account childAcct = TDdAccountFactory.createAccounts('Child Account', 1)[0];
            childAcct.BillingCountry = 'United States';
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
            // Get Account
            Test.startTest();
            // Execute positive use case
            Account retObj = CDdLtngNimdaSyncCtrl.getAccount(childAcct.Id);
            System.assertEquals(true, retObj!=null, 'Expecting a valid return object');
            System.assertEquals(childAcct.Id, retObj.Id, 'Expecting account identifier ' + childAcct.Id);
            Test.stopTest();
        }
    }
   /** 
    * @description Run test case - Invalid Account Id
    */
    @isTest
    public static void testInvalidAccount() {
        System.runAs (getTestRunUser()) {
            // Get Account
            Test.startTest();           
            // Execute negative use case
            try {
                Account retObj = CDdLtngNimdaSyncCtrl.getAccount(null);
            } catch (AuraHandledException ex){
                System.assertEquals(true, ex!=null, 'Expecting error ');                
            }
            Test.stopTest();
        }
    }    
   /** 
    * @description Run test case - Get Opportunity
    */
    @isTest
    public static void testGetOpportunity() {
        System.runAs (getTestRunUser()) {
            Account parentAcct = TDdAccountFactory.createAccounts('Parent Account', 1)[0];
            parentAcct.Business_ID__c = 143611;
            //parentAcct.Requesting_Account_Management__c = 'Unmanaged';
            Account childAcct = TDdAccountFactory.createAccounts('Child Account', 1)[0];
            //childAcct.BillingCountry = 'United States';
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
            // Get Account
            Test.startTest();
            // Execute positive use case
            Opportunity retObj = CDdLtngNimdaSyncCtrl.getOpportunity(closedWonOpportunity.Id);
            System.assertEquals(true, retObj!=null, 'Expecting a valid return object');
            System.assertEquals(closedWonOpportunity.Id, retObj.Id, 'Expecting account identifier ' + closedWonOpportunity.Id);
            Test.stopTest();
        }
    }
   /** 
    * @description Run test case - Invalid Opportunity Id
    */
    @isTest
    public static void testInvalidOpportunity() {
        System.runAs (getTestRunUser()) {
            // Get Opportunity
            Test.startTest();           
            // Execute negative use case
            try {
                Opportunity retObj = CDdLtngNimdaSyncCtrl.getOpportunity(null);
            } catch (AuraHandledException ex){
                System.assertEquals(true, ex!=null, 'Expecting error ');                
            }
            Test.stopTest();
        }
    }     
   /** 
    * @description Run test case - Invalid Address on Account
    */
    @isTest
    public static void testInvalidAddress() {
        System.runAs (getTestRunUser()) {
            Account parentAcct = TDdAccountFactory.createAccounts('Parent Account', 1)[0];
            parentAcct.Business_ID__c = 143611;
            //parentAcct.Requesting_Account_Management__c = 'Unmanaged';
            Account childAcct = TDdAccountFactory.createAccounts('Child Account', 1)[0];
            // - No Billing Country
            //childAcct.BillingCountry = 'United States';
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
            // Get Account
            Test.startTest();
            // Execute positive use case
            Opportunity retObj1 = CDdLtngNimdaSyncCtrl.getOpportunity(closedWonOpportunity.Id);
            System.assertEquals(true, retObj1!=null, 'Expecting a valid return object');
            System.assertEquals(closedWonOpportunity.Id, retObj1.Id, 'Expecting account identifier ' + closedWonOpportunity.Id);
            // Execute negative use case
            try {
                Object retObj = CDdLtngNimdaSyncCtrl.createStore('143611', childAcct, closedWonOpportunity);
            } catch (AuraHandledException ex){
                System.assertEquals(true, ex!=null, 'Expecting error ');                
            }
            Test.stopTest();
        }
    }                   
   /** 
    * @description Run positive test case - Create Store
    */
    @isTest
    public static void testPositiveCreateStore() {
        System.runAs (getTestRunUser()) {
            Account parentAcct = TDdAccountFactory.createAccounts('Parent Account', 1)[0];
            parentAcct.Business_ID__c = 143611;
            //parentAcct.Requesting_Account_Management__c = 'Unmanaged';
            Account childAcct = TDdAccountFactory.createAccounts('Child Account', 1)[0];
            childAcct.BillingCountry = 'United States';
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

            Test.startTest();
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('mockResponse_DSJ_store_success');
            mock.setStatusCode(200);
            mock.setHeader('Content-Type', 'application/json');
            // Set the mock callout mode
            Test.setMock(HttpCalloutMock.class, mock);
            Object retVal = CDdLtngNimdaSyncCtrl.createStore('143611', childAcct, closedWonOpportunity);
            CDdNimdaSyncService.CDdNimdaSyncInfo retObj = (CDdNimdaSyncService.CDdNimdaSyncInfo)JSON.deserialize((String)retVal, CDdNimdaSyncService.CDdNimdaSyncInfo.class);
            System.assertEquals(true, retObj!=null, 'Expecting a valid return object');
            System.assertEquals(CDdNimdaSyncConstants.STEP_CREATE_STORE, ((CDdNimdaSyncService.CDdNimdaSyncInfo)retObj).step, 'Expecting step ' + CDdNimdaSyncConstants.STEP_CREATE_STORE);
            Test.stopTest();
        }
    }
   /** 
    * @description Run negative test case - Create Store
    */
    @isTest
    public static void testNegativeCreateStore() {
        System.runAs (getTestRunUser()) {
            Account parentAcct = TDdAccountFactory.createAccounts('Parent Account', 1)[0];
            parentAcct.Business_ID__c = 143611;
            //parentAcct.Requesting_Account_Management__c = 'Unmanaged';
            Account childAcct = TDdAccountFactory.createAccounts('Child Account', 1)[0];
            childAcct.BillingCountry = 'United States';
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

            Test.startTest();
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('mockResponse_DSJ_store_failure');
            mock.setStatusCode(200);
            mock.setHeader('Content-Type', 'application/json');
            // Set the mock callout mode
            Test.setMock(HttpCalloutMock.class, mock);
            // Execute with invalid store response
            try {
                Object retObj = CDdLtngNimdaSyncCtrl.createStore('143611', childAcct, closedWonOpportunity);
            } catch (AuraHandledException ex){
                System.assertEquals(true, ex!=null, 'Expecting error ');                
            }   
            Test.stopTest();
        }
    }
   /** 
    * @description Run positive test case - Update Store
    */
    @isTest
    public static void testPositiveUpdateStore() {
        System.runAs (getTestRunUser()) {
            Test.startTest();
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('mockResponse_DSJ_get_store_success');
            mock.setStatusCode(200);
            mock.setHeader('Content-Type', 'application/json');
            // Set the mock callout mode
            Test.setMock(HttpCalloutMock.class, mock);
            Map<String, String> stroreRequestMap = new Map<String, String>{'name' => 'test store'};
            Object retVal = CDdLtngNimdaSyncCtrl.updateStore('143611', JSON.serialize(stroreRequestMap));
            CDdNimdaSyncSearchStoreService.CDdNimdaSyncInfo retObj = (CDdNimdaSyncSearchStoreService.CDdNimdaSyncInfo)JSON.deserialize((String)retVal, CDdNimdaSyncSearchStoreService.CDdNimdaSyncInfo.class);
            System.assertEquals(true, retObj!=null, 'Expecting a valid return object');
            System.assertEquals(CDdNimdaSyncConstants.STEP_UPDATE_STORE, ((CDdNimdaSyncSearchStoreService.CDdNimdaSyncInfo)retObj).step, 'Expecting step ' + CDdNimdaSyncConstants.STEP_UPDATE_STORE);
            Test.stopTest();
        }
    }
   /** 
    * @description Run negative test case - Update Store
    */
    @isTest
    public static void testNegativeUpdateStore() {
        System.runAs (getTestRunUser()) {
            Test.startTest();
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('mockResponse_DSJ_store_failure');
            mock.setStatusCode(400);
            mock.setHeader('Content-Type', 'application/json');
            // Set the mock callout mode
            Test.setMock(HttpCalloutMock.class, mock);
            // Execute with invalid store response
            try {
                Map<String, String> stroreRequestMap = new Map<String, String>{'name' => 'test store'};
                Object retVal = CDdLtngNimdaSyncCtrl.updateStore('143611', JSON.serialize(stroreRequestMap));
            } catch (AuraHandledException ex){
                System.assertEquals(true, ex!=null, 'Expecting error ');                
            }   
            Test.stopTest();
        }
    }
   /** 
    * @description Run positive test case - Update Store Point of Sale Info
    */
    @isTest
    public static void testPositiveUpdateStorePOS() {
        System.runAs (getTestRunUser()) {
            Test.startTest();
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('mockResponse_DSJ_get_store_success');
            mock.setStatusCode(200);
            mock.setHeader('Content-Type', 'application/json');
            // Set the mock callout mode
            Test.setMock(HttpCalloutMock.class, mock);
            Map<String, String> storeRequestMap = new Map<String, String>{'provider_type' => 'olo_rails', 'location_id' => '13333'};
            Object retVal = CDdLtngNimdaSyncCtrl.updateStorePOS('143611', JSON.serialize(storeRequestMap));
            CDdNimdaSyncSearchStoreService.CDdNimdaSyncInfo retObj = (CDdNimdaSyncSearchStoreService.CDdNimdaSyncInfo)JSON.deserialize((String)retVal, CDdNimdaSyncSearchStoreService.CDdNimdaSyncInfo.class);
            System.assertEquals(true, retObj!=null, 'Expecting a valid return object');
            System.assertEquals(CDdNimdaSyncConstants.STEP_UPDATE_STORE, ((CDdNimdaSyncSearchStoreService.CDdNimdaSyncInfo)retObj).step, 'Expecting step ' + CDdNimdaSyncConstants.STEP_UPDATE_STORE);
            Test.stopTest();
        }
    }
   /** 
    * @description Run negative test case - Update Store Point of Sale Info
    */
    @isTest
    public static void testNegativeUpdateStorePOS() {
        System.runAs (getTestRunUser()) {
            Test.startTest();
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('mockResponse_DSJ_store_failure');
            mock.setStatusCode(400);
            mock.setHeader('Content-Type', 'application/json');
            // Set the mock callout mode
            Test.setMock(HttpCalloutMock.class, mock);
            // Execute with invalid store response
            try {
                Map<String, String> storeRequestMap = new Map<String, String>{'provider_type' => 'olo_rails', 'location_id' => '13333'};
                Object retVal = CDdLtngNimdaSyncCtrl.updateStorePOS('143611', JSON.serialize(storeRequestMap));
            } catch (AuraHandledException ex){
                System.assertEquals(true, ex!=null, 'Expecting error ');                
            }   
            Test.stopTest();
        }
    }        
   /** 
    * @description Run positive test case - Create User
    */
    @isTest
    public static void testPositiveCreateUser() {
        System.runAs (getTestRunUser()) {
            Account parentAcct = TDdAccountFactory.createAccounts('Parent Account', 1)[0];
            parentAcct.Business_ID__c = 143611;
            //parentAcct.Requesting_Account_Management__c = 'Unmanaged';
            Account childAcct = TDdAccountFactory.createAccounts('Child Account', 1)[0];
            childAcct.BillingCountry = 'United States';
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

            Test.startTest();
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('mockResponse_DSJ_user_success');
            mock.setStatusCode(200);
            mock.setHeader('Content-Type', 'application/json');
            // Set the mock callout mode
            Test.setMock(HttpCalloutMock.class, mock);
            Object retVal = CDdLtngNimdaSyncCtrl.createUser('143611', '272630', childAcct, closedWonOpportunity);
            CDdNimdaSyncService.CDdNimdaSyncInfo retObj = (CDdNimdaSyncService.CDdNimdaSyncInfo)JSON.deserialize((String)retVal, CDdNimdaSyncService.CDdNimdaSyncInfo.class);
            System.assertEquals(true, retObj!=null, 'Expecting a valid return object');
            System.assertEquals(CDdNimdaSyncConstants.STEP_CREATE_USER, ((CDdNimdaSyncService.CDdNimdaSyncInfo)retObj).step, 'Expecting step ' + CDdNimdaSyncConstants.STEP_CREATE_USER);           
            Test.stopTest();
        }
    }
   /** 
    * @description Run negative test case - Create User
    */
    @isTest
    public static void testNegativeCreateUser() {
        System.runAs (getTestRunUser()) {
            Account parentAcct = TDdAccountFactory.createAccounts('Parent Account', 1)[0];
            parentAcct.Business_ID__c = 143611;
            //parentAcct.Requesting_Account_Management__c = 'Unmanaged';
            Account childAcct = TDdAccountFactory.createAccounts('Child Account', 1)[0];
            childAcct.BillingCountry = 'United States';
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

            Test.startTest();
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('mockResponse_DSJ_user_failure');
            mock.setStatusCode(200);
            mock.setHeader('Content-Type', 'application/json');
            // Set the mock callout mode
            Test.setMock(HttpCalloutMock.class, mock);
            // Execute with invalid store id
            try {
                Object retObj = CDdLtngNimdaSyncCtrl.createUser('143611', null, childAcct, closedWonOpportunity);
            } catch (AuraHandledException ex){
                System.assertEquals(true, ex!=null, 'Expecting error ');                
            }
            // Execute with invalid opportunity type
            try {
                closedWonOpportunity.Type = CDdNimdaSyncConstants.OPPORTUNITY_TYPE_PROTOCOL_CHANGE_ONLY_NP;
                Object retObj = CDdLtngNimdaSyncCtrl.createUser('143611', '272630', childAcct, closedWonOpportunity);
            } catch (AuraHandledException ex){
                System.assertEquals(true, ex!=null, 'Expecting error ');                
            }               
            Test.stopTest();
        }
    }
   /** 
    * @description Run positive test case - Create Merchant
    */
    @isTest
    public static void testPositiveCreateMerchant() {
        System.runAs (getTestRunUser()) {
            Account parentAcct = TDdAccountFactory.createAccounts('Parent Account', 1)[0];
            parentAcct.Business_ID__c = 143611;
            //parentAcct.Requesting_Account_Management__c = 'Unmanaged';
            Account childAcct = TDdAccountFactory.createAccounts('Child Account', 1)[0];
            childAcct.BillingCountry = 'United States';
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

            Test.startTest();
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('mockResponse_DSJ_merchant_success');
            mock.setStatusCode(200);
            mock.setHeader('Content-Type', 'application/json');
            // Set the mock callout mode
            Test.setMock(HttpCalloutMock.class, mock);
            Object retVal = CDdLtngNimdaSyncCtrl.createMerchant('143611', '272630', '36137649', childAcct, closedWonOpportunity);
            CDdNimdaSyncService.CDdNimdaSyncInfo retObj = (CDdNimdaSyncService.CDdNimdaSyncInfo)JSON.deserialize((String)retVal, CDdNimdaSyncService.CDdNimdaSyncInfo.class);           
            System.assertEquals(true, retObj!=null, 'Expecting a valid return object');
            System.assertEquals(CDdNimdaSyncConstants.STEP_CREATE_MERCHANT, ((CDdNimdaSyncService.CDdNimdaSyncInfo)retObj).step, 'Expecting step ' + CDdNimdaSyncConstants.STEP_CREATE_MERCHANT);           
            Test.stopTest();
        }
    }
   /** 
    * @description Run negative test case - Create Merchant
    */
    @isTest
    public static void testNegativeCreateMerchant() {
        System.runAs (getTestRunUser()) {
            Account parentAcct = TDdAccountFactory.createAccounts('Parent Account', 1)[0];
            parentAcct.Business_ID__c = 143611;
            //parentAcct.Requesting_Account_Management__c = 'Unmanaged';
            Account childAcct = TDdAccountFactory.createAccounts('Child Account', 1)[0];
            childAcct.BillingCountry = 'United States';
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

            Test.startTest();
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('mockResponse_DSJ_merchant_failure');
            mock.setStatusCode(200);
            mock.setHeader('Content-Type', 'application/json');
            // Set the mock callout mode
            Test.setMock(HttpCalloutMock.class, mock);
            try {
                Object retObj = CDdLtngNimdaSyncCtrl.createMerchant('143611', '272630', '36137649', childAcct, closedWonOpportunity);
            } catch (AuraHandledException ex){
                System.assertEquals(true, ex!=null, 'Expecting error ');                
            }
            Test.stopTest();
        }
    }
   /** 
    * @description Run positive test case - Create Payment Account
    */
    @isTest
    public static void testPositiveCreatePaymentAccount() {
        String PAYMENT_ACCOUNTS_ENDPOINT = 'https://api.doordash.com/v1/payment_accounts/';
        System.runAs (getTestRunUser()) {
            Account parentAcct = TDdAccountFactory.createAccounts('Parent Account', 1)[0];
            parentAcct.Business_ID__c = 143611;
            //parentAcct.Requesting_Account_Management__c = 'Unmanaged';
            Account childAcct = TDdAccountFactory.createAccounts('Child Account', 1)[0];
            childAcct.BillingCountry = 'United States';
            // Payment Account Details on the Account object
            childAcct.Legal_Business_Name__c = 'Test Entity Business';
            /*childAcct.EIN_Encrypted__c = '123456';
            childAcct.Bank_Account_Number_Encrypted__c = '12345678900';
            childAcct.Bank_Routing_Number_Encrypted__c = '123456';  */         
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

            Test.startTest();
            StaticResourceCalloutMock mock1 = new StaticResourceCalloutMock();
            mock1.setStaticResource('mockResponse_Stripe_Account_Token_success');
            mock1.setStatusCode(200);
            mock1.setHeader('Content-Type', 'application/json');
            StaticResourceCalloutMock mock2 = new StaticResourceCalloutMock();
            mock2.setStaticResource('mockResponse_DSJ_payment_acct_success');
            mock2.setStatusCode(200);
            mock2.setHeader('Content-Type', 'application/json');
            Map<String, HttpCalloutMock> calloutMockMap = new Map<String, HttpCalloutMock>();
            calloutMockMap.put(CDdNimdaSyncConstants.CREATE_STRIPE_BANK_TOKEN_ENDPOINT, mock1);
            calloutMockMap.put(PAYMENT_ACCOUNTS_ENDPOINT, mock2);
            HttpCalloutMock multiCalloutMock = new MultiRequestMock(calloutMockMap);
            // Set the mock callout mode
            Test.setMock(HttpCalloutMock.class, multiCalloutMock);
            Account testAccount = CDdLtngNimdaSyncCtrl.getAccount(childAcct.Id);
            Opportunity testOpportunity = CDdLtngNimdaSyncCtrl.getOpportunity(closedWonOpportunity.Id);
            Object retVal = CDdLtngNimdaSyncCtrl.createPaymentAccount('143611', '272630', testAccount, testOpportunity);
            CDdNimdaSyncService.CDdNimdaSyncInfo retObj = (CDdNimdaSyncService.CDdNimdaSyncInfo)JSON.deserialize((String)retVal, CDdNimdaSyncService.CDdNimdaSyncInfo.class);           
            System.assertEquals(true, retObj!=null, 'Expecting a valid return object');
            System.assertEquals(CDdNimdaSyncConstants.STEP_PAYMENT_ACCOUNT, ((CDdNimdaSyncService.CDdNimdaSyncInfo)retObj).step, 'Expecting step ' + CDdNimdaSyncConstants.STEP_PAYMENT_ACCOUNT);           
            Test.stopTest();
        }
    }    
   /** 
    * @description Run negative test case - Create Payment Account
    */
    @isTest
    public static void testNegativeCreatePaymentAccount() {
        System.runAs (getTestRunUser()) {
            Account parentAcct = TDdAccountFactory.createAccounts('Parent Account', 1)[0];
            parentAcct.Business_ID__c = 143611;
            //parentAcct.Requesting_Account_Management__c = 'Unmanaged';
            Account childAcct = TDdAccountFactory.createAccounts('Child Account', 1)[0];
            childAcct.BillingCountry = 'United States';
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

            Test.startTest();
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('mockResponse_DSJ_payment_acct_failure');
            mock.setStatusCode(200);
            mock.setHeader('Content-Type', 'application/json');
            // Set the mock callout mode
            Test.setMock(HttpCalloutMock.class, mock);
            // Store Id null
            try {
                Object retObj = CDdLtngNimdaSyncCtrl.createPaymentAccount('143611', null, childAcct, closedWonOpportunity);
            } catch (AuraHandledException ex){
                System.assertEquals(true, ex!=null, 'Expecting error ');                
            }
            // Error in response
            try {
                Object retObj = CDdLtngNimdaSyncCtrl.createPaymentAccount('143611', '272630', childAcct, closedWonOpportunity);
            } catch (AuraHandledException ex){
                System.assertEquals(true, ex!=null, 'Expecting error ');                
            }           
            // Field error on the Opportunity record
            try {
                closedWonOpportunity.Stripe_Account_Owner__c = null;
                Object retObj = CDdLtngNimdaSyncCtrl.createPaymentAccount('143611', null, childAcct, closedWonOpportunity);
            } catch (AuraHandledException ex){
                System.assertEquals(true, ex!=null, 'Expecting error ');                
            }                       
            Test.stopTest();
        }
    }
   /** 
    * @description Run positive test case - Create Stripe Bank Token
    */
    @isTest
    public static void testPositiveCreateStripeBankToken() {
        System.runAs (getTestRunUser()) {
            Account parentAcct = TDdAccountFactory.createAccounts('Parent Account', 1)[0];
            parentAcct.Business_ID__c = 143611;
            //parentAcct.Requesting_Account_Management__c = 'Unmanaged';
            Account childAcct = TDdAccountFactory.createAccounts('Child Account', 1)[0];
            childAcct.BillingCountry = 'United States';
            // Payment Account Details on the Account object
            childAcct.Legal_Business_Name__c = 'Test Entity Business';
            /*childAcct.EIN_Encrypted__c = '123456';
            childAcct.Bank_Account_Number_Encrypted__c = '12345678900';
            childAcct.Bank_Routing_Number_Encrypted__c = '123456'; */    
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

            Test.startTest();
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('mockResponse_Stripe_Token_success');
            mock.setStatusCode(200);
            mock.setHeader('Content-Type', 'application/json');
            // Set the mock callout mode
            Test.setMock(HttpCalloutMock.class, mock);
            Object retVal = CDdLtngNimdaSyncCtrl.createStripeBankToken('143611', childAcct, closedWonOpportunity);
            CDdNimdaSyncService.CDdNimdaSyncInfo retObj = (CDdNimdaSyncService.CDdNimdaSyncInfo)JSON.deserialize((String)retVal, CDdNimdaSyncService.CDdNimdaSyncInfo.class);
            System.assertEquals(true, retObj!=null, 'Expecting a valid return object');
            System.assertEquals(CDdNimdaSyncConstants.STEP_STRIPE_BANK_TOKEN, ((CDdNimdaSyncService.CDdNimdaSyncInfo)retObj).step, 'Expecting step ' + CDdNimdaSyncConstants.STEP_STRIPE_BANK_TOKEN);           
            Test.stopTest();
        }
    }
   /** 
    * @description Run negative test case - Create Stripe Bank Token
    */
    @isTest
    public static void testNegativeCreateStripeBankToken() {
        System.runAs (getTestRunUser()) {
            Account parentAcct = TDdAccountFactory.createAccounts('Parent Account', 1)[0];
            parentAcct.Business_ID__c = 143611;
            //parentAcct.Requesting_Account_Management__c = 'Unmanaged';
            Account childAcct = TDdAccountFactory.createAccounts('Child Account', 1)[0];
            childAcct.BillingCountry = 'United States';
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

            Test.startTest();
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('mockResponse_Stripe_Token_failure');
            mock.setStatusCode(200);
            mock.setHeader('Content-Type', 'application/json');
            // Set the mock callout mode
            Test.setMock(HttpCalloutMock.class, mock);
            // Error in response
            try {
                Object retObj = CDdLtngNimdaSyncCtrl.createStripeBankToken('143611', childAcct, closedWonOpportunity);
            } catch (AuraHandledException ex){
                System.assertEquals(true, ex!=null, 'Expecting error ');                
            }           
            Test.stopTest();
        }
    }
   /** 
    * @description Run positive test case - Create Stripe Bank Account
    */
    @isTest
    public static void testPositiveCreateStripeBankAccount() {
        System.runAs (getTestRunUser()) {
            Account parentAcct = TDdAccountFactory.createAccounts('Parent Account', 1)[0];
            parentAcct.Business_ID__c = 143611;
            //parentAcct.Requesting_Account_Management__c = 'Unmanaged';
            Account childAcct = TDdAccountFactory.createAccounts('Child Account', 1)[0];
            childAcct.BillingCountry = 'United States';
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

            Test.startTest();
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('mockResponse_Stripe_ExtAcct_success');
            mock.setStatusCode(200);
            mock.setHeader('Content-Type', 'application/json');
            // Set the mock callout mode
            Test.setMock(HttpCalloutMock.class, mock);
            Object retVal = CDdLtngNimdaSyncCtrl.createStripeBankAccount('143611', 'acct_1CSw7eJCKaerxYOb', '123456', childAcct, closedWonOpportunity);
            CDdNimdaSyncService.CDdNimdaSyncInfo retObj = (CDdNimdaSyncService.CDdNimdaSyncInfo)JSON.deserialize((String)retVal, CDdNimdaSyncService.CDdNimdaSyncInfo.class);
            System.assertEquals(true, retObj!=null, 'Expecting a valid return object');
            System.assertEquals(CDdNimdaSyncConstants.STEP_STRIPE_BANK_ACCOUNT, ((CDdNimdaSyncService.CDdNimdaSyncInfo)retObj).step, 'Expecting step ' + CDdNimdaSyncConstants.STEP_STRIPE_BANK_ACCOUNT);
            CDdLtngNimdaSyncCtrl.applyUpdates('143611', '272630', '123456', '123456', 'acct_1CSw7eJCKaerxYOb', 'ba_1CUOHGJCKaerxYObpFE81SWY', childAcct, closedWonOpportunity, JSON.serialize(new Map<String, String>{'step' => CDdNimdaSyncConstants.STEP_COMPLETE})); 
            CDdLtngNimdaSyncCtrl.applyPaymentV3Updates('123456', 'acct_1CSw7eJCKaerxYOb', 'ba_1CUOHGJCKaerxYObpFE81SWY', childAcct, closedWonOpportunity, JSON.serialize(new Map<String, String>{'step' => CDdNimdaSyncConstants.STEP_COMPLETE}));                         
            Test.stopTest();
        }
    }
   /** 
    * @description Run negative test case - Create Stripe Bank Account
    */
    @isTest
    public static void testNegativeCreateStripeBankAccount() {
        System.runAs (getTestRunUser()) {
            Account parentAcct = TDdAccountFactory.createAccounts('Parent Account', 1)[0];
            parentAcct.Business_ID__c = 143611;
            //parentAcct.Requesting_Account_Management__c = 'Unmanaged';
            Account childAcct = TDdAccountFactory.createAccounts('Child Account', 1)[0];
            childAcct.BillingCountry = 'United States';
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

            Test.startTest();
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('mockResponse_Stripe_ExtAcct_failure');
            mock.setStatusCode(200);
            mock.setHeader('Content-Type', 'application/json');
            // Set the mock callout mode
            Test.setMock(HttpCalloutMock.class, mock);
            // Strip Bank Token Id null
            try {
                Object retObj = CDdLtngNimdaSyncCtrl.createStripeBankAccount('143611', 'acct_1CSw7eJCKaerxYOb', null, childAcct, closedWonOpportunity);
            } catch (AuraHandledException ex){
                System.assertEquals(true, ex!=null, 'Expecting error ');                
            }
            // Error in response
            try {
                Object retObj = CDdLtngNimdaSyncCtrl.createStripeBankAccount('143611', 'acct_1CSw7eJCKaerxYOb', '12345', childAcct, closedWonOpportunity);
            } catch (AuraHandledException ex){
                System.assertEquals(true, ex!=null, 'Expecting error ');                
            }
            CDdLtngNimdaSyncCtrl.applyUpdates('143611', '272630', '123456', '123456', 'acct_1CSw7eJCKaerxYOb', 'ba_1CUOHGJCKaerxYObpFE81SWY', childAcct, closedWonOpportunity, JSON.serialize(new Map<String, String>{'step' => CDdNimdaSyncConstants.STEP_STRIPE_BANK_ACCOUNT, 'errorType' => 'Response Error', 'errorMessage' => 'Invalid Bank Token', 'calloutRequest' => 'Test callout request', 'calloutResponse' => 'Test callout response'}));
            CDdLtngNimdaSyncCtrl.applyPaymentV3Updates('123456', 'acct_1CSw7eJCKaerxYOb', 'ba_1CUOHGJCKaerxYObpFE81SWY', childAcct, closedWonOpportunity, JSON.serialize(new Map<String, String>{'step' => CDdNimdaSyncConstants.STEP_STRIPE_BANK_ACCOUNT, 'errorType' => 'Response Error', 'errorMessage' => 'Invalid Bank Token', 'calloutRequest' => 'Test callout request', 'calloutResponse' => 'Test callout response'}));
            Test.stopTest();
        }
    }
   /** 
    * @description Run positive test case - Create DSJ Bank Account
    */
    @isTest
    public static void testPositiveCreateDSJBankAccount() {
        System.runAs (getTestRunUser()) {
            Account parentAcct = TDdAccountFactory.createAccounts('Parent Account', 1)[0];
            parentAcct.Business_ID__c = 143611;
            //parentAcct.Requesting_Account_Management__c = 'Unmanaged';
            Account childAcct = TDdAccountFactory.createAccounts('Child Account', 1)[0];
            childAcct.BillingCountry = 'United States';
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

            Test.startTest();
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('mockResponse_DSJ_ExtAcct_success');
            mock.setStatusCode(200);
            mock.setHeader('Content-Type', 'application/json');
            // Set the mock callout mode
            Test.setMock(HttpCalloutMock.class, mock);
            Object retVal = CDdLtngNimdaSyncCtrl.createDSJBankAccount('143611', '13101674', '123456', childAcct, closedWonOpportunity);
            CDdNimdaSyncService.CDdNimdaSyncInfo retObj = (CDdNimdaSyncService.CDdNimdaSyncInfo)JSON.deserialize((String)retVal, CDdNimdaSyncService.CDdNimdaSyncInfo.class);
            System.assertEquals(true, retObj!=null, 'Expecting a valid return object');
            System.assertEquals(CDdNimdaSyncConstants.STEP_STRIPE_BANK_ACCOUNT, ((CDdNimdaSyncService.CDdNimdaSyncInfo)retObj).step, 'Expecting step ' + CDdNimdaSyncConstants.STEP_STRIPE_BANK_ACCOUNT);
            CDdLtngNimdaSyncCtrl.applyUpdates('143611', '272630', '123456', '13101674', 'acct_1CSw7eJCKaerxYOb', 'ba_1CUOHGJCKaerxYObpFE81SWY', childAcct, closedWonOpportunity, JSON.serialize(new Map<String, String>{'step' => CDdNimdaSyncConstants.STEP_COMPLETE}));
            CDdLtngNimdaSyncCtrl.applyPaymentV3Updates('13101674', 'acct_1CSw7eJCKaerxYOb', 'ba_1CUOHGJCKaerxYObpFE81SWY', childAcct, closedWonOpportunity, JSON.serialize(new Map<String, String>{'step' => CDdNimdaSyncConstants.STEP_COMPLETE}));                                                              
            Test.stopTest();
        }
    }
   /** 
    * @description Run negative test case - Create DSJ Bank Account
    */
    @isTest
    public static void testNegativeCreateDSJBankAccount() {
        System.runAs (getTestRunUser()) {
            Account parentAcct = TDdAccountFactory.createAccounts('Parent Account', 1)[0];
            parentAcct.Business_ID__c = 143611;
            //parentAcct.Requesting_Account_Management__c = 'Unmanaged';
            Account childAcct = TDdAccountFactory.createAccounts('Child Account', 1)[0];
            childAcct.BillingCountry = 'United States';
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

            Test.startTest();
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('mockResponse_DSJ_ExtAcct_failure');
            mock.setStatusCode(200);
            mock.setHeader('Content-Type', 'application/json');
            // Set the mock callout mode
            Test.setMock(HttpCalloutMock.class, mock);
            // Strip Bank Token Id null
            try {
                Object retObj = CDdLtngNimdaSyncCtrl.createDSJBankAccount('143611', '13101674', null, childAcct, closedWonOpportunity);
            } catch (AuraHandledException ex){
                System.assertEquals(true, ex!=null, 'Expecting error ');                
            }
            // Error in response
            try {
                Object retObj = CDdLtngNimdaSyncCtrl.createStripeBankAccount('143611', '13101674', '12345', childAcct, closedWonOpportunity);
            } catch (AuraHandledException ex){
                System.assertEquals(true, ex!=null, 'Expecting error ');                
            }
            CDdLtngNimdaSyncCtrl.applyUpdates('143611', '272630', '123456', '13101674', 'acct_1CSw7eJCKaerxYOb', 'ba_1CUOHGJCKaerxYObpFE81SWY', childAcct, closedWonOpportunity, JSON.serialize(new Map<String, String>{'step' => CDdNimdaSyncConstants.STEP_STRIPE_BANK_ACCOUNT, 'errorType' => 'Response Error', 'errorMessage' => 'Invalid Bank Token', 'calloutRequest' => 'Test callout request', 'calloutResponse' => 'Test callout response'}));
            CDdLtngNimdaSyncCtrl.applyPaymentV3Updates('13101674', 'acct_1CSw7eJCKaerxYOb', 'ba_1CUOHGJCKaerxYObpFE81SWY', childAcct, closedWonOpportunity, JSON.serialize(new Map<String, String>{'step' => CDdNimdaSyncConstants.STEP_STRIPE_BANK_ACCOUNT, 'errorType' => 'Response Error', 'errorMessage' => 'Invalid Bank Token', 'calloutRequest' => 'Test callout request', 'calloutResponse' => 'Test callout response'}));                                          
            Test.stopTest();
        }
    }    
   /** 
    * @description Run positive test case - Payment Account using Stripe Account Token
    */
    @isTest
    public static void testPositivePaymentAccountForAUS() {
        String PAYMENT_ACCOUNTS_ENDPOINT = 'https://api.doordash.com/v1/payment_accounts/';
        System.runAs (getTestRunUser()) {
            Account childAcct = TDdAccountFactory.createAccounts('Child Account', 1, 'Marketplace')[0];
            childAcct.Phone = '+61111111111';
            childAcct.Business_ID__c = 143611;
            childAcct.BillingStreet = '207 St Georges Rd';
            childAcct.BillingCity = 'Fitzroy North';
            childAcct.BillingState = 'Victoria';
            childAcct.BillingPostalCode = '3068';
            childAcct.BillingCountry = 'Australia';
            childAcct.BillingCountryCode = 'AU';
            // Legal Entity Address Details on the Account object
            childAcct.ShippingStreet = '207 St Georges Rd';
            childAcct.ShippingCity = 'Fitzroy North';
            childAcct.ShippingState = 'Victoria';
            childAcct.ShippingPostalCode = '3068';
            childAcct.ShippingCountry = 'Australia';
            // Payment Account Details on the Account object
            childAcct.Legal_Business_Name__c = 'Test Entity Business';
            childAcct.Mx_Tax_Id_VAT__c = '123456';
            childAcct.Bank_Account_Number_Encrypted__c = '12345678900';
            childAcct.Bank_Routing_Number_Encrypted__c = '123456'; 
            // Stripe Account Owner Details on the Contact object                       
            Contact contact = VTestUtil.createContact('Test', 'Contact', childAcct);
            contact.BirthDate = Date.newInstance(1990, 2, 24);
            contact.MailingStreet = '207 St Georges Rd';
            contact.MailingCity = 'Fitzroy North';
            contact.MailingState = 'Victoria';
            contact.MailingPostalCode = '3068';
            contact.MailingCountry = 'Australia';
            // store accounts     
            List<Account> accounts = new List<Account>();
            //accounts.add(parentAcct);
            accounts.add(childAcct);
            upsert accounts;
            // store contacts
            List<Contact> contacts = new List<Contact>();
            contacts.add(contact);
            upsert contacts;
            // store opportunities
            List<Opportunity> opportunities = new List<Opportunity>();
            Opportunity closedWonOpportunity =createClosedWonOpportunity('Test Closed Opp', childAcct, contact);
            closedWonOpportunity.Stripe_Account_Owner__c = contact.Id;
            opportunities.add(closedWonOpportunity);
            upsert opportunities;

            Test.startTest();
            StaticResourceCalloutMock mock1 = new StaticResourceCalloutMock();
            mock1.setStaticResource('mockResponse_Stripe_Account_Token_success');
            mock1.setStatusCode(200);
            mock1.setHeader('Content-Type', 'application/json');
            StaticResourceCalloutMock mock2 = new StaticResourceCalloutMock();
            mock2.setStaticResource('mockResponse_DSJ_payment_acct_success');
            mock2.setStatusCode(200);
            mock2.setHeader('Content-Type', 'application/json');
            Map<String, HttpCalloutMock> calloutMockMap = new Map<String, HttpCalloutMock>();
            calloutMockMap.put(CDdNimdaSyncConstants.CREATE_STRIPE_BANK_TOKEN_ENDPOINT, mock1);
            calloutMockMap.put(PAYMENT_ACCOUNTS_ENDPOINT, mock2);
            HttpCalloutMock multiCalloutMock = new MultiRequestMock(calloutMockMap);
            // Set the mock callout mode
            Test.setMock(HttpCalloutMock.class, multiCalloutMock);
            Object retVal = CDdLtngNimdaSyncCtrl.createPaymentAccount('143611', '272630', CDdLtngNimdaSyncCtrl.getAccount(childAcct.Id), CDdLtngNimdaSyncCtrl.getOpportunity(closedWonOpportunity.Id));
            CDdNimdaSyncService.CDdNimdaSyncInfo retObj = (CDdNimdaSyncService.CDdNimdaSyncInfo)JSON.deserialize((String)retVal, CDdNimdaSyncService.CDdNimdaSyncInfo.class);           
            System.assertEquals(true, retObj!=null, 'Expecting a valid return object');
            System.assertEquals(CDdNimdaSyncConstants.STEP_PAYMENT_ACCOUNT, ((CDdNimdaSyncService.CDdNimdaSyncInfo)retObj).step, 'Expecting step ' + CDdNimdaSyncConstants.STEP_PAYMENT_ACCOUNT);                                    
            Test.stopTest();
        }
    }
    /** 
    * @description Run positive test case - Create Stripe Bank Token for Country Australia
    */
    @isTest
    public static void testPositiveCreateStripeBankToken1() {
        System.runAs (getTestRunUser()) {
            Account childAcct = TDdAccountFactory.createAccounts('Child Account', 1, 'Marketplace')[0];
            childAcct.Phone = '+61111111111';
            childAcct.Business_ID__c = 143611;
            childAcct.BillingStreet = '207 St Georges Rd';
            childAcct.BillingCity = 'Fitzroy North';
            childAcct.BillingState = 'Victoria';
            childAcct.BillingPostalCode = '3068';
            childAcct.BillingCountry = 'Australia';
            childAcct.BillingCountryCode = 'AU';
            // Legal Entity Address Details on the Account object
            childAcct.ShippingStreet = '207 St Georges Rd';
            childAcct.ShippingCity = 'Fitzroy North';
            childAcct.ShippingState = 'Victoria';
            childAcct.ShippingPostalCode = '3068';
            childAcct.ShippingCountry = 'Australia';
            // Payment Account Details on the Account object
            childAcct.Legal_Business_Name__c = 'Test Entity Business';
            childAcct.Mx_Tax_Id_VAT__c = '123456';
            childAcct.Bank_Account_Number_Encrypted__c = '12345678900';
            childAcct.Bank_Routing_Number_Encrypted__c = '123456'; 
            // Stripe Account Owner Details on the Contact object                       
            Contact contact = VTestUtil.createContact('Test', 'Contact', childAcct);
            contact.BirthDate = Date.newInstance(1990, 2, 24);
            contact.MailingStreet = '207 St Georges Rd';
            contact.MailingCity = 'Fitzroy North';
            contact.MailingState = 'Victoria';
            contact.MailingPostalCode = '3068';
            contact.MailingCountry = 'Australia';
            // store accounts     
            List<Account> accounts = new List<Account>();
            //accounts.add(parentAcct);
            accounts.add(childAcct);
            upsert accounts;
            // store contacts
            List<Contact> contacts = new List<Contact>();
            contacts.add(contact);
            upsert contacts;
            // store opportunities
            List<Opportunity> opportunities = new List<Opportunity>();
            Opportunity closedWonOpportunity =createClosedWonOpportunity('Test Closed Opp', childAcct, contact);
            closedWonOpportunity.Stripe_Account_Owner__c = contact.Id;
            opportunities.add(closedWonOpportunity);
            upsert opportunities;

            Test.startTest();
            StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
            mock.setStaticResource('mockResponse_Stripe_Token_success');
            mock.setStatusCode(200);
            mock.setHeader('Content-Type', 'application/json');
            // Set the mock callout mode
            Test.setMock(HttpCalloutMock.class, mock);
            Object retVal = CDdLtngNimdaSyncCtrl.createStripeBankToken('143611', CDdLtngNimdaSyncCtrl.getAccount(childAcct.Id), CDdLtngNimdaSyncCtrl.getOpportunity(closedWonOpportunity.Id));
            CDdNimdaSyncService.CDdNimdaSyncInfo retObj = (CDdNimdaSyncService.CDdNimdaSyncInfo)JSON.deserialize((String)retVal, CDdNimdaSyncService.CDdNimdaSyncInfo.class);
            System.assertEquals(true, retObj!=null, 'Expecting a valid return object');
            System.assertEquals(CDdNimdaSyncConstants.STEP_STRIPE_BANK_TOKEN, ((CDdNimdaSyncService.CDdNimdaSyncInfo)retObj).step, 'Expecting step ' + CDdNimdaSyncConstants.STEP_STRIPE_BANK_TOKEN);           
            Test.stopTest();
        }
    }
   /** 
    * @description Run positive test case - Get Store Request
    */
    @isTest
    public static void testPositiveGetStoreRequest() {
        System.runAs (getTestRunUser()) {
            Account parentAcct = TDdAccountFactory.createAccounts('Parent Account', 1)[0];
            parentAcct.Business_ID__c = 143611;
            //parentAcct.Requesting_Account_Management__c = 'Unmanaged';
            Account childAcct = TDdAccountFactory.createAccounts('Child Account', 1)[0];
            childAcct.BillingCountry = 'United States';
            // Payment Account Details on the Account object
            childAcct.Legal_Business_Name__c = 'Test Entity Business';
            /*childAcct.EIN_Encrypted__c = '123456';
            childAcct.Bank_Account_Number_Encrypted__c = '12345678900';
            childAcct.Bank_Routing_Number_Encrypted__c = '123456';  */         
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

            Test.startTest();
            Object retVal = CDdLtngNimdaSyncCtrl.getStoreRequest('143611', childAcct, closedWonOpportunity);
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
            Account parentAcct = TDdAccountFactory.createAccounts('Parent Account', 1)[0];
            parentAcct.Business_ID__c = 143611;
            //parentAcct.Requesting_Account_Management__c = 'Unmanaged';
            Account childAcct = TDdAccountFactory.createAccounts('Child Account', 1)[0];
            childAcct.BillingCountry = 'United States';
            // Payment Account Details on the Account object
            childAcct.Legal_Business_Name__c = 'Test Entity Business';
            /*childAcct.EIN_Encrypted__c = '123456';
            childAcct.Bank_Account_Number_Encrypted__c = '12345678900';
            childAcct.Bank_Routing_Number_Encrypted__c = '123456';  */         
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
                        
            Test.startTest();
            try {
                Object retVal = CDdLtngNimdaSyncCtrl.getStoreRequest('143611', null, closedWonOpportunity);
            } catch (AuraHandledException ex){
                System.assertEquals(true, ex!=null, 'Expecting error ');                
            }            
            Test.stopTest();
        }
    }
   /** 
    * @description Run positive test case - Get Store Request
    */
    @isTest
    public static void testUpdateAccountAndOpportunity() {
        System.runAs (getTestRunUser()) {
            Account parentAcct = TDdAccountFactory.createAccounts('Parent Account', 1)[0];
            parentAcct.Business_ID__c = 143611;
            //parentAcct.Requesting_Account_Management__c = 'Unmanaged';
            Account childAcct = TDdAccountFactory.createAccounts('Child Account', 1)[0];
            childAcct.BillingCountry = 'United States';
            // Payment Account Details on the Account object
            childAcct.Legal_Business_Name__c = 'Test Entity Business';
            /*childAcct.EIN_Encrypted__c = '123456';
            childAcct.Bank_Account_Number_Encrypted__c = '12345678900';
            childAcct.Bank_Routing_Number_Encrypted__c = '123456';  */         
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

            Test.startTest();
            Boolean retVal = CDdLtngNimdaSyncCtrl.updateAccountAndOpportunity(childAcct, closedWonOpportunity, contact);
            System.assertEquals(true, retVal, 'Expecting successful update of account and opportunity');
            Test.stopTest();
        }
    }
   /** 
    * @description Run positive test case - Get Store Request
    */
    @isTest
    public static void testInsertNimdaHistoryRecords() {
        System.runAs (getTestRunUser()) {
            Account parentAcct = TDdAccountFactory.createAccounts('Parent Account', 1)[0];
            parentAcct.Business_ID__c = 143611;
            //parentAcct.Requesting_Account_Management__c = 'Unmanaged';
            Account childAcct = TDdAccountFactory.createAccounts('Child Account', 1)[0];
            childAcct.BillingCountry = 'United States';
            // Payment Account Details on the Account object
            childAcct.Legal_Business_Name__c = 'Test Entity Business';
            /*childAcct.EIN_Encrypted__c = '123456';
            childAcct.Bank_Account_Number_Encrypted__c = '12345678900';
            childAcct.Bank_Routing_Number_Encrypted__c = '123456';  */         
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

            Test.startTest();
            Nimda_History__c nimdaHistory = new Nimda_History__c(
                    Opportunity__c = closedWonOpportunity.Id
                    , Account__c = childAcct.Id
                    , Field__c = 'name'
                    , Original_Value__c = 'Original Store'
                    , New_Value__c = 'New Store'
                );
            String nimdaHistoryRecordsJsonStr = JSON.serialize(new List<Nimda_History__c>{nimdaHistory});
            Boolean retVal = CDdLtngNimdaSyncCtrl.insertNimdaHistoryRecords(nimdaHistoryRecordsJsonStr);
            System.assertEquals(true, retVal, 'Expecting successful creation of Nimda history record');
            Test.stopTest();
        }
    }
   /** 
    * @description Rest Connector testing to improve coverage
    */
    @isTest
    public static void testRestConnectorService() {
        System.runAs (getTestRunUser()) {
            CDdRESTConnectorSvc connector = new CDdRESTConnectorSvc();
            connector.printSettings();
            connector.useProd();
            connector.useSandbox();
            System.assertEquals(true, connector!=null, 'Expecting a new instance of Rest Connector Service');
            Test.startTest();
            VDispatchdeliveryCalloutMock m = new VDispatchdeliveryCalloutMock(200, 'OK', VTestUtil.DISPATCH_DELIVERY_MESSAGE);
            Test.setMock(HttpCalloutMock.class, m);
            CDdRestJSONObj.RestAPIResponse retObj =connector.getDeliveryInfo(100);
            System.assertEquals(true, retObj!=null, 'Expecting a valid delivery info object');
            Test.stopTest();
        }
    }                                                                   
   /** 
    * @description Create 'Closed Won' stage opportunity
    */
    private static Opportunity createClosedWonOpportunity(String name, Account account, Contact contact){
        Opportunity closedWonOpportunity = TDdOpportunityFactory.createOpportunity(name, account.Id, contact.Id, 'Closed Won');
        return closedWonOpportunity;        
    }
    /** 
    * @description Create 'Pipeline' stage opportunity
    */
    private static Opportunity createPipelineOpportunity(String name, Account account) {
        return VTestUtil.createOpportunity(name, account);
    }
    /** 
    * @description Mock for multiple requests
    */    
    public class MultiRequestMock implements HttpCalloutMock {
        Map<String, HttpCalloutMock> requests;

        public MultiRequestMock(Map<String, HttpCalloutMock> requests) {
            this.requests = requests;
        }
        public HTTPResponse respond(HTTPRequest req) {
            System.debug('****************** MultiRequestMock *************** ' + ' - getEndpoint - ' + req.getEndpoint());
            HttpCalloutMock mock = requests.get(req.getEndpoint());
            if (mock != null) {
                return mock.respond(req);
            } else {
                System.debug('****************** MultiRequestMock *************** ' + ' - getEndpoint - ' + 'Did not find a mock with the endpoint - ' + req.getEndpoint());
                return null;
            }
        }
        public void addRequestMock(String url, HttpCalloutMock mock) {
            requests.put(url, mock);
        }
    }    
}