/********************************************************************************************************************
* @author Sriram
* @date 11/08/2021
*
* @group Merchant Services
*
* @description Apex test class for handling Merchant Services events          
* 
**************************************************************************************************************************************/
@isTest
public class CDdMxSxEventTest {
    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    public static final String TEST_OPPORTUNITY_NAME_FOR_CPQ = 'MxSx_Test_Opp_123';
    public static final String TEST_OPP_PACTSAFE_CONTRACT_TYPE = 'English Sign Up Sheet';
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
     * @description Test - Create Storefront Onboarding Case
     */    
    @isTest
    public static void testCreateStorefrontOnboardingCase() {
        System.runAs (getTestRunUser()) {
            Opportunity opportunity = getCpqOpportunity();
            Order order = getOrder(opportunity.Id);
            OrderItem orderItem = CDdMxSxTestCPQSetup.getStorefrontPackageOrderItem(order.Id); 
            Set<Id> opportunityIds = new Set<Id>{opportunity.Id};
            CDdMxSxOpportunityHelper opportunityHelper;
            CDdMxSxParentAccountHelper parentAccountHelper;
            // Pre-event checks
            opportunityHelper = new CDdMxSxOpportunityHelper(opportunityIds);
            System.assertEquals(true, opportunityHelper.isClosedWon(opportunity.Id));
            System.assertEquals(true, opportunityHelper.getStoreAccountId(opportunity.Id)!=null);
            System.assertEquals(true, opportunityHelper.hasCPQProducts(opportunity.Id));
            System.assertEquals(true, opportunityHelper.getCPQStorefrontPackage(opportunity.Id)!=null);
            System.assertEquals(false, opportunityHelper.hasLegacyProducts(opportunity.Id));
            System.assertEquals(true, opportunityHelper.getLegacyStorefrontPackage(opportunity.Id)==null);
            System.assertEquals(true, opportunityHelper.hasStorefrontPricing(opportunity.Id));
            System.assertEquals(true, opportunityHelper.hasNetNewStorefrontPricing(opportunity.Id));
            // BZAP-13225 - No parent account id will be available as the Opp is created as Closed Won without Storefront pricing 
            //System.assertEquals(true, opportunityHelper.hasParentAccountId(opportunity.Id));  // Because the opp trigger is responsible to create the parent account if a business exists on the store acount
            System.assertEquals(orderItem.Id, opportunityHelper.getCPQStorefrontPackage(opportunity.Id).Id);                         
            Test.startTest();
            CDdMxSxEventPublisher.publishEventsOpportunityClosedWon(opportunityIds); 
            Test.stopTest();
            // Post-event checks
            opportunityHelper = new CDdMxSxOpportunityHelper(opportunityIds);
            parentAccountHelper = new CDdMxSxParentAccountHelper(opportunityHelper.getParentAccountIds());
            System.assertEquals(true, opportunityHelper.hasParentAccountId(opportunity.Id));
            System.assertEquals(true, !opportunityHelper.getCases(opportunity.Id, CDdMxSxConstants.RECORD_TYPE_ID_CASE_STOREFRONT_ONBOARDING, null).isEmpty());
            System.assertEquals(true, parentAccountHelper.hasActiveStorefrontOnboardingCase(opportunityHelper.getParentAccountId(opportunity.Id), opportunityHelper.getCloseDate(opportunity.Id)));
            Id parentAccountId = opportunityHelper.getParentAccountId(opportunity.Id);
            System.assertEquals(true, parentAccountHelper.hasActiveStorefrontOnboardingCaseInHoldingQueue(parentAccountId, null));
            System.assertEquals(true, parentAccountHelper.hasInactiveStores(parentAccountId));
            Case storefrontOnboardingCase = opportunityHelper.getCases(opportunity.Id, CDdMxSxConstants.RECORD_TYPE_ID_CASE_STOREFRONT_ONBOARDING, null).get(0);
            Case storefrontOnboardingCaseFromDB = [SELECT Id, RecordTypeId, OwnerId, Date_Time_Case_Became_Workable__c FROM Case WHERE Id = :storefrontOnboardingCase.Id LIMIT 1];
            System.assertEquals(CDdMxSxConstants.QUEUE_ID_STOREFRONT_CASE_HOLDING_QUEUE, storefrontOnboardingCaseFromDB.OwnerId);
            System.assertEquals(null, storefrontOnboardingCaseFromDB.Date_Time_Case_Became_Workable__c);                                
        }
    }
    /**
     * @description Test - Create Storefront Onboarding Case
     */    
    @isTest
    public static void testCreatePostSaleActivationCase() {
        System.runAs (getTestRunUser()) {
            Opportunity opportunity = getCpqOpportunity();
            Set<Id> opportunityIds = new Set<Id>{opportunity.Id};
            CDdMxSxOpportunityHelper opportunityHelper;
            CDdMxSxParentAccountHelper parentAccountHelper;
            // Pre-event checks
            opportunityHelper = new CDdMxSxOpportunityHelper(opportunityIds);
            System.assertEquals(true, opportunityHelper.isClosedWon(opportunity.Id));
            System.assertEquals(true, opportunityHelper.getStoreAccountId(opportunity.Id)!=null);
            System.assertEquals(true, opportunityHelper.hasCPQProducts(opportunity.Id));
            System.assertEquals(true, opportunityHelper.getCPQStorefrontPackage(opportunity.Id)!=null);
            System.assertEquals(false, opportunityHelper.hasLegacyProducts(opportunity.Id));
            System.assertEquals(true, opportunityHelper.getLegacyStorefrontPackage(opportunity.Id)==null);
            System.assertEquals(true, opportunityHelper.hasStorefrontPricing(opportunity.Id));
            System.assertEquals(true, opportunityHelper.hasNetNewStorefrontPricing(opportunity.Id));
            // BZAP-13225 - No parent account id will be available as the Opp is created as Closed Won without Storefront pricing 
            //System.assertEquals(true, opportunityHelper.hasParentAccountId(opportunity.Id));  // Because the opp trigger is responsible to create the parent account if a business exists on the store acount                         
            Test.startTest();
            // Update the storefront package quantity to reflect renegotiation pricing
            OrderItem storefrontPackage = opportunityHelper.getCPQStorefrontPackage(opportunity.Id);
            System.assertEquals(true, storefrontPackage!=null);
            SBQQ.TriggerControl.disable();
            storefrontPackage.SBQQ__QuotedQuantity__c = 0;
            storefrontPackage.SBQQ__OrderedQuantity__c = 0;
            update storefrontPackage;
            SBQQ.TriggerControl.enable();
            CDdMxSxEventPublisher.publishEventsOpportunityClosedWon(opportunityIds);
            Test.getEventBus().deliver();
            // Post-event checks
            opportunityHelper = new CDdMxSxOpportunityHelper(opportunityIds);
            System.assertEquals(true, opportunityHelper.hasRenegotiatedStorefrontPricing(opportunity.Id));
            System.assertEquals(true, opportunityHelper.hasPostSalesActivationCaseForStorefrontBundle(opportunity.Id));
            testDmlLogErrors(opportunity.Id);
            // check for error entry - begin
            Apex_Log__c errorLog1 = null;
            for (Apex_Log__c l : [SELECT Id, Object__c, Reference_Id__c, Operation__c,  Log__c FROM Apex_Log__c WHERE Reference_Id__c = :opportunity.Id]){
                errorLog1 = l;
            }
            System.assertEquals(true, errorLog1 != null); 
            // check for error entry - end            
            Database.executebatch(new CDdMxSxBatchEventExceptionHandler(), 10);            
            Test.stopTest();
            // check for error entry - begin
            Apex_Log__c errorLog2 = null;
            for (Apex_Log__c l : [SELECT Id, Object__c, Reference_Id__c, Operation__c,  Log__c FROM Apex_Log__c WHERE Reference_Id__c = :opportunity.Id]){
                errorLog2 = l;
            }
            System.assertEquals(true, errorLog2 == null); 
            // check for error entry - end                        
        }
    }    
    /**
     * @description Test - Update Storefront Onboarding Case to active queue
     */    
    @isTest
    public static void testUpdateStorefrontOnboardingCaseToActiveQueue() {
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
            // Update store Account
            Account storeAccount = [SELECT Id, Is_Partner__c, Currently_Active__c FROM Account WHERE Id = :opportunity.AccountId LIMIT 1];
            storeAccount.Is_Partner__c = 'Yes';
            storeAccount.Currently_Active__c = 'Yes';
            update storeAccount;
            Test.startTest();
            parentAccountHelper = new CDdMxSxParentAccountHelper(opportunityHelper.getParentAccountIds());
            System.assertEquals(true, !parentAccountHelper.hasInactiveStores(parentAccountId));     
            CDdMxSxEventPublisher.publishEventsStoreActive(new Set<Id>{parentAccountId}); 
            Test.stopTest();
            // Post-event checks
            parentAccountHelper = new CDdMxSxParentAccountHelper(opportunityHelper.getParentAccountIds());
            System.assertEquals(true, parentAccountHelper.hasActiveStorefrontOnboardingCase(parentAccountId, null));
            System.assertEquals(true, !parentAccountHelper.hasActiveStorefrontOnboardingCaseInHoldingQueue(parentAccountId, null));
            Case storefrontOnboardingCase = parentAccountHelper.getActiveStorefrontOnboardingCase(parentAccountId, null);
            Case storefrontOnboardingCaseFromDB = [SELECT Id, RecordTypeId, OwnerId, Date_Time_Case_Became_Workable__c FROM Case WHERE Id = :storefrontOnboardingCase.Id LIMIT 1];
            System.assertNotEquals(CDdMxSxConstants.QUEUE_ID_STOREFRONT_CASE_HOLDING_QUEUE, storefrontOnboardingCaseFromDB.OwnerId);            
            System.assertEquals(true, storefrontOnboardingCaseFromDB.Date_Time_Case_Became_Workable__c!=null);     
        }
    }
    /**
     * @description Test - Opportunity related Case Updates
     */    
    @isTest
    public static void testOpportunityRelatedCaseUpdates() {
        User opportunityUpdateTestUser = TDdAccountFactory.createUsers(1, null, TEST_ROLE_ID)[0];
        opportunityUpdateTestUser.Username = 'opportunityUpdateTestUser@doordash.com';
        insert opportunityUpdateTestUser;        
        System.runAs (getTestRunUser()) {
            Opportunity opportunity = getCpqOpportunity();
            Set<Id> opportunityIds = new Set<Id>{opportunity.Id};
            CDdMxSxOpportunityHelper opportunityHelper;
            CDdMxSxEventHandler.handleEventsOpportunityClosedWon(opportunityIds);
            // Pre-event checks
            opportunityHelper = new CDdMxSxOpportunityHelper(opportunityIds);
            System.assertEquals(true, !opportunityHelper.getCases(opportunity.Id, CDdMxSxConstants.RECORD_TYPE_ID_CASE_STOREFRONT_ONBOARDING, null).isEmpty());
            Test.startTest();
            Opportunity oppToUpdate = new Opportunity(Id = opportunity.Id, OwnerId = opportunityUpdateTestUser.Id, Pickup_Inflation_Opp__c = 'Yes & Not POS Blocked');
            update oppToUpdate;
            Test.stopTest();
            // Post-event checks
            opportunityHelper = new CDdMxSxOpportunityHelper(opportunityIds);
            Map<Id, List<Case>> casesForOpportunities = CDdMxSxCaseHelper.getCasesForOpportunities(opportunityIds);
            System.assertEquals(true, !casesForOpportunities.isEmpty());
            System.assertEquals(true, !casesForOpportunities.get(opportunity.Id).isEmpty());
            System.assertEquals(opportunityUpdateTestUser.Id, casesForOpportunities.get(opportunity.Id)[0].Op_Owner__c);
        }
    }    
    /**
     * @description Test MxSx Batch Event Scheduler for retrying errors
     */    
    @isTest
    public static void testMxSxBatchEventSchedule() {
        System.runAs (getTestRunUser()) {
            Opportunity opportunity = getCpqOpportunity();
            Set<Id> opportunityIds = new Set<Id>{opportunity.Id};
            CDdMxSxOpportunityHelper opportunityHelper;
            CDdMxSxParentAccountHelper parentAccountHelper;
            // Pre-event checks
            opportunityHelper = new CDdMxSxOpportunityHelper(opportunityIds);
            System.assertEquals(true, opportunityHelper.isClosedWon(opportunity.Id));
            System.assertEquals(true, opportunityHelper.getStoreAccountId(opportunity.Id)!=null);
            System.assertEquals(true, opportunityHelper.hasCPQProducts(opportunity.Id));
            System.assertEquals(true, opportunityHelper.getCPQStorefrontPackage(opportunity.Id)!=null);
            System.assertEquals(false, opportunityHelper.hasLegacyProducts(opportunity.Id));
            System.assertEquals(true, opportunityHelper.getLegacyStorefrontPackage(opportunity.Id)==null);
            System.assertEquals(true, opportunityHelper.hasStorefrontPricing(opportunity.Id));
            System.assertEquals(true, opportunityHelper.hasNetNewStorefrontPricing(opportunity.Id));
            // BZAP-13225 - No parent account id will be available as the Opp is created as Closed Won without Storefront pricing 
            //System.assertEquals(true, opportunityHelper.hasParentAccountId(opportunity.Id));  // Because the opp trigger is responsible to create the parent account if a business exists on the store acount                         
            Test.startTest();
            // Update the storefront package quantity to reflect renegotiation pricing
            OrderItem storefrontPackage = opportunityHelper.getCPQStorefrontPackage(opportunity.Id);
            System.assertEquals(true, storefrontPackage!=null);
            SBQQ.TriggerControl.disable();
            storefrontPackage.SBQQ__QuotedQuantity__c = 0;
            storefrontPackage.SBQQ__OrderedQuantity__c = 0;
            update storefrontPackage;
            SBQQ.TriggerControl.enable();
            CDdMxSxEventPublisher.publishEventsOpportunityClosedWon(opportunityIds);
            Test.getEventBus().deliver();
            // Post-event checks
            opportunityHelper = new CDdMxSxOpportunityHelper(opportunityIds);
            System.assertEquals(true, opportunityHelper.hasRenegotiatedStorefrontPricing(opportunity.Id));
            System.assertEquals(true, opportunityHelper.hasPostSalesActivationCaseForStorefrontBundle(opportunity.Id));
            testDmlLogErrors(opportunity.Id);
            // check for error entry - begin
            Apex_Log__c errorLog1 = null;
            for (Apex_Log__c l : [SELECT Id, Object__c, Reference_Id__c, Operation__c,  Log__c FROM Apex_Log__c WHERE Reference_Id__c = :opportunity.Id]){
                errorLog1 = l;
            }
            System.assertEquals(true, errorLog1 != null); 
            // check for error entry - end            
            new CDdMxSxBatchEventExceptionSched().execute(null);                 
            Test.stopTest();
            // check for error entry - begin
            Apex_Log__c errorLog2 = null;
            for (Apex_Log__c l : [SELECT Id, Object__c, Reference_Id__c, Operation__c,  Log__c FROM Apex_Log__c WHERE Reference_Id__c = :opportunity.Id]){
                errorLog2 = l;
            }
            System.assertEquals(true, errorLog2 == null); 
            // check for error entry - end                        
        }
    }     
    /**
     * @description Test CDdMxSxException for dml log errors
     */     
    private static void testDmlLogErrors(Id opportunityId){
        Set<Id> opportunityIds = new Set<Id>{opportunityId};
        CDdMxSxOpportunityHelper opportunityHelper = new CDdMxSxOpportunityHelper(opportunityIds);
        // Test event log for error
        List<Case> postSaleActivationCases = opportunityHelper.getCases(opportunityId, CDdMxSxConstants.RECORD_TYPE_ID_CASE_POST_SALE_ACTIVATIONS, null);
        Product2 storefrontProduct = opportunityHelper.getStorefrontPackage(opportunityId);
        //set invalid - it should be Order Item record id       
        postSaleActivationCases[0].Order_Product__c = storefrontProduct.Id; 
        //expecting errors to be logged
        List<Database.SaveResult> sResults = Database.update(postSaleActivationCases, false);
        List<String> errorMessages = new List<String>();
        errorMessages = CDdErrorUtilities.processSaveResults(sResults, errorMessages); 
        CDdMxSxException.logDmlErrors(CDdMxSxException.DML_OPERATION_UPDATE, 'CDdMxSxOpportunityCaseHelper', 'createPosActivationCases', String.valueOf(CDdMxSxConstants.MXSX_EVENT.OPPORTUNITY_CLOSED_WON), LoggingLevel.ERROR, CDdMxSxConstants.SOBJECT_TYPE_OPPORTUNITY, 'Opportunity_Name__c', errorMessages, postSaleActivationCases);
        Apex_Log__c errorLog = [SELECT Id, Object__c, Reference_Id__c, Operation__c,  Log__c FROM Apex_Log__c WHERE Reference_Id__c = :opportunityId LIMIT 1];
        System.assertEquals(true, errorLog!=null);                               
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
    /**
    * @description Test - Do not Update Storefront Onboarding Case to active queue if the store account is reparented after the Storefront onboarding case is created
    */   
   @isTest
   public static void testNOTUpdateStorefrontOnboardingCaseToActiveQueueNoStoreAccountsUnderParentAccount() {
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
           // reparenting the store Account
           Account parentAccountToReparent = [SELECT Id, Is_Partner__c, Currently_Active__c FROM Account WHERE Business_Id__c = 1224444];
           Account storeAccountFromDB = [SELECT Id, Is_Partner__c, Currently_Active__c FROM Account WHERE Id = :opportunity.AccountId LIMIT 1];
           storeAccountFromDB.ParentId = parentAccountToReparent.id;
           update storeAccountFromDB;
           Test.startTest();
           //Publish the store active event on the original parent account
           CDdMxSxEventPublisher.publishEventsStoreActive(new Set<Id>{parentAccountId});
           Test.stopTest();
           // Post-event checks
           // the store accounts for original parent account , should be zero..
           parentAccountHelper = new CDdMxSxParentAccountHelper(new Set<Id>{parentAccountId});
           System.assertEquals(false, parentAccountHelper.hasStores(parentAccountId));

           parentAccountHelper = new CDdMxSxParentAccountHelper(opportunityHelper.getParentAccountIds());
           // reparented acc does not have storefront onBoarding case
           System.assertEquals(false, parentAccountHelper.hasActiveStorefrontOnboardingCase(parentAccountToReparent.Id, null));
           System.assertEquals(false, parentAccountHelper.hasActiveStorefrontOnboardingCaseInHoldingQueue(parentAccountToReparent.Id, null));

           // case under the original parent account//parentAccountId should be still be still under the holding queue
           Case storefrontOnboardingCase = parentAccountHelper.getActiveStorefrontOnboardingCase(parentAccountId, null);
           Case storefrontOnboardingCaseFromDB = [SELECT Id, RecordTypeId, OwnerId, Date_Time_Case_Became_Workable__c FROM Case WHERE Id = :storefrontOnboardingCase.Id LIMIT 1];
           System.assertEquals(CDdMxSxConstants.QUEUE_ID_STOREFRONT_CASE_HOLDING_QUEUE, storefrontOnboardingCaseFromDB.OwnerId);        
       }
   }                
}