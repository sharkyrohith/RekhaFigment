/**
 * 
 * @author: Tia Xuan
 * @date: 2021-07
 * @description Dispatch Delivery information
 * 
 */
public with sharing class CDdDispatchDeliveryInformation {

    //BIZS-467 Tia Xuan 09/2021
    public static Map<String, String> COUNTRY_MAP = new Map<String, String>();
    public static Map<String, String> State_MAP = new Map<String, String>();
    //BIZS-519 Jeegar 11/2021
    // changes to add mapping of country code to phone. 
    private static Map<String, String> countryPhoneFormatMap;

    static {
		for(Schema.PicklistEntry entry : Schema.SObjectType.Account.fields.BillingCountryCode.getPicklistValues()) {
			COUNTRY_MAP.put(entry.getLabel(), entry.getValue());
		}
	}

    static {
		for(Schema.PicklistEntry entry : Schema.SObjectType.Account.fields.BillingStateCode.getPicklistValues()) {
			State_MAP.put(entry.getLabel(), entry.getValue());
		}
	}
        
    public CDdDispatchDeliveryInformation() {}

    /**
    * @description Serialize a API responses
    * @param jsonInput string response from dispatch request
    * @return a list of VDeliveryInformation records
    **/
    public static List<VDeliveryInformation> deserialize(String jsonInput) {
        List<VDeliveryInformation> results = new List<VDeliveryInformation>();
        if(jsonInput.contains('salesforceAudienceInfoBulkResponse')) {
            DispatchResponses responses = (DispatchResponses) JSON.deserialize(jsonInput, DispatchResponses.class);
            for (DispatchResponse resp : responses.salesforceAudienceInfoBulkResponse){
                VDeliveryInformation info = deserializeOne(resp);
                results.add(info);
            }
        } else {
            DispatchResponse singleResponse = (DispatchResponse) JSON.deserialize(jsonInput, DispatchResponse.class); 
            results.add(deserializeOne(singleResponse));
        }
        

        return results;
    }

    /**
    * @description Serialize one API response
    * @param resp one response from dispatch deserialized
    * @return a VDeliveryInformation record
    **/
    public static VDeliveryInformation deserializeOne(DispatchResponse resp){

        VDeliveryInformation res = new VDeliveryInformation();

        // Customer
        if (resp.audience.consumerAudience != null
                && String.isNotBlank(resp.audience.consumerAudience.id)){
            res.customerId = Double.valueOf(resp.audience.consumerAudience.id);
            res.customerPhoneNumber = resp.audience.consumerAudience.phoneNumber;
            res.customerFirstName = resp.audience.consumerAudience.firstName;
            res.customerLastName = resp.audience.consumerAudience.lastName;
            res.customerEmail = resp.audience.consumerAudience.email;
            res.customerExperience = resp.audience.consumerAudience.experienceString;
            res.cxUnavailLast3OrdersFlag = resp.audience.consumerAudience.cxUnavailLast3OrdersFlag;
            if(String.isNotBlank(res.customerPhoneNumber)){
                res.customerPhoneNumber = getPhoneNumber(res.customerPhoneNumber, resp.audience.consumerAudience.phoneNumberComponents);
            }
        }

        // Merchant
        if (resp.audience.store != null
                && String.isNotBlank(resp.audience.store.id)){

            res.merchantId = Double.valueOf(resp.audience.store.id);
            res.merchantPhoneNumber = resp.audience.store.phoneNumber;
            res.merchantname = resp.audience.store.name;
            res.merchantStreet = resp.audience.store.address.street;
            res.merchantCity = resp.audience.store.address.city;
            res.merchantState = resp.audience.store.address.administrativeAreaLevel1;
            res.merchantZipCode = resp.audience.store.address.postalCode;
            res.merchantCountry = resp.audience.store.address.countryShortname;

            //BZAPSUP-1658 Tia Xuan 02/2021
            res.merchantCountryFromResponse = resp.audience.store.address.country;
            if(String.isNotBlank(res.merchantPhoneNumber)){
                res.merchantPhoneNumber = getPhoneNumber(res.merchantPhoneNumber, resp.audience.store.phoneNumberComponents);
            }

            res.merchantBusinessId = Double.valueOf(resp.audience.store.business.id);
            res.merchantBusinessName = resp.audience.store.name;
            res.merchantOrderProtocol = resp.audience.store.orderProtocol;
            res.merchantIsPartner = resp.audience.store.isPartner;

            //BIZS-467 Tia Xuan 09/2021
            if(COUNTRY_MAP.containsKey(res.merchantCountry)) {
                res.merchantCountry = COUNTRY_MAP.get(res.merchantCountry);
            }
    
            if(String.isBlank(res.merchantCountry) || res.merchantCountry == 'USA') {
                res.merchantCountry = 'US';
            }

            if(State_MAP.containsKey(res.merchantState)) {
                res.merchantState = State_MAP.get(res.merchantState);
            }
            if(String.isNotBlank(resp.audience.store.business.businessVerticalId)) {
                res.merchantBusinessVerticalId = resp.audience.store.business.businessVerticalId;
            }
        }
        
        //Dasher
        
        if ( resp.audience.dasherAudience != null 
                && String.isNotBlank(resp.audience.dasherAudience.id)){

            res.dasherId = Double.valueOf(resp.audience.dasherAudience.id);
            res.dasherFirstName = resp.audience.dasherAudience.firstName;
            res.dasherLastName = resp.audience.dasherAudience.lastName;
            res.dasherPhoneNumber = resp.audience.dasherAudience.phoneNumber;
            res.dasherEmail =resp.audience.dasherAudience.email;
            if(String.isNotBlank(res.dasherPhoneNumber)){
                res.dasherPhoneNumber = getPhoneNumber(res.dasherPhoneNumber, resp.audience.dasherAudience.phoneNumberComponents);
            }
            res.dasherDeliveryStatus = resp.audience.dasherAudience.dasherDeliveryStatus;
        }

        //Delivery
        res.deliveryId = 0;
        if(resp.delivery != null){
            res.deliveryUUID = resp.delivery.deliveryUuid;
            res.deliveryDate = Date.valueOf(resp.delivery.activeDate);
            res.estPickupDateTimeFormatted = resp.delivery.estimatedPickupTimeInMarketTimezone;
            res.isDeliveryCurrent = resp.delivery.isDeliveryCurrent;
        }
        return res;
    }

    /**
    * Helper methods
    **/

    /**
    * @description format a phone number in the locality
    * @param phoneNo phone number
    * @param phoneObj phone object
    * @return phone number 
    **/
    public static String getPhoneNumber(String phoneNo, DispatchPhone phoneObj){
        String phoneFormat = CDdSupportConstants.FORMATTED_INTERNATIONAL_NUMBER;
        if (phoneObj != null){
            if(String.isNotBlank(phoneObj.countryShortname)){
                phoneFormat = getPhoneFormat(phoneObj.countryShortname);
            }
            switch on phoneFormat {
                when 'formattedInternationalNumber' {
                    return phoneObj.formattedInternationalNumber;
                }
                when 'formattedNationalNumber' {
                    return phoneObj.formattedNationalNumber;
                }
                when 'internationalNumber' {
                    return phoneObj.internationalNumber;
                }
                when 'nationalNumber' {
                    return phoneObj.nationalNumber;
                }
                when else {
                    return phoneObj.formattedInternationalNumber;
                }
            }
        } 
        return phoneNo;
    }

    //BIZS-519 Jeegar 11/2021

    private static String getPhoneFormat(String countryShortName) {
        if(countryPhoneFormatMap == null) {
            populatePhoneFormatMap(); 
        }
        if(countryPhoneFormatMap.containsKey(countryShortName)) {
            return countryPhoneFormatMap.get(countryShortName);
        } else if(countryPhoneFormatMap.containsKey(CDdSupportConstants.DEFAULT_STRING)) {
            return countryPhoneFormatMap.get(CDdSupportConstants.DEFAULT_STRING);
        } else {       
            return CDdSupportConstants.FORMATTED_INTERNATIONAL_NUMBER; 
        }
    }

    private static void populatePhoneFormatMap(){
        countryPhoneFormatMap = new Map<String, String>(); 

        List<Country_Phone_Format_Mapping__c> countryPhoneFormatList = Country_Phone_Format_Mapping__c.getAll().values();
        for(Country_Phone_Format_Mapping__c countryPhoneFormat : countryPhoneFormatList) {
            countryPhoneFormatMap.put(countryPhoneFormat.Country_Short_Name__c, countryPhoneFormat.Phone_Format__c); 
        }
        
    }

    /**
    * @description Objects for the serialization of the dispatch response
    **/
    public class DispatchResponses {
        public List<DispatchResponse> salesforceAudienceInfoBulkResponse    { get; set; }
    }
    public class DispatchResponse {
        public Integer customerType         { get; set; }
        public DispatchAudience audience    { get; set; }
        public DispatchDelivery delivery    { get; set; }
    }
    public class DispatchDelivery {
        public String deliveryUuid                          { get; set; }
        public DateTime activeDate                          { get; set; }
        public DateTime estimatedPickupTime                 { get; set; }
        public String estimatedPickupTimeInMarketTimezone   { get; set; }
        public Boolean isDeliveryCurrent                    { get; set; }
    }
    public class DispatchAudience {
        DispatchConsumer consumerAudience   { get; set; }
        DispatchDasher dasherAudience       { get; set; }
        DispatchMerchant store              { get; set; }
    }
    public class DispatchConsumer {
        public String id                            { get; set; }
        public String firstName                     { get; set; }
        public String lastName                      { get; set; }
        public String email                         { get; set; }
        public String phoneNumber                   { get; set; }
        public String country                       { get; set; }
        public Integer experience                   { get; set; }
        public String experienceString              { get; set; }
        public Boolean isVIP                        { get; set; }
        public Integer vipTier                      { get; set; }
        public String language                      { get; set; }
        public DispatchAddress address              { get; set; }
        public DispatchPhone phoneNumberComponents  { get; set; }
        public Integer cxUnavailLast3OrdersFlag      { get; set; }
    }
    public class DispatchDasher {
        public String id                            { get; set; }
        public String firstName                     { get; set; }
        public String lastName                      { get; set; }
        public String phoneNumber                   { get; set; }
        public String email                         { get; set; }
        public Integer experience                   { get; set; }
        public DispatchAddress address              { get; set; }
        public DispatchPhone phoneNumberComponents  { get; set; }
        public String language                      { get; set; }   
        public Integer dasherDeliveryStatus         { get; set; }
    }
    public class DispatchMerchant {
        public String id                            { get; set; }
        public String name                          { get; set; }
        public DispatchBusiness business            { get; set; }
        public String phoneNumber                   { get; set; }
        public Boolean isPartner                    { get; set; }
        public DispatchAddress address              { get; set; }
        public DispatchPhone phoneNumberComponents  { get; set; }
        public String orderProtocol                 { get; set; }
    }
    public class DispatchBusiness {
        public String id                            { get; set; }
        public String name                          { get; set; }
        public String businessVertical              { get; set; }
        public String businessVerticalId            { get; set; }
    }
    public class DispatchAddress {
        public String id                        { get; set; }
        public String street                    { get; set; }
        public String city                      { get; set; }
        public String administrativeAreaLevel1  { get; set; }
        public String postalCode                { get; set; }
        public String country                   { get; set; }
        public String countryShortname          { get; set; }
    }
    public class DispatchPhone {
        public String countryCode                   { get; set; }
        public String countryShortname              { get; set; }
        public String formattedInternationalNumber  { get; set; }
        public String formattedNationalNumber       { get; set; }
        public String internationalNumber           { get; set; }
        public String nationalNumber                { get; set; }
    }

}