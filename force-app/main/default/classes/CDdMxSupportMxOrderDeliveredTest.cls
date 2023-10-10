/********************************************************************************************************************
* @author Sriram
* @date 06/28/2022
*
* @group Merchant Services
*
* @description Test Merchant Order Delivered script via Mx Support Job framework     
* 
**************************************************************************************************************************************/
@isTest
public class CDdMxSupportMxOrderDeliveredTest {
   /**
     * Begin - Test class to execute if one of these classes is updated
     */
    private static List<System.Type> CLASS_REFERENCE = new List<System.Type>{       
        CDdMxSupportMxOrderDelivered.class
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

            insertEventConfig();
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
            insert account;
            
            Contact contact = TDdAccountFactory.createContacts(1, account.Id)[0];
            insert contact;

            List<Mx_Product__c> mxProducts = createMxProducts();
            Mx_Order_Request__c mxOrderRequest = createMxOrderRequest(TEST_MX_ORDER_REQUEST_TYPE, TEST_MX_ORDER_REQUEST_COUNTRY_CODE, mxProducts);

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

            Case tabletRequestToUpdate = new Case(Id = tabletRequestCase.Id, 
                                                    Status = CDdMxSxConstants.CASE_STATUS_RECEIVED, 
                                                    Tablet_Received_Date_2__c = System.now(),
                                                    Tablet_Serial_Number__c = TEST_IDENTIFIER_TABLET,
                                                    Printer_IMEI__c = TEST_IDENTIFIER_PRINTER
                                                );
            update tabletRequestToUpdate;
            Test.getEventBus().deliver();            
           
            Test.startTest();
            Mx_Order__c mxOrderToUpdate = [SELECT Id, Order_Status__c FROM Mx_Order__c WHERE Id = :mxOrder.Id LIMIT 1];
            mxOrderToUpdate.Order_Id__c = '12345678';
            mxOrderToUpdate.Order_Status__c = null;
            update mxOrderToUpdate;            
            CDdMxSupportEventBatch supportBatch = new CDdMxSupportEventBatch(CDdMxSupportEventEnum.MX_ORDER_DELIVERED);
            Database.executeBatch(supportBatch, CDdMxSupportEventConfig.getBatchSize(CDdMxSupportEventEnum.MX_ORDER_DELIVERED));            
            Test.stopTest();

            Mx_Order__c mxOrderFromDB = [SELECT Id, Order_Status__c, (SELECT Id, Identifier__c, Product_Family__c FROM Mx_Order_Items__r) FROM Mx_Order__c WHERE Id = :mxOrder.Id LIMIT 1];
            System.assertEquals(true, mxOrderFromDB != null, 'Expecting a Mx Order record ');
            System.assertEquals(CDdMxSxConstants.MX_ORDER_STATUS_DELIVERED, mxOrderFromDB.Order_Status__c, 'Expecting Mx Order status ' + CDdMxSxConstants.MX_ORDER_STATUS_DELIVERED);
            Mx_Order_Item__c tabletItem = null;
            Mx_Order_Item__c printerItem = null;
            for (Mx_Order_Item__c item : mxOrderFromDB.Mx_Order_Items__r){
                if (CDdMxSxConstants.MX_PRODUCT_FAMILY_TABLET.equals(item.Product_Family__c)){
                    tabletItem = item;
                }
                if (CDdMxSxConstants.MX_PRODUCT_FAMILY_PRINTER.equals(item.Product_Family__c)){
                    printerItem = item;
                }                
            }
            System.assertEquals(true, tabletItem != null);
            System.assertEquals(TEST_IDENTIFIER_TABLET, tabletItem.Identifier__c);
            System.assertEquals(true, printerItem != null);
            System.assertEquals(TEST_IDENTIFIER_PRINTER, printerItem.Identifier__c);
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
        for (Case c :   [   SELECT Id, RecordTypeId
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
        if(doInsert)
           insert events;
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
    public static void insertEventConfig(){
            // Add mx support configuration
            Mx_Support_Event_Config__c eventConfig = new Mx_Support_Event_Config__c();
            eventConfig.Apex_Class__c = 'CDdMxSupportMxOrderDelivered';
            eventConfig.Batch_Size__c = 1;
            eventConfig.Event_Name__c = CDdMxSupportEventEnum.MX_ORDER_DELIVERED.name();
            eventConfig.Is_Active__c = true;
            eventConfig.Query_Last_N_Days__c = 10;
            eventConfig.Query_SObject_Type__c = 'Mx_Order__c';
            eventConfig.Sequence__c = 1;
            eventConfig.Query_Limit__c = 100;
            insert eventConfig;        
    }              
}