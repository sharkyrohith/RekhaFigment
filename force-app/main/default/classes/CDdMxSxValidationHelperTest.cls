/**
 * CDdMxSxValidationHelperTest
**/
@isTest
public class CDdMxSxValidationHelperTest {
    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    public static final String TEST_SSMO_DD_RUN_USERNAME = 'testssmo.runninguser@doordash.com';
    public static final String TEST_OPPORTUNITY_NAME_FOR_CPQ = 'MxSx_Test_Opp_123';
    public static final String TEST_SSMO_OPPORTUNITY_NAME_FOR_CPQ = 'MxSx_SSMO_Test_Opp';
    public static final String TEST_OPP_PACTSAFE_CONTRACT_TYPE = 'English Sign Up Sheet';
    public static final String TEST_SSMO_USER_NAME = 'Self-Serve Integration User';
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
        }
        return testRunUser;
    }
    /**
     * @description Prepare and return the test running SSMO user  
     */
    private static User getSSMOTestRunUser() {
        User ssmoTestRunUser = null;
        ssmoTestRunUser = TDdAccountFactory.createUsers(1, null, TEST_ROLE_ID)[0];
        ssmoTestRunUser.Username = TEST_SSMO_DD_RUN_USERNAME;
        ssmoTestRunUser.LastName = TEST_SSMO_USER_NAME;
        
        return ssmoTestRunUser;
    }
   /** 
    * @description Prepare test data
    */
    @TestSetup
    static void setup() {
        Account account ;
        Contact contact ;
        System.runAs(getTestRunUser()){

            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = getTestRunUser().Id);
            validation.Bypass_Opportunity_Validations__c = true;
            validation.Bypass_Account_Validations__c = true;
            insert validation;

            Test.startTest();
           
            Submarket__c submarket = TDdCPQTestDataFactory.createSubmarket('New York', 'NEW YORK', 10, null, true);
            RealZip__RealZips__c realZip = TDdCPQTestDataFactory.createRealZip(submarket, false);
            realZip.Alcohol_Eligibility__c = 'Pickup';
            insert realZip; 
            
            account = TDdAccountFactory.createAccounts('Account', 1)[0];
            account.RealZip__RealZip__c = realZip.Id;
            account.Business_ID__c = 1234567;
            insert account;
            
            CDdMxSxTestCPQSetup.insertCPQProducts();
            CDdMxSxTestCPQSetup.insertCPQPriceBookEntries();

            contact = TDdAccountFactory.createContacts(1, account.Id)[0];
            insert contact;
            
            Opportunity opp = TDdOpportunityFactory.createOpportunityByDevRT(TEST_OPPORTUNITY_NAME_FOR_CPQ, account.Id, contact.Id, 'Meeting Ran / Negotiated', 'ML_Inside_Sales');
            opp = updateOpportunityFieldsforClosedWon(opp);
            opp.Decision_maker__c = contact.Id ;
            opp.Stripe_Account_Owner__c = contact.Id;
            insert opp;  
            
            SBQQ__Quote__c quote = TDdCPQTestDataFactory.createQuote(opp, account, contact, false);
            quote.SBQQ__StartDate__c = Date.today().addDays(-30);
            quote.PactSafe_Contract_Type__c ='';   
            quote.SBQQ__Status__c = 'Contract Signed' ;
    
            insert quote;  
            
            opp.SBQQ__PrimaryQuote__c = quote.Id;
            update opp;            
            
            createProductDetail(opp.Id);

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
        System.runAs(getSSMOTestRunUser()){
            //Create SSMO Opportunity
            Opportunity ssmoOpp = TDdOpportunityFactory.createOpportunityByDevRT(TEST_SSMO_OPPORTUNITY_NAME_FOR_CPQ, account.Id, contact.Id, 'Meeting Ran / Negotiated', 'ML_Inside_Sales');
            ssmoOpp = updateOpportunityFieldsforClosedWon(ssmoOpp);
            ssmoOpp.Decision_maker__c = contact.Id ;
            ssmoOpp.Stripe_Account_Owner__c = contact.Id;
            insert ssmoOpp;  
            
            SBQQ__Quote__c ssmoQuote = TDdCPQTestDataFactory.createQuote(ssmoOpp, account, contact, false);
            ssmoQuote.SBQQ__StartDate__c = Date.today().addDays(-30);
            ssmoQuote.SBQQ__Status__c = 'Contract Signed' ;
            ssmoQuote.PactSafe_Contract_Type__c ='';       
            insert ssmoQuote;  
            
            ssmoOpp.SBQQ__PrimaryQuote__c = ssmoQuote.Id;
            update ssmoQuote;            
            
            SBQQ.TriggerControl.disable();
            CDdMxSxTestCPQSetup.insertQuoteLines(ssmoQuote);
            SBQQ.TriggerControl.enable();

            Order ssmoOrder = TDdCPQTestDataFactory.createOrder(account, ssmoOpp, ssmoQuote, false);
            ssmoOrder.EffectiveDate = Date.today();
            ssmoOrder.EndDate = null;
            insert ssmoOrder;
            CDdMxSxTestCPQSetup.insertOrderItems(ssmoOrder, ssmoQuote);
        }
   }
    /**
     * @description Test - Closed - Won Non SSMO Storefront Opportunity
     *                     With No ImplementationCall Event   
     */    
    @isTest
    public static void testNonSSMOOpportunityNoEvent() {
        System.runAs (getTestRunUser()) {
            Opportunity opportunity = getCpqOpportunity();
            Test.startTest();
            String exceptionMessage = '';
            try{
                opportunity.StageName = 'Closed Won';
                update opportunity ;
            }catch(Exception e){
                exceptionMessage = e.getMessage();
            }
            Test.stopTest();
            System.assert(TRUE, exceptionMessage.containsIgnoreCase(System.Label.MxSx_StoreFront_Opportunity_No_Storefront_Event_Error));
       }
    }
    /**
     * @description Test - Closed - Won Non SSMO Storefront Opportunity
     *                     With No Decision Maker   
     */    
    @isTest
    public static void testNonSSMOOpportunityNoDM() {
        System.runAs (getTestRunUser()) {
            Opportunity opportunity = getCpqOpportunity();
            Test.startTest();
            String exceptionMessage = '';
            try{
                opportunity.StageName = 'Closed Won';
                opportunity.Decision_maker__c = null;
                update opportunity ;
            }catch(Exception e){
                exceptionMessage = e.getMessage();
            }
            Test.stopTest();
            System.assert(TRUE, exceptionMessage.containsIgnoreCase(System.Label.MxSx_StoreFront_Opportunity_Decision_Maker_Error));
       }
    }
    /**
     * @description Test - Closed - Won Non SSMO Storefront Opportunity
     *                     With ImplementationCall Event
     */    
    @isTest
    public static void testNonSSMOOpportunityWithEvent() {
        System.runAs (getTestRunUser()) {
            String contactId = [Select Id from Contact limit 1].Id;  
            createEvent('Storefront Implementation Call', contactId, System.Now().addMinutes(15), System.Now().addMinutes(15), 'Meeting', true);
            Opportunity opportunity = getCpqOpportunity();
            Test.startTest();
            opportunity.StageName = 'Closed Won';
            opportunity.Storefront_Qualification_Complete__c = true;
            update opportunity ;
            Test.stopTest();
            opportunity = getCpqOpportunity();
            System.assertEquals(true, CDdMxSxConstants.OPPORTUNITY_STAGE_CLOSED_WON.equalsignoreCase(opportunity.StageName));
       }
    }
    /**
     * @description Test - Closed - Won SSMO Storefront Opportunity
     *                     With No ImplementationCall Event   
     */    
    @isTest
    public static void testSSMOOpportunity() {
        System.runAs (getTestRunUser()) {
            Opportunity opportunity = getSSMOOpportunity();
            Set<Id> opportunityIds = new Set<Id>{opportunity.Id};
            CDdMxSxOpportunityHelper opportunityHelper;
            opportunityHelper = new CDdMxSxOpportunityHelper(opportunityIds);
            System.assert(TRUE, opportunityHelper.isSelfServe(opportunity.Id));
            Test.startTest();
            opportunity.StageName = 'Closed Won';
            update opportunity ;
            Test.stopTest();
            opportunity = getSSMOOpportunity();
            System.assertEquals(true, CDdMxSxConstants.OPPORTUNITY_STAGE_CLOSED_WON.equalsignoreCase(opportunity.StageName));
        }
    }
    /**
     * @description Test - BZAP-12366 - Validate for Storefront (net-new pricing) Opportunities, whether the Qualification Questions are completed
     */    
    @isTest
    public static void testVerifyStorefrontOpportunityQualifyingQuestionsforClosedWon() {
        System.runAs (getTestRunUser()) {
            String contactId = [Select Id from Contact limit 1].Id;  
            createEvent('Storefront Implementation Call', contactId, System.Now().addMinutes(15), System.Now().addMinutes(15), 'Meeting', true);
            Opportunity opportunity = getCpqOpportunity();
            Test.startTest();
            String exceptionMessage = '';
            try{
                opportunity.StageName = 'Closed Won';
                update opportunity ;
            }catch(Exception e){
                exceptionMessage = e.getMessage();
            }
            Test.stopTest();
            System.assert(TRUE, exceptionMessage.containsIgnoreCase(System.Label.MxSx_StoreFront_Opportunity_Qualifying_Questions_Check_Error));            
       }
    }    
    /**
     * @description Create and return List of Events for the Decision maker
     */
    public static List<Event> createEvent(String name, String whoId, Datetime startTime, Datetime endTime, String etype, Boolean doInsert){
        List<Event> events = new List<Event>();
        Event e = new Event(Subject = name, WhoId = whoId, Type = etype, StartDateTime = startTime, EndDateTime = endTime);
        events.add(e);
        if(doInsert){
           insert events;
        }
        return events;
    } 
    /**
     * @description Return the test cpq opportunity record created in the setup method
     */      
    private static Opportunity getCpqOpportunity() {
        return [SELECT Id, AccountId, StageName, CreatedById, CreatedBy.Name, CreatedBy.LastName, SBQQ__PrimaryQuote__c FROM Opportunity WHERE Name = :TEST_OPPORTUNITY_NAME_FOR_CPQ LIMIT 1];
    }
    /**
     * @description Return the test SSMO opportunity record created in the setup method
     */      
    private static Opportunity getSSMOOpportunity() {
        return [SELECT Id, AccountId, StageName, CreatedById, CreatedBy.Name, CreatedBy.LastName, SBQQ__PrimaryQuote__c FROM Opportunity WHERE Name = :TEST_SSMO_OPPORTUNITY_NAME_FOR_CPQ LIMIT 1];
    }
   /**
     * @description Return the Opportunity record by populating the required fields for closed won
     */  
    private static Opportunity updateOpportunityFieldsforClosedWon(Opportunity opp){
                opp.Activate_Centrally_2__c = 'Yes';
                opp.Commission__c = 0.2;
                opp.Hours_of_Operation__c = 'test';
                opp.Legal_Entity__c = 'US';
                opp.Menu_Has_Been_Provided__c = true; // "Menu Isn't Blurry & Contains Pricing"
                opp.Menu_URL__c = 'https://test.doordas.com/menu_url';
                opp.Order_Protocol__c = 'POS and and Tablet (DoorDash Owns)';
                opp.Proposed_Date_of_Activation__c = System.today().addDays(20);
                opp.Proposed_Date_of_Menu__c = System.today().addDays(10);
                opp.Menu_to_be_completed_by__c = 'DoorDash Onboarding Team';
                opp.Menu_Setup_Method__c  = 'Create New Menu(s) using Menu Source';
                opp.Commission__c = 15;
                opp.In_App_Pickup_Commission__c = 15;
                opp.DashPass_Only_Commission__c = 15;
                opp.Referred_Delivery_Commission__c = 15;
                opp.Referred_Pickup_Commission__c = 15;
                opp.Weekly_Printer_Subscription_Fee__c = '$0';
                opp.Activation_Fee__c = '$0';
                opp.Weekly_Tablet_Subscription_Fee__c = '$3';
                opp.PactSafe_Contract_Type__c = TEST_OPP_PACTSAFE_CONTRACT_TYPE;
                return opp;
    }

    /**
        @author: Dan Thoreson
        @date: 17-Jan-2023
        @description: Initializes a default Product Detail for an applicable Opportunity
    **/
    private static Product_Detail__c createProductDetail(Id opportunityId) {
        Product_Detail__c storefrontDetails = new Product_Detail__c();
        storefrontDetails.RecordTypeId = CDdCaseMilestoneStorefrontOnboarding.PRODUCT_DETAILS_STOREFRONT_RT;
        storefrontDetails.Opportunity__c = opportunityId;
        storefrontDetails.Implementation_Type__c = CDdCaseMilestoneStorefrontOnboarding.GOOGLE_FOOD;
        insert storefrontDetails;

        return storefrontDetails;
    }
}