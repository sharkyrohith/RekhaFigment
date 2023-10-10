/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 05/21/2021
*
* @group Fee Onboarding
*
* @description  Test class for Fee Onboarding CPQ
* 
**************************************************************************************************************************************/
@isTest
public class CDdFeeOnboardingCPQTest {
    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    public static final String TEST_OPP_PACTSAFE_CONTRACT_TYPE = 'English Sign Up Sheet';
    public static final String TEST_STATIC_RESOURCE_NAME = 'SRDd_CPQ_FeeOnboarding_TestData';
    public static final String TEST_CONFIG_KEY_PRODUCT_NAME = 'productName';
    public static final String TEST_CONFIG_KEY_PACKAGE_NAME = 'packageName';
    public static final String TEST_CONFIG_KEY_PLATFORM = 'platform';
    public static final String TEST_CONFIG_KEY_IS_TRIAL = 'isTrial';
    public static final String TEST_CONFIG_KEY_QUOTE_LINE_FIELD_NAME = 'quoteLineFieldName';
    public static final String TEST_CONFIG_KEY_QUOTE_LINE_FIELD_VALUE = 'quoteLineFieldValue';
    public static final String TEST_CONFIG_KEY_ORDER_ITEM_FIELD_NAME = 'orderItemFieldName';
    public static final String TEST_CONFIG_KEY_ORDER_ITEM_FIELD_VALUE = 'orderItemFieldValue';
    public static final String TEST_STOREFRONT_PACKAGE_DD_CUSTOM_ID = 'MKTPKG-0000109';
    public static final Set<String> TEST_STOREFRONT_PRODUCT_DD_CUSTOM_IDS = new Set<String>{'MKTPL-0000127','MKTPL-0000141','MKTPL-0000142','MKTPL-0000144','MKTPL-0000145','MKTPL-0000151','MKTPL-0000156'};
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
                product.Package_Name__c = (String)TEST_DD_CUSTOM_ID_CONFIG_DATA.get(ddCustomId).get(TEST_CONFIG_KEY_PACKAGE_NAME); 
                product.Platform__c = (String)TEST_DD_CUSTOM_ID_CONFIG_DATA.get(ddCustomId).get(TEST_CONFIG_KEY_PLATFORM);  
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
            
            Opportunity opp = TDdOpportunityFactory.createOpportunityByDevRT('Opp', account.Id, contact.Id, 'Closed Won', 'ML_Inside_Sales');
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
            // Get package product and price book entry
            Product2 packageProduct = [SELECT Id FROM Product2 WHERE DD_Custom_ID__c = :TEST_STOREFRONT_PACKAGE_DD_CUSTOM_ID LIMIT 1];
            PricebookEntry packagePricebookEntry = pbeForDDCustomId.get(TEST_STOREFRONT_PACKAGE_DD_CUSTOM_ID);            
            // Create storefront package quote line - BEGIN 
            SBQQ__QuoteLine__c packageQuoteLine = TDdCPQTestDataFactory.createQuoteLine(packageProduct, quote, false);
            packageQuoteLine.SBQQ__PricebookEntryId__c = packagePricebookEntry.Id;
            insert packageQuoteLine;
            // Create storefront package quote line - END
            // Create non-package quote lines - BEGIN
            Map<String, SBQQ__QuoteLine__c> quoteLineForDDCustomId = new Map<String, SBQQ__QuoteLine__c>();
            for(String ddCustomId : TEST_DD_CUSTOM_ID_CONFIG_DATA.keySet()){
                if (!TEST_STOREFRONT_PACKAGE_DD_CUSTOM_ID.equals(ddCustomId)){
                    Product2 product = productForDDCustomId.get(ddCustomId);
                    Boolean isTrialConfig = (Boolean)TEST_DD_CUSTOM_ID_CONFIG_DATA.get(ddCustomId).get(TEST_CONFIG_KEY_IS_TRIAL);
                    SBQQ__QuoteLine__c quoteLine = TDdCPQTestDataFactory.createQuoteLine(product, quote, false);
                    if (isTrialConfig){
                        quoteLine.Trial_Period__c = '60';
                    }
                    //quoteLine.SBQQ__NetPrice__c = null;
                    String fieldName = (String)TEST_DD_CUSTOM_ID_CONFIG_DATA.get(ddCustomId).get(TEST_CONFIG_KEY_QUOTE_LINE_FIELD_NAME);
                    Object fieldvalue = (Object)TEST_DD_CUSTOM_ID_CONFIG_DATA.get(ddCustomId).get(TEST_CONFIG_KEY_QUOTE_LINE_FIELD_VALUE);
                    if (fieldName!=null && fieldvalue!=null){
                        quoteLine.put(fieldName, fieldvalue);
                    }
                    quoteLine.SBQQ__PricebookEntryId__c = pbeForDDCustomId.get(ddCustomId).Id;
                    // Add package quote line reference to quote lines with storefront products 
                    if (TEST_STOREFRONT_PRODUCT_DD_CUSTOM_IDS.contains(ddCustomId)){
                        quoteLine.SBQQ__RequiredBy__c = packageQuoteLine.Id;
                    }
                    quoteLineForDDCustomId.put(ddCustomId, quoteLine);
                }
            }
            // Create non-package quote lines - END  
            insert quoteLineForDDCustomId.values();
            // add store front package quote line
            quoteLineForDDCustomId.put(TEST_STOREFRONT_PACKAGE_DD_CUSTOM_ID, packageQuoteLine);
            SBQQ.TriggerControl.enable();

            Order order = TDdCPQTestDataFactory.createOrder(account, opp, quote, false);
            order.EffectiveDate = Date.today();
            order.EndDate = null;
            insert order;

            // Create storefront package order item - BEGIN 
            OrderItem packageOrderItem = TDdCPQTestDataFactory.createOrderItem(
                                            order,
                                            quoteLineForDDCustomId.get(TEST_STOREFRONT_PACKAGE_DD_CUSTOM_ID), 
                                            packagePricebookEntry.Id, 
                                            false);
            packageOrderItem.PricebookEntryId = packagePricebookEntry.Id;
            insert packageOrderItem;
            // Create storefront package order item - END            
            
            Map<String, OrderItem> orderItemForDDCustomId = new Map<String, OrderItem>();
            for(String ddCustomId : TEST_DD_CUSTOM_ID_CONFIG_DATA.keySet()){
                if (!TEST_STOREFRONT_PACKAGE_DD_CUSTOM_ID.equals(ddCustomId)){
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
                    // Add package order item reference to order items with storefront products 
                    if (TEST_STOREFRONT_PRODUCT_DD_CUSTOM_IDS.contains(ddCustomId)){
                        orderItem.SBQQ__RequiredBy__c = packageOrderItem.Id;
                    }                    
                    orderItemForDDCustomId.put(ddCustomId, orderItem);
                }
            }  
            insert orderItemForDDCustomId.values();
            // add store front package quote line
            orderItemForDDCustomId.put(TEST_STOREFRONT_PACKAGE_DD_CUSTOM_ID, packageOrderItem);            
        }
    }
   /** 
    * @description Test Get Program Objects
    */
    @isTest
    public static void testGetProgramObjects() {
        System.runAs (getTestRunUser()) {
            Test.startTest();
            List<CDdFeeOnboardingProgramObject> programObjects = getProgramObjects();
            System.assertEquals(true, !programObjects.isEmpty());
            //Test Product Record are created with help of test static resource SRDd_CPQ_FeeOnboarding_TestData.json. As we did changes in this file that's why updating the same in below assert
            //System.assertEquals(6, programObjects.size());  7/12/2022 commenting this assert statement as this code is no longer in use and will be deprecated
            Test.stopTest();
        }
    }
   /** 
    * @description Test Fee Onboarding API Service
    */
    @isTest
    public static void testFeeOnboardingAPIService() {
        System.runAs (getTestRunUser()) {
            Test.startTest();
            List<CDdFeeOnboardingProgramObject> programObjects = getProgramObjects();
            CDdFeeOnboardingAPIServiceInterface apiService = new CDdFeeOnboardingApiService();
            apiService.addRequests(programObjects);
            System.assertEquals(true, apiService.hasRequests());
            System.assertEquals(true, apiService.hasRequest(CDdFeeOnboardingApiType.MX_PROGRAM_FEE));
            //System.assertEquals(true, apiService.hasRequest(CDdFeeOnboardingApiType.CX_STOREFRONT_FEE));   7/12/2022 commenting this assert statement as this code is no longer in use and will be deprecated
            Test.stopTest();
        }
    }    
    /**
     * @description Get the program objects for the inserted test data
     * Expecting 7 programs are eligible
     * Expected - 2 programs are not eligible - Marketplace Pickup, Marketplace Weblinks - Pickup
     * @param -
     * @return List<CDdFeeOnboardingProgramObject> collection of program objects
     */
    private static List<CDdFeeOnboardingProgramObject> getProgramObjects(){
        Id opportunityId = null;
        Id primaryQuoteId = null;
        for (Opportunity opportunity : [SELECT Id, SBQQ__PrimaryQuote__c FROM Opportunity LIMIT 1]){
            opportunityId = opportunity.Id;
            primaryQuoteId = opportunity.SBQQ__PrimaryQuote__c;
        }            
        return new CDdFeeOnboardingCPQService(opportunityId, primaryQuoteId).getProgramObjects();
    }    
}