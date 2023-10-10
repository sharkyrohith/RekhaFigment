/********************************************************************************************************************
* @author Lathika
* @date 02/2023
*
* @group Merchant Services
*
* @description: test class for CDdMxSupportTurboChargeCaviarCaseUpdate: to handle CAVIAR_TURBO_CHARGE_UPDATE events
* using 'Mx Support Event' service
*
**************************************************************************************************************************************/
@isTest
public class CDdMxSupportTurboChargeCaviarCaseTest {

    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    public static final String TEST_OPPORTUNITY_NAME_FOR_CPQ = 'MxSx_Test_Opp_123';
    public static final String TEST_INSTANCE_NAME = 'CDdMxSupportTurboChargeCaviarCaseUpdate';
    public static CDdMxSupportEventEnum testEvent1 = CDdMxSupportEventEnum.CAVIAR_TURBO_CHARGE_UPDATE;
    public static final String QUERY_LAST_N_DAYS = '10';
    private static vCS__c testSettings;

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
            validation.Bypass_Milestone_Validations__c  = true;
            insert validation;

            Support_Feature_Flag__c featureFlag = Support_Feature_Flag__c.getOrgDefaults();
            featureFlag.Enable_Qualtrics_Surveys__c = false;
            featureFlag.EnableReopen__c = true;
            featureFlag.EnableMXPAgentReopens__c = true;
            featureFlag.Enable_Tasks_on_Case_Feed__c = true;
            featureFlag.MXP_Support_E2C_Linking__c = true;
            featureFlag.Enable_Sendbird_API_Callouts__c = true;
            upsert featureFlag;

            Feature_Flags__c ftrFlag = Feature_Flags__c.getOrgDefaults();
            ftrFlag.Enable_Case_Trigger_Optimization__c = true;
            insert ftrFlag;

            testSettings = VTestUtil.createVeltigSettings();
            insert testSettings ;
            Submarket__c submarket = TDdCPQTestDataFactory.createSubmarket('New York', 'NEW YORK', 10, null, true);
            RealZip__RealZips__c realZip = TDdCPQTestDataFactory.createRealZip(submarket, false);
            realZip.Alcohol_Eligibility__c = 'Pickup';
            insert realZip;
            Account account = TDdAccountFactory.createAccounts('Account', 1)[0];
            account.RealZip__RealZip__c = realZip.Id;
            account.Business_ID__c = 1234567;
            insert account;

            Contact contact = TDdAccountFactory.createContacts(1, account.Id)[0];
            insert contact;

            Test.startTest();
            Opportunity opp = TDdOpportunityFactory.createOpportunityByDevRT(TEST_OPPORTUNITY_NAME_FOR_CPQ, account.Id, contact.Id, 'Open', 'ML_Inside_Sales');
            opp.Commission__c = 15;
            opp.In_App_Pickup_Commission__c = 15;
            opp.DashPass_Only_Commission__c = 15;
            opp.Referred_Delivery_Commission__c = 15;
            opp.Referred_Pickup_Commission__c = 15;
            opp.Weekly_Printer_Subscription_Fee__c = '$0';
            opp.Activation_Fee__c = '$0';
            opp.Weekly_Tablet_Subscription_Fee__c = '$3';
            opp.Order_Protocol__c = 'Tablet (DoorDash Owns)';
            opp.Decision_Maker__c = contact.id;
            opp.Platform__c = CDdMxSxConstants.OPPORTUNITY_PLATFORM_CAVIAR_AND_DOORDASH;
            opp.StageName = CDdOpportunityConstants.OPPORTUNITY_STAGE_CLOSED_WON;
            opp.Menu_Setup_Method__c = 'Create New Menu(s) using Menu Source';
            opp.Region_Type__c = CDdMxSxConstants.OPPORTUNITY_LIVE_REGION;
            insert opp;
            Mx_Support_Event_Config__c eventConfig = new Mx_Support_Event_Config__c();
            eventConfig.Apex_Class__c = TEST_INSTANCE_NAME;
            eventConfig.Batch_Size__c = 1;
            eventConfig.Event_Name__c = testEvent1.name();
            eventConfig.Is_Active__c = true;
            eventConfig.Query_Last_N_Days__c = Decimal.valueOf(QUERY_LAST_N_DAYS);
            eventConfig.Query_SObject_Type__c = 'Case';
            eventConfig.Sequence__c = 1;
            insert eventConfig;
            Test.stopTest();

        }
    }

    /**
     * @description: Code coverage for CDdMxSupportTurboChargeCaviarCaseUpdate class
     */
    @isTest
    static void testUpdateCaviarOnboardingOwnerAndStatusWhenPxPhandOffDateisReached() {
        System.runAs(getTestRunUser()){
            Opportunity oppty = getCpqOpportunity();

            PriceBook2 pricebook = new Pricebook2(Id = Test.getStandardPricebookId(), isActive = true);
            update pricebook;
            Product2 product1 = TDdCPQTestDataFactory.createProduct(false);
            product1.Family = CDdMxSxConstants.PRODUCT_FAMILIES_ADS_PROMOS[0];
            product1.DD_Custom_ID__c = 'TEST-01';
            Product2 product2 = TDdCPQTestDataFactory.createProduct(false);
            product2.Family = CDdMxSxConstants.PRODUCT_FAMILIES_ADS_PROMOS[1];
            product2.DD_Custom_ID__c = 'TEST-02';
            product1.Create_Post_Sale_Activation_Case__c = true;
            List<Product2> products = new List<Product2>{product1, product2};
            insert products;
            PricebookEntry pbe1 = TDdCPQTestDataFactory.createPriceBookEntry(product1, 'USD', false);
            PricebookEntry pbe2 = TDdCPQTestDataFactory.createPriceBookEntry(product2, 'USD', false);
            List<PricebookEntry> pbes = new List<PricebookEntry>{pbe1,pbe2};
            insert pbes;

            SBQQ.TriggerControl.disable();
            SBQQ__Quote__c quote = TDdCPQTestDataFactory.createQuote(oppty, new Account(Id=oppty.accountId), null, false);
            quote.SBQQ__StartDate__c = Date.today().addDays(-30);
            quote.PactSafe_Contract_Type__c = '';
            insert quote;
            SBQQ__QuoteLine__c quoteLine1 = TDdCPQTestDataFactory.createQuoteLine(product1, quote, false);
            SBQQ__QuoteLine__c quoteLine2 = TDdCPQTestDataFactory.createQuoteLine(product2, quote, false);
            quoteLine1.SBQQ__PriceBookEntryId__c = pbe1.Id;
            quoteLine2.SBQQ__PriceBookEntryId__c = pbe2.Id;
            List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>{quoteLine1, quoteLine2};
            insert quoteLines;
            quoteLine2.SBQQ__RequiredBy__c = quoteLine1.Id;
            update quoteLine2;
            Order order = TDdCPQTestDataFactory.createOrder(new Account(Id=oppty.accountId), oppty, quote, false);
            order.EffectiveDate = Date.today();
            order.EndDate = null;
            insert order;
            OrderItem orderProduct1 = TDdCPQTestDataFactory.createOrderItem(order, quoteLine1, pbe1.Id, false);
            OrderItem orderProduct2 = TDdCPQTestDataFactory.createOrderItem(order, quoteLine2, pbe2.Id, false);
            orderProduct1.Length_of_Term__c = '30';
            orderProduct1.Delay_after_Activation_days__c = '7';
            orderProduct2.Length_of_Term__c = '30';
            orderProduct2.Delay_after_Activation_days__c = '7';
            List<OrderItem> orderProducts = new List<OrderItem>{orderProduct1,orderProduct2};

            insert orderProducts;
            orderProduct2.SBQQ__RequiredBy__c = orderProduct1.Id;
            update orderProduct2;
            SBQQ.TriggerControl.enable();

            Test.startTest();

            oppty.SBQQ__PrimaryQuote__c = quote.Id;
            oppty.StageName = 'Closed Won';
            Update oppty;
            Case caviarOnboardingCase = [SELECT Id FROM Case WHERE Opportunity_Name__c = :oppty.Id AND RecordTypeId = :CDdSchemaUtils.CASE_RT.caviarOnboardingId() LIMIT 1][0];
            caviarOnboardingCase.Activation_Date__c = System.today();
            caviarOnboardingCase.MxP_Handoff_Date__c = System.today();
            update caviarOnboardingCase;
            CDdMxSupportEventBatch supportBatch = new CDdMxSupportEventBatch(testEvent1);
            Database.executeBatch(supportBatch, CDdMxSupportEventConfig.getBatchSize(testEvent1));
            Test.stopTest();
            Case caviarOnboardingCaseFromDB = [SELECT Id, OwnerId, Status FROM Case WHERE Opportunity_Name__c = :oppty.Id AND RecordTypeId = :CDdSchemaUtils.CASE_RT.caviarOnboardingId() LIMIT 1][0];
            System.assertEquals(CDdMxSxConstants.QUEUE_ID_ONBOARDING_ADS_PROMO, caviarOnboardingCaseFromDB.OwnerId);
            System.assertEquals(CDdMxSxConstants.CASE_STATUS_ONBOARDING_ADS_AND_PROMO, caviarOnboardingCaseFromDB.Status);


    }
}
private static Opportunity getCpqOpportunity() {
    return [SELECT Id, AccountId, SBQQ__PrimaryQuote__c,CloseDate FROM Opportunity WHERE Name = :TEST_OPPORTUNITY_NAME_FOR_CPQ LIMIT 1];
}

}