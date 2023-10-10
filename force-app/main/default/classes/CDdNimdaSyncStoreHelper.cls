/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 10/16/2019
*
* @group Nimda
*
* @description This class will provide helper methods to GET a store, Update a store etc.
*   - It utilizes the configuration found in Custom Metadata 'Nimda Store Field Definition' 
*   
**************************************************************************************************************************************/
public class CDdNimdaSyncStoreHelper {

    private static final vCS__c apiSettings = vCS__c.getInstance();
    private static final List<Nimda_Store_Field_Definition__mdt> nimdaStoreFieldDefinitions;
    private static final List<Nimda_Store_Partnership_Field_Definition__mdt> nimdaStorePartnershipFieldDefinitions;
    private static final String EXTRA_PARAM = 'extra=';

    static {
        nimdaStoreFieldDefinitions = new List<Nimda_Store_Field_Definition__mdt>();
        for (Nimda_Store_Field_Definition__mdt d : [SELECT Id, Sequence__c , MasterLabel, DeveloperName,
                                                    Include_In_Compact_Layout__c, Is_Readable__c, Is_Editable__c 
                                                    FROM Nimda_Store_Field_Definition__mdt 
                                                    ORDER BY Sequence__c ASC]){
            nimdaStoreFieldDefinitions.add(d);
        }
        nimdaStorePartnershipFieldDefinitions = new List<Nimda_Store_Partnership_Field_Definition__mdt>();
        for (Nimda_Store_Partnership_Field_Definition__mdt d : [SELECT Id, Sequence__c , MasterLabel, DeveloperName,
                                                    Include_In_Compact_Layout__c, Is_Readable__c, Is_Editable__c 
                                                    FROM Nimda_Store_Partnership_Field_Definition__mdt 
                                                    ORDER BY Sequence__c ASC]){
            nimdaStorePartnershipFieldDefinitions.add(d);
        }
    }
    /**
    * @description Read the Nimda Store field definition configuration to 
    * return the extra field query parameter string for 'GET' store DoorDash Rest API
    * REST Endpoint referenced is '/v1/stores/<store id>/'
    * @return Return the extra field query parameter string
    **/  
    public static String getStoreExtraFieldQueryString(){
        String retVal = '';
        for (Nimda_Store_Field_Definition__mdt d : nimdaStoreFieldDefinitions){
            if (d.Is_Readable__c){
                retVal += ((String.isNotBlank(retVal) ? '&' : '?') + EXTRA_PARAM + d.DeveloperName);
            }
        }
        return retVal;
    }
    /**
    * @description Read the Nimda Store Partnership field definition configuration to 
    * return the extra field query parameter string for 'GET' store DoorDash Rest API
    * REST Endpoint referenced is '/v1/stores/<store id>/store_partnerships/'
    * @return Return the extra field query parameter string
    **/  
    public static String getStorePartnershipExtraFieldQueryString(){
        String retVal = '';
        for (Nimda_Store_Partnership_Field_Definition__mdt d : nimdaStorePartnershipFieldDefinitions){
            if (d.Is_Readable__c){
                retVal += ((String.isNotBlank(retVal) ? '&' : '?') + EXTRA_PARAM + d.DeveloperName);
            }
        }
        return retVal;
    }    
    /**
    * @description Get Nimda Store field definitions from custom metadata
    * @return Collection of store field definitions - List<Nimda_Store_Field_Definition__mdt>
    **/    
    public static List<Nimda_Store_Field_Definition__mdt> getNimdaStoreFieldDefinitions(){
        return nimdaStoreFieldDefinitions;
    }
    /**
    * @description Prepare and return the store request object using data from the Account and Opportunity record
    * @param String input step - Is the request for Create Store or Update Store?
    * @param String input Business Id
    * @param Account input account record   
    * @param Opportunity input opportunity record    
    * @return the store request object <CDdRestJSONObj.DoorstepStoreRequest>
    **/             
    public static CDdRestJSONObj.DoorstepStoreRequest getStoreRequest(String step, String businessId, Account account, Opportunity opportunity) {
        Map<String, Object> storeRequest = new Map<String, Object>();
        storeRequest.putAll(getStoreData(step, businessId, account, opportunity));
        storeRequest.putAll(new CDdNimdaSyncStoreProductHelper(new Set<Id>{opportunity.Id}).getStoreProductData().get(opportunity.Id));
        return (CDdRestJSONObj.DoorstepStoreRequest)JSON.deserialize(
            JSON.serialize(storeRequest), 
            CDdRestJSONObj.DoorstepStoreRequest.class
        );
    }
    /**
    * @description Return the store data map Collection using data from the Account and Opportunity record
    * - Collecton key - Store Property Name
    * - Collection value - value extracted from Account (or Opportunity object) - refer to input parameters 
    * @param String input step - Is the request for Create Store or Update Store?
    * @param String input Business Id
    * @param Account input account record   
    * @param Opportunity input opportunity record    
    * @return Map<String, Object> return the store data map Collection
    **/     
    public static Map<String, Object> getStoreData(String step, String businessId, Account account, Opportunity opportunity){
        Map<String, Object>  storeData = new Map<String, Object>();
        CDdNimdaSyncValidator validator = new CDdNimdaSyncValidator(account, opportunity);
        Boolean hasAddressFields = validator.fieldValidator(account, CDdNimdaSyncConstants.VALIDATE_ADDRESS_FIELDS_ON_ACCOUNT).isEmpty();
        Boolean isMarketplace = new List<String>{CDdSchemaUtils.OPPORTUNITY_RT.mlInsideSalesId(), CDdSchemaUtils.OPPORTUNITY_RT.enterpriseMarketplaceId()}.indexOf(opportunity.RecordTypeId) > -1;
        Boolean isTrial = String.isNotBlank(opportunity.Trial_Type__c) && (opportunity.Trial_End_Date__c == null || opportunity.Trial_End_Date__c >= System.today());

        storeData.put('name', account.Name);
        storeData.put('submarket_id', '2');
        storeData.put('business_id', businessId);
        storeData.put('phone_number', (account.BillingCountryCode.equals('AU') ? '+61' : '') + CDdStringUtil.formatPhoneNum(account.Phone, account.BillingCountryCode));
        storeData.put('is_partner', 'true');
        storeData.put('active', 'false');

        if (!String.isBlank(opportunity.Order_Protocol_Email__c)) {
            storeData.put('email', opportunity.Order_Protocol_Email__c);
            storeData.put('error_report_emails', '["' + opportunity.Order_Protocol_Email__c + '"]');
        } else {
            storeData.put('error_report_emails', '["' + opportunity.DM_Email__c + '"]');
        }
        storeData.put('order_protocol', CDdNimdaSyncConstants.SFTODSJ_STORE_ORDERPROTOCOLMAP.get(opportunity.Order_Protocol__c));
        storeData.put('confirm_protocol', CDdNimdaSyncConstants.SFTODSJ_STORE_ORDERTOCONFIRMPROTOCOLMAP.get((String)storeData.get('order_protocol')));
        if(validator.isOrderProtocolPointOfSale()) {
            storeData.put('special_instructions_max_length', '0');
        }
        if (CDdNimdaSyncConstants.STEP_CREATE_STORE.equals(step) && validator.isOrderProtocolPointOfSale()){
            storeData.put('order_protocol', 'OTHER');
            storeData.put('confirm_protocol', 'NO_CONFIRMATION');
        }        
        if (CDdNimdaSyncConstants.STEP_UPDATE_STORE.equals(step)){
            storeData.put('provider_type', (String.isNotBlank(opportunity.POS_Integration_Type__c) ? opportunity.POS_Integration_Type__c : null));
            storeData.put('location_id', opportunity.POS_Integration_ID__c);            
        }        
        storeData.put('error_report_emails', '["' + opportunity.DM_Email__c + '"]');
        storeData.put('contact_emails', '["' + opportunity.DM_Email__c + '"]');
                                   
        storeData.put('salesforce_id', opportunity.AccountId);
        storeData.put('salesforce_lead_id', account.Converted_Lead_ID__c);
        storeData.put('error_report_frequency', 'daily + weekly');
        storeData.put('price_range', account.Price_Range_S2N__c != null ? String.valueOf(account.Price_Range_S2N__c.length()) : '2');
        storeData.put('fax_number', opportunity.Order_Protocol_Fax__c != null 
                                        ? (account.BillingCountryCode.equals('AU') ? '+61' : '+1') + CDdStringUtil.formatPhoneNum(opportunity.Order_Protocol_Fax__c, account.BillingCountryCode) 
                                        : null);
        storeData.put('max_order_size', String.valueOf(opportunity.Maximum_Order_Size__c));
        storeData.put('override_tax_rate', String.valueOf(opportunity.Tax_Override_Rate__c));
        if (hasAddressFields) {
            storeData.put('street_address', String.valueOf(account.BillingStreet));
            storeData.put('city', String.valueOf(account.BillingCity));
            storeData.put('zipcode', String.valueOf(account.BillingPostalCode));
            storeData.put('state', String.valueOf(account.BillingState));            
        } else {
            storeData.put('lat', account.BillingLatitude);
            storeData.put('lng', account.BillingLongitude);
        }
        if (opportunity.Custom_Delivery_Radius__c != null){
            storeData.put('delivery_radius', opportunity.Custom_Delivery_Radius__c.toPlainString());
            storeData.put('max_delivery_radius', opportunity.Custom_Delivery_Radius__c.toPlainString());
        }       
        if(opportunity.Max_Delivery_radius_KM__c != null){
            storeData.put('max_delivery_radius', (opportunity.Max_Delivery_radius_KM__c * 1000).toPlainString());         
        }
        storeData.put('fulfills_own_deliveries_disabled', (account.Fulfills_Own_Deliveries_Disabled__c ? 'true' : 'false'));
        if (opportunity.Inflation__c != null){
            storeData.put('inflation_rate', opportunity.Inflation__c);
        }
        if (opportunity.Inflation_Rounding_Unit__c != null){
            storeData.put('inflation_rounding_unit', opportunity.Inflation_Rounding_Unit__c.toPlainString());
        }            
        if (String.isNotBlank(account.Merchant_Supplied_ID__c)){
            storeData.put('merchant_supplied_id', account.Merchant_Supplied_ID__c);
        }
        if (CDdNimdaSyncConstants.ENABLE_S2N_CREATION_METHOD && CDdNimdaSyncConstants.STEP_CREATE_STORE.equals(step) 
                && String.isNotBlank(account.Formstack_Version__c) && !CDdNimdaSyncConstants.ACCOUNT_FORMSTACK_VERSION_SSMO.equals(account.Formstack_Version__c)) {
                storeData.put('creation_method', System.Label.NimdaFormStackCreationMethod);
        }
        storeData.put('test', 'false');        
        storeData.put('formatted_address', getFormattedAddress(account));         
        storeData.put('auto_release_enabled', (opportunity.AOR_Enabled__c ? 'true' : 'false'));
        if(opportunity.AOR_Distance__c != null){
            storeData.put('auto_release_distance', (opportunity.AOR_Distance__c).toPlainString());         
        }         
        storeData.put('payment_protocol', getPaymentProtocol(opportunity.Shopping_Protocol__c)); 
        return storeData;
    }
    /**
     *  BZAP-10275 - Return formatted address 
     **/
    public static String getFormattedAddress(Account account){
        String formattedAddress = '{0}, {1}, {2} {3}, {4}';
        List<String> addressParameters = new List<String>{
            String.isNotBlank(account.BillingStreet) ? account.BillingStreet : '',
            String.isNotBlank(account.BillingCity) ? account.BillingCity : '',
            String.isNotBlank(account.BillingStateCode) ? account.BillingStateCode : '',
            String.isNotBlank(account.BillingPostalCode) ? account.BillingPostalCode : '',
            String.isNotBlank(account.BillingCountryCode) ? account.BillingCountryCode : ''
        };
        return String.format(formattedAddress, addressParameters); 
    }
    public static Boolean isChangeOfOwnership(Opportunity opportunity){
        return CDdNimdaSyncConstants.ENABLE_S2N_CHANGE_OF_OWNERSHIP && CDdNimdaSyncConstants.OPPORTUNITY_TYPE_CHANGE_OF_OWNERSHIP.equals(opportunity.Type);        
    }   
    /**
     * BZAP-12385 derive Payment Protocol based on the Shopping Protocol PickListValue on Opportunity
     * @param shoppingProtocol shoppingProtocol picklist value on Oppportunity   
     * @return String paymentProtocol is calculated based on the Shopping Protocol Value
     **/
    public static String getPaymentProtocol(String shoppingProtocol){
        String paymentProtocol = CDdNimdaSyncConstants.DIRECT_DEPOSIT;
        CDdNimdaSyncConstants.ShoppingProtocolValue shoppingProtocolValue = CDdNimdaSyncConstants.shoppingProtocolMap.get(shoppingProtocol);
        switch on (shoppingProtocolValue) {
            when MX_PICK {
                paymentProtocol = CDdNimdaSyncConstants.DIRECT_DEPOSIT;
            }
            when SHOPPER_PICK {
                paymentProtocol = CDdNimdaSyncConstants.ORDER_PLACER_RED_CARD;
            }                
            when DASHER_PICK {
                paymentProtocol = CDdNimdaSyncConstants.DASHER_RED_CARD;
            }
        }
            return paymentProtocol;
    }  
    
}