/********************************************************************************************************************
* @author Sriram
* @date 04/10/2022
*
* @group Merchant Services
*
* @description Test Merchant Order functionality
*
**************************************************************************************************************************************/
@isTest
public class CDdMxOrderTest {
    /**
     * Begin - Test class to execute if one of these classes is updated
     */
    private static List<System.Type> CLASS_REFERENCE = new List<System.Type>{
        CDdMxOrderAccountHelper.class,
        CDdMxOrderBatch.class,
        CDdMxOrderBatchConfig.class,
        CDdMxOrderBatchEnum.class,
        CDdMxOrderBatchScheduler.class,
        CDdMxOrderEventConfig.class,
        CDdMxOrderEventEnum.class,
        CDdMxOrderEventEnumHelper.class,
        CDdMxOrderEventHandler.class,
        CDdMxOrderEventHelper.class,
        CDdMxOrderEventPublisher.class,
        CDdMxOrderEventTriggerHandler.class,
        CDdMxOrderItemTriggerHandler.class,
        CDdMxOrderItemTriggerHelper.class,
        CDdMxOrderMappingHandlerCaseToMxOrder.class,
        CDdMxOrderMappingHandlerInterface.class,
        CDdMxOrderMappingHandlerMxOrderToCase.class,
        CDdMxOrderMxSxEventHandler.class,
        CDdMxOrderProcessController.class,
        CDdMxOrderProcessor.class,
        CDdMxOrderQueueTriggerHandler.class,
        CDdMxOrderQueueTriggerHelper.class,
        CDdMxOrderShipmentService.class,
        CDdMxOrderTriggerHandler.class,
        CDdMxOrderTriggerHelper.class,
        CDdMxOrderValidator.class,
        CDdMxSxConfigHelper.class,
        CDdMxSxConstants.class,
        CDdMxSxEventHandler.class,
        CDdMxSxEventPublisher.class,
        CDdMxSxEventTriggerHandler.class,
        CDdMxSxTriggerHelper.class
    };
    /**
     * End - Test class to execute if one of these classes is updated
     */
    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    public static final String TEST_OPPORTUNITY_NAME_FOR_CPQ = 'MxSx_Test_Opp_123';
    public static final String TEST_OPP_PACTSAFE_CONTRACT_TYPE = 'English Sign Up Sheet';
    public static final Id RECORD_TYPE_ID_CASE_TABLET_REQUESTS = CDdSchemaUtils.CASE_RT.tabletRequestsId();
    public static String TEST_MX_ORDER_REQUEST_TYPE = 'Ship to Merchant (New Tablet)';
    public static String TEST_MX_ORDER_REQUEST_COUNTRY_CODE = 'US';
    public static String TEST_MX_ORDER_ID = '21234sdasewsd';
    public static String TEST_SHIPPING_TRACKING_NUMBER = '12321234xhdfg';
    public static String TEST_IDENTIFIER_TABLET = 'IMEI-TB-0001';
    public static String TEST_IDENTIFIER_PRINTER = 'IMEI-PR-0001';
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

            vCS__c testSettings;
            testSettings = VTestUtil.createVeltigSettings();
            testSettings.CaseTrigger__c = true;
            insert testSettings;

            Feature_Flags__c ftrFlag = Feature_Flags__c.getOrgDefaults();
            ftrFlag.Enable_CPU_Time_Check__c = true;
            ftrFlag.Enable_Debug_Logs__c = true;
            insert ftrFlag;

            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
            validation.Bypass_Opportunity_Validations__c = true;
            validation.Bypass_Account_Validations__c = true;
            validation.Bypass_Case_Validations__c = true;
            insert validation;

            CDdMilestoneTemplate.insertMilestoneTemplates();

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
            account.Deck_Rank__c = 'Queen';
            account.Restaurant_Id__c = '123456';
            account.iPad_Username__c = '12345678';
            account.iPad_Password__c = '12345678';
            account.Language__c = 'English';
            insert account;

