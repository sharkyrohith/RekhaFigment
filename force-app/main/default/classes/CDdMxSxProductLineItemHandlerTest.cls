/********************************************************************************************************************
* @author Veera
* @date 07/2022
*
* @group Merchant Services
*
* @description Test CDdMxSx Product Line Item Handler
*
**************************************************************************************************************************************/
@isTest
public class CDdMxSxProductLineItemHandlerTest {

    private static vCS__c testSettings;
    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser33@doordash.com';
    public static final String TEST_OPPORTUNITY_NAME_FOR_CPQ = 'MxSx_Test_Opp_123';
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

            //Insert Milestone Templates
            CDdMilestoneTemplate.insertMilestoneTemplates();

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
            opp.StageName = CDdOpportunityConstants.OPPORTUNITY_STAGE_CLOSED_WON;
            opp.Menu_Setup_Method__c = 'Create New Menu(s) using Menu Source';
            opp.Region_Type__c = CDdMxSxConstants.OPPORTUNITY_LIVE_REGION;
            insert opp;

            List<Case> cases = TDdCaseFactory.createCases(1, account.Id, opp.Id, CDdSchemaUtils.CASE_RT.tabletRequestsId());
            for (Case cas : cases) {
                cas.Tablet_Shipment_Status__c = 'Shipped';
                cas.Request_Type__c = 'Ship to Merchant (New Tablet)';
                cas.Tablet_Ship_Date2__c = System.today().addDays(-1);
                cas.Tablet_Received_Date_2__c = System.today();
                cas.Tablet_Tracking_UPS__c = '123456789';
                cas.Tablet_Serial_Number__c = '123456789';
                cas.Return_Shipping_Address_State__c = 'Florida';
            }
            insert cases;
            Test.stopTest();
       }
    }

    @isTest
    static void testupdateOrderLineItemsOnStoreActivation(){
        System.runAs(getTestRunUser()){
            Opportunity oppty = getCpqOpportunity();

            PriceBook2 pricebook = new Pricebook2(Id = Test.getStandardPricebookId(), isActive = true);
            update pricebook;
            Product2 product1 = TDdCPQTestDataFactory.createProduct(false);
            product1.Family = CDdMxSxConstants.PRODUCT_FAMILIES_ADS_PROMOS[0];
            Product2 product2 = TDdCPQTestDataFactory.createProduct(false);
            product2.Family = CDdMxSxConstants.PRODUCT_FAMILIES_ADS_PROMOS[1];
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
            Case onboardingCase = [SELECT Id FROM Case WHERE Opportunity_Name__c = :oppty.Id AND RecordTypeId = :CDdSchemaUtils.CASE_RT.marketplaceOnboardingId() LIMIT 1][0];


            oppty.SBQQ__PrimaryQuote__c = quote.Id;
            oppty.StageName = 'Closed Won';
            Update oppty;

            Map<String, Milestone_Template__c> templateByNameMap = listToMap(CDdMilestoneSelector.templatesByParentTypeMap('Case').values(), 'Milestone_Type__c');
            List<Milestone__c> milestoneList = new List<Milestone__c>();
            Milestone__c asMileStone = new CDdMilestone().initializeMilestone(templateByNameMap.get('Activate Store'), 'Case__c', onboardingCase.Id);
            asMileStone.Type__c = 'Rep Activation';
            milestoneList.add(asMileStone);

            Milestone__c adsPromosMileStone = new CDdMilestone().initializeMilestone(templateByNameMap.get('Ads & Promos'), 'Case__c', onboardingCase.Id);
            milestoneList.add(adsPromosMileStone);
            insert milestoneList;

            onboardingCase.OwnerId = UserInfo.getUserId();
            onboardingCase.Stage__c = 'Ready for Activation';

            update onboardingCase;

            asMileStone.Status__c = new CDdMilestone().Complete;
            update asMileStone;
            Test.stopTest();

            List<OrderItem> OrderLineItems = [SELECT Id, Product2.Family, Promo_Start_Day__c,Promo_End_Day__c FROM OrderItem WHERE Order.OpportunityId =: oppty.Id];
            System.assertEquals(true, OrderLineItems.size() > 0);
            for(OrderItem orderLineItem : OrderLineItems){
                if(CDdMxSxConstants.PRODUCT_FAMILIES_ADS_PROMOS.contains(orderLineItem.Product2.Family)){
                    Date startdate = orderLineItem.Promo_Start_Day__c;
                    System.assertEquals(startdate.format(), orderLineItem.Promo_Start_Day__c.format());
                    System.assertEquals(startdate.addDays(30).format(), orderLineItem.Promo_End_Day__c.format());
                }
            }
        }
    }

    private static Opportunity getCpqOpportunity() {
        return [SELECT Id, AccountId, SBQQ__PrimaryQuote__c,CloseDate FROM Opportunity WHERE Name = :TEST_OPPORTUNITY_NAME_FOR_CPQ LIMIT 1];
    }

    private static Map<String, Milestone_Template__c> listToMap(List<Milestone_Template__c> sobjects, String keyField) {
        Map<String, Milestone_Template__c> sobjectMap = new Map<String, Milestone_Template__c>();
        for (Milestone_Template__c sobj : sobjects) {
            String key = (String) sobj.get(keyField);
            sobjectMap.put(key, sobj);
        }
        return sobjectMap;
    }
}