/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 04/11/2019
*
* @group Nimda
*
* @description This class maintains all constants relevant to Nimda data sync functionality
*
**************************************************************************************************************************************/
public class CDdNimdaSyncConstants {

    public static final String STEP_INITIALIZATION = 'Initialize';
    public static final String STEP_SEARCH_ADDRESS = 'Search Address';
    public static final String STEP_SEARCH_STORE = 'Search Store';
    public static final String STEP_GET_STORE = 'Get Store';
    public static final String STEP_GET_STORE_MENU = 'Get Store Menu';
    public static final String STEP_CREATE_BUSINESS = 'Create Business';
    public static final String STEP_GET_BUSINESS = 'Get Business';
    public static final String STEP_GET_PAYMENT_ACCOUNT = 'Get Payment Account';
    public static final String STEP_CREATE_STORE = 'Create Store';
    public static final String STEP_UPDATE_STORE = 'Update Store';
    public static final String STEP_MX_API = 'Get Mx Affiliate Program';
    public static final String STEP_CREATE_USER = 'Create User';
    public static final String STEP_CREATE_MERCHANT = 'Create Merchant';
    public static final String STEP_PAYMENT_ACCOUNT = 'Payment Account';
    public static final String STEP_STRIPE_BANK_TOKEN = 'Stripe Bank Token';
    public static final String STEP_STRIPE_BANK_ACCOUNT = 'Stripe Bank Account';
    public static final String STEP_COMPLETE = 'Complete';
    public static final String FULL_ONBOARDING_CREATE = 'Full Onboarding Create';
    public static final String FULL_ONBOARDING_UPDATE = 'Full Onboarding Update';
    public static final String STEP_PRODUCT_AND_PRICING_ONBOARDING = 'Product and Pricing Onboarding';
    public static final String STEP_CREATE_MERCHANT_PROGRAM = 'Create Merchant Program';
    public static final String STEP_CREATE_MERCHANT_RECURRING_PROGRAM = 'Create Merchant Recurring Program';
    public static final String STEP_CREATE_OPPORTUNITY_PRODUCTS = 'Create Opportunity Products';
    public static final String STEP_CHANGE_OF_OWNERSHIP_CREATE = 'Change of Ownership Create';
    public static final String STEP_CHANGE_OF_OWNERSHIP_UPDATE = 'Change of Ownership Update';

    public static final String ERROR_TYPE_VALIDATION = 'Validation Error';
    public static final String ERROR_TYPE_RESPONSE = 'Response Error';
    public static final String ERROR_TYPE_RUNTIME_EXCEPTION = 'Runtime Exception';

    public static final String AUTHORIZATION_BEARER = 'Bearer ';

    public static final Map<String, Schema.RecordTypeInfo> RECORD_TYPE_OPPORTUNITY_BY_DEV_NAME
                                                = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName();
    public static final String RECORD_TYPE_OPPORTUNITY_DEV_NAME_MARKETPLACE = 'ML_Inside_Sales';
    public static final String RECORD_TYPE_OPPORTUNITY_DEV_NAME_ENT_MARKETPLACE = 'Enterprise_Marketplace';
    public static final Id RECORD_TYPE_OPPORTUNITY_ID_MARKETPLACE = RECORD_TYPE_OPPORTUNITY_BY_DEV_NAME.get(RECORD_TYPE_OPPORTUNITY_DEV_NAME_MARKETPLACE).getRecordTypeId();
    public static final Id RECORD_TYPE_OPPORTUNITY_ID_ENT_MARKETPLACE = RECORD_TYPE_OPPORTUNITY_BY_DEV_NAME.get(RECORD_TYPE_OPPORTUNITY_DEV_NAME_ENT_MARKETPLACE).getRecordTypeId();
    public static final Set<Id> RECORD_TYPE_OPPORTUNITY_IDS_FOR_NEW_PRICING_TIER_AND_FEE = new Set<Id>{
        RECORD_TYPE_OPPORTUNITY_ID_MARKETPLACE
        , RECORD_TYPE_OPPORTUNITY_ID_ENT_MARKETPLACE
    };

