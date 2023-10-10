/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 04/29/2021
*
* @group Nimda
*
* @description This helper retrieves the product/pricing data based on one of the following models
* - Opportunity
*       For this model, product/pricing information is retrieved from the Opportunity object
* - CPQ
*       For this model, product/pricing information is retrieved from the OrderItems of the Orders
*       associated with the Opportunity and the Primary Quote (tagged on the Opportunity record)
*
**************************************************************************************************************************************/
public class CDdNimdaSyncStoreProductHelper {
    /**
     * @description Default Product Data
     */
    private static final Map<String, Object> DEFAULT_PRODUCT_DATA = CDdS2NProductPropertyHelper.getDefaultProductData();
    private static final Set<String> S2N_PRODUCT_CPQ_DD_CUSTOM_IDS = CDdS2NProductPropertyHelper.getCPQProductDDCustomIds();
    private static final List<String> ORDER_ITEM_FIELDS = new List<String>(CDdS2NProductPropertyHelper.getOrderItemFields());
    private static final String SOQL_QUERY_ORDER_ITEM_SELECT
                                = 'SELECT Id, OrderId, Order.OpportunityId,CurrencyIsoCode,Order.SBQQ__Quote__c, Product2.DD_Custom_ID__c, '
                                + String.join(ORDER_ITEM_FIELDS, ',');
    private static final String SOQL_QUERY_ORDER_ITEM_FROM = ' FROM OrderItem ';
    private static final String SOQL_QUERY_ORDER_ITEM_WHERE
                                = ' WHERE Order.OpportunityId = :opportunityIds '
                                + ' AND Order.SBQQ__Quote__c = :primaryQuoteIds '
                                + ' AND Product2.DD_Custom_ID__c IN :S2N_PRODUCT_CPQ_DD_CUSTOM_IDS ';
    private static final String SOQL_QUERY_ORDER_ITEM_STRING = SOQL_QUERY_ORDER_ITEM_SELECT
                                                + SOQL_QUERY_ORDER_ITEM_FROM
                                                + SOQL_QUERY_ORDER_ITEM_WHERE;
    private static final vCS__c apiSettings = vCS__c.getInstance();
    private static final String PROGRAM_ONLINE_ORDERING_DELIVERY = 'Online_Ordering_Delivery';
    private static final String PROGRAM_ONLINE_ORDERING_PICKUP = 'Online_Ordering_Pickup';
    private static final String PROGRAM_ONLINE_ORDERING_TRIAL_PICKUP_PROMO_PERIOD = 'Online_Ordering_Pickup_Trial_Promo';
    private static final String PROGRAM_ONLINE_ORDERING_TRIAL_DELIVERY_PROMO_PERIOD = 'Online_Ordering_Delivery_Trial_Promo';
    private Map<Id, Opportunity> opportunities;
    private Map<Id, List<OrderItem>> orderItemsForOpportunity;
    private static Map<String, MxAffiliateProgram__mdt> CONFIGURED_PROGRAMS;
    static {
        CONFIGURED_PROGRAMS = new Map<String, MxAffiliateProgram__mdt>();
        for (MxAffiliateProgram__mdt program : [SELECT Id, Label, DeveloperName,
                Experience__c, Channel__c, Fulfillment_Type__c, Audience__c,
                IsOpportunityProductProgram__c, Product_Name__c, Is_Active__c,
        (SELECT Id, Label, DeveloperName, Display_Name__c, Is_Trial__c,
                Fee_Name__c, Fee_Type__c, Fee_Rate_Charging_Target__c
        FROM MxAffiliateFeeAttributes__r
        WHERE Is_Active__c = true)
        FROM MxAffiliateProgram__mdt
        WHERE Is_Active__c = true
        ORDER BY DeveloperName ASC]){
            CONFIGURED_PROGRAMS.put(program.DeveloperName, program);
        }
    }
    /**
     * @description default constructor
     */
    public CDdNimdaSyncStoreProductHelper(Set<Id> opportunityIds) {
        this.setOpportunities(opportunityIds);
        this.setOrderItemsForOpportunity(this.opportunities);
    }
    /**
     * @description Query and set the Opportunity records for the input Collection of Opportunity Ids
     * @param opportunityIds Collection of Opportunity Record Identifiers
     * @return
     */
    public void setOpportunities(Set<Id> opportunityIds){
        this.opportunities = new Map<Id, Opportunity>();
        for (Opportunity opp : [SELECT Id, Trial_Type__c, Trial_End_Date__c, Platform__c ,Order_Service_Type__c, Merchant_Agreed_to__c,
                                Trial_Pricing_Tier__c, Pricing_Tier_New__c, DashPass_Eligible_CW__c, Delivery_Fee__c,
                                Fulfills_Own_Deliveries__c, Trial_Commission__c, Commission__c, Trial_Service_Fee__c,
                                Service_Fee_New__c, In_App_Pickup_Commission__c, Legal_Entity__c,
                                Activation_Fee__c, Weekly_Tablet_Subscription_Fee__c, Weekly_Printer_Subscription_Fee__c,
                                DashPass_Only_Commission__c, DashPass_Flat_Fee__c, Referred_Delivery_Commission__c,
                                Referred_Pickup_Commission__c, SBQQ__PrimaryQuote__c
                                FROM Opportunity
                                WHERE Id IN :opportunityIds]){
            this.opportunities.put(opp.Id, opp);
        }
    }
    /**
     * @description Query and set the Map Collection of Order Item records
     * Key - Opportunity Id
     * Value - Collection of Order Item records
     * Perform query to filter Order Item records by
     * - Input Opportunity Ids
     * - The tagged Primary Quote Ids found on the corresponding Opportunity record(s)
     * - AND for S2N Product DD Custom IDs ONLY
     * @param opportunities Input Map collection of Opportunity records with key as Opportunity Id
     * @return
     */
    public void setOrderItemsForOpportunity(Map<Id, Opportunity> opportunities){
        this.orderItemsForOpportunity = new Map<Id, List<OrderItem>>();
        Map<Id, Id> primaryQuoteIdForOpportunityId = new Map<Id, Id>();
        Set<Id> opportunityIds = new Set<Id>();
        Set<Id> primaryQuoteIds = new Set<Id>();
        for (Id opportunityId : opportunities.keySet()){
            Opportunity opportunity = opportunities.get(opportunityId);
            if (isCPQModel(opportunity)){
                primaryQuoteIdForOpportunityId.put(opportunity.Id, opportunity.SBQQ__PrimaryQuote__c);
                opportunityIds.add(opportunity.Id);
                primaryQuoteIds.add(opportunity.SBQQ__PrimaryQuote__c);
            }
        }
        for (OrderItem orderItem : Database.query(SOQL_QUERY_ORDER_ITEM_STRING)){
            Id opportunityIdFromDB = orderItem.Order.OpportunityId;
            Id quoteIdFromDB = orderItem.Order.SBQQ__Quote__c;
            // ensuring Order Item is eligible for processing
            // i.e. Opp Id and the corresponding Primary Quote Id match related data points on the Order Item record
            Boolean processOrderItem = primaryQuoteIdForOpportunityId.containsKey(opportunityIdFromDB)
                                        &&
                                        quoteIdFromDB.equals(primaryQuoteIdForOpportunityId.get(opportunityIdFromDB));
            if (processOrderItem) {
                if (this.orderItemsForOpportunity.containsKey(opportunityIdFromDB)){
                    this.orderItemsForOpportunity.get(opportunityIdFromDB).add(orderItem);
                } else {
                    this.orderItemsForOpportunity.put(opportunityIdFromDB, new List<OrderItem>{orderItem});
                }
            }
        }
    }
    /**
     * @description Return the S2N Product Data for the Collection of Opportunity records
     * For each Opportunity record in the Collection
     *  - Opportunity is evaluated for Pricing Model
     *  - For pricing model 'Opportunity', the product data is extracted from the opportunity record
     *  - For pricing model 'CPQ', the product data is extracted from the Collection of associated Order Items
     * @param -
     * @return Map<Id, Map<String, Object>> -
     *      Key - Opportunity Id
     *      Value - Collection (Map<String, Object>) of Product Data for coresponding Opportunity
     */
    public Map<Id, Map<String, Object>> getStoreProductData(){
        Map<Id, Map<String, Object>> storeProductData = new Map<Id, Map<String, Object>>();
        for (Id opportunityId : this.opportunities.keySet()){
            Opportunity opportunity = this.opportunities.get(opportunityId);
            switch on getPricingModel(opportunity) {
                when OPPORTUNITY {
                    storeProductData.put(opportunityId, getOpportunityProductData(opportunity));
                }
                when CPQ {
                    if (this.orderItemsForOpportunity.containsKey(opportunityId)){
                        storeProductData.put(
                                opportunityId,
                                getCPQProductData(this.orderItemsForOpportunity.get(opportunityId))
                            );
                    }
                }
                when else {}
            }
        }
        return storeProductData;
    }
    /**
     * @description Return the S2N Pricing Model
     * @param Opportunity Input opportunity record
     * @return CDdS2NSyncPricingModel - enum value
     */
    public CDdS2NSyncPricingModel getPricingModel(Opportunity opportunity){
        return String.isNotBlank(opportunity.SBQQ__PrimaryQuote__c)
                ?   CDdS2NSyncPricingModel.CPQ
                :   CDdS2NSyncPricingModel.OPPORTUNITY;
    }
    /**
     * @description Is the S2N Pricing Model a CPQ Model?
     * @param Opportunity Input opportunity record
     * @return Boolean
     */
    public Boolean isCPQModel(Opportunity opportunity){
        return CDdS2NSyncPricingModel.CPQ.equals(getPricingModel(opportunity));
    }

    public Boolean isTrialOpp(){
        Boolean isTrial = false;

        for (Id opportunityId : this.opportunities.keySet()){
            Opportunity opportunity = this.opportunities.get(opportunityId);
            switch on getPricingModel(opportunity) {
                when OPPORTUNITY {
                    isTrial = String.isNotBlank(opportunity.Trial_Type__c) && (opportunity.Trial_End_Date__c == null || opportunity.Trial_End_Date__c >= System.today());
                }
                when CPQ {
                    if (this.orderItemsForOpportunity.containsKey(opportunityId)){
                        isTrial = isTrialVal(this.orderItemsForOpportunity.get(opportunityId));
                    }
                }
                when else {}
            }
        }
        return isTrial;
    }
    /**
     * @description Return the S2N Product Data for Opportunity Pricing Model
     * @param Opportunity Input opportunity record
     * @return Map<String, Object> - product data as a Map Collection
     */
    private Map<String, Object> getOpportunityProductData(Opportunity opportunity){
        Map<String, Object> productData = new Map<String, Object>(DEFAULT_PRODUCT_DATA);
        Boolean isTrial = String.isNotBlank(opportunity.Trial_Type__c) && (opportunity.Trial_End_Date__c == null || opportunity.Trial_End_Date__c >= System.today());
        Boolean isJPN = String.isNotBlank(opportunity.Legal_Entity__c) && opportunity.Legal_Entity__c.toUpperCase().equals(CDdCoreConstants.JPN);
        Set<String> CAVIAR_PLATFORMS = new Set<String>{'Caviar', 'Caviar and DoorDash'};
        Set<String> DOORDASH_PLATFORMS = new Set<String>{'DoorDash', 'Caviar and DoorDash'};

        // Set Store Data
        if (String.isNotBlank(opportunity.Order_Service_Type__c) || ('Yes'.equals(opportunity.Merchant_Agreed_to__c))){
            productData.put('offers_pickup', ((opportunity.In_App_Pickup_Commission__c != null) && ((opportunity.Order_Service_Type__c == 'Pickup Only') || (opportunity.Order_Service_Type__c == 'Delivery + Pickup') || ('Yes'.equals(opportunity.Merchant_Agreed_to__c)))) ? 'true' : 'false');
        }
        if (String.isNotBlank(opportunity.Order_Service_Type__c)){
            productData.put('offers_delivery', (String.isNotBlank(opportunity.Order_Service_Type__c) && opportunity.Order_Service_Type__c.contains('Delivery')) ? 'true' : 'false');
        }
        if (CDdNimdaSyncConstants.ENABLE_S2N_TRIAL_PRICING_TIER_AND_FEE){
            productData.put('tier_level', isTrial ? opportunity.Trial_Pricing_Tier__c : opportunity.Pricing_Tier_New__c);
        }
        if (String.isNotBlank(opportunity.DashPass_Eligible_CW__c)){
            productData.put('consumer_subscription_eligible', (opportunity.DashPass_Eligible_CW__c.equals('Yes') ? 'true' : 'false'));
        }
        Integer custom_delivery_fee;
        if (CDdNimdaSyncConstants.ENABLE_S2N_CUSTOM_DELIVERY_FEE && String.isNotBlank(opportunity.Delivery_Fee__c)){
            custom_delivery_fee = isJPN ? Integer.valueOf(opportunity.Delivery_Fee__c) : Integer.valueOf((Decimal.valueOf(opportunity.Delivery_Fee__c.subString(1)) * 100).stripTrailingZeros());
            productData.put('custom_delivery_fee', custom_delivery_fee);
        }
        if (String.isNotBlank(opportunity.Fulfills_Own_Deliveries__c)){
            productData.put('fulfills_own_deliveries', (opportunity.Fulfills_Own_Deliveries__c.equals('Yes') ? 'true' : 'false'));
        }
        // Set Store Partnership Data
        if (CDdNimdaSyncConstants.ENABLE_S2N_TRIAL_PRICING_TIER_AND_FEE){
            productData.put('service_rate', String.isNotBlank(opportunity.Trial_Type__c) ? opportunity.Trial_Service_Fee__c : opportunity.Service_Fee_New__c);
        }
        String activation_fee_dollars = CDdStringUtil.extractFirstDecimal(opportunity.Activation_Fee__c);
        if (activation_fee_dollars != null) {
            productData.put('activation_fee', CDdStringUtil.dollarsToCents(activation_fee_dollars) == '0' ? '0' : '-' + CDdStringUtil.dollarsToCents(activation_fee_dollars));
        }
        Integer weekly_tablet_fee_cents;
        Integer weekly_printer_fee_cents;
        if (opportunity.Weekly_Tablet_Subscription_Fee__c != null) {
        weekly_tablet_fee_cents = isTrial ? 0 : isJPN ? Integer.valueOf(CDdStringUtil.extractFirstDecimal(opportunity.Weekly_Tablet_Subscription_Fee__c)) : Integer.valueOf(CDdStringUtil.dollarsToCents(CDdStringUtil.extractFirstDecimal(opportunity.Weekly_Tablet_Subscription_Fee__c)));
        }
        if (opportunity.Weekly_Printer_Subscription_Fee__c != null) {
            weekly_printer_fee_cents = isTrial ? 0 : isJPN ? Integer.valueOf(CDdStringUtil.extractFirstDecimal(opportunity.Weekly_Printer_Subscription_Fee__c)) : Integer.valueOf(CDdStringUtil.dollarsToCents(CDdStringUtil.extractFirstDecimal(opportunity.Weekly_Printer_Subscription_Fee__c)));
        }
        if (apiSettings.S2N_Store_Feature_Flag__c) {
            productData.put('weekly_tablet_subscription_fee', weekly_tablet_fee_cents!=null ? String.valueOf(weekly_tablet_fee_cents) : null);
            productData.put('weekly_printer_subscription_fee', weekly_printer_fee_cents!=null ? String.valueOf(weekly_printer_fee_cents) : null);
        } else {
            productData.put('weekly_tablet_subscription_fee', (weekly_tablet_fee_cents!=null || weekly_printer_fee_cents!=null
                                                        ?   String.valueOf((weekly_tablet_fee_cents!=null ? weekly_tablet_fee_cents : 0) + (weekly_printer_fee_cents!=null ? weekly_printer_fee_cents : 0))
                                                        :   null));
        }

        if(opportunity.Platform__c!=null && DOORDASH_PLATFORMS.contains(opportunity.Platform__c)) {

            productData.put('commission_rate', isTrial ? opportunity.Trial_Commission__c : opportunity.Commission__c);

            if (opportunity.In_App_Pickup_Commission__c != null){
                productData.put('pickup_commission', isTrial ? String.valueOf(opportunity.Trial_Commission__c) : String.valueOf(opportunity.In_App_Pickup_Commission__c));
            }
             if (opportunity.DashPass_Only_Commission__c != null){
                productData.put('subscription_commission', isTrial ? String.valueOf(opportunity.Trial_Commission__c) : String.valueOf(opportunity.DashPass_Only_Commission__c));
            }
            if (opportunity.DashPass_Flat_Fee__c!=null){
                Integer dashpass_flat_fee = isJPN ? Integer.valueOf(opportunity.DashPass_Flat_Fee__c) : Integer.valueOf((opportunity.DashPass_Flat_Fee__c * 100).stripTrailingZeros());
                productData.put('dash_pass_marketing_fee', dashpass_flat_fee);
            }
            if (opportunity.Referred_Delivery_Commission__c != null){
                productData.put('reduced_commission', isTrial ? String.valueOf(opportunity.Trial_Commission__c) : String.valueOf(opportunity.Referred_Delivery_Commission__c));
            }
            if (opportunity.Referred_Pickup_Commission__c != null){
                productData.put('reduced_pickup_commission', isTrial ? String.valueOf(opportunity.Trial_Commission__c) : String.valueOf(opportunity.Referred_Pickup_Commission__c));
            }

        }
        if(opportunity.Platform__c!=null && CAVIAR_PLATFORMS.contains(opportunity.Platform__c)) {

            productData.put('delivery_fee', isTrial ? opportunity.Trial_Commission__c : (isJPN ? Integer.valueOf(opportunity.Commission__c)  : Integer.valueOf(opportunity.Commission__c)));

            if (opportunity.In_App_Pickup_Commission__c != null){
                productData.put('pickup_fee', isTrial ? String.valueOf(opportunity.Trial_Commission__c) : String.valueOf(opportunity.In_App_Pickup_Commission__c));
            }

            if (opportunity.DashPass_Only_Commission__c != null){
                productData.put('dashpass_commission', isTrial ? String.valueOf(opportunity.Trial_Commission__c) : String.valueOf(opportunity.DashPass_Only_Commission__c));
            }
            if (opportunity.DashPass_Flat_Fee__c!=null){
                //productData.put('subscription_flat_fee', opportunity.DashPass_Flat_Fee__c);
            }
            if (opportunity.Referred_Delivery_Commission__c != null){
                productData.put('weblink_delivery_fee', isTrial ? String.valueOf(opportunity.Trial_Commission__c) : String.valueOf(opportunity.Referred_Delivery_Commission__c));
            }
            if (opportunity.Referred_Pickup_Commission__c != null){
                productData.put('weblink_pickup_fee', isTrial ? String.valueOf(opportunity.Trial_Commission__c) : String.valueOf(opportunity.Referred_Pickup_Commission__c));
            }

        }
        CDdNimdaSyncStoreProductHelper storehelper = new CDdNimdaSyncStoreProductHelper(new Set<Id>{opportunity.Id});
        Map<String,Object> opplineItems = storehelper.getOpportunityLineItems(opportunity,isTrial,isJPN);
        if(opplineItems!=null && !opplineItems.isEmpty()){
            productData.putAll(opplineItems);
        }
        // Return product data
        return productData;
    }
    private Map<String,Object> getOpportunityLineItems(Opportunity opportunity, Boolean isTrial,Boolean isJPN){
        Map<String, Object> productData = new Map<String, Object>();

        List<OpportunityLineItem> opportunityLineItemsList =  [SELECT Id, OpportunityId,Name, Product2.Name, Start_Date__c, End_Date__c,
                                            Flat_Fee__c, Payment_Processing_Fee__c, Payment_Processing_Rate__c,
                                            Trial_Type__c, Length_of_Trial__c, CreatedDate, Service_Rate__c, Service_Fee__c,
                                            Subscription_Fee__c, LastModifiedDate
                                            FROM OpportunityLineItem where OpportunityId = : opportunity.Id] ;

        if(opportunityLineItemsList.size() == 0) return null;
        for (OpportunityLineItem opportunityLineItem : opportunityLineItemsList){
           if (CONFIGURED_PROGRAMS.get(PROGRAM_ONLINE_ORDERING_TRIAL_PICKUP_PROMO_PERIOD).Product_Name__c.equals(opportunityLineItem.Product2.Name)){
                productData.put('storefront_delivery_fee', dollarsToCents(opportunityLineItem.Flat_Fee__c,isJPN));
                productData.put('storefront_processing_fee', dollarsToCents(opportunityLineItem.Payment_Processing_Fee__c,isJPN));
                productData.put('storefront_processing_rate', opportunityLineItem.Payment_Processing_Rate__c);
            }
            if (CONFIGURED_PROGRAMS.get(PROGRAM_ONLINE_ORDERING_TRIAL_DELIVERY_PROMO_PERIOD).Product_Name__c.equals(opportunityLineItem.Product2.Name)){
                productData.put('storefront_pickup_fee', dollarsToCents(opportunityLineItem.Flat_Fee__c,isJPN));
                productData.put('storefront_processing_fee', dollarsToCents(opportunityLineItem.Payment_Processing_Fee__c,isJPN));
                productData.put('storefront_processing_rate', opportunityLineItem.Payment_Processing_Rate__c);
            }
            if (CONFIGURED_PROGRAMS.get(PROGRAM_ONLINE_ORDERING_DELIVERY).Product_Name__c.equals(opportunityLineItem.Product2.Name)){
                productData.put('storefront_delivery_fee', dollarsToCents(opportunityLineItem.Flat_Fee__c,isJPN));
                productData.put('storefront_processing_fee', dollarsToCents(opportunityLineItem.Payment_Processing_Fee__c,isJPN));
                productData.put('storefront_processing_rate', opportunityLineItem.Payment_Processing_Rate__c);
                productData.put('storefront_subscription_fee', dollarsToCents(opportunityLineItem.Subscription_Fee__c,isJPN));

            }
            if (CONFIGURED_PROGRAMS.get(PROGRAM_ONLINE_ORDERING_PICKUP).Product_Name__c.equals(opportunityLineItem.Product2.Name)){
                productData.put('storefront_pickup_fee', dollarsToCents(opportunityLineItem.Flat_Fee__c,isJPN));
                productData.put('storefront_processing_fee', dollarsToCents(opportunityLineItem.Payment_Processing_Fee__c,isJPN));
                productData.put('storefront_processing_rate', opportunityLineItem.Payment_Processing_Rate__c);
                productData.put('storefront_subscription_fee', dollarsToCents(opportunityLineItem.Subscription_Fee__c,isJPN));
            }
        }
        return productData;
    }
    /**
     * @description Return the S2N Product Data for CPQ Pricing Model
     * 1. Re-organize the input Order Item Collection as a Map Collection with
     *      key - Product DD Custom Id
     *      value - OrderItem record
     * 2. Process each Product property
     *      a. Retrieve the configured Product DD Custom Id as found in custom metadata
     *      b. Check if an order item record is found for the corresponding Product DD Custom Id
     *      c. If found,
     *          - Extract the S2N property value from the order Item record
     *          - Set the value in the CPQ Product Data map collection
     * @param List<OrderItem> Input Collection of OrderItem
     * @return Map<String, Object> - product data as a Map Collection
     */
    private Map<String, Object> getCPQProductData(List<OrderItem> orderItems){
        Map<String, Object> productData = new Map<String, Object>(DEFAULT_PRODUCT_DATA);
        Map<String, OrderItem> orderItemForProductDDCustomId = new Map<String, OrderItem>();
        for (OrderItem orderItem : orderItems){
            orderItemForProductDDCustomId.put(orderItem.Product2.DD_Custom_ID__c, orderItem);
        }
        for (String propertyName : CDdS2NProductPropertyHelper.getProductPropertyNames()){
            Set<String> cpqProductDDCustomIds = CDdS2NProductPropertyHelper.getCPQProductDDCustomIds(propertyName);
            for (String cpqProductDDCustomId : cpqProductDDCustomIds){
                if (String.isNotBlank(cpqProductDDCustomId) && orderItemForProductDDCustomId.containsKey(cpqProductDDCustomId)){
                    productData.put(propertyName,
                        CDdS2NProductPropertyHelper.getCPQOrderItemValue(
                            propertyName,
                            orderItemForProductDDCustomId.get(cpqProductDDCustomId))
                        );
                }
            }
        }
        return productData;
    }
    // Check if the OrderItems are eligible for Trial
    private Boolean isTrialVal(List<OrderItem> orderItems){
        Boolean isCPQTrial = false;
        Map<String, Object> productData = new Map<String, Object>(DEFAULT_PRODUCT_DATA);
        Map<String, OrderItem> orderItemForProductDDCustomId = new Map<String, OrderItem>();
        for (OrderItem orderItem : orderItems){
            orderItemForProductDDCustomId.put(orderItem.Product2.DD_Custom_ID__c, orderItem);
        }
        for (String propertyName : CDdS2NProductPropertyHelper.getProductPropertyNames()){
            Set<String> cpqProductDDCustomIds = CDdS2NProductPropertyHelper.getCPQProductDDCustomIds(propertyName);
            for (String cpqProductDDCustomId : cpqProductDDCustomIds){
                if (String.isNotBlank(cpqProductDDCustomId) && orderItemForProductDDCustomId.containsKey(cpqProductDDCustomId)){
                    isCPQTrial = CDdS2NProductPropertyHelper.isTrialOrderItem(propertyName,orderItemForProductDDCustomId.get(cpqProductDDCustomId)) ? true : false;

                }
            }
        }
        return isCPQTrial;
    }
    /**
    * @description Return the converted Integer value of dollars to cents
    **/
    private Integer dollarsToCents(Decimal input, Boolean isJPN) {
        return input!=null ? (isJPN ? input.intValue() : (input * 100).intValue()) : null;
    }
}