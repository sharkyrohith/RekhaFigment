public class CDdRestJSONObj {
	/*
     * @author: jnguyen
     * All REST API request/response object structure should live in this class
     */

    public class Address {
        public String city;
        public String subpremise;
        public Integer id;
        public String printable_address;
        public String state;
        public String street;
        public String country;
        public Double lat;
        public Double lng;
        public String shortname;

        // DSJ Store
        public String zip_code;

        // DSJ Payment Account
        public String line1;
        public String line2;
        public String postal_code;
    }

    public class Business {
        public Decimal id;
        public String name;
        public String description;
    }

    public class StoreSuccesses {
        public String name;
        public Boolean is_active;
        public String special_instructions_max_length;
        public String cover_img_url;
        public Address address;
        public Integer id;
    }
    public class StoreFailures {
        public String name;
        public String is_active;
        public Decimal business_id;
        public String submarket_id;
        public String payment_protocol;
        public String street_address;
        public String zipcode;
        public String city;
        public String state;
        public Double lat;
        public Double lng;
        public String detail;
    }

    public class RestAPIResponse {
        public String body;
        public Integer statusCode;
        public String status;
    }

    public class DoorstepBusinessRequest {
        public String name;
        public String description;
        public String webhook_url;
    }

    public class DoorstepBusinessResponse {
        public String name;
        public String description;
        public String webhook_url;
        public Decimal id;
        public String detail;
    }

    public class DoorstepStoreRequest {
        public String salesforce_id;
        public String name;
        public String email;
        public String active;
        public String is_partner;
        public String business_id;
        public String submarket_id;
        public String order_protocol;
        public String confirm_protocol;
        public String payment_protocol;
        public String tier_level;
        public String street_address;
        public String phone_number;
        public String zipcode;
        public String city;
        public String state;
        public Decimal commission_rate;
        public Double lat;
        public Double lng;
        public String special_instructions_max_length;
        public String error_report_emails;
        public String contact_emails;
        public String offers_pickup;
        public Decimal service_rate;
        public String provider_type;
        public String location_id;
        public String salesforce_lead_id;
        public String error_report_frequency;
        public String price_range;
        public String fax_number;
        public String max_order_size;
        public String override_tax_rate;
        public String pickup_commission;
        public String weekly_tablet_subscription_fee;
        public String weekly_printer_subscription_fee;
        public String subscription_commission;
        public String activation_fee;
        public String delivery_radius;
        public String max_delivery_radius;
        public String fulfills_own_deliveries;
        public Integer custom_delivery_fee;
        public String consumer_subscription_eligible;
        public Decimal inflation_rate;
        public String inflation_rounding_unit;
        public String reduced_pickup_commission;
        public String reduced_commission;
        public String delivery_fee;
        public String pickup_fee;
        public String dashpass_commission;
        public String weblink_pickup_fee;
        public String weblink_delivery_fee;
        public String storefront_delivery_fee;
        public String storefront_pickup_fee;
        public String storefront_processing_fee;
        public String storefront_processing_rate;
        public String merchant_supplied_id;
        public String creation_method;
        public String test;
        public String offers_delivery;
        public String fulfills_own_deliveries_disabled;
        public Decimal dash_pass_marketing_fee;
        public String formatted_address;
        public String auto_release_enabled;
        public String auto_release_distance;
    }

    public class DoorstepStoreResponse {
        public StoreSuccesses successes;
        public StoreFailures failures;
        public String detail;
    }

    public class DoorstepStorePOSRequest {
        public String provider_type;
        public String location_id;
    }

    public class DoorstepStorePOSResponse {
        public Integer store_id;
        public String provider_type;
        public String location_id;
        public String detail;
    }

    public class DoorstepUserRequest {
        public String email;
        public String phone_number;
        public String first_name;
        public String last_name;
        public String client_id; // optional
        public String store_id;
        public String dm_email;
    }

    public class DoorstepUserResponse {
        public String token;
        public DoorStepUser user;
        public String refresh_token;
        public String detail;
    }

    public class DoorstepUser {
        public String phone_number;
        public String first_name;
        public String last_name;
        public String email;
        public Boolean is_staff;
        //public List<String> groups;
        public Double id;
    }

    public class DoorstepMerchantRequest {
        public String user;
        public String store;
    }

    public class DoorstepMerchantResponse {
        public String email;
        public Double id;
        public String first_name;
        public String last_name;
        public String detail;
    }

    public static DoorstepStoreResponse parseStoreResponse(String json) {
        return (DoorstepStoreResponse) System.JSON.deserialize(json, DoorstepStoreResponse.class);
    }

    public class KodakitRequest {
        public String businessName;
        public String address;
        public String lat;
        public String lng;
        public String country;
        public String bookingDateTime;
        public String bookingTemplate;
        public String contactNumber;
        public String contactName;
        public String contactEmail;
        public String altContactNumber;
        public String altContactName;
        public String listingId;
        public String additionalAddressDetails;
        public String notes;
    }

    public class KodakitResponse {
        public String status;
        public Decimal jobId;
    }

    public class DoorstepStoreGetResponse {
        public Decimal id;
        public String name;
        public Business business;
        public String is_active;
        public String special_instructions_max_length;
        public String cover_img_url;
        public Address address;
        public String detail;
    }

    public class DoorstepDasherCheckrStatusResponse {
        public String name;
        public String checkr_id;
        public String email;
        public String mv_report_results ;
        public String background_check_results;
        public String detail;
    }

    public class RequestParams {
        public String method;
        public String postData;
        public String auth;
        public String endpoint;
        public String postfix;
        public String contentType;
    }

    public class DOB {
        public String month;
        public String day;
        public String year;
    }

    public class DoorstepPaymentAccountRequest {
        public String target_type;
        public String target_id;
        public String first_name;
        public String last_name;
        public DOB date_of_birth;
        public String business_name;
        public String business_tax_id;
        public Address address;
        public String account_token;
        public String person_token;
    }

    public class DoorstepPaymentAccountResponse {
        public String id;
        public String stripe_account_id;
        public String stripe_account_type;
        public String detail;
        public String non_field_errors;
    }

    public class DoorstepBankAccountRequest {
        public String stripe_token;
    }

    public class DoorstepBankAccountResponse {
        public String id;
        public String stripe_account_id;
        public String stripe_account_type;
        public DoorstepStripeAccount stripe_account;
        public String detail;
        public String non_field_errors;
    }

    public class DoorstepStripeAccount {
        public String id;
        public String default_currency;
        public DoorstepExternalAccount external_account;
    }

    public class DoorstepExternalAccount {
        public String routing_number;
        public String bank_name;
        public String last4;
        public String country;
        public String account_holder_name;
        public String status;
        public String fingerprint;
    }

    public class StripeBankTokenRequest {
        public String country {get; set;}
        public String curr {get; set;}
        public String account_holder_name {get; set;}
        public String account_holder_type {get; set;}
        public String account_number {get; set;}
        public String routing_number {get; set;}

        public String getURLEncoded() {
            String encodedURL = 'bank_account[country]=' + (this.country != null ? this.country : '')
                        + '&bank_account[currency]=' + (this.curr != null ? this.curr : '')
                        + '&bank_account[account_holder_name]=' + (this.account_holder_name != null ? this.account_holder_name : '')
                        + '&bank_account[account_holder_type]=' + (this.account_holder_type != null ? this.account_holder_type : '')
                        + '&bank_account[account_number]=' + (this.account_number != null ? this.account_number : '')
                        + '&bank_account[routing_number]=' + (this.routing_number != null ? this.routing_number : '');
            return encodedURL;
        }
    }

    public class StripeBankTokenResponse {
        public String id;
        public String client_ip;
        public String created;
        public StripeBankTokenDetails bank_account;
        public StripeError error;
    }

    public class StripeAccountTokenRequest {
        public String business_type {get; set;}
        public Boolean tos_shown_and_accepted {get; set;}
        public String company_name {get; set;}
        public Address company_address {get; set;}
        public String company_tax_id  {get; set;}

        public String getURLEncoded() {
            String encodedURL = 'account[business_type]=' + (this.business_type != null ? this.business_type : '')
                        + '&account[tos_shown_and_accepted]=' + this.tos_shown_and_accepted
                        + '&account[company][name]=' + (this.company_name != null ? EncodingUtil.urlEncode(this.company_name, 'UTF-8') : '')
                        + '&account[company][address][line1]=' + (this.company_address != null && String.isNotBlank(this.company_address.line1) ? EncodingUtil.urlEncode(this.company_address.line1, 'UTF-8') : '')
                        + '&account[company][address][line2]=' + (this.company_address != null && String.isNotBlank(this.company_address.line2) ? EncodingUtil.urlEncode(this.company_address.line2, 'UTF-8') : '')
                        + '&account[company][address][city]=' + (this.company_address != null && String.isNotBlank(this.company_address.city) ? EncodingUtil.urlEncode(this.company_address.city, 'UTF-8') : '')
                        + '&account[company][address][state]=' + (this.company_address != null && String.isNotBlank(this.company_address.state) ? EncodingUtil.urlEncode(this.company_address.state, 'UTF-8') : '')
                        + '&account[company][address][postal_code]=' + (this.company_address != null && String.isNotBlank(this.company_address.postal_code) ? EncodingUtil.urlEncode(this.company_address.postal_code, 'UTF-8') : '')
                        + '&account[company][address][country]=' + (this.company_address != null && String.isNotBlank(this.company_address.country) ? EncodingUtil.urlEncode(this.company_address.country, 'UTF-8') : '')
                        + '&account[company][tax_id]=' + (String.isNotBlank(this.company_tax_id) ? EncodingUtil.urlEncode(this.company_tax_id, 'UTF-8') : '');
            return encodedURL;
        }
    }

    public class StripeAccountTokenResponse {
        public String id;
        public String client_ip;
        public String created;
        public StripeError error;
    }

    public class StripePersonTokenRequest {
        public String individual_first_name {get; set;}
        public String individual_last_name {get; set;}
        public String individual_id_number {get; set;}
        public DOB individual_date_of_birth {get; set;}
        public Address individual_address {get; set;}
        public Boolean individual_relationship_executive {get; set;}
        public Boolean individual_relationship_representative {get; set;}

        public String getURLEncoded() {
            String encodedURL = 'person[first_name]=' + (String.isNotBlank(this.individual_first_name) ? EncodingUtil.urlEncode(this.individual_first_name, 'UTF-8') : '')
                        + '&person[last_name]=' + (String.isNotBlank(this.individual_last_name) ? EncodingUtil.urlEncode(this.individual_last_name, 'UTF-8') : '')
                        + (String.isNotBlank(this.individual_id_number) ? '&person[id_number]=' + EncodingUtil.urlEncode(this.individual_id_number, 'UTF-8') : '')
                        + '&person[dob][day]=' + (this.individual_date_of_birth != null && String.isNotBlank(this.individual_date_of_birth.day) ? EncodingUtil.urlEncode(this.individual_date_of_birth.day, 'UTF-8') : '')
                        + '&person[dob][month]=' + (this.individual_date_of_birth != null && String.isNotBlank(this.individual_date_of_birth.month) ? EncodingUtil.urlEncode(this.individual_date_of_birth.month, 'UTF-8') : '')
                        + '&person[dob][year]=' + (this.individual_date_of_birth != null && String.isNotBlank(this.individual_date_of_birth.year) ? EncodingUtil.urlEncode(this.individual_date_of_birth.year, 'UTF-8') : '')
                        + '&person[address][line1]=' + (this.individual_address != null && String.isNotBlank(this.individual_address.line1) ? EncodingUtil.urlEncode(this.individual_address.line1, 'UTF-8') : '')
                        + '&person[address][line2]=' + (this.individual_address != null && String.isNotBlank(this.individual_address.line2) ? EncodingUtil.urlEncode(this.individual_address.line2, 'UTF-8') : '')
                        + '&person[address][city]=' + (this.individual_address != null && String.isNotBlank(this.individual_address.city) ? EncodingUtil.urlEncode(this.individual_address.city, 'UTF-8') : '')
                        + '&person[address][state]=' + (this.individual_address != null && String.isNotBlank(this.individual_address.state) ? EncodingUtil.urlEncode(this.individual_address.state, 'UTF-8') : '')
                        + '&person[address][postal_code]=' + (this.individual_address != null && String.isNotBlank(this.individual_address.postal_code) ? EncodingUtil.urlEncode(this.individual_address.postal_code, 'UTF-8') : '')
                        + '&person[address][country]=' + (this.individual_address != null && String.isNotBlank(this.individual_address.country) ? EncodingUtil.urlEncode(this.individual_address.country, 'UTF-8') : '')
                        + '&person[relationship][executive]=' + this.individual_relationship_executive
                        + '&person[relationship][representative]=' + this.individual_relationship_representative;
            return encodedURL;
        }
    }

    public class StripePersonTokenResponse {
        public String id;
        public String client_ip;
        public String created;
        public StripeError error;
    }

    public class StripeError {
        public String code;
        public String doc_url;
        public String message;
        public String param;
        public String type;

        public String getFormattedError() {
            return '[bankToken] ' + this.message;
        }
    }

    public class StripeBankTokenDetails {
        public String id;
        public String account_holder_name;
        public String account_holder_type;
        public String bank_name;
        public String country;
        public String fingerprint;
        public String last4;
        public String routing_number;
        public String status;
    }

    public class StripeExternalAccountRequest {
        public String external_account;

        public String getURLEncoded() {
            return 'external_account=' + (this.external_account != null ? this.external_account : '');
        }
    }

    public class StripeExternalAccountResponse {
        public String id;
        public String account;
        public String account_holder_name;
        public String account_holder_type;
        public String bank_name;
        public String country;
        public boolean default_for_currency;
        public String fingerprint;
        public String routing_number;
        public String status;
        public StripeError error;
    }

    public class BFFCreatePromotionRequest {
        public String promotion_category_id;
        public BFFPromoContraintsReq constraint;
        public BFFPromoBenefitReq benefit;
        public Integer submarket_id;
        public BFFPromoStoreCatReq store_category;
        public String sfdc_id;
    }

    public class BFFPromoContraintsReq {
        public Decimal min_subtotal;
        public Boolean new_consumers_only;
    }

    public class BFFPromoBenefitReq {
        public Integer delivery_fee;
    }

    public class BFFPromoStoreCatReq {
        public String title;
        public String description;
        public Boolean show_as_carousel;
        public Integer sort_order;
    }

    public class BFFCreatePromotionResponse {
        public String id;
        public BFFErrorResponse errors;
    }

    public class BFFUpdatePromotionRequest {
        public String promotion_id;
        public BFFPromoStoreCatReq store_category;
        public String sfdc_id;
    }

    public class BFFUpdatePromotionResponse {
        public String status;
        public String id;
    }

    public class BFFCreateStorePromotionRequest {
        public Integer submarket_id;
        public Datetime start_date_time;
        public Datetime end_date_time;
        public String status;
        public Integer store_id;
        public String promotion_id;
        public Decimal percentage_rate;
        public Decimal absolute_rate_in_cents;
        public Integer sort_order;
        public String sfdc_id;
    }

    public class BFFCreateStorePromotionResponse {
        public String status;
        public String id;
    }

    public class BFFUpdateStorePromotionRequest {
        public String store_promotion_id;
        public String sfdc_id;
        public Integer sort_order;
    }

    public class BFFUpdateStorePromotionStatusRequest {
        public String store_promotion_id;
        public String sfdc_id;
    }

    public class BFFUpdateStorePromotionStatusResponse {
        public String status;
        public String id;
    }


    public class BFFBulkResponse {
        public String id;
        public String status;
        public String updated_at;
        public String resource;
        public List<BFFErrorResponse> errors;
    }

    public class BFFErrorResponse {
        public String field;
        public String code;
        public String message;
    }

    public class BFFBulkCreatePromotionRequest {
        public List<BFFCreatePromotionRequest> requests;
    }


    public class BFFBulkUpdatePromotionRequest {
        public List<BFFUpdatePromotionRequest> requests;
    }

    public class BFFBulkCreateStorePromotionRequest {
        public List<BFFCreateStorePromotionRequest> requests;
    }

    public class BFFBulkUpdateStorePromotionStatusRequest {
        public List<BFFUpdateStorePromotionStatusRequest> requests;
    }

    public class BFFBulkUpdateStorePromotionRequest {
        public List<BFFUpdateStorePromotionRequest> requests;
    }

    public class coverageCheckResponse {
        public String starting_point;
        public Boolean valid;
        public String submarket_is_valid;
        public String starting_point_name;
        public String pickup_address;
        public coverageChecError errors;
    }

    public class CoverageCheckResponseV2 {
        public StartingPoint starting_point;
        public SubMarket submarket;
        public Integer statusCode;
        public String status;
    }

    public class StartingPoint{
        public String id;
        public String name;
        public Boolean active;
    }

    public class SubMarket{
        public String id;
        public String name;
        public Boolean active;
    }

    public class coverageChecError{
		public String closest_starting_point_name;	//ME: Lewiston
		public String[] pickup_address;
        public Integer closest_starting_point;	//3753
    }
    // public class storeBountyProgramLinkRequest {
    //     public Integer store_id;
    //     public String SFDC_account_id;
    //     public List<BountyProgram> bounty_programs;
    // }

    // public class BountyProgram {
    //     public String type;
    //     public String start_date_time;
    //     public String end_date_time;
    //     public Integer amount;
    //     public String description;
    // }

    // public class BountyProgramResponse {
    //     public String id;
    //     public String type;
    //     public BountyConsumerPromotion consumer_promotion;
    // }

    // public class BountyConsumerPromotion {
    //     public String id;
    //     public String code;
    //     public List<BountySubmarketResponse> submarkets;
    // }

    // public class BountySubmarketResponse {
    //     public Integer id;
    // }

    public class SnapprBookingRequest {
        public String title;
        public Double latitude;
        public Double longitude;
        public String shoottype;
        public String start_at;
        public Integer duration;
        public String location_notes;
        public String style_notes;
        public String customer_firstname;
        public String customer_surname;
        public String customer_email;
        public String customer_mobilephone;
        public String customer_company;
        public String internal_id;
        public String address;
    }

    public class SnapprBookingResponse {
        public String uid;
        public Double latitude;
        public Double longitude;
        public String shoottype;
        public String start_at;
        public Integer duration;
        public String location_notes;
        public String style_notes;
        public String customer_firstname;
        public String customer_surname;
        public String customer_email;
        public String customer_mobilephone;
        public String customer_company;
        public String photographer_name;
        public String created_at;
        public String updated_at;
    }

    public class SnapprAvailabilityRequest {
        public Double latitude;
        public Double longitude;
        public String shootType;
        public Integer duration;
        public String booking_date;

    }
    public class SnapprAvailabilityResponse {
        public Double latitude;
        public Double longitude;
        public String shootType;
        public Integer duration;
        public String booking_date;
        public String timezone;
        public List<String> available_times;
    }
    public class SnapprErrorResponse {
        public List<String> errors;
        public String code;
    }
    /**
    *   @description Request object for Fee Onboarding DSJ API
    */
    public class MxFeeOnboardingRequest {
        public String creator_email;
        public List<MxAffiliateProgram> programs;
    }
    /**
     * @description Request object for Fee Onboarding MuleSoft API
     */
    public class MxFeeOnboardingRequest_MS {
        public String creator_user_id;
        public List<MxAffiliateProgram_MS> programs;
    }
    /**
    *   @description Response object from Fee Onboarding DSJ API
    */
    public class FeeOnboardingResponse {
        public List<MxAffiliateProgramResponse> created_programs;
        public String non_field_errors;
        public String request;
        public String response;
        public Integer statusCode;
        public String errorMessage;
    }
    /**
    *   @description Response object from Fee Onboarding MS API
    */
    public class FeeOnboardingResponse_MS {
        public List<MxAffiliateProgramResponse_MS> createdPrograms;
        public String request;
        public String response;
        public Integer statusCode;
        public String errorMessage;
    }
    /**
    *   @description Mx Affiliate Program for Fee Onboarding DSJ API
    */
    public class MxAffiliateProgram {
        public Integer store_id;
        public String experience;
        public String channel;
        public String fulfillment_type;
        public String audience;
        public List<MxAffiliateFeeAttribute> fee_attributes;
        public String program_cap_type;
        public Decimal program_cap;
        public String program_type;
        public Datetime start_time;
        public Datetime end_time;
        public String salesforce_opportunity_id;
    }
    /**
     *   @description Mx Affiliate Program for Fee Onboarding MuleSoft API
     */
    public class MxAffiliateProgram_MS {
        public String store_id;
        public String experience;
        public String channel;
        public String fulfillment_type;
        public String audience;
        public MxAffiliateSchedule_MS schedule;
        public List<MxAffiliateFeeAttribute_MS> fee_attributes;
        public String program_cap_type;
        public Decimal program_cap;
        public String program_type;
        public Datetime start_time;
        public Datetime end_time;
        public String salesforce_opportunity_id;
    }
    /**
     *   @description Mx Affiliate Schedule for Fee Onboarding MuleSoft API
     */
    public class MxAffiliateSchedule_MS {
        public String name;
        public String frequency;
        public Datetime effective_start_date;
        public Datetime effective_end_date;
        public Datetime anchor_start_date;
        public Datetime anchor_end_date;
        public String create_method_type;
    }
    /**
    *   @description Mx Affiliate Fee Attribute for Fee Onboarding DSJ API
    */
    public class MxAffiliateFeeAttribute {
        public String name;
        public String friendly_display_name;
        public String fee_type;
        public Integer flat_fee_in_cents;
        public String flat_fee_in_minor_units;
        public String fee_rate;
        public String fee_rate_charging_target;
        public Integer min_amount_in_cents;
        public Integer max_amount_in_cents;
        public Datetime start_time;
        public Datetime end_time;
    }
    /**
     *   @description Mx Affiliate Fee Attribute for Fee Onboarding MuleSoft API
     */
    public class MxAffiliateFeeAttribute_MS {
        public String name;
        public String friendly_display_name;
        public String fee_type;
        public String flat_fee_in_cents;
        public String flat_fee_in_minor_units;
        public String fee_rate;
        public String fee_rate_charging_target;
        public Integer min_amount_in_cents;
        public Integer max_amount_in_cents;
        public Datetime start_time;
        public Datetime end_time;
    }
    /**
    *   @description Mx Affiliate Program response from Fee Onboarding DSJ API
    */
    public class MxAffiliateProgramResponse {
        public String program_id;
        public String schedule_id;
        public List<String> fee_attribute_ids;
    }
    /**
    *   @description Mx Affiliate Program response from Fee Onboarding MS API
    */
    public class MxAffiliateProgramResponse_MS {
        public String programId;
        public String scheduleId;
        public List<String> feeAttributeIds;
    }
    /**
    *   @description Request object for Fee Onboarding DSJ API
    */
    public class CxFeeOnboardingRequest {
        public Integer store_id;
        public List<Product> products;
        public String creator_email;
    }
    /**
    *   @description Request object for Fee Onboarding MuleSoft API
    */
    public class CxFeeOnboardingRequest_MS {
        public String store_id;
        public List<Product_MS> opportunity_products;
        public String creator_user_id;
    }
    /**
     *   @description Cx Delivery Fee Product object for Fee Onboarding DSJ API
     */
    public class Product {
        public Datetime created_at;
        public Datetime end_time;
        public Datetime start_time;
        public Decimal service_rate;
        public Integer delivery_fee;
        public Integer min_order_fee;
        public Integer min_order_subtotal;
        public String audience;
        public String channel;
        public String experience;
        public String fulfillment_type;
        public String opportunity_id;
        public String opportunity_line_item_id;
    }
    /**
     *   @description Cx Delivery Fee Product object for Fee Onboarding MS API
     */
    public class Product_MS {
        public Datetime created_at;
        public Datetime end_time;
        public Datetime start_time;
        public String service_rate;
        public String delivery_fee;
        public Integer min_order_fee;
        public Integer min_order_subtotal;
        public String audience;
        public String channel;
        public String experience;
        public String fulfillment_type;
        public String opportunity_id;
        public String opportunity_line_item_id;
    }

    public class SendbirdCaseUpdate{
        public String agentFirstName;
        public String caseId;
        public String ownerId;
        public String prevOwnerId;
        public String prevCaseStatus;
        public String caseStatus;
        public String chatSessionId;
        public String chatEscalationId;
        public String caseOrigin;
        public Boolean isRealTimeQueue;
    }
    public class SendbirdResponse {
        public String responseKey;
    }
    public class SendbirdRequest {
        public List<SendbirdCaseUpdate> caseUpdates;
    }

    //OCUS API
    public class OCUSAPIRequest{
        public OCUSData data;
    }

    public class OCUSData{
        public String type;
        public Attributes attributes;
        public Relationships relationships;

        //response
        public String id;
    }

    public class Attributes{
        public String name;
        public String internal_reference;
        //Fixed dates must be more than 48 hours in the future. Attempting to set a fixed date within the next 48 hours will return an error from the API.
        public String approved_appointment;
        public String description;

        //Webhook response
        public String mission_id;
        public String mission_reference_id;
        public String organization_id;
        public String public_status;
        public String assignment_id;

        //getResponse
        public String current_status;
        public Relationships relationships;

        //Media
        public Boolean deliverable;
        public String extension;
        public String md5;
        public String mime_type;
        public String original_filename;
        public String url;
        public Integer size;
        public String type;
        public String version;
        public Boolean uploaded;

        //Blocked
        public String code;
        public String status;
        public String payload;
        public String blocker_id;
        public BlockedBy blocked_by;
    }

    public class BlockedBy {
        public String type;
        public String id;
        public Attributes attributes;
    }

    public class Relationships{
        public OCUSAddress address;
        public Offers offers;
        public Contacts contacts;

        //Get Response Parameters
        public OCUSOrganization organization;
        public OCUSMedia media;

         //get response Relationships --> organization --> relationships
        //Commenting as we don't need indidual files at this time
        //public OCUSFiles files;

        //Will get the zip file url for all photos
        public OCUSFiles archives;

        public OCUSEvent events;
    }

    public class OCUSEvent{
        public List<OCUSEventData> data;
    }

    public class OCUSEventData{
         public String type;
         public String id;
         public Attributes attributes;
         public List<Relationships> relationships;
    }

    public class OCUSAddress{
         public AddressData data;
         public String type;
         public AddressAttributes attributes;
         public String id;
    }

    public class OCUSFiles {
        public List<OCUSFileData> data;
    }

    public class OCUSFileData {
        public String type;
        public Attributes attributes;
        public String id;
        public List<Relationships> relationships;
    }

    public class OCUSMedia {
        public List<OCUSData> data;
    }

    public class AddressData{
        public String type;
        public AddressAttributes attributes;
    }

    public class AddressAttributes{
        public String city;
        public String country_code;
        public String street1;
        public String zip_code;
        public String state;
        public String street2;
    }

    public class Contacts{
        public List<ContactData> data;
    }

    public class ContactData{
        public String type;
        public ContactAttributes attributes;
    }

    public class ContactAttributes{
        public String firstname;
        public String lastname;
        public String email;
        public String phone_1;
    }

    public class Offers{
        public List<OfferData> data;
    }

    public class OfferData{
        public String type;
        public String id;
    }

    public class OCUSWebhookResponse{
        public String type;
        public String id;
        public Attributes attributes;
    }

    //Create Mission response
    public class OCUSMissionResponse{
        public OCUSData data;
        public Boolean isSuccess;
        public String message;
        public Integer statusCode;
        public Map<String,List<String>> errors;
    }

    //get Milestone
    public class OCUSOrganization{
        public String type;
        public String id;
        public GETAttributes attributes;
        public Relationships relationships;
    }

    public class GETAttributes{
        //Get Response Parameters
        public String reference_id;
        public String name;
        public String current_status;
        public String public_status;
        public String description;
        public List<String> product_types;
        public Integer short_id;
        public Boolean is_legacy;
        public String approved_appointment;
        public String internal_reference;
        public String operator_density;
        public String expires_in;
        public String selected_at;
        public String attributed_at;
        public String started_at;
        public String created_at;
        public String updated_at;
        public String assignment_id;

        // Get Response Parameters --> relationships --> organization
        public String country_code;
        public String vertical;
        public String url;
        public String parent_organization_id;
        public Boolean missions_visibility;
        public Boolean ready;
        public String next_available_appointment;
    }
    //dispatchCalloutApiRequest
    public class dispatchRequest{
        public CustomerAudience customerAudience;
    }
    public class CustomerAudience{
        public List<Customer> customers;
    }

    public class Customer{
        public String email;
        public String phoneNumber;
        public Decimal customerType;
        public Decimal experience;
    }
    //BIZS-2325  - for chargeback sumbission automation
    public class ChargeBackSubmission{
        public Id caseId;
        public String description;
        public String deliveryUuidShort;
        public String storeId;
        public Integer storeRefund; //if Error Charge Amount = 12.34, then store_refund = 1234
        public String idempotencyKey;
        public String ddUserId;
        public String merchantPaymentAdjustmentReason;//BIZS-2975 - we use this parameter to distinguish between error charge disputes and cancelled order refunds
        public String contactName;
        public String contactEmail;
    }

    public class ChargeBackSubmissionResponse {
        public String responseKey;
    }
    public class ChargeBackSubmissions {
        public List<ChargeBackSubmission> lstChargeBackSubmission;
    }
}