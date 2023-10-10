/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 05/03/2021
*
* @group Nimda S2N
*
* @description  Test class for Apex Helper Class CDdNimdaSyncStoreProductHelper
* 
**************************************************************************************************************************************/
@isTest
public class CDdNimdaSyncStoreProductHelperTest {
    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    public static final String TEST_STATIC_RESOURCE_NAME = 'SRDd_CPQ_S2N_TestData';
    public static final String TEST_CONFIG_KEY_PRODUCT_NAME = 'productName';
    public static final String TEST_CONFIG_KEY_IS_TRIAL = 'isTrial';
    public static final String TEST_CONFIG_KEY_QUOTE_LINE_FIELD_NAME = 'quoteLineFieldName';
    public static final String TEST_CONFIG_KEY_QUOTE_LINE_FIELD_VALUE = 'quoteLineFieldValue';
    public static final String TEST_CONFIG_KEY_ORDER_ITEM_FIELD_NAME = 'orderItemFieldName';
    public static final String TEST_CONFIG_KEY_ORDER_ITEM_FIELD_VALUE = 'orderItemFieldValue';
    public static final Map<String, Map<String, Object>> TEST_DD_CUSTOM_ID_CONFIG_DATA;
    static {
        TEST_ROLE_ID = [SELECT Id FROM UserRole WHERE DeveloperName = 'COO'].Id;
        StaticResource sr = [SELECT Body FROM StaticResource WHERE Name = :TEST_STATIC_RESOURCE_NAME LIMIT 1];
        Map<String, Object> srTestConfigData = (Map<String, Object>)JSON.deserializeUntyped(sr.Body.toString());
        TEST_DD_CUSTOM_ID_CONFIG_DATA = new Map<String, Map<String, Object>>();
        for (String ddCustomId : srTestConfigData.keySet()){
            String testDDCustomIdData = JSON.serialize(srTestConfigData.get(ddCustomId));
            TEST_DD_CUSTOM_ID_CONFIG_DATA.put(ddCustomId, (Map<String, Object>)JSON.deserializeUntyped(testDDCustomIdData));
        }
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
            insert account;
            
            Contact contact = TDdAccountFactory.createContacts(1, account.Id)[0];
            insert contact;
               
            Map<String, Product2> productForDDCustomId = new Map<String, Product2>();
            for(String ddCustomId : TEST_DD_CUSTOM_ID_CONFIG_DATA.keySet()){
                Product2 product = TDdCPQTestDataFactory.createProduct(false); 
                product.Name = (String)TEST_DD_CUSTOM_ID_CONFIG_DATA.get(ddCustomId).get(TEST_CONFIG_KEY_PRODUCT_NAME); 
                product.DD_Custom_ID__c = ddCustomId;
                productForDDCustomId.put(ddCustomId, product);
            }   
            insert productForDDCustomId.values();
            
            Map<String, PricebookEntry> pbeForDDCustomId = new Map<String, PricebookEntry>();
            for(String ddCustomId : TEST_DD_CUSTOM_ID_CONFIG_DATA.keySet()){
                Product2 product = productForDDCustomId.get(ddCustomId);
                PricebookEntry pbe = TDdCPQTestDataFactory.createPriceBookEntry(product, 'USD', false);
                pbeForDDCustomId.put(product.DD_Custom_ID__c, pbe);
            }
            insert pbeForDDCustomId.values();
            
            List<Opportunity> oppList = new List<Opportunity>();
            
            Opportunity opp = TDdOpportunityFactory.createOpportunityByDevRT('Opp', account.Id, contact.Id, 'Closed Won', 'ML_Inside_Sales');
            opp.Commission__c = 15;
            opp.In_App_Pickup_Commission__c = 15;
            opp.DashPass_Only_Commission__c = 15;
            opp.Referred_Delivery_Commission__c = 15;
            opp.Referred_Pickup_Commission__c = 15;
            opp.Weekly_Printer_Subscription_Fee__c = '$0';
            opp.Activation_Fee__c = '$0';
            opp.Weekly_Tablet_Subscription_Fee__c = '$3';
            opp.PactSafe_Contract_Type__c = 'English Sign Up Sheet';
            //insert opp;  
            oppList.add(opp);
            

            Opportunity legacyOpp = TDdOpportunityFactory.createOpportunityByDevRT('Opp', account.Id, contact.Id, 'Closed Won', 'ML_Inside_Sales');
            legacyOpp.Commission__c = 15;
            legacyOpp.Platform__c = 'Caviar and DoorDash';
            legacyOpp.In_App_Pickup_Commission__c = 15;
            legacyOpp.DashPass_Only_Commission__c = 15;
            legacyOpp.Referred_Delivery_Commission__c = 15;
            legacyOpp.Referred_Pickup_Commission__c = 15;
            legacyOpp.Weekly_Printer_Subscription_Fee__c = '$0';
            legacyOpp.Activation_Fee__c = '$0';
            legacyOpp.Order_Service_Type__c = 'Pickup Only';
            legacyOpp.Order_Service_Type__c = 'Pickup Only';
            legacyOpp.Weekly_Tablet_Subscription_Fee__c = '$3';
            legacyOpp.PactSafe_Contract_Type__c = 'English Sign Up Sheet';
            //insert legacyOpp; 
            oppList.add(legacyOpp); 
            
            Opportunity trialOpp = TDdOpportunityFactory.createOpportunityByDevRT('Opp', account.Id, contact.Id, 'Closed Won', 'ML_Inside_Sales');
            trialOpp.Commission__c = 15;
            trialOpp.Trial_Type__c = 'Promotional Period';
            trialOpp.Length_of_Trial__c = '14 Days';
            trialOpp.Trial_Commission__c = 0;
            trialOpp.Platform__c = 'Caviar and DoorDash';
            trialOpp.In_App_Pickup_Commission__c = 15;
            trialOpp.DashPass_Only_Commission__c = 15;
            trialOpp.Referred_Delivery_Commission__c = 15;
            trialOpp.Referred_Pickup_Commission__c = 15;
            trialOpp.Weekly_Printer_Subscription_Fee__c = '$0';
            trialOpp.Activation_Fee__c = '$0';
            trialOpp.Order_Service_Type__c = 'Pickup Only';
            trialOpp.Order_Service_Type__c = 'Pickup Only';
            trialOpp.Weekly_Tablet_Subscription_Fee__c = '$3';
            trialOpp.PactSafe_Contract_Type__c = 'English Sign Up Sheet';
            //insert legacyOpp;  
            oppList.add(trialOpp); 
            
          	insert oppList;
            
            SBQQ__Quote__c quote = TDdCPQTestDataFactory.createQuote(opp, account, contact, false);
            quote.SBQQ__StartDate__c = Date.today().addDays(-30);
            quote.PactSafe_Contract_Type__c = '';      
            insert quote;  
            
            oppList[0].SBQQ__PrimaryQuote__c = quote.Id;
            update oppList[0];            
            
            Test.stopTest();  

            SBQQ.TriggerControl.disable();
            Map<String, SBQQ__QuoteLine__c> quoteLineForDDCustomId = new Map<String, SBQQ__QuoteLine__c>();
            for(String ddCustomId : TEST_DD_CUSTOM_ID_CONFIG_DATA.keySet()){
                Product2 product = productForDDCustomId.get(ddCustomId);
                Boolean isTrialConfig = (Boolean)TEST_DD_CUSTOM_ID_CONFIG_DATA.get(ddCustomId).get(TEST_CONFIG_KEY_IS_TRIAL);
                SBQQ__QuoteLine__c quoteLine = TDdCPQTestDataFactory.createQuoteLine(product, quote, false);
                if (isTrialConfig){
                    quoteLine.Trial_Period__c = '60';
                }
                String fieldName = (String)TEST_DD_CUSTOM_ID_CONFIG_DATA.get(ddCustomId).get(TEST_CONFIG_KEY_QUOTE_LINE_FIELD_NAME);
                Object fieldvalue = (Object)TEST_DD_CUSTOM_ID_CONFIG_DATA.get(ddCustomId).get(TEST_CONFIG_KEY_QUOTE_LINE_FIELD_VALUE);
                if (fieldName!=null && fieldvalue!=null){
                    quoteLine.put(fieldName, fieldvalue);
                }
                quoteLine.SBQQ__PricebookEntryId__c = pbeForDDCustomId.get(ddCustomId).Id;
                quoteLineForDDCustomId.put(ddCustomId, quoteLine);
            }  
            insert quoteLineForDDCustomId.values();
            SBQQ.TriggerControl.enable();

            Order order = TDdCPQTestDataFactory.createOrder(account, opp, quote, false);
            order.EffectiveDate = Date.today();
            order.EndDate = null;
            insert order;
            
            Map<String, OrderItem> orderItemForDDCustomId = new Map<String, OrderItem>();
            for(String ddCustomId : TEST_DD_CUSTOM_ID_CONFIG_DATA.keySet()){
                SBQQ__QuoteLine__c quoteLine = quoteLineForDDCustomId.get(ddCustomId);
                PricebookEntry pricebookEntry = pbeForDDCustomId.get(ddCustomId);
                OrderItem orderItem = TDdCPQTestDataFactory.createOrderItem(
                                                order,
                                                quoteLine, 
                                                pricebookEntry.Id, 
                                                false);
                String fieldName = (String)TEST_DD_CUSTOM_ID_CONFIG_DATA.get(ddCustomId).get(TEST_CONFIG_KEY_ORDER_ITEM_FIELD_NAME);
                Object fieldvalue = (Object)TEST_DD_CUSTOM_ID_CONFIG_DATA.get(ddCustomId).get(TEST_CONFIG_KEY_ORDER_ITEM_FIELD_VALUE);
                if (fieldName!=null && fieldvalue!=null){
                    orderItem.put(fieldName, fieldvalue);
                }                
                orderItem.PricebookEntryId = pricebookEntry.Id;
                orderItemForDDCustomId.put(ddCustomId, orderItem);
            }  
            insert orderItemForDDCustomId.values();
            
        }
    }    
   /** 
    * @description Test method convertToAPIType
    */
    @isTest
    public static void testGetStoreProductData() {
        System.runAs (getTestRunUser()) {
            Test.startTest();
            List<Id> opportunityIds = new List<Id>();
            for (Opportunity opportunity : [SELECT Id FROM Opportunity where SBQQ__PrimaryQuote__c != null]){
                opportunityIds.add(opportunity.Id);
            }
            CDdNimdaSyncStoreProductHelper helper = new CDdNimdaSyncStoreProductHelper(new Set<Id>(opportunityIds));
            Map<Id, Map<String, Object>> storeProductData = helper.getStoreProductData();
            System.assertEquals(true, !storeProductData.isEmpty());
        
            CDdRestJSONObj.DoorstepStoreRequest storeRequest = (CDdRestJSONObj.DoorstepStoreRequest)JSON.deserialize(
                                                                JSON.serialize(storeProductData.get(opportunityIds.get(0))), 
                                                                CDdRestJSONObj.DoorstepStoreRequest.class
                                                            );
            System.assertEquals(25.50, storeRequest.commission_rate);
            System.assertEquals(12.50, storeRequest.service_rate);
            System.assertEquals('true', storeRequest.offers_pickup);
            System.assertEquals('true', storeRequest.offers_delivery);
            System.assertEquals('13.00', storeRequest.subscription_commission);
            System.assertEquals(null, storeRequest.dash_pass_marketing_fee);
            System.assertEquals('18.00', storeRequest.activation_fee);                                                              
            Test.stopTest();
        }
    }
	@isTest
    public static void testGetStoreProductDataforLegacyOpp() {
        System.runAs (getTestRunUser()) {
            Test.startTest();
            List<Id> opportunityIds = new List<Id>();
            for (Opportunity opportunity : [SELECT Id FROM Opportunity where SBQQ__PrimaryQuote__c = null]){
                opportunityIds.add(opportunity.Id);
            }
            TDdOpportunityLineItemFactory.createProducts();
            List<OpportunityLineItem> products = TDdOpportunityLineItemFactory.createOpportunityProducts(opportunityIds[0]);
            insert products;     
            CDdNimdaSyncStoreProductHelper helper = new CDdNimdaSyncStoreProductHelper(new Set<Id>(opportunityIds));
            Map<Id, Map<String, Object>> storeProductData = helper.getStoreProductData();
            System.assertEquals(true, !storeProductData.isEmpty());
        
            CDdRestJSONObj.DoorstepStoreRequest storeRequest = (CDdRestJSONObj.DoorstepStoreRequest)JSON.deserialize(
                                                                JSON.serialize(storeProductData.get(opportunityIds.get(0))), 
                                                                CDdRestJSONObj.DoorstepStoreRequest.class
                                                            );
            System.assertEquals(15.00, storeRequest.commission_rate);
            System.assertEquals(10.00, storeRequest.service_rate);
            System.assertEquals('true', storeRequest.offers_pickup);
            System.assertEquals('false', storeRequest.offers_delivery);
            System.assertEquals('15.00', storeRequest.subscription_commission);
            System.assertEquals(null, storeRequest.dash_pass_marketing_fee);
            System.assertEquals('0', storeRequest.activation_fee);                                                              
            Test.stopTest();
        }
    }
    @isTest
    public static void testGetStoreProductDataforTrialOpp() {
        System.runAs (getTestRunUser()) {
            Test.startTest();
            List<Id> opportunityIds = new List<Id>();
            for (Opportunity opportunity : [SELECT Id FROM Opportunity where Trial_Type__c != null]){
                opportunityIds.add(opportunity.Id);
            }
            CDdNimdaSyncStoreProductHelper helper = new CDdNimdaSyncStoreProductHelper(new Set<Id>(opportunityIds));
            Map<Id, Map<String, Object>> storeProductData = helper.getStoreProductData();
            Boolean isTrial = helper.isTrialOpp();
            System.assertEquals(true, !storeProductData.isEmpty());
            System.assertEquals(true, isTrial);
        
            CDdRestJSONObj.DoorstepStoreRequest storeRequest = (CDdRestJSONObj.DoorstepStoreRequest)JSON.deserialize(
                                                                JSON.serialize(storeProductData.get(opportunityIds.get(0))), 
                                                                CDdRestJSONObj.DoorstepStoreRequest.class
                                                            );
            System.assertEquals(0.00, storeRequest.commission_rate);
            System.assertEquals(10.00, storeRequest.service_rate);
            System.assertEquals('true', storeRequest.offers_pickup);
            System.assertEquals('false', storeRequest.offers_delivery);
            System.assertEquals('0.00', storeRequest.subscription_commission);
            System.assertEquals(null, storeRequest.dash_pass_marketing_fee);
            System.assertEquals('0', storeRequest.activation_fee);                                                              
            Test.stopTest();
        }
    }
}