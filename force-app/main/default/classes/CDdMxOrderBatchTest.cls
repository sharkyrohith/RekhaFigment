/********************************************************************************************************************
* @author Lathika
* @date 04/15/2022
*
* @group Merchant Services
*
* @description Test class for CDdMxOrderBatch BZAP-14359
*
* 
**************************************************************************************************************************************/
@isTest
public class CDdMxOrderBatchTest {
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
        CDdMxSxTriggerHelper.class,
        CDdMxOrderBatchSendemailHelper.class
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
            account.iPad_Username__c = '';
            account.iPad_Password__c = '';
            account.Name='DoorDash';
            account.Top_Mx__c = true;
            insert account;
            
            Contact contact = TDdAccountFactory.createContacts(1, account.Id)[0];
            contact.Email = 'contact@testdd.com';
            contact.Phone = '1234567890';            
            insert contact;

            List<Mx_Product__c> mxProducts = createMxProducts();
            createMxOrderRequest(TEST_MX_ORDER_REQUEST_TYPE, TEST_MX_ORDER_REQUEST_COUNTRY_CODE, mxProducts);
            
            CDdMxSxTestCPQSetup.insertCPQProducts();
            CDdMxSxTestCPQSetup.insertCPQPriceBookEntries();

            String contactId = contact.Id ;
            createEvent('Storefront Implementation Call', contactId, System.Now().addMinutes(15), System.Now().addMinutes(15), 'Meeting', true);

            String PARTNER_INTEGRATION_SQUARE = 'square';