    public static final String TRIAL_TYPE_FREE_TRIAL = 'Free Trial';
    public static final String TRIAL_TYPE_PROMOTIONAL_PERIOD = 'Promotional Period';
    public static final Set<String> TRIAL_TYPES_FREE_OR_PROMO = new Set<String>{TRIAL_TYPE_FREE_TRIAL, TRIAL_TYPE_PROMOTIONAL_PERIOD};

    public static final Boolean ENABLE_S2N_TRIAL_PRICING_TIER_AND_FEE = CDdExperimentSvc.getFeatureFlag('Enable_S2N_Trial_Pricing_Tier_And_Fee__c');
    public static final Boolean ENABLE_S2N_CREATION_METHOD = CDdExperimentSvc.getFeatureFlag('Enable_S2N_Creation_Method__c');
    public static final Boolean ENABLE_S2N_CUSTOM_DELIVERY_FEE = CDdExperimentSvc.getFeatureFlag('Enable_S2N_Custom_Delivery_Fee__c');
    public static final Boolean ENABLE_S2N_AU_INDIVIDUAL_ID_NUMBER = CDdExperimentSvc.getFeatureFlag('Enable_S2N_AU_Individual_Id_Number__c');
    public static final Boolean ENABLE_S2N_CA_INDIVIDUAL_ID_NUMBER = CDdExperimentSvc.getFeatureFlag('Enable_S2N_CA_Individual_Id_Number__c');
    public static final Boolean ENABLE_S2N_US_INDIVIDUAL_ID_NUMBER = CDdExperimentSvc.getFeatureFlag('Enable_S2N_US_Individual_Id_Number__c');
    public static final Boolean ENABLE_S2N_DD_USER = CDdExperimentSvc.getFeatureFlag('Enable_S2N_DD_User__c');
    public static final Boolean ENABLE_S2N_CHANGE_OF_OWNERSHIP;
    public static final Boolean DISABLE_ONBOARD_PROGRAM_API;
    public static final Boolean DISABLE_MX_RECURRING_PROGRAM_API;
    public static final Boolean DISABLE_DELIVERY_FEE_API;

    public static final String ACCOUNT_FORMSTACK_VERSION_SSMO = 'SSMO';
    public static final String OPPORTUNITY_STAGE_CLOSED_WON = 'Closed Won';
    public static final String ORDER_PROTOCOL_POINT_OF_SALE = 'POINT_OF_SALE';
    public static final String OPPORTUNITY_TYPE_PROTOCOL_CHANGE_ONLY_NP = 'Protocol Change Only (NP)';
    public static final String SELF_ONBOARDING = 'SELF_ONBOARDING';
    public static final Set<String> NIMDA_V3_PYMT_SUPPORTED_BILLING_CODES = new Set<String>(System.Label.Nimda_V3_Pymt_Supported_Billing_Codes.split(','));
    public static final String OPPORTUNITY_TYPE_CHANGE_OF_OWNERSHIP = 'Change of Ownership';

    public static final String CREATE_STORE_ENDPOINT_SUFFIX = '/v1/stores';
    public static final String CREATE_USER_ENDPOINT_SUFFIX = '/v1/users';
    public static final String CREATE_MERCHANT_ENDPOINT_SUFFIX = '/v1/merchants';
    public static final String CREATE_PAYMENT_ACCOUNT_ENDPOINT_SUFFIX = '/v1/payment_accounts';

    public static final String CREATE_STRIPE_BANK_TOKEN_ENDPOINT = 'https://api.stripe.com/v1/tokens';
    public static final String CREATE_STRIPE_BANK_ACCOUNT_ENDPOINT = 'https://api.stripe.com/v1/accounts/' + '{0}';
    public static final String CREATE_STRIPE_BANK_ACCOUNT_ENDPOINT_SUFFIX = '/external_accounts';

    public static final String CREATE_USER_EMAIL_DOMAIN = 'doordash.com';
    public static final String CREATE_USER_LAST_NAME_ADMIN = 'Admin';

    public static final vCS__c VCS_API_SETTINGS = vCS__c.getInstance();

