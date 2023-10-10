/********************************************************************************************************************
* @author Sriram
* @date 12/06/2021
*
* @group Merchant Services
*
* @description This class will read the configured data as found in Merchant Services Configuration (custom metadata - MxSx_Config__mdt)
*               and provide the corresponding configuration setup values to the caller of this class
*
*               In order to optimize serving the configuration information to the caller, a one-time read is performed on the
*               custom metadata - MxSx_Config__mdt record, and the values are populated to static variables in this helper class.
*               Note: These values expect to go unchanged within the caller's execution/transaction, once read from this helper class
*
**************************************************************************************************************************************/
public class CDdMxSxConfigHelper {
    public static Date OPPORTUNITY_CLOSE_DATE_CUTOVER;
    public static Integer PLATFORM_EVENT_RETRY_LIMIT;
    public static Boolean GENERATE_MX_ORDER;
    public static Boolean ENABLE_MX_ORDER_ROUTING;
    public static Boolean ENABLE_MX_ONBOARDING_PLATFORMEVENT_UPDATE;
    public static Set<String> MX_ORDER_OPEN_CASE_STATUS_TO_EXCLUDE;
    public static Set<String> MX_ORDER_STATE_VALID_COUNTRY_EXCLUSION;
    public static Integer MX_ORDER_SUBMISSION_MIN_ELAPSED_MINUTES;
    public static final String DEFAULT_DEVELOPER_NAME = 'Default';
    public static final String CASE_ORIGIN_LABEL_NAME = 'Equipment_Request_Case_Origin_Mapping';
    public static final String MX_EQUIPMENTREQUEST_ACCOUNTRECORDTYPES_DEVELOPERNAME = 'Mx_EquipmentRequest_AccountRecordTypes';
    public static final String MX_EQUIPMENTREQUEST_ORDERPROTOCOL_DEVELOPERNAME = 'Mx_EquipmentRequest_OrderProtocol';
    public static final String MX_EQUIPMENTREQUEST_PROTOCOL_UPGRADE_MAP_DEVELOPERNAME = 'Mx_EquipmentRequest_Protocol_Upgrade_Map';
    public static final String MX_EQUIPMENTREQUEST_RETURNPRODUCT_MAP_DEVELOPERNAME = 'Mx_EquipmentRequest_ReturnProduct_Map';
    public static final String MX_ROUTING_LABEL_NAME = 'Mx_Routing';
    public static Map<String, Map<String, String>> Mx_CASE_ORIGIN_REQUEST_TYPE_MAP;
    public static Map<String, Map<String, String>> Mx_ROUTING_RETURN_CONFIG;
    public static String MX_EQUIPMENTREQUEST_ACCOUNTRECORDTYPES;
    public static String MX_EQUIPMENTREQUEST_ORDERPROTOCOL;
    public static String MX_EQUIPMENTREQUEST_PROTOCOL_UPGRADE_MAP;
    public static String MX_EQUIPMENTREQUEST_RETURNPRODUCT_MAP;
    public static final String DISBLED_SETTING_NAME = 'Disabled';
    public static Map<String, Boolean> MX_DISABLED_SETTING;
    public static String MX_EVENT_COUNT_CONFIG = 'EventCountConfig';
    public static Map<String, Integer> MX_EVENT_COUNT_BY_EVENT_NAME;
    public static String INTEGRATION_REQUEST_SCHEDULER_FREQUENCY = 'Integration_Request_Schedule_Frequency';
    public static Integer INTEGRATION_REQUEST_SCHEDULER_FREQUENCY_MIN;
    static {
        OPPORTUNITY_CLOSE_DATE_CUTOVER = System.today();
        PLATFORM_EVENT_RETRY_LIMIT = 4;
        GENERATE_MX_ORDER = false;
        ENABLE_MX_ORDER_ROUTING = false;
        ENABLE_MX_ONBOARDING_PLATFORMEVENT_UPDATE = false;
        MX_ORDER_OPEN_CASE_STATUS_TO_EXCLUDE = new Set<String>();
        MX_ORDER_STATE_VALID_COUNTRY_EXCLUSION = new Set<String>();
        MX_ORDER_SUBMISSION_MIN_ELAPSED_MINUTES = 20;
        Mx_CASE_ORIGIN_REQUEST_TYPE_MAP = new Map<String, Map<String, String>>();
        Mx_ROUTING_RETURN_CONFIG = new Map<String, Map<String, String>>();
        MX_DISABLED_SETTING = new Map<String, Boolean>();
        MX_EVENT_COUNT_BY_EVENT_NAME = new Map<String, Integer>();
        for (MxSx_Config__mdt config : [SELECT Id, Opportunity_Close_Date_Cutover__c, Platform_Event_Retry_Limit__c,
                                        Generate_Mx_Order__c, Enable_Mx_Order_Routing__c, Mx_Order_Open_Case_Status_To_Exclude__c,
                                        Mx_Order_State_Valid_Country_Exclusion__c, Mx_Order_Submission_Min_Elapsed_Minutes__c,developerName,
                                        Label,Type_of_order__c,Country__c,Request_Type__c,Reusable_Text_Field__c,
                                        First_Equipment_Caseorigin__c,Follow_Up_Caseorigin__c,Disabled__c,Enable_MxOnboarding_PlatformEvent_Update__c,
                                        Do_Not_Process_Opp_Closed_X_Years_Ago__c, Event_count__c
                                        FROM MxSx_Config__mdt limit 1000]){
            if (config.developerName == DEFAULT_DEVELOPER_NAME) {
                OPPORTUNITY_CLOSE_DATE_CUTOVER = config.Opportunity_Close_Date_Cutover__c != null ? config.Opportunity_Close_Date_Cutover__c : OPPORTUNITY_CLOSE_DATE_CUTOVER;
                //Considering the latest cutover date from config to publish events on Opportunity closed won
                //Opportunity_Close_Date_Cutover__c, Do_Not_Process_Opp_Closed_X_Years_Ago__c (Date will be calculated using the years)
                if(config.Do_Not_Process_Opp_Closed_X_Years_Ago__c != null){
                    Date DO_NOT_PROCESS_OPP_CLOSED_X_YEARS_AGO = System.today().addYears(-Integer.valueOf(config.Do_Not_Process_Opp_Closed_X_Years_Ago__c));
                    if (DO_NOT_PROCESS_OPP_CLOSED_X_YEARS_AGO > OPPORTUNITY_CLOSE_DATE_CUTOVER) {
                        OPPORTUNITY_CLOSE_DATE_CUTOVER = DO_NOT_PROCESS_OPP_CLOSED_X_YEARS_AGO;
                    }
                }
                PLATFORM_EVENT_RETRY_LIMIT = config.Platform_Event_Retry_Limit__c != null ? config.Platform_Event_Retry_Limit__c.intValue() : PLATFORM_EVENT_RETRY_LIMIT;
                GENERATE_MX_ORDER = config.Generate_Mx_Order__c != null ? config.Generate_Mx_Order__c : GENERATE_MX_ORDER;
                ENABLE_MX_ORDER_ROUTING = config.Enable_Mx_Order_Routing__c != null ? config.Enable_Mx_Order_Routing__c : ENABLE_MX_ORDER_ROUTING;
                ENABLE_MX_ONBOARDING_PLATFORMEVENT_UPDATE = config.Enable_MxOnboarding_PlatformEvent_Update__c != null ? config.Enable_MxOnboarding_PlatformEvent_Update__c : ENABLE_MX_ONBOARDING_PLATFORMEVENT_UPDATE;
                MX_ORDER_OPEN_CASE_STATUS_TO_EXCLUDE = String.isNotBlank(config.Mx_Order_Open_Case_Status_To_Exclude__c)
                                                                ? new Set<String>(config.Mx_Order_Open_Case_Status_To_Exclude__c.split(';')) : new Set<String>();
                MX_ORDER_STATE_VALID_COUNTRY_EXCLUSION = String.isNotBlank(config.Mx_Order_State_Valid_Country_Exclusion__c)
                                                                ? new Set<String>(config.Mx_Order_State_Valid_Country_Exclusion__c.split(';')) : new Set<String>();
                MX_ORDER_SUBMISSION_MIN_ELAPSED_MINUTES = config.Mx_Order_Submission_Min_Elapsed_Minutes__c != null ? config.Mx_Order_Submission_Min_Elapsed_Minutes__c.intValue() : MX_ORDER_SUBMISSION_MIN_ELAPSED_MINUTES;
            }
            if (config.Label == CASE_ORIGIN_LABEL_NAME) {
            Map<String, String> CASE_ORIGIN_FIRST_AND_FOLLOW_MAP = new Map<String, String>{config.First_Equipment_Caseorigin__c => config.Follow_Up_Caseorigin__c};
            Mx_CASE_ORIGIN_REQUEST_TYPE_MAP.put(config.Request_Type__c,CASE_ORIGIN_FIRST_AND_FOLLOW_MAP);
            }
            if(config.Label == DISBLED_SETTING_NAME){
               MX_DISABLED_SETTING.put(config.developerName ,config.disabled__c);
            }
            if (config.developerName == MX_EQUIPMENTREQUEST_ACCOUNTRECORDTYPES_DEVELOPERNAME ) {
            MX_EQUIPMENTREQUEST_ACCOUNTRECORDTYPES = config.Reusable_Text_Field__c;
            }
            if (config.developerName == MX_EQUIPMENTREQUEST_ORDERPROTOCOL_DEVELOPERNAME) {
            MX_EQUIPMENTREQUEST_ORDERPROTOCOL = config.Reusable_Text_Field__c;
            }
            if (config.developerName == MX_EQUIPMENTREQUEST_PROTOCOL_UPGRADE_MAP_DEVELOPERNAME) {
            MX_EQUIPMENTREQUEST_PROTOCOL_UPGRADE_MAP = config.Reusable_Text_Field__c;
            }
            if (config.developerName == MX_EQUIPMENTREQUEST_RETURNPRODUCT_MAP_DEVELOPERNAME) {
            MX_EQUIPMENTREQUEST_RETURNPRODUCT_MAP = config.Reusable_Text_Field__c;
            }
            if (config.Label == MX_ROUTING_LABEL_NAME) {
            Map<String, String> Mx_Routing_Attributes = new Map<String, String>{'Vendor' => config.Reusable_Text_Field__c};
            Mx_ROUTING_RETURN_CONFIG.put(config.Country__c, Mx_Routing_Attributes);
            }
            if(config.Label == MX_EVENT_COUNT_CONFIG){
            MX_EVENT_COUNT_BY_EVENT_NAME.put(config.developerName, Integer.valueof(config.Event_count__c));
            }
            if(config.Label == INTEGRATION_REQUEST_SCHEDULER_FREQUENCY){
                INTEGRATION_REQUEST_SCHEDULER_FREQUENCY_MIN = Integer.valueof(config.Reusable_Text_Field__c);
            }
        }
    }
}