/********************************************************************************************************************
* @author Sriram
* @date 10/08/2022
*
* @group fflib
*
* @description Merchant Services Apex Mock Test Data Factory
*
**************************************************************************************************************************************/
public class MxSxApexMockTestDataFactory {
    public static final Set<String> CPQ_PRODUCT_DD_CUSTOM_IDS;
    public static final String CPQ_CONFIG_KEY_PRODUCT_NAME = 'productName';
    public static final String CPQ_CONFIG_KEY_PACKAGE_NAME = 'packageName';
    public static final String CPQ_CONFIG_KEY_PLATFORM = 'platform';
    public static final String CPQ_CONFIG_KEY_IS_TRIAL = 'isTrial';
    public static final String CPQ_CONFIG_KEY_QUOTE_LINE_FIELD_NAME = 'quoteLineFieldName';
    public static final String CPQ_CONFIG_KEY_QUOTE_LINE_FIELD_VALUE = 'quoteLineFieldValue';
    public static final String CPQ_CONFIG_KEY_ORDER_ITEM_FIELD_NAME = 'orderItemFieldName';
    public static final String CPQ_CONFIG_KEY_ORDER_ITEM_FIELD_VALUE = 'orderItemFieldValue';
    public static final String CPQ_STOREFRONT_PACKAGE_DD_CUSTOM_ID = 'MKTPKG-0000109';
    public static final Set<String> CPQ_STOREFRONT_PRODUCT_DD_CUSTOM_IDS = new Set<String>{'MKTPL-0000127','MKTPL-0000141','MKTPL-0000142','MKTPL-0000144','MKTPL-0000145','MKTPL-0000151','MKTPL-0000156'};
    public static final Map<String, Map<String, Object>> CPQ_DD_CUSTOM_ID_CONFIG_DATA;
    public static Map<String, Object> CPQ_PRODUCT_CONFIG_DATA = (Map<String, Object>)JSON.deserializeUntyped('{"MKTPL-0000127":{"productName":"SaaS Fee", "packageName":"default", "platform":"DoorDash", "isTrial":false, "quoteLineFieldName":null, "quoteLineFieldValue":null, "orderItemFieldName":null, "orderItemFieldValue":null }, "MKTPL-0000135":{"productName":"Caviar Delivery", "packageName":"default", "platform":"Caviar", "isTrial":true, "quoteLineFieldName":"Trial_Commission__c", "quoteLineFieldValue":5, "orderItemFieldName":"Trial_Commission__c", "orderItemFieldValue":5 }, "MKTPL-0000138":{"productName":"Caviar Pickup", "packageName":"default", "platform":"Caviar", "isTrial":false, "quoteLineFieldName":null, "quoteLineFieldValue":null, "orderItemFieldName":null, "orderItemFieldValue":null }, "MKTPL-0000141":{"productName":"Pickup Fee - Storefront", "packageName":"default", "platform":"DoorDash", "isTrial":false, "quoteLineFieldName":"SBQQ__ListPrice__c", "quoteLineFieldValue":50, "orderItemFieldName":"UnitPrice", "orderItemFieldValue":50 }, "MKTPL-0000142":{"productName":"Payment Processing Fee", "packageName":"default", "platform":"DoorDash", "isTrial":false, "quoteLineFieldName":"SBQQ__ListPrice__c", "quoteLineFieldValue":25.50, "orderItemFieldName":"UnitPrice", "orderItemFieldValue":25.50 }, "MKTPL-0000144":{"productName":"Payment Processing Rate", "packageName":"default", "platform":"DoorDash", "isTrial":false, "quoteLineFieldName":"Final_Commission__c", "quoteLineFieldValue":30, "orderItemFieldName":"Final_Commission__c", "orderItemFieldValue":30 }, "MKTPL-0000145":{"productName":"Service Fee", "packageName":"default", "platform":"default", "isTrial":false, "quoteLineFieldName":null, "quoteLineFieldValue":null, "orderItemFieldName":null, "orderItemFieldValue":null }, "MKTPL-0000151":{"productName":"Cx Delivery Fee - Storefront", "packageName":"default", "platform":"DoorDash", "isTrial":false, "quoteLineFieldName":"SBQQ__ListPrice__c", "quoteLineFieldValue":15, "orderItemFieldName":"UnitPrice", "orderItemFieldValue":15 }, "MKTPL-0000154":{"productName":"Caviar DashPass", "packageName":"default", "platform":"Caviar", "isTrial":false, "quoteLineFieldName":null, "quoteLineFieldValue":null, "orderItemFieldName":null, "orderItemFieldValue":null }, "MKTPL-0000156":{"productName":"Mx Delivery Fee", "packageName":"default", "platform":"default", "isTrial":false, "quoteLineFieldName":null, "quoteLineFieldValue":null, "orderItemFieldName":null, "orderItemFieldValue":null }, "MKTPKG-0000109":{"productName":"Standard Storefront Package", "packageName":"Storefront", "platform":"DoorDash", "isTrial":false, "quoteLineFieldName":null, "quoteLineFieldValue":null, "orderItemFieldName":null, "orderItemFieldValue":null } }');
    public static final Map<String, Schema.RecordTypeInfo> CASE_RECORD_TYPE_INFO_BY_DEV_NAME = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName();
    public static final String[] SOBJECT_TYPE_STRINGS = new String[]{'SBQQ__QuoteLine__c', 'OrderItem'};
    public static Set<String> FIELD_TYPES_STRING = new Set<String>{Schema.DisplayType.String.name()
        , Schema.DisplayType.ID.name()
        , Schema.DisplayType.Picklist.name()
        , Schema.DisplayType.Email.name()};
    public static Set<String> FIELD_TYPES_NUMBER = new Set<String>{Schema.DisplayType.Double.name()
        , Schema.DisplayType.Integer.name()
        , Schema.DisplayType.Long.name()
        , Schema.DisplayType.Currency.name()
        , Schema.DisplayType.Percent.name()};
    public static Set<String> FIELD_TYPES_BOOLEAN = new Set<String>{Schema.DisplayType.boolean.name()};
    public static final Map<String, Schema.DescribeSObjectResult> DESCRIBE_SOBJECT_RESULT_BY_SOBJECT_TYPE_STRING;
    static {
        CPQ_PRODUCT_DD_CUSTOM_IDS = new Set<String>();
        CPQ_DD_CUSTOM_ID_CONFIG_DATA = new Map<String, Map<String, Object>>();
        for (String ddCustomId : CPQ_PRODUCT_CONFIG_DATA.keySet()){
            CPQ_PRODUCT_DD_CUSTOM_IDS.add(ddCustomId);
            String cpqProductDDCustomIdData = JSON.serialize(CPQ_PRODUCT_CONFIG_DATA.get(ddCustomId));
            CPQ_DD_CUSTOM_ID_CONFIG_DATA.put(ddCustomId, (Map<String, Object>)JSON.deserializeUntyped(cpqProductDDCustomIdData));
        }
        Schema.DescribeSObjectResult[] descResult = Schema.describeSObjects(SOBJECT_TYPE_STRINGS);
        DESCRIBE_SOBJECT_RESULT_BY_SOBJECT_TYPE_STRING = new Map<String, Schema.DescribeSObjectResult>();
        for (Integer i=0; i<SOBJECT_TYPE_STRINGS.size(); i++){
            DESCRIBE_SOBJECT_RESULT_BY_SOBJECT_TYPE_STRING.put(SOBJECT_TYPE_STRINGS.get(i), descResult[i]);
        }
    }
    /**
     * Instance variables definitions begin here
     */
    public Submarket__c submarket  {
        get {
            if (this.submarket == null){
                this.setSubmarket();
            }
            return this.submarket;
        }
        set;
    }
    public RealZip__RealZips__c realZip  {
        get {
            if (this.realZip == null){
                this.setRealZip();
            }
            return this.realZip;
        }
        set;
    }
    public User selfServeUser  {
        get {
            if (this.selfServeUser == null){
                this.setSelfServeUser();
            }
            return this.selfServeUser;
        }
        set;
    }
    public Account grandparentAccount  {
        get {
            if (this.grandparentAccount == null){
                this.setGrandparentAccount();
            }
            return this.grandparentAccount;
        }
        set;
    }
    public Account parentAccount  {
        get {
            if (this.parentAccount == null){
                this.setParentAccount();
            }
            return this.parentAccount;
        }
        set;
    }
    public Account marketplaceAccount  {
        get {
            if (this.marketplaceAccount == null){
                this.setMarketplaceAccount();
            }
            return this.marketplaceAccount;
        }
        set;
    }
    public Contact decisionMaker  {
        get {
            if (this.decisionMaker == null){
                this.setDecisionMaker();
            }
            return this.decisionMaker;
        }
        private set;
    }
    public Opportunity marketplaceOpportunity {
        get {
            if (this.marketplaceOpportunity == null){
                this.setMarketplaceOpportunity();
            }
            return this.marketplaceOpportunity;
        }
        set;
    }
    public Case storefrontOnboardingCase {
        get {
            if (this.storefrontOnboardingCase == null){
                this.setStorefrontOnboardingCase();
            }
            return this.storefrontOnboardingCase;
        }
        set;
    }
    public Case marketplaceOnboardingCase {
        get {
            if (this.marketplaceOnboardingCase == null){
                this.setMarketplaceOnboardingCase();
            }
            return this.marketplaceOnboardingCase;
        }
        set;
    }
    public Case posIntegrationCase {
        get {
            if (this.posIntegrationCase == null){
                this.setPosIntegrationCase();
            }
            return this.posIntegrationCase;
        }
        set;
    }
    public Case caviarOnboardingCase {
        get {
            if (this.caviarOnboardingCase == null){
                this.setCaviarOnboardingCase();
            }
            return this.caviarOnboardingCase;
        }
        set;
    }
    public SBQQ__Quote__c primaryQuote {
        get {
            if (this.primaryQuote == null){
                this.setPrimaryQuote();
            }
            return this.primaryQuote;
        }
        set;
    }
    public List<SBQQ__QuoteLine__c> primaryQuoteLines {
        get {
            if (this.primaryQuoteLines == null){
                this.setPrimaryQuoteLines();
            }
            return this.primaryQuoteLines;
        }
        set;
    }
    public Order marketplaceOrder {
        get {
            if (this.marketplaceOrder == null){
                this.setMarketplaceOrder();
            }
            return this.marketplaceOrder;
        }
        set;
    }
    public List<OrderItem> marketplaceOrderItems {
        get {
            if (this.marketplaceOrderItems == null){
                this.setMarketplaceOrderItems();
            }
            return this.marketplaceOrderItems;
        }
        set;
    }
    public PriceBook2 pricebook {
        get {
            if (this.pricebook == null){
                this.setPricebook();
            }
            return this.pricebook;
        }
        set;
    }
    public List<Product2> products {
        get {
            if (this.products == null){
                this.setProducts();
            }
            return this.products;
        }
        set;
    }
    public List<PricebookEntry> pricebookEntries {
        get {
            if (this.pricebookEntries == null){
                this.setPricebookEntries();
            }
            return this.pricebookEntries;
        }
        set;
    }
    public List<Integration_Request__x> posIntegrationRequests {
        get {
            if (this.PosIntegrationRequests == null){
                this.setPosIntegrationRequests();
            }
            return this.PosIntegrationRequests;
        }
        set;
    }
    /**
     * Instance variables definitions end here
     */
    public void setSubmarket(){
        this.submarket = new Submarket__c(
            Id = fflib_IDGenerator.generate(Submarket__c.getSObjectType()),
            Name = 'New York',
            Region__c = 'NEW YORK',
            NP_Service_Fee__c = null,
            Service_Fee__c = 10
        );
    }
    public void setRealZip(){
        this.realZip = new RealZip__RealZips__c(
            Id = fflib_IDGenerator.generate(RealZip__RealZips__c.getSObjectType()),
            Submarket_lookup__c = this.submarket.Id
        );
    }
    public void setSelfServeUser(){
        User u = new User(
            Id = fflib_IDGenerator.generate(User.getSObjectType()),
            FirstName = 'Self-Serve',
            LastName = 'Integration User',
            Email = 'mx-eng-api@doordash.com',
            Username = 'selfserve@doordash.com'
        );
        this.selfServeUser = (User)fflib_ApexMocksUtils.setReadOnlyFields(
            u,
            User.class,
            new Map<SObjectField, Object> { User.Name => 'Self-Serve Integration User' }
        );
    }
    public void setGrandparentAccount() {
        this.grandparentAccount = new Account(
            Id = fflib_IDGenerator.generate(Account.getSObjectType()),
            RecordTypeId = CDdSchemaUtils.ACCOUNT_RT.parentAccountId(),
            BillingStreet = getRandomInteger() + ' Mulberry Ln',
            BillingCity = 'South San Francisco',
            BillingState = 'CA',
            BillingCountryCode = 'US',
            BillingCountry = 'United States',
            Phone = String.valueOf(getRandomInteger(10)),
            BillingPostalCode = '95689',
            Legal_Business_Name__c = 'Easy Pizza',
            Business_Id__c = 1225555,
            Deck_Rank__c = 'Jack'
        );
    }
    public void setParentAccount() {
        this.parentAccount = new Account(
            Id = fflib_IDGenerator.generate(Account.getSObjectType()),
            RecordTypeId = CDdSchemaUtils.ACCOUNT_RT.parentAccountId(),
            ParentId = this.grandparentAccount.Id,
            Parent = this.grandparentAccount,
            BillingStreet = getRandomInteger() + ' Mulberry Ln',
            BillingCity = 'South San Francisco',
            BillingState = 'CA',
            BillingCountryCode = 'US',
            BillingCountry = 'United States',
            Phone = String.valueOf(getRandomInteger(10)),
            BillingPostalCode = '95689',
            Legal_Business_Name__c = 'Easy Pizza',
            Business_Id__c = 1224444,
            Deck_Rank__c = 'Jack'
        );
    }
    public void setMarketplaceAccount() {
        this.marketplaceAccount = new Account(
            Id = fflib_IDGenerator.generate(Account.getSObjectType()),
            RecordTypeId = CDdSchemaUtils.ACCOUNT_RT.prospectId(),
            ParentId = this.parentAccount.Id,
            Parent = this.parentAccount,
            BillingStreet = getRandomInteger() + ' Mulberry Ln',
            BillingCity = 'South San Francisco',
            BillingState = 'CA',
            Restaurant_ID__c = '224455',
            BillingCountryCode = 'US',
            BillingCountry = 'United States',
            Phone = String.valueOf(getRandomInteger(10)),
            BillingPostalCode = '95689',
            Bank_Account_Number_Encrypted__c = '123456789',
            Bank_Routing_Number_Encrypted__c = '123456789',
            EIN_Encrypted__c = '123456789',
            Legal_Business_Name__c = 'Easy Pizza',
            RealZip__RealZip__c = this.realZip.Id,
            Is_Test_Store__c = false
        );
    }
    public void setMarketplaceOpportunity() {
        Opportunity opp = this.marketplaceOpportunity = new Opportunity(
            Id = fflib_IDGenerator.generate(Opportunity.getSObjectType()),
            RecordTypeId = CDdSchemaUtils.OPPORTUNITY_RT.mlInsideSalesId(),
            AccountId = this.marketplaceAccount.Id,
            Account = this.marketplaceAccount,
            Name = 'Test CPQ Closed One Opportunity',
            StageName = 'Closed Won',
            CloseDate = System.Date.today(),
            Menu_to_be_completed_by__c = 'DoorDash Onboarding Team',
            Mx_Marketing_Request_created__c = false,
            of_Addressable_Locations__c = 1,
            PactSafe_Contract_Type__c = 'English Sign Up Sheet',
            PactSafe_Record__c = 'https://app.pactsafe.com/PacksafeURL',
            Region_Type__c = 'Live Region',
            Tablet_Delivery_Method__c = 'Drop-ship',
            Tablet_Kit_Type__c = 'Standard',
            Type = 'New Partner',
            Activate_Centrally_2__c = 'Yes',
            Decision_Maker__c = this.decisionMaker.Id,
            Store_Manager__c = this.decisionMaker.Id,
            Hours_of_Operation__c = 'test',
            Legal_Entity__c = 'US',
            Menu_Has_Been_Provided__c = true,
            Menu_URL__c = 'https://test.doordas.com/menu_url',
            Order_Protocol__c = 'POS and and Tablet (DoorDash Owns)',
            Proposed_Date_of_Activation__c = System.today().addDays(20),
            Proposed_Date_of_Menu__c = System.today().addDays(10),
            Menu_Setup_Method__c  = 'Create New Menu(s) using Menu Source',
            Commission__c = 15,
            In_App_Pickup_Commission__c = 15,
            DashPass_Only_Commission__c = 15,
            Referred_Delivery_Commission__c = 15,
            Referred_Pickup_Commission__c = 15,
            Weekly_Printer_Subscription_Fee__c = '$0',
            Activation_Fee__c = '$0',
            Weekly_Tablet_Subscription_Fee__c = '$3'
        );
        opp.SBQQ__PrimaryQuote__c = this.primaryQuote.Id;
        opp.SBQQ__PrimaryQuote__r = this.primaryQuote;
        Opportunity opp1 = (Opportunity)fflib_ApexMocksUtils.setReadOnlyFields(
            opp,
            Opportunity.class,
            new Map<SObjectField, Object> { Opportunity.CreatedById => this.selfServeUser.Id }
        );
        this.marketplaceOpportunity = ((List<Opportunity>)fflib_ApexMocksUtils.makeRelationship(
            List<Opportunity>.class,
            new List<Opportunity>{ opp1 },
            Case.Opportunity_Name__c,
            new List<List<Case>>{new List<Case>{ this.storefrontOnboardingCase }}
        ))[0];
    }
    public void setDecisionMaker() {
        Integer randomInteger = 123;
        this.decisionMaker = new Contact(
            Id = fflib_IDGenerator.generate(Contact.getSObjectType()),
            AccountId = this.marketplaceAccount.Id,
            firstName = 'TestFn'+ randomInteger,
            LastName = 'TestLn'+ randomInteger,
            Email = 'testfnln'+ randomInteger +'@test.com',
            Birthdate = Date.newInstance(1991, 9, 29)
        );
    }
    public void setStorefrontOnboardingCase() {
        Product2 storefrontPackageProduct = getStorefrontPackageProduct();
        OrderItem storefrontPackageProductOrderItem  = getStorefrontPackageProductOrderItem();
        this.storefrontOnboardingCase = new Case(
            Id = fflib_IDGenerator.generate(Case.getSObjectType()),
            RecordTypeId = CASE_RECORD_TYPE_INFO_BY_DEV_NAME.get('Storefront_Onboarding').getRecordTypeId(),
            AccountId = this.parentAccount.Id,
            Account = this.parentAccount,
            ContactId = this.decisionMaker.Id,
            Contact = this.decisionMaker,
            Decision_Maker__c = this.decisionMaker.Id,
            Opportunity_Name__c = this.marketplaceOpportunity.Id,
            Origin = 'Closed Won Opportunity',
            Stage__c = 'Not Started',
            Status = 'Open',
            ProductId = storefrontPackageProduct.Id,
            Product_Family_Text__c = storefrontPackageProduct.Family,
            Product_Name_Text__c = storefrontPackageProduct.Name,
            Order_Product__c = (storefrontPackageProductOrderItem != null ? storefrontPackageProductOrderItem.Id : null),
            OwnerId = CDdMxSxConstants.QUEUE_ID_STOREFRONT_CASE_HOLDING_QUEUE,
            Date_Time_Case_Became_Workable__c = System.now()
        );
    }
    public void setMarketplaceOnboardingCase() {
        this.marketplaceOnboardingCase = new Case(
            Id = fflib_IDGenerator.generate(Case.getSObjectType()),
            RecordTypeId = CASE_RECORD_TYPE_INFO_BY_DEV_NAME.get('Marketplace_Onboarding').getRecordTypeId(),
            AccountId = this.marketplaceAccount.Id,
            Account = this.marketplaceAccount,
            ContactId = this.decisionMaker.Id,
            Contact = this.decisionMaker,
            Decision_Maker__c = this.decisionMaker.Id,
            Opportunity_Name__c = this.marketplaceOpportunity.Id,
            Origin = 'Closed Won Opportunity',
            Stage__c = 'Not Started',
            Status = 'Open',
            Date_Time_Case_Became_Workable__c = System.now()
        );
    }
    public void setPosIntegrationCase() {
        this.posIntegrationCase = new Case(
            Id = fflib_IDGenerator.generate(Case.getSObjectType()),
            RecordTypeId = CASE_RECORD_TYPE_INFO_BY_DEV_NAME.get('POS_Integrations').getRecordTypeId(),
            AccountId = this.marketplaceAccount.Id,
            Account = this.marketplaceAccount,
            ContactId = this.decisionMaker.Id,
            Contact = this.decisionMaker,
            Decision_Maker__c = this.decisionMaker.Id,
            Opportunity_Name__c = this.marketplaceOpportunity.Id,
            Origin = 'Closed Won Opportunity',
            Stage__c = 'Not Started',
            Status = 'Open',
            POS_Integration_Type__c = 'SquareUp',
            POS_Integration_ID__c = '12345667',
            Date_Time_Case_Became_Workable__c = System.now()
        );
    }
    public void setCaviarOnboardingCase() {
        this.caviarOnboardingCase = new Case(
            Id = fflib_IDGenerator.generate(Case.getSObjectType()),
            RecordTypeId = CASE_RECORD_TYPE_INFO_BY_DEV_NAME.get('Caviar_Onboarding').getRecordTypeId(),
            AccountId = this.marketplaceAccount.Id,
            Account = this.marketplaceAccount,
            ContactId = this.decisionMaker.Id,
            Contact = this.decisionMaker,
            Decision_Maker__c = this.decisionMaker.Id,
            Opportunity_Name__c = this.marketplaceOpportunity.Id,
            Origin = 'Closed Won Opportunity',
            Stage__c = 'Not Started',
            Status = 'Open',
            Date_Time_Case_Became_Workable__c = System.now()
        );
    }

    public void setPrimaryQuote(){
        SBQQ__Quote__c qt = new SBQQ__Quote__c(
            Id = fflib_IDGenerator.generate(SBQQ__Quote__c.getSObjectType()),
            SBQQ__StartDate__c = Date.today().addDays(-30),
            PactSafe_Contract_Type__c = '',
            SBQQ__Primary__c = true,
            SBQQ__Type__c = 'Quote',
            SBQQ__Status__c = 'Draft',
            SBQQ__Account__c = this.marketplaceAccount.Id,
            SBQQ__ExpirationDate__c = this.marketplaceOpportunity.CloseDate,
            SBQQ__BillingCity__c = 'Grand Rapids',
            SBQQ__BillingCountry__c = 'US',
            SBQQ__BillingName__c = 'Billing Name',
            SBQQ__BillingPostalCode__c = '49506',
            SBQQ__BillingState__c = 'MI',
            SBQQ__BillingStreet__c = '1234 Main',
            SBQQ__Opportunity2__c = this.marketplaceOpportunity.Id,
            SBQQ__PriceBook__c = this.pricebook.Id,
            SBQQ__PricebookId__c = this.pricebook.Id,
            SBQQ__PrimaryContact__c = this.decisionMaker.Id,
            SBQQ__ShippingCity__c = 'Grand Rapids',
            SBQQ__ShippingCountry__c = 'US',
            SBQQ__ShippingName__c = 'Shipping Name',
            SBQQ__ShippingPostalCode__c = '49506',
            SBQQ__ShippingState__c = 'MI',
            SBQQ__ShippingStreet__c = '1234 Main St',
            SBQQ__SubscriptionTerm__c = 12,
            RecordTypeId = CDdSchemaUtils.QUOTE_RT.draftId()
        );
        this.primaryQuote = ((List<SBQQ__Quote__c>)fflib_ApexMocksUtils.makeRelationship(
            List<SBQQ__Quote__c>.class,
            new List<SBQQ__Quote__c>{qt},
            SBQQ__QuoteLine__c.SBQQ__Quote__c,
            new List<List<SBQQ__QuoteLine__c>>{replaceNullValuesWithDefaults('SBQQ__QuoteLine__c', this.primaryQuoteLines)}
        ))[0];
    }
    public void setPrimaryQuoteLines(){
        this.primaryQuoteLines = new List<SBQQ__QuoteLine__c>();
        Map<String, Product2> cpqProductsByDDCustomId = getCPQProductsByDDCustomId();
        Map<String, PricebookEntry> cpqPriceBookEntriesByDDCustomId = getCPQPriceBookEntriesByDDCustomId();
        // Get package product and price book entry
        Product2 packageProduct = cpqProductsByDDCustomId.get(CPQ_STOREFRONT_PACKAGE_DD_CUSTOM_ID);
        PricebookEntry packagePricebookEntry = cpqPriceBookEntriesByDDCustomId.get(CPQ_STOREFRONT_PACKAGE_DD_CUSTOM_ID);
        // Create storefront package quote line - BEGIN
        SBQQ__QuoteLine__c packageQuoteLine = new SBQQ__QuoteLine__c(
            Id = fflib_IDGenerator.generate(SBQQ__QuoteLine__c.getSObjectType()),
            SBQQ__BillingFrequency__c = 'Monthly',
            SBQQ__DefaultSubscriptionTerm__c = 1,
            SBQQ__Number__c = 1,
            SBQQ__Product__c = packageProduct.Id,
            SBQQ__Product__r = packageProduct,
            SBQQ__Quantity__c = 1,
            SBQQ__Quote__c = this.primaryQuote.Id,
            SBQQ__Quote__r = this.primaryQuote,
            SBQQ__NetPrice__c = 100,
            SBQQ__PricebookEntryId__c = packagePricebookEntry.Id
        );
        this.primaryQuoteLines.add(packageQuoteLine);
        // Create storefront package quote line - END
        // Create non-package quote lines - BEGIN
        for(String ddCustomId : CPQ_PRODUCT_DD_CUSTOM_IDS){
            // quoueline for storefront package is already processed
            if (!CPQ_STOREFRONT_PACKAGE_DD_CUSTOM_ID.equals(ddCustomId)){
                Product2 product = cpqProductsByDDCustomId.get(ddCustomId);
                Boolean isTrialConfig = (Boolean)CPQ_DD_CUSTOM_ID_CONFIG_DATA.get(ddCustomId).get(CPQ_CONFIG_KEY_IS_TRIAL);
                SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(
                    Id = fflib_IDGenerator.generate(SBQQ__QuoteLine__c.getSObjectType()),
                    SBQQ__BillingFrequency__c = 'Monthly',
                    SBQQ__DefaultSubscriptionTerm__c = 1,
                    SBQQ__Number__c = 1,
                    SBQQ__Product__c = product.Id,
                    SBQQ__Product__r = product,
                    SBQQ__Quantity__c = 1,
                    SBQQ__Quote__c = this.primaryQuote.Id,
                    SBQQ__Quote__r = this.primaryQuote,
                    SBQQ__NetPrice__c = 100,
                    SBQQ__PricebookEntryId__c = cpqPriceBookEntriesByDDCustomId.get(ddCustomId).Id
                );
                if (isTrialConfig){
                    quoteLine.Trial_Period__c = '60';
                }
                //quoteLine.SBQQ__NetPrice__c = null;
                String fieldName = (String)CPQ_DD_CUSTOM_ID_CONFIG_DATA.get(ddCustomId).get(CPQ_CONFIG_KEY_QUOTE_LINE_FIELD_NAME);
                Object fieldvalue = (Object)CPQ_DD_CUSTOM_ID_CONFIG_DATA.get(ddCustomId).get(CPQ_CONFIG_KEY_QUOTE_LINE_FIELD_VALUE);
                if (fieldName!=null && fieldvalue!=null){
                    quoteLine.put(fieldName, fieldvalue);
                }
                quoteLine.SBQQ__PricebookEntryId__c = cpqPriceBookEntriesByDDCustomId.get(ddCustomId).Id;
                // Add package quote line reference to quote lines with storefront products
                if (CPQ_STOREFRONT_PRODUCT_DD_CUSTOM_IDS.contains(ddCustomId)){
                    quoteLine.SBQQ__RequiredBy__c = packageQuoteLine.Id;
                }
                quoteLine.SBQQ__Quantity__c = 1;
                this.primaryQuoteLines.add(quoteLine);
            }
        }
    }
    public void setMarketplaceOrder(){
        Order ord = new Order(
            Id = fflib_IDGenerator.generate(Order.getSObjectType()),
            AccountId = this.marketplaceAccount.Id,
            EffectiveDate = Date.today(),
            OpportunityId = this.marketplaceOpportunity.Id,
            Pricebook2Id = this.pricebook.Id,
            SBQQ__ContractingMethod__c = 'By Subscription End Date',
            SBQQ__PaymentTerm__c = 'Net 30',
            SBQQ__PriceCalcStatus__c = 'Not Started',
            SBQQ__Quote__c = this.primaryQuote.Id,
            SBQQ__RenewalTerm__c = 1,
            Status = 'Draft',
            Type = 'New'
        );
        this.marketplaceOrder = ((List<Order>)fflib_ApexMocksUtils.makeRelationship(
            List<Order>.class,
            new List<Order>{ord},
            OrderItem.OrderId,
            new List<List<OrderItem>>{replaceNullValuesWithDefaults('OrderItem', this.marketplaceOrderItems)}
        ))[0];
    }
    public void setMarketplaceOrderItems(){
        this.marketplaceOrderItems = new List<OrderItem>();
        Integer i=0;
        for (SBQQ__QuoteLine__c quoteLine : this.primaryQuoteLines){
            OrderItem ordItem = new OrderItem(
                Id = fflib_IDGenerator.generate(OrderItem.getSObjectType()),
                OrderId = this.marketplaceOrder.Id,
                Order = this.marketplaceOrder,
                Product2Id = quoteLine.SBQQ__Product__c,
                Product2 = quoteLine.SBQQ__Product__r,
                PricebookEntryId = quoteLine.SBQQ__PricebookEntryId__c,
                UnitPrice = quoteLine.SBQQ__NetPrice__c,
                Quantity = 1,
                QuoteLineItemId = quoteLine.Id,
                ListPrice = quoteLine.SBQQ__NetPrice__c,
                ServiceDate = Date.today(),
                EndDate = Date.today().addMonths(12),
                SBQQ__Activated__c = false,
                SBQQ__BillingFrequency__c = quoteLine.SBQQ__BillingFrequency__c,
                SBQQ__BillingType__c = quoteLine.SBQQ__BillingType__c,
                SBQQ__BookingsIndicator__c = 'Include',
                SBQQ__ChargeType__c = quoteLine.SBQQ__ChargeType__c,
                SBQQ__ContractAction__c = 'New',
                SBQQ__ContractingMethod__c = 'Inherit',
                SBQQ__DefaultSubscriptionTerm__c = 1,
                SBQQ__OrderedQuantity__c = quoteLine.SBQQ__Quantity__c,
                SBQQ__ProrateMultiplier__c = 1,
                SBQQ__QuoteLine__c = quoteLine.Id,
                SBQQ__QuoteLine__r = quoteLine,
                SBQQ__QuotedListPrice__c = quoteLine.SBQQ__ListPrice__c,
                SBQQ__QuotedQuantity__c = quoteLine.SBQQ__Quantity__c,
                SBQQ__Status__c = 'Draft',
                SBQQ__SubscriptionPricing__c = quoteLine.SBQQ__SubscriptionPricing__c,
                SBQQ__SubscriptionTerm__c = quoteLine.SBQQ__SubscriptionTerm__c
            );
            if (quoteLine.SBQQ__RequiredBy__c != null){
                ordItem.SBQQ__RequiredBy__c = quoteLine.SBQQ__RequiredBy__c;
            }
            ordItem = (OrderItem)fflib_ApexMocksUtils.setReadOnlyFields(
				ordItem,
				OrderItem.class,
				new Map<SObjectField, Object> {OrderItem.OrderItemNumber => '000000000' + i++, OrderItem.TotalPrice => (quoteLine.SBQQ__NetPrice__c * 1) }
		    );
            this.marketplaceOrderItems.add(ordItem);
        }
    }
    public void setPricebook(){
        this.pricebook = new Pricebook2(
            Id = fflib_IDGenerator.generate(Pricebook2.getSObjectType()),
            isActive = true
        );
    }
    /**
     * @description Insert CPQ Product records
     * @param
     * @return
     */
    public void setProducts(){
        this.products = new List<Product2>();
        for(String ddCustomId : CPQ_PRODUCT_DD_CUSTOM_IDS){
            Product2 product = new Product2();
            product.Description = 'Product';
            product.IsActive = true;
            product.ProductCode = 'ProductCode';
            product.Family = 'Marketplace';
            product.SBQQ__AssetAmendmentBehavior__c = 'Default';
            product.SBQQ__AssetConversion__c = 'One per quote line';
            product.SBQQ__BillingFrequency__c = 'Monthly';
            product.SBQQ__BillingType__c = 'Advance';
            product.SBQQ__ChargeType__c = 'Recurring';
            product.SBQQ__ConfigurationEvent__c = 'Always';
            product.SBQQ__ConfigurationType__c = 'Allowed';
            product.SBQQ__DefaultQuantity__c = 1;
            product.SBQQ__PriceEditable__c = true;
            product.SBQQ__PricingMethod__c = 'List';
            product.SBQQ__SubscriptionBase__c = 'List';
            product.SBQQ__SubscriptionPricing__c = 'Fixed Price';
            product.SBQQ__SubscriptionTerm__c = 1;
            product.SBQQ__SubscriptionType__c = 'Renewable';
            product.Id = fflib_IDGenerator.generate(Product2.getSObjectType());
            product.Name = (String)CPQ_DD_CUSTOM_ID_CONFIG_DATA.get(ddCustomId).get(CPQ_CONFIG_KEY_PRODUCT_NAME);
            product.Package_Name__c = (String)CPQ_DD_CUSTOM_ID_CONFIG_DATA.get(ddCustomId).get(CPQ_CONFIG_KEY_PACKAGE_NAME);
            product.Platform__c = (String)CPQ_DD_CUSTOM_ID_CONFIG_DATA.get(ddCustomId).get(CPQ_CONFIG_KEY_PLATFORM);
            product.DD_Custom_ID__c = ddCustomId;
            product.Priority_for_Activation__c = 'High';
            this.products.add(product);
        }
    }
    public void setPricebookEntries(){
        this.pricebookEntries = new List<PricebookEntry>();
        for (Product2 p : this.products){
            this.pricebookEntries.add(new PricebookEntry(
                    Id = fflib_IDGenerator.generate(PricebookEntry.getSObjectType()),
                    Pricebook2Id =  this.pricebook.Id,
                    Product2Id = p.Id,
                    UnitPrice = 0,
                    IsActive = true,
                    CurrencyIsoCode = 'USD')
            );
        }
    }
     /**
     * @description mock pos integraion request records.
     */
    public void setPosIntegrationRequests(){
        this.posIntegrationRequests = new List<Integration_Request__x>();
        Integration_Request__x posRequest = new Integration_Request__x();
        posRequest.Id =  fflib_IDGenerator.generate(Integration_Request__x.getSObjectType());
        posRequest.Sfdc_status__c = 'Pending';
        posRequest.store_Id__c = '224455';
        posRequest.sfdc_org__c = 'Figment';
        posRequest.Integration_Provider__c = 'square';
        posRequest.Integration_Id__c = '12345667';
        posRequest.Activation_Date__c =  Date.today().adddays(20);
        posRequest.systemmodstamp__c = Datetime.now();
        posRequest.onboarding_Id__c = 'onboardingId001';
        posRequest.Integration_Type__c = 'POS Requests';
        posRequest.Request_Owner_Email__c = 'test@doordash.com';
        posRequest.Action__c = 'CREATE';
        posRequest.Integration_Provider__c = 'toast';
        this.posIntegrationRequests.add(posRequest);
    }
    public static String getRandomInteger(Integer length){
        final String chars = '0123456789';
        String randStr = '';
        While (randStr.length() < length){
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randStr += chars.substring(idx, idx+1);
        }
        return randStr;
    }
    /**
     * @description Return CPQ Price Book Entry records by DD Custom Id
     * @param
     * @return Map<String, PricebookEntry>
     */
    public Map<String, PricebookEntry> getCPQPriceBookEntriesByDDCustomId(){
        Map<String, PricebookEntry> cpqPriceBookEntriesByDDCustomId = new Map<String, PricebookEntry>();
        for (PricebookEntry pbe : this.pricebookEntries){
            for (Product2 p : this.products){
                if (p.Id.equals(pbe.Product2Id)){
                    cpqPriceBookEntriesByDDCustomId.put(p.DD_Custom_ID__c, pbe);
                }
            }
        }
        return cpqPriceBookEntriesByDDCustomId;
    }
    /**
     * @description Return CPQ Product records by DD Custom Id
     * @param
     * @return Map<String, Product2>
     */
    public Map<String, Product2> getCPQProductsByDDCustomId(){
        Map<String, Product2> cpqProductsByDDCustomId = new Map<String, Product2>();
        for (Product2 p : this.products){
            cpqProductsByDDCustomId.put(p.DD_Custom_ID__c, p);
        }
        return cpqProductsByDDCustomId;
    }
    public Product2 getStorefrontPackageProduct(){
        Map<String, Product2> cpqProductsByDDCustomId = getCPQProductsByDDCustomId();
        return cpqProductsByDDCustomId.get(CPQ_STOREFRONT_PACKAGE_DD_CUSTOM_ID);
    }
    public OrderItem getStorefrontPackageProductOrderItem(){
        Product2 storefrontPackageProduct = getStorefrontPackageProduct();
        OrderItem storefrontPackageProductOrderItem = null;
        for (OrderItem item : this.marketplaceOrderItems){
            if (storefrontPackageProduct.Id.equals(item.Product2Id)){
                storefrontPackageProductOrderItem = item;
            }
        }
        return storefrontPackageProductOrderItem;
    }
    public static Integer getRandomInteger() {
        Integer randomInteger = Crypto.getRandomInteger();
        return randomInteger < 0 ? (randomInteger * -1) : randomInteger;
    }
    public List<SObject> replaceNullValuesWithDefaults(String sObjectType, List<SObject> sObjs){
        Schema.DescribeSObjectResult descSObjResultMap =DESCRIBE_SOBJECT_RESULT_BY_SOBJECT_TYPE_STRING.get(sObjectType);
        Map<String, Schema.SObjectField> sObjectFields = descSObjResultMap.fields.getMap();
        Map<String, Schema.DescribeFieldResult> descSObjFieldResultMap = new Map<String, Schema.DescribeFieldResult>();
        for (SObject sObj : sObjs){
            Map<String, Object> fieldsToValue = sObj.getPopulatedFieldsAsMap();
            for (String fieldName : fieldsToValue.keySet()){
                if (fieldsToValue.get(fieldName) == null){
                    // add the fieldName to the descSObjFieldResultMap if not already present
                    if (!descSObjFieldResultMap.containsKey(fieldName)){
                        descSObjFieldResultMap.put(fieldName, sObjectFields.get(fieldName).getDescribe());
                    }
                    // set the default value on the sObject field
                    if (FIELD_TYPES_STRING.contains(descSObjFieldResultMap.get(fieldName).getType().name())){
                        sObj.put(fieldName, 'default');
                    }
                    if (FIELD_TYPES_NUMBER.contains(descSObjFieldResultMap.get(fieldName).getType().name())){
                        sObj.put(fieldName, 0);
                    }
                    if (FIELD_TYPES_BOOLEAN.contains(descSObjFieldResultMap.get(fieldName).getType().name())){
                        sObj.put(fieldName, false);
                    }
                }
            }
        }
        return sObjs;
    }
}