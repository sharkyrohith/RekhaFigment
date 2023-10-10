/********************************************************************************************************************
* @author Sriram
* @date 10/24/2022
*
* @group fflib
*
* @description Apex test class for OpportunitiesSelector
*
* In order to test some of the fflib related selector operations, you would need to perform dml operations 
* and test/validate the queries in the Selector Class
*
* In figment today, a lot of the complex operations reside in the trigger automation and platform events (asynchronous)
*
* INTERIM SOLUTION
* If you perform dml operations in figment, you will need to perform the following until the complex automation are migrated to fflib patterns
* - Prepare a test user that has sufficient permissions. This would allow you to bypass validations as well.
* - Introduce a setup method for preparation of data (Example for a Store Opportunity, you will need an Account, a Parent Account, Contact as a decision maker etc.)
* - Use test start/stop operations to
*   - allow for asynchronous operations to complete (Example - Case generation for Closed Won Opportunties)
*   - reset governor limits due to execution of complex automation
*
**************************************************************************************************************************************/
@isTest
public class OpportunitiesSelectorTest {
    public static final Id TEST_OPP_ROLE_ID;
    public static final String TEST_OPP_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    public static final String TEST_OPPORTUNITY_NAME = 'MxSx_Test_Opp_123';
    public static final String TEST_OPP_PACTSAFE_CONTRACT_TYPE = 'English Sign Up Sheet';
    static {
        TEST_OPP_ROLE_ID = [SELECT Id FROM UserRole WHERE DeveloperName = 'COO'].Id;
    }
    /**
     * @description Prepare and return the test running user
     */
    private static User getTestRunUserForOpportunitySelector() {
        User testRunUser = null;
        for (User u : [SELECT Id FROM User WHERE UserName = :TEST_OPP_DD_RUN_USERNAME]){
            testRunUser = u;
        }
        if (testRunUser == null){
            testRunUser = TDdAccountFactory.createUsers(1, null, TEST_OPP_ROLE_ID)[0];
            testRunUser.Username = TEST_OPP_DD_RUN_USERNAME;
        }
        return testRunUser;
    }
    /**
     *  @description Prepare test data
     */
    @TestSetup
    static void setup() {
        System.runAs(getTestRunUserForOpportunitySelector()){
            // setting bypass validations
            Validation_Bypass__c disableValidationForOppSelector = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
            disableValidationForOppSelector.Bypass_Opportunity_Validations__c = true;
            disableValidationForOppSelector.Bypass_Account_Validations__c = true;
            disableValidationForOppSelector.Bypass_Case_Validations__c = true;
            insert disableValidationForOppSelector;
            // starting the test transaction
            Test.startTest();
            PriceBook2 pricebookForOppSelector = new Pricebook2(Id = Test.getStandardPricebookId(), isActive = true);
            update pricebookForOppSelector;
            // inserting real zip record
            Submarket__c submarketForOppSelector = TDdCPQTestDataFactory.createSubmarket('New York', 'NEW YORK', 10, null, true);
            RealZip__RealZips__c realZipForOppSelector = TDdCPQTestDataFactory.createRealZip(submarketForOppSelector, false);
            realZipForOppSelector.Alcohol_Eligibility__c = 'Pickup';
            insert realZipForOppSelector; 
            // inserting account record
            Account accountForOppSelector = TDdAccountFactory.createAccounts('Account', 1)[0];
            accountForOppSelector.RealZip__RealZip__c = realZipForOppSelector.Id;
            accountForOppSelector.Business_ID__c = 1234567;
            insert accountForOppSelector;
            // insert parent account
            String parentAccountName = 'Test Parent Account';
            Account parentAccount = TDdAccountFactory.createAccounts(parentAccountName, 1, 'Parent Account')[0];
            parentAccount.BillingCountry = 'United States';
            parentAccount.Business_Id__c = 1224444;
            parentAccount.Deck_Rank__c = 'Jack';
            insert parentAccount; 
            // inserting contact record
            Contact contact = TDdAccountFactory.createContacts(1, accountForOppSelector.Id)[0];
            insert contact;
            // inserting opportunity record
            Opportunity opp = TDdOpportunityFactory.createOpportunityByDevRT(TEST_OPPORTUNITY_NAME, accountForOppSelector.Id, contact.Id, 'Closed Won', 'ML_Inside_Sales');
            opp.Commission__c = 15;
            opp.In_App_Pickup_Commission__c = 15;
            opp.DashPass_Only_Commission__c = 15;
            opp.Referred_Delivery_Commission__c = 15;
            opp.Referred_Pickup_Commission__c = 15;
            opp.Weekly_Printer_Subscription_Fee__c = '$0';
            opp.Activation_Fee__c = '$0';
            opp.Weekly_Tablet_Subscription_Fee__c = '$3';
            opp.PactSafe_Contract_Type__c = TEST_OPP_PACTSAFE_CONTRACT_TYPE;
            opp.StageName = 'Meeting Ran / Negotiated';
            insert opp;  
            // stopping the test transaction
            Test.stopTest();  
        }
    }
    @isTest
    public static void testWhenSelectedBOnboardingOpportunitiesWithLineItemsAndCasesThenItShouldReturnRecordsWithTheGivenIds() {
        System.runAs (getTestRunUserForOpportunitySelector()) {
            Test.startTest();
            Id testOpportunityId = null;
            for (Opportunity opportunity : [SELECT Id FROM Opportunity where Name = :TEST_OPPORTUNITY_NAME]){
                testOpportunityId = opportunity.Id;
            }
            System.assertEquals(true, testOpportunityId!=null); 
            TDdOpportunityLineItemFactory.createProducts();
            List<OpportunityLineItem> testOpportunityLineItems = TDdOpportunityLineItemFactory.createOpportunityProducts(testOpportunityId);
            insert testOpportunityLineItems;
            Opportunity testOpportunity = new Opportunity(Id = testOpportunityId, StageName = 'Closed Won');
            update testOpportunity;                     
            Test.stopTest(); 
            Map<Id, Opportunity> testRecords = new Map<Id, Opportunity>(new OpportunitiesSelector().selectOnboardingOpportunitiesWithLineItemsAndCases(new Set<Id>{testOpportunityId}));
            System.assert(!testRecords.isEmpty(), 'Expecting test record collection to be not empty'); 
            System.assert(testRecords.size() == 1, 'Expecting test record collection size to be 1'); 
            System.assert(testRecords.containsKey(testOpportunityId), 'Expecting test record collection to contain test Opportunity Id '); 
            System.assert(testRecords.get(testOpportunityId).OpportunityLineItems!=null && !testRecords.get(testOpportunityId).OpportunityLineItems.isEmpty(),
                                'Expecting not empty collection Opportunity Line Items for the test Opportunity');
            System.assert(testOpportunityLineItems.size() == testRecords.get(testOpportunityId).OpportunityLineItems.size(),
                                'Expecting Opportunity Line Item collection size to match with the total count of Opportunity Line Items inserted for the test opportunity in the database');
            Case testMarketplaceOnboardingCase = null;
            for (Case c : [ SELECT Id, RecordTypeId, AccountId, Opportunity_Name__c 
                            FROM Case 
                            WHERE Opportunity_Name__c = :testOpportunityId
                            AND RecordTypeId = :CDdSchemaUtils.CASE_RT.marketplaceOnboardingId()]){
                testMarketplaceOnboardingCase = c;                
            }
            System.assert(testMarketplaceOnboardingCase!=null, 'Expecting a Marketplace Onboarding Case created asynchronously for the closed won opportunity'); 
            System.assert(CDdSchemaUtils.CASE_RT.marketplaceOnboardingId().equals(testMarketplaceOnboardingCase.RecordTypeId), 
                                'Expecting Case to be of record type Marketplace Onboarding'); 
            System.assert(testRecords.get(testOpportunityId).Cases__r!=null && !testRecords.get(testOpportunityId).Cases__r.isEmpty(),
                        'Expecting a non-empty collection of Case records related to the test opportunity queried by the selector method');
            Map<Id, Case> testCaseRecords = new Map<Id, Case>(testRecords.get(testOpportunityId).Cases__r);
            System.assert(testCaseRecords.containsKey(testMarketplaceOnboardingCase.Id), 
                        'Expecting the Marketplace Onboarding Case to be present in the related Case records queried by the selector method for the test opportunity');
        }
    }
     /**
     *  @description Test method for opportunity selector method getOpportunitiesByAccountIds(). 
     */
    @isTest
    public static void testWhentheAccountIdsarePassedReturnTheOpportunities() {
        System.runAs (getTestRunUserForOpportunitySelector()) {
            Opportunity opp = getOpportunityByName(TEST_OPPORTUNITY_NAME);
            String accountId = opp.AccountId;
            List<Opportunity> testRecords = new List<Opportunity>(new OpportunitiesSelector().getOpportunitiesByAccountIds(new Set<Id>{accountId}));
            System.assert(!testRecords.isEmpty(), 'Expecting test record collection to be not empty'); 
            System.assert(testRecords.size() == 1, 'Expecting test record collection size to be 1');
        }
    }
     /**
     *  @description Test method for opportunity selector method searchOpportunitiesBysearchTermAndAccountIds(). 
     */
    @isTest
    public static void testWhenSearchTermAndAccountIdsPassedReturnOpportunities() {
        System.runAs (getTestRunUserForOpportunitySelector()) {
            Opportunity opp = getOpportunityByName(TEST_OPPORTUNITY_NAME);
            String accountId = opp.AccountId;
            String opportunityName = opp.Name;
            String oppId = opp.Id;
            Id [] fixedSearchResults= new Id[1];
            fixedSearchResults[0] = oppId;
            Test.setFixedSearchResults(fixedSearchResults);
            List<Opportunity> opps = new List<Opportunity>();
            List<List<sObject>> opportunitySearchResults = OpportunitiesSelector.newInstance().searchOpportunitiesBysearchTermAndAccountIds(opportunityName, new Set<Id>{accountId});
            opps = (Opportunity[])opportunitySearchResults[0];
            System.assert(!opps.isEmpty(), 'Expecting test record collection to be not empty'); 
            System.assert(opps.size() == 1, 'Expecting test record collection size to be 1');
            System.assert(opps[0].Name == TEST_OPPORTUNITY_NAME, 'Expecting opportunity with the name '+TEST_OPPORTUNITY_NAME);              
        }
    }
    /**
     *  @description Method returns the opportunities by Name. 
     */
    public static Opportunity getOpportunityByName(String oppName){
        return [SELECT Id,AccountId,Name FROM Opportunity WHERE Name = :oppName LIMIT 1];
    }
}