public with sharing class VDeliveryInformation {
	//public static Set<String> VALID_SUBMARKETS = new Set<String>();
	public static Map<String, String> COUNTRY_MAP = new Map<String, String>();
    public static Map<String, String> State_MAP = new Map<String, String>();
    //public static Boolean dispatchAllFields = CDdExperimentSvc.getFeatureFlag('Dispatch_All_Fields__c');
    
    //BZAPSUP-1438 Tia Xuan 06/2021 Dispatch with Japanese numbers
    private static final String ZERO_PREFIX = '0';
    private static final String AUSTRALIA_COUNTRY_CODE = 'AU';
    private static final String AUSTRALIA_PHONE_COUNTRY_CODE = '+61 ';
    private static final String AUSTRALIA_PHONE_COUNTRY_CODE_PREFIX = '61';
    private static final String JAPAN_COUNTRY_CODE = 'JP';
    private static final String JAPAN_PHONE_COUNTRY_CODE = '+81 ';
    private static final String JAPAN_PHONE_COUNTRY_CODE_PREFIX = '81';
    private static final String JAPAN_PHONE_TOLL_FREE_PREFIX = '120';

	static {
		/*
		for(Schema.PicklistEntry entry : Schema.SobjectType.Account.fields.Market_Area__c.getPicklistValues()) {
		    if(entry.isActive()) {
		    	VALID_SUBMARKETS.add(entry.getValue());
		    }
		}
		*/

		for(Schema.PicklistEntry entry : Schema.SObjectType.Account.fields.BillingCountryCode.getPicklistValues()) {
			COUNTRY_MAP.put(entry.getLabel(), entry.getValue());
		}
	}

    static {

		for(Schema.PicklistEntry entry : Schema.SObjectType.Account.fields.BillingStateCode.getPicklistValues()) {
			State_MAP.put(entry.getLabel(), entry.getValue());
		}
	}

	public Integer callAttempts { get; set; }

	public VDeliveryInformation() {}

	public double liveAgentCustomerId { get; set; }
	public double liveAgentDasherId { get; set; }
	public double liveAgentMerchantId { get; set; }
    public String chatButtonId {get; set;}

    public double deliveryId { get; set; }
    // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
    public String deliveryUUID { get; set; }
	public Date deliveryDate { get; set; }
	public Delivery__c delivery { get; set; }
	public Case salesforceCase { get; set; }
    // 02/09 Nayana Kapse BIZS-879 - Consume estimatedPickupTime
    public String estPickupDateTimeFormatted { get; set; }
    // 09/15 BIZS-1875 
    public Boolean isDeliveryCurrent { get; set; }

	public Account customerAccount { get; set; }
	public double customerId { get; set; }
	public String  customerPhoneNumber { get; set; }
	public String  customerFirstName { get; set; }
	public String  customerLastName { get; set; }
    public String  customerEmail { get; set; }
    // BZAPSUP-786 Tia Xuan 08/2020
	// Update Dispatch Callout Result with Platform Field
    public String  customerExperience { get; set; }
    public Integer  cxUnavailLast3OrdersFlag { get; set; }

	public Account merchantAccount { get; set; }
    public Lead merchantLead {get; set;}
	public double merchantId { get; set; }
	public String  merchantPhoneNumber { get; set; }
	public String  merchantName { get; set; }
	public String  merchantStreet { get; set; }
	public String  merchantCity { get; set; }
	public String  merchantState { get; set; }
	public String  merchantZipCode { get; set; }
	public String  merchantCountry { get; set; }
    //BZAPSUP-1658 Tia Xuan 02/2021
    public String  merchantCountryFromResponse { get; set; }
    public String merchantBusinessVerticalId { get; set; }
	public Boolean merchantIsPartner { get; set; }
	public String  merchantSubmarket { get; set; }
	public String  merchantOrderProtocol { get; set; }
    public String merchantBusinessName { get; set; }
    public double merchantBusinessId { get; set; }

	public Account dasherAccount { get; set; }
	public double dasherId { get; set; }
	public String  dasherPhoneNumber { get; set; }
	public String  dasherFirstName { get; set; }
	public String  dasherLastName { get; set; }
	public String  dasherEmail { get; set; }
    // 02/09 Nayana Kapse BIZS-1241 - Consume DasherDeliveryStatus
    public Integer dasherDeliveryStatus { get; set; }

    // BZAP-3875 Tia Xuan 05/22/2019
	// Additional information for dispatch
    /*public Boolean  groupCartOrders { get; set; }
    public Boolean  firstOrder { get; set; }
    public String  platform { get; set; }
    public String  submarket { get; set; }
    public Boolean  firstDasherDelivery { get; set; }
    public String  vehicleOfDasher { get; set; }
    public String  businessName { get; set; }
    public DateTime  quotedDeliveryTime { get; set; }
    public DateTime  estimatedDeliveryTime { get; set; }
    public Boolean  isReorder { get; set; }
    public String  source { get; set; }
    public Boolean  isFromStoreToUs { get; set; }
    public Boolean  isSubscribedConsumer { get; set; }
    public String  orderProtocol { get; set; }
    public Boolean  isPartner { get; set; }
    public Decimal  subtotal { get; set; }
    public Decimal  valueOfContents { get; set; }
    public Boolean  wasBatched { get; set; }
    public Decimal  dasherWaitDuration { get; set; }
    public Decimal  dasherScore { get; set; }
    public Boolean  isConsumerPickup { get; set; }
    public Decimal  numUnassigns { get; set; }
    public Boolean  isVIP { get; set; }
    public Boolean  isManagedCateringOrder { get; set; }
    public Decimal  consumerNumOrders { get; set; }*/

	public static VDeliveryInformation deserialize(String jsonInput) {
		System.debug(jsonInput);

		VDeliveryInformation res = new VDeliveryInformation();

		Map<String, Object> jsonResult = (Map<String, Object>)JSON.deserializeUntyped(jsonInput);
		Map<String, Object> customer = (Map<String, Object>)jsonResult.get('consumer');
		Map<String, Object> merchant = (Map<String, Object>)jsonResult.get('store');
		Map<String, Object> dasher = (Map<String, Object>)jsonResult.get('dasher');
		Map<String, Object> submarket = (Map<String, Object>)merchant.get('submarket');

		res.customerId = (double)customer.get('id');
		res.customerPhoneNumber = (String)customer.get('phone_number');
		res.customerFirstName = (String)customer.get('first_name');
		res.customerLastName = (String)customer.get('last_name');
        res.customerEmail = (String)customer.get('email');
        // BZAPSUP-786 Tia Xuan 08/2020
        // Update Dispatch Callout Result with Platform Field
        res.customerExperience = (String)customer.get('experience');

		res.merchantId = (double)merchant.get('id');
		res.merchantPhoneNumber = (String)merchant.get('phone_number');
		res.merchantname = (String)merchant.get('name');

		Map<String, Object> merchantAddress = (Map<String, Object>)merchant.get('address');

		if(merchantAddress != null && merchantAddress.size() > 0) {
			res.merchantStreet = (String)merchantAddress.get('street');
			res.merchantCity = (String)merchantAddress.get('city');
			res.merchantState = (String)merchantAddress.get('state');
			res.merchantZipCode = (String)merchantAddress.get('zip_code');
			res.merchantCountry = (String)merchantAddress.get('country');
             //BZAPSUP-1658 Tia Xuan 02/2021
            res.merchantCountryFromResponse = (String)merchantAddress.get('country');
		}

		if(COUNTRY_MAP.containsKey(res.merchantCountry)) {
			res.merchantCountry = COUNTRY_MAP.get(res.merchantCountry);
		}

		if(String.isBlank(res.merchantCountry) || res.merchantCountry == 'USA') {
			res.merchantCountry = 'US';
		}

         if(String.isNotBlank(res.customerPhoneNumber)){
            res.customerPhoneNumber = formatPhoneNumber(res.customerPhoneNumber, res.merchantCountry);
        }

        if(String.isNotBlank(res.merchantPhoneNumber)){
            res.merchantPhoneNumber = formatPhoneNumber(res.merchantPhoneNumber, res.merchantCountry);
        }

        if(State_MAP.containsKey(res.merchantState)) {
			res.merchantState = State_MAP.get(res.merchantState);
		}


		res.merchantIsPartner = (Boolean)merchant.get('is_partner');
        
        Map<String, Object> merchantBusiness = (Map<String, Object>)merchant.get('business');

		if(merchantBusiness != null && merchantBusiness.size() > 0) {
			res.merchantBusinessId = (double)merchantBusiness.get('id');
			res.merchantBusinessName = (String)merchantBusiness.get('name');
            res.merchantBusinessVerticalId = (String)merchantBusiness.get('businessVerticalId');
		}

		/*
        if(submarket != null && submarket.size() > 0) {
			String submarketName = (String)submarket.get('name');
			if(String.isNotBlank(submarketName) && VALID_SUBMARKETS.contains(submarketName)) {
				res.merchantSubmarket = submarketName;
			}
		}
		*/

		res.merchantOrderProtocol = (String)merchant.get('order_protocol');

		if(res.merchantIsPartner == null) {
			res.merchantIsPartner = false;
		}
		
		if(dasher != null) {
			res.dasherId = (double)dasher.get('id');
			res.dasherFirstName = (String)dasher.get('first_name');
			res.dasherLastName = (String)dasher.get('last_name');
			res.dasherPhoneNumber = (String)dasher.get('phone_number');
			res.dasherEmail = (String)dasher.get('email');
		}

        // 10/2020 Tia Xuan BZAPSUP-1047 Dispatch Delivery/Order ID Obfuscation SFDC Retrofit  - Followup API Switch
        if (jsonResult.containsKey('id')){
            
            // dispatch is returning an empty string for 'id' which is causing an exception
            // checking for value type when casting it to a double. 
            // if the Id is blank, we'd still be receiving deliveryUUId. 

            Object idValue = jsonResult.get('id');
            if (idValue instanceOf double 
                || idValue instanceOf Integer){
                
                res.deliveryId = (double)jsonResult.get('id');
            } else {
                res.deliveryId = 0;
            }
        } else {
            res.deliveryId = 0; 
        }
        // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
        if (jsonResult.containsKey('delivery_uuid')){
            res.deliveryUUID = (String)jsonResult.get('delivery_uuid');
        } else {
            res.deliveryUUID = '';
        }

		String deliveryDateStr = (String)jsonResult.get('active_date');
		if(String.isNotBlank(deliveryDateStr)) {
			res.deliveryDate = Date.valueOf(deliveryDateStr);
		}

         if(String.isNotBlank(res.dasherPhoneNumber)){
            res.dasherPhoneNumber = formatPhoneNumber(res.dasherPhoneNumber, res.merchantCountry);
        }

        // BZAP-3875 Tia Xuan 05/22/2019
		// Additional information for dispatch
		/*if (dispatchAllFields){
			res.groupCartOrders = (Boolean)jsonResult.get('group_cart');
			res.firstOrder = (Boolean)jsonResult.get('is_first_order_cart');
			res.platform = (String)jsonResult.get('submit_platform');
			res.submarket = (String)jsonResult.get('submarket_name');
			res.firstDasherDelivery = (Boolean)jsonResult.get('is_first_dasher_shift');
			res.vehicleOfDasher = (String)jsonResult.get('delivery_vehicle_type');
			res.businessName = (String)jsonResult.get('business_name');
			String quotedDeliveryTimeStr = (String)jsonResult.get('quoted_delivery_time');
			if(String.isNotBlank(quotedDeliveryTimeStr)) {
				res.quotedDeliveryTime = DateTime.valueOf(quotedDeliveryTimeStr.replace('T',' '));
			}
			String estimatedDeliveryTimeStr = (String)jsonResult.get('estimated_delivery_time');
			if(String.isNotBlank(estimatedDeliveryTimeStr)) {
				res.estimatedDeliveryTime = DateTime.valueOf(estimatedDeliveryTimeStr.replace('T',' '));
			}
			res.isReorder = (Boolean)jsonResult.get('is_reorder');
			res.source = (String)jsonResult.get('source');
			res.isFromStoreToUs = (Boolean)jsonResult.get('is_from_store_to_us');
			res.isSubscribedConsumer = (Boolean)jsonResult.get('is_subscribed_consumer');
			res.orderProtocol = (String)jsonResult.get('order_protocol');
			res.isPartner = (Boolean)jsonResult.get('is_partner');
			res.subtotal = (Decimal)jsonResult.get('subtotal');
			res.valueOfContents = (Decimal)jsonResult.get('value_of_contents');
			res.wasBatched = (Boolean)jsonResult.get('was_batched');
			res.dasherWaitDuration = (Decimal)jsonResult.get('dasher_wait_remaining_seconds');
			res.dasherScore = (Decimal)jsonResult.get('dasher_score');
			res.isConsumerPickup = (Boolean)jsonResult.get('is_consumer_pickup');
			res.numUnassigns = (Decimal)jsonResult.get('num_unassigns');
			res.isVIP = (Boolean)jsonResult.get('is_vip');
			res.isManagedCateringOrder = (Boolean)jsonResult.get('is_managed_catering_order');
			res.consumerNumOrders = (Decimal)jsonResult.get('consumer_num_orders');
		}*/

		return res;
	}

    public static String formatPhoneNumber(String phoneNo, String country){
        if (country == AUSTRALIA_COUNTRY_CODE){
            String formattedPhone  = '';
            for(integer i =0;i<phoneNo.length();i++){
                String s= phoneNo.mid(i,1);
                if(s.isNumeric()){
                    formattedPhone +=s;
                }
            }
            Integer fpLength = formattedPhone.length();

            if (fpLength > 9){
                if (formattedPhone.startsWith(AUSTRALIA_PHONE_COUNTRY_CODE_PREFIX) && fpLength == 11){
                     return AUSTRALIA_PHONE_COUNTRY_CODE + formattedPhone.mid(2, 3) + ' ' 
                                    + formattedPhone.mid(5, 3) + ' ' 
                                    + formattedPhone.mid(8, 3);
                } else if (formattedPhone.startsWith(AUSTRALIA_PHONE_COUNTRY_CODE_PREFIX) && fpLength == 12){
                     return AUSTRALIA_PHONE_COUNTRY_CODE + formattedPhone.mid(3, 3) + ' ' 
                                    + formattedPhone.mid(6, 3) + ' ' 
                                    + formattedPhone.mid(9, 3);
                } else if (formattedPhone.startsWith(ZERO_PREFIX) && fpLength == 10){
                    return  AUSTRALIA_PHONE_COUNTRY_CODE + formattedPhone.mid(1, 3) + ' ' 
                                    + formattedPhone.mid(4, 3) + ' ' 
                                    + formattedPhone.mid(7, 3);

                } 
            } 
            return phoneNo;
        //BZAPSUP-1438 Tia Xuan 06/2021 Dispatch with Japanese numbers
        } else if (country == JAPAN_COUNTRY_CODE){
            if (CDdExperimentSvc.getSupportFeatureFlag('Enable_Japan_Dispatch_Phone_Conversion__c')){
                String formattedPhone  = '';
                for(integer i =0;i<phoneNo.length();i++){
                    String s= phoneNo.mid(i,1);
                    if(s.isNumeric()){
                        formattedPhone +=s;
                    }
                }

                Integer fpLength = formattedPhone.length();

                if (fpLength >= 9){
                    if (formattedPhone.startsWith(JAPAN_PHONE_COUNTRY_CODE_PREFIX)){
                        if (formattedPhone.startsWith(JAPAN_PHONE_COUNTRY_CODE_PREFIX + JAPAN_PHONE_TOLL_FREE_PREFIX)){
                            return JAPAN_PHONE_COUNTRY_CODE + formattedPhone.mid(2, 3) + '-' 
                            + formattedPhone.mid(5, 3) + '-' 
                            + formattedPhone.mid(8, 3);
                        } else if (fpLength == 11){
                            return JAPAN_PHONE_COUNTRY_CODE + formattedPhone.mid(2, 2) + '-' 
                                        + formattedPhone.mid(4, 3) + '-' 
                                        + formattedPhone.mid(7, 4);
                        } else if (fpLength == 12){
                            return JAPAN_PHONE_COUNTRY_CODE + formattedPhone.mid(2, 2) + '-' 
                                        + formattedPhone.mid(4, 4) + '-' 
                                        + formattedPhone.mid(8, 4);
                        }
                    } else if (formattedPhone.startsWith(ZERO_PREFIX)){
                        if (formattedPhone.startsWith(ZERO_PREFIX + JAPAN_PHONE_TOLL_FREE_PREFIX)){
                            return JAPAN_PHONE_COUNTRY_CODE + formattedPhone.mid(1, 3) + '-' 
                            + formattedPhone.mid(4, 3) + '-' 
                            + formattedPhone.mid(7, 3);
                        } else if (fpLength == 10){
                            return JAPAN_PHONE_COUNTRY_CODE + formattedPhone.mid(1, 2) + '-' 
                                        + formattedPhone.mid(3, 3) + '-' 
                                        + formattedPhone.mid(6, 4);
                        } else if (fpLength == 11){
                                return JAPAN_PHONE_COUNTRY_CODE + formattedPhone.mid(1, 2) + '-'  
                                            + formattedPhone.mid(3, 4) + '-' 
                                            + formattedPhone.mid(7, 4);
                        } 
                    }
                } 
            }

            return phoneNo;
        } else {
            return phoneNo;
        }
    }

    /**
     * @author      Mahesh Chouhan
     * @date        July 2023
     * @jira        https://doordash.atlassian.net/browse/BIZS-2991
     * @description Populate Customer Segment on Case from Dispatch Response
     * @param VDeliveryInformation info
     * @param Case caseRecord
     * @return Updated Case
     */
    public static Case populateCustomerSegment(VDeliveryInformation info, Case caseRecord){
        if(info.cxUnavailLast3OrdersFlag != null && CDdSupportHelper.mapCustomerSegmentmapping.containsKey(Integer.valueOf(info.cxUnavailLast3OrdersFlag))){
            caseRecord.Customer_Segment__c = CDdSupportHelper.mapCustomerSegmentmapping.get(Integer.valueOf(info.cxUnavailLast3OrdersFlag));
        }
        return caseRecord;
    }
}