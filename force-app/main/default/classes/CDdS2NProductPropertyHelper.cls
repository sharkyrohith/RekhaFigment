/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 04/29/2021
*
* @group Nimda S2N Product
*
* @description  This class reads the S2N Product Property custom metadata to return S2N product property information such as
*               - Property Name (related to S2N Product such as 'Offers Delivery' or 'Commission Rate')
*               - Nimda Object (What Nimda Object does the property belong to? i.e. Store or Store Partnership)
*               - SFDC Property Type [How is the property defined in Salesforce? (i.e. Schema Display Type)]
*               - Nimda API Type [What is the Nimda API Type for the property, when posting the property in the body of REST API Request?]
*               - Is Trial Applicable [Is trial applicable for S2N Product Property]
*               - S2N_Product_CPQ_Order_Item__mdt [S2N property associated Child custom metadata for config/setting of CPQ Order Item]
*                   a) Order Item Field, which has the field api name that contains the value for S2N Property
*                   b) Order Item Trial Field, which has the field api name that contains the trial value for S2N Property
*                   c) Order Item Trail Start Date Field, which has the field api date field
*                       for when the trial starts for S2N property
*                   d) Order Item Trail Start End Field, which has the field api date field
*                       for when the trial ends for S2N property
* 
**************************************************************************************************************************************/
public class CDdS2NProductPropertyHelper {
    public static final Map<String, S2N_Product_Property__mdt> S2N_PRODUCT_PROPERTIES;
    public static final Map<String, Object> DEFAULT_S2N_PRODUCT_DATA;
    public static final Set<String> S2N_PRODUCT_CPQ_DD_CUSTOM_IDS;
    private static Set<String> ORDER_ITEM_FIELDS;
    static {
        S2N_PRODUCT_PROPERTIES = new Map<String, S2N_Product_Property__mdt>();
        DEFAULT_S2N_PRODUCT_DATA = new Map<String, Object>();
        S2N_PRODUCT_CPQ_DD_CUSTOM_IDS = new Set<String>();
        for (S2N_Product_Property__mdt p : [SELECT Id, Is_Active__c, MasterLabel, DeveloperName, 
                                            Nimda_Object__c, SFDC_Property_Type__c, Nimda_API_Type__c,
                                            Is_Trial_Applicable__c,
                                            (SELECT Product_DD_Custom_ID__c, Order_Item_Field__c,
                                            Order_Item_Trial_Field__c, Order_Item_Trial_Start_Date_Field__c,
                                            Order_Item_Trial_End_Date_Field__c 
                                            FROM S2N_Product_CPQ_Order_Items__r
                                            )
                                            FROM S2N_Product_Property__mdt
                                            WHERE Is_Active__c = TRUE]){
            S2N_PRODUCT_PROPERTIES.put(p.DeveloperName, p);
            DEFAULT_S2N_PRODUCT_DATA.put(p.DeveloperName, null);
            for (S2N_Product_CPQ_Order_Item__mdt c : p.S2N_Product_CPQ_Order_Items__r){
                S2N_PRODUCT_CPQ_DD_CUSTOM_IDS.add(c.Product_DD_Custom_ID__c);
                addOrderItemField(c.Order_Item_Field__c);
                addOrderItemField(c.Order_Item_Trial_Field__c);
                addOrderItemField(c.Order_Item_Trial_Start_Date_Field__c);
                addOrderItemField(c.Order_Item_Trial_End_Date_Field__c);
            }
        }
    }
    /**
     * @description Add the order item field api name from custom metadata record, if not null
     * @param String orderItemField
     * @return 
     */    
    private static void addOrderItemField(String orderItemField){
        if (ORDER_ITEM_FIELDS == null){
            ORDER_ITEM_FIELDS = new Set<String>();
        }
        if (String.isNotBlank(orderItemField)){
            ORDER_ITEM_FIELDS.add(orderItemField);
        }
    }
    /**
     * @description Get default product data for S2N
     * - Build a Map collection with all the product properties (defined in custom metadata) as key 
     *   and set the default value as NULL for each property
     * - Return the Map Collection as the default product data to the Caller of this operation
     * @param -
     * @return Map<String, Object>
     */
    public static Map<String, Object> getDefaultProductData(){
        return DEFAULT_S2N_PRODUCT_DATA;
    }
    /**
     * @description Return all the S2N Property Names as a Set Collection
     * @param -
     * @return Set<String>
     */
    public static Set<String> getProductPropertyNames(){
        return S2N_PRODUCT_PROPERTIES.keySet();
    }
    /**
     * @description Return the Order Item Field API names as found configured in the 
     * 'S2N Product CPQ Order Item' Custom Metadata records
     * @param -
     * @return Set<String> Collection of Order Item field API Names
     */      
    public static Set<String> getOrderItemFields(){
        return ORDER_ITEM_FIELDS;
    }    
    /**
     * @description Return the Property Display Type (SFDC Schema Field Type) for the input product property
     * @param String propertyName
     * @return String - the Product Property Type
     */    
    public static String getProductPropertyType(String propertyName){
        return S2N_PRODUCT_PROPERTIES.containsKey(propertyName)
                ? S2N_PRODUCT_PROPERTIES.get(propertyName).SFDC_Property_Type__c
                : null;
    }
    /**
     * @description Return the S2N CPQ Product DD Custom Id Collection
     * @param -
     * @return String - Return the Collection of CPQ Product DD Custom Id
     */     
    public static Set<String> getCPQProductDDCustomIds(){
        return S2N_PRODUCT_CPQ_DD_CUSTOM_IDS;
    }    
    /**
     * @description Return a Collection of CPQ Product DD Custom Ids for the S2N property 
     * Note: More than one cpq product may influence a S2N property in the backend
     * @param String propertyName
     * @return Set<String> - Return a Collection of CPQ Product DD Custom Ids
     */     
    public static Set<String> getCPQProductDDCustomIds(String propertyName){
        Set<String> cpqProductDDCustomIds = new Set<String>();
        if (S2N_PRODUCT_PROPERTIES.containsKey(propertyName) 
                    && !S2N_PRODUCT_PROPERTIES.get(propertyName).S2N_Product_CPQ_Order_Items__r.isEmpty()){
            for (S2N_Product_CPQ_Order_Item__mdt item : S2N_PRODUCT_PROPERTIES.get(propertyName).S2N_Product_CPQ_Order_Items__r){
                cpqProductDDCustomIds.add(item.Product_DD_Custom_ID__c);
            }
        }
        return cpqProductDDCustomIds;
    }
    /**
     * @description Return the S2N Product CPQ Order Item Setting [child custom metadata for S2N Product Property] 
     * @param String propertyName
     * @param String productDDCustomId
     * @return S2N_Product_CPQ_Order_Item__mdt - Return the S2N Product CPQ Order Item Setting
     */     
    public static S2N_Product_CPQ_Order_Item__mdt getCPQProductOrderItemSetting(String propertyName, String productDDCustomId){
        S2N_Product_CPQ_Order_Item__mdt s2nProductCPQOrderItem = null;
        if (S2N_PRODUCT_PROPERTIES.containsKey(propertyName) 
                    && !S2N_PRODUCT_PROPERTIES.get(propertyName).S2N_Product_CPQ_Order_Items__r.isEmpty()){
            for (S2N_Product_CPQ_Order_Item__mdt item : S2N_PRODUCT_PROPERTIES.get(propertyName).S2N_Product_CPQ_Order_Items__r){
                if (productDDCustomId.equals(item.Product_DD_Custom_ID__c)){
                    s2nProductCPQOrderItem = item;
                }                                
            }
        }
        return s2nProductCPQOrderItem;
    }    
    /**
     * @description Return the Property API Type (i.e. the field type of the property as included in post body of REST API) 
     * @param String propertyName
     * @return String - the Product Property API Type
     */     
    public static String getProductPropertyAPIType(String propertyName){
        return S2N_PRODUCT_PROPERTIES.containsKey(propertyName)
                ? S2N_PRODUCT_PROPERTIES.get(propertyName).Nimda_API_Type__c
                : null;
    }
    /**
     * @description Return the Is_Trial_Applicable__c for the S2N Property 
     * @param String propertyName
     * @return Boolean - Is trial applicable for S2N Property
     */     
    public static Boolean isTrialApplicableForProperty(String propertyName){
        return S2N_PRODUCT_PROPERTIES.containsKey(propertyName)
                ? S2N_PRODUCT_PROPERTIES.get(propertyName).Is_Trial_Applicable__c
                : false;
    }    
    /**
     * @description Check if the order item record a trial record
     * 1. Check if trial is applicable for the S2N property
     * 2. If so, then check if the trial data points for Order item have values in them
     * 3. And finally check if the data point for Order Item trial end date is >= Today
     * Return true if all the above conditions are met
     * @param String propertyName
     * @param OrderItem order item record
     * @return Boolean - Is the Order Item a trial record? True or False
     */      
    public static Boolean isTrialOrderItem(String propertyName, OrderItem orderItem){
        Map<String, Object> fieldsToValue = orderItem.getPopulatedFieldsAsMap();
        S2N_Product_CPQ_Order_Item__mdt mdtRec = getCPQProductOrderItemSetting(propertyName, orderItem.Product2.DD_Custom_ID__c);
        return
            mdtRec != null 
            &&
            isTrialApplicableForProperty(propertyName)
            &&
            fieldsToValue.containsKey(mdtRec.Order_Item_Trial_Field__c)
            &&
            fieldsToValue.get(mdtRec.Order_Item_Trial_Field__c) != null 
            &&
            fieldsToValue.containsKey(mdtRec.Order_Item_Trial_Start_Date_Field__c) 
            &&
            fieldsToValue.get(mdtRec.Order_Item_Trial_Start_Date_Field__c) != null 
            &&
            fieldsToValue.containsKey(mdtRec.Order_Item_Trial_End_Date_Field__c) 
            &&
            fieldsToValue.get(mdtRec.Order_Item_Trial_End_Date_Field__c) != null
            &&
            (Date)fieldsToValue.get(mdtRec.Order_Item_Trial_End_Date_Field__c) >= System.today()
        ;
    }
    /**
     * @description Return the CPQ Order Item value for the input S2N product property
     * Return NULL, if the configured Product DD Custom Id for the S2N product property
     * DOES NOT MATCH the Product DD Custom Id found on the input Order Ietm record
     * 1. If the S2N product proerty type is Boolean, return the value 'true'
     * 2. If the Order Item represents a trial record, then return the value from the Order Item configured Trial field
     * 3. Else, return the value from the Order Item configured regular field
     * NOTE : The return value is converted to Nimda API Type, prior to returning the value to the Caller of this operation
     * @param String propertyName
     * @param OrderItem order item record
     * @return Object - return the CPQ Order Item value for the input S2N product property
     */        
    public static Object getCPQOrderItemValue(String propertyName, OrderItem orderItem){
        Set<String> cpqProductDDCustomIds = getCPQProductDDCustomIds(propertyName);
        if (cpqProductDDCustomIds.isEmpty()
            ||
            !cpqProductDDCustomIds.contains(orderItem.Product2.DD_Custom_ID__c)){
            return null;
        }
        S2N_Product_CPQ_Order_Item__mdt mdtRec = getCPQProductOrderItemSetting(propertyName, orderItem.Product2.DD_Custom_ID__c);
        String orderItemCurrency = orderItem.get('CurrencyIsoCode')!=null ? (String)orderItem.get('CurrencyIsoCode') : null;
        Object value = getProductPropertyType(propertyName).equals('Boolean')
                        ?   true 
                        : ( isTrialOrderItem(propertyName, orderItem)
                            ?   orderItem.get(mdtrec.Order_Item_Trial_Field__c)
                            :   orderItem.get(mdtrec.Order_Item_Field__c)
                        );
        return convertToAPIType(propertyName, value,orderItemCurrency);
    }    
    /**
     * @description Convert the value to API type supported by DSJ REST API
     * @param String propertyName
     * @param Object value
     * @return Object - return the converted value
     */     
    public static Object convertToAPIType(String propertyName, Object value , String currencyVal) {
        if (value == null){
            return null;
        }
        String propertyType = getProductPropertyType(propertyName);
        String apiType = getProductPropertyAPIType(propertyName);
        Boolean isJPY = currencyVal == 'JPY' ? true : false;
        Object retVal = value;
        switch on (propertyType){
            when 'Boolean' {
                retVal = 'String'.equals(apiType) ? String.valueOf(value) : value;
            }
            when 'Currency', 'Percent' {
                switch on apiType {
                    when 'Cents'{
                        retVal = isJPY ? ((Decimal)value) : ((Decimal)value * 100).intValue();
                    }
                    when 'String' { 
                        retVal = ((Decimal)value).toPlainString(); 
                    }
                    when else { retVal = value; }                                            
                }
            }
            when else { retVal = String.valueOf(value); }
        }
        return retVal;
    }                     
}