            Id PARTNER_INTEGRATION_POS_RECORDTYPEID = Schema.SObjectType.Partner_Integration__c.getRecordTypeInfosByDeveloperName().get('Point_Of_Sale').getRecordTypeId();
            Partner_Integration__c partnerIntegration1 = new Partner_Integration__c(Provider_Type__c = PARTNER_INTEGRATION_SQUARE, Provider_Name__c = PARTNER_INTEGRATION_SQUARE, Integration_Function__c = 'New Verticals', Launch_Day__c = 'PDOA', Menu_Type__c = 'OPEN_API', Menu_Pull__c = 'False', Menu_Push__c = 'True', Integration_Status__c = 'Live', Integration_Type__c = 'POS System', RecordTypeId=PARTNER_INTEGRATION_POS_RECORDTYPEID);
            partnerIntegration1.Menu_Vs_Order_Integration__c = CDdMxSxConstants.PARTNER_INTEG_MENU_ONLY_INTEGRATION;
            insert partnerIntegration1;

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
            opp.POS_Integration_Type__c = PARTNER_INTEGRATION_SQUARE;
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
     * @description Test Invalid Mx Order for relevant Milestone in Progress
     * Mx Order is invalid because Account fields 'Restaurant_Id__c', 'iPad_Username__c', 'iPad_Password__c' are blank
     * However, the milestones - Review & Triage and Setup Store are in progress
     * Expectation - Case should continue to be in 'Open' status and must not be escalated after the Batch execution
     */    
    @isTest
    public static void testInvalidMxOrderWhenMilestonesInProgress() {
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
            executeBatch(CDdMxOrderBatchEnum.PROCESS_MX_ORDER);
            Test.stopTest();
            Case tabletRequestCaseFromDB = getTableRequestCase(opportunity.Id);
            Mx_Order__c mxOrderFromDB = [SELECT Id, Order_Status__c FROM Mx_Order__c WHERE Case__c = :tabletRequestCaseFromDB.Id LIMIT 1];
            System.assertEquals(CDdMxSxConstants.MX_ORDER_STATUS_OPEN, mxOrderFromDB.Order_Status__c, 'Expecting Mx Order Status - ' + CDdMxSxConstants.MX_ORDER_STATUS_OPEN);
            System.assertEquals('Open', tabletRequestCaseFromDB.Status, 'Expecting Case status to be Open' );             
        }
    }
    /**
     * @description Test Invalid Mx Order for when Opportunity 'Proposed Date of Tablet' is in the future
     * Mx Order is invalid because Account fields 'Restaurant_Id__c', 'iPad_Username__c', 'iPad_Password__c' are blank
     * However, the Opportunity 'Proposed Date of Tablet' is in the future
     * Expectation - Case should continue to be in 'Open' status and must not be escalated after the Batch execution
     */    
    @isTest
    public static void testInvalidMxOrderWhenOppPDOTIsInFuture() {
        System.runAs (getTestRunUser()) {
            Opportunity opportunity = getCpqOpportunity();
            opportunity.Proposed_Date_of_Activation__c = Date.today().addDays(10);
            opportunity.Proposed_Date_of_Menu__c = Date.today().addDays(5);
            opportunity.Proposed_Date_of_Menu_Original__c = null;
            opportunity.Proposed_Date_of_Tablet__c = Date.today().addDays(5);
            update opportunity;
            Case tabletRequestCase = getTableRequestCase(opportunity.Id);
            System.assertEquals(true, tabletRequestCase!=null, 'Expecting a tablet request case record');  
            Mx_Order__c mxOrder = [SELECT Id, Vendor__c, Mx_Order_Request__c FROM Mx_Order__c WHERE Case__c = :tabletRequestCase.Id LIMIT 1];
            System.assertEquals(true, mxOrder.Id != null, 'Expecting a Mx Order to be generated/created' );
            System.assertEquals('Social Mobile', mxOrder.Vendor__c, 'Expecting the vendor value - ' + 'Social Mobile' );
            Mx_Order_Request__c mxOrderRequestFromDB = getMxOrderRequest();
            System.assertEquals(mxOrderRequestFromDB.Id, mxOrder.Mx_Order_Request__c, 'Expecting the Mx Order Request value - ' + mxOrderRequestFromDB.Id );
            Test.startTest();
            executeBatch(CDdMxOrderBatchEnum.PROCESS_MX_ORDER);
            Test.stopTest();
            Case tabletRequestCaseFromDB = getTableRequestCase(opportunity.Id);
            Mx_Order__c mxOrderFromDB = [SELECT Id, Order_Status__c, Order_Status_Description__c FROM Mx_Order__c WHERE Case__c = :tabletRequestCaseFromDB.Id LIMIT 1];
            System.assertEquals(CDdMxSxConstants.MX_ORDER_STATUS_OPEN, mxOrderFromDB.Order_Status__c, 'Expecting Mx Order Status - ' + CDdMxSxConstants.MX_ORDER_STATUS_OPEN);
            System.assertEquals('Open', tabletRequestCaseFromDB.Status, 'Expecting Case status to be Open' ); 
            System.assertEquals(CDdMxSxConstants.MX_ORDER_FUTURE_PDOT_DATE_ERROR_MESSAGE, mxOrderFromDB.Order_Status_Description__c);            
        }
    }    
    /**
     * @description Test Invalid Mx Order for relevant Milestone when Complete
     * Mx Order is invalid because In_Coverage__c is 'No'
     * However, the milestones - Review & Triage and Setup Store are Complete
     * Expectation - Case should be in 'Escalated' status after the Batch execution
     */    
    @isTest
    public static void testInvalidMxOrderWhenMilestonesCompleted() {
        System.runAs (getTestRunUser()) {
            Opportunity opportunity = getCpqOpportunity();
            Case tabletRequestCase = getTableRequestCase(opportunity.Id);
            System.assertEquals(true, tabletRequestCase!=null, 'Expecting a tablet request case record');  
            Mx_Order__c mxOrder = [SELECT Id, Vendor__c, Mx_Order_Request__c FROM Mx_Order__c WHERE Case__c = :tabletRequestCase.Id LIMIT 1];
            System.assertEquals(true, mxOrder.Id != null, 'Expecting a Mx Order to be generated/created' );
            System.assertEquals('Social Mobile', mxOrder.Vendor__c, 'Expecting the vendor value - ' + 'Social Mobile' );
            Mx_Order_Request__c mxOrderRequestFromDB = getMxOrderRequest();
            System.assertEquals(mxOrderRequestFromDB.Id, mxOrder.Mx_Order_Request__c, 'Expecting the Mx Order Request value - ' + mxOrderRequestFromDB.Id );
            Case marketplaceOnboardingCase = getMarketplaceOnboardingCase(opportunity.Id);
            System.assertEquals(true, marketplaceOnboardingCase != null);
            Map<Id, Milestone__c> milestoneByRecordTypeId = getMilestonesByRecordTypeId(marketplaceOnboardingCase.Id);
            System.assertEquals(true, !milestoneByRecordTypeId.isEmpty(), 'Expecting milestones for Marketplace Onboarding Case');
            // Update the tablet credentials, Store Id, Starting Point on the Account
            // However set the Coverage check as 'No' on the Account
            update new Account(Id = opportunity.AccountId, 
                                iPad_Username__c = '12345678', 
                                iPad_Password__c = '12345678', 
                                Restaurant_Id__c = '123456', 
                                Starting_Point__c = '101',
                                In_Coverage__c = 'No');            
            // Move the relevant milestones to complete
            Milestone__c reviewAndTriageMilestone = milestoneByRecordTypeId.get(CDdMxSxConstants.MILESTONE_RECORD_TYPE_ID_REVIEW_AND_TRIAGE);
            Milestone__c setupStoreMilestone = milestoneByRecordTypeId.get(CDdMxSxConstants.MILESTONE_RECORD_TYPE_ID_SETUP_STORE); 
            UPDATE new Case ( Id = marketplaceOnboardingCase.Id, OwnerId = UserInfo.getUserId() );
            List<Milestone__c> milestonesToUpdate =  new List<Milestone__c>{
                                                            new Milestone__c (   Id = reviewAndTriageMilestone.Id,
                                                                                Status__c = CDdMxSxConstants.MILESTONE_STATUS_COMPLETE
                                                            ),
                                                            new Milestone__c (   Id = setupStoreMilestone.Id,
                                                                                Status__c = CDdMxSxConstants.MILESTONE_STATUS_COMPLETE
                                                            )
                                                    };
            update milestonesToUpdate;                                                                                            
            Test.getEventBus().deliver();                         
            Test.startTest();
            executeBatch(CDdMxOrderBatchEnum.PROCESS_MX_ORDER);
            Test.stopTest();
            Case tabletRequestCaseFromDB = getTableRequestCase(opportunity.Id);
            Mx_Order__c mxOrderFromDB = [SELECT Id, Order_Status__c FROM Mx_Order__c WHERE Case__c = :tabletRequestCaseFromDB.Id LIMIT 1];
            System.assertEquals(CDdMxSxConstants.MX_ORDER_STATUS_INVALID, mxOrderFromDB.Order_Status__c, 'Expecting Mx Order Status - ' + CDdMxSxConstants.MX_ORDER_STATUS_INVALID);
            System.assertEquals('Escalated', tabletRequestCaseFromDB.Status, 'Expecting Case status to be Escalated' );             
        }
    }
    /**
     * @description Test valid Mx Order when relevant Milestones are Complete
     * Mx Order is valid and all relevant milestones are Complete
     * Expectation - A Mx Order Queue record should be present when the batch job completes its execution
     */    
    @isTest
    public static void testQueueableMxOrder() {
        System.runAs (getTestRunUser()) {
            Opportunity opportunity = getCpqOpportunity();
            Case tabletRequestCase = getTableRequestCase(opportunity.Id);
            System.assertEquals(true, tabletRequestCase!=null, 'Expecting a tablet request case record');  
            Mx_Order__c mxOrder = [SELECT Id, Vendor__c, Mx_Order_Request__c FROM Mx_Order__c WHERE Case__c = :tabletRequestCase.Id LIMIT 1];
            System.assertEquals(true, mxOrder.Id != null, 'Expecting a Mx Order to be generated/created' );
            System.assertEquals('Social Mobile', mxOrder.Vendor__c, 'Expecting the vendor value - ' + 'Social Mobile' );
            Mx_Order_Request__c mxOrderRequestFromDB = getMxOrderRequest();
            System.assertEquals(mxOrderRequestFromDB.Id, mxOrder.Mx_Order_Request__c, 'Expecting the Mx Order Request value - ' + mxOrderRequestFromDB.Id );
            Case marketplaceOnboardingCase = getMarketplaceOnboardingCase(opportunity.Id);
            System.assertEquals(true, marketplaceOnboardingCase != null);
            Map<Id, Milestone__c> milestoneByRecordTypeId = getMilestonesByRecordTypeId(marketplaceOnboardingCase.Id);
            System.assertEquals(true, !milestoneByRecordTypeId.isEmpty(), 'Expecting milestones for Marketplace Onboarding Case');
            // Update the tablet credentials, Store Id, Starting Point, Coverage Check on the Account
            update new Account(Id = opportunity.AccountId, 
                                iPad_Username__c = '12345678', 
                                iPad_Password__c = '12345678', 
                                Restaurant_Id__c = '123456', 
                                Starting_Point__c = '101',
                                In_Coverage__c = 'Yes');
            // Move the relevant milestones to complete
            Milestone__c reviewAndTriageMilestone = milestoneByRecordTypeId.get(CDdMxSxConstants.MILESTONE_RECORD_TYPE_ID_REVIEW_AND_TRIAGE);
            Milestone__c setupStoreMilestone = milestoneByRecordTypeId.get(CDdMxSxConstants.MILESTONE_RECORD_TYPE_ID_SETUP_STORE); 
            UPDATE new Case ( Id = marketplaceOnboardingCase.Id, OwnerId = UserInfo.getUserId() );
            List<Milestone__c> milestonesToUpdate =  new List<Milestone__c>{
                                                            new Milestone__c (   Id = reviewAndTriageMilestone.Id,
                                                                                Status__c = CDdMxSxConstants.MILESTONE_STATUS_COMPLETE
                                                            ),
                                                            new Milestone__c (   Id = setupStoreMilestone.Id,
                                                                                Status__c = CDdMxSxConstants.MILESTONE_STATUS_COMPLETE
                                                            )
                                                    };
            update milestonesToUpdate;                                                                                            
            Test.getEventBus().deliver();                         
            Test.startTest();
            Mx_Order__c mxOrderFromDB1 = [SELECT Id, Order_Status__c, Order_Status_Description__c, Mx_Order_Queue__c, Mx_Order_Queue__r.Attempt__c FROM Mx_Order__c WHERE Case__c = :tabletRequestCase.Id LIMIT 1];
            System.assertEquals(true, mxOrderFromDB1.Mx_Order_Queue__c == null, 'Mx Order Queue record not present on Mx Order');           
            executeBatch(CDdMxOrderBatchEnum.PROCESS_MX_ORDER);
            Test.stopTest();
            Mx_Order__c mxOrderFromDB2 = [SELECT Id, Order_Status__c, Order_Status_Description__c, Mx_Order_Queue__c, Mx_Order_Queue__r.Attempt__c FROM Mx_Order__c WHERE Case__c = :tabletRequestCase.Id LIMIT 1];
            System.assertEquals(null, mxOrderFromDB2.Order_Status_Description__c, 'Expecting Mx Order Status description null' );
            System.assertEquals(CDdMxSxConstants.MX_ORDER_STATUS_QUEUED, mxOrderFromDB2.Order_Status__c, 'Expecting Mx Order Status - ' + CDdMxSxConstants.MX_ORDER_STATUS_QUEUED);
            System.assertEquals(true, mxOrderFromDB2.Mx_Order_Queue__c != null, 'Expecting Mx Order Queue record' );
            System.assertEquals(1, mxOrderFromDB2.Mx_Order_Queue__r.Attempt__c, 'Expecting Mx Order Queue record to be inserted by the batch job' );                        
        }
    }
    /**
     * @description Test valid Mx Order when relevant Milestones are Complete
     * Mx Order is valid and all relevant milestones are Complete
     * Expectation - A Mx Order Queue record should be retried when the batch job completes its execution
     */    
    @isTest
    public static void testRetryableMxOrder() {
        System.runAs (getTestRunUser()) {
            Opportunity opportunity = getCpqOpportunity();
            Case tabletRequestCase = getTableRequestCase(opportunity.Id);
            System.assertEquals(true, tabletRequestCase!=null, 'Expecting a tablet request case record');  
            Mx_Order__c mxOrder = [SELECT Id, Vendor__c, Mx_Order_Request__c FROM Mx_Order__c WHERE Case__c = :tabletRequestCase.Id LIMIT 1];
            System.assertEquals(true, mxOrder.Id != null, 'Expecting a Mx Order to be generated/created' );
            System.assertEquals('Social Mobile', mxOrder.Vendor__c, 'Expecting the vendor value - ' + 'Social Mobile' );
            Mx_Order_Request__c mxOrderRequestFromDB = getMxOrderRequest();
            System.assertEquals(mxOrderRequestFromDB.Id, mxOrder.Mx_Order_Request__c, 'Expecting the Mx Order Request value - ' + mxOrderRequestFromDB.Id);
            Case marketplaceOnboardingCase = getMarketplaceOnboardingCase(opportunity.Id);
            System.assertEquals(true, marketplaceOnboardingCase != null);
            Map<Id, Milestone__c> milestoneByRecordTypeId = getMilestonesByRecordTypeId(marketplaceOnboardingCase.Id);
            System.assertEquals(true, !milestoneByRecordTypeId.isEmpty(), 'Expecting milestones for Marketplace Onboarding Case');
            // Update the tablet credentials, Store Id, Starting Point, Coverage Check on the Account
            update new Account(Id = opportunity.AccountId, 
                                iPad_Username__c = '12345678', 
                                iPad_Password__c = '12345678', 
                                Restaurant_Id__c = '123456', 
                                Starting_Point__c = '101',
                                In_Coverage__c = 'Yes');
            // Move the relevant milestones to complete
            Milestone__c reviewAndTriageMilestone = milestoneByRecordTypeId.get(CDdMxSxConstants.MILESTONE_RECORD_TYPE_ID_REVIEW_AND_TRIAGE);
            Milestone__c setupStoreMilestone = milestoneByRecordTypeId.get(CDdMxSxConstants.MILESTONE_RECORD_TYPE_ID_SETUP_STORE); 
            UPDATE new Case ( Id = marketplaceOnboardingCase.Id, OwnerId = UserInfo.getUserId() );
            List<Milestone__c> milestonesToUpdate =  new List<Milestone__c>{
                                                            new Milestone__c (   Id = reviewAndTriageMilestone.Id,
                                                                                Status__c = CDdMxSxConstants.MILESTONE_STATUS_COMPLETE
                                                            ),
                                                            new Milestone__c (   Id = setupStoreMilestone.Id,
                                                                                Status__c = CDdMxSxConstants.MILESTONE_STATUS_COMPLETE
                                                            )
                                                    };
            update milestonesToUpdate;                                                                                            
            Test.getEventBus().deliver();                         
            Test.startTest();
            Mx_Order__c mxOrderFromDB1 = [SELECT Id, Order_Status__c, Order_Status_Description__c, Mx_Order_Queue__c, Mx_Order_Queue__r.Attempt__c FROM Mx_Order__c WHERE Case__c = :tabletRequestCase.Id LIMIT 1];
            System.assertEquals(true, mxOrderFromDB1.Mx_Order_Queue__c == null, 'Mx Order Queue record not present on Mx Order');
            insert new Mx_Order_Queue__c(Mx_Order__c = mxOrderFromDB1.Id);           
            executeBatch(CDdMxOrderBatchEnum.PROCESS_MX_ORDER);
            Test.stopTest();
            Mx_Order__c mxOrderFromDB2 = [SELECT Id, Order_Status__c, Order_Status_Description__c, Mx_Order_Queue__c, Mx_Order_Queue__r.Attempt__c FROM Mx_Order__c WHERE Case__c = :tabletRequestCase.Id LIMIT 1];
            System.assertEquals(null, mxOrderFromDB2.Order_Status_Description__c, 'Expecting Mx Order Status description null' );
            System.assertEquals(CDdMxSxConstants.MX_ORDER_STATUS_QUEUED, mxOrderFromDB2.Order_Status__c, 'Expecting Mx Order Status - ' + CDdMxSxConstants.MX_ORDER_STATUS_QUEUED);
            System.assertEquals(true, mxOrderFromDB2.Mx_Order_Queue__c != null, 'Expecting Mx Order Queue record' );
            System.assertEquals(true, mxOrderFromDB2.Mx_Order_Queue__r.Attempt__c > 0, 'Expecting Mx Order Queue record to be retried by the batch job' );                        
        }
    }
    /**
     * @description Test valid Mx Order when relevant Milestones are Complete
     * Mx Order is valid and all relevant milestones are Complete
     * Expectation - A Mx Order Queue record should be present when the batch job completes its execution
     */    
    @isTest
    public static void testGenerateMxOrder() {
        System.runAs (getTestRunUser()) {
            Opportunity opportunity = getCpqOpportunity();
            Case tabletRequestCase = getTableRequestCase(opportunity.Id);
            System.assertEquals(true, tabletRequestCase!=null, 'Expecting a tablet request case record');  
            Mx_Order__c originalMxOrder = [SELECT Id, Mx_Order_Queue__c FROM Mx_Order__c WHERE Case__c = :tabletRequestCase.Id LIMIT 1];
            System.assertEquals(true, originalMxOrder.Id != null, 'Expecting a Mx Order to be generated/created' );
            Id originalMxOrderId = originalMxOrder.Id;
            delete originalMxOrder;                                                                                                                    
            Test.startTest();
            executeBatch(CDdMxOrderBatchEnum.GENERATE_MX_ORDER);       
            Test.getEventBus().deliver();
            Test.stopTest();
            Mx_Order__c mxOrderFromDB = [SELECT Id FROM Mx_Order__c WHERE Case__c = :tabletRequestCase.Id LIMIT 1];
            System.assertEquals(false, mxOrderFromDB.Id.equals(originalMxOrderId), 'Expecting a new Mx Order to be generated for the Case record' );                     
        }
    }
    /**
     * @description Test Send Mx Order Email when status is Shipped and attachments are present
     * Once the order has return label(attachment) email the return label to the Merchant.
     * Expectation - A Mx Order Status should be 'return to label' when the batch job completes its execution
     */    
   @isTest
    public static void testSendMxOrderAttachmentInEmail() {
        System.runAs (getTestRunUser()) {
            Account act  = [select id from account where Name = 'DoorDash'];
            Contact con = [select id from contact where accountid = :act.Id];
            Opportunity opp=[select id from Opportunity where accountId = :act.Id ];
            List<Mx_Product__c> mxProducts =[select id from Mx_Product__c limit 10]; 
            
            CDdMxEquipmentRequestModel cs = new CDdMxEquipmentRequestModel();
            cs.AccountId = act.Id;
            cs.ContactId = con.Id;
            cs.OppId = opp.Id;
            cs.requestType = TEST_MX_ORDER_REQUEST_TYPE;
            cs.returnProducts = new List<String>{mxProducts[0].Id};
            cs.newProducts = new List<String>{mxProducts[0].Id};
            cs.returnReplaceComponent = 'Yes';
            cs.isLemonadeAccount =false;
            
            String payLoad= JSON.serialize(cs);
            test.startTest();
            CDdMxEquipmentRequestController.CreateCases(payLoad);  
            test.stopTest();  
            Case returnCase =[select id,origin from case where Type_Of_Mx_Order__c =:CDdMxSxConstants.TYPE_OF_MX_ORDER_RETURN and createddate >= today and recordtypeId= :CDdMxSxConstants.CASE_RECORD_TYPE_ID_TABLET_REQUESTS limit 1];
            Mx_Order__c mx =[select id, case__c,Type_Of_Mx_Order__c from Mx_Order__c where case__c =:returnCase.Id and Type_Of_Mx_Order__c =:CDdMxSxConstants.TYPE_OF_MX_ORDER_RETURN];
            mx.Order_Status__c =CDdMxSxConstants.MX_ORDER_STATUS_LABELED;
            mx.vendor__c =CDdMxSxConstants.MX_VENDOR_SOCIAL_MOBILE;
            update mx;
            Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
            Attachment a = new Attachment(ParentId=mx.Id,Name='test attach',body=bodyBlob);
            insert a;
            List<Mx_Order__c> mxOrder = [Select Id, Name,Case__r.ContactEmail,Order_Status_Description__c,Case__r.Case_Owner_Email__c, Account__r.Owner.Email,OwnerId,(select id from Attachments order by Createddate desc limit 1) from Mx_Order__c where Id =:mx.id];
            CDdMxOrderBatchSendemailHelper sendEmail =new CDdMxOrderBatchSendemailHelper();
            sendEmail.sendingEmail(mxOrder);
            List<Mx_Order__c> mxOrders = [Select Id, Order_Status__c,Order_Status_Description__c from Mx_Order__c where Id=:mxOrder[0].Id];
            System.assertEquals(true, mxOrders[0].Order_Status__c == CDdMxSxConstants.MX_ORDER_STATUS_RETURN_LABEL_SENT , 'Status should be updated to \'return label sent\'');
        }
    }
    
    
    /**
     * @description Test batch scheduler
     */    
    @isTest
    public static void testMxOrderBatchScheduler() {
        System.runAs (getTestRunUser()) {
            Test.startTest();
            CDdMxOrderBatchScheduler scheduler = new CDdMxOrderBatchScheduler(CDdMxOrderBatchEnum.GENERATE_MX_ORDER);
            String timeScheduleString = '0 20 * * * ?'; // Apex Scheduler will run 20 minutes past every hour
            String schedulerJobID = System.schedule(
                    'Mx Order Batch Scheduler ' + Integer.valueof(Math.random() * 1000),
                    timeScheduleString,
                    scheduler
                );
            System.assertEquals(true, String.isNotBlank(schedulerJobID));
            Test.stopTest();                                
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
    
    private static  void executeBatch(CDdMxOrderBatchEnum batchEnum){
        CDdMxOrderBatchConfig batchConfig = new CDdMxOrderBatchConfig(batchEnum);
        Database.executeBatch(new CDdMxOrderBatch(batchEnum), batchConfig.getBatchSize());        
    }                                                                         
    /**
     * @description Return the test cpq opportunity record created in the setup method
     */      
    private static Opportunity getCpqOpportunity() {
        return [SELECT Id, AccountId, SBQQ__PrimaryQuote__c FROM Opportunity WHERE Name = :TEST_OPPORTUNITY_NAME_FOR_CPQ LIMIT 1];
    }
    private static Case getTableRequestCase(Id opportunityId){
        Case tabletRequestCase = null;
        for (Case c :   [   SELECT Id, RecordTypeId, Status
                            FROM Case
                            WHERE RecordTypeId = :RECORD_TYPE_ID_CASE_TABLET_REQUESTS
                            AND Opportunity_Name__c = :opportunityId]){
            tabletRequestCase = c;
        }
        return tabletRequestCase;
    }
    private static Case getMarketplaceOnboardingCase(Id opportunityId){
        return [SELECT Id, RecordTypeId, RecordType.Name 
                FROM Case 
                WHERE Opportunity_name__c = :opportunityId
                AND RecordTypeId = :CDdMxSxConstants.RECORD_TYPE_ID_CASE_MARKETPLACE_ONBOARDING
                LIMIT 1];
    }
    private static Map<Id, Milestone__c> getMilestonesByRecordTypeId(Id marketplaceOnboardingCaseId){
        Map<Id, Milestone__c> milestoneByRecordTypeId = new Map<Id, Milestone__c>();
        for (Milestone__c m : [ SELECT Id, Name, RecordTypeId, Case__c, Status__c, Status_Reason__c 
                                FROM Milestone__c 
                                WHERE Case__c = :marketplaceOnboardingCaseId 
                                AND Case__r.RecordTypeId = :CDdMxSxConstants.RECORD_TYPE_ID_CASE_MARKETPLACE_ONBOARDING 
                                AND RecordTypeId IN :CDdMxSxConstants.MX_ORDER_APPLICABLE_MILESTONE_RECORD_TYPE_IDS]){
            milestoneByRecordTypeId.put(m.RecordTypeId, m);
        }
        return milestoneByRecordTypeId;        
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
            Family__c = 'Tablet',
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
        insert mxProducts;
        return mxProducts;
    }
    /**
     * @description Validation error if Mx Order is not eligibile for printer
     */    
    @isTest
    public static void testPrinterEligibility() {
        System.runAs (getTestRunUser()) {
            Opportunity opportunity = getCpqOpportunity();
            Case tabletRequestCase = getTableRequestCase(opportunity.Id);
            Case marketplaceOnboardingCase = getMarketplaceOnboardingCase(opportunity.Id);
            tabletRequestCase.Request_Type__c = new List<String>(CDdMxSxConstants.CASE_REQUEST_TYPES_FOR_INCLUSION_OF_PRINTER)[0];
            marketplaceOnboardingCase.Request_Type__c = new List<String>(CDdMxSxConstants.CASE_REQUEST_TYPES_FOR_INCLUSION_OF_PRINTER)[0];
            List<Case> cases = new List<Case>();
            cases.add(tabletRequestCase);
            cases.add(marketplaceOnboardingCase);
            update cases;
            Map<Id, Milestone__c> milestoneByRecordTypeId = getMilestonesByRecordTypeId(marketplaceOnboardingCase.Id);
            // Update the tablet credentials, Store Id, Starting Point, Coverage Check on the Account
            update new Account(Id = opportunity.AccountId, 
                                iPad_Username__c = '12345678', 
                                iPad_Password__c = '12345678', 
                                Restaurant_Id__c = '123456', 
                                Starting_Point__c = '101',
                                In_Coverage__c = 'Yes',
                                Top_Mx__c = false);
            // Move the relevant milestones to complete
            Milestone__c reviewAndTriageMilestone = milestoneByRecordTypeId.get(CDdMxSxConstants.MILESTONE_RECORD_TYPE_ID_REVIEW_AND_TRIAGE);
            Milestone__c setupStoreMilestone = milestoneByRecordTypeId.get(CDdMxSxConstants.MILESTONE_RECORD_TYPE_ID_SETUP_STORE); 
            UPDATE new Case ( Id = marketplaceOnboardingCase.Id, OwnerId = UserInfo.getUserId() );
            List<Milestone__c> milestonesToUpdate =  new List<Milestone__c>{
                                                            new Milestone__c (   Id = reviewAndTriageMilestone.Id,
                                                                                Status__c = CDdMxSxConstants.MILESTONE_STATUS_COMPLETE
                                                            ),
                                                            new Milestone__c (   Id = setupStoreMilestone.Id,
                                                                                Status__c = CDdMxSxConstants.MILESTONE_STATUS_COMPLETE
                                                            )
                                                    };
            Test.startTest();
            update milestonesToUpdate;                                                                                            
            Test.getEventBus().deliver(); 
            Test.stopTest();                        
            Mx_Order__c mxOrderFromDB1 = [SELECT Id, Order_Status__c, Order_Status_Description__c, Mx_Order_Queue__c, Mx_Order_Queue__r.Attempt__c FROM Mx_Order__c WHERE Case__c = :tabletRequestCase.Id LIMIT 1];
            System.assert(mxOrderFromDB1.Order_Status_Description__c.contains(Mx_Order_Validation_Config__mdt.getInstance('Printer_Eligibility').Error_Message__c), 'Expecting Priniter Eligibilty validation error' );                            
        }
    }    
}