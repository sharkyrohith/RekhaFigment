/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 12/29/2020
*
* @group Nimda
*
* @description Purpose is to test the Nimda Step Enforcer Helper class.
* There are certain data points in Salesforce that influence whether a Nimda Step should be performed within MuleSoft.
* Examples of Nimda Step and the corresponding data points in Salesforce
* To execute - Nimda Step : Create User
*   Portal Username on the Account should be blank or null 
* To execute - Nimda Step : Payment Account
*   Payment Account on the Account should be blank or null 
*   Stripe Account on the Opportunity should be blank or null
**************************************************************************************************************************************/
@isTest
public class CDdNimdaEnforceStepHelperTest {
    // sample test data related variables
    private static String SAMPLE_PARENT_ACCOUNT_RECORD = 'Sample_Parent_Account_Record';
    private static String SAMPLE_ACCOUNT_RECORD = 'Sample_Account_Record';
    private static String SAMPLE_ACCOUNT_WITHOUT_PARENT_ACCOUNT_RECORD = 'Sample_Account_Without_Parent_Account_Record';
    private static String SAMPLE_OPPORTUNITY_RECORD_0 = 'Sample_Opportunity_Record_0';
    private static String SAMPLE_OPPORTUNITY_RECORD_1 = 'Sample_Opportunity_Record_1';
    // test user related variables    
    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    public static final Id SYSTEM_ADMIN_PROFILE_ID;
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
    @testSetup 
    static void setup() {
        System.runAs (getTestRunUser()) {
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
    @isTest
    static void testFullOnboardingCreate(){
        System.runAs(getTestRunUser()){
            Map<String, SObject> data = setupData();
            // This is the opportunity associated to an Account that does not have a Parent account
            Opportunity sampleOpportunity = (Opportunity)data.get(SAMPLE_OPPORTUNITY_RECORD_1);            
            Test.startTest();
            CDdNimdaEnforceStepHelper helper = new CDdNimdaEnforceStepHelper(sampleOpportunity.Id, CDdNimdaSyncConstants.FULL_ONBOARDING_CREATE);
            Opportunity opportunityToProcess = new Opportunity(Id = sampleOpportunity.Id);
            List<SObject> sObjs = helper.prepareSObjectsForOnboarding(opportunityToProcess);
            System.assertEquals(true, !sObjs.isEmpty(), 'Expecting a non-empty return object');
            Test.stopTest();     
        }        
    }    
    @isTest
    static void testFullOnboardingUpdate(){
        System.runAs(getTestRunUser()){
            Map<String, SObject> data = setupData();
            // This is the opportunity associated to an Account that has a Parent account with null business id
            Opportunity sampleOpportunity = (Opportunity)data.get(SAMPLE_OPPORTUNITY_RECORD_0);            
            Test.startTest();
            CDdNimdaEnforceStepHelper helper = new CDdNimdaEnforceStepHelper(sampleOpportunity.Id, CDdNimdaSyncConstants.FULL_ONBOARDING_UPDATE);
            Opportunity opportunityToProcess = new Opportunity(Id = sampleOpportunity.Id);
            List<SObject> sObjs = helper.prepareSObjectsForOnboarding(opportunityToProcess);
            System.assertEquals(true, !sObjs.isEmpty(), 'Expecting a non-empty return object');            
            Test.stopTest();     
        }        
    }         
   /** 
    * @description Set up account, contact and opportunity
    */
    private static Map<String, SObject> setupData(){
        Account parentAcct = TDdAccountFactory.createAccounts('Parent Account', 1)[0];
        parentAcct.Business_ID__c = null;
        //parentAcct.Requesting_Account_Management__c = 'Unmanaged';
        List<Account> childAccounts = TDdAccountFactory.createAccounts('Child Account', 2);
        childAccounts[0].BillingCountry = 'United States';
        childAccounts[0].Legal_Business_Name__c = 'Test Entity Business 0';
        childAccounts[0].Restaurant_Id__c = '12345';
        childAccounts[0].Payment_Account_ID__c = '123456';
        // Child Account 1 does not have a restaurant id and will not have a parent account
        childAccounts[1].BillingCountry = 'United States';
        childAccounts[1].Legal_Business_Name__c = 'Test Entity Business 0';
        childAccounts[1].Payment_Account_ID__c = '123467';
        
        Contact contact0 = VTestUtil.createContact('Test0', 'Contact0', childAccounts[0]);
        Contact contact1 = VTestUtil.createContact('Test1', 'Contact1', childAccounts[1]);
        // store accounts     
        List<Account> accounts = new List<Account>();
        accounts.add(parentAcct);
        accounts.addAll(childAccounts);
        upsert accounts;
        // store contacts
        List<Contact> contacts = new List<Contact>();
        contacts.add(contact0);
        contacts.add(contact1);
        upsert contacts;
        // update child account
        childAccounts[0].ParentId = parentAcct.Id;
        upsert childAccounts[0];           
        // store opportunities
        List<Opportunity> opportunities = new List<Opportunity>();
        Opportunity closedWonOpportunity0 =createClosedWonOpportunity('Test Closed Opp 0', childAccounts[0], contacts[0]);
        closedWonOpportunity0.Stripe_Account__c = 'acct_1234sdfasder';
        opportunities.add(closedWonOpportunity0);
        Opportunity closedWonOpportunity1 =createClosedWonOpportunity('Test Closed Opp 1', childAccounts[1], contacts[1]);
        closedWonOpportunity1.Stripe_Account__c = 'acct_4567sdfaszxr';
        opportunities.add(closedWonOpportunity1);        
        upsert opportunities;
        return new Map<String, SObject>{
            SAMPLE_ACCOUNT_RECORD => childAccounts[0],
            SAMPLE_ACCOUNT_WITHOUT_PARENT_ACCOUNT_RECORD => childAccounts[1],
            SAMPLE_OPPORTUNITY_RECORD_0 => closedWonOpportunity0,
            SAMPLE_OPPORTUNITY_RECORD_1 => closedWonOpportunity1
        };        
    }                  
   /** 
    * @description Create 'Closed Won' stage opportunity
    */
    private static Opportunity createClosedWonOpportunity(String name, Account account, Contact contact){
        Opportunity closedWonOpportunity = TDdOpportunityFactory.createOpportunity(name, account.Id, contact.Id, 'Closed Won');
        return closedWonOpportunity;        
    }                
}