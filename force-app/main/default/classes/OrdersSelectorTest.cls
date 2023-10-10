/********************************************************************************************************************
* @author Sriram
* @date 10/24/2022
*
* @group fflib
*
* @description Apex test class for OrdersSelector
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
public class OrdersSelectorTest {
    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    public static final String TEST_OPPORTUNITY_NAME = 'MxSx_Test_Opp_123';
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
     *  @description Prepare test data
     */
    @TestSetup
    static void setup() {
        System.runAs(getTestRunUser()){
            // setting bypass validations
            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
            validation.Bypass_Opportunity_Validations__c = true;
            validation.Bypass_Account_Validations__c = true;
            validation.Bypass_Case_Validations__c = true;
            insert validation;
            // starting the test transaction
            Test.startTest();
            PriceBook2 pricebook = new Pricebook2(Id = Test.getStandardPricebookId(), isActive = true);
            update pricebook;
            // inserting real zip record
            Submarket__c submarket = TDdCPQTestDataFactory.createSubmarket('New York', 'NEW YORK', 10, null, true);
            RealZip__RealZips__c realZip = TDdCPQTestDataFactory.createRealZip(submarket, false);
            realZip.Alcohol_Eligibility__c = 'Pickup';
            insert realZip; 
            // inserting account record
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
            // inserting contact record
            Contact contact = TDdAccountFactory.createContacts(1, account.Id)[0];
            insert contact;
            // inserting cpq products       
            CDdMxSxTestCPQSetup.insertCPQProducts();
            CDdMxSxTestCPQSetup.insertCPQPriceBookEntries();
            // inserting opportunity record
            Opportunity opp = TDdOpportunityFactory.createOpportunityByDevRT(TEST_OPPORTUNITY_NAME, account.Id, contact.Id, 'Closed Won', 'ML_Inside_Sales');
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
            // inserting quote
            SBQQ__Quote__c quote = TDdCPQTestDataFactory.createQuote(opp, account, contact, false);
            quote.SBQQ__StartDate__c = Date.today().addDays(-30);
            quote.PactSafe_Contract_Type__c ='';       
            insert quote;  
            // updating opportunity
            opp.SBQQ__PrimaryQuote__c = quote.Id;
            update opp;            
            // stopping the test transaction
            Test.stopTest();  
            // disabling cpq triggers to allow for inserting quote lines
            SBQQ.TriggerControl.disable();
            CDdMxSxTestCPQSetup.insertQuoteLines(quote);
            SBQQ.TriggerControl.enable();
            // inserting order and order items
            Order order = TDdCPQTestDataFactory.createOrder(account, opp, quote, false);
            order.EffectiveDate = Date.today();
            order.EndDate = null;
            insert order;
            CDdMxSxTestCPQSetup.insertOrderItems(order, quote);
        }
    }
    @IsTest
    static void testWhenQueriesAreExecutedThenItShouldReturnRecordsFromTheOrderSObject() {
        SObjectType actualType = new OrdersSelector().getSObjectType();
        System.assertEquals(
            Order.SObjectType,
            actualType,
            'Received an unexpected SObject token.  Expecting Order.SObjectType and received: ' + actualType );
    }
    @IsTest
    static void testWhenQueriesAreExecutedThenItShouldReturnRecordsWithTheExpectedFields() {
        SObjectField[] expectedTokens = new SObjectField[]{
            Order.Id,
            Order.OpportunityId,
            Order.SBQQ__Quote__c
        };

        SObjectField[] actualTokens = new OrdersSelector().getSObjectFieldList();
        System.assertEquals(
            expectedTokens,
            actualTokens,
            'Received an unexpected list of SObjectField tokens.  Expected: ' + expectedTokens + ' Received: ' + actualTokens
        );
    }    
    @isTest
    public static void testWhenSelectedByIdThenItShouldReturnRecordsWithTheGivenIds() {
        System.runAs (getTestRunUser()) {
            // Given
            Id testOpportunityId = null;
            for (Opportunity opportunity : [SELECT Id FROM Opportunity where Name = :TEST_OPPORTUNITY_NAME]){
                testOpportunityId = opportunity.Id;
            }
            System.assert(testOpportunityId!=null);
            List<Order> testOrdersFromDB = new List<Order>([SELECT Id, OpportunityId, SBQQ__Quote__c FROM Order WHERE OpportunityId = :testOpportunityId]);
            System.assert(testOrdersFromDB!=null && !testOrdersFromDB.isEmpty());

            // Select
            Map<Id, Order> testOrdersFromSelector = new Map<Id, Order>(new OrdersSelector().selectById(new Set<Id>{testOrdersFromDB[0].Id}));

            //Assert
            System.assert(!testOrdersFromSelector.isEmpty()); 
            System.assert(testOrdersFromSelector.containsKey(testOrdersFromDB[0].Id));                  
        }
    }
    @isTest
    public static void testWhenSelectedByIdThenItShouldNotReturnRecordsOutsideOfTheGivenIds() {
        System.runAs (getTestRunUser()) {
            // Given
            Id testOpportunityId = null;
            for (Opportunity opportunity : [SELECT Id FROM Opportunity where Name = :TEST_OPPORTUNITY_NAME]){
                testOpportunityId = opportunity.Id;
            }
            System.assert(testOpportunityId!=null);
            List<Order> testOrdersFromDB = new List<Order>([SELECT Id, OpportunityId, SBQQ__Quote__c FROM Order WHERE OpportunityId = :testOpportunityId]);
            System.assert(testOrdersFromDB!=null && !testOrdersFromDB.isEmpty());

            // Select
            Map<Id, Order> testOrdersFromSelector = new Map<Id, Order>(new OrdersSelector().selectById(new Set<Id>{Fake.generateId( Order.class )}));

            //Assert
            System.assert(testOrdersFromSelector.isEmpty());                 
        }
    }    
    @isTest
    public static void testWhenSelectedOrderAndOrderItemsByOpportunityIdThenItShouldReturnRecordsWithTheGivenOpportunityIds() {
        System.runAs (getTestRunUser()) {
            Id testOpportunityId = null;
            for (Opportunity opportunity : [SELECT Id FROM Opportunity where Name = :TEST_OPPORTUNITY_NAME]){
                testOpportunityId = opportunity.Id;
            }
            System.assertEquals(true, testOpportunityId!=null);
            List<Order> testOrdersFromDB = new List<Order>();
            Map<Id, List<OrderItem>> testOrderItemsByOrderIdFromDB = new Map<Id, List<OrderItem>>();
            for (Order o : [    SELECT Id, OpportunityId, SBQQ__Quote__c,
                                (SELECT Id, OrderId, Quantity, SBQQ__OrderedQuantity__c,
                                SBQQ__QuoteLine__r.SBQQ__StartDate__c, SBQQ__QuoteLine__r.Trial_Start_Date__c, 
                                SBQQ__QuoteLine__r.SBQQ__Quote__r.Contract_Signed_Date__c, 
                                Product2Id, Product2.Id, Product2.Family, Product2.Name, Product2.Priority_for_Activation__c,
                                Delay_after_Activation_days__c,Length_of_Term__c
                                FROM OrderItems)
                FROM Order
                WHERE OpportunityId = :testOpportunityId]){
                testOrdersFromDB.add(o);
                testOrderItemsByOrderIdFromDB.put(o.Id, o.OrderItems);   
            }
            System.assert(testOrdersFromDB!=null && !testOrdersFromDB.isEmpty(), 'Expecting test order in the database for the test opportunity record');
            System.assert(testOrderItemsByOrderIdFromDB!=null && !testOrderItemsByOrderIdFromDB.isEmpty(),
                                'Expected a non-empty collection of Order Products to be found in the database for the Order associated with the test opportunity record');
            Map<Id, Order> testOrdersFromSelector = new Map<Id, Order>(new OrdersSelector().selectOrderAndOrderItemsByOpportunityId(new Set<Id>{testOpportunityId}));
            System.assert(!testOrdersFromSelector.isEmpty() && testOrdersFromSelector.size()==1, 'Expecting an Order to be retrieved by the selector for the test opportunity'); 
            System.assert(testOrdersFromSelector.containsKey(testOrdersFromDB[0].Id));
            System.assert(testOpportunityId.equals(testOrdersFromSelector.get(testOrdersFromDB[0].Id).OpportunityId),
                                'Expecting the test opportunity id to be found on the test Order record queried by the selector method');
            //Evaluate Order Items
            List<OrderItem> testOrderItemsFromDB = new List<OrderItem>(testOrderItemsByOrderIdFromDB.get(testOrdersFromDB[0].Id));
            System.assert(testOrderItemsFromDB!=null && !testOrderItemsFromDB.isEmpty(),
                                'Expecting a non-empty Collection of Order Products found in the database when queried for the Order associated with the test Opportunity');
            Map<Id, OrderItem> testOrderItemsFromSelector = new Map<Id, OrderItem>(testOrdersFromSelector.get(testOrdersFromDB[0].Id).OrderItems);
            System.assert(testOrderItemsFromSelector!=null && !testOrderItemsFromSelector.isEmpty(),
                                'Expecting a non-empty Collection of Order Products returned by the selector method along with the Order associated with the test Opportunity');
            System.assert(testOrderItemsFromDB.size() == testOrderItemsFromSelector.size(),
                                'Expecting the collection size to match between Order Products as queried from db and the Order Products returned by the selector method');             
        }  
    }
    @isTest
    public static void testWhenSelectedOrderAndOrderItemsByOpportunityIdThenItShouldNotReturnRecordsOutsideOfTheGivenIds() {
        System.runAs (getTestRunUser()) {
            // Given
            Id testOpportunityId = null;
            for (Opportunity opportunity : [SELECT Id FROM Opportunity where Name = :TEST_OPPORTUNITY_NAME]){
                testOpportunityId = opportunity.Id;
            }
            System.assert(testOpportunityId!=null);
            List<Order> testOrdersFromDB = new List<Order>([SELECT Id, OpportunityId, SBQQ__Quote__c FROM Order WHERE OpportunityId = :testOpportunityId]);
            System.assert(testOrdersFromDB!=null && !testOrdersFromDB.isEmpty());

            // Select
            Map<Id, Order> testOrdersFromSelector = new Map<Id, Order>(new OrdersSelector().selectOrderAndOrderItemsByOpportunityId(new Set<Id>{Fake.generateId( Opportunity.class )}));

            //Assert
            System.assert(testOrdersFromSelector.isEmpty());                 
        }
    }                  
}