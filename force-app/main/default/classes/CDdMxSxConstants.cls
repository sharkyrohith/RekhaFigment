/********************************************************************************************************************
* @author Sriram
* @date 11/01/2021
*
* @group Merchant Services
*
* @description Constants are defined here
*
**************************************************************************************************************************************/
public class CDdMxSxConstants {
    /** Define Mx Services enums and related variables here */
    public enum MXSX_EVENT {
        OPPORTUNITY_CLOSED_WON,
        OPPORTUNITY_RELATED_CASE_UPDATES,
        STORE_ACTIVE,
        MILESTONE_BLOCKED,
        MILESTONE_COMPLETE,
        SEND_MX_ORDER_TO_VENDOR,
        MILESTONE_IN_PROGRESS,
        TABLET_CASE_SHIPPED,
        TABLET_CASE_RECEIVED,
        POS_INTEGRATION_CASE_STATUS_CHANGE,
        MILESTONE_IN_DEAD,
        MX_ONBOARDING_UPDATE_INBOUND_EVENT,
        UPDATE_ORDER_FROM_ACCOUNT,
        MARKETPLACE_ONBOARDING_CASE_INSERT_EVENT,
        MARKETPLACE_ONBOARDING_CASE_UPDATE_EVENT,
        POS_INTEGRATION_REQUEST,
        POS_INTEGRATION_REQUEST_FROM_BAT,
        CAVIAR_ONBOARDING_CASE_UPDATE_EVENT
    }
     /** Define Mx Segment Notifications event enums*/
    public enum MXSX_SEGMENT_NOTIFICATION_EVENTS {
        MILESTONE_BLOCKED,
        MILESTONE_COMPLETED,
        OPPORTUNITY_CLOSED_WON,
        TABLET_CASE_SHIPPED,
        TABLET_CASE_RECEIVED
    }
    public static final Map<String, MXSX_EVENT> MXSX_EVENTS;
    /** Define feature flags here */
    public static final Boolean ENABLE_MXSX_FRAMEWORK;
    public static final Boolean ENABLE_MXSX_DECISIONMAKER_VALIDATION;
    /** Define Merchant Services configuration related variables here */
    public static final Date OPPORTUNITY_CLOSE_DATE_CUTOVER;
    public static final Integer MXSX_PLATFORM_EVENT_RETRY_LIMIT;
    public static Boolean GENERATE_MX_ORDER;
    public static Boolean ENABLE_MX_ORDER_ROUTING;
    public static Boolean ENABLE_MX_ONBOARDING_PLATFORMEVENT_UPDATE;
    public static Set<String> MX_ORDER_OPEN_CASE_STATUS_TO_EXCLUDE;
    public static Set<String> MX_ORDER_SHIPPING_STATE_VALIDATION_COUNTRY_CODES_TO_EXCLUDE;
    public static Integer MX_ORDER_SUBMISSION_MIN_ELAPSED_MINUTES;
    /** Define batch variable here */
    public final static Integer DEFAULT_BATCH_SIZE = 50;
    public final static Integer DEFAULT_BATCH_LAST_MODIFIED_DAYS = 5;
    public final static Integer DEFAULT_QUERY_LIMIT = 10000;
    /** Define SObject Type variables here */
    public static final String SOBJECT_TYPE_ACCOUNT = 'Account';
    public static final String SOBJECT_TYPE_OPPORTUNITY = 'Opportunity';
    /** Define Mx Services Record Type variables here */
    public static final Id RECORD_TYPE_ID_ACCOUNT_PARENT_ACCOUNT = CDdSchemaUtils.ACCOUNT_RT.parentAccountId();
    public static final Id RECORD_TYPE_ID_ACCOUNT_ENTERPRISE_MARKETPLACE = CDdSchemaUtils.ACCOUNT_RT.enterpriseMarketplaceId();
    public static final Id RECORD_TYPE_ID_ACCOUNT_MARKETPLACE = CDdSchemaUtils.ACCOUNT_RT.prospectId();
    public static final Id RECORD_TYPE_ID_OPPORTUNITY_ENTERPRISE_MARKETPLACE = CDdSchemaUtils.OPPORTUNITY_RT.enterpriseMarketplaceId();
    public static final Id RECORD_TYPE_ID_OPPORTUNITY_MARKETPLACE = CDdSchemaUtils.OPPORTUNITY_RT.mlInsideSalesId();
    public static final Id RECORD_TYPE_ID_OPPORTUNITY_POST_SALE = CDdSchemaUtils.OPPORTUNITY_RT.postSaleId();
    public static final Id RECORD_TYPE_ID_CASE_MARKETPLACE_ONBOARDING = CDdSchemaUtils.CASE_RT.marketplaceOnboardingId();
    public static final Id RECORD_TYPE_ID_CASE_POST_SALE_ACTIVATIONS = CDdSchemaUtils.CASE_RT.postSaleActivationsId();
    public static final Id RECORD_TYPE_ID_CASE_POS_INTEGRATIONS = CDdSchemaUtils.CASE_RT.posIntegrationsId();
    public static final Id RECORD_TYPE_ID_CASE_CAVIAR_ONBOARDING = CDdSchemaUtils.CASE_RT.caviarOnboardingId();

    // Todo - move to CDdSchemaUtils
    public static final Map<String, Schema.RecordTypeInfo> CASE_RECORD_TYPE_INFO_BY_DEV_NAME = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName();
    public static final Id RECORD_TYPE_ID_CASE_STOREFRONT_ONBOARDING = CASE_RECORD_TYPE_INFO_BY_DEV_NAME.get('Storefront_Onboarding').getRecordTypeId();
    public static final Set<Id> MXSX_STORE_ACCOUNT_RECORD_TYPE_IDS = new Set<Id>{
        RECORD_TYPE_ID_ACCOUNT_ENTERPRISE_MARKETPLACE,
        RECORD_TYPE_ID_ACCOUNT_MARKETPLACE
    };
    public static final Set<Id> MXSX_PARENT_ACCOUNT_PLUS_STORE_ACCOUNT_RECORD_TYPE_IDS = new Set<Id>{
        RECORD_TYPE_ID_ACCOUNT_PARENT_ACCOUNT,
        RECORD_TYPE_ID_ACCOUNT_ENTERPRISE_MARKETPLACE,
        RECORD_TYPE_ID_ACCOUNT_MARKETPLACE
    };
    public static final Set<Id> MXSX_OPPORTUNITY_RECORD_TYPE_IDS = new Set<Id>{
        RECORD_TYPE_ID_OPPORTUNITY_ENTERPRISE_MARKETPLACE,
        RECORD_TYPE_ID_OPPORTUNITY_MARKETPLACE,
        RECORD_TYPE_ID_OPPORTUNITY_POST_SALE
    };
    public enum MXSX_OPPORTUNITY_PLATFORM {
        CAVIAR,
        CAVIAR_AND_DOORDASH,
        DOORDASH
    }
    public static final Map<String, MXSX_OPPORTUNITY_PLATFORM> MXSX_OPPORTUNITY_PLATFORM_STRING_ENUM_MAP = new Map<String, MXSX_OPPORTUNITY_PLATFORM>{
        'Caviar' => MXSX_OPPORTUNITY_PLATFORM.CAVIAR,
        'Caviar and DoorDash' => MXSX_OPPORTUNITY_PLATFORM.CAVIAR_AND_DOORDASH,
        'DoorDash' => MXSX_OPPORTUNITY_PLATFORM.DOORDASH
    };
    public static final Set<String> MXSX_OPPORTUNITY_CAVIAR_ORDER_PROTOCOL_POS = new Set<String>{'POS'};
    /** Define Mx Services Queue variables here */
    public static final Set<String> MX_SERVICES_QUEUE_DEVELOPER_NAMES = new Set<String>{
                                                                            'Post_Sale_Activations',
                                                                            'Storefront_Case_Holding_Queue',
                                                                            'Storefront_Implementation_Call_MOS',
                                                                            'Storefront_Link_Implementation_MxS',
                                                                            'Storefront_Under_Review_MxS',
                                                                            'POS_Integration_Requests',
                                                                            'Onboarding_Ads_Promos'
                                                                        };
    public static final String QUEUE_ID_STOREFRONT_POST_SALE_ACTIVATIONS;
    public static final String QUEUE_ID_POS_INTEGRATION_REQUESTS;
    public static final String QUEUE_ID_STOREFRONT_CASE_HOLDING_QUEUE;
    public static final String QUEUE_ID_STOREFRONT_IMPLEMENTATION_CALL_MOS;
    public static final String QUEUE_ID_STOREFRONT_LINK_IMPLEMENTATION_MXS;
    public static final String QUEUE_ID_STOREFRONT_UNDER_REVIEW_MXS;
    public static final String QUEUE_ID_ONBOARDING_ADS_PROMO;

    public static final Set<Decimal> BUSINESS_ID_WITH_NO_PARENT_ACCOUNTS = new Set<Decimal>{45655, 70678};
    public static final Set<String> ACCOUNT_STORE_ACTIVE_FIELD_API_NAMES = new Set<String>{'Currently_Active__c', 'Is_Partner__c'};
    public static final String OPPORTUNITY_STAGE_CLOSED_WON = 'Closed Won';
    public static final Set<String> OPPORTUNITY_RELATED_CASE_UPDATES_API_NAMES = new Set<String>{'OwnerId'};
    public static final Set<String> OPPORTUNITY_CLOSED_WON_TYPES_TO_EXCLUDE = new Set<String>{'Old Close Not in SFDC'};
    public static final String PACTSAFE_CONTRACT_TYPE_SSMO_SIGN_UP_SHEET = 'SSMO Sign Up Sheet';

    public static final Set<String> SELF_SERVE_USER_NAMES = new Set<String>{'Self-Serve Integration User', 'Store Front Integration User'};
    public static final String MULESOFT_INTEGRATION_USER_NAME = 'Mulesoft Integration User';
    public static final String FORMSTACK_INTEGRATION_USER_NAME = 'Formstack Integration User';
    public static final String NINTEX_INTEGRATION_USER_NAME = 'Nintex Integration User';

    public static final Set<Id> SELF_SERVE_USER_IDS;
    public static final Id MULESOFT_INTEGRATION_USER_ID;
    public static final Id FORMSTACK_INTEGRATION_USER_ID;
    public static final Id NINTEX_INTEGRATION_USER_ID;

    public static final Set<String> MXSX_MISSING_MILESTONES_UPDATE_RECORDTYPES = new Set<String>{RECORD_TYPE_ID_CASE_MARKETPLACE_ONBOARDING,
                                                                                                 RECORD_TYPE_ID_CASE_STOREFRONT_ONBOARDING,
                                                                                                 RECORD_TYPE_ID_CASE_POS_INTEGRATIONS
                                                                                                };
    public static final String CASE_STATUS_OPEN = 'Open';
    public static final String CASE_STATUS_CLOSED = 'Closed';
    public static final String CASE_STATUS_DEAD = 'Dead';
    public static final String CASE_STATUS_ONBOARDING_ADS_AND_PROMO = 'Onboarding Ads and Promo';
    public static final String CASE_STATUS_READY_TO_ACTIVATE = 'Ready to activate';
    public static final String CASE_STAGE_NOT_STARTED = 'Not Started';
    public static final String CASE_STAGE_READY_FOR_ACTIVATION = 'Ready for Activation';
    public static final String CASE_ORIGIN_OPP_CLOSED_WON = 'Closed Won Opportunity';
    public static final String CASE_ORIGIN_OPP_CLOSED_WON_SSMO = 'Closed Won Opportunity - SSMO';
    public static final String CASE_ORIGIN_LEMONADE = 'Lemonade';
    public static final String CASE_ORIGIN_UI_LEMONADE = 'UI - Lemonade';
    public static final Set<String> LEMONADE_CASE_ORIGINS = new Set<String>{'Lemonade','UI - Lemonade'};
    public static final Set<String> MXSX_CASEORIGINS_FOR_MILESTONES = new Set<String>{'Closed Won Opportunity'};
    public static final String SELF_SERVE_CASE_ORIGIN = 'Closed Won Opportunity - SSMO';

    public static final String STOREFRONT_CONTAINS_KEY_BUNDLE_NAME_FOR_CPQ = 'Storefront Package';
    public static final String STOREFRONT_CONTAINS_KEY_BUNDLE_NAME_FOR_LEGACY = 'Online Ordering Subscription';
    public static final String STOREFRONT_EVENTNAME = 'Storefront Implementation Call';

    public static final String DECK_RANK_ACE_OF_SPADES = 'Ace of Spades';
    public static final String DECK_RANK_KING_OF_SPADES = 'King of Spades';
    public static final String DECK_RANK_OF_SPADES = 'of Spades';
    public static final String SEGMENT_ENTERPRISE = 'Enterprise';
    public static final String SEGMENT_LOCAL_PREMIUM = 'Local Premium';
    public static final String SEGMENT_LOCAL = 'Local';
    public static final BusinessHours BUSINESS_HOURS_DEFAULT;
    public static final BusinessHours BUSINESS_HOURS_WEEKDAYS;

    public static final String MILESTONE_STATUS_API_NAME = 'Status__c';
    public static final String MILESTONE_STATUS_BLOCKED = 'Blocked';
    public static final Set<String> MILESTONE_MXSX_EVENTS_API_NAMES = new Set<String>{'Status__c', 'Status_Reason__c'};
    public static final String MX_ONBOARDING_MXSX_EVENTS_API_NAME =  'UpdateType__c';
    public static final String MX_ONBOARDING_MX_PORTAL_UPDATE_TYPE_INBOUND =  'Inbound';

    public static final String SOBJECT_TYPE_CASE = 'Case';
    public static final String SOBJECT_TYPE_MILESTONE = 'Milestone__c';
    public static final String SOBJECT_TYPE_MX_ONBOARDING = 'Mx_Onboarding__c';
    public static final String SOBJECT_TYPE_POS_INTEGRATION_REQUEST= 'Integration_Request__x';

    public static final Id CASE_RECORD_TYPE_ID_TABLET_REQUESTS = CDdSchemaUtils.CASE_RT.tabletRequestsId();
    public static final Map<String, Schema.RecordTypeInfo> MILESTONE_RECORD_TYPE_INFO_BY_DEV_NAME = Schema.SObjectType.Milestone__c.getRecordTypeInfosByDeveloperName();
    public static final Id MILESTONE_RECORD_TYPE_ID_DELIVER_TABLET = MILESTONE_RECORD_TYPE_INFO_BY_DEV_NAME.get('Deliver_Tablet').getRecordTypeId();
    public static final String CASE_TABLET_REQUEST_STATUS_RETURNED_TO_SENDER = 'Returned to Sender';
    public static Set<String> CASE_TABLET_REQUEST_STATUS_TO_PROCESS_FOR_UPDATE_DELIVER_TABLET = new Set<String>{'Shipped', 'Received', 'Dead', 'Returned to Sender', 'Rejected','Approved','Opened', 'Reopened'};
    public static final String MILESTONE_STATUS_IN_PROGRESS = 'In Progress';
    public static final String MILESTONE_STATUS_ESCALATED = 'Escalated';
    public static final String MILESTONE_STATUS_COMPLETE = 'Complete';
    public static final String MILESTONE_STATUS_DEAD = 'Dead';
    public static Set<String> MILESTONE_STATUS_TO_NOT_PROCESS_FOR_UPDATE_DELIVER_TABLET = new Set<String>{MILESTONE_STATUS_COMPLETE, MILESTONE_STATUS_DEAD};
    public static final String MILESTONE_EVENT_OPERATION_UPDATE_DELIVER_TABLET = 'Update Deliver Tablet';
    public static final String MILESTONE_STATUS_REASON_RETURN_TO_SENDER = 'Returned to Sender';
    public static final String MILESTONE_STATUS_REASON_NO_RESPONSE = 'No Response';
    public static final String MILESTONE_STATUS_REASON_TABLET_CASE_REJECTED = 'Tablet Case Rejected';
    public static final String MILESTONE_STATUS_REASON_DETAILS_FOR_NO_RESPONSE = 'Outreach Exhausted/Request Cancelled';
    public static final String OPPORTUNITY_TYPE_CHANGE_OF_OWNERSHIP = 'Change of Ownership';
    public static final Set<String> CASE_CLOSED_NOT_ELIGIBLE_RECORDTYPES = new Set<String>{RECORD_TYPE_ID_CASE_MARKETPLACE_ONBOARDING,
                                                                                           CASE_RECORD_TYPE_ID_TABLET_REQUESTS,
                                                                                           RECORD_TYPE_ID_CASE_POS_INTEGRATIONS
                                                                                          };

    // Mx Order related constants
    public final static String TYPE_OF_MX_ORDER_NEW = 'New';
    public final static String TYPE_OF_MX_ORDER_RETURN = 'Return';
    public final static String TYPE_OF_MX_ORDER_Replacement = 'Replacement';

    public final static String CASE_FIELD_API_NAME_STATUS = 'Status';
    public final static String CASE_FIELD_API_NAME_STAGE = 'Stage__c';
    public final static String CASE_STATUS_APPROVED = 'Approved';
    public final static String CASE_STATUS_SHIPPED = 'Shipped';
    public final static String CASE_STATUS_RECEIVED = 'Received';
    public final static String CASE_STATUS_IN_PROGRESS = 'In Progress';
    public final static String CASE_STATUS_BLOCKED = 'Blocked';
    public final static String CASE_STATUS_ESCALATED = 'Escalated';
    public final static String CASE_STATUS_RE_OPENED= 'Reopened';
    public static final Set<String> OB_CASE_OPEN_STATUS = new Set<String>{
        CASE_STATUS_OPEN,
        CASE_STATUS_IN_PROGRESS,
        CASE_STATUS_ESCALATED,
        CASE_STATUS_BLOCKED,
        CASE_STATUS_RE_OPENED
    };
    public static final String SOBJECT_TYPE_MX_ORDER = 'Mx_Order__c';
    public final static String SOBJECT_TYPE_MX_ORDER_ITEM = 'Mx_Order_Item__c';
    public static final String MX_PRODUCT_FAMILY_TABLET = 'Tablet';
    public static final String MX_PRODUCT_FAMILY_PRINTER = 'Printer';
    public static final String MX_PRODUCT_LANGUAGE_DEFAULT = 'English';
    public static final Id MILESTONE_RECORD_TYPE_ID_REVIEW_AND_TRIAGE = MILESTONE_RECORD_TYPE_INFO_BY_DEV_NAME.get('Review_Triage').getRecordTypeId();
    public static final Id MILESTONE_RECORD_TYPE_ID_SETUP_STORE = MILESTONE_RECORD_TYPE_INFO_BY_DEV_NAME.get('Setup_Store').getRecordTypeId();
    public static final Id MILESTONE_RECORD_TYPE_ID_SETUP_BANKING = MILESTONE_RECORD_TYPE_INFO_BY_DEV_NAME.get('Setup_Banking').getRecordTypeId();
    public static final Id MILESTONE_RECORD_TYPE_ID_ACTIVATE_STORE = MILESTONE_RECORD_TYPE_INFO_BY_DEV_NAME.get('Activate_Store').getRecordTypeId();
    public static final Id MILESTONE_RECORD_TYPE_ID_ACTIVATIONS_CHECKLIST = MILESTONE_RECORD_TYPE_INFO_BY_DEV_NAME.get('Activations_Checklist').getRecordTypeId();
    public static final Id MILESTONE_RECORD_TYPE_ID_SETUP_MENU = MILESTONE_RECORD_TYPE_INFO_BY_DEV_NAME.get('Setup_Menu').getRecordTypeId();
    public static final Id MILESTONE_RECORD_TYPE_ID_GENERAL_POS = MILESTONE_RECORD_TYPE_INFO_BY_DEV_NAME.get('General_POS').getRecordTypeId();
    public static final Id MILESTONE_RECORD_TYPE_ID_SETUP_POS_INTEGRATION = MILESTONE_RECORD_TYPE_INFO_BY_DEV_NAME.get('Setup_POS_Integration').getRecordTypeId();
    public static final Set<Id> MX_ONBOARDING_APPLICABLE_MILESTONE_RECORD_TYPE_IDS = new Set<Id>{ MILESTONE_RECORD_TYPE_ID_SETUP_STORE, MILESTONE_RECORD_TYPE_ID_SETUP_BANKING,
                                                                                                  MILESTONE_RECORD_TYPE_ID_ACTIVATE_STORE, MILESTONE_RECORD_TYPE_ID_ACTIVATIONS_CHECKLIST,
                                                                                                  MILESTONE_RECORD_TYPE_ID_SETUP_MENU, MILESTONE_RECORD_TYPE_ID_GENERAL_POS, MILESTONE_RECORD_TYPE_ID_DELIVER_TABLET,
                                                                                                  MILESTONE_RECORD_TYPE_ID_SETUP_POS_INTEGRATION};
    public static final Set<Id> MX_ORDER_APPLICABLE_MILESTONE_RECORD_TYPE_IDS = new Set<Id>{ MILESTONE_RECORD_TYPE_ID_REVIEW_AND_TRIAGE, MILESTONE_RECORD_TYPE_ID_SETUP_STORE };
    public static final Set<String> MX_ORDER_MILESTONE_CASE_STATUS_EXCLUSION = new Set<String>{'Closed', 'Dead'};
    public final static String MX_ORDER_FIELD_API_NAME_STATUS = 'Order_Status__c';
    public static final String MX_ORDER_STATUS_INVALID = 'invalid';
    public static final String MX_ORDER_STATUS_QUEUED = 'queued';
    public static final String MX_ORDER_STATUS_NEW = 'new';
    public static final String MX_ORDER_STATUS_OPEN = 'open';
    public static final String MX_ORDER_STATUS_BLOCKED = 'blocked';
    public static String MX_ORDER_STATUS_LABELED = 'labeled';
    public static String MX_ORDER_STATUS_RETURN_LABEL_SENT = 'return label sent';
    public static String MX_ORDER_STATUS_SHIPPED = 'shipped';
    public static String MX_ORDER_STATUS_DELIVERED = 'delivered';
    public static final Set<String> MILESTONE_APPLICABLE_CASE_REQUEST_TYPES = new Set<String>{ 'Ship to Merchant (New Tablet)', 'Ship to Merchant (New Tablet, Printer)' };
    public static final String MX_ORDER_MILESTONE_BLOCKED_ERROR_MESSAGE = 'Milestone \'Review & Triage\' or \'Setup Store\' is blocked for the Account';
    public static final String MX_ORDER_MILESTONE_COMPLETE_ERROR_MESSAGE = 'Milestone \'Review & Triage\' and \'Setup Store\' must be completed';
    public static final String MX_ORDER_FUTURE_PDOT_DATE_ERROR_MESSAGE = 'PDOT Date on the related Opportunity is in the future';
    public static final String MX_VENDOR_DENALI = 'Denali';
    public static final String MX_VENDOR_SOCIAL_MOBILE = 'Social Mobile';
    public static final String MX_SHIPPING_METHOD_STANDARD = 'Standard';
    public static final String MX_SHIPPING_METHOD_EXPEDITED = 'Expedited';
    public enum MX_SHIPPING_CARRIER { DHLEXPRESS, FEDEX, SAGAWA_EXPRESS, STARTRACK, UPS, USPS }
    public static final String MX_SHIPPING_CARRIER_DHL_EXPRESS = 'DHLExpress';
    public static final String MX_SHIPPING_CARRIER_FEDEX = 'FedEx';
    public static final String MX_SHIPPING_CARRIER_SAGAWA_EXPRESS = 'Sagawa Express';
    public static final String MX_SHIPPING_CARRIER_STARTRACK = 'StarTrack';
    public static final String MX_SHIPPING_CARRIER_UPS = 'UPS';
    public static final String MX_SHIPPING_CARRIER_USPS = 'USPS';
    public static final String OPPORTUNITY_DOORDASH = 'Door Dash';
    public static final String OPPORTUNITY_DOORDASH_OWNS = 'DoorDash Owns';
    public static final String OPPORTUNITY_LIVE_REGION = 'Live Region';
    public static final String OPPORTUNITY_PLATFORM_CAVIER = 'Caviar';
    public static final String OPPORTUNITY_PLATFORM_DOORDASH = 'DoorDash';
    public static final String OPPORTUNITY_PLATFORM_CAVIAR_AND_DOORDASH  = 'Caviar and DoorDash';
    public static Set<String>  OPPORTUNITY_PLATFORMS_CONTAINS_CAVIAR = new Set<String>{ OPPORTUNITY_PLATFORM_CAVIER, OPPORTUNITY_PLATFORM_CAVIAR_AND_DOORDASH};
    public static final String OPPORTUNITY_POS = 'POS';
    public static final String OPPORTUNITY_CAVIAR_POS_OWNS = 'POS (Caviar Owns)';
    public static final String PRODUCT_TYPE_FAMILY_MARKETING_KIT = 'Marketing Kit';
    public static Set<String> DECK_RANKS_TO_EXCLUDE_FOR_SMB = new Set<String>{ DECK_RANK_ACE_OF_SPADES, DECK_RANK_KING_OF_SPADES};
    public static List<String> ADS_PROMOS_PRODUCTS_DD_CUSTOM_IDS_TO_EXCLUDE = System.Label.Mx_Ads_Promos_Products_DD_Custom_IDs_to_Exclude.split(',');

    public static final List<String> CASE_REQUEST_TYPES_SEGMENT_NOTIFICATIONS = new List<String>{
        'Ship to Merchant (New Tablet)',
        'Ship to Merchant (New Tablet, Printer)',
        'Ship to Merchant (Dunkin\' Kit)',
        'Ship to Merchant (New Tablet, Printer, Return Label)',
        'Ship to Merchant (Replacement All Components)',
        'Protocol Upgrade'
    };

    public static final Map<String, MX_SHIPPING_CARRIER> MX_SHIPPING_CARRIER_STRING_TO_ENUM = new Map<String, MX_SHIPPING_CARRIER>{
        MX_SHIPPING_CARRIER_DHL_EXPRESS => MX_SHIPPING_CARRIER.DHLEXPRESS,
        MX_SHIPPING_CARRIER_FEDEX => MX_SHIPPING_CARRIER.FEDEX,
        MX_SHIPPING_CARRIER_SAGAWA_EXPRESS => MX_SHIPPING_CARRIER.SAGAWA_EXPRESS,
        MX_SHIPPING_CARRIER_STARTRACK => MX_SHIPPING_CARRIER.STARTRACK,
        MX_SHIPPING_CARRIER_UPS => MX_SHIPPING_CARRIER.UPS,
        MX_SHIPPING_CARRIER_USPS => MX_SHIPPING_CARRIER.USPS
    };
    public static final Map<String, String> MX_SHIPPING_CARRIER_MAPPING_VALUES = new Map<String, String>{
        'dhl' => MX_SHIPPING_CARRIER_DHL_EXPRESS,
        'fedex' => MX_SHIPPING_CARRIER_FEDEX,
        'sagawa' => MX_SHIPPING_CARRIER_SAGAWA_EXPRESS,
        'startrack' => MX_SHIPPING_CARRIER_STARTRACK,
        'ups' => MX_SHIPPING_CARRIER_UPS,
        'usps' => MX_SHIPPING_CARRIER_USPS
    };
    public static final Set<String> REQUEST_TYPES_THAT_INCLUDE_TABLET = new Set<String>{
        'Ship to Merchant (New Tablet)',
        'Protocol Upgrade',
        'Ship to Merchant (Replacement All Components)',
        'Ship to Merchant (New Tablet, Printer)',
        'Ship to Merchant (New Tablet, Printer, Return Label)',
        'Ship to Merchant (McDonald\'s Kit)',
        'Ship to Merchant (Replacement McDonalds Kit + Return Label)'
    };
    public static final Set<String> CASE_REQUEST_TYPES_FOR_INCLUSION_OF_PRINTER = new Set<String>{
        'Ship to Merchant (New Tablet, Printer)',
        'Ship to Merchant (New Tablet, Printer, Return Label)',
        'Ship to Merchant (Replacement Charger for Star Micronics Printer 143)',
        'Ship to Merchant (Replacement Charger for Star Micronics Printer 654)',
        'Ship to Merchant (Printer Only + Return Label)',
        'Ship to Merchant (Replacement Printer + Return Label)'
    };
    public static final Set<String> REQUEST_TYPES_CI_MAINTENANCE = new Set<String>{
        'Email to Merchant (Return Label Only)'
    };
    public static final String POS_INTEGRATION_REQUESTS_STATUS_PENDING = 'Pending';
    public static final String POS_INTEGRATION_REQUESTS_STATUS_FAILED = 'Failed';
    public static final String POS_INTEGRATION_REQUESTS_STATUS_PROCESSED = 'Processed';
    public static final String POS_INTEGRATION_REQUESTS_ORG_FIGMENT= 'Figment';
    public static final String PRODUCT_FAMILY_MARKETPLACE = 'Marketplace';
    public static final List<String> PRODUCT_FAMILIES_ADS_PROMOS = new List<String>{'Marketplace Promotion','Advertisement'};

    public static final String MILESTONE_AD_PROMS_VALIDATION_MESSAGE = 'Activate Store or Activations Checklist should be completed before working on Ads & Promos';
    public static Map<String, Boolean> MX_DISABLED_SETTING;

    public static List<String> PRINTER_ELIGIBLE_ACCOUNT_DECK_RANKS = new List<String>{'Ace', 'King', 'Ace of Spades', 'King of Spades'};
    public static String PARTNER_INTEG_MENU_ONLY_INTEGRATION = 'Menu Only Integration';
    public static Set<String> PRINTER_BYPASS_PROFILES = new Set<String>{'Empty Profile', 'Integration User', 'Integration User (API Only)', 'Integration User (API Only) NEW'};
    public static Set<String> PRINTER_BYPASS_PERMISSIONSETS = new Set<String>{'Bypass_Printer_Block'};

    public static final Set<String> STORE_ORDER_PROTOCOL = new Set<String>{'IPAD'};
    public static final Set<String> ACCOUNT_FIELD_API_NAMES_FOR_ORDER_EVENTS = new Set<String>{'iPad_Username__c','iPad_Password__c'};
    public static final Set<String> NEW_MERCHANT_REQUEST_TYPES = new Set<String>{ 'Ship to Merchant (New Tablet)', 'Ship to Merchant (New Tablet, Printer)' };
    public static final String RETURN_REQUEST_TYPE = 'Email to Merchant (Return Label Only)';
    static {
        MXSX_EVENTS = new Map<String, MXSX_EVENT>();
        MX_DISABLED_SETTING = new Map<String, Boolean>();
        for (MXSX_EVENT enumValue : MXSX_EVENT.values()){
            MXSX_EVENTS.put(String.valueOf(enumValue).toUpperCase(), enumValue);
        }
        for (Group g : [SELECT Id, Name, DeveloperName FROM Group WHERE Type = 'QUEUE' AND DeveloperName IN :MX_SERVICES_QUEUE_DEVELOPER_NAMES]){
            switch on (g.DeveloperName) {
                when 'Post_Sale_Activations' {
                    QUEUE_ID_STOREFRONT_POST_SALE_ACTIVATIONS = g.Id;
                }
                when 'Storefront_Case_Holding_Queue' {
                    QUEUE_ID_STOREFRONT_CASE_HOLDING_QUEUE = g.Id;
                }
                when 'Storefront_Implementation_Call_MOS' {
                    QUEUE_ID_STOREFRONT_IMPLEMENTATION_CALL_MOS = g.Id;
                }
                when 'Storefront_Link_Implementation_MxS' {
                    QUEUE_ID_STOREFRONT_LINK_IMPLEMENTATION_MXS = g.Id;
                }
                when 'Storefront_Under_Review_MxS' {
                    QUEUE_ID_STOREFRONT_UNDER_REVIEW_MXS = g.Id;
                }
                when 'POS_Integration_Requests' {
                    QUEUE_ID_POS_INTEGRATION_REQUESTS = g.Id;
                }
                when 'Onboarding_Ads_Promos' {
                    QUEUE_ID_ONBOARDING_ADS_PROMO = g.Id;
                }
            }
        }
        Set<String> USER_NAMES = new Set<String>();
        USER_NAMES.addAll(SELF_SERVE_USER_NAMES);
        USER_NAMES.add(MULESOFT_INTEGRATION_USER_NAME);
        USER_NAMES.add(FORMSTACK_INTEGRATION_USER_NAME);
        USER_NAMES.add(NINTEX_INTEGRATION_USER_NAME);
        SELF_SERVE_USER_IDS = new Set<Id>();
        for (User u : [SELECT Id, Name FROM User WHERE Name IN :USER_NAMES]){
            if (SELF_SERVE_USER_NAMES.contains(u.Name)) {
                SELF_SERVE_USER_IDS.add(u.Id);
            }else if(String.isBlank(MULESOFT_INTEGRATION_USER_ID) && MULESOFT_INTEGRATION_USER_NAME.equalsIgnoreCase(u.Name)){
                MULESOFT_INTEGRATION_USER_ID = u.Id;
            }else if(String.isBlank(FORMSTACK_INTEGRATION_USER_ID) && FORMSTACK_INTEGRATION_USER_NAME.equalsIgnoreCase(u.Name)){
                FORMSTACK_INTEGRATION_USER_ID = u.Id;
            }else if(String.isBlank(NINTEX_INTEGRATION_USER_ID) && NINTEX_INTEGRATION_USER_NAME.equalsIgnoreCase(u.Name)){
                NINTEX_INTEGRATION_USER_ID = u.Id;
            }
        }
        for (BusinessHours bh : [SELECT Id,Name,IsDefault FROM BusinessHours WHERE IsDefault = true OR Name = 'Inbound Weekdays (Extended)']){
            if(bh.IsDefault){
                BUSINESS_HOURS_DEFAULT = bh;
            }else if(bh.Name == 'Inbound Weekdays (Extended)'){
                BUSINESS_HOURS_WEEKDAYS = bh;
            }
        }
        ENABLE_MXSX_FRAMEWORK = (Test.isRunningTest() || (CDdExperimentSvc.getFeatureFlag('Enable_MxSx_Framework__c') == null ? false : CDdExperimentSvc.getFeatureFlag('Enable_MxSx_Framework__c')));
        ENABLE_MXSX_DECISIONMAKER_VALIDATION = (Test.isRunningTest() || (CDdExperimentSvc.getFeatureFlag('Enable_MxSx_Decision_Maker_Validation__c') == null ? false : CDdExperimentSvc.getFeatureFlag('Enable_MxSx_Decision_Maker_Validation__c')));
        OPPORTUNITY_CLOSE_DATE_CUTOVER = (Test.isRunningTest() ? System.today() : CDdMxSxConfigHelper.OPPORTUNITY_CLOSE_DATE_CUTOVER);
        MXSX_PLATFORM_EVENT_RETRY_LIMIT = CDdMxSxConfigHelper.PLATFORM_EVENT_RETRY_LIMIT;
        GENERATE_MX_ORDER = (Test.isRunningTest() ? TRUE : CDdMxSxConfigHelper.GENERATE_MX_ORDER);
        ENABLE_MX_ORDER_ROUTING = (Test.isRunningTest() ? TRUE : CDdMxSxConfigHelper.ENABLE_MX_ORDER_ROUTING);
        ENABLE_MX_ONBOARDING_PLATFORMEVENT_UPDATE = CDdMxSxConfigHelper.ENABLE_MX_ONBOARDING_PLATFORMEVENT_UPDATE;
        MX_ORDER_OPEN_CASE_STATUS_TO_EXCLUDE = CDdMxSxConfigHelper.MX_ORDER_OPEN_CASE_STATUS_TO_EXCLUDE;
        MX_ORDER_SHIPPING_STATE_VALIDATION_COUNTRY_CODES_TO_EXCLUDE = CDdMxSxConfigHelper.MX_ORDER_STATE_VALID_COUNTRY_EXCLUSION;
        MX_ORDER_SUBMISSION_MIN_ELAPSED_MINUTES = (Test.isRunningTest() ? 0 :CDdMxSxConfigHelper.MX_ORDER_SUBMISSION_MIN_ELAPSED_MINUTES);
        MX_DISABLED_SETTING = CDdMxSxConfigHelper.MX_DISABLED_SETTING;
    }
    public static MXSX_OPPORTUNITY_PLATFORM getMxSxOpportunityPlatform(String platform){
        return (String.isNotBlank(platform) && MXSX_OPPORTUNITY_PLATFORM_STRING_ENUM_MAP.containsKey(platform)) ? MXSX_OPPORTUNITY_PLATFORM_STRING_ENUM_MAP.get(platform) : null;
    }
    public static Integer getMaxRowsToProcess() {
        return Math.min(Limits.getLimitQueryRows() - Limits.getQueryRows(), DEFAULT_QUERY_LIMIT);
    }
        public static Map<String, Map<String, String>> getCaseOriginToRequestMap() {
        return CDdMxSxConfigHelper.Mx_CASE_ORIGIN_REQUEST_TYPE_MAP;
    }
    public static String getEquipmentRequestAccountRecordType() {
        return CDdMxSxConfigHelper.MX_EQUIPMENTREQUEST_ACCOUNTRECORDTYPES;
    }
    public static String getEquipmentRequestOrderProtocol() {
        return CDdMxSxConfigHelper.MX_EQUIPMENTREQUEST_ORDERPROTOCOL;
    }
    public static String getEquipmentRequestProtocolUpgradeMap() {
        return CDdMxSxConfigHelper.MX_EQUIPMENTREQUEST_PROTOCOL_UPGRADE_MAP;
    }
    public static String getEquipmentRequestReturnProductMap() {
        return CDdMxSxConfigHelper.MX_EQUIPMENTREQUEST_RETURNPRODUCT_MAP;
    }
    public static Map<String, Map<String, String>> getMxReturnRoutingConfig() {
        return CDdMxSxConfigHelper.Mx_ROUTING_RETURN_CONFIG;
    }
    public static Boolean isSandBox(){
       return [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
    }
    public static Integer getRandomInteger() {
        Integer randomInteger = Crypto.getRandomInteger();
        return randomInteger < 0 ? (randomInteger * -1) : randomInteger;
    }
    public static Boolean isDisabled(String settingName) {
        return MX_DISABLED_SETTING == null || test.isRunningTest() || !MX_DISABLED_SETTING.containsKey(settingName)? false:MX_DISABLED_SETTING.get(settingName);
    }
    /**
     * @description Custom method that adds the weekend days (wherever applicable) on top of the input Business Days to arrive at output
     * For accurate results, the Business Days to add should not exceed 7 days.
     * If you do go beyond 7 days, then the weekend days would only be included once (wherever applicable). It is currently a limitation.
     * DO NOT send a negative integer value for days. This operation currently does not support negative integer values as input
     * @param Date input date relative to which the Business Days is calculated for
     * @param Integer business days to add to arrive at the appropriate Business Date
     * @return Return the Date with additional Business Days (inclusive of weekend days wherever applicable)
     */
    public static Date addBusinessDays(Date dt, Integer days){
        switch on Datetime.newInstance(dt.year(), dt.month(), dt.day(), 0, 0, 0).format('E') {
            when 'Mon' {
                return (days > 4
                    ? BusinessHours.nextStartDate(CDdMxSxConstants.BUSINESS_HOURS_WEEKDAYS.Id, dt.addDays(days + 2)).date()
                    : BusinessHours.nextStartDate(CDdMxSxConstants.BUSINESS_HOURS_WEEKDAYS.Id, dt.addDays(days)).date()
                );
            }
            when 'Tue' {
                return (days > 3
                    ? BusinessHours.nextStartDate(CDdMxSxConstants.BUSINESS_HOURS_WEEKDAYS.Id, dt.addDays(days + 2)).date()
                    : BusinessHours.nextStartDate(CDdMxSxConstants.BUSINESS_HOURS_WEEKDAYS.Id, dt.addDays(days)).date()
                );
            }
            when 'Wed' {
                return (days > 2
                    ? BusinessHours.nextStartDate(CDdMxSxConstants.BUSINESS_HOURS_WEEKDAYS.Id, dt.addDays(days + 2)).date()
                    : BusinessHours.nextStartDate(CDdMxSxConstants.BUSINESS_HOURS_WEEKDAYS.Id, dt.addDays(days)).date()
                );
            }
            when 'Thu' {
                return (days > 1
                    ? BusinessHours.nextStartDate(CDdMxSxConstants.BUSINESS_HOURS_WEEKDAYS.Id, dt.addDays(days + 2)).date()
                    : BusinessHours.nextStartDate(CDdMxSxConstants.BUSINESS_HOURS_WEEKDAYS.Id, dt.addDays(days)).date()
                );
            }
            when 'Fri' {
                return (days > 0
                    ? BusinessHours.nextStartDate(CDdMxSxConstants.BUSINESS_HOURS_WEEKDAYS.Id, dt.addDays(days + 2)).date()
                    : BusinessHours.nextStartDate(CDdMxSxConstants.BUSINESS_HOURS_WEEKDAYS.Id, dt.addDays(days)).date()
                );
            }
            when 'Sat' {
                return BusinessHours.nextStartDate(CDdMxSxConstants.BUSINESS_HOURS_WEEKDAYS.Id, dt.addDays(days + 1)).date();
            }
            when 'Sun' {
                return BusinessHours.nextStartDate(CDdMxSxConstants.BUSINESS_HOURS_WEEKDAYS.Id, dt.addDays(days)).date();
            }
            when else {
                return null;
            }
        }
    }

    //BASD-35044
    public static List<String> REQUEST_TYPE_FITER_VALUES_UPDATE_DELIVER_TABLET = new List<String>{
        'Ship to Merchant (New Tablet)',
        'Ship to Merchant (New Tablet, Printer)'};

    //BASD-52032 Case Onboarding Ads and Promo Status
	public static final String ADS_AND_PROMO_STATUS_INCOMPLETE = 'Incomplete';
}