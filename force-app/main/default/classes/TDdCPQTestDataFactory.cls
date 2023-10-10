@isTest
public class TDdCPQTestDataFactory {
    @testVisible private static final String DEFAULT_OPPORTUNITY_NAME = 'Paul';

    /**
     * @description Creates an Account record for test purposes using the default values ('Marketplace' record type).
     *
     * @param doInsert (Boolean)
     * @return Account
     */
    public static Account createAccount(Boolean doInsert){
        Account newAccount = TDdAccountFactory.createAccount();

        if(doInsert){
            insert newAccount;
        }

        return newAccount;
    }

    public static Lead createLead(Boolean doInsert) {
        Lead lead = new Lead();
        lead.IsConverted = false;
        lead.FirstName = 'Test';
        lead.LastName = 'Lead';
        lead.State = 'MT';
        lead.Status = 'Open';
        if (doInsert) {
            insert lead;
        }
        return lead;
    }
    
    public static Lead createLead(
        String firstName,
        String lastName,
        String street,
        String city,
        String state,
        String postalCode,
        String country,
        String companyName,
        Boolean doInsert
    ) {
        Lead lead = new Lead();
        lead.IsConverted = false;
        lead.FirstName = firstName;
        lead.LastName = lastName;
        lead.Street = street;
        lead.City = city;
        lead.State = state;
        lead.PostalCode = postalCode;
        lead.Country = country;
        lead.Company = companyName;
        lead.Status = 'Open';
        if (doInsert) {
            insert lead;
        }
        return lead;
    }
    
    public static Contact createContact(Boolean doInsert) {
        Contact testContact = new Contact();
        testContact.FirstName = 'FirstName';
        testContact.LastName = 'LastName';
        if (doInsert) {
            insert testContact;
        }
        return testContact;
      }
    
    public static PricebookEntry createPriceBookEntry(Product2 product, String currencyCode, Boolean doInsert) {
        return createPriceBookEntry(product, new Pricebook2(Id = Test.getStandardPricebookId()), currencyCode, doInsert);
    }
    
    public static PricebookEntry createPriceBookEntry(Product2 product, Pricebook2 pricebook, String currencyCode, Boolean doInsert) {
        //pricebook entry
        PricebookEntry testPbEntry = new PricebookEntry();
        testPbEntry.Pricebook2Id = pricebook.Id;
        testPbEntry.Product2Id = product.Id;
        testPbEntry.UnitPrice = 0;
        testPbEntry.IsActive = true;
        testPbEntry.CurrencyIsoCode = currencyCode;
        if (doInsert) {
            insert testPbEntry;
        }
        return testPbEntry;
    }
    public static Product2 createProduct(Boolean doInsert) {
        Product2 product = new Product2();
        product.Name = 'Test Product';
        product.Description = 'Product';
        product.IsActive = true;
        product.ProductCode = 'ProductCode';
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
        if (doInsert) {
            insert product;
        }
        return product;
    }

    /**
     * @description Creates an Opportunity record using as many default values as possible.
     *  defaults contactId to null.
     *
     * @param accountId (Id)
     * @param doInsert (Boolean)
     * @return (Opportunity)
     */
    public static Opportunity createOpportunity(Id accountId, Boolean doInsert){
        return createOpportunity(accountId, null, doInsert);
    }

    /**
     * @description Creates an Opportunity record using as many default values as possible.
     *  defaults Name to 'Paul', stage to 'Meeting Ran / Negotiated' and record type to 'ML_Inside_Sales'.
     *
     * @param accountId (Id)
     * @param contactId (Id)
     * @param doInsert (Boolean)
     * @return (Opportunity)
     */
    public static Opportunity createOpportunity(Id accountId, Id contactId, Boolean doInsert){
        return createOpportunityByDevRT('Paul', accountId, contactId, 'Meeting Ran / Negotiated', 'ML_Inside_Sales', doInsert);
    }

    /**
     * @description Creates an Opportunity record of the provided type using as many default values as possible.
     *  defaults Name to 'Paul', stage to 'Meeting Ran / Negotiated'.
     *
     * @param accountId (Id)
     * @param contactId (Id)
     * @param recordTypeName (String)
     * @param doInsert (Boolean)
     * @return (Opportunity)
     */
    public static Opportunity createOpportunityByDevRT(Id accountId, Id contactId, String recordTypeName, Boolean doInsert){
        return createOpportunityByDevRT(DEFAULT_OPPORTUNITY_NAME, accountId, contactId, 'Meeting Ran / Negotiated', recordTypeName, doInsert);
    }

    public static Opportunity createOpportunityByDevRT(String name, Id accountId, Id contactId, String stageName, String rtName, boolean doInsert){
        Opportunity opp = TDdOpportunityFactory.createOpportunityByDevRT( name, accountId, contactId, stageName, rtName);
        opp.Pactsafe_Contract_Type__c = null;
        if(doInsert){
            insert opp;
        }
        return opp;
    }

    public static OpportunityLineItem createOpportunityLineItem(Id oppId, Id productId, Id pricebookEntryId, boolean doInsert){
        OpportunityLineItem oppLineItem = new OpportunityLineItem();
        oppLineItem.OpportunityId = oppId;
        oppLineItem.PricebookEntryId = pricebookEntryId; 
        oppLineItem.Product2Id = productId; 
        oppLineItem.Quantity = 1; 
        oppLineItem.UnitPrice = 1;  
    
        if (doInsert) {
            insert oppLineItem;
        }
        return oppLineItem; 
    }

    /**
     * @description Creates a SBQQ__Quote__c record for testing. Defaults it to be a primary quote.
     *
     * @param oppty (Opportunity)
     * @param account (Account)
     * @param contact (Contact)
     * @param doInsert (Boolean)
     * @return (SBQQ__Quote__c)
     */
    public static SBQQ__Quote__c createQuote(Opportunity oppty, Account account, Contact contact, Boolean doInsert) {
        return createQuote(oppty, account, contact, true, doInsert);
    }

    /**
     * @description Creates a SBQQ__Quote__c record for testing.
     *
     * @param oppty (Opportunity)
     * @param account (Account)
     * @param contact (Contact)
     * @param isPrimary (Boolean)
     * @param doInsert (Boolean)
     * @return (SBQQ__Quote__c)
     */
    public static SBQQ__Quote__c createQuote(Opportunity oppty, Account account, Contact contact, Boolean isPrimary, Boolean doInsert) {
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.SBQQ__Primary__c = isPrimary;
        quote.SBQQ__Type__c = 'Quote';
        quote.SBQQ__Status__c = 'Draft';
        quote.SBQQ__Account__c = account.Id;
        quote.SBQQ__ExpirationDate__c = oppty == null ? null : oppty.CloseDate;
        quote.SBQQ__BillingCity__c = 'Grand Rapids';
        quote.SBQQ__BillingCountry__c = 'US';
        quote.SBQQ__BillingName__c = 'Billing Name';
        quote.SBQQ__BillingPostalCode__c = '49506';
        quote.SBQQ__BillingState__c = 'MI';
        quote.SBQQ__BillingStreet__c = '1234 Main';
        quote.SBQQ__Opportunity2__c = oppty == null ? null : oppty.Id;
        quote.SBQQ__PriceBook__c = Test.getStandardPricebookId();
        quote.SBQQ__PricebookId__c = Test.getStandardPricebookId();
        quote.SBQQ__PrimaryContact__c = contact == null ? null : contact.Id;
        quote.SBQQ__ShippingCity__c = 'Grand Rapids';
        quote.SBQQ__ShippingCountry__c = 'US';
        quote.SBQQ__ShippingName__c = 'Shipping Name';
        quote.SBQQ__ShippingPostalCode__c = '49506';
        quote.SBQQ__ShippingState__c = 'MI';
        quote.SBQQ__ShippingStreet__c = '1234 Main St';
        quote.SBQQ__StartDate__c = Date.today();
        quote.SBQQ__SubscriptionTerm__c = 12;
        quote.RecordTypeId = CDdSchemaUtils.QUOTE_RT.draftId();
        if (doInsert) {
          insert quote;
        }
        return quote;
    }

    public static SBQQ__QuoteLine__c createQuoteLine(Product2 product, SBQQ__Quote__c quote, Boolean doInsert) {
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
        quoteLine.SBQQ__BillingFrequency__c = 'Monthly';
        quoteLine.SBQQ__DefaultSubscriptionTerm__c = 1;
        quoteLine.SBQQ__Number__c = 1;// might need to set
        quoteLine.SBQQ__Product__c = product.Id;
        quoteLine.SBQQ__Quantity__c = 1;
        quoteLine.SBQQ__Quote__c = quote.Id;
        quoteLine.SBQQ__NetPrice__c = 100;        
        if (doInsert) { 
            insert quoteLine; 
        }
        return quoteLine;
    }

    public static Order createOrder(Account account, Opportunity opp, SBQQ__Quote__c quote, Boolean doInsert) {
        Order order = new Order();
        order.AccountId = account.Id;
        order.EffectiveDate = Date.today();
        order.EndDate = Date.today().addMonths(12);
        order.OpportunityId = opp.Id;
        order.Pricebook2Id = Test.getStandardPricebookId();
        order.SBQQ__ContractingMethod__c = 'By Subscription End Date';
        order.SBQQ__PaymentTerm__c = 'Net 30';
        order.SBQQ__PriceCalcStatus__c = 'Not Started';
        order.SBQQ__Quote__c = quote.Id;
        order.SBQQ__RenewalTerm__c = 1;
        order.Status = 'Draft';
        order.Type = 'New';
        if (doInsert) {
          insert order;
        }
        return order;
      }
    
      public static OrderItem createOrderItem(Order order, SBQQ__QuoteLine__c quoteLine, Id priceBookEntryId, Boolean doInsert) {
        OrderItem oi = new OrderItem();
        oi.EndDate = Date.today().addMonths(12);
        oi.OrderId = order.Id;
        oi.Quantity = 1;
        oi.SBQQ__Activated__c = false;
        oi.SBQQ__BillingFrequency__c = quoteLine.SBQQ__BillingFrequency__c;
        oi.SBQQ__BillingType__c = quoteLine.SBQQ__BillingType__c;
        oi.SBQQ__BookingsIndicator__c = 'Include';
        oi.SBQQ__ChargeType__c = quoteLine.SBQQ__ChargeType__c;
        oi.SBQQ__ContractAction__c = 'New';
        oi.SBQQ__ContractingMethod__c = 'Inherit';
        oi.SBQQ__DefaultSubscriptionTerm__c = 1;
        oi.SBQQ__OrderedQuantity__c = quoteLine.SBQQ__Quantity__c;
        oi.SBQQ__ProrateMultiplier__c = 1;
        oi.SBQQ__QuoteLine__c = quoteLine.Id;
        oi.SBQQ__QuotedListPrice__c = quoteLine.SBQQ__ListPrice__c;
        oi.SBQQ__QuotedQuantity__c = quoteLine.SBQQ__Quantity__c;
        oi.SBQQ__Status__c = 'Draft';
        oi.SBQQ__SubscriptionPricing__c = quoteLine.SBQQ__SubscriptionPricing__c;
        oi.SBQQ__SubscriptionTerm__c = quoteLine.SBQQ__SubscriptionTerm__c;
        oi.ServiceDate = Date.today();
        oi.UnitPrice = quoteLine.SBQQ__NetPrice__c;
        oi.PricebookEntryId = priceBookEntryId;
        if (doInsert) {
          insert oi;
        }
        return oi;
      }

    public static RealZip__RealZips__c createRealZip(Submarket__c submarket, Boolean doInsert){
        RealZip__RealZips__c realZip = new RealZip__RealZips__c(); 
        realzip.Submarket_lookup__c = submarket.Id; 
        if(doInsert){
            insert realZip; 
        }
        return realZip;
    }

    public static Submarket__c createSubmarket(String name, String region, Decimal serviceFee, Decimal npServiceFee, Boolean doInsert){
        Submarket__c submarket = new Submarket__c(); 
        submarket.Name = name; 
        submarket.Region__c = region;
        submarket.NP_Service_Fee__c = npServiceFee;
        submarket.Service_Fee__c = serviceFee;
        if(doInsert){
            insert submarket; 
        }
        return submarket;
    }

    public static SBQQ__ProductOption__c createProductOption(Id configuredProductId, Id optionalProductId, Integer orderNumber, Boolean doInsert) {
        SBQQ__ProductOption__c productOption = new SBQQ__ProductOption__c();
        productOption.SBQQ__ConfiguredSKU__c = configuredProductId;
        productOption.SBQQ__OptionalSKU__c = optionalProductId;
        productOption.SBQQ__Number__c = orderNumber;        
        if(doInsert){
            insert productOption; 
        }
        return productOption;
    }

    /**
     * @description Creates a pactsafe1__PactSafeRequest__c record associated with the provided quote.
     *
     * @param quoteId (Id)
     * @param doInsert (Boolean)
     * @return (pactsafe1__PactSafeRequest__c)
     */
    public static pactsafe1__PactSafeRequest__c createPSRequest(Id quoteId, Boolean doInsert){
        pactsafe1__PactSafeRequest__c newRequest = new pactsafe1__PactSafeRequest__c(
            Quote__c = quoteId
        );

        if(doInsert){
            insert newRequest;
        }

        return newRequest;
    }
    
    /*
     * @description Function to create a single users with a given profile ID and a role Id
                    If the userProfileId is null, it will use Sys Admin profile.
                    If the RoleId is Null, it will create a test role. 
    ****************************************************************************************
    THIS METHOD IS DEPRECATED. PLEASE USE TDdUserFactory.createUsers method instead. 
    ****************************************************************************************
     */
    public static User createUser(Id userProfileId, Id roleId, String rollName) {
    /****************************************************************************************
    THIS METHOD IS DEPRECATED. PLEASE USE TDdUserFactory.createUsers method instead. 
    ****************************************************************************************/
        return TDdUserFactory.createUsers(1)[0];
    }

    public static Commission_Rate__c createCommissionRate(
        String currencyCode,     
        Id productId, 
        Id packageProductId,
        String region,
        Id submarketId, 
        Date startDate, 
        Date endDate,
        String primaryMxCat,     
        Boolean doInsert
    ){
        Commission_Rate__c commissionRate = new Commission_Rate__c();
        commissionRate.CurrencyIsoCode = currencyCode;
        commissionRate.Start__c = startDate;
        commissionRate.End__c = endDate;
        commissionRate.Package__c = packageProductId;
        commissionRate.Primary_Merchant_Category__c = primaryMxCat;
        commissionRate.Product__c = productId;
        commissionRate.Region__c = region;
        commissionRate.Submarket__c = submarketId;
        if(doInsert){
            insert commissionRate;
        }
        return commissionRate;
    }
}