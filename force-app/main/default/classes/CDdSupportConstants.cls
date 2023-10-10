/**
 * @description       : Reusable Constants
 * @author            : Jeegar
 * @group             :
 * @last modified on  : 02-22-2023
 * @last modified by  : Jose Vega
**/
public with sharing class CDdSupportConstants {
    /***************************** GENERIC SUPPORT CONSTANTS *****************************/

    /* Record Types */
    public static final String RECORDTYPE_NAME_CUSTOMER = 'Customer'; //Label is Support, API name is Customer
    public static final String RECORDTYPE_LABEL_CUSTOMER = 'Support'; //Label is Support, API name is Customer
    public static final String RECORDTYPE_NAME_API = 'API';
    public static final String RECORDTYPE_NAME_SUPPORT = 'Support';
    public static final String RECORDTYPE_NAME_MARKETPLACE = 'Marketplace';
    public static final String RECORDTYPE_LABEL_PARENTACC = 'Parent_Account';
    public static final String RECORDTYPE_NAME_CAVIAR_ONBOADING = 'Caviar Onboarding';
    public static final String RECORDTYPE_NAME_CAVIRA_SUPPORT = 'Caviar Support';
    public static final String RECORDTYPE_NAME_CFC_CATERING= 'CFC Catering Onboarding';
    public static final String RECORDTYPE_NAME_ENT_COO_RESCUE= 'ENT COO Rescue';
    public static final String RECORDTYPE_NAME_DRIVE_API = 'Drive API Support';
    public static final String RECORDTYPE_NAME_MARKETPLACE_ONBOARDING = 'Marketplace Onboarding';
    public static final String RECORDTYPE_ONBOARDING_MGR_HANDOFF ='Onboarding Manager Handoff';
    public static final String RECORDTYPE_SUPPORT_TRAINING = 'Support Training';
    public static final String RECORDTYPE_NAME_ACCOUNT_MANAGEMENT = 'Account Management';
    public static final String RECORDTYPE_NAME_BULK_UPLOAD_REQUEST = 'Bulk Upload Request';
    public static final String RECORDTYPE_NAME_STOREFRONT_ONBOARDING = 'Storefront Onboarding';
    public static final String RECORDTYPE_NAME_PROACTIVE_OUTREACH = 'Proactive Outreach';
    public static final String RECORDTYPE_NAME_POS_INTEGRATIONS = 'POS_Integrations';
    public static final String RECORDTYPE_NAME_TABLET_REQUESTS = 'Tablet Requests';

    /* Case Status */
    public static final String REOPEN_STATUS = 'Reopened';
    public static final String OPEN_STATUS= 'Open';
    public static final String CLOSED_STATUS= 'Closed';
    public static final String NEW_STATUS = 'New';
    public static final String WAITING_DD_TEAM_STATUS = 'Waiting for DD Internal Team';
    public static final String PENDING_STATUS = 'Pending';
    public static final String SOLVED_STATUS= 'Solved';
    public static final String STATUS_REQUEST_DENIED ='Request Denied';
    public static final String STATUS_BLOCKED ='Blocked';
    public static final String RECEIVED_STATUS = 'Received';
    public static final String ACTIVATED_STATUS = 'Activated';
    public static final String RETURN_TO_SENDER_STATUS = 'Return to Sender';
    public static final String ESCALATED_STATUS = 'Escalated';
    public static final String APPROVED_STATUS = 'Approved';
    public static final String COMPLETED_STATUS = 'Completed';
    public static final String INRESCUE_STATUS = 'In Rescue';
    public static final String SHIPPED_STATUS = 'Shipped'; //BASD-39324 New Constant
    public static final String UNDER_REVIEW_STATUS = 'Under Review';
    public static final String IN_PROGRESS = 'In Progress';

    /* Priority */
    public static final String MEDIUM_PRIORITY = 'Medium';
    public static final String URGENT_PRIORITY = 'Urgent';

    /* Roles */
    public static final String ROLE_HQ_SUPERVISOR = 'HQ Supervisor';
    public static final String ROLE_HQ_SUPERVISOR_DEV_NAME = 'HQ_Supervisor';

    /* Role Keywords */
    public static final String ROLE_SUPERVISOR = 'Supervisor';
    public static final String ROLE_T3_SUPPORT = 'T3 Support';

    /* Profiles */
    public static final String SYSADMIN_PROFILE = 'System Administrator';
    public static final String PROFILE_SYS_ADM = 'System Administrator';
    public static final String SYSTEMADMIN_PROFILE_LABEL  = 'System Administrator';
    public static final String BIZAPPSTEAM_PROFILE_LABEL  = 'BizApps Team';
    public static final String BIZAPPSADMIN_PROFILE_LABEL  = 'BizApps Admin Profile';
    public static final String BIZAPPS_TEAM_PROFILE = 'BizApps Team';

    /* Sobjects / SObject Fields */
    public static final String CASE_OBJECT_LABEL = 'Case';
    public static final String GROUP_QUEUE = 'Queue';
    public static final String USER_OBJECT_LABEL  = 'User';
    public static final String PRESENCEUSERCONFIG_OBJECT_LABEL  = 'PresenceUserConfig';
    public static final String PRESENCEUSERCONFIGUSER_OBJECT_LABEL  = 'PresenceUserConfigUser';

    /* Generic API status */
    public static final String ERROR_LABEL  = 'Error';
    public static final String SUCCESS_LABEL  = 'Success';
    public static final String INSERT_LABEL  = 'Insert';
    public static final String DELETE_LABEL  = 'Delete';
    public static final String FAILURE_LABEL  = 'Failure';

    /* Formstack Constants */
    public static final String FORMSTACK_SUBCATEGORY_CHANGE_ORDER_PROTOCOL = 'Change Order Protocol';
    public static final String FORMSTACK_SUBCATEGORY_ERROR_CHARGE_DISPUTES = 'Missing / Incorrect Error Charge Disputes';
    public static final String FORMSTACK_SUBCATEGORY_ERROR_CHARGE_DISPUTES_2 = 'Error Charge Disputes';
    public static final String FORMSTACK_STORE_LOCATION_SINGLE_LOCATION = 'Single Location';

    /* Case Origin */
    public static final String ORIGIN_EMAIL_MXP = 'Email - MXP';
    public static final String ORIGIN_EMAIL_CLOSED_CASE_RESPONSE = 'Auto Created - Closed Case Response';
    public static final String CASE_ORIGIN_PHONE = 'Phone';
    public static final String CASE_ORIGIN_WEB = 'Web';
    public static final String CASE_ORIGIN_EMAIL = 'Email';

    /* Case Feed Types */
    public static final String CASEFEED_TYPE_TEXTPOST = 'TextPost';

    /* Case Issue */
    public static final String CASE_ISSUE_ATO_REPORTED = 'ATO Reported';
    public static final String CASE_ISSUE_ACCT_SETTINGS = 'Update Account Information';
    public static final String CASE_ISSUE_ACCT_MGMT = 'Account Management - CX';
    public static final String CASE_ISSUE_TYPE_ACCOUNT_MANAGEMENT = 'Account Management';
    public static final String CASE_ISSUE_TYPE_ACCOUNT_MANAGEMENT_CX = 'Account Management - CX';
    public static final String CASE_ISSUE_TYPE_ACCOUNT_MANAGEMENT_DX = 'Account Management - DX';
    public static final String CASE_ISSUE_TYPE_ACCOUNT_MANAGEMENT_MX = 'Account Management - MX';
    public static final String ISSUE_ONBOARDING = 'Onboarding Questions';
    public static final String ISSUE_LEGALQUERY = 'Legal Question/Concern';
    public static final String ISSUE_UPDATE_EMAIL = 'Update Email';
    public static final String ISSUE_UPDATE_PHONE = 'Update Phone';
    public static final String ISSUE_TYPE_PAY_MANAGEMENT_MX = 'Pay Management - MX';
    public static final String ISSUE_CHARGEBACK_DISPUTE = 'Chargeback Dispute';
    public static final String ISSUE_UNRESOLVED_CONTACT = 'Unresolved Contact: Dropped';
    public static final String ISSUETYPE_LIVE_ORDER_MX = 'Live Order - MX';
    public static final String ISSUE_ITEM_UNAVAILABLE = 'Item Unavailable';
    public static final String ISSUETYPE_LIVE_ORDER_CX = 'Live Order - CX';
    public static final String ISSUETYPE_DOORDASH_DRIVE_MX = 'DoorDash Drive - MX';
    public static final String ISSUETYPE_DOORDASH_DRIVE_CX = 'DoorDash Drive - CX';
    public static final string ISUETYPE_OTHER_CX = 'Other - CX';

    /* Case Resolution Type */
    public static final String RESOLUTION_TYPE_ACCOUNT_MANAGEMENT_MX = 'Account Management - MX';
    public static final string RESOLUTION_TYPE_OTHER_MX = 'Other - MX';
    public static final string RESOLUTION_TYPE_OTHER_CX = 'Other - CX';
    public static final string RESOLUTION_TYPE_OTHER_DX = 'Other - DX';
    public static final string RESOLUTION_TYPE_OTHER = 'Other';
    /* Case Resolution */
    public static final String RESOLUTION_DIRECTED_TO_MX_PORTAL_T3 = 'Directed to MX Portal [T3]';
    //Bulk Case Update App

    /***************************** TASK / PROJECT SPECIFIC SUPPORT CONSTANTS *****************************/

    public static final String SURVEY_PROVIDER_DELIGHTED = 'Delighted';
    public static final String SURVEY_PROVIDER_QUALTRICS = 'Qualtrics';
    public static final String SURVEY_TYPE_MENU_UPDATE = 'Menu Update';

    // Jeegar 03/2021 https://doordash.atlassian.net/browse/BZAPSUP-1730 for ATO fields to be bypassed

    public static final String CHAT_TRANS_ISSUE_PAYMENTS = 'Payments';
    public static final String CHAT_TRANS_ISSUE_ACCT_SETTINGS = 'Account Settings';
    public static final String CHAT_TRANS_ISSUE_SUBCAT_REPORT_UNAUTH_CHARGE = 'Report Unauthorized Charges';
    public static final String CHAT_TRANS_ISSUE_SUBCAT_REACTIVATE_DD_ACCT = 'Reactivate DoorDash Account';
    public static final String CHAT_TRANS_ISSUE_SUBCAT_FRAUD_ACCT_ACTIVITY = 'Fraudulent Account Activity';

    // Tia Xuan 02/22/2021 BZAPSUP-1405 Chat bot values for VIP routing
    public static final Set<Integer> CHATBOT_VIP_VALUES = new Set<Integer>{94, 96};
    public static final String DRS_DD_API_TOKEN = 'FynW4QtGECUAAAAAAAAAAJn306dIT0hMAAAAAAAAAACqVYBmGI9sSwAAAAAAAAAA';

    //BZAP-1095 Case Constants
    public static final String CASE_ESC_REASON_CUST_INT = 'Customer Initiated';
    public static final String CASE_ESC_REASON_SUP_OPS = 'Support Ops';
    public static final String TEST_QUEUE_LABEL = 'Test Queue';
    public static final String ROLE_CEBU_ESC_DEV_NAME = 'Cebu_Escalation';
    // Raja 07/29/2021 BIZS-273
    public static final String DOORDASH_DOMAIN= 'doordash.com';
    // Tia Xuan 04/07/2021 BZAPSUP-1411 QueueMonitor
    public static final String QUEUE_MONITOR_PREFIX = 'local.QueueManager.QM';
    // Origin Constants
    public static final String ORIGIN_CLOSED_WON_NEW_MX_KIT = 'Closed Won - New Mx Kit';
    public static final String ORIGIN_CLOSED_WON_OPPORTUNITY = 'Closed Won Opportunity';
    public static final String ORIGIN_CLOSED_WON_OPPORTUNITY_SSMO = 'Closed Won Opportunity - SSMO';
    public static final String ORIGIN_DRIVE = 'Drive';
    public static final String ORIGIN_INTERNAL = 'Internal';
    public static final String ORIGIN_MERCHANT_CATERING_PILOT = 'Merchant Catering Pilot';
    public static final String ORIGIN_NEW_TABLET_REQUEST = 'New Tablet Request';
    public static final String ORIGIN_PROTOCOL_CHANGE = 'Protocol Change';
    public static final String ORIGIN_SSMO_CW_TABLETCASE= 'New Tablet Request:SSMO';
    public static final String ORIGIN_DASHER_APPLY = 'Dasher Apply';
    public static final String ORIGIN_PHOTOSHOOT_REQUEST = 'Photoshoot Request';
    public static final String ORIGIN_PHOTOS_SENT = 'Photos Sent';
    public static final String ORIGIN_FORMSTACK = 'Formstack';


    //Sendbird Integration Constants
    public static final String LIVEAGENT_CHANNEL = 'Live Agent';
    public static final String DD_API_TOKEN = 'DD-API-Token';
    public static final String CREDENTIAL_PASSWORD = '{!$Credential.Password}';
    public static final String SUPPORT_GATEWAY = 'Support_Gateway';
    public static final String CASE_CHANNEL_CHAT_SENDBIRD = 'Doordash App - Sendbird';
    public static final String CASE_ORIGIN_CHAT = 'Chat';
    public static final String SENDBIRD_ERS_ENDPOINT_PATH = '/case_updates';

    //support gateway generic constants
    public static final String SUPPORT_GATEWAY_GENERIC_ENDPOINT = 'Support_Gateway_Generic_End_point';

    //Agent Specific Routing constants
    public static final String MXP_ROLE_NAME = 'MXP';
    public static final String MX_SUCCESS_ASSOCIATE = 'MxSx - Mx Success Associate';
    public static final String NAME_MXP_AGENT = 'Mxp Agent';
    public static final String NAME_TEST_USER = 'Test User';
    public static final String NAME_TEST_ACCOUNT = 'Test Account';
    public static final String QUEUE_MX_SUCCESSASSOCIATE = 'Mx Success Associate Queue';
    public static final String QUEUE_DEVNAME_MXP_FALLBACK = 'MxSx_Mx_Success_Associate';
    public static final String ISSUE_POS = 'Point of Sale';
    public static final String QUEUE_INBOUND_SALES_OMNI_QUEUE = 'Inbound Sales - Omni';
    public static final String QUEUE_BAD_LEAD_DATA = 'Bad Lead Data';


    /* Case Customer Types */
    public static final String CUSTOMER_TYPE_DASHER = 'Dasher';
    public static final String CUSTOMER_TYPE_MERCHANT = 'Merchant';
    public static final String CUSTOMER_TYPE_CONSUMER = 'Consumer';

    public static final Set<String> ALL_CUSTOMER_TYPES = new Set<String> {
        CUSTOMER_TYPE_CONSUMER,
        CUSTOMER_TYPE_DASHER,
        CUSTOMER_TYPE_MERCHANT
    };

    // Naren 07/22/2021 BIZS-168 User Nesting Constants
    public static final Integer MAX_MANUAL_LIMIT  = 1000;

    //vendor split on cases
    public static final String VIP_LABEL = 'VIP';

    // Tia Xuan 07/2021 BIZS-43 Repoint API for Dispatch callout
    public static final String POST_METHOD = 'POST';
    public static final String PUT_METHOD = 'PUT';
    public static final String CONTENT_TYPE = 'Content-Type';
    public static final String CONTENT_TYPE_JSON = 'application/json';
    public static final String CONTENT_TYPE_URL_ENCODED = 'application/x-www-form-urlencoded';
    public static final String DELIVERY_MAIN_BODY = '{"deliveryAudience":{"deliveryUuids":{0}}}';
    public static final String DELIVERY_UUIDS_REPLACEMENT_STRING = '{0}';
    public static final String AUTHORIZATION_BEARER = 'Bearer ';

    // MXP Manager controller Constants - Pranil 05 Aug 2021
    public static final String MXP_TEAM_MANAGER = 'MXP_Team_Manager';
    public static final String MXP_TEAM_MEMBER = 'MXP_Team_Member';
    public static final String OPERATION_MXP_MAPPING = 'MXP Mapping';

    //Nyaana Kapse 08/2021 BIZS-348 MXP-Eligible Web Escalated Cases Re-Routing to MXP Queue - Web ONLY
    public static final String MXP_ROUTING_OVERRIDE_VALUE = 'Mx Success Associate Queue';
    public static final String ACCOUNT_ISSUETYPE_ONBOARDING = 'Onboarding issues';

    //BIZS-751
    public static final Set<String> MXP_CASE_REPORT_DEFAULT_CASE_STATUS = new Set<String> {
        OPEN_STATUS,REOPEN_STATUS,PENDING_STATUS,WAITING_DD_TEAM_STATUS
    };

    //BIZS-519 Jeegar 11/2021
    // Constants for Country - Phone  mappings
    public static final String FORMATTED_INTERNATIONAL_NUMBER = 'formattedInternationalNumber';
    public static final String FORMATTED_NATIONAL_NUMBER = 'formattedNationalNumber';
    public static final String INTERNATIONAL_NUMBER = 'internationalNumber';
    public static final String NATIONAL_NUMBER = 'nationalNumber';
    public static final String DEFAULT_STRING = 'default';

    public static final String COUNTRY_NAME_GERMANY = 'Germany';
    public static final String COUNTRY_NAME_JAPAN = 'Japan';
    public static final String COUNTRY_NAME_USA = 'United States';
    public static final String COUNTRY_NAME_AUSTRALIA = 'Australia';

    public static final String COUNTRY_SHORT_NAME_GERMANY = 'DE';
    public static final String COUNTRY_SHORT_NAME_JAPAN = 'JP';
    public static final String COUNTRY_SHORT_NAME_USA = 'US';
    public static final String COUNTRY_SHORT_NAME_AUSTRALIA = 'AU';

    //BASD-16630
    public static final String TEST_EMAIL = 'test@test.com';

    public static final String CONTINUED = '...';

    //BASD-24576
    public static final String CLOSED_BY_MERGE = 'Closed by Merge';

    //BASD-22817
    public static final String T3_ESCALATION_TEXT = 'Your Requested Resolution Plan for San Francisco Team';
    //BASD-34107
    public static final String T3_ESCALATION_TEXT_2 = 'Expected resolution plan for the escalation team';

    //BIZS-1145
    public static final String AC_REGION_US_WEST_2 = 'us-west-2';
    public static final String AC_INSTANCE_ID = '11f66d9e-8199-4a63-9ab8-d9eeb7a08aa0';
    public static final String AC_API_URL = 'https://rx5wjnrkog.execute-api.us-west-2.amazonaws.com/chat/connect?task=${task_id}&user=${user_id}';
    public static final String AC_CONTACT_FLOW_ID = 'ebf8d4f3-91d9-4054-a49e-0755698a4c83';
    // Lead Platforms
    public static final String LEAD_PLATFORM_CAVIAR = 'Caviar';

    //Bulk Case Update App
    public static final String OPERATION_CASE_UPDATES = 'Bulk Case Updates';

    //BASD-27729
    public static final String CUSTOMER_SEGMENT_OFFENDER = 'Offender';

    //Mission Control Evaluation Criteria
    public static final String CREATED = 'Created';
    public static final String UPDATED = 'Updated';
    public static final String CREATED_UPDATED = 'Created and Updated';
    public static final String CREATED_UPDATED_SUBSEQUENTLY_MEET_CRITERIA = 'Created and Updated to Subsequently meet criteria';
    public static final String UPDATED_SUBSEQUENTLY_MEET_CRITERIA = 'Updated to Subsequently meet criteria';
    public static List<String> insertEvaluationCriteria = new List<String>{CDdSupportConstants.CREATED, CDdSupportConstants.CREATED_UPDATED, CDdSupportConstants.CREATED_UPDATED_SUBSEQUENTLY_MEET_CRITERIA};
    public static List<String> updateEvaluationCriteria = new List<String>{CDdSupportConstants.UPDATED, CDdSupportConstants.CREATED_UPDATED, CDdSupportConstants.CREATED_UPDATED_SUBSEQUENTLY_MEET_CRITERIA, CDdSupportConstants.UPDATED_SUBSEQUENTLY_MEET_CRITERIA};

    //BASD-26831
    public static final String BUSINESS_VERTICAL_RESTAURANT = 'Restaurant';

    //BIZS-1390
    public static final String STATUS_DRAFT = 'Draft';
    public static final String STATUS_PUBLISHED = 'Published';
    public static final String STATUS_ARCHIVED = 'Archived';

    public static final String CASE_PHOTOSHOOT_VENDOR_SNAPPR = 'Snappr';

    // BIZS-1478 Sid
    public static final String CASE_MXP_PENDING_REASON_SOLVE_WITH_DELAY = 'Solve with Delay';
    public static final String CASE_MXP_PENDING_REASON_SOLVE_WITH_DELAY_COMPLETED = 'DO NOT USE Solve with Delay (Completed)';
    public static final String CASE_MXP_PENDING_REASON_SOLVE_WITH_DELAY_EXITED = 'DO NOT USE Solve with Delay (Exited)';
    public static final String CASE_MXP_PENDING_REASON_WAITING_ON_POS_PROVIDER = 'Waiting on POS provider';
    public static final String CASE_STATUS_PENDING = 'Pending';
    public static final String CASE_ISSUE_TYPE_POINT_OF_SALE = 'Point of Sale';

    //BIZS-2857
    public static final string CASE_RESOLUTION_AUTOMATED_MERGE_DUPLICATE = 'Automated Merge - Duplicate';
    //BASD-39324
    public static final String CHANGE_STATUS_TO_TABLET_SHIPPED = 'Change Status to Tablet Shipped (FedEx)';


    // BASD-39769 Account Deck Rank Set
    public static final String JACK_RANK = 'Jack';
    public static final String JOKER_RANK = 'Joker';
    public static final String QUEEN_RANK = 'Queen';
    public static final String PENDING_RANK = 'Pending';

    public static final Set<String> CASE_ORIGINS_MARKETING_KIT_INCLUDED = new Set<String>{ 'New Tablet Request', 'New Tablet Request:SSMO' };

    //BIZS-2297 Project Horizon
    public static final String WF_ACTION_EMAIL_ALERT = 'Email Alert';
    public static final String WF_ACTION_FIELD_UPDATE = 'Field Update';
    public static final String WF_ACTION_TASK_CREATION = 'Task Creation';
    public static final String WF_ACTION_FEED_NOTE_CREATION = 'Feed Note Creation';

    //BASD-46840
    public static final String LIVE_ORDER_ISSUES_MDT_NAME = 'MANDATORY_DELIVERY_UUID';

    //BASD-46039 Case Deatils Requied field for Trust & Safety
    public static final String PRIMARY_INCIDENT_TYPE = 'Adt Contact';
    public static final String SECONDARY_INCIDENT_TYPE = 'Adt Silent Alert';
    public static final String REPORTER = 'Safety Feature';
    public static final String INCIDENT_HISTORY = 'No';
    public static final String ACTIONS_TAKEN = 'Wellness Check';
    public static final String ACCOUNT_SHARING_NOT_MY_DASHER = 'No';

    //Attribute Based Routing
    public static final String ATTRIBUTE_BASED_ROUTING =  'Attribute Based Routing';
    public static final String SKILL_BASED_ROUTING_TYPE = 'SkillsBased';
    ///BASD-46039 Trust & Safety Queue Names
	public static final String QUEUE_P0_SPANISH_TRUST_AND_SAFETY = 'P0 - Spanish - Trust & Safety';
    public static final String QUEUE_P0_TRUST_AND_SAFETY = 'P0 - Trust & Safety';
    public static final String QUEUE_P1_SPANISH_TRUST_AND_SAFETY = 'P1 - Spanish - Trust & Safety';
    public static final String QUEUE_P1_TRUST_AND_SAFETY = 'P1 - Trust & Safety';
    public static final String QUEUE_P2_SPANISH_TRUST_AND_SAFETY = 'P2 - Spanish - Trust & Safety';
    public static final String QUEUE_P2_TRUST_AND_SAFETY = 'P2 - Trust & Safety';
    public static final String QUEUE_M_ESCALATIONS = 'M-Escalations';
    public static final String QUEUE_M_ESCALATIONS_JAPAN = 'M-Escalations (Japan)';
}