            Contact contact = TDdAccountFactory.createContacts(1, account.Id)[0];
            insert contact;
            List<Mx_Product__c> mxProducts = createMxProducts();
            createMxOrderRequest(TEST_MX_ORDER_REQUEST_TYPE, TEST_MX_ORDER_REQUEST_COUNTRY_CODE, mxProducts);

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
            opp.Delivery_Inflation_Opp__c = 'Yes & POS Blocked';
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
     * @description Test Generate Mx Order Event
     */
    @isTest
    public static void testGenerateMxOrderEvent() {
        System.runAs (getTestRunUser()) {
            Opportunity opportunity = getCpqOpportunity();
            Case tabletRequestCase = getTableRequestCase(opportunity.Id);
            System.assertEquals(true, tabletRequestCase!=null, 'Expecting a tablet request case record');
            Mx_Order__c mxOrder = [SELECT Id, Vendor__c, Mx_Order_Request__c, (select id from Mx_Order_Items__r) FROM Mx_Order__c WHERE Case__c = :tabletRequestCase.Id LIMIT 1];
            System.assertEquals(true, mxOrder.Id != null, 'Expecting a Mx Order to be generated/created' );
            //only pull English language products not the spanich language products.
            System.assertEquals(3, mxOrder.Mx_Order_Items__r.size(), 'Expecting a Mx Order to be generated/created' );
            System.assertEquals('Social Mobile', mxOrder.Vendor__c, 'Expecting the vendor value - ' + 'Social Mobile' );
            Mx_Order_Request__c mxOrderRequestFromDB = getMxOrderRequest();
            System.assertEquals(mxOrderRequestFromDB.Id, mxOrder.Mx_Order_Request__c, 'Expecting the Mx Order Request value - ' + mxOrderRequestFromDB.Id );
            Test.startTest();
            Case tbCase = new Case(Id = tabletRequestCase.Id, Status= 'Approved', Return_Shipping_Address_Suite_Apt_etc__c = 'XXXXYYYY', Language__c = 'Spanish');
            update tbCase;
            Test.stopTest();
        }
    }
    /**
     * @description Test - Test Update Non Queued Mx Order for Case Update
     */
    @isTest
    public static void testUpdateNonQueuedMxOrderForCaseUpdate() {
        System.runAs (getTestRunUser()) {
            Opportunity opportunity = getCpqOpportunity();
            Case tabletRequestCase = getTableRequestCase(opportunity.Id);
            System.assertEquals(true, tabletRequestCase!=null, 'Expecting a tablet request case record');
            Mx_Order__c mxOrder = [SELECT Id, Vendor__c, Mx_Order_Request__c FROM Mx_Order__c WHERE Case__c = :tabletRequestCase.Id LIMIT 1];
            System.assertEquals(true, mxOrder.Id != null, 'Expecting a Mx Order to be generated/created' );
            System.assertEquals('Social Mobile', mxOrder.Vendor__c, 'Expecting the vendor value - ' + 'Social Mobile' );
            Mx_Order_Request__c mxOrderRequestFromDB = getMxOrderRequest();
            System.assertEquals(mxOrderRequestFromDB.Id, mxOrder.Mx_Order_Request__c, 'Expecting the Mx Order Request value - ' + mxOrderRequestFromDB.Id );
            Test.startTest();
            Case tbCase = new Case(Id = tabletRequestCase.Id, Return_Shipping_Address_Suite_Apt_etc__c = 'XXXXYYYY', Language__c = 'Spanish');
            update tbCase;
            Test.stopTest();
            Mx_Order__c mxOrderFromDB = [SELECT Id, Address_Line2__c, Language__c FROM Mx_Order__c WHERE Case__c = :tabletRequestCase.Id LIMIT 1];
            System.assertEquals(true, mxOrderFromDB != null, 'Expecting a Mx Order ');
            System.assertEquals('XXXXYYYY', mxOrderFromDB.Address_Line2__c, 'Expecting a Mx Order Address Line 2 - ' + 'XXXXYYYY');
            System.assertEquals('Spanish', mxOrderFromDB.Language__c, 'Expecting a Mx Order Language - ' + 'Spanish');
            Mx_Order_Item__c mxOrderItemFromDB = [SELECT Id, Mx_Order__c, Mx_Product__r.Language__c FROM Mx_Order_Item__c WHERE Mx_Order__c = :mxOrderFromDB.Id AND Mx_Product__r.Language__c = 'Spanish' LIMIT 1];
            System.assertEquals(true, mxOrderItemFromDB != null, 'Expecting a Mx Order Item for Language - ' + 'Spanish');
        }
    }
    /**
     * @description Test Case Update when Mx Order has received an Order Id with status as 'new'
     */
    @isTest
    public static void testUpdateCaseMxOrderStatusNew() {
        System.runAs (getTestRunUser()) {
            Opportunity opportunity = getCpqOpportunity();
            Case tabletRequestCase = getTableRequestCase(opportunity.Id);
            System.assertEquals(true, tabletRequestCase!=null, 'Expecting a tablet request case record');
            Mx_Order__c mxOrder = [SELECT Id, Vendor__c, Mx_Order_Request__c FROM Mx_Order__c WHERE Case__c = :tabletRequestCase.Id LIMIT 1];
            System.assertEquals(true, mxOrder.Id != null, 'Expecting a Mx Order to be generated/created' );
            System.assertEquals('Social Mobile', mxOrder.Vendor__c, 'Expecting the vendor value - ' + 'Social Mobile' );
            Mx_Order_Request__c mxOrderRequestFromDB = getMxOrderRequest();
            System.assertEquals(mxOrderRequestFromDB.Id, mxOrder.Mx_Order_Request__c, 'Expecting the Mx Order Request value - ' + mxOrderRequestFromDB.Id );
            Test.startTest();
            Mx_Order__c mxOrderToUpdate = new Mx_Order__c(Id = mxOrder.Id, Order_Id__c = '1234567', Order_Status__c = 'new', Order_Status_Last_Modified_Date__c = System.now());
            update mxOrderToUpdate;
            Test.getEventBus().deliver();
            Test.stopTest();
            Case caseFromDB = [SELECT Id, Status FROM Case WHERE Id = :tabletRequestCase.Id LIMIT 1];
            System.assertEquals(true, caseFromDB != null, 'Expecting a Case record ');
            System.assertEquals('Approved', caseFromDB.Status, 'Expecting Case status ' + 'Approved');
        }
    }

