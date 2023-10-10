/********************************************************************************************************************
* @author Sriram
* @date 11/08/2021
*
* @group Merchant Services
*
* @description Apex test data setup for CPQ     
* 
**************************************************************************************************************************************/
public class CDdMxSxTestCPQSetup {
    public static final String CPQ_STATIC_RESOURCE_NAME = 'SRDd_CPQ_FeeOnboarding_TestData';
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
    static {
        StaticResource sr = [SELECT Body FROM StaticResource WHERE Name = :CPQ_STATIC_RESOURCE_NAME LIMIT 1];
        CPQ_PRODUCT_DD_CUSTOM_IDS = new Set<String>();
        Map<String, Object> cpq_product_config_data = (Map<String, Object>)JSON.deserializeUntyped(sr.Body.toString());
        CPQ_DD_CUSTOM_ID_CONFIG_DATA = new Map<String, Map<String, Object>>();
        for (String ddCustomId : cpq_product_config_data.keySet()){
            CPQ_PRODUCT_DD_CUSTOM_IDS.add(ddCustomId);
            String cpqProductDDCustomIdData = JSON.serialize(cpq_product_config_data.get(ddCustomId));
            CPQ_DD_CUSTOM_ID_CONFIG_DATA.put(ddCustomId, (Map<String, Object>)JSON.deserializeUntyped(cpqProductDDCustomIdData));
        }
    }
    /**
     * @description Insert CPQ Product records
     * @param 
     * @return 
     */ 
    public static void insertCPQProducts(){
        Map<String, Product2> productForDDCustomId = new Map<String, Product2>();
        for(String ddCustomId : CPQ_PRODUCT_DD_CUSTOM_IDS){
            Product2 product = TDdCPQTestDataFactory.createProduct(false); 
            product.Name = (String)CPQ_DD_CUSTOM_ID_CONFIG_DATA.get(ddCustomId).get(CPQ_CONFIG_KEY_PRODUCT_NAME);
            product.Package_Name__c = (String)CPQ_DD_CUSTOM_ID_CONFIG_DATA.get(ddCustomId).get(CPQ_CONFIG_KEY_PACKAGE_NAME); 
            product.Platform__c = (String)CPQ_DD_CUSTOM_ID_CONFIG_DATA.get(ddCustomId).get(CPQ_CONFIG_KEY_PLATFORM);  
            product.DD_Custom_ID__c = ddCustomId;
            productForDDCustomId.put(ddCustomId, product);
        }   
        insert productForDDCustomId.values();
    }
    /**
     * @description Return CPQ Product records by DD Custom Id
     * @param 
     * @return Map<String, Product2>
     */     
    public static Map<String, Product2> getCPQProductsByDDCustomId(){
        Map<String, Product2> cpqProductsByDDCustomId = new Map<String, Product2>();
        for (Product2 p : [ SELECT Id, Name, Package_Name__c, Platform__c, DD_Custom_ID__c 
                            FROM Product2
                            WHERE DD_Custom_ID__c IN :CPQ_PRODUCT_DD_CUSTOM_IDS ]){
            cpqProductsByDDCustomId.put(p.DD_Custom_ID__c, p);
        }
        return cpqProductsByDDCustomId;
    }
    /**
     * @description Insert CPQ Price Book Entry records
     * @param 
     * @return 
     */     
    public static void insertCPQPriceBookEntries(){
        Map<String, PricebookEntry> pbeForDDCustomId = new Map<String, PricebookEntry>();
        Map<String, Product2> cpqProductsByDDCustomId = getCPQProductsByDDCustomId();
        for(String ddCustomId : CPQ_PRODUCT_DD_CUSTOM_IDS){
            Product2 product = cpqProductsByDDCustomId.get(ddCustomId);
            PricebookEntry pbe = TDdCPQTestDataFactory.createPriceBookEntry(product, 'USD', false);
            pbeForDDCustomId.put(product.DD_Custom_ID__c, pbe);
        }
        insert pbeForDDCustomId.values();        
    }
    /**
     * @description Return CPQ Price Book Entry records by DD Custom Id
     * @param 
     * @return Map<String, PricebookEntry>
     */     
    public static Map<String, PricebookEntry> getCPQPriceBookEntriesByDDCustomId(){
        Map<String, PricebookEntry> cpqPriceBookEntriesByDDCustomId = new Map<String, PricebookEntry>();
        for (PricebookEntry pbe : [ SELECT Id, Pricebook2Id, Product2Id, Product2.DD_Custom_ID__c , UnitPrice, IsActive, CurrencyIsoCode
                                    FROM PricebookEntry
                                    WHERE Product2.DD_Custom_ID__c IN :CPQ_PRODUCT_DD_CUSTOM_IDS]){
            cpqPriceBookEntriesByDDCustomId.put(pbe.Product2.DD_Custom_ID__c, pbe);
        }
        return cpqPriceBookEntriesByDDCustomId;
    }
    /**
     * @description Insert CPQ Quote Line records
     * @param SBQQ__Quote__c quote
     * @return 
     */      
    public static void insertQuoteLines(SBQQ__Quote__c quote){
        Map<String, Product2> cpqProductsByDDCustomId = getCPQProductsByDDCustomId();
        Map<String, PricebookEntry> cpqPriceBookEntriesByDDCustomId = getCPQPriceBookEntriesByDDCustomId();
        // Get package product and price book entry
        Product2 packageProduct = cpqProductsByDDCustomId.get(CPQ_STOREFRONT_PACKAGE_DD_CUSTOM_ID);
        PricebookEntry packagePricebookEntry = cpqPriceBookEntriesByDDCustomId.get(CPQ_STOREFRONT_PACKAGE_DD_CUSTOM_ID);            
        // Create storefront package quote line - BEGIN 
        SBQQ__QuoteLine__c packageQuoteLine = TDdCPQTestDataFactory.createQuoteLine(packageProduct, quote, false);
        packageQuoteLine.SBQQ__PricebookEntryId__c = packagePricebookEntry.Id;
        packageQuoteLine.SBQQ__Quantity__c = 1;
        insert packageQuoteLine;
        // Create storefront package quote line - END
        // Create non-package quote lines - BEGIN
        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();
        for(String ddCustomId : CPQ_PRODUCT_DD_CUSTOM_IDS){
            // quoueline for storefront package is already processed
            if (!CPQ_STOREFRONT_PACKAGE_DD_CUSTOM_ID.equals(ddCustomId)){
                Product2 product = cpqProductsByDDCustomId.get(ddCustomId);
                Boolean isTrialConfig = (Boolean)CPQ_DD_CUSTOM_ID_CONFIG_DATA.get(ddCustomId).get(CPQ_CONFIG_KEY_IS_TRIAL);
                SBQQ__QuoteLine__c quoteLine = TDdCPQTestDataFactory.createQuoteLine(product, quote, false);
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
                quoteLines.add(quoteLine);
            }
        }
        // Create non-package quote lines - END  
        insert quoteLines;       
    }
    /**
     * @description Return CPQ Quote Line records by DD Custom Id
     * @param SBQQ__Quote__c quote
     * @return Map<String, SBQQ__QuoteLine__c>
     */      
    public static Map<String, SBQQ__QuoteLine__c> getQuoteLinesByDDCustomId(SBQQ__Quote__c quote){
        Map<String, SBQQ__QuoteLine__c> quoteLinesByDDCustomId = new Map<String, SBQQ__QuoteLine__c>();
        for (SBQQ__QuoteLine__c ql : [ SELECT Id, SBQQ__Quote__c, SBQQ__Product__c, SBQQ__Product__r.DD_Custom_ID__c , SBQQ__Quantity__c, 
                                        SBQQ__BillingFrequency__c, SBQQ__BillingType__c, SBQQ__ChargeType__c, SBQQ__ListPrice__c, 
                                        SBQQ__SubscriptionPricing__c, SBQQ__SubscriptionTerm__c, SBQQ__NetPrice__c
                                        FROM SBQQ__QuoteLine__c
                                        WHERE SBQQ__Quote__c = :quote.Id]){
            quoteLinesByDDCustomId.put(ql.SBQQ__Product__r.DD_Custom_ID__c, ql);
        }
        return quoteLinesByDDCustomId;        
    }
    /**
     * @description Insert Order Item records
     * @param Order order
     * @param SBQQ__Quote__c quote
     * @return 
     */     
    public static void insertOrderItems(Order order, SBQQ__Quote__c quote){
        Map<String, Product2> cpqProductsByDDCustomId = getCPQProductsByDDCustomId();
        Map<String, PricebookEntry> cpqPriceBookEntriesByDDCustomId = getCPQPriceBookEntriesByDDCustomId();        
        Map<String, SBQQ__QuoteLine__c> quoteLinesByDDCustomId = getQuoteLinesByDDCustomId(quote);
        // Create storefront package order item - BEGIN
        Product2 packageProduct = cpqProductsByDDCustomId.get(CPQ_STOREFRONT_PACKAGE_DD_CUSTOM_ID);
        PricebookEntry packagePricebookEntry = cpqPriceBookEntriesByDDCustomId.get(CPQ_STOREFRONT_PACKAGE_DD_CUSTOM_ID);         
        OrderItem packageOrderItem = TDdCPQTestDataFactory.createOrderItem(
                                        order,
                                        quoteLinesByDDCustomId.get(CPQ_STOREFRONT_PACKAGE_DD_CUSTOM_ID), 
                                        packagePricebookEntry.Id, 
                                        false);
        packageOrderItem.PricebookEntryId = packagePricebookEntry.Id;
        packageOrderItem.SBQQ__QuotedQuantity__c = 1;
        packageOrderItem.SBQQ__OrderedQuantity__c = 1;
        insert packageOrderItem;
        // Create storefront package order item - END
        List<OrderItem> orderItems = new List<OrderItem>();
        for(String ddCustomId : CPQ_PRODUCT_DD_CUSTOM_IDS){
            // Order Item for storefront package is already processed
            if (!CPQ_STOREFRONT_PACKAGE_DD_CUSTOM_ID.equals(ddCustomId)){                    
                SBQQ__QuoteLine__c quoteLine = quoteLinesByDDCustomId.get(ddCustomId);
                PricebookEntry pricebookEntry = cpqPriceBookEntriesByDDCustomId.get(ddCustomId);
                OrderItem orderItem = TDdCPQTestDataFactory.createOrderItem(
                                                order,
                                                quoteLine, 
                                                pricebookEntry.Id, 
                                                false);
                String fieldName = (String)CPQ_DD_CUSTOM_ID_CONFIG_DATA.get(ddCustomId).get(CPQ_CONFIG_KEY_ORDER_ITEM_FIELD_NAME);
                Object fieldvalue = (Object)CPQ_DD_CUSTOM_ID_CONFIG_DATA.get(ddCustomId).get(CPQ_CONFIG_KEY_ORDER_ITEM_FIELD_VALUE);
                if (fieldName!=null && fieldvalue!=null){
                    orderItem.put(fieldName, fieldvalue);
                }                
                orderItem.PricebookEntryId = pricebookEntry.Id;
                // Add package order item reference to order items with storefront products 
                if (CPQ_STOREFRONT_PRODUCT_DD_CUSTOM_IDS.contains(ddCustomId)){
                    orderItem.SBQQ__RequiredBy__c = packageOrderItem.Id;
                }
                orderItem.SBQQ__QuotedQuantity__c = 1;
                orderItem.SBQQ__OrderedQuantity__c = 1;
                orderItems.add(orderItem);                                    
            }
        }  
        insert orderItems;        
    }
    /**
     * @description Return Order Item records by DD Custom Id
     * @param Order order
     * @return Map<String, OrderItem>
     */       
    public static Map<String, OrderItem> getOrderItemsByDDCustomId(Id orderId){
        Map<String, OrderItem> orderItemsByDDCustomId = new Map<String, OrderItem>();
        for (OrderItem oi : [ SELECT Id, OrderId, Product2Id, Product2.Name, Product2.Family, Product2.DD_Custom_ID__c, Quantity 
                                FROM OrderItem
                                WHERE OrderId = :orderId]){
            orderItemsByDDCustomId.put(oi.Product2.DD_Custom_ID__c, oi);
        }
        return orderItemsByDDCustomId;        
    }
    /**
     * @description Return Storefront Package Order Item record
     * @param Id orderId
     * @return OrderItem
     */      
    public static OrderItem getStorefrontPackageOrderItem(Id orderId){
        Map<String, OrderItem> orderItemsByDDCustomId = getOrderItemsByDDCustomId(orderId);
        return orderItemsByDDCustomId.get(CPQ_STOREFRONT_PACKAGE_DD_CUSTOM_ID);
    }   
}