    public static final Map<String, String> SFTODSJ_STORE_ORDERPROTOCOLMAP = new Map<String, String>{
        'Android Tablet (Merchant Owns)' => 'IPAD',
            'Email' => 'EMAIL',
            'Fax' => 'FAX',
            'iOS Tablet (Merchant Owns)' => 'IPAD',
            'Other' => 'OTHER',
            'Tablet (DoorDash Owns)' => 'IPAD',
            'Tablet and Printer (DoorDash Owns)' => 'IPAD',
            'POS' => 'POINT_OF_SALE',
            'POS and Tablet (Merchant Owns)' => 'POINT_OF_SALE',
            'POS and and Tablet (DoorDash Owns)' => 'POINT_OF_SALE', //[JN-NOTE]: Fix this typo before merging
            'POS and Tablet Return Label' => 'POINT_OF_SALE',
            'Phone' => 'PHONE'
            };

    public static final Map<String, String> SFTODSJ_STORE_ORDERTOCONFIRMPROTOCOLMAP = new Map<String, String>{
            'IPAD' => 'ROBOCALL_LONG_DELAY',
            'EMAIL' => 'ROBOCALL_SIMPLE',
            'FAX' => 'ROBOCALL_SIMPLE',
            'Other' => 'NO_CONFIRMATION',
            'POINT_OF_SALE' => 'NO_CONFIRMATION',
            'PHONE' => 'NO_CONFIRMATION'
        };

    public static final Map<String, String> SFTODSJ_STORE_POSTYPEMAP = new Map<String, String>{
            'OLO' => 'olo_rails',
            'Chick-Fil-A' => 'chick_fil_a',
            'Novadine' => 'novadine',
            'Chipotle' => 'chipotle',
            'Cheesecake Factory' => 'positouch'
        };

    public static final List<String> VALIDATE_FIELDS_ON_OPPORTUNITY = new List<String>{'Name', 'Type'};
    public static final List<String> VALIDATE_POS_FIELDS_ON_OPPORTUNITY = new List<String>{'POS_Integration_ID__c', 'POS_Integration_Type__c'};
    public static final List<String> VALIDATE_FIELDS_ON_ACCOUNT = new List<String>{'RealZip_Submarket_ID__c', 'Phone'};
    public static final List<String> VALIDATE_ADDRESS_FIELDS_ON_ACCOUNT = new List<String>{'BillingStreet', 'BillingState', 'BillingCity', 'BillingPostalCode', 'BillingCountry'};
    public static final List<String> VALIDATE_GEOLOCATION_FIELDS_ON_ACCOUNT = new List<String>{'BillingLatitude', 'BillingLongitude'};
    public static final List<String> VALIDATE_PAYMENT_ACCOUNT_FIELDS_ON_ACCOUNT = new List<String>{'Legal_Business_Name__c', 'EIN_Encrypted__c', 'Bank_Account_Number_Encrypted__c', 'Bank_Routing_Number_Encrypted__c'};
    public static final List<String> VALIDATE_ACCOUNT_TOKEN_FIELDS_ON_OPPORTUNITY = new List<String>{'Stripe_Account_Owner__c'};
    public static final List<String> VALIDATE_ACCOUNT_TOKEN_FIELDS_ON_ACCOUNT = new List<String>{'Legal_Business_Name__c', 'EIN_Encrypted__c', 'ShippingStreet', 'ShippingCity', 'ShippingState', 'ShippingPostalCode', 'ShippingCountry'};
    public static final List<String> VALIDATE_ACCOUNT_TOKEN_FIELDS_ON_CONTACT = new List<String>{'FirstName', 'LastName', 'Birthdate', 'MailingStreet', 'MailingCity', 'MailingState', 'MailingPostalCode', 'MailingCountry'};
    public static final List<String> VALIDATE_ACCOUNT_TOKEN_FIELDS_ON_ACCOUNT_FOR_US_CAN = new List<String>{'Legal_Business_Name__c', 'EIN_Encrypted__c'};
    public static final List<String> VALIDATE_ACCOUNT_TOKEN_FIELDS_ON_CONTACT_FOR_US_CAN = new List<String>{'FirstName', 'LastName'};

    public static final String ERROR_MSG_INVALID_ACCOUNT_ID = 'Account Id was null! Please provide a valid Account Id!';
    public static final String ERROR_MSG_INVALID_OPPORTUNITY_ID = 'Opportunity Id was null or not found! Please provide a valid Opportunity Id!';
    public static final String ERROR_MSG_INVALID_STORE_ID = 'The store id was null! Please provide a valid store id!';
    public static final String ERROR_MSG_INVALID_BUSINESS_ID = 'The business id was null! Please provide a valid business id!';
    public static final String ERROR_MSG_INVALID_USER_ID = 'The user id was null! Please provide a valid user id!';
    public static final String ERROR_MSG_INVALID_OPPORTUNITY_STAGE = 'Your opportunity is invalid because it has not been Closed Won!';
    public static final String ERROR_MSG_OPPORTUNITY_TYPE_NON_PARTNER = 'A user was not generated. The opportunity you are trying to create a user for is not a partner!';
    public static final String ERROR_MSG_INVALID_STRIPE_ACCOUNT_ID = 'You did not generate a stripe account id!';
    public static final String ERROR_MSG_INVALID_BANK_TOKEN_ID = 'You did not generate a bank token id!';
    public static final String ERROR_MSG_ADDRESS_NOT_FOUND = 'Address not found';
    public static final String ERROR_MSG_MULTIPLE_ADDRESSES_FOUND = 'Multiple addresses found';
    public static final String ERROR_MSG_STORE_NOT_FOUND = 'Store not found';
    public static final String ERROR_MSG_MULTIPLE_STORES_FOUND = 'Multiple stores found';
    public static final String ERROR_MSG_INVALID_ACCOUNT_TOKEN_ID = 'You did not generate an account token id!';
    public static final String ERROR_MSG_INVALID_PAYMENT_ACCOUNT_ID = 'Please provide a valid payment account id!';
    public static final String ERROR_MSG_INVALID_PERSON_TOKEN_ID = 'You did not generate a person token id!';
    public static final String ERROR_MSG_OPPORTUNITY_NOT_CLOSED_WON = 'Send to Nimda can only be used for Opportunities where Stage = "Closed Won". Please move the Opportunity Stage to "Closed Won" to proceed.';
    public static final String ERROR_MSG_INVALID_BUSINESS_NAME = 'The business name was blank! Please provide a valid business name!';
    public static final String ERROR_MSG_NIMDA_V3_PYMT_UNSUPPORTED_BILLING_CODE = 'Billing Country {0} not supported by S2N v3 Payment Check';
    public static final String ERROR_MSG_DECISION_MAKER_NOT_FOUND = 'Unable to update contact e-mail. Decision maker not found on the Opportunity record';
    public static final String ERROR_MSG_CHANGE_OF_OWNERSHIP_PROPOSED_DATE_OF_MENU = System.Label.Nimda_Change_Of_Ownership_Proposed_Date_Of_Menu_Error_Msg;

    static {
        DISABLE_ONBOARD_PROGRAM_API = CDdExperimentSvc.getFeatureFlag('Disable_Onboard_Program_API__c') == null ? false : CDdExperimentSvc.getFeatureFlag('Disable_Onboard_Program_API__c');
        DISABLE_MX_RECURRING_PROGRAM_API = CDdExperimentSvc.getFeatureFlag('Disable_Mx_Recurring_Program_API__c') == null ? false : CDdExperimentSvc.getFeatureFlag('Disable_Mx_Recurring_Program_API__c');
        DISABLE_DELIVERY_FEE_API = CDdExperimentSvc.getFeatureFlag('Disable_Delivery_Fee_API__c') == null ? false : CDdExperimentSvc.getFeatureFlag('Disable_Delivery_Fee_API__c');
        ENABLE_S2N_CHANGE_OF_OWNERSHIP = CDdExperimentSvc.getFeatureFlag('Enable_S2N_Change_Of_Ownership__c') == null ? false : CDdExperimentSvc.getFeatureFlag('Enable_S2N_Change_Of_Ownership__c');
    }
    public static final String DIRECT_DEPOSIT = 'Direct Deposit';
    public static final String ORDER_PLACER_RED_CARD = 'Order Placer Red Card';
    public static final String DASHER_RED_CARD = 'Dasher Red Card';
    public enum ShoppingProtocolValue {
        MX_PICK,
        SHOPPER_PICK,
        DASHER_PICK
    }
    public static final Map<String,ShoppingProtocolValue> shoppingProtocolMap = new Map<String,ShoppingProtocolValue> {
        'Mx Pick' =>  ShoppingProtocolValue.MX_PICK ,
        'Shopper Pick' => ShoppingProtocolValue.SHOPPER_PICK,
        'Dasher Pick' => ShoppingProtocolValue.DASHER_PICK
    };

}