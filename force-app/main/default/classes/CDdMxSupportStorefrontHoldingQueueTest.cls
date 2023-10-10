@isTest
public class CDdMxSupportStorefrontHoldingQueueTest {
   
    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    public static final String TEST_OPPORTUNITY_NAME_FOR_CPQ = 'MxSx_Test_Opp_123';
    public static final String TEST_OPP_PACTSAFE_CONTRACT_TYPE = 'English Sign Up Sheet';    
    public static final String TEST_INSTANCE_NAME = 'CDdMxSupportStorefrontHoldingQueue';
    public static final String QUERY_LIMIT = '100';
    public static CDdMxSupportEventEnum STOREFRONT_HOLDING_QUEUE = CDdMxSupportEventEnum.STOREFRONT_HOLDING_QUEUE;
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
    @TestSetup
    static void setup() {
        System.runAs(getTestRunUser()){
            // Add mx support configuration
            Mx_Support_Event_Config__c eventConfig = new Mx_Support_Event_Config__c();
            eventConfig.Apex_Class__c = TEST_INSTANCE_NAME;
            eventConfig.Batch_Size__c = 1;
            eventConfig.Event_Name__c = STOREFRONT_HOLDING_QUEUE.name();
            eventConfig.Is_Active__c = true;
            eventConfig.Query_Last_N_Days__c = 10;
            eventConfig.Query_SObject_Type__c = 'Case';
            eventConfig.Sequence__c = 1;
            eventConfig.Query_Limit__c = Decimal.valueOf(QUERY_LIMIT);
            insert eventConfig;

            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
            validation.Bypass_Opportunity_Validations__c = true;
            validation.Bypass_Account_Validations__c = true;
            validation.Bypass_Case_Validations__c = true;
            insert validation;

            Test.startTest();
            PriceBook2 pricebook = new Pricebook2(Id = Test.getStandardPricebookId(), isActive = true);
            update pricebook;
    
            Submarket__c submarket = TDdCPQTestDataFactory.createSubmarket('New York', 'NEW YORK', 10, null, true);
            RealZip__RealZips__c realZip = TDdCPQTestDataFactory.createRealZip(submarket, false);
            realZip.Alcohol_Eligibility__c = 'Pickup';
            insert realZip; 
            
            Account account = TDdAccountFactory.createAccounts('Account', 1)[0];
            account.RealZip__RealZip__c = realZip.Id;
            account.Business_ID__c = 1234567;
            insert account;

            // insert parent account
            String parentAccountName = 'Test Parent Account';
            Account parentAccount = TDdAccountFactory.createAccounts(parentAccountName, 1, 'Parent Account')[0];
            parentAccount.BillingCountry = 'United States';
            parentAccount.Business_Id__c = 1224444;
            parentAccount.Deck_Rank__c = 'Jack';
            insert parentAccount; 
            
            Contact contact = TDdAccountFactory.createContacts(1, account.Id)[0];
            insert contact;
               
            CDdMxSxTestCPQSetup.insertCPQProducts();
            CDdMxSxTestCPQSetup.insertCPQPriceBookEntries();

            String contactId = contact.Id ;
            createEvent('Storefront Implementation Call', contactId, System.Now().addMinutes(15), System.Now().addMinutes(15), 'Meeting', true);

            Opportunity opp = TDdOpportunityFactory.createOpportunityByDevRT(TEST_OPPORTUNITY_NAME_FOR_CPQ, account.Id, contact.Id, 'Closed Won', 'ML_Inside_Sales');
            opp.Commission__c = 15;
            opp.In_App_Pickup_Commission__c = 15;
            opp.DashPass_Only_Commission__c = 15;
            opp.Referred_Delivery_Commission__c = 15;
            opp.Referred_Pickup_Commission__c = 15;
            opp.Weekly_Printer_Subscription_Fee__c = '$0';
            opp.Activation_Fee__c = '$0';
            opp.Weekly_Tablet_Subscription_Fee__c = '$3';
            opp.PactSafe_Contract_Type__c = TEST_OPP_PACTSAFE_CONTRACT_TYPE;
            insert opp;  
            
            SBQQ__Quote__c quote = TDdCPQTestDataFactory.createQuote(opp, account, contact, false);
            quote.SBQQ__StartDate__c = Date.today().addDays(-30);
            quote.PactSafe_Contract_Type__c ='';       
            insert quote;  
            
            opp.SBQQ__PrimaryQuote__c = quote.Id;
            update opp;            
            
            Test.stopTest();  

            SBQQ.TriggerControl.disable();
            CDdMxSxTestCPQSetup.insertQuoteLines(quote);
            SBQQ.TriggerControl.enable();

            Order order = TDdCPQTestDataFactory.createOrder(account, opp, quote, false);
            order.EffectiveDate = Date.today();
            order.EndDate = null;
            insert order;
            CDdMxSxTestCPQSetup.insertOrderItems(order, quote);            
        }
    }

    /** 
    * @description Code coverage for the CDdMxSupportStorefrontHoldingQueue class
    */
    @isTest
    static void testCDdMxSupportStorefrontHoldingQueue() {
        System.runAs (getTestRunUser()) {
            Opportunity opportunity = getCpqOpportunity();
            Set<Id> opportunityIds = new Set<Id>{opportunity.Id};
            CDdMxSxOpportunityHelper opportunityHelper;
            CDdMxSxParentAccountHelper parentAccountHelper;
            CDdMxSxEventHandler.handleEventsOpportunityClosedWon(opportunityIds);
            // Pre-event checks
            opportunityHelper = new CDdMxSxOpportunityHelper(opportunityIds);
            parentAccountHelper = new CDdMxSxParentAccountHelper(opportunityHelper.getParentAccountIds());
            System.assertEquals(true, opportunityHelper.hasParentAccountId(opportunity.Id));
            System.assertEquals(true, !opportunityHelper.getCases(opportunity.Id, CDdMxSxConstants.RECORD_TYPE_ID_CASE_STOREFRONT_ONBOARDING, null).isEmpty());
            System.assertEquals(true, parentAccountHelper.hasActiveStorefrontOnboardingCase(opportunityHelper.getParentAccountId(opportunity.Id), opportunityHelper.getCloseDate(opportunity.Id)));
            Id parentAccountId = opportunityHelper.getParentAccountId(opportunity.Id);
            System.assertEquals(true, parentAccountHelper.hasActiveStorefrontOnboardingCaseInHoldingQueue(parentAccountId, null));
            System.assertEquals(true, parentAccountHelper.hasInactiveStores(parentAccountId));
            // Update quote
            SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c WHERE Id = :opportunity.SBQQ__PrimaryQuote__c LIMIT 1];
            quote.SBQQ__Status__c = 'Approved';
            update quote;
            Test.startTest();
            parentAccountHelper = new CDdMxSxParentAccountHelper(opportunityHelper.getParentAccountIds());
            CDdMxSupportEventBatch supportBatch = new CDdMxSupportEventBatch(STOREFRONT_HOLDING_QUEUE);
            Database.executeBatch(supportBatch, CDdMxSupportEventConfig.getBatchSize(STOREFRONT_HOLDING_QUEUE));
            Test.stopTest();
            // Post-event checks
            parentAccountHelper = new CDdMxSxParentAccountHelper(opportunityHelper.getParentAccountIds());
            System.assertEquals(true, parentAccountHelper.hasActiveStorefrontOnboardingCase(parentAccountId, null));
            System.assertEquals(true, parentAccountHelper.hasActiveStorefrontOnboardingCaseInHoldingQueue(parentAccountId, null));  
        }
    }

    @isTest
    static void testConfigValues() {
        System.runAs(getTestRunUser()){
            Test.startTest();
            System.assertEquals(QUERY_LIMIT, CDdMxSupportStorefrontHoldingQueue.QUERY_LIMIT);
            Test.stopTest();
        }
    }

    /**
     * @description Create and return List of Events for the Decision maker
     */
    public static List<Event> createEvent(String name, String whoId, Datetime startTime, Datetime endTime, String etype, Boolean doInsert){
        List<Event> events = new List<Event>();
        Event e = new Event(Subject = name, WhoId = whoId, Type = etype, StartDateTime = startTime, EndDateTime = endTime);
        events.add(e);
        if(doInsert)
           insert events;
        return events;
    }   
    /**
     * @description Return the test cpq opportunity record created in the setup method
     */      
    private static Opportunity getCpqOpportunity() {
        return [SELECT Id, AccountId, SBQQ__PrimaryQuote__c FROM Opportunity WHERE Name = :TEST_OPPORTUNITY_NAME_FOR_CPQ LIMIT 1];
    }
    /**
     * @description Return the Order record created in the setup method
     */      
    private static Order getOrder(Id opportunityId) {
        return [SELECT Id, OpportunityId, AccountId FROM Order WHERE OpportunityId = :opportunityId LIMIT 1];
    }    
}