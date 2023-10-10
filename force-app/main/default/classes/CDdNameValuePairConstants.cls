/**
 * @author:         Raju Lakshman
 * @date:           March 2022
 * @description     Contains the 'name' of the name-value pair of the CDdNameValuePairHelper.
 *
 *  This will be the DeveloperName of the record in Soft_Coded_Name_Value_Pair__mdt.
 */
public without sharing class CDdNameValuePairConstants {
    public static final String CASE_TRIGGER_VALIDATE_DASHER_ESCALATION_QUEUE = 'Case_Validate_Dasher_Escalation_Queue';
    public static final String CASE_TRIGGER_VALIDATE_DASHER_ESCALATION_QUEUE_ERROR_MSG = 'Case_Validate_Dasher_Esc_Queue_Msg';
    public static final String CASE_TRIGGER_VALIDATE_INRESCUE_STATUS_ERROR_MSG = 'Case_Validate_In_Rescue_Status_Msg';
    public static final String MISSION_CONTROL_RECURSION_LIMIT = 'Mission_Control_Recursion_Limit';
    public static final String DASHER_DELIVERY_STATUS_0 = 'Dasher_Status_0';
    public static final String DASHER_DELIVERY_STATUS = 'Dasher_Status_';
    public static final String MERCHANT_CUSTOMER_TYPE_VALUE_1 = 'Customer_Type_Value_1';
    public static final String CONSUMER_CUSTOMER_TYPE_VALUE_2 = 'Customer_Type_Value_2';
    public static final String DASHER_CUSTOMER_TYPE_VALUE_3 = 'Customer_Type_Value_3';

    /* MXP Bulk load Requests - BIZS-1093 */
    public static final String MXP_LOAD_REPORT_URL = 'MXP_Load_Report_URL';
    public static final String ERROR_PBATCH_UNFINISHED = 'MXP_Previous_Batch_not_finished';
    public static final String ERROR_ACC_DOESNT_EXIST = 'MXP_Load_Account_doesnt_exist';
    public static final String ERROR_USER_DOESNT_EXIST = 'MXP_User_Doesnt_exist';

    //Case Bulk Load App
    public static final String CASE_UPDATE_REPORT_URL = 'Case_Update_Report_URL';

    //BIZS-917
    public static final String INTERNAL_ALERT_REFRESH_INTERVAL = 'Internal_Alert_Refresh_Interval';

    // BIZS-1478 Case Validations on "Pending Reason"
    public static final String CASE_VR_PENDING_SOLVE_MISSING_PERM = 'CASE_VR_PENDING_SOLVE_MISSING_PERM';
    public static final String CASE_VR_PENDING_SOLVE_WRONG_STATUS = 'CASE_VR_PENDING_SOLVE_WRONG_STATUS';
    public static final String CASE_VR_PENDING_POS_WRONG_FIELD = 'CASE_VR_PENDING_POS_WRONG_FIELD';
    public static final String CASE_VR_PENDING_POS_MISSING_FIELD = 'CASE_VR_PENDING_POS_MISSING_FIELD';

    //BIZS-1609
    public static final String UNRESOLVED_CONTACT = 'Unresolved_Contact';
    public static final String OPERATION_PHONE_CASE_UNRESOLVED = 'Op_Phone_Case_Unresolved';

    //Address Item Unavailable Use Case Merchant Ids part of POC BIZS-1886
    public static final String ITEM_UNAVAILABLE_POC_MERCHANTIDS = 'Item_Unavailable_POC_MerchantIds';
    public static final String ITEM_UNAVAILABLE_CASE_NOTES = 'Item_Unavailable_Case_Notes';
    public static final String ITEM_UNAVAILABLE_EXCLUDED_MERCHANTIDS = 'Item_Unavailable_Excluded_Merchants';

    // BIZS-1702
    public static final String MXP_BOB_UPDATE_TOOL_REPORT_LINK = 'MXP_BOB_UPDATE_TOOL_REPORT_LINK';
    public static final String MXP_BOB_UPDATE_PRE_APPROVE_ERROR = 'MXP_BOB_UPDATE_PRE_APPROVE_ERROR';
    public static final String MXP_BOB_UPDATE_NEW_MERCHANT_MXP_ERROR = 'MXP_BOB_UPDATE_NEW_MERCHANT_MXP_ERROR';
    public static final String MXP_BOB_UPDATE_TRANSFER_MXP_ERROR = 'MXP_BOB_UPDATE_TRANSFER_MXP_ERROR';
    //BZAP-17786
    public static final String OPPLINETRIGGER_FOPO_OR_OAS_PRODUCTS = 'OpportunityLine_fopoAndOrOAS_Products';
    public static final String OPPLINETRIGGER_FOPO_OR_OAS_PRICEBOOKS = 'OpportunityLine_fopoAndOrOAS_Pricebooks';

    //BASD-39057
    public static final String OPS_TEAM_MANAGER_PROFILE_ID = 'Operations_Team_Manager_Profile_Id';

    //BIZS-2057 getting profileid by profile name
    public static final String LIGHTNING_SUP_PROFILEIDS = 'Lightning_Support_ProfileIds';

    //BASD-43689
    public static final String AUTOMATED_PROCESS_USER_ID = 'Automated_Process_User_Id';
    //BIZS-2517 - DD User id for chargeback submission integration
    public static final String DD_USERID_FOR_CHARGEBACK_SUBMISSION = 'DD_USERID_FOR_CHARGEBACK_SUBMISSION';
    //BASD-5179
    public static final String PREVENT_DISPATCH_UPDATE_ISSUE_TYPE = 'Prevent_Dispatch_Update_Issue_Type';

}