    /**
     * @description Test for Case with Request Type  'Email to Merchant (Return Label Only)'
     */
    @isTest
    public static void testForCaseOfRequestTypeCIMaintenance() {
        System.runAs (getTestRunUser()) {
            Opportunity opportunity = getCpqOpportunity();
            Case tabletRequestCase = getTableRequestCase(opportunity.Id);
            System.assertEquals(true, tabletRequestCase!=null, 'Expecting a tablet request case record');
            Mx_Order__c mxOrder = [SELECT Id, Vendor__c, Mx_Order_Request__c FROM Mx_Order__c WHERE Case__c = :tabletRequestCase.Id LIMIT 1];
            System.assertEquals(true, mxOrder.Id != null, 'Expecting a Mx Order to be generated/created' );
            System.assertEquals('Social Mobile', mxOrder.Vendor__c, 'Expecting the vendor value - ' + 'Social Mobile' );
            Mx_Order_Request__c mxOrderRequestFromDB = getMxOrderRequest();
            System.assertEquals(mxOrderRequestFromDB.Id, mxOrder.Mx_Order_Request__c, 'Expecting the Mx Order Request value - ' + mxOrderRequestFromDB.Id );
            // Update the Case Request Type to CI Maintenance
            String requestType = null;
            for (String r : CDdMxSxConstants.REQUEST_TYPES_CI_MAINTENANCE){
                requestType = r;
            }
            tabletRequestCase.Request_Type__c = requestType;
            update tabletRequestCase;
            Test.startTest();
            // Set status on Mx Order to New
            update new Mx_Order__c(Id = mxOrder.Id, Order_Status__c = CDdMxSxConstants.MX_ORDER_STATUS_NEW);
            Test.stopTest();
            Mx_Order__c mxOrderFromDB = [SELECT Id, Order_Id__c FROM Mx_Order__c WHERE Id = :mxOrder.Id LIMIT 1];
            System.assertEquals(true, mxOrderFromDB != null, 'Expecting a Mx Order record ');
            System.assertEquals(true, mxOrderFromDB.Order_Id__c != null, 'Expecting a random Mx Order Id');
        }
    }
    /**
     * @description Test - Configured Mx Order for Case Update
     */
    @isTest
    public static void testUpdateCaseMxOrderStatusConfigured() {
        System.runAs (getTestRunUser()) {
            Opportunity opportunity = getCpqOpportunity();
            Case tabletRequestCase = getTableRequestCase(opportunity.Id);
            System.assertEquals(true, tabletRequestCase!=null, 'Expecting a tablet request case record');
            Mx_Order__c mxOrder = [SELECT Id, Vendor__c, Mx_Order_Request__c FROM Mx_Order__c WHERE Case__c = :tabletRequestCase.Id LIMIT 1];
            System.assertEquals(true, mxOrder.Id != null, 'Expecting a Mx Order to be generated/created' );
            System.assertEquals('Social Mobile', mxOrder.Vendor__c, 'Expecting the vendor value - ' + 'Social Mobile' );
            Mx_Order_Request__c mxOrderRequestFromDB = getMxOrderRequest();
            System.assertEquals(mxOrderRequestFromDB.Id, mxOrder.Mx_Order_Request__c, 'Expecting the Mx Order Request value - ' + mxOrderRequestFromDB.Id );
            Test.startTest();
            Mx_Order__c mxOrderConfigured = new Mx_Order__c(Id = mxOrder.Id, Order_Id__c = '1234567', Order_Status__c = 'configured', Order_Status_Last_Modified_Date__c = System.now());
            update mxOrderConfigured;
            Test.stopTest();
            Case caseFromDB = [SELECT Id, Status FROM Case WHERE Id = :tabletRequestCase.Id LIMIT 1];
            System.assertEquals(true, caseFromDB != null, 'Expecting a Case record ');
            System.assertEquals('In Progress', caseFromDB.Status, 'Expecting Case status ' + 'In Progress');
        }
    }
    /**
     * @description Test - Shipped Mx Order for Case Update
     */
    @isTest
    public static void testUpdateCaseMxOrderStatusShipped() {
        System.runAs (getTestRunUser()) {
            Opportunity opportunity = getCpqOpportunity();
            Case tabletRequestCase = getTableRequestCase(opportunity.Id);
            System.assertEquals(true, tabletRequestCase!=null, 'Expecting a tablet request case record');
            Mx_Order__c mxOrder = [SELECT Id, Vendor__c, Mx_Order_Request__c FROM Mx_Order__c WHERE Case__c = :tabletRequestCase.Id LIMIT 1];
            System.assertEquals(true, mxOrder.Id != null, 'Expecting a Mx Order to be generated/created' );
            System.assertEquals('Social Mobile', mxOrder.Vendor__c, 'Expecting the vendor value - ' + 'Social Mobile' );
            Mx_Order_Request__c mxOrderRequestFromDB = getMxOrderRequest();
            System.assertEquals(mxOrderRequestFromDB.Id, mxOrder.Mx_Order_Request__c, 'Expecting the Mx Order Request value - ' + mxOrderRequestFromDB.Id );
            Test.startTest();
            Mx_Order__c mxOrderShipped = new Mx_Order__c(Id = mxOrder.Id,
                                                            Order_Id__c = TEST_MX_ORDER_ID,
                                                            Order_Status__c = CDdMxSxConstants.MX_ORDER_STATUS_SHIPPED,
                                                            Order_Status_Last_Modified_Date__c = System.now(),
                                                            Shipping_Carrier__c = CDdMxSxConstants.MX_SHIPPING_CARRIER_FEDEX,
                                                            Shipping_Tracking_Number__c = TEST_SHIPPING_TRACKING_NUMBER);
            update mxOrderShipped;
            Test.stopTest();
            Case caseFromDB = [SELECT Id, Status, Tablet_Tracking_FedEx__c, Tablet_Ship_Date2__c FROM Case WHERE Id = :tabletRequestCase.Id LIMIT 1];
            System.assertEquals(true, caseFromDB != null, 'Expecting a Case record ');
            System.assertEquals('Shipped', caseFromDB.Status, 'Expecting Case status ' + 'Shipped');
            System.assertEquals(TEST_SHIPPING_TRACKING_NUMBER, caseFromDB.Tablet_Tracking_FedEx__c, 'Expecting FedEx Tracking Number ' + TEST_SHIPPING_TRACKING_NUMBER);
            System.assertEquals(mxOrderShipped.Order_Status_Last_Modified_Date__c, caseFromDB.Tablet_Ship_Date2__c, 'Expecting Shipped Date ' + mxOrderShipped.Order_Status_Last_Modified_Date__c);
        }
    }
    /**
     * @description Test - Mx Order delivered scenario
     */
    @isTest
    public static void testUpdateMxOrderCaseStatusReceived() {
        System.runAs (getTestRunUser()) {
            Opportunity opportunity = getCpqOpportunity();
            Case tabletRequestCase = getTableRequestCase(opportunity.Id);
            System.assertEquals(true, tabletRequestCase!=null, 'Expecting a tablet request case record');
            Mx_Order__c mxOrder = [SELECT Id, Vendor__c, Mx_Order_Request__c FROM Mx_Order__c WHERE Case__c = :tabletRequestCase.Id LIMIT 1];
            System.assertEquals(true, mxOrder.Id != null, 'Expecting a Mx Order to be generated/created' );
            System.assertEquals('Social Mobile', mxOrder.Vendor__c, 'Expecting the vendor value - ' + 'Social Mobile' );
            Mx_Order_Request__c mxOrderRequestFromDB = getMxOrderRequest();
            System.assertEquals(mxOrderRequestFromDB.Id, mxOrder.Mx_Order_Request__c, 'Expecting the Mx Order Request value - ' + mxOrderRequestFromDB.Id );

            Trigger_Bypass_Settings__c triggerBypassSetting = new Trigger_Bypass_Settings__c(SetupOwnerId = UserInfo.getUserId());
            triggerBypassSetting.Case_Run_Methods__c = 'updateTabletDeliveredOnOpp;updateDeliverTabletMilestone;processCasesForMxSx';
            insert triggerBypassSetting;

            Test.startTest();
            Case tabletRequestToUpdate = new Case(Id = tabletRequestCase.Id, Status = 'Received', Tablet_Received_Date_2__c = System.now());
            update tabletRequestToUpdate;
            Test.getEventBus().deliver();
            Test.stopTest();
            Case caseFromDB = [SELECT Id, Status, Tablet_Tracking_FedEx__c, Tablet_Received_Date_2__c FROM Case WHERE Id = :tabletRequestCase.Id LIMIT 1];
            System.assertEquals(true, caseFromDB != null, 'Expecting a Case record ');
            System.assertEquals('Received', caseFromDB.Status, 'Expecting Case status ' + 'Received');
            Mx_Order__c mxOrderFromDB = [SELECT Id, Order_Status__c FROM Mx_Order__c WHERE Id = :mxOrder.Id LIMIT 1];
            System.assertEquals(true, mxOrderFromDB != null, 'Expecting a Mx Order record ');
            System.assertEquals('delivered', mxOrderFromDB.Order_Status__c, 'Expecting Mx Order status ' + 'delivered');
        }
    }
     /**
     * @description Test Case Update when Mx Order has blocked status
     */
    @isTest
    public static void testUpdateCaseMxOrderStatusblocked() {
        System.runAs (getTestRunUser()) {
            Opportunity opportunity = getCpqOpportunity();
            Case tabletRequestCase = getTableRequestCase(opportunity.Id);
            System.assertEquals(true, tabletRequestCase!=null, 'Expecting a tablet request case record');
            Mx_Order__c mxOrder = [SELECT Id, Vendor__c, Mx_Order_Request__c FROM Mx_Order__c WHERE Case__c = :tabletRequestCase.Id LIMIT 1];
            System.assertEquals(true, mxOrder.Id != null, 'Expecting a Mx Order to be generated/created' );
            Test.startTest();
            Mx_Order__c mxOrderToUpdate = new Mx_Order__c(Id = mxOrder.Id, Order_Id__c = '1234567', Order_Status__c = 'blocked', Order_Status_Last_Modified_Date__c = System.now());
            update mxOrderToUpdate;
            Test.getEventBus().deliver();
            Test.stopTest();
            Case caseFromDB = [SELECT Id, Status FROM Case WHERE Id = :tabletRequestCase.Id LIMIT 1];
            System.assertEquals(true, caseFromDB != null, 'Expecting a Case record ');
            System.assertEquals('Blocked', caseFromDB.Status, 'Expecting Case status ' + 'Escalated');
        }
    }
    /**
     * @description Test - Configured Mx Order for Case Update
     */
    @isTest
    public static void testMilestoneBlockedValidation() {
        System.runAs (getTestRunUser()) {
            Disable_Declarative_Automation__c disableAuto = new Disable_Declarative_Automation__c();
            disableAuto.Case__c = true;
            insert disableAuto;
            Opportunity opportunity = getCpqOpportunity();
            Case tabletRequestCase = getTableRequestCase(opportunity.Id);
            System.assertEquals(true, tabletRequestCase!=null, 'Expecting a tablet request case record');
            Mx_Order__c mxOrder = [SELECT Id, Vendor__c, Mx_Order_Request__c FROM Mx_Order__c WHERE Case__c = :tabletRequestCase.Id LIMIT 1];
            System.assertEquals(true, mxOrder.Id != null, 'Expecting a Mx Order to be generated/created' );
            System.assertEquals('Social Mobile', mxOrder.Vendor__c, 'Expecting the vendor value - ' + 'Social Mobile' );
            Mx_Order_Request__c mxOrderRequestFromDB = getMxOrderRequest();
            System.assertEquals(mxOrderRequestFromDB.Id, mxOrder.Mx_Order_Request__c, 'Expecting the Mx Order Request value - ' + mxOrderRequestFromDB.Id );
            Test.startTest();
            Map<Id, Case> onboardingCases = new Map<Id, Case>([ SELECT Id, RecordTypeId, RecordType.Name
                                                                FROM Case
                                                                WHERE Opportunity_name__c = :opportunity.Id
                                                                AND RecordTypeId = :CDdMxSxConstants.RECORD_TYPE_ID_CASE_MARKETPLACE_ONBOARDING]);
            Map<Id, Milestone__c> milestoneByRecordTypeId = new Map<Id, Milestone__c>();
            for (Milestone__c m : [ SELECT Id, Name, RecordTypeId, Case__c, Status__c, Status_Reason__c
                                    FROM Milestone__c
                                    WHERE Case__c IN :onboardingCases.keySet()
                                    AND Case__r.RecordTypeId = :CDdMxSxConstants.RECORD_TYPE_ID_CASE_MARKETPLACE_ONBOARDING
                                    AND RecordTypeId IN :CDdMxSxConstants.MX_ORDER_APPLICABLE_MILESTONE_RECORD_TYPE_IDS]){
                milestoneByRecordTypeId.put(m.RecordTypeId, m);
            }
            System.assertEquals(true, !milestoneByRecordTypeId.isEmpty(), 'Expecting milestones for Marketplace Onboarding Case');
            Milestone__c reviewAndTriageMilestone = milestoneByRecordTypeId.get(CDdMxSxConstants.MILESTONE_RECORD_TYPE_ID_REVIEW_AND_TRIAGE);
            System.assertEquals(true, reviewAndTriageMilestone!=null, 'Expecting Review & Triage Milestone');
            UPDATE new Case ( Id = reviewAndTriageMilestone.Case__c, OwnerId = UserInfo.getUserId() );
            UPDATE new Milestone__c (   Id = reviewAndTriageMilestone.Id,
                                        Status__c = CDdMxSxConstants.MILESTONE_STATUS_BLOCKED,
                                        Status_Reason__c = 'Account and Opportunity do not match'
                                    );
            Test.getEventBus().deliver();
            Test.stopTest();
            Case caseFromDB = [SELECT Id, Status FROM Case WHERE Id = :tabletRequestCase.Id LIMIT 1];
            System.assertEquals('Escalated', caseFromDB.Status, 'Expecting Tablet request Case Status - Escalated');
        }
    }
    /**
     * @description Test - Create Mx Order Shipment
     */
    @IsTest
    public static void testCreateMxOrderShipmentForFedEx() {
        system.runAs(getTestRunUser()) {
            Opportunity opportunity = getCpqOpportunity();
            Case tabletRequestCase = getTableRequestCase(opportunity.Id);
            Mx_Order__c mxOrder = [SELECT Id, Vendor__c, Mx_Order_Request__c FROM Mx_Order__c WHERE Case__c = :tabletRequestCase.Id LIMIT 1];
            System.assertEquals(true, mxOrder.Id != null, 'Expecting a Mx Order to be generated/created' );
            System.assertEquals('Social Mobile', mxOrder.Vendor__c, 'Expecting the vendor value - ' + 'Social Mobile' );
            Test.startTest();
            mxOrder.Order_Id__c = TEST_MX_ORDER_ID;
            mxOrder.Order_Status__c = CDdMxSxConstants.MX_ORDER_STATUS_LABELED;
            mxOrder.Order_Status_Last_Modified_Date__c = System.now();
            mxOrder.Shipping_Tracking_Number__c = TEST_SHIPPING_TRACKING_NUMBER;
            mxOrder.Shipping_Carrier__c = CDdMxSxConstants.MX_SHIPPING_CARRIER_FEDEX;
            mxOrder.Shipping_Method__c = CDdMxSxConstants.MX_SHIPPING_METHOD_EXPEDITED;
            update new List<Mx_Order__c>{ mxOrder };
            Test.stopTest();
            List<zkmulti__MCShipment__c> shipmentRecords = [SELECT Id, zkmulti__Tracking_Number__c, Case__c, Mx_Order__c
                                                            FROM zkmulti__MCShipment__c
                                                            WHERE Mx_Order__c = :mxOrder.Id
                                                         ];
            System.assertEquals(1, shipmentRecords.size(), 'shipmentRecords: ' + shipmentRecords);
            System.assertEquals(TEST_SHIPPING_TRACKING_NUMBER, shipmentRecords[0].zkmulti__Tracking_Number__c);
            System.assertEquals(tabletRequestCase.Id, shipmentRecords[0].Case__c);
            Case caseFromDB = [SELECT Id, Status, Shipping_Type__c, Tablet_Tracking_FedEx__c FROM Case WHERE Id = :tabletRequestCase.Id LIMIT 1];
            System.assertEquals(TEST_SHIPPING_TRACKING_NUMBER, caseFromDB.Tablet_Tracking_FedEx__c, 'Expecting Shipping Tracking Number ' + TEST_SHIPPING_TRACKING_NUMBER);
            System.assertEquals(CDdMxSxConstants.MX_SHIPPING_METHOD_EXPEDITED, caseFromDB.Shipping_Type__c);
        }
    }
    /**
     * @description Test - Mx Order Item updates to tablet/printer identifiers
     */
    @isTest
    public static void testUpdateMxOrderItemIdentification() {
        System.runAs (getTestRunUser()) {
            Opportunity opportunity = getCpqOpportunity();
            Case tabletRequestCase = getTableRequestCase(opportunity.Id);
            System.assertEquals(true, tabletRequestCase!=null, 'Expecting a tablet request case record');
            Mx_Order__c mxOrder = [SELECT Id, Vendor__c, Mx_Order_Request__c FROM Mx_Order__c WHERE Case__c = :tabletRequestCase.Id LIMIT 1];
            System.assertEquals(true, mxOrder.Id != null, 'Expecting a Mx Order to be generated/created' );
            System.assertEquals('Social Mobile', mxOrder.Vendor__c, 'Expecting the vendor value - ' + 'Social Mobile' );
            Mx_Order_Request__c mxOrderRequestFromDB = getMxOrderRequest();
            System.assertEquals(mxOrderRequestFromDB.Id, mxOrder.Mx_Order_Request__c, 'Expecting the Mx Order Request value - ' + mxOrderRequestFromDB.Id );
            Test.startTest();
            // Get Mx Order Items - tablet and printer
            List<Mx_Order_Item__c> itemsToUpdate = new List<Mx_Order_Item__c>();
            for (Mx_Order_Item__c item : [SELECT Id, Product_Family__c, Identifier__c FROM Mx_Order_Item__c WHERE Mx_Order__c = :mxOrder.Id]){
                if (CDdMxSxConstants.MX_PRODUCT_FAMILY_TABLET.equals(item.Product_Family__c)){
                    itemsToUpdate.add(new Mx_Order_Item__c(Id = item.Id, Identifier__c = TEST_IDENTIFIER_TABLET));
                }
                if (CDdMxSxConstants.MX_PRODUCT_FAMILY_PRINTER.equals(item.Product_Family__c)){
                    itemsToUpdate.add(new Mx_Order_Item__c(Id = item.Id, Identifier__c = TEST_IDENTIFIER_PRINTER));
                }
            }
            update itemsToUpdate;
            Test.stopTest();
            Case caseFromDB = [SELECT Id, Status, Tablet_Serial_Number__c, Printer_IMEI__c FROM Case WHERE Id = :tabletRequestCase.Id LIMIT 1];
            System.assertEquals(true, caseFromDB != null, 'Expecting a Case record ');
            System.assertEquals(TEST_IDENTIFIER_TABLET, caseFromDB.Tablet_Serial_Number__c, 'Expecting Identifier ' + TEST_IDENTIFIER_TABLET);
            System.assertEquals(TEST_IDENTIFIER_PRINTER, caseFromDB.Printer_IMEI__c, 'Expecting Identifier ' + TEST_IDENTIFIER_PRINTER);
        }
    }
    /**
     * @description BZAP-15532 - Shipping Type Validation
     */
    @isTest
    public static void testShippingTypeValidation() {
        System.runAs (getTestRunUser()) {
            Opportunity opportunity = getCpqOpportunity();
            Case tabletRequestCase = getTableRequestCase(opportunity.Id);
            System.assertEquals(true, tabletRequestCase!=null, 'Expecting a tablet request case record');
            Mx_Order__c mxOrder = [SELECT Id, Vendor__c, Mx_Order_Request__c FROM Mx_Order__c WHERE Case__c = :tabletRequestCase.Id LIMIT 1];
            System.assertEquals(true, mxOrder.Id != null, 'Expecting a Mx Order to be generated/created' );
            System.assertEquals('Social Mobile', mxOrder.Vendor__c, 'Expecting the vendor value - ' + 'Social Mobile' );
            Mx_Order_Request__c mxOrderRequestFromDB = getMxOrderRequest();
            System.assertEquals(mxOrderRequestFromDB.Id, mxOrder.Mx_Order_Request__c, 'Expecting the Mx Order Request value - ' + mxOrderRequestFromDB.Id );
            Test.startTest();
            Map<Id, Case> onboardingCases = new Map<Id, Case>([ SELECT Id, RecordTypeId, RecordType.Name
                                                                FROM Case
                                                                WHERE Opportunity_name__c = :opportunity.Id
                                                                AND RecordTypeId = :CDdMxSxConstants.RECORD_TYPE_ID_CASE_MARKETPLACE_ONBOARDING]);
            Map<Id, Milestone__c> milestoneByRecordTypeId = new Map<Id, Milestone__c>();
            for (Milestone__c m : [ SELECT Id, Name, RecordTypeId, Case__c, Status__c, Status_Reason__c
                                    FROM Milestone__c
                                    WHERE Case__c IN :onboardingCases.keySet()
                                    AND Case__r.RecordTypeId = :CDdMxSxConstants.RECORD_TYPE_ID_CASE_MARKETPLACE_ONBOARDING
                                    AND RecordTypeId IN :CDdMxSxConstants.MX_ORDER_APPLICABLE_MILESTONE_RECORD_TYPE_IDS]){
                milestoneByRecordTypeId.put(m.RecordTypeId, m);
            }
            System.assertEquals(true, !milestoneByRecordTypeId.isEmpty(), 'Expecting milestones for Marketplace Onboarding Case');
            Milestone__c reviewAndTriageMilestone = milestoneByRecordTypeId.get(CDdMxSxConstants.MILESTONE_RECORD_TYPE_ID_REVIEW_AND_TRIAGE);
            System.assertEquals(true, reviewAndTriageMilestone!=null, 'Expecting Review & Triage Milestone');
            Milestone__c setupStoreMilestone = milestoneByRecordTypeId.get(CDdMxSxConstants.MILESTONE_RECORD_TYPE_ID_SETUP_STORE);
            System.assertEquals(true, setupStoreMilestone!=null, 'Expecting Setup Store Milestone');
            UPDATE new List<Case>{  new Case ( Id = reviewAndTriageMilestone.Case__c, OwnerId = UserInfo.getUserId() ),
                                    new Case ( Id = tabletRequestCase.Id, Shipping_Type__c = null )
                                };
            UPDATE new List<Milestone__c>{  new Milestone__c (  Id = reviewAndTriageMilestone.Id,
                                                                Status__c = CDdMxSxConstants.MILESTONE_STATUS_COMPLETE),
                                            new Milestone__c (  Id = setupStoreMilestone.Id,
                                                                Status__c = CDdMxSxConstants.MILESTONE_STATUS_COMPLETE)
                                        };
            Test.getEventBus().deliver();
            Test.stopTest();
            Mx_Order__c mxOrderFromDB = [SELECT Id, Order_Status__c, Order_Status_Description__c, Case__r.Status FROM Mx_Order__c WHERE Id = :mxOrder.Id LIMIT 1];
            System.assertEquals(CDdMxSxConstants.MX_ORDER_STATUS_INVALID, mxOrderFromDB.Order_Status__c);
            System.assertEquals('Escalated', mxOrderFromDB.Case__r.Status, 'Expecting Tablet request Case Status - Escalated');
            String shippingTypeMissingErrorMsg = CDdMxOrderValidator.VALIDATION_CONFIGURATION.get(CDdMxOrderValidator.VALIDATION_STEP.SHIPPING_TYPE_EXISTS).Error_Message__c;
            System.assertEquals(true, mxOrderFromDB.Order_Status_Description__c.contains(shippingTypeMissingErrorMsg));
        }
    }
         /**
     * @description adding test method to bypass code scan for system.type reference.
     */
    @isTest
    public static void testApexClassType() {
        System.runAs (getTestRunUser()) {
            Type t1 = CLASS_REFERENCE[0];
            Type t2 = Type.forName('CDdMxOrderAccountHelper');
            System.assert(t1.equals(t2));
        }
    }
    /**
     * @description Return the test cpq opportunity record created in the setup method
     */
    private static Opportunity getCpqOpportunity() {
        return [SELECT Id, AccountId, SBQQ__PrimaryQuote__c FROM Opportunity WHERE Name = :TEST_OPPORTUNITY_NAME_FOR_CPQ LIMIT 1];
    }
    private static Case getTableRequestCase(Id opportunityId){
        Case tabletRequestCase = null;
        for (Case c :   [   SELECT Id, RecordTypeId, Mx_Order_Vendor__c
                            FROM Case
                            WHERE RecordTypeId = :RECORD_TYPE_ID_CASE_TABLET_REQUESTS
                            AND Opportunity_Name__c = :opportunityId]){
            tabletRequestCase = c;
        }
        return tabletRequestCase;
    }
    /**
     * @description Return the Order record created in the setup method
     */
    private static Order getOrder(Id opportunityId) {
        return [SELECT Id, OpportunityId, AccountId FROM Order WHERE OpportunityId = :opportunityId LIMIT 1];
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
    public static Mx_Order_Request__c getMxOrderRequest(){
        return [SELECT Id FROM Mx_Order_Request__c WHERE Request_Type__c = :TEST_MX_ORDER_REQUEST_TYPE AND Country_Code__c = :TEST_MX_ORDER_REQUEST_COUNTRY_CODE LIMIT 1];
    }
    public static Mx_Order_Request__c createMxOrderRequest(String requestType, String countryCode, List<Mx_Product__c> mxProducts){
        Mx_Order_Request__c request = new Mx_Order_Request__c(
            Is_Active__c = TRUE,
            Request_Type__c = requestType,
            Country_Code__c = countryCode,
            Is_Routing_Enabled__c = true
        );
        insert request;
        List<Mx_Order_Request_Product__c> mxOrderRequestProducts = new List<Mx_Order_Request_Product__c>();
        for (Mx_Product__c mxProduct : mxProducts){
            mxOrderRequestProducts.add(new Mx_Order_Request_Product__c(
                Mx_Order_Request__c = request.Id,
                Mx_Product__c = mxProduct.Id
            ));
        }
        insert mxOrderRequestProducts;
        return request;
    }
    public static List<Mx_Product__c> createMxProducts() {
        List<Mx_Product__c> mxProducts = new List<Mx_Product__c>();
        mxProducts.add(new Mx_Product__c(
            Family__c = CDdMxSxConstants.MX_PRODUCT_FAMILY_TABLET,
            Name = 'Samsung Galaxy Tab A7 lite',
            Country__c = 'ALL',
            SKU_Social_Mobile__c = 'TB-0000-00000000'
        ));
        mxProducts.add(new Mx_Product__c(
            Family__c = 'Marketing Kit',
            Name = 'Overture Box US English',
            Country__c = 'ALL',
            SKU_Social_Mobile__c = 'MK-0000-01000000',
            Language__c = 'English'
        ));
        mxProducts.add(new Mx_Product__c(
            Family__c = 'Marketing Kit',
            Name = 'Overture Box US Spanish',
            Country__c = 'ALL',
            SKU_Social_Mobile__c = 'MK-0000-02000000',
            Language__c = 'Spanish'
        ));
        mxProducts.add(new Mx_Product__c(
            Family__c = CDdMxSxConstants.MX_PRODUCT_FAMILY_PRINTER,
            Name = 'Samsung Galaxy Printer',
            Country__c = 'ALL',
            SKU_Social_Mobile__c = 'PR-0000-00000000'
        ));
        insert mxProducts;
        return mxProducts;
    }
}