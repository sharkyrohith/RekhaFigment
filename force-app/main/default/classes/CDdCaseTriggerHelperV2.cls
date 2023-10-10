/**
 * @author: Raju Lakshman
 * @date: Dec 2021
 * @description Optimized Case Trigger Helper
 */

/*
 _     _    ___    _____   _____           ____    _       _____       __       ____    _____       ____    _____       __       ____
|  \  | |  / _ \  |_   _| |  ___|         |  _ \  | |     |  ___|     /  \     /  __|  |  ___|     |  _ \  |  ___|     /  \     |  _ \
|   \ | | | | | |   | |   | |_     _      | |_) | | |     | |_       / /\ \    | |__   | |_        | |_) | | |_       / /\ \    | | | |
| |\ \| | | | | |   | |   |  _|   (_)     |  __/  | |     |  _|     / /__\ \   \___ \  |  _|       |    /  |  _|     / /__\ \   | | | |
| | \   | | |_| |   | |   | |___   _      | |     | |___  | |___   /  ____  \   ___) | | |___      | |\ \  | |___   /  ____  \  | |_| |
|_|  \__|  \___/    |_|   |_____| (_)     |_|     |_____| |_____| /__/    \__\ |____/  |_____|     |_| \_\ |_____| /__/    \__\ |____/

This class uses the Trigger Optimizations in conjunction with CDdCaseTriggerHandlerV2 / CDdCaseTriggerOptimizationHelper.

Use the optimization code to
> Access related entities like accounts, opportunitnities, contacts
> Access queues
> Access record types
> Access the 'single dml per entity' framework

Documentation for this can be found here: <TO DO>

Optimization examples within the code have been tagged/commented using the text : OPTIMIZATION EXAMPLE
Please search this within this code to understand the usage.

>>>> Use isNewOrFieldUpdated method to determine if the record is a new one, or if a field has changed on the record
>>>> Use isFieldUpdated method to determine if a field has changed on the record

*/
public class CDdCaseTriggerHelperV2 {
    public static final Boolean doDebug = CDdExperimentSvc.getCustomSettingFeatureFlag('Enable_Debug_Logs__c');

    public static final Long MILLISECONDS_IN_DAY = 86400000L;

    public static final Map<String, Integer> MARKETPLACE_ONBOARDING_CASE_STAGE_SORT_ORDER = new Map<String, Integer> {
        'Not Started' => 0,
        'Under Review' => 1,
        'Store Configuration' => 2,
        'Menu Configuration' => 3,
        'Onboarding Quality Check' => 4,
        'Contacting Mx' => 5,
        'Ready for Activation' => 6,
        'Onboarding Complete' => 7
    };
    public static final Map<String, Integer> STOREFRONT_ONBOARDING_CASE_STAGE_SORT_ORDER = new Map<String, Integer> {
        'Not Started' => 0,
        'Under Review' => 1,
        'Store Configuration' => 2,
        'Setup Storefront Page' => 3,
        'Implementation Call' => 4,
        'Link Implementation' => 5,
        'Link Optimization' => 6,
        'Onboarding Complete' => 7
    };
    public static final Map<Integer, String> MARKETPLACE_SORT_ORDER_KPI_FIELD = new Map<Integer, String> {
        1 => 'Under_Review_Date_Time__c',
        2 => 'Store_Configuration_Date_Time__c',
        3 => 'Menu_Configuration_Date_Time__c',
        4 => 'Onboarding_Quality_Check_Date_Time__c',
        5 => 'Contacting_Mx_Date_Time__c',
        6 => 'Ready_for_Activation_Date_Time__c'
    };
    public static final Map<Integer, String> STOREFRONT_SORT_ORDER_KPI_FIELD = new Map<Integer, String> {
        1 => 'Under_Review_Date_Time__c',
        2 => 'Store_Configuration_Date_Time__c',
        3 => 'Storefront_Page_Date_Time__c',
        4 => 'Implementation_Call_Date_Time__c',
        5 => 'Link_Implementation_Date_Time__c',
        6 => 'Link_Optimization_Date_Time__c'
    };

    public static final String LABEL_INTERNAL_COMMENT = 'Internal Comment';
    public static final String LABEL_TEXTPOST = 'TextPost';
    public static final String LABEL_NORMAL = 'Normal';
    public static final String LABEL_COMPLETED = 'Completed';
    public static final String DEBUG_CHATTERFEED = 'Logging postInternalChatterFeedBeforeInsert';

    private static final String SITE_ROLEBASED = '_Role';
    private static final String SITE_QUEUEBASED = '_Queue';

    public static final String QUEUE_MENU_READY_FOR_QA = 'Onboarding - Menu Ready for QA';
    public static final String QUEUE_MENU_VENDOR_ALLOCATION = 'Onboarding - Menu Vendor Allocation';
    public static final String QUEUE_NEW_PARTNER_ESCALATIONS = 'Onboarding - New Partner Escalations';
    public static final String QUEUE_SSME_PENDING = 'Onboarding - SSME Pending';
    public static final String QUEUE_TRAINING_SUPPORT = 'Support Training';
    public static final String QUEUE_CAVIAR_ONBOARDING = 'Caviar Onboarding Team';
    public static final String QUEUE_POS_INTEGRATION = 'POS_Integration_Requests';
    public static final String QUEUE_POS_INTEGRATION_ENTERPRISE = 'POS_Integration_Requests_Enterprise';
    public static final String QUEUE_PM_QUEUE = 'PM Queue';
    public static final String QUEUE_SPM_POST_SALE ='SPM (Post-Sale Handoff)';
    public static final String QUEUE_TOKYO_ESCALATIONS = 'Tokyo Escalations';
    public static final String SHIPPING_TYPE_NZ = CDdNameValuePairHelper.getTextValue('Shipping_Type_DHL_NZ');
    public static final String ZENKRAFT_PREFERNCE_NZ = CDdNameValuePairHelper.getTextValue('Zenkraft_Preference_DHL_NZ');
    public static final String QUEUE_SF_DASHER = 'SF_Dasher';
    public static final String QUEUE_CDMX_DASHER = 'CDMX_Dasher';
    public static final String QUEUE_SOCIAL_VIP = 'Social VIP';
    public static final String QUEUE_TIER_3_SOCIAL = 'Tier 3 Social';
    public static final String QUEUE_SOCIAL_INSTAGRAM_POST = 'Social - Instagram Posts';
    public static final String QUEUE_SOCIAL_FACEBOOK_DM = 'Social - Facebook DMs';
    public static final String QUEUE_SOCIAL_FACEBOOK_POST = 'Social - Facebook Posts';
    public static final String QUEUE_SOCIAL_TWITTER_DM = 'Social - Twitter DMs';
    public static final String QUEUE_SOCIAL_TWITTER_POST = 'Social - Twitter Posts';
    public static final String QUEUE_MX_PARKING = 'Mx Parking Queue';
    public static final String QUEUE_HIBERNATED_POS_PROVIDERS = 'Hibernated POS Providers';
    public static final String QUEUE_SUSPENDED_POS_PROVIDERS = 'Suspended POS Providers';

    private static final String SITE_CONFIGS   = 'local.DoorDash.siteEscConfigs';
    public static Map<String, String> categorySubCategoryArticleMap;

    public static Boolean ranPopulateRecommendedKBArticles = false;
    public static Boolean ranUpdateDeliverTabletMilestone = false;
    public static Boolean ranProcessPOSCases = false;
    public static Boolean ranSurveySend = false;
    public static Boolean ranProcessSendbirdChats = false;
    public static Boolean ranprocessNonChatCasesForTHQ = false;
    public static Boolean ranProcessCaseTouchCount = false;
    public static Boolean ranUpdateSalesNotesOnOCUSPortal = false;
    public static Boolean ranAssociatePartnerIntegrationRecord = false;
    public static Boolean ranautomateCaseBlockedTime = false;
    public static Boolean ranProactiveCase = false;
    public static Boolean ransetCaseStatusToClosed = false;
    public static Boolean ranMergeCaseAfterSolved = false;

    public static final vCS__c VCS_SETTINGS = vCS__c.getInstance();
    public static Disaster_Prevention_Setting__mdt defaultDPS = Test.isRunningTest()
        ? Disaster_Prevention_Setting__mdt.getInstance('TEST_DO_NOT_DELETE') : Disaster_Prevention_Setting__mdt.getInstance('Default');

    public static final String REOPEN_REASON_ERROR_MESG = 'You need to provide a value for Reopen Reason.';
    public static final String CASE_STATUS_UPDATE_NOT_ALLOWED_ERROR_MESG = 'You are not allowed to update the Case status.';
    public static final String DISASTER_ESC_CASE_FEED_TITLE = 'Disaster Escalation Case';
    public static final String DISASTER_ESC_MARKING_CASE_ERROR = 'Marking Case as Disaster Escalation Case \nReason : ';
    public static final String DISASTER_ESC_ADD_CRITERIA_ERROR = 'Disaster Escalation Case - Additional Criteria met \nReason : ';
    public static final String DISASTER_ESC_INBOUND_LIMIT_ERROR = 'Has inbounded {0} times in the past 30 days';
    public static final String DISASTER_ESC_STATUS_CHANGE_LIMIT_ERROR = 'Change status over {0} times';
    public static final String DISASTER_ESC_OWNER_CHANGE_LIMIT_ERROR = 'Case owner - assigned to at least {0} different users (not queues)';
    public static final String DISASTER_ESC_OPEN_DAYS_LIMIT_ERROR = 'Case has been opened (without being solved) for over {0} days';

    public static final String THIS_IS_SPAM_CASE_MSG = 'This is a spam case.';
    public static final String CANNOT_DELETE_CASE = 'The Delete Option for Cases has been Disabled. Please Close the Case instead.';

    @TestVisible private static final String POST_SALE_PBRUN = 'Post Sale Handoff Case Rejected';
    @TestVisible private static final String REQUESTING_ACC_MGMT_UNMANGED = 'Unmanaged';
    @TestVisible private static final String ONBOARDING_MGR_PBRUN = 'Onboarding Manager Handoff- rejected';

    public static Boolean SEND_TO_DENALI = true;
    public static Boolean SEND_TO_DENALI_RUN_ONCE = false;
    public static Boolean PACKAGE_TRACKING_RUN_ONCE = false;
    public static Boolean RAN_OPEN_TO_NEW = false;
    public static Boolean RAN_WORKABLE = false;
    /**
     * @description  Determines if a field has been updated on the record
     * @param   Case newCase - Case in trigger.new
     *          Map<Id, Case> oldMap - trigger.oldMap
     *          String fieldName - field to check if it has been updated
     * @return  Boolean
     */
    public static Boolean isFieldUpdated(Case newCase,Map<Id, Case> oldMap,String fieldName) {
        return (oldMap != null && newCase.get(fieldName) != oldMap.get(newCase.Id).get(fieldName));
    }

    /**
     * @description  Determines if the record is a new record or if a field has been updated on the record
     * @param   Case newCase - Case in trigger.new
     *          Map<Id, Case> oldMap - trigger.oldMap
     *          String fieldName - field to check if it has been updated
     * @return  Boolean
     */
    public static Boolean isNewOrFieldUpdated(Case newCase,Map<Id, Case> oldMap,String fieldName) {
        return trigger.isInsert || isFieldUpdated(newCase,oldMap,fieldName);
    }


    public static void setAccountId(List<Case> cases, Map<Id, Case> oldMap) {
        if (CDdCustomMetaData.isDisabled('CDdCaseTriggerHandler_setAccountId')) return;
        Set<String> storeIDs = new Set<String>();
        /***************************** OPTIMIZATION EXAMPLE *****************************
        * Using isNewOrFieldUpdated to determine if Store_ID__c has been changed or the record is a new record
        ********************************************************************************/
        for (Case c : cases) {
            if (String.isNotBlank(c.Store_ID__c) && isNewOrFieldUpdated(c, oldMap, 'Store_ID__c')) {
                storeIDs.add(c.Store_ID__c);
            }
        }
        if (storeIDs.isEmpty()) {
            return;
        }

        /***************************** OPTIMIZATION EXAMPLE *****************************
        * Query accounts which are not in the CDdCaseTriggerOptimizationHelper cache and add it to the cache for subsequent methods in the txn
        ********************************************************************************/
        List<Account> accounts = Database.query(CDdCaseTriggerOptimizationHelper.getAccountBaseQuery() + ' WHERE Restaurant_Id__c IN :storeIDs');
        CddCaseTriggerOptimizationHelper.addToAccountMap(accounts);

        Map<String, String> accountIDmap = new Map<String, String>();
        for (Account a : accounts) {
            accountIDmap.put(a.Restaurant_ID__c, a.Id);
        }
        for (Case c : cases) {
            c.AccountId = accountIDmap.containsKey(c.Store_ID__c) ? accountIDmap.get(c.Store_ID__c) : null;
        }
    }

    /**
    * @author: Tia Xuan
    * @date 03/2020
    * @description: BZAP-6950 Changing PB to Trigger -- Update Tablet Delivered on Op
    *
    */
    public static void updateTabletDeliveredOnOpp(List<Case> newCases, Map<Id,Case> oldCaseMap){
        Map<Id, Opportunity> oppMap = CDdCaseTriggerOptimizationHelper.getOpportunityMap();

        for (Case c : newCases){
           Opportunity opp = c.Opportunity_Name__c != null ? oppMap.get(c.Opportunity_Name__c) : new Opportunity();
           if ( isNewOrFieldUpdated(c, oldCaseMap, 'Tablet_Received_Date_2__c')
                    && c.RecordTypeId == CDdGenericTriggerOptimizationHelper.tabletRequestRecordTypeId
                    && c.Tablet_Received_Date_2__c != null
                    && c.Opportunity_Name__c != null
                    && opp != null
                    && opp.Tablet_Received_Date__c == null) {

                /***************************** OPTIMIZATION EXAMPLE *****************************
                * Opportunity Update is sent to the Optimization Helper which will cache this update request and execute at the end of after insert/update
                * Passing multiple fields to the method
                ********************************************************************************/
                Map<String,Object> fieldVal = new Map<String,Object>{
                    'Tablet_Delivered__c' => true,
                    'Tablet_Received_Date__c' => c.Tablet_Received_Date_2__c
                };
                CDdCaseTriggerOptimizationHelper.setSobjectToUpdate('Opportunity',opp.Id,fieldVal);
           }
       }
    }
    /**
    * @author: Tia Xuan
    * @date 03/2020
    * @description: BZAP-6950 Changing PB to Trigger -- Include Marketing Kit on Tablet Request Case
    *
    */
    public static void includeMarketingKitTabletRequest(List<Case> newCases){
        /***************************** OPTIMIZATION EXAMPLE *****************************
        * Getting Record Type Id by Name from the Optimization Helper
        ********************************************************************************/
        Id enterpriseMarketplaceRTId = CDdGenericTriggerOptimizationHelper.getOpportunityRecordTypeId('Enterprise Marketplace');

        Map<Id, Opportunity> oppMap = CDdCaseTriggerOptimizationHelper.getOpportunityMap();

        for (Case c : newCases){
            Opportunity opp = c.Opportunity_Name__c != null ? oppMap.get(c.Opportunity_Name__c) : new Opportunity();
            if( c.RecordTypeId == CDdGenericTriggerOptimizationHelper.tabletRequestRecordTypeId
                    && c.Request_Type__c != 'Ship to Merchant (Replacement All Components)'
                    && c.Request_Type__c != 'Ship to Merchant (Printer Only)'
                    && c.AccountId != null
                    && c.Opportunity_Name__c != null
                    && CDdSupportConstants.CASE_ORIGINS_MARKETING_KIT_INCLUDED.contains(c.Origin)
                    && c.Include_Marketing_Kit__c == false
                    && opp != null
                    && (opp.RecordTypeId != enterpriseMarketplaceRTId || opp.Send_Marketing_Kit__c == true)) {
                c.Include_Marketing_Kit__c = true;
            }
        }
    }

    /**
    * @author: Tia Xuan
    * @date 03/2020
    * @description: BZAP-6950 Changing PB to Trigger -- General Case Updates
    *               BIZS-666 - Raju L - Changed if ... else if ... else if... to if ... if ... if ... (verified that PB had this flow)
    */
    public static void generalCaseUpdates(List<Case> newCases, Map<Id,Case> oldCaseMap){
        Id bulkUploadRequestRTId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeId('Bulk Upload Request');

        /***************************** OPTIMIZATION EXAMPLE *****************************
        * Getting Opportunity, Account and User Map from the cache.
        ********************************************************************************/
        Map<Id, Opportunity> oppMap = CDdCaseTriggerOptimizationHelper.getOpportunityMap();
        Map<Id, Account> accMap = CDdCaseTriggerOptimizationHelper.getAccountMap();
        Map<Id, User> reqMap = CDdCaseTriggerOptimizationHelper.getUserMap();

        for (Case c : newCases){
            Opportunity opp = c.Opportunity_Name__c != null ? oppMap.get(c.Opportunity_Name__c) : new Opportunity();
            Account acc = c.AccountId != null ? accMap.get(c.AccountId) : new Account();
            User req = c.Requester__c != null ? reqMap.get(c.Requester__c) : new User();
            Case oldCase = (oldCaseMap == null ? null : oldCaseMap.get(c.Id));

            if (oldCaseMap == null
                && ((c.Opportunity_Name__c != null && opp.Preferred_Language__c != null) ||
                    (c.AccountId != null && acc != null && acc.Language__c != null))) {
                c.Language__c = c.Opportunity_Name__c != null && opp.Preferred_Language__c != null ?
                    opp.Preferred_Language__c : acc.Language__c;
            }

            if ( oldCaseMap == null
                       && c.RecordTypeId == bulkUploadRequestRTId
                       && c.Requester__c != null
                       && req.Email != null){
                c.User_Email__c = req.Email;
            }

            // Fix for https://doordash.atlassian.net/browse/BASD-26160
            if ( oldCaseMap == null
                       && c.RecordTypeId == CDdGenericTriggerOptimizationHelper.tabletRequestRecordTypeId
                       && (c.AccountId != null && acc != null && String.isNotBlank(acc.BillingState))){
                Boolean isStatePuertoRico = (CDdI18nUtility.COUNTRY_CODE_US.equals(acc.BillingCountryCode)
                                                && (CDdI18nUtility.STATE_CODE_PUERTO_RICO.equals(acc?.RealZip__RealZip__r?.RealZip__State__c)
                                                    || (CDdI18nUtility.STATE_NAME_PUERTO_RICO.equals(acc.BillingState))
                                                    )
                                            );
                c.Return_Shipping_Address_State__c = isStatePuertoRico ? CDdI18nUtility.STATE_CODE_PUERTO_RICO : c.Return_Shipping_Address_State__c;
            }

            // Fix for https://doordash.atlassian.net/browse/BIZS-1852, Sid A
            if(oldCase != null &&
                    String.isNotBlank(c.Pending_Reason__c) && c.Pending_Reason__c.equals(CDdSupportConstants.CASE_MXP_PENDING_REASON_SOLVE_WITH_DELAY) &&
                    isFieldUpdated(c, oldCaseMap, 'Status') && oldCase.Status.equals(CDdSupportConstants.CASE_STATUS_PENDING)
                )
            {
                c.Pending_Reason__c = CDdSupportConstants.CASE_MXP_PENDING_REASON_SOLVE_WITH_DELAY_EXITED;
            }

            //BASD-39324 MxS - Transition active Case Workflow 'Change Status to Tablet Shipped (FedEx)' to Trigger for 12/07 Release
            if((String.isNotBlank(c.Tablet_Tracking__c) && isNewOrFieldUpdated(c,oldCaseMap,'Tablet_Tracking__c') ||
                    String.isNotBlank(c.Tracking_StarTrack__c) && isNewOrFieldUpdated(c,oldCaseMap,'Tracking_StarTrack__c') ||
                        String.isNotBlank(c.Tablet_Tracking_FedEx__c) && isNewOrFieldUpdated(c,oldCaseMap,'Tablet_Tracking_FedEx__c')) &&
                            c.Tablet_Ship_Date2__c == null && c.status != CDdSupportConstants.RECEIVED_STATUS)
                   {
                       c.Status = CDdSupportConstants.SHIPPED_STATUS;
                       c.Tablet_Ship_Date2__c = System.Now();
                       c.PB_WF_Flow_Ran__c = CDdSupportConstants.CHANGE_STATUS_TO_TABLET_SHIPPED;
                   }
        }
    }

    /**
    * @author: Tia Xuan
    * @date 03/2020
    * @description: BZAP-6950 Changing PB to Trigger -- Update Cases from Support Form in Mx Portal
    *
    */
    public static void updateCasesFromSupportFormMxPortal(List<Case> newCases){
        Id menuUpdateRTId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeId('Menu Update');
        Id supportRTId = CDdGenericTriggerOptimizationHelper.supportRecordTypeId;
        List<String> accountDeckRanks = new List<String>{'Ace','King','Queen','Jack','Joker'};
        List<String> accountDeckRanks2 = new List<String>{'Ace of Spades','King of Spades'};
        List<String> formstackCategories = new List<String>{'Account Support', 'Merchant Portal', 'Point of Sale', 'Partnership Inquiries', 'Tablet and Tech Troubleshooting'};

        Map<Id, Account> caseAccountMap = CDdCaseTriggerOptimizationHelper.getAccountMap();

        for (Case c : newCases){
            Account acc = caseAccountMap.containsKey(c.AccountId) ? caseAccountMap.get(c.AccountId) : null;

            if( c.Formstack_Source__c == 'Support Request - Mx Portal'){
                if (c.Formstack_Category__c == 'Point of Sale Troubleshooting'
                    || c.Formstack_Subcategory__c == 'Change Order Protocol'){
                    c.Issue_Category__c = 'Order Protocol';
                } else if (c.Formstack_Category__c == 'Tablet and Tech Troubleshooting'){
                    c.Issue_Category__c = 'Tablet/Printer';
                } else if (c.Formstack_Category__c == 'Feedback / Other'){
                    c.Issue_Category__c = 'Feedback';
                } else if (c.Formstack_Type__c == 'Reopen Store - End Temporary Deactivation'){
                    c.Issue_Category__c = 'Reactivation';
                } else if (c.Formstack_Type__c == 'Close Store - Temporary Deactivation'
                            || c.Formstack_Type__c == 'Close Store - Permanent Deactivation'){
                    c.Issue_Category__c = 'Deactivation';
                } else if (c.Formstack_Subcategory__c == 'Change of Ownership'){
                    c.Issue_Category__c = 'Change of Ownership';
                } else if (c.Formstack_Subcategory__c == 'Tax Update'
                            || c.Formstack_Subcategory__c == 'Payments'
                            || c.Formstack_Subcategory__c == 'Item-Level Tax Update'){
                    c.Issue_Category__c = 'Payment';
                } else if (c.Formstack_Subcategory__c == 'Menu'){
                    c.Issue_Category__c = 'Menu';
                } else if (c.Formstack_Subcategory__c == 'Onboarding'){
                    c.Issue_Category__c = 'Onboarding Issues';
                } else if (c.Formstack_Subcategory__c == 'Merchant Portal'){
                    c.Issue_Category__c = 'Merchant Portal';
                } else {
                    c.Issue_Category__c = 'Account Settings';
                }

                if (c.Formstack_Type__c  == 'Order'
                    || c.Formstack_Type__c == 'Deposit'
                    || c.Formstack_Subcategory__c == 'Health or Safety Concern'
                    || c.Formstack_Subcategory__c == 'Legal Concern'){
                    c.Priority = 'High';
                } else if (c.Formstack_Category__c  == 'Point of Sale Troubleshooting'){
                    c.Priority = 'Urgent';
                } else {
                    c.Priority = 'Normal';
                }
            }
            if ( c.Formstack_Source__c == 'Support Request - Mx Portal'
                        && c.Formstack_Category__c == 'Menu'
                        && (c.Formstack_Subcategory__c == 'Menu Update'
                            || c.Formstack_Subcategory__c == 'Other')){
                c.RecordTypeId = menuUpdateRTId;
            }
            if (c.Formstack_Source__c == 'Support Request - Mx Portal'
                        && (c.Formstack_Subcategory__c == 'Tablets'
                            || c.Formstack_Subcategory__c == 'Printers'
                            || c.Formstack_Subcategory__c == 'Receiving a Tablet'
                            || c.Formstack_Category__c == 'Point of Sale Troubleshooting')){
                c.Customer_Type__c = 'Merchant';
                c.RecordTypeId = supportRTId;
            }

            if ((
                    (c.Formstack_Source__c == 'Support Request - Mx Portal'
                        &&  c.Formstack_Category__c == 'Menu'
                        &&  c.Formstack_Subcategory__c == 'Menu Update')
                    ||  c.Formstack_Source__c == 'Menu Request - Mx Portal'
                )
                && acc != null
                && (acc.Case_Routing_Override__c == 'Mx Success Associate Queue'
                        || acc.Support_Priority_Rank__c == 2
                        || String.isBlank(acc.Deck_Rank__c)
                    || accountDeckRanks.contains(acc.Deck_Rank__c)
                )
                && !accountDeckRanks2.contains(acc.Deck_Rank__c)) {

                c.RecordTypeId = supportRTId;
            }

            if(c.Formstack_Source__c == 'Support Request - Mx Portal'
                && caseAccountMap.containsKey(c.AccountId) && caseAccountMap.get(c.AccountId).Case_Routing_Override__c == 'Mx Success Associate Queue'
                && ((formstackCategories.contains(c.Formstack_Category__c)
                    && !(c.Formstack_Subcategory__c == CDdSupportConstants.FORMSTACK_SUBCATEGORY_CHANGE_ORDER_PROTOCOL
                    && c.Formstack_Type__c == CDdSupportConstants.ISSUE_POS))
                || (c.Formstack_Category__c == 'Payments' && c.Formstack_Subcategory__c == 'Payment Reporting')
                || (c.Formstack_Category__c == 'Payments' && c.Formstack_Subcategory__c == 'Deposit Discrepancies')
                || (c.Formstack_Category__c == 'Payments' && c.Formstack_Subcategory__c == 'Fees')
                || (c.Formstack_Category__c == 'Menu' && c.Formstack_Subcategory__c == 'Item-Level Tax Update')
                || (c.Formstack_Category__c == 'Menu' && c.Formstack_Subcategory__c == 'Other')
                || (c.Formstack_Category__c == 'Getting Activated' && c.Formstack_Subcategory__c == 'Add Banking Information'))){

                c.RecordTypeId = supportRTId;
            }

            // the code below is a temporary code. will be deleted when business is ready. Approx Time to deprecate the code : July 15th.
            // Please do not forget to delete the feature flag as well! :)

            Support_Feature_Flag__c featureFlag = Support_Feature_Flag__c.getInstance();
            if(!featureFlag.Disable_MXP_Payment_Error_RT_Update__c
                && c.Formstack_Source__c == 'Support Request - Mx Portal'
                && c.Formstack_Category__c == 'Payments'
                && (c.Formstack_Subcategory__c.contains('Error Charge Disputes') ||
                c.Formstack_Subcategory__c.contains('Cancelled Order Refund'))) {

                c.RecordTypeId = supportRTId;
            }
            // the code above is a temporary code. will be deleted when business is ready. Approx Time to deprecate the code : July 15th.
        }
    }

    /**
    * @author: Tia Xuan
    * @date 03/2020
    * @description: BZAP-6950 Changing PB to Trigger -- Update Account Owner from Handoff Cases
    */

    public static void updateAccountOwnerFromHandoffCases(List<Case> newCases, Map<Id,Case> oldCaseMap){
        Id onboardingManagerHandoffRTId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeId('Onboarding Manager Handoff');

        Map<Id, Opportunity> oppMap = CDdCaseTriggerOptimizationHelper.getOpportunityMap();

        for (Case c : newCases){
            Opportunity opp = c.Opportunity_Name__c != null ? oppMap.get(c.Opportunity_Name__c) : new Opportunity();
            if (isNewOrFieldUpdated(c, oldCaseMap, 'Status') && c.Status == 'Request Approved') {
                if (c.RecordTypeId == onboardingManagerHandoffRTId && c.Post_Sale_Owner__c != null && opp.AccountId != null) {
                    CDdCaseTriggerOptimizationHelper.setSobjectToUpdate('Account',opp.AccountId,'Helper__c',c.Post_Sale_Owner__c);
                }
            }
        }
    }

    /**
    * @author: Tia Xuan
    * @date 05/2020
    * @description: BZAP-7594 Setup Caviar Diner Chat for Communities (Embedded Services Chat)
    */
    public static void fillSubjectCaviarChat(List<Case> newCases){
        Id rtId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeId(CDdSupportConstants.RECORDTYPE_NAME_CAVIRA_SUPPORT);
        for (Case c: newCases){
            if (c.RecordTypeId == rtId && c.Channel__c == 'Caviar Diner Community' && c.Origin == 'Chat' && String.isBlank(c.Subject)) {
                c.Subject = 'Inbound Diner Help Center Chat - ' + c.Caviar_Diner_Category__c;
            }
        }
    }

    /**
    * @author: Tia Xuan
    * @date 06/2020
    * @description: BZAPSUP-296 For Chat created Cases match Contact on Phone in addition to Email
    */
    public static void fillContactOnCase(List<Case> newCases, Map<Id,Case> oldCaseMap){
        List<String> emailList = new List<String>();
        List<Case> casesAffected = new List<Case>();
        for (Case c: newCases){
            if (c.ContactId == null && c.Origin == 'Chat' && String.isNotBlank(c.SuppliedEmail)) {
                emailList.add(c.SuppliedEmail.toLowerCase());
                casesAffected.add(c);
            }
        }

        if (casesAffected.isEmpty()){
            return;
        }

        /***************************** OPTIMIZATION EXAMPLE *****************************
        * Updating the contact map cache in optimization helper
        ********************************************************************************/
        CddCaseTriggerOptimizationHelper.setContactMap(emailList);
        Map<String,List<Contact>> emailContacts = CddCaseTriggerOptimizationHelper.getContactByEmailMap();

        for (Case cse : casesAffected) {
            String email = cse.SuppliedEmail.toLowerCase();
            if (!emailContacts.containsKey(email)) {
                continue;
            }
            List<Contact> ctcs = emailContacts.get(email);
            for (Contact c : ctcs) {
                if (cse.Customer_Type__c == 'Consumer' && c.CustomerNo__c != null) {
                    cse.ContactId = c.Id;
                } else if (cse.Customer_Type__c == 'Dasher' && c.DasherNo__c != null) {
                    cse.ContactId = c.Id;
                } else if (cse.Customer_Type__c == 'Merchant' && cse.ContactId == null && !c.IsPersonAccount) {
                    cse.ContactId = c.Id;
                }
            }
        }
    }

    /**
    * @author: Tia Xuan
    * @date 07/2020
    * @description: Convert Case PB to Trigger --- Caviar Support - Case Creation Flow
    */
    public static void caviarCaseCreationFlow(List<Case> newCases, Map<Id,Case> oldCaseMap){
        if (!CDdExperimentSvc.getFeatureFlag('Enable_Caviar_Case_PB_Trigger__c')){
            return;
        }

        Id caviarRTId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeId(CDdSupportConstants.RECORDTYPE_NAME_CAVIRA_SUPPORT);
       //BASD-43874 to assign opportunity owner to case op_owner__c field
       Id caviarOnboardingRTId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeId(CDdSupportConstants.RECORDTYPE_NAME_CAVIAR_ONBOADING);
       Map<Id, Opportunity> oppMap = CDdCaseTriggerOptimizationHelper.getOpportunityMap();

        Set<String> communityForms = new Set<String>{'Merchant - Caviar','Companies - Caviar','CFC Merchant - Caviar'};
        List<String> emailList = new List<String>();
        List<Case> casesAffected = new List<Case>();

        for (Case c : newCases){
            //BASD-43874 to assign opportunity owner to case op_owner__c field
            Opportunity opp = c.Opportunity_Name__c != null ? oppMap.get(c.Opportunity_Name__c) : new Opportunity();
            if(c.RecordTypeId == caviarOnboardingRTId && c.Op_Owner__c != opp.OwnerId) {
                c.Op_Owner__c = opp.OwnerId;
            }
            // #####CHECK THIS : Add isNewOrFieldUpdated(AccountId) for this if
            if(c.RecordTypeId == caviarRTId && c.SuppliedEmail != null && communityForms.contains(c.Community_Form__c)){
                emailList.add(c.SuppliedEmail);
                casesAffected.add(c);
            }
        }

        if (casesAffected.isEmpty()) {
            return;
        }

        List<Id> accRTIds = new List<Id>{
            CDdGenericTriggerOptimizationHelper.getAccountRecordTypeIdByDevName('Prospect'),
            CDdGenericTriggerOptimizationHelper.getAccountRecordTypeIdByDevName('Corporate_Customers')
        };

        List<Account> accList = Database.query(CDdCaseTriggerOptimizationHelper.getAccountBaseQuery() +
              ' WHERE Decision_Maker_Email__c =: emailList AND RecordTypeId =: accRTIds');
        if (accList.isEmpty()) {
            return;
        }

        CDdCaseTriggerOptimizationHelper.addToAccountMap(accList);

        Map<String, Account> emailToAccount = new Map<String, Account>();
        for (Account acc : accList){
            emailToAccount.put(acc.Decision_Maker_Email__c, acc);
        }

        if (emailToAccount.isEmpty()) {
            return;
        }

        for (Case c : casesAffected){
            if (emailToAccount.containsKey(c.SuppliedEmail)){
                Account curAcc = emailToAccount.get(c.SuppliedEmail);
                c.ContactId = curAcc.Decision_Maker__c;
                c.AccountId = curAcc.Id;
            }
        }
    }

    /**
     * @description Populte KB Article Recommendation : BZAPSUP-169
     */
    public static void populateRecommendedKBArticles(List<Case> newCases,Map<Id,Case> oldCaseMap) {
        if (categorySubCategoryArticleMap == null){
            categorySubCategoryArticleMap = getCategoryKBMapping();
        }
        String keyValue;
        /***************************** OPTIMIZATION EXAMPLE *****************************
        * Frequently used record type ids can be stored within the optimization helper
        ********************************************************************************/
        String supportRTId = CDdGenericTriggerOptimizationHelper.supportRecordTypeId;
        String tempKey;
        if(!ranPopulateRecommendedKBArticles) {
            for(Case currCase : newCases) {
                tempKey = null;
                CDdUtilities.debug(LoggingLevel.DEBUG,'><> oldMap '+oldCaseMap,doDebug);
                if(currCase.RecordTypeId == supportRTId &&
                    currCase.Origin == 'Chat' &&
                        (isNewOrFieldUpdated(currCase, oldCaseMap, 'comm_dependent_cx_Category__c') ||
                        isNewOrFieldUpdated(currCase, oldCaseMap, 'communities_dependent_mx_Category__c') ||
                        isNewOrFieldUpdated(currCase, oldCaseMap, 'communities_dependent_dx_Category__c') ||
                        isNewOrFieldUpdated(currCase, oldCaseMap, 'Chat_Issue__c') ||
                        isNewOrFieldUpdated(currCase, oldCaseMap, 'Origin') ||
                        isNewOrFieldUpdated(currCase, oldCaseMap, 'communities_cx_Subcategory__c') ||
                        isNewOrFieldUpdated(currCase, oldCaseMap, 'communities_mx_Subcategory__c') ||
                        isNewOrFieldUpdated(currCase, oldCaseMap, 'communities_dx_Subcategory__c'))) {

                    if (String.isBlank(currCase.Channel__c)) {
                        // if Channel is blank, it is a mobile chat case
                        tempKey = currCase.Chat_Issue__c;

                    } else if (currCase.Customer_Type__c == 'Consumer' && currCase.Channel__c == 'Consumer Community') {
                        // this is a consumer community case.
                        tempKey = currCase.comm_dependent_cx_Category__c + currCase.communities_cx_Subcategory__c;
                    } else if (currCase.Customer_Type__c == 'Merchant') {
                        tempKey = currCase.communities_dependent_mx_Category__c + currCase.communities_mx_Subcategory__c;
                    } else if (currCase.Customer_Type__c == 'Dasher') {
                        tempKey = currCase.communities_dependent_dx_Category__c + currCase.communities_dx_Subcategory__c;
                    }

                    if(tempKey != null){
                        // append Customer_Tpye__c only if the tempKey is not null;
                        if(!String.isBlank(currCase.Customer_Type__c)){
                            tempKey += currcase.Customer_Type__c;
                        }
                        tempKey = tempKey.toLowerCase();
                    }

                    CDdUtilities.debug(LoggingLevel.DEBUG,'TempKey = '+tempKey,doDebug);
                    if (tempKey != null && categorySubCategoryArticleMap.containsKey(tempKey)) {
                        currCase.KB_Recommendation__c = categorySubCategoryArticleMap.get(tempKey);
                        ranPopulateRecommendedKBArticles = true;
                    } else {
                        currCase.KB_Recommendation__c = null;
                        ranPopulateRecommendedKBArticles = true;
                    }
                }
            }
        }
    }

    /**
     * @description Get map of Case Category, Sub Category KB Mapping.
     */
    public static Map<String,String> getCategoryKBMapping(){
        List<KB_Recommendation_Mappings__c> KBMappingList = KB_Recommendation_Mappings__c.getAll().values();

        Map<String, String> categorySubCategoryArticleMap = new Map<String,String>();
        CDdUtilities.debug(LoggingLevel.DEBUG,'Getting MAP',doDebug);
        for (KB_Recommendation_Mappings__c kbRecommendation : KBMappingList) {
            String keyValue = kbRecommendation.Case_Category__c.toLowerCase();
            if (!String.isBlank(kbRecommendation.Case_Sub_Category__c)) {
                keyValue+= kbRecommendation.Case_Sub_Category__c.toLowerCase();
            }
            if (!String.isBlank(kbRecommendation.Customer_Type__c)) {
                keyValue+= kbRecommendation.Customer_Type__c.toLowerCase();
            }
            categorySubCategoryArticleMap.put(keyValue, kbRecommendation.Recommended_KB_Article__c);
            CDdUtilities.debug(LoggingLevel.DEBUG,'Map Key = '+keyValue,doDebug);
        }
        return categorySubCategoryArticleMap;
    }

    /**
    * @author: Jeremy Johnson
    * @date 08/2020
    * @description: BZAP-8298: Set Case Record Type to "POS Integrations" if a POS Order Protocol Change support request from the portal
    *               BZAP-8696: Update criteria
    */
    public static void updatePOSIntegrationsGoLiveDate(List<Case> caseList) {
        if (CDdCustomMetaData.isDisabled('CDdCaseTriggerHandler_posIntegrations')) {
            return;
        }
        Id recordTypeId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeIdByDevName('POS_Integrations');
        for (Case c : caseList) {
            if (recordTypeId.equals(c.RecordTypeId) && c.POS_Go_Live_Date__c < System.today().addDays(5)) {
                c.POS_Go_Live_Date__c = System.today().addDays(5);
            }
        }
    }

    /**
    * @author: Tia Xuan
    * @date 09/2020
    * @description: BZAPSUP-922: Populate Decision Maker Email Field with Decision Maker Email
    */
    public static void populateDecisionMakerEmail(List<Case> caseList, Map<Id, Case> oldMap) {
        Set<Id> caseRTIds = new Set<Id>{
            CDdGenericTriggerOptimizationHelper.getCaseRecordTypeId(CDdSupportConstants.RECORDTYPE_NAME_API),
            CDdGenericTriggerOptimizationHelper.getCaseRecordTypeId(CDdSupportConstants.RECORDTYPE_NAME_SUPPORT),
            CDdGenericTriggerOptimizationHelper.getCaseRecordTypeId(CDdSupportConstants.RECORDTYPE_NAME_ACCOUNT_MANAGEMENT)
        };

        Map<Id, Account> accMap = CDdCaseTriggerOptimizationHelper.getAccountMap();

        for (Case c : caseList){
            if (String.isBlank(c.Decision_Maker_Email__c)
                    && c.AccountId != null
                    && accMap.containsKey(c.AccountId)
                    && caseRTIds.contains(c.RecordTypeId)){
                c.Decision_Maker_Email__c = accMap.get(c.AccountId).Decision_Maker_Email__c;
            }
        }
    }

    /**
     * @author      Sahil
     * @date        August 2021
     * @jira        https://doordash.atlassian.net/browse/BIZS-206
     * @description set owner on cases
     */
    public static void setCaseOwner(List<Case> newCaseList, System.TriggerOperation operationType) {
        //check if feature is enabled
        if (CDdCustomMetaData.isDisabled('CDdCaseTriggerHelper_setCaseOwner')) {
            return;
        }
        //call vendor split service to set preferred vendor
        CDdVendorSplitHelper.setCaseOwner(newCaseList, operationType);
    }

    /**
     * @author     Sahil
     * @date  2021-07-27
     * @decription update cases with total comment count and last internal comment date
     * @param   list of cases
     * @return  void
    */
    public static void postInternalChatterFeedBeforeInsert(List<Case> cases) {
        //check if feature is enabled
        if (CDdCustomMetaData.isDisabled('CDdCaseTriggerHelper_PICFBefInsert')) {
            return;
        }
        for (Case c : cases) {
            if (c.CreateInternalComment__c == true && c.InternalCommentToFeed__c != null) {
                //log to see if this method is running
                CDdErrorUtilities.publishException('CDdCaseTriggerHelper', 'postInternalChatterFeedBeforeInsert',
                                                    null, DEBUG_CHATTERFEED);
                if (c.TotalCommentCount__c == null || c.TotalCommentCount__c == 0) {
                    c.TotalCommentCount__c = 1;
                } else {
                    c.TotalCommentCount__c ++;
                }
                c.Last_Internal_Comment__c = DateTime.now();
            }
        }
    }

    /**
     * @author      Mahesh Chouhan
     * @date        Oct 2021
     * @jira        https://doordash.atlassian.net/browse/BIZS-602
     * @description set case owner on support training cases
     */
    public static void setTrainingCaseOwner(List<Case> newCaseList) {
        Id supportTrainingRTId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeId(CDdSupportConstants.RECORDTYPE_SUPPORT_TRAINING);

        Id trainingSupportQueueId = CDdGenericTriggerOptimizationHelper.getQueueIdByName(QUEUE_TRAINING_SUPPORT);
        for (Case caseObj: newCaseList){
            if (caseObj.RecordTypeId == supportTrainingRTId) {
                caseObj.OwnerId = trainingSupportQueueId;
            }
        }
    }

    /**
     * @author      Raju Lakshman
     * @date        Nov 2021
     * @jira        https://doordash.atlassian.net/browse/BIZS-666
     * @description Moving this method over from VCaseTriggerHandler
     */
    public static void addPersonAccounts(List<Case> newCases) {
        if (!VCS_SETTINGS.CustomerPAUpsert__c)
            return;

        List<Case> caseList = new List<Case>();
        List<String> emailList = new List<String>();

        for (Case c : newCases) {
            if (c.BypassVeltigCaseTrigger__c) {
                continue;
            }
            if (c.SuppliedEmail != null
                    && ((c.Origin == 'Web' && (c.Customer_Type__c == 'Consumer' || c.Customer_Type__c == 'Dasher')) || c.Origin == 'Email')
                && c.Case_Record_Type__c == CDdSupportConstants.RECORDTYPE_NAME_SUPPORT) {
                caseList.add(c);
                emailList.add(c.SuppliedEmail);
            }
        }

        if (caseList.isEmpty()) {
            return;
        }

        Id personAccountRecordTypeId = CDdGenericTriggerOptimizationHelper.getAccountRecordTypeIdByDevName('PersonAccount');

        CddCaseTriggerOptimizationHelper.setContactMap(emailList);
        Map<String,List<Contact>> contactByEmailMap = CddCaseTriggerOptimizationHelper.getContactByEmailMap();

        List<Account> accountsToInsert = new List<Account>();
        List<Case> caseListIteration2 = new List<Case>();

        for (Case c : caseList) {
            Contact personAccountContactRec = null;
            String email = c.SuppliedEmail.toLowerCase();

            if (contactByEmailMap.containsKey(email)) {
                List<Contact> contacts = contactByEmailMap.get(email);
                for (Contact con : contacts) {
                    if (con.IsPersonAccount) {
                        personAccountContactRec = con;
                        break;
                    }
                }
            }

            if (personAccountContactRec == null) {
                Account acc = new Account(
                    RecordTypeId = personAccountRecordTypeId,
                    PersonEmail = c.SuppliedEmail,
                    Phone = c.SuppliedPhone
                );
                if(c.SuppliedName != null) {
                    String[] names = c.SuppliedName.trim().split(' ');
                    if (names.size() > 1) {
                        acc.FirstName = names[0];
                        acc.LastName = names[1];
                    } else {
                        acc.LastName = names[0];
                    }
                } else {
                    acc.LastName = c.SuppliedEmail;
                }
                accountsToInsert.add(acc);
                caseListIteration2.add(c);
            } else {
                if (VCS_SETTINGS.CasePopulateContact__c) {
                    c.ContactId = personAccountContactRec.Id;
                }

                if (VCS_SETTINGS.CasePopulatePersonAccount__c) {
                    c.AccountId = personAccountContactRec.AccountId;
                }
            }
        }

        if (accountsToInsert.isEmpty())
            return;

        try {
            insert accountsToInsert;
        } catch (Exception e) {
            String payload = 'Cases for which person accounts could not be inserted: ';
            for (Case c : caseListIteration2) {
                payload += c.id + CDdCoreConstants.DELIMITER_COMMA;
            }
            CDdErrorUtilities.publishException(e,'CDdCaseTriggerHelperV2','addPersonAccounts', payload.removeEnd(CDdCoreConstants.DELIMITER_COMMA));
            throw e;
        }

        List<Contact> newPersonContacts = Database.query(CDdCaseTriggerOptimizationHelper.getContactBaseQuery() + ' WHERE AccountId IN :accountsToInsert');
        CddCaseTriggerOptimizationHelper.addToContactMap(newPersonContacts);

        contactByEmailMap = CddCaseTriggerOptimizationHelper.getContactByEmailMap();

        for (Case c : caseListIteration2) {
            Contact personAccountContactRec = null;
            String email = c.SuppliedEmail.toLowerCase();
            if (contactByEmailMap.containsKey(email)) {
                List<Contact> contacts = contactByEmailMap.get(email);
                for (Contact con : contacts) {
                    if (con.IsPersonAccount) {
                        personAccountContactRec = con;
                        break;
                    }
                }
            }

            if (personAccountContactRec != null) {
                if(VCS_SETTINGS.CasePopulateContact__c) {
                    c.ContactId = personAccountContactRec.Id;
                }
                if(VCS_SETTINGS.CasePopulatePersonAccount__c) {
                    c.AccountId = personAccountContactRec.AccountId;
                }
            }
        }
    }

    /**
    * @author Saniya Belim
    * @date 2018-10
    *
    * @description JIRA: BZAP-2574
    * Convert "Mx Marketing Case has Address added when Account added" PB
    * Updated the Shipping address on Case when associated with an Account with Billing address
    *       BIZS-666 - Moving this method over from VCaseTriggerHandler
    */
    public static void processMxMarketingCase(List<Case> newCases) {
        Id dasherMxCaseRecordTypeId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeId('Dasher / Merchant Kits');

        Map<Id,Account> accountMap = CDdCaseTriggerOptimizationHelper.getAccountMap();
        for (Case c:newCases) {
            if (c.RecordTypeId == dasherMxCaseRecordTypeId &&
                    c.AccountId != null &&
                    accountMap.containsKey(c.AccountId)) {
                Account currAcct = accountMap.get(c.AccountId);
                c.Return_Shipping_Address_City__c = currAcct.BillingCity;
                c.Return_Shipping_Address_State__c = currAcct.BillingState;
                c.Return_Shipping_Address_Street__c = currAcct.BillingStreet;
                c.Return_Shipping_Address_Zip__c = currAcct.BillingPostalCode;
                c.Shipping_Address_Country__c = currAcct.BillingCountry;
            }
        }
    }

    /**
    * @author Saniya Belim
    * @date 2018-12
    *
    * @description JIRA: BZAP-2817
    * Case Subject Line - Automation Requirements
    * Auto-populate the Case subject when either a case is created or updated
    *       BIZS-666 - Raju L - Moving this method over from VCaseTriggerHandler
    */
    public static void caseSubjectAutomation(List<Case> newCases, Map<Id,Case> oldCaseMap) {
        Set<Id> recordTypeIds = new Set<Id> {
            CDdGenericTriggerOptimizationHelper.getCaseRecordTypeId(CDdSupportConstants.RECORDTYPE_NAME_SUPPORT),
            CDdGenericTriggerOptimizationHelper.getCaseRecordTypeId(CDdSupportConstants.RECORDTYPE_NAME_API)
        };

        Map<Id, Account> acctMap = CDdCaseTriggerOptimizationHelper.getAccountMap();
        Map<Id, Contact> contactMap = CDdCaseTriggerOptimizationHelper.getContactByIdMap();

        for (Case c : newCases) {
            if (recordTypeIds.contains(c.RecordTypeId)
                && c.Subject != CDdSupportConstants.CLOSED_BY_MERGE
                && (isNewOrFieldUpdated(c, oldCaseMap, 'Subject') ||
                    isNewOrFieldUpdated(c, oldCaseMap, 'Issue__c') ||
                    isNewOrFieldUpdated(c, oldCaseMap, 'Issue_Type__c') ||
                    isNewOrFieldUpdated(c, oldCaseMap, 'ContactId') ||
                    isNewOrFieldUpdated(c, oldCaseMap, 'AccountId'))
            ) {
                List<String> subject = new List<String>();

                if(c.Issue__c != null && c.Issue_Type__c != null) {
                    if (acctMap.get(c.AccountId) != null) {
                        subject.add(acctMap.get(c.AccountId).Name);
                    } else if (contactMap.get(c.ContactId) != null) {
                        subject.add(contactMap.get(c.ContactId).Name);
                    }
                }

                if (c.Issue__c != null) {
                    subject.add(c.Issue__c);
                }

                if (c.Issue_Type__c != null) {
                    subject.add(c.Issue_Type__c);
                }

                if (!subject.isEmpty()) {
                    c.Subject = String.join(subject, ' - ');
                }
            }
        }
    }

    /**
    * @author Tia Xuan
    * @date 2019-04
    *
    * @description Convert PB to Trigger (Case Reopened Date)
    *               BIZS-666 - Raju L - Moving this method over from VCaseTriggerHandler
    * BASD-29472 - moved the logic to populate the reopen count from WF to before update trigger
    */
    public static void caseReopenedDate(List<Case> newCases, Map<Id,Case> oldCaseMap){
        for (Case c : newCases){
            if (isNewOrFieldUpdated(c, oldCaseMap, 'Status') && c.Status == 'Reopened') {
                c.PB_WF_Flow_Ran__c = 'Case Reopened Date';
                c.Reopened_Date__c = DateTime.now();
                c.Times_Reopened__c=c.Times_Reopened__c+1;
            }
        }
    }

    /**
    * @author: Tia Xuan
    * @date 07/2020
    * @description: Convert Case PB to Trigger --- Case Process Builder (Caviar Onboarding)
    *                                          --- Caviar - Update Previous Case Owner
    */
    // **** CHECK THIS: Not called in before insert
    public static void caviarOnboarding(List<Case> newCases, Map<Id,Case> oldCaseMap){
        if (!CDdExperimentSvc.getFeatureFlag('Enable_Caviar_Case_PB_Trigger__c')){
            return;
        }
        Id grpId = CDdGenericTriggerOptimizationHelper.getQueueIdByName('Caviar Onboarding Team');

        Id caviarOnboardingRTId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeId(CDdSupportConstants.RECORDTYPE_NAME_CAVIAR_ONBOADING);
        Id caviarSupportRTId  = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeId(CDdSupportConstants.RECORDTYPE_NAME_CAVIRA_SUPPORT);
        Map<Id,Opportunity> oppMap = CDdCaseTriggerOptimizationHelper.getOpportunityMap();

        for (Case c : newCases){
            Case oldCase = oldCaseMap != null ? oldCaseMap.get(c.Id) : null;
            Opportunity opp = oppMap.containsKey(c.Opportunity_Name__c) ? oppMap.get(c.Opportunity_Name__c) : null;
            if (isFieldUpdated(c, oldCaseMap, 'OwnerId')
                    && c.Status == 'New'
                    && c.Activations_Lead__c == null
                    && c.RecordTypeId == caviarOnboardingRTId) {
                c.Activations_Lead__c = c.OwnerId;
            } else if (c.Status == 'Tablet and Banking Configuration'
                        && c.Activations_Lead__c != null
                        && c.RecordTypeId == caviarOnboardingRTId) {
                c.OwnerId = c.Activations_Lead__c;
            } else if (c.Status == 'Tablet and Banking Configuration'
                        && c.Activations_Lead__c == null
                        && c.RecordTypeId == caviarOnboardingRTId) {
                c.OwnerId = grpId;
            } else if (oldCase != null
                        && isFieldUpdated(c, oldCaseMap, 'OwnerId')
                        && ((String)oldCase.OwnerId).startsWith('005')
                        && c.RecordTypeId == caviarSupportRTId){
                c.Previous_Case_Owner__c = oldCase.OwnerId;
            } else if (oldCase != null
                      && opp != null
                      && c.RecordtypeId == caviarOnboardingRTId
                      && isFieldUpdated(c, oldCaseMap, 'Status')
                      && CDdMxSxConstants.CASE_STATUS_CLOSED.equals(c.Status)
                      && CDdMxSxConstants.CASE_STATUS_ONBOARDING_ADS_AND_PROMO.equals(oldCaseMap.get(c.id).Status)
                      && String.isNotBlank(opp.Platform__c)
                      && CDdMxSxConstants.OPPORTUNITY_PLATFORM_CAVIAR_AND_DOORDASH.equals(opp.Platform__c)
                      && c.MxP_Handoff_Date__c != null
                      && c.Activations_Lead__c != null
                       ) {
                c.ownerId = c.Activations_Lead__c;
            }
        }
    }

    /**
    * @author Tia Xuan
    * @date 2019-10
    *
    * @description  Associate an equipment to Case when Denali record ID
    *               are entered for tablet or printer
    *               BIZS-666 - Raju L - Moved Over from VCaseTriggerHandler
    */
    public static void assignEquipmentToCase(List<Case> newCases, Map<Id,Case> oldCaseMap){
        List<String> equipmentList = new List<String>();
        List<Case> casesToTreat = new List<Case>();
        for (Case c : newCases){
            if( c.RecordTypeId == CDdGenericTriggerOptimizationHelper.tabletRequestRecordTypeId
                && (isFieldUpdated(c,oldCaseMap,'Denali_Tablet_Record_ID__c') || isFieldUpdated(c,oldCaseMap,'Denali_Printer_Record_ID__c'))
            ) {
                casesToTreat.add(c);
                if (String.isNotBlank(c.Denali_Tablet_Record_ID__c)) {
                    equipmentList.add(c.Denali_Tablet_Record_ID__c);
                }
                if (String.isNotBlank(c.Denali_Printer_Record_ID__c)) {
                    equipmentList.add(c.Denali_Printer_Record_ID__c);
                }
            }
        }

        if (equipmentList.isEmpty()){
            return;
        }

        Map<String, Id> equipMap = new Map<String, Id>();
        for (ELTON__Equipment__c equip : [SELECT Id, Denali_Record_ID__c
                                            FROM ELTON__Equipment__c
                                           WHERE Denali_Record_ID__c =: EquipmentList]){
            equipMap.put(equip.Denali_Record_ID__c, equip.Id);
        }

        List<ELTON__Equipment__c> equipToInsert = new List<ELTON__Equipment__c>();
        for (Case c : casesToTreat){
            if (String.isNotBlank(c.Denali_Tablet_Record_ID__c) && !equipMap.containsKey(c.Denali_Tablet_Record_ID__c)){
                equipToInsert.add(new ELTON__Equipment__c(Denali_Record_ID__c = c.Denali_Tablet_Record_ID__c));
            }

            if (String.isNotBlank(c.Denali_Printer_Record_ID__c) && !equipMap.containsKey(c.Denali_Printer_Record_ID__c)){
                equipToInsert.add(new ELTON__Equipment__c(Denali_Record_ID__c = c.Denali_Printer_Record_ID__c));
            }
        }

        if (equipToInsert.size() > 0){
            insert equipToInsert;
            for (ELTON__Equipment__c equip : equipToInsert){
                equipMap.put(equip.Denali_Record_ID__c, equip.Id);
            }
        }

        for (Case c : casesToTreat){
            if (String.isNotBlank(c.Denali_Tablet_Record_ID__c)){
                c.Equipment__c = equipMap.get(c.Denali_Tablet_Record_ID__c);
            }

            if (String.isNotBlank(c.Denali_Printer_Record_ID__c)){
                c.Printer_Equipment__c = equipMap.get(c.Denali_Printer_Record_ID__c);
            }
        }
    }

    /**
    * @author: Knick
    * @date 08/2020
    * @description: Re-Open Rejected Cases (converted to trigger from Process Builder)
    * 01/11/2021 - BZAP-9015 - POS Case Process Enhancements
    * 7/05/22 - added reopen logic frpm WF rules MX/CX/DX part of BASD-29472
    */
    public static void updateCaseStatus(List<Case> caseList, Map<Id, Case> oldMap) {
        if (CDdCustomMetaData.isDisabled('CDdCaseTriggerHelper_updateCaseStatus')) {
            return;
        }

        Id posIntegrationsRT = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeIdByDevName('POS_Integrations');

        Id supportRT= CDdGenericTriggerOptimizationHelper.getCaseRecordTypeIdByDevName('Customer');
        Id loggedUserPId=UserInfo.getProfileId();
        try{
            for (Case c : caseList) {
                if (posIntegrationsRT.equals(c.RecordTypeId)) {
                    switch on c.Status {
                        when 'Solved' {
                            if (isNewOrFieldUpdated(c, oldMap, 'Last_Email_from_Customer__c')
                                    && c.Last_Email_from_Customer__c!=null
                                    && c.Last_Email_from_Customer__c >= DateTime.now().addHours(12 * -1)){
                                c.Status = 'Reopened';
                            }
                        }
                        when 'Closed' {}
                        when else {
                            if (isNewOrFieldUpdated(c, oldMap, 'Activation_Date__c')&& c.Activation_Date__c != null) {
                                c.Status = 'Solved';
                                c.Sub_Status__c = null;
                            }
                        }
                    }
                }
                //BZAP-15632 - updating MV_Status__c to completed when Case status moved from Escalated to Approved
                if (CDdGenericTriggerOptimizationHelper.tabletRequestRecordTypeId.equals(c.RecordTypeId)) {
                    if (oldMap != null &&
                        oldMap.get(c.Id).Status == CDdSupportConstants.ESCALATED_STATUS &&
                        c.status == CDdSupportConstants.APPROVED_STATUS) {
                            c.MV_Status__c = CDdSupportConstants.COMPLETED_STATUS;
                    }
                }
                // Reopen for SF-Dasher/Merchant/Consumer - converted WF to trigger
                if (supportRT.equals(c.RecordTypeId)) {
                    if (isNewOrFieldUpdated(c, oldMap, 'Last_Email_from_Customer__c')
                    && c.Priority != CDdSupportConstants.URGENT_PRIORITY
                    && c.Status !=CDdSupportConstants.CLOSED_STATUS
                    && c.SF_Queue__c
                    && ( c.Case_Owner_Profile__c =='Agent'
                    || Agent_Setting__c.getInstance(loggedUserPId).Is_Agent__c)
                    && (c.Customer_Type__c == CDdSupportConstants.CUSTOMER_TYPE_MERCHANT
                    || c.Customer_Type__c ==  CDdSupportConstants.CUSTOMER_TYPE_DASHER
                    || c.Customer_Type__c ==  CDdSupportConstants.CUSTOMER_TYPE_CONSUMER)){
                        c.Status = CDdSupportConstants.REOPEN_STATUS;
                    }
                }
            }
        }
        catch(Exception ex){
            CDdErrorUtilities.publishException('CDdCaseTriggerHelperV2','updateCaseStatus', ex);
        }
    }
    /**
     * Assign POS Integrations RecordType after ownership assignment.
     */
    public static void updatePOSIntegrationsRecordType(List<Case> caseList, Map<Id, Case> oldMap) {
        if (CDdCustomMetaData.isDisabled('CDdCaseTriggerHandler_posIntegrations')) {
            return;
        }
        /***************************** OPTIMIZATION EXAMPLE *****************************
        * Using Optimization helper to get queues. Note that queues add the optimization cache during the CDdCaseTriggerHelperV2 Constructor
        ********************************************************************************/

        Set<Id> owners = new Set<Id> {
            CDdGenericTriggerOptimizationHelper.getQueueIdByDevName(QUEUE_POS_INTEGRATION_ENTERPRISE),
            CDdGenericTriggerOptimizationHelper.getQueueIdByDevName(QUEUE_POS_INTEGRATION)
        };

        Set<Id> recordTypeIds = new Set<Id>{
            CDdGenericTriggerOptimizationHelper.getCaseRecordTypeId(CDdSupportConstants.RECORDTYPE_NAME_ACCOUNT_MANAGEMENT),
            CDdGenericTriggerOptimizationHelper.getCaseRecordTypeIdByDevName('POS_Support')
        };

        Id posIntgRecordTypeId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeIdByDevName('POS_Integrations');

        for (Case c : caseList) {
            Id previousOwnerId = oldMap.get(c.Id).OwnerId;
            if (recordTypeIds.contains(c.RecordTypeId)
                    && c.OwnerId != previousOwnerId
                    && owners.contains(previousOwnerId)
                    && String.valueOf(c.OwnerId).startsWith('005')) {
                c.RecordTypeId = posIntgRecordTypeId;
            }
        }
    }

    /**
    * @author: Knick
    * @date 11/2020
    * @description: BZAPSUP-1179 Set Entitlements for Mx Cases
    * NOTE: In a sandbox without full data replication, you may either delete Mx_Entitlement_Id
    * OR, Create an Account and an Entitlement and populate Mx_Entitlement_Id with a valid value
    */
    public static final Id MxEntitlementId = CDdCustomMetadata.getIdValueFor('Mx_Entitlement_Id');
    public static void setEntitlements(List<Case> cases, Map<Id, Case> oldMap) {
        if (CDdCustomMetaData.isDisabled('CDdCaseTriggerHandler_setEntitlements')) {
            return;
        }
        if (MxEntitlementId == null) {
            CDdUtilities.debug(LoggingLevel.DEBUG,'WARNING: MxEntitlementId is null',doDebug);
            return;
        }
        for (Case c: cases) {
            if ((c.EntitlementId == null)
            &&  (   (c.Initial_Queue_Name__c == 'MxSx - Escalated')
            ||      (c.Initial_Queue_Name__c == 'MxSx - National')
            ||      (c.Initial_Queue_Name__c == 'MxSx - Regional')
            ))  {
                c.EntitlementId = MxEntitlementId;
            }
        }
    }

    public static void automateCaseBlockedTime(List<Case> cases, Map<Id, Case> oldCases){
        if (CDdCustomMetaData.isDisabled('CDdCaseTriggerHelper_automateCaseBlockedTime')) return;
        if(ranautomateCaseBlockedTime){
            return;
        }
        boolean isOnboardingCase = false;
        boolean isCaseStatusChangedFromBlocked = false;
        boolean isCaseStatusChangedToBlocked = false;
        Set<String> onboardingCaseRTId = CDdMxSxConstants.MXSX_MISSING_MILESTONES_UPDATE_RECORDTYPES;
        for(Case c: cases){
            isOnboardingCase = onboardingCaseRTId.contains(c.RecordTypeId);
            // exit logic if not onboarding case
            if(!isOnboardingCase){
                continue;
            }
            // onboarding case blocked status kpi
            Case oldCase = oldCases.get(c.Id);
            isCaseStatusChangedFromBlocked = isFieldUpdated(c,oldCases,'Status') && oldCase.Status == CDdSupportConstants.STATUS_BLOCKED;
            isCaseStatusChangedToBlocked = isFieldUpdated(c,oldCases,'Status') && c.Status == CDdSupportConstants.STATUS_BLOCKED;
            if(isCaseStatusChangedFromBlocked || isCaseStatusChangedToBlocked){
                if(isCaseStatusChangedFromBlocked && c.Last_Blocked_Date_Time__c != null){
                    Decimal elapsedTimeSpentInBlocked = Decimal.valueOf((system.now().getTime() - c.Last_Blocked_Date_Time__c.getTime()))/(MILLISECONDS_IN_DAY);
                    Decimal currentlyRecordedElapsedTimeSpentInBlocked = c.Time_Spent_In_Blocked_Days__c;
                    c.Time_Spent_In_Blocked_Days__c = (currentlyRecordedElapsedTimeSpentInBlocked == null)
                            ? elapsedTimeSpentInBlocked
                            : elapsedTimeSpentInBlocked + currentlyRecordedElapsedTimeSpentInBlocked;
                }else if(isCaseStatusChangedToBlocked){
                    c.Last_Blocked_Date_Time__c = system.now();
                }
                ranautomateCaseBlockedTime = true;
            }
        }
    }

    public static void automateOnboardingKPIs(List<Case> cases, Map<Id, Case> oldCases){
        if (CDdCustomMetaData.isDisabled('CDdCaseTriggerHelper_automateKPIs')) return;
        Id marketplaceRTId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeId(CDdSupportConstants.RECORDTYPE_NAME_MARKETPLACE_ONBOARDING);
        Id storefrontRTId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeId(CDdSupportConstants.RECORDTYPE_NAME_STOREFRONT_ONBOARDING);
        Set<Id> onboardingCaseRTId = new Set<Id>{marketplaceRTId,storefrontRTId};
        boolean isOnboardingCase = false;
        boolean isCaseStageChanged = false;
        Integer newStageSortOrder = -1;
        String sortOrderKPIField = '';
        Map<String, Integer> ONBOARDING_CASE_STAGE_SORT_ORDER = new Map<String, Integer>();
        Map<Integer, String> SORT_ORDER_KPI_FIELD = new Map<Integer, String>();
        for(Case c: cases){
            isOnboardingCase = onboardingCaseRTId.contains(c.RecordTypeId);
            // exit logic if not onboarding case
            if(!isOnboardingCase){
                continue;
            }
            // BZAP-13084 - Allow Storefront Onboarding team to understand when Case became workable
            if (CDdMxSxConstants.RECORD_TYPE_ID_CASE_STOREFRONT_ONBOARDING.equals(c.RecordTypeId)
                && String.isNotBlank(c.OwnerId) && String.valueOf(c.OwnerId).startsWith('00G')){
                c.Date_Time_Case_Became_Workable__c = (!CDdMxSxConstants.QUEUE_ID_STOREFRONT_CASE_HOLDING_QUEUE.equals(c.OwnerId) && c.Date_Time_Case_Became_Workable__c == null) ? System.now() : c.Date_Time_Case_Became_Workable__c;
            }
            // onboarding case stage kpi
            ONBOARDING_CASE_STAGE_SORT_ORDER = (storefrontRTId == c.RecordTypeId)?STOREFRONT_ONBOARDING_CASE_STAGE_SORT_ORDER:MARKETPLACE_ONBOARDING_CASE_STAGE_SORT_ORDER ;
            SORT_ORDER_KPI_FIELD = (storefrontRTId == c.RecordTypeId)?STOREFRONT_SORT_ORDER_KPI_FIELD:MARKETPLACE_SORT_ORDER_KPI_FIELD ;

            isCaseStageChanged = c.Stage__c != oldCases.get(c.Id).Stage__c;
            if(!isCaseStageChanged){
                continue;
            }
            newStageSortOrder = (c.Stage__c == null || ONBOARDING_CASE_STAGE_SORT_ORDER.get(c.Stage__c) == null)
                    ? 0
                    : ONBOARDING_CASE_STAGE_SORT_ORDER.get(c.Stage__c);
            for(Integer belowStageSortOrder = 1; belowStageSortOrder <= Math.min(SORT_ORDER_KPI_FIELD.size(),newStageSortOrder); belowStageSortOrder++){
                sortOrderKPIField = SORT_ORDER_KPI_FIELD.get(belowStageSortOrder);
                if(c.get(sortOrderKPIField) == null){
                    c.put(sortOrderKPIField, system.now());
                }
            }
        }
    }

    /**
     * @author      Jeegar
     * @date        Jan 2021
     * @jira        https://doordash.atlassian.net/browse/BZAPSUP-1374
     * @description Asynchronous method to Send Surveys.
     *              This method creates a Platform Event that will create Delighted Tasks.
     *              Delighted Tasks have a trigger that makes an api callout to send CSAT surveys.
     *              It sends a % of the total surveys. % is stored in 'Batch and Trigger Settings' custom metadata
     *              RecordName = CDdCaseTriggerHandler_setAccountId
     *              Field name that has Percentage 'Custom Number'
     *
     *              Logic of the Process builder and the converted trigger is documented here
     *              https://docs.google.com/spreadsheets/d/1kxPvk4Tztl-JF4zxUR83wizvY7s0Yyh5xVjcyL0tSdw/edit?usp=sharing
     */

    public static void sendSurvey(List<Case> newCaseList, Map<Id,Case> oldCaseMap, Boolean usePlatformEvents) {
        // add feature flags
        // enable feature flag only for in trigger context.
        // We want the sendSurvey methods to be always executed in the batch context.
        //
        if (!System.isBatch() && CDdCustomMetaData.isDisabled('CDdCaseTriggerHelper_sendSurvey')) return;
        if (ranSurveySend) return;

        Integer sendPercentage = CDdCustomMetaData.getCustomNumber('CDdCaseTriggerHelper_sendSurvey');

        sendPercentage = sendPercentage == null ? 100 : sendPercentage;
        sendPercentage = sendPercentage > 100 ? 100 : sendPercentage;
        sendPercentage = sendPercentage < 0 ? 0 : sendPercentage;

        if(sendPercentage == 0) {
            // if the send percentage = 0, do not run anything.
            ranSurveySend = true;
            return;
        }

        Set<Id> chatCaseIds = new Set<Id>();
        Set<String> caseChatKeys = new Set<String>();
        for(Case isChatCase : newCaseList) {
            if (isChatCase.Origin == 'Chat'
                && !String.isBlank(isChatCase.ChatKey__c)) {

                caseChatKeys.add(isChatCase.ChatKey__c);
            }
        }
        Map<String, LiveChatTranscript> caseTranscriptMap = getCaseTranscriptMap (caseChatKeys);

        Set<Id> sendSurveyCases = new Set<Id>();
        Set<String> customerTypes = new Set<String>{'Consumer','Dasher','Merchant'};
        Set<String> issueAndResolutionSet = new Set<String>{'Unresolved Contact: Abandoned',
                                                                'Unresolved Contact: Dropped',
                                                                'Social - No Response Required'};

        Id supportRecordTypeId = CDdGenericTriggerOptimizationHelper.supportRecordTypeId;
        Id menuUpdateRTId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeId('Menu Update');
        for (Case currCase : newCaseList) {
            if(currCase.Delighted_Task_Created__c == null
                // if Language is blank or English, send the survey.
                && (String.isBlank(currCase.Language__c)
                    || currCase.Language__c.equalsIgnoreCase('English'))
                && (currCase.RecordtypeId == supportRecordTypeId
                    || currCase.RecordtypeId == menuUpdateRTId)
                )  {

                // Menu Update Start
                if(currCase.RecordtypeId == menuUpdateRTId
                    && currCase.Status == 'Closed'
                    && isFieldUpdated(currCase, oldCaseMap, 'Status')
                    && !currCase.Do_Not_Sent_Survey__c
                    && (currCase.ContactEmail != null
                        || currCase.SuppliedEmail != null)
                    && !String.isBlank(currCase.Is_Partner_NIMDA__c)
                    && currCase.Is_Partner_NIMDA__c.equalsIgnoreCase('Yes')
                    && currCase.Solved_At__c != null
                    && CDdSurveyHelper.toSendOrNotToSend(sendPercentage)
                    ) {
                    CDdUtilities.debug(LoggingLevel.DEBUG,'MenuUpdate case adding to sendSurveyCases ',doDebug);
                    sendSurveyCases.add(currCase.Id);

                } // Menu Update End
                // Support Case Start
                else if(currCase.RecordTypeId == supportRecordTypeId
                        && currCase.Status == 'Solved'
                        && !currCase.Do_Not_Sent_Survey__c
                        && customerTypes.contains(currCase.Customer_Type__c)
                        && !issueAndResolutionSet.contains(currCase.Resolution__c)
                        && !issueAndResolutionSet.contains(currCase.Issue__c)
                        && currCase.Communities_Dependent_Dx_Category__c != 'Insurance Claims'
                        && currCase.Survey_Taken_Date__c == null
                        ) {

                    // Phone/Chat
                    if(CDdSurveyHelper.isPhoneChatCase(currCase)) {
                        CDdUtilities.debug(LoggingLevel.DEBUG,' ----> Chat Key = '+currCase.ChatKey__c,doDebug);
                        if(!String.isBlank(currCase.ChatKey__c)
                            && caseTranscriptMap.containsKey(currCase.ChatKey__c)
                                && currCase.Customer_Type__c == 'Consumer'
                                && isInAppChatTranscript(caseTranscriptMap.get(currCase.ChatKey__c))) {
                            CDdUtilities.debug(LoggingLevel.DEBUG,' ----> This is an InAppChat',doDebug);
                            continue;
                        } else if (CDdSurveyHelper.toSendOrNotToSend(sendPercentage)) {
                            CDdUtilities.debug(LoggingLevel.DEBUG,'phoneChat case adding to sendSurveyCases ',doDebug);
                            sendSurveyCases.add(currCase.Id);
                        }
                    }

                    // Web with no Contact Email Start
                    if(CDdSurveyHelper.isWebWithNoContactEmailCase(currCase)
                            && CDdSurveyHelper.toSendOrNotToSend(sendPercentage)) {
                        CDdUtilities.debug(LoggingLevel.DEBUG,'webNoContact case adding to sendSurveyCases ',doDebug);
                        sendSurveyCases.add(currCase.Id);
                    }

                    // Web / Email Start
                    if(CDdSurveyHelper.isWebEmailCase(currCase)
                            && CDdSurveyHelper.toSendOrNotToSend(sendPercentage)) {
                        CDdUtilities.debug(LoggingLevel.DEBUG,'WebEmail case adding to sendSurveyCases ',doDebug);
                        sendSurveyCases.add(currCase.Id);
                    }
                    // Web / Email END
                }
                // Support Case End
            }
        }
        CDdUtilities.debug(LoggingLevel.DEBUG,'usePlatformEvents = '+usePlatformEvents+' sendSurveyCases.size() = '+sendSurveyCases.size()+' SystemisBatch() = '+System.isBatch(),doDebug);
        if(usePlatformEvents && !sendSurveyCases.isEmpty() ) {
            CDdUtilities.debug(LoggingLevel.DEBUG,'Caling from Trigger',doDebug);
            CDdQualtricsSurveyEventTriggerHandler.publishEvents(sendSurveyCases);
            ranSurveySend = true;

        } else if(!usePlatformEvents && !sendSurveyCases.isEmpty() && System.isBatch()) {
            // call in batch context
            CDdUtilities.debug(LoggingLevel.DEBUG,'Caling from batch',doDebug);
            CDdSurveyHelper.processCasesForDelightedTaskCreation(sendSurveyCases);
            ranSurveySend = true;
        }

    }

    /**
     * @author      Jeegar
     * @date        Jan 2021
     * @jira        https://doordash.atlassian.net/browse/BZAPSUP-1374
     * @description Get Map of ChatKey and ChatTranscripts
     */

    public static Map<String, LiveChatTranscript> getCaseTranscriptMap (Set<String> caseChatKeys) {
        Map<String, LiveChatTranscript> caseTranscriptMap = new Map<String, LiveChatTranscript>();

        List<LiveChatTranscript> transcripts = [SELECT id, CaseId, UserAgent, Platform, ChatKey
                                                    FROM LiveChatTranscript
                                                    WHERE ChatKey in: caseChatKeys];

        for(LiveChatTranscript transcript : transcripts) {
            caseTranscriptMap.put(transcript.ChatKey, transcript);
        }

        return caseTranscriptMap;
    }

    /**
     * @author      Jeegar
     * @date        Jan 2021
     * @jira        https://doordash.atlassian.net/browse/BZAPSUP-1374
     * @description Checks if the case is a Web/Email Case
     */

    public static boolean isInAppChatTranscript(LiveChatTranscript transcript){
        if(transcript != null
            && ((transcript.Platform!= null
                    && transcript.Platform == 'Android')
                ||( transcript.UserAgent!= null
                    && transcript.UserAgent.startsWithIgnoreCase('iPhone')
            ))){
            return true;
        }
        return false;
    }
    /*********************************************************************************************************
     * @name            setOwnership
     * @author          Jose Vega <jose.vega@doordash.com>
     * @created         26 / 02 / 2021
     * @description     Handles settings the ownership of a  Marketplace Onboarding case
     *                  in scenarios where milestones 1 - 4 are completed after Setup Menu
     *                  BZAP-9937
     * @param           List<Case>, Map<Id,Case> Trigger helper methods
    **********************************************************************************************************/
    public static void setOwnership(List<Case> cases, Map<Id, Case> oldMap) {
        Id newCaseOwnerId;
        Id previousCaseOwnerId;
        Id onboardingCaseRTId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeId(CDdSupportConstants.RECORDTYPE_NAME_MARKETPLACE_ONBOARDING);
        Map<Id, Milestone__c> caseIdToMenuSetupMiletone = new Map<Id, Milestone__c>();
        Set<Id> caseQueueIds = new Set<Id>{
            CDdGenericTriggerOptimizationHelper.getQueueIdByName(QUEUE_MENU_VENDOR_ALLOCATION),
            CDdGenericTriggerOptimizationHelper.getQueueIdByName(QUEUE_SSME_PENDING)
        };

        List<Case> toProcess = new List<Case>();
        for (Case c: cases){
            newCaseOwnerId = c.ownerId;
            previousCaseOwnerId = oldMap.get(c.Id).ownerid;
            if(c.RecordTypeId != onboardingCaseRTId || newCaseOwnerId == previousCaseOwnerId){
                continue;
            }
            if(caseQueueIds.contains(newCaseOwnerId)){
                toProcess.add(c);
            }
        }

        if (toProcess.isEmpty()) {
            return;
        }

        for(Milestone__c m: [SELECT Id, Status__c, Status_Reason__c, Case__c, OwnerId FROM Milestone__c
                WHERE Case__c IN :toProcess AND (Status__c = 'Ready for QA' OR (Status__c = 'Escalated' AND Status_Reason__c = 'SSME to Doordash'))]){
            caseIdToMenuSetupMiletone.put(m.Case__c, m);
        }

        for(Case c : toProcess){
            if (!caseIdToMenuSetupMiletone.containsKey(c.Id)){
                continue;
            }
            Milestone__c tmp = caseIdToMenuSetupMiletone.get(c.Id);
            if (tmp.Status__c == 'Ready for QA') {
                c.OwnerId = CDdGenericTriggerOptimizationHelper.getQueueIdByName(QUEUE_MENU_READY_FOR_QA);
            }
            else { // query filter will ensure that else is equivalent to Status__c = 'Escalated' AND Status_Reason__c = 'SSME to Doordash')
                c.OwnerId = CDdGenericTriggerOptimizationHelper.getQueueIdByName(QUEUE_NEW_PARTNER_ESCALATIONS);
            }
        }
    }

    /**
     * @author      Sahil
     * @date        March 2021
     * @jira        https://doordash.atlassian.net/browse/BZAPSUP-1095
     * @description Checks if the case owner change is valid
     */
    public static void checkValidEscOrTransfer(List<Case> newCaseList, Map<Id,Case> oldCaseMap) {
        //check if feature is enabled
        if (CDdCustomMetaData.isDisabled('CDdCaseTriggerHelper_checkValidEscOrTransfer')) {
            return;
        }
        //get support record type
        Id supportRecordTypeId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeIdByDevName(CDdSupportConstants.RECORDTYPE_NAME_CUSTOMER);
        //build a list of cases which meet the criteria
        List<Case> tempCaseList = new List<Case>();
        Map<string,String> cacheKeySetMap = new Map<string,String>(); // key is cachekey, value is old case owner queue id
        for (Case caseVar : newCaseList) {
            if (caseVar.RecordtypeId == supportRecordTypeId
                && isFieldUpdated(caseVar, oldCaseMap, 'OwnerId')
                && caseVar.OwnerId.getSObjectType() == Group.sObjectType) {
                    tempCaseList.add(caseVar);
                    cacheKeySetMap.put(SITE_CONFIGS  +string.valueOf(caseVar.OwnerId)+string.valueOf(oldcaseMap.get(caseVar.Id).OwnerId),string.valueOf(caseVar.OwnerId)+'0KY0'+oldcaseMap.get(caseVar.Id).OwnerId );
                    cacheKeySetMap.put(SITE_CONFIGS  +string.valueOf(caseVar.OwnerId),string.valueOf(caseVar.OwnerId));
            }
        }

        if((UserInfo.getUserRoleId()) != null && !(tempCaseList == null || tempCaseList.isEmpty())){
            cacheKeySetMap.put(SITE_CONFIGS +String.valueOf(UserInfo.getUserRoleId()),String.valueof(UserInfo.getUserRoleId()));
        }

        //check criteria on the new list if there are cases
        if (!cacheKeySetMap.isEmpty() || cacheKeySetMap != null) {
            //get site escalation/transfer configs from platform cache by role id
            List<Site_Escalation_Config__c> siteEscConfigList = CDdSiteEscalationConfigService.getCachedSiteEscConfigsByUserRoleId(UserInfo.getUserRoleId(), cacheKeySetMap);
            //process further is there are any configs loaded from cache/database


            if (!siteEscConfigList.isEmpty()) {
                Map<String, Site_Escalation_Config__c> queueIdToSiteRoleMap = new Map<String, Site_Escalation_Config__c>();
                for (Site_Escalation_Config__c sECVar : siteEscConfigList) {
                    if(sECVar.Site_Role_Name__c != null){
                      queueIdToSiteRoleMap.put(sECVar.Queue_ID__c+SITE_ROLEBASED,sECVar);
                    }else if(sECVar.From_Queue_Id__c != null){
                      queueIdToSiteRoleMap.put(sECVar.Queue_ID__c+SITE_QUEUEBASED,sECVar);
                    }
                    //Ignore role as well as queue based check and prevent assigning cases to Queue_ID__c queue
                    else if(String.isBlank(sECVar.Site_Role_Name__c) && String.isBlank(sECVar.From_Queue_Id__c)){
                        queueIdToSiteRoleMap.put(sECVar.Queue_ID__c+SITE_QUEUEBASED,sECVar);
                    }
                }
                  //check if new Queue exists in the config, otherwise error
                for (Case caseVar : tempCaseList) {
                    String strError = '';
                    if (queueIdToSiteRoleMap.containsKey(caseVar.OwnerId+SITE_QUEUEBASED) && !queueIdToSiteRoleMap.get(caseVar.OwnerId+SITE_QUEUEBASED).Is_Default_Escalation__c){
                        if (caseVar.isEscalated && queueIdToSiteRoleMap.get(caseVar.OwnerId+SITE_QUEUEBASED).IsEscalation__c) {
                           strError = strError+' ' +System.Label.Case_Invalid_Escalation;
                        } else if (!caseVar.isEscalated && queueIdToSiteRoleMap.get(caseVar.OwnerId+SITE_QUEUEBASED).IsTransfer__c) {
                           strError = strError+' ' +System.Label.Case_Invalid_Transfer;
                        } else if (caseVar.isEscalated) {
                           strError = strError+' ' +System.Label.Case_Invalid_Escalation;
                        } else if (!caseVar.isEscalated) {
                           strError = strError+' ' +System.Label.Case_Invalid_Transfer;
                        }
                    }
                    if (queueIdToSiteRoleMap.containsKey(caseVar.OwnerId+SITE_ROLEBASED) && !queueIdToSiteRoleMap.get(caseVar.OwnerId+SITE_ROLEBASED).Is_Default_Escalation__c){
                        if(String.isNotBlank(strError)){
                                strError = strError + ',';
                        }
                        if (caseVar.isEscalated && queueIdToSiteRoleMap.get(caseVar.OwnerId+SITE_ROLEBASED).IsEscalation__c) {
                            strError = strError+' ' +System.Label.Case_Invalid_Escalation_UserRole;
                        } else if (!caseVar.isEscalated && queueIdToSiteRoleMap.get(caseVar.OwnerId+SITE_ROLEBASED).IsTransfer__c) {
                            strError = strError+' ' +System.Label.Case_Invalid_Transfer_For_UserRole;
                        } else if (caseVar.isEscalated) {
                            strError = strError+' ' +System.Label.Case_Invalid_Escalation_UserRole;
                        } else if (!caseVar.isEscalated) {
                            strError = strError+' ' +System.Label.Case_Invalid_Transfer_For_UserRole;
                        }
                    }
                    if(String.isNotBlank(strError)){
                        caseVar.addError(strError);
                    }
                }
            }
        }
    }

    /**
     * @author      Sahil
     * @date        March 2021
     * @jira        https://doordash.atlassian.net/browse/BZAPSUP-1095
     * @description sets default escalation queue if case is escalated without choosing a queue
     */
    public static void setDefaultEscalationQueue(List<Case> newCaseList, Map<Id,Case> oldCaseMap) {
        //check if feature is enabled
        if (CDdCustomMetaData.isDisabled('CDdCaseTriggerHelper_setDefaultEscalationQueue')) {
            return;
        }
        //get support record type
        Id supportRecordTypeId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeIdByDevName(CDdSupportConstants.RECORDTYPE_NAME_CUSTOMER);
        //build a list of cases which meet the criteria
        List<Case> tempCaseList = new List<Case>();
        Map<string,String> cacheKeySetMap = new Map<string,String>(); // key is cachekey, value is old case owner queue i
        if((UserInfo.getUserRoleId()) != null){
            cacheKeySetMap.put(SITE_CONFIGS +String.valueOf(UserInfo.getUserRoleId()),String.valueof(UserInfo.getUserRoleId()));
        }
        for (Case caseVar : newCaseList) {
            if (caseVar.RecordtypeId == supportRecordTypeId
                && caseVar.IsEscalated
                && oldcaseMap.get(caseVar.Id).OwnerId.getSobjectType() == User.sObjectType) {
                    tempCaseList.add(caseVar);
            }
        }
        if (!(tempCaseList == null || tempCaseList.isEmpty()) && UserInfo.getUserRoleId() != null) {
            //get site escalation/transfer configs from platform cache by role id
            List<Site_Escalation_Config__c> siteEscConfigList = CDdSiteEscalationConfigService.getCachedSiteEscConfigsByUserRoleId(UserInfo.getUserRoleId(),cacheKeySetMap);
            //process further is there are any configs loaded from cache/database
            if (!siteEscConfigList.isEmpty()) {
                Id defaultEscQueueId;
                for (Site_Escalation_Config__c sECVar : siteEscConfigList) {
                    if (sECVar.Is_Default_Escalation__c) {
                        defaultEscQueueId = (Id) sECVar.Queue_Id__c;//default escalation queue id
                        break;//just need the first one
                    }
                }
                //check for a default queue and change the owner to the default queue, otherwise error
                for (Case caseVar : tempCaseList) {
                    if (defaultEscQueueId != null) {
                        caseVar.OwnerId = defaultEscQueueId;
                    } else {
                        //error because there is no default queue to escalate to
                        caseVar.addError(System.Label.Case_No_Default_Queue);
                    }
               }
            }
        }
    }

    /**
     * @author      Sahil
     * @date        June 2021
     * @jira        https://doordash.atlassian.net/browse/BZAPSUP-1923
     * @description process case touch count
     */
    public static void processCaseTouchCount(List<Case> newCaseList, Map<Id,Case> oldCaseMap) {
        //check if feature is enabled
        if (CDdCustomMetaData.isDisabled('CDdCaseTriggerHelper_processCaseTouchCou')) {
            return;
        }
        //recursion check
        if (ranProcessCaseTouchCount) {
            return;
        }
        //check if case status or owner changed
        for (Case caseVar : newCaseList) {
            // Changed to use New or Field Update so that the touchcount is updated when status changes to open in before insert.
            if ((isNewOrFieldUpdated(caseVar, oldCaseMap, 'Status')
                && caseVar.Status != 'New' ) || isNewOrFieldUpdated(caseVar, oldCaseMap, 'OwnerId')) {
                if (caseVar.Overall_Touch_Count__c == null) {
                    caseVar.Overall_Touch_Count__c = 0;//set it to 0 if null - happens for historical cases
                }
                caseVar.Overall_Touch_Count__c++;//increment counter
                ranProcessCaseTouchCount = true;//avoid recursion
            }
        }
    }

    /**
     * @author      Sahil
     * @date        August 2021
     * @jira        https://doordash.atlassian.net/browse/BIZS-206
     * @description set actual vendor on cases
     */
    public static void setActualVendor(List<Case> newCaseList, Map<Id,Case> oldCaseMap) {
        //check if feature is enabled
        if (CDdCustomMetaData.isDisabled('CDdCaseTriggerHelper_setActualVendor')) {
            return;
        }
        //call vendor split service to set actual vendor
        List<Case> toProcess = new List<Case>();
        for (Case caseVar : newCaseList) {
            //only try to set actual vendor if there is a preferred vendor present
            if (String.isBlank(caseVar.Actual_Vendor__c) && String.isNotBlank(caseVar.Preferred_Vendor__c)) {
                toProcess.add(caseVar);
            }
        }
        if (!toProcess.isEmpty()) {
            CDdVendorSplitHelper.setActualVendor(toProcess,oldCaseMap);
        }
    }

    /**
     * @author      Nayana
     * @date        August 2021
     * @jira        https://doordash.atlassian.net/browse/BIZS-348
     * @description When MxP Case is escalated set MxP Queue owner instead of Tier 3 queue
     */
    public static void processMxPEscalatedCases(List<Case> newCaseList, Map<Id,Case> oldCaseMap) {
        //check if feature is enabled
        if (CDdCustomMetaData.isDisabled('CDdCaseTriggerHelper_processMxPEscalated')){
            return;
        }
        Case oldCase = new Case();
        List<Case> lstFilterCases = new List<Case> (); //Set of cases which satisfies the criteria
        String bypassIssueType = Label.MxP_Escalation_Issue_Type;
        Set<String> setIssueType = String.isNotBlank(bypassIssueType) ? new Set<String>(bypassIssueType.split(';')): new Set<String>();
        Set<Id> setTier3QueueIds = CDdAccountTeamMemberUtilities.getMxPEscalationQueue();
        CDdAccountTeamMemberUtilities atmUtil = new CDdAccountTeamMemberUtilities();

        Id supportRTId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeId(CDdSupportConstants.RECORDTYPE_NAME_SUPPORT);
        Id accountMgmtRTId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeId(CDdSupportConstants.RECORDTYPE_NAME_ACCOUNT_MANAGEMENT);

        //Loop over cases to find if eligible for MxP escalation logic or not
        for(Case caseObj: newCaseList){
            oldCase = oldCaseMap.get(caseObj.Id);
            //Filter cases only If owner has been changed for MXP overriden cases and if new owner is one of the queueTier3 queue
            if(String.isNotBlank(caseObj.AccountId) && caseObj.OwnerId!=oldCase.OwnerId && setTier3QueueIds.contains(caseObj.OwnerId) && atmUtil.isMxPRoutingOverridenCase(caseObj) && caseObj.Status!=CDdSupportConstants.SOLVED_STATUS){
                if((caseObj.RecordtypeId == supportRTId && !setIssueType.contains(caseObj.Issue__c)) ||
                (caseObj.RecordtypeId == accountMgmtRTId && caseObj.Issue_Category__c!=CDdSupportConstants.ACCOUNT_ISSUETYPE_ONBOARDING)){
                    lstFilterCases.add(caseObj);
                }
            }
        }

        if(lstFilterCases.isEmpty()){
            return;
        }

        //Get the Mx Assosciate Queue Id
        Id mxpQueueId = CDdAccountTeamMemberUtilities.fallbackQueueIdSelector(CDdSupportConstants.MX_SUCCESS_ASSOCIATE);
        List<Id> lstMxpQueueUser = new List<Id>();
        //Get the Mx Assisciate Queue Member
        for(GroupMember gm:[SELECT GroupId, Id, UserOrGroupId FROM GroupMember WHERE GroupId=:mxpQueueId]){
            lstMxpQueueUser.add(gm.UserOrGroupId);
        }
        for(Case caseObj: lstFilterCases){
            oldCase = oldCaseMap.get(caseObj.Id);
            if (mxpQueueId != null && caseObj.OwnerId != mxpQueueId && oldCase.OwnerId != mxpQueueId && !lstMxpQueueUser.contains(oldCase.OwnerId)) {
                //set the owner to the fallback queue if present
                caseObj.OwnerId = mxpQueueId;
            }
        }
    }

    /**
    * @author Saniya Belim
    * @date 2018-11
    *
    * @description JIRA: BZAP-2575
    * Convert "vPerson Account Change" PB
    * Update the Contact name on a Case when associated with a Person Account
    *           BIZS-666 - Raju L - Moving this method over from VCaseTriggerHandler
    */
    public static void processPersonAccountChange(List<Case> newCases, Map<Id,Case> oldCaseMap){
        Map<Id, Account> acctMap = CDdCaseTriggerOptimizationHelper.getAccountMap();
        for (Case c : newCases) {
            if (isFieldUpdated(c,oldCaseMap,'AccountId') && c.isPersonAccount__c) {
                Account acc = acctMap.get(c.AccountId);
                if (acc != null) {
                    c.ContactId = acc.PersonContactId;
                }
            }
        }
    }

    /**
    * @author Raju Lakshman
    * @date Apr 2023
    * @description BASD-47618 - Once mission control sets the queue; other code might want to know more information about the queue set.
    */
    public static void requeryQueueInformation(List<Case> newCases) {
        Set<Id> queueIds = new Set<Id>();
        for (Case c : newCases) {
            if (CDdUtilities.idIsGroup(c.OwnerId)) {
                queueIds.add(c.OwnerId);
            }
        }
        if (!queueIds.isEmpty()) {
            CDdGenericTriggerOptimizationHelper.setQueueMap(queueIds);
        }
    }

    /**
    * @author Saniya Belim
    * @date 2018-11
    *
    * @description JIRA: BZAP-2573
    * Convert "vBack to Queue - Add to Queue" into Trigger Framework
    *           BIZS-666 - Raju L - Moving this method over from VCaseTriggerHandler
    */
    public static void processBackToQueue(List<Case> newCases) {
        Set<String> origins = new Set<String>{'Web','Facebook','Twitter'};
        for (Case c : newCases) {
            if (c.Initial_Queue__c == null && CDdUtilities.idIsGroup(c.OwnerId)) {
                c.Initial_Queue__c = c.OwnerId;
                Group q = CDdGenericTriggerOptimizationHelper.getQueue(c.OwnerId);
                if (q != null) {
                    c.Initial_Queue_Name__c  = q.Name;
                } else if (String.isNotBlank(c.Case_Owner_Queue_Name__c)) {
                    c.Initial_Queue_Name__c  = c.Case_Owner_Queue_Name__c;
                }
            } else if (c.Back_to_Queue__c == true &&
                       String.isNotEmpty(c.Initial_Queue__c) &&
                       c.BypassVeltigCaseTrigger__c == false &&
                       origins.contains(c.Origin)) {
                c.Back_to_Queue__c = false;
                c.OwnerId = c.Initial_Queue__c;
                c.Status = 'New';
            }
        }
    }

    /**
    * @author Jessica Tamayo
    * @date 2019-03
    *
    * @description JIRA: BZAP-3302
    * Move old workflow: vPrevious Queue into a new trigger method.
    * Link to old workflow: https://figment.my.salesforce.com/01Q1a0000001WhT
    *           BIZS-666 - Raju L - Moving this method over from VCaseTriggerHandler
    */
    public static void processPreviousQueue(List<Case> newCases,Map<Id, Case> oldMap) {
        for (Case c : newCases) {
            Case oldCase = oldMap.get(c.Id);
            Id caseOwnerId = c.OwnerId;
            Id oldCaseOwnerId = oldCase.OwnerId;

            Boolean caseOwnerIsQueue = caseOwnerId != null && String.valueOf(caseOwnerId).startsWith('00G');
            Boolean oldCaseOwnerIsQueue = oldCaseOwnerId != null && String.valueOf(oldCaseOwnerId).startsWith('00G');

            Boolean queueToQueueChange = caseOwnerId != oldCaseOwnerId && caseOwnerIsQueue && oldCaseOwnerIsQueue;
            Boolean queueToUserChange = caseOwnerId != null && !caseOwnerIsQueue && oldCaseOwnerIsQueue;
            if ( queueToQueueChange || queueToUserChange ) {
                c.Previous_Queue_ID__c = oldCaseOwnerId;
                c.Previous_Queue__c = oldCase.Case_Owner_Queue_Name__c;
                c.Previous_Queue_Change__c = system.now();
            }
        }
    }

    /**
     * @author      Raju Lakshman
     * @date        Nov 2021
     * @jira        https://doordash.atlassian.net/browse/BIZS-666
     * @description Moving this method over from VCaseTriggerHandler
     */
    public static void updateContactId(List<Case> newList, Map<ID, Case> oldMap) {
        List<Case> toProcess = new List<Case>();

        Set<Id> recordTypeIds = new Set<Id>{
            CDdGenericTriggerOptimizationHelper.getCaseRecordTypeId(CDdSupportConstants.RECORDTYPE_NAME_SUPPORT),
            CDdGenericTriggerOptimizationHelper.getCaseRecordTypeId(CDdSupportConstants.RECORDTYPE_NAME_CAVIRA_SUPPORT),
            CDdGenericTriggerOptimizationHelper.getCaseRecordTypeId(CDdSupportConstants.RECORDTYPE_NAME_API)
        };

        Map<Id, Account> accMap = CDdCaseTriggerOptimizationHelper.getAccountMap();

        for(Case c : newList) {
            if(c.BypassVeltigCaseTrigger__c) continue;

            if(c.AccountId != null
                    && c.ContactId == null
                    && c.IsPersonAccount__c
                    && recordTypeIds.contains(c.RecordTypeId)
                    && accMap.containsKey(c.AccountId)) {
                c.ContactId = accMap.get(c.AccountId).PersonContactId;
            }
        }
    }

    /**
     * @author      Raju Lakshman
     * @date        Nov 2021
     * @jira        https://doordash.atlassian.net/browse/BIZS-666
     * @description Moving this method over from VCaseTriggerHandler
     */


    /**
    * @author Tia Xuan
    * @date 2019-07
    *       updated 2019-09
    *       updated 2020-03
    *
    * @description  BZAP-4281 Tracking for USPS Tracking
    *               BZAP-5114 Include FedEx in Case Trigger to create Shipments when Tracking # Entered
    *               BZAP-6032 Update Trigger for Zenkraft Multi-Carrier package for AUS
    *               BIZS-666  Moved from VCaseTriggerHandler
    */
    public static void trackPackages(List<Case> newCases, Map<Id,Case> oldCaseMap){
        if (PACKAGE_TRACKING_RUN_ONCE) {
            return;
        }

        PACKAGE_TRACKING_RUN_ONCE = true;

        Set<String> allTrackingNumbersForQuery = new Set<String>();
        List<zkmulti__MCShipment__c>  JPShipments = new List<zkmulti__MCShipment__c>();
        Set<String> oldJPNumbers = new Set<String>();
        List<zkmulti__MCShipment__c>  genericShipments = new List<zkmulti__MCShipment__c>();
        Set<String> oldTabletTrackingNumbers = new Set<String>();
        List<zkmulti__MCShipment__c>  starTrackShipments = new List<zkmulti__MCShipment__c>();
        Set<String> oldTrackNumbers = new Set<String>();
        List<zkmulti__MCShipmate_Preference__c> shipPreferenceList = new List<zkmulti__MCShipmate_Preference__c>([SELECT Id, zkmulti__CarrierAccountDescription__c
                                                            FROM zkmulti__MCShipmate_Preference__c
                                                            WHERE zkmulti__CarrierAccountDescription__c =: ZENKRAFT_PREFERNCE_NZ LIMIT 1]);

        // collect tracking numbers
        for (Case c : newCases) {
            if (String.isNotBlank(c.Tablet_Tracking__c) && isNewOrFieldUpdated(c,oldCaseMap,'Tablet_Tracking__c')) {
                oldTabletTrackingNumbers.add(c.Tablet_Tracking__c);
                allTrackingNumbersForQuery.add(c.Tablet_Tracking__c);
            }
            if (String.isNotBlank(c.Tracking_StarTrack__c) && isNewOrFieldUpdated(c,oldCaseMap,'Tracking_StarTrack__c')) {
                oldTrackNumbers.add(c.Tracking_StarTrack__c);
                allTrackingNumbersForQuery.add(c.Tracking_StarTrack__c);
            }
            if (String.isNotBlank(c.Tablet_Tracking_FedEx__c) && isNewOrFieldUpdated(c,oldCaseMap,'Tablet_Tracking_FedEx__c')) {
                oldTrackNumbers.add(c.Tablet_Tracking_FedEx__c);
                allTrackingNumbersForQuery.add(c.Tablet_Tracking_FedEx__c);
            }
            if (String.isNotBlank(c.USPS_Tracking_Number__c) && isNewOrFieldUpdated(c,oldCaseMap,'USPS_Tracking_Number__c')) {
                oldTrackNumbers.add(c.USPS_Tracking_Number__c);
                allTrackingNumbersForQuery.add(c.USPS_Tracking_Number__c);
            }
        }

        // check existing shipments
        Map<String, Id> oldTrackShipmentMap = new Map<String, Id>();
        Map<String, Id> oldJPShipmentMap = new Map<String, Id>();
        Map<String, Id> historicalShipmentMap = new Map<String, Id>();

        for (zkmulti__MCShipment__c ship: [SELECT Id, zkmulti__Tracking_Number__c FROM zkmulti__MCShipment__c WHERE zkmulti__Tracking_Number__c IN :allTrackingNumbersForQuery]) {
            if (oldTrackNumbers.contains(ship.zkmulti__Tracking_Number__c)) {
                oldTrackShipmentMap.put(ship.zkmulti__Tracking_Number__c, ship.Id);
            }
            if (oldJPNumbers.contains(ship.zkmulti__Tracking_Number__c)) {
                oldJPShipmentMap.put(ship.zkmulti__Tracking_Number__c, ship.Id);
            }
            if (oldTabletTrackingNumbers.contains(ship.zkmulti__Tracking_Number__c)) {
                historicalShipmentMap.put(ship.zkmulti__Tracking_Number__c, ship.Id);
            }
        }

        for (Case c : newCases){
            if (isNewOrFieldUpdated(c,oldCaseMap,'USPS_Tracking_Number__c') ||
                    isNewOrFieldUpdated(c,oldCaseMap,'Tablet_Tracking_FedEx__c') ||
                    isNewOrFieldUpdated(c,oldCaseMap,'Tracking_StarTrack__c') ||
                    isNewOrFieldUpdated(c,oldCaseMap,'Tablet_Tracking__c')) {
                if (String.isNotBlank(c.USPS_Tracking_Number__c) && !oldTrackShipmentMap.containsKey(c.USPS_Tracking_Number__c)){
                    zkusps.InvocableTracking.TrackParameter input = new zkusps.InvocableTracking.TrackParameter();
                    input.trackingNumber = c.USPS_Tracking_Number__c;
                    input.createShipmentIfNotFound = true;
                    input.customAddressId = Label.Zenkraft_USPS_Custom_Address_ID;
                    input.recordId = c.Id;
                    zkusps.InvocableTracking.trackShipment(new List<zkusps.InvocableTracking.TrackParameter>{input});
                } else if (String.isNotBlank(c.Tablet_Tracking_FedEx__c) && !oldTrackShipmentMap.containsKey(c.Tablet_Tracking_FedEx__c)){
                    zkfedex.InvocableTracking.TrackParameter input = new zkfedex.InvocableTracking.TrackParameter();
                    input.trackingNumber = c.Tablet_Tracking_FedEx__c;
                    input.createShipmentIfNotFound = true;
                    input.customAddressId = Label.Zenkraft_Fedex_Custom_Address_ID;
                    input.preferenceId = Label.Zenkraft_Fedex_Preference_ID;
                    input.forceShipmentCreation = true;
                    input.recordId = c.Id;
                    zkfedex.InvocableTracking.trackShipment(new List<zkfedex.InvocableTracking.TrackParameter>{input});
                } else if (String.isNotBlank(c.Tracking_StarTrack__c)){
                    // zkmulti.InvocableTracking.TrackParameter input = new zkmulti.InvocableTracking.TrackParameter();
                    // input.trackingNumber = c.Tracking_StarTrack__c;
                    // input.createShipmentIfNotFound = true;
                    // input.customAddressId = Label.Zenkraft_StarTrack_Custom_Address_ID;
                    // input.preferenceId = Label.Zenkraft_StarTrack_Preference_ID;
                    // input.recordId = c.Id;
                    // input.forceShipmentCreation = true;
                    // zkmulti.InvocableTracking.trackShipment(new List<zkmulti.InvocableTracking.TrackParameter>{input});

                    // ignore shipment if it was created before
                    if (!oldTrackShipmentMap.containsKey(c.Tracking_StarTrack__c)) {
                        zkmulti__MCShipment__c starTrackShip = new zkmulti__MCShipment__c();
                        starTrackShip.Case__c = c.Id;
                        starTrackShip.zkmulti__Tracking_Number__c = c.Tracking_StarTrack__c;
                        starTrackShip.zkmulti__Shipmate_Preference__c = Label.Zenkraft_StarTrack_Preference_ID;
                        starTrackShip.zkmulti__Mod_Key__c = 'ZKMULTI2016';
                        starTrackShipments.add(starTrackShip);
                    }
                } else if (String.isNotBlank(c.Tablet_Tracking__c) &&
                    String.isNotBlank(c.Shipping_Type__c) &&
                    !historicalShipmentMap.containsKey(c.Tablet_Tracking__c) &&
                    (c.Shipping_Type__c.contains(System.Label.SHIPPING_DHL) ||
                    c.Shipping_Type__c.contains(System.Label.SHIPPING_HIKYAKU_EXPRESS) || c.Shipping_Type__c.contains(SHIPPING_TYPE_NZ))) {
                        String shippingType = c.Shipping_Type__c;
                        zkmulti__MCShipment__c genericShip = new zkmulti__MCShipment__c();
                        genericShip.Case__c = c.Id;
                        genericShip.zkmulti__Tracking_Number__c = c.Tablet_Tracking__c;
                        genericShip.zkmulti__Mod_Key__c = 'ZKMULTI2016';
                        if(shippingType.contains(System.Label.SHIPPING_DHL)){
                            genericShip.zkmulti__Shipmate_Preference__c = Label.Zenkraft_DHL_Preference_ID;
                        }else if(shippingType.contains(SHIPPING_TYPE_NZ)){
                            genericShip.zkmulti__Shipmate_Preference__c = (!shipPreferenceList.isEmpty()) ? shipPreferenceList[0].Id : null;
                        }else if(shippingType.contains(System.Label.SHIPPING_HIKYAKU_EXPRESS) && !Test.isRunningTest()){
                            genericShip.zkmulti__Shipmate_Preference__c = System.Label.Zenkraft_Hikyaku_Preference_ID;
                        }
                        genericShipments.add(genericShip);
                }
            }
        }
        if (!starTrackShipments.isEmpty()) {
            CDdCaseTriggerOptimizationHelper.setSObjectToInsert('zkmulti__MCShipment__c', starTrackShipments);
        }

        if (!JPShipments.isEmpty()) {
            CDdCaseTriggerOptimizationHelper.setSObjectToInsert('zkmulti__MCShipment__c', JPShipments);
        }

        if (!genericShipments.isEmpty()) {
            CDdCaseTriggerOptimizationHelper.setSObjectToInsert('zkmulti__MCShipment__c', genericShipments);
        }
    }

    /**
    * @author Tia Xuan
    * @date 2019-08
    * @description Route case to Denali
    *              BIZS-666 - Raju L - Moved from VCaseTriggerHandler
    */
    public static void routeCaseToDenaliLegacy(List<Case> newCases, Map<Id,Case> oldCaseMap){
        if (SEND_TO_DENALI == false) {
            return;
        }

        if(CDdCustomMetadata.isDisabled(Batch_and_Trigger_Setting__mdt.getInstance('VCaseTrigger_LegacyDenaliInt'))){
            return;
        }

        for (Case c : newCases){
            if( c.RecordTypeId == CDdGenericTriggerOptimizationHelper.tabletRequestRecordTypeId
                && c.Status == 'Approved'
                && isFieldUpdated(c, oldCaseMap, 'Status')
            ) {
                c.Send_To_Denali__c = true;
            }
        }
    }

    /**
    * @author @ebby
    * @date 2021-10-22
    *
    * @description Create Denali log when DenaliRecordId on case is updated | BZAP-12384
    *              BIZS-666 - Raju L - Moved from VCaseTriggerHandler
    */
    public static void createDenaliLogs(List<Case> newCases, Map<Id,Case> oldCaseMap){
        String DENALIRECORDIDUPDATE = 'Denali Record Id Updated';
        List<Denali_Log__c> denaliLogs = new List<Denali_Log__c>();
        for (Case c : newCases){
            if (c.RecordTypeId == CDdGenericTriggerOptimizationHelper.tabletRequestRecordTypeId && isFieldUpdated(c, oldCaseMap, 'Denali_Record_ID__c')) {
                denaliLogs.add(new Denali_Log__c(Case__c = c.Id, Status__c = DENALIRECORDIDUPDATE,
                        ElapsedTime__c = c.Denali_Sync_Elapsed_Time__c, Message__c=c.Denali_Record_ID__c));
            }
        }
        /***************************** OPTIMIZATION EXAMPLE *****************************
        * Sending to Optimization Helper to insert records at the end of after insert/update trigger
        ********************************************************************************/
        CDdCaseTriggerOptimizationHelper.setSObjectToInsert('Denali_Log__c', denaliLogs);
    }

    /**
     * @author     Sahil
     * @date  2021-08-01
     * @decription insert/update cases with total comment count and last internal comment date
     * @param   list of cases, trigger operation type
     * @return  void
    */
    public static void postInternalChatterFeed(List<Case> cases, System.TriggerOperation operationType) {
        List<FeedItem> itemsToCreateList = new List<FeedItem>();
        List<Task> tasksTocreateList = new List<Task>();
        Support_Feature_Flag__c supportFeatureFlag = Support_Feature_Flag__c.getInstance();
        Boolean isTaskCreateEnabled = supportFeatureFlag.Enable_Tasks_on_Case_Feed__c;
        for (Case c : cases) {
            if (c.CreateInternalComment__c == true && c.InternalCommentToFeed__c != null) {
                if (String.valueOf(operationType).equalsIgnoreCase(String.valueOf(CDdCoreConstants.TriggerOperationType.AFTER_INSERT))
                    && c.TotalCommentCount__c != 1) {
                    break;
                }
                FeedItem chatterPost = new FeedItem();
                chatterPost.ParentId = c.Id;
                chatterPost.Title = LABEL_INTERNAL_COMMENT;
                chatterPost.Body = c.InternalCommentToFeed__c;
                chatterPost.Type = LABEL_TEXTPOST;
                itemsToCreateList.add(chatterPost);
                if (isTaskCreateEnabled) {
                    Task newTask = new Task();
                    newTask.WhatId = c.Id;
                    newTask.OwnerId = c.LastModifiedById;
                    newTask.Priority = LABEL_NORMAL;
                    newTask.Status = LABEL_COMPLETED;
                    tasksTocreateList.add(newTask);
                }
                if (String.valueOf(operationType).equalsIgnoreCase(String.valueOf(CDdCoreConstants.TriggerOperationType.BEFORE_UPDATE))) {
                    c.CreateInternalComment__c = false;
                    if(c.TotalCommentCount__c == null || c.TotalCommentCount__c == 0){
                        c.TotalCommentCount__c = 1;
                    } else {
                        c.TotalCommentCount__c ++;
                    }
                    c.Last_Internal_Comment__c = DateTime.now();
                }
            }
        }
        if (itemsToCreateList.size() > 0) {
            if (String.valueOf(operationType).equalsIgnoreCase(String.valueOf(CDdCoreConstants.TriggerOperationType.BEFORE_UPDATE))) {
                VFeedItemTriggerHandler.doNotUpdateCases = true;
            }
            List<Database.SaveResult> results = Database.insert(itemsToCreateList,false);
            CDdErrorUtilities.publishException('CDdCaseTriggerHelperV2','postInternalChatterFeed',results);
        }
        if (tasksTocreateList.size() > 0) {
            List<Database.SaveResult> results = Database.insert(tasksTocreateList,false);
            CDdErrorUtilities.publishException('CDdCaseTriggerHelperV2','postInternalChatterFeed',results);
        }
    }

    /**
    * @author Knick
    * @description BZAP-6564---Case-Process-Trigger--Update-Op-Activation-Details
    */
    public static void updateOpActDetails(List<Case> cases, Map<Id, Case> oldMap) {
        CDdUtilities.debug(LoggingLevel.DEBUG,'Cases: '+cases,doDebug);

        if (CDdCustomMetaData.isDisabled('CDdCaseTriggerHandler_updateOpActDetails')) {
            return;
        }

        Set<Id> assetIDs = new Set<Id>();
        Map<Id, Case> checkedCases = new Map<Id, Case>();
        for (Case c : cases) {                                   // Update Activation / Deactivation on Assets
            if (c.AssetId != null && c.Opportunity_Name__c != null && c.IsClosed) {
                assetIDs.add(c.AssetId);
                checkedCases.put(c.Id, c);
            }
        }

        if (assetIDs.size() > 0) {
            Map<Id, Asset> assetMap = new Map<Id, Asset>([SELECT Id, Activation_Date__c, Deactivation_Date__c, Status FROM Asset WHERE Id IN :assetIDs]);
            for (Case c : checkedCases.values()) {
                Asset a = assetMap.get(c.AssetId);
                if (a.Deactivation_Date__c == null && c.Deactivation_Date__c != null) {
                    Map<String,Object> fieldVal = new Map<String,Object>{
                        'Deactivation_Date__c' => c.Deactivation_Date__c,
                        'Status' => 'Deactivated'
                    };
                    CDdCaseTriggerOptimizationHelper.setSobjectToUpdate('Asset',a.Id,fieldVal);
                }
                if (a.Activation_Date__c == null && c.Activation_Date__c != null) {
                    Map<String,Object> fieldVal = new Map<String,Object>{
                        'Activation_Date__c' => c.Activation_Date__c,
                        'Status' => 'Activated'
                    };
                    CDdCaseTriggerOptimizationHelper.setSobjectToUpdate('Asset',a.Id,fieldVal);
                }
            }
        }

        Map<Id,Opportunity> oppMap = CDdCaseTriggerOptimizationHelper.getOpportunityMap();
        if (oppMap.isEmpty()) {
            return;
        }
        Set<Id> opportunityRecordTypes = new Set<Id>{
            CDdGenericTriggerOptimizationHelper.getOpportunityRecordTypeIdByDevName('ML_Inside_Sales'),
            CDdGenericTriggerOptimizationHelper.getOpportunityRecordTypeIdByDevName('Enterprise_Marketplace')
        };

        for (Case c : cases) {                                  // Update Activation / Deactivation on Opportunities
            if (c.Opportunity_Name__c == null || !oppMap.containsKey(c.Opportunity_Name__c)) {
                continue;
            }
            Opportunity opp = oppMap.get(c.Opportunity_Name__c);
            if ((c.Origin != 'Follow Up Tablet Request') &&
                    (c.Activation_Date__c != null || c.Activation_Date_2__c != null) &&
                    (c.Opportunity_Name__c != null) &&
                    (opp.Activation_Date__c == null) &&
                    (opportunityRecordTypes.contains(opp.RecordTypeID))) {

                CDdCaseTriggerOptimizationHelper.setSobjectToUpdate('Opportunity',opp.Id,'Activation_Date__c',
                    c.Activation_Date__c != null ? c.Activation_Date__c : c.Activation_Date_2__c.date()
                );
            }
        }
    }

    public static void createPhotoshootRequest(List<Case> newList) {
        Id photoshootRecordTypeId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeIdByDevName('Photoshoot_Processing');
        Set<Id> snapprCaseIdSet = new Set<Id>();
        Set<Id> ocusCaseIdSet = new Set<Id>();
        for(Case currCase : newList) {
            if(currCase.RecordTypeId == photoshootRecordTypeId
                && currCase.Photo_Provider__c == 'Snappr'
            ) {
                snapprCaseIdSet.add(currCase.Id);
            } else if(currCase.RecordTypeId == photoshootRecordTypeId && currCase.Photo_Provider__c == 'OCUS') {
                ocusCaseIdSet.add(currCase.Id);
            }
        }
        if(snapprCaseIdSet.size() > 0 && !Test.isRunningTest()) {
            CDdSnapprAPIHandler.createPhotoshoot(snapprCaseIdSet);
        }
        if(ocusCaseIdSet.size() > 0 && !Test.isRunningTest()) {
            CDdOCUSAPIHandler.handleOCUSPhotoshoot(ocusCaseIdSet,true);
        }
    }

    /**
     * @author      Sahil
     * @date        June 2021
     * @jira        https://doordash.atlassian.net/browse/BZAPSUP-1866
     * @description process incoming MxP cases
     */
    public static void processMxPCases(List<Case> newCaseList, Map<Id, Case> oldMap) {
        //check if feature is enabled
        if (CDdCustomMetaData.isDisabled('CDdCaseTriggerHelper_processMxPCases')) {
            return;
        }
        Id mxSuccessAssociateQueueId =
            CDdGenericTriggerOptimizationHelper.getQueueIdByDevName(CDdSupportConstants.QUEUE_DEVNAME_MXP_FALLBACK);

        //list of platform events to publish if case destination criteria matches
        List<Case_Reopen_Event__e> caseReopenEventList = new List<Case_Reopen_Event__e>();
        //check criteria on each case and get routing Destination
        for (Case caseVar : newCaseList) {
            Boolean routedToMxSuccessOnInsert = false;
            Boolean transferredToMxSuccess = false;
            if (oldMap == null) {
                //call metadata framework to check routing criteria based on case data
                CDdIssueBasedRoutingHelper.RoutingInfo routingInfo = CDdIssueBasedRoutingHelper.getRoutingInfo(caseVar);
                routedToMxSuccessOnInsert = routingInfo.routingDestination == CDdSupportConstants.MX_SUCCESS_ASSOCIATE;
            } else {
                transferredToMxSuccess = isFieldUpdated(caseVar,oldMap,'OwnerId') && caseVar.OwnerId == mxSuccessAssociateQueueId;
            }
            //if the case destination is MxSA Queue, raise a PE
            if (routedToMxSuccessOnInsert || transferredToMxSuccess) {
                //raise a Case Reopen Platform event for further processing
                Case_Reopen_Event__e cre = new Case_Reopen_Event__e();
                cre.CaseId__c = caseVar.Id;
                cre.newCase__c = true;
                caseReopenEventList.add(cre);
            }
        }
        //publish events
        if(!caseReopenEventList.isEmpty()) {
            List<Database.SaveResult> peInsertResult = EventBus.publish(caseReopenEventList);
            CDdErrorUtilities.publishException('CDdCaseTriggerHelperV2', 'processMxPCases', peInsertResult);
        }
    }

    /**
    * @author: Knick
    * @date 11/2020
    * @description: BZAPSUP-1179 Check Case Milestones
    */
    public static void checkMilestones(List<Case> cases, Map<Id, Case> oldMap) {
        if (CDdCustomMetaData.isDisabled('CDdCaseTriggerHandler_checkMilestones')) {
            return;
        }
        Set<Id> caseIDs = new Set<Id>();
        /* #####CHECK THIS: any other checks with oldMap??? */
        for (Case c: cases) {
            if (c.EntitlementId != null) {
                caseIDs.add(c.Id);
            }
        }

        if (caseIDs.isEmpty())
            return;

        DateTime timeStamp = System.dateTime.now();
        List<CaseMilestone> Milestones = [
            SELECT Id, StartDate, MilestoneType.Name
              FROM CaseMilestone
             WHERE CaseId IN :CaseIDs
               AND IsCompleted = false
               AND MilestoneType.Name = 'Merchant Support Update'
        ];
        for (CaseMilestone milestone : Milestones) {
            CDdCaseTriggerOptimizationHelper.setSobjectToUpdate('CaseMilestone',milestone.Id,'StartDate',timeStamp);
        }
    }

    public static void updateDeliverTabletMilestone(List<Case> cases, Map<Id, Case> oldCases){
        if (CDdCustomMetaData.isDisabled('CDdCaseTriggerHelper_updateDeliverTablet') || ranUpdateDeliverTabletMilestone) {
            return;
        }
        ranUpdateDeliverTabletMilestone = CDdCaseMilestone.updateDeliverTabletMilestone(cases);

        /*Set<Id> trCaseIds = new Set<Id>();

        for (Case c: cases) {
            if(c.RecordTypeId == CDdGenericTriggerOptimizationHelper.tabletRequestRecordTypeId
                && isFieldUpdated(c,oldCases,'Status')
                && ((c.Status == 'Shipped')
                    || (c.Status == 'Received')
                    || (c.Status == 'Dead')
                    || (c.Status == 'Returned to Sender' && c.Request_Type__c != null) )
                ) {
                trCaseIds.add(c.Id);
            }
        }
        if (!trCaseIds.isEmpty()) {
            CDdGenericPlatformEventHelper.publishEvents(
                CDdGenericPlatformEventHelper.PlatformEventType.DELIVER_TABLET_MILESTONE, trCaseIds);
            ranUpdateDeliverTabletMilestone = true;
        }*/
    }

    /**
     * @author      Schubert Tonarelli
     * @date        2023-06-13
     * @jira        https://doordash.atlassian.net/browse/BASD-49578
     * @description Stop the process of creation of a case if SPAM references are founded
     */
    public static void processStopSpamCase( List<Case> newCaseList){

        List<Stop_Spam_Case_Reference__c> referenceList = CdStopSpamCaseReferenceService.getCachedStopSpamCaseReference();

        for( Case c : newCaseList ){
            for( Stop_Spam_Case_Reference__c ref : referenceList ){

                if( c.get(ref.Field__c) != NULL && (
                       		ref.Operator__c == 'contains' && String.valueOf(c.get(ref.Field__c)).containsIgnoreCase( ref.Value__c )
                       		|| ( ref.Operator__c == '=' && String.valueOf(c.get(ref.Field__c)) == ref.Value__c ) )

                ){
                	c.addError( THIS_IS_SPAM_CASE_MSG );
                }
            }
        }
    }

    /**
     * @author      Srikant Matety
     * @date        07-19-2023
     * @jira        https://doordash.atlassian.net/browse/BASD-51546
     * @description Block Users From Deleting the Cases.
     */
    public static void processDeleteCase( List<Case> oldCaseList) {
        if (CDdCustomMetaData.isDisabled('CDdCaseTriggerHelper_processDeleteCase')) {
            return;
        }
        // get the feature flag to check if users has access to delete case.
        Boolean allowcasedelete = CDdExperimentSvc.getSupportFeatureFlag('Allow_Case_Deletion__c');

        if(!allowcasedelete) {
            for(Case c : oldCaseList) {
                c.addError(CANNOT_DELETE_CASE);
            }
        }
    }

    /**
     * @author      Sriram
     * @date        Jan 2021
     * @jira        https://doordash.atlassian.net/browse/BZAP-9015
     * @description Process POS Integration Cases
     *              Platform Events are published to send emails if certain conditions are met
     */
    public static void processPOSCases(List<Case> newCaseList, Map<Id,Case> oldCaseMap) {
        // add feature flags
        if (CDdCustomMetaData.isDisabled('CDdCaseTriggerHelper_processPOSCases') || ranProcessPOSCases) {
            return;
        }

        Set<Id> posSupportRedirectCases = new Set<Id>();
        Set<Id> posPostActivationMarketplaceCases = new Set<Id>();

        Id posIntgRTId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeId('POS Integrations');

        for (Case currCase : newCaseList) {
            if (currCase.RecordtypeId == posIntgRTId){
                Case oldCase = oldCaseMap != null ? oldCaseMap.get(currCase.Id) : null;
                if ((oldCase != null)
                        && (oldCase.Last_Email_from_Customer__c != null)
                        && isNewOrFieldUpdated(currCase, oldCaseMap, 'Last_Email_from_Customer__c')
                        && (oldCase.Last_Email_from_Customer__c < DateTime.now().addHours(12 * -1))
                        && ('Closed'.equals(currCase.status))){
                    posSupportRedirectCases.add(currCase.Id);
                }
                if (isNewOrFieldUpdated(currCase, oldCaseMap, 'Activation_Date__c')
                        && ('Solved'.equals(currCase.status))
                        && currCase.Activation_Date__c != null) {
                    posPostActivationMarketplaceCases.add(currCase.Id);
                }
            }
        }
        if(!posSupportRedirectCases.isEmpty()) {
            CDdGenericPlatformEventHelper.publishEvents(
                CDdGenericPlatformEventHelper.PlatformEventType.CASE_SEND_EMAIL_POS_SUPPORT_REDIRECT, posSupportRedirectCases);
            ranProcessPOSCases = true;
        }
        if(!posPostActivationMarketplaceCases.isEmpty()) {
            CDdGenericPlatformEventHelper.publishEvents(
                CDdGenericPlatformEventHelper.PlatformEventType.CASE_SEND_EMAIL_POS_POST_ACTIVATION_MARKETPLACE, posPostActivationMarketplaceCases);
            ranProcessPOSCases = true;
        }
    }

    /**
     * @author      Jeegar
     * @date        2021-03
     * @description This method processes cases that are sendbird cases. It will check if the case status / owner has changed
     *              if changed, it sends an API callout to ERS endpoint so that the chat room is closed.
     * @param       List<Case> newCases, Map<Id, Case> oldMap
     * @return      void
     * @Update      2023-02 : jeegar: Added check for THQ cases "shouldSendTHQAlert()"
    */
    public static void processNonChatCasesForTHQ(List<Case> newCases) {
        // create a new flag for Phone cases / THQ features;
        if(ranprocessNonChatCasesForTHQ || CDdExperimentSvc.getSupportFeatureFlag('Disable_THQ_Callouts__c')) {
            return;
        }
        Sendbird_Settings__c sendbirdSettings = CDdSendBirdAPIHandler.sendbirdSettings;
        List<Case> nonChatCasesToProcess = new List<Case>();
        for(Case currCase : newCases) {
            if(shouldSendTHQAlert(currCase, null)) {
                nonChatCasesToProcess.add(currCase);
            }
        }
        if(nonChatCasesToProcess.size() > 0 ) {
            notifyTHQ(nonChatCasesToProcess, null);

            if (sendbirdSettings != null && !sendbirdSettings.Recursive_Case_Update__c) {
                //if recursion is disabled in custom settings, set flag to true - this will avoid recursion
                ranprocessNonChatCasesForTHQ = true;
            }
        }


    }
    /**
     * @author      Jeegar
     * @date        2021-03
     * @description This method processes cases that are sendbird cases. It will check if the case status / owner has changed
     *              if changed, it sends an API callout to ERS endpoint so that the chat room is closed.
     * @param       List<Case> newCases, Map<Id, Case> oldMap
     * @return      void
     * @Update      2023-02 : jeegar: Added check for THQ cases "shouldSendTHQAlert()"
     */
    public static void processSendbirdChats(List<Case> newCases, Map<Id, Case> oldMap) {

        if(ranprocessSendbirdChats || !CDdExperimentSvc.getSupportFeatureFlag('Enable_Sendbird_API_Callouts__c')) {
            return;
        }
        Sendbird_Settings__c sendbirdSettings = CDdSendBirdAPIHandler.sendbirdSettings;
        Case oldCase;
        List<Case> sendbirdCasesToProcess = new List<Case>();
        for(Case currCase : newCases) {
            oldCase = oldMap.get(currCase.Id);

            // put it behind a flag and check that in the method.
            if((isSendbirdCase(currCase.Origin, currCase.Channel__c, currCase.RecordTypeId)
                    || shouldSendTHQAlert(currCase, oldCase))
                && (isFieldUpdated(currCase,oldMap,'OwnerId') || isFieldUpdated(currCase,oldMap,'Status'))) {

                sendbirdCasesToProcess.add(currCase);
            }
        }
        if(sendbirdCasesToProcess.size() > 0 ) {
            notifyTHQ(sendbirdCasesToProcess, oldMap);
        }

        if (sendbirdSettings != null && !sendbirdSettings.Recursive_Case_Update__c) {
            //if recursion is disabled in custom settings, set flag to true - this will avoid recursion
            ranprocessSendbirdChats = true;
        }
    }
    /**
     * @author
     * @date
     * @description this method notifiy THQ about changes to a case.
     * @Change Log
     * April 3      Jeegar      Removed Mulesoft PE.
     *                          Added logic to use future method without platform event.
     */
    public static void notifyTHQ(List<Case> casesToProcess, Map<Id,Case> oldMap) {

        List<Sendbird_Chat_Event__e> sendbirdChatEvents = new List<Sendbird_Chat_Event__e>();
        List<Sendbird_Mulesoft_Chat_Event__e> sendbirdMulesoftChatEvents = new List<Sendbird_Mulesoft_Chat_Event__e>();
        // adding logging
        Boolean shouldLog = ApiLoggerServiceImplHelper.shouldLog('Sendbird');
        List<API_Log__c> apiLogsToInsert = new List<API_Log__c>();
        API_Log__c tempLog;
        Sendbird_Chat_Event__e tempChatEvent;

        // Jeegar : April 2023 :
        // use future methods without platform events.

        Boolean sendbirdUseFutureMethod = CDdExperimentSvc.getSupportFeatureFlag('Sendbird_Use_Future_Method__c');
        List<CDdSupportHelper.SendBirdChatEventWrapper> sbeWrappers = new List <CDdSupportHelper.SendBirdChatEventWrapper>();
        CDdSupportHelper.SendBirdChatEventWrapper tempSBEWrapper;

        Case oldCase;
        if(!casesToProcess.isEmpty()) {
            List<Case> casesWithOwnerFirstName =
                [SELECT Id, ChatKey__c, Origin, OwnerId, Owner.FirstName, RecordTypeId, Status, Chat_Escalation_Id__c
                FROM Case
                WHERE Id in: casesToProcess];
            for (Case caseToPublish: casesWithOwnerFirstName) {
                oldCase = null;
                if(oldMap != null) {
                    oldCase = oldMap.get(caseToPublish.id);
                }
                if(sendbirdUseFutureMethod) {
                    tempSBEWrapper = new CDdSupporthelper.SendBirdChatEventWrapper(
                        caseToPublish, oldCase,
                        CDdSupporthelper.findIfRealTime(String.valueOf(caseToPublish.OwnerId)));
                    sbeWrappers.add(tempSBEWrapper);

                    if(shouldLog) {
                        tempLog = new API_Log__c();
                        tempLog.Calling_Code__c = 'notifyTHQ - FM';
                        tempLog.Related_To_Id__c = caseToPublish.id;
                        tempLog.Related_To_Owner_Id__c = caseToPublish.ownerId;
                        tempLog.Request__c = JSON.serialize(tempSBEWrapper);
                        apiLogsToInsert.add(tempLog);
                    }

                } else{

                    tempChatEvent = CDdSupportHelper.createSendbirdEvent(caseToPublish, oldcase);
                    sendbirdChatEvents.add(tempChatEvent);
                    // adding logging, not relying on framework to insert because I want to check if there are any drops in platform events.
                    // inserts on apiLogs should be trivial because there are no triggers on the object.
                    if(shouldLog) {
                        tempLog = new API_Log__c();
                        tempLog.Calling_Code__c = 'notifyTHQ - PE';
                        tempLog.Related_To_Id__c = caseToPublish.id;
                        tempLog.Related_To_Owner_Id__c = caseToPublish.ownerId;
                        tempLog.Request__c = String.valueOf(tempChatEvent);
                        apiLogsToInsert.add(tempLog);
                    }
                }
            }
        }
        try {
            if(!sbeWrappers.isEmpty()){
                CDdSendbirdChatEventTriggerHelper myHelper = new CDdSendbirdChatEventTriggerHelper();
                myhelper.processSendbirdChatsByFutureMethod(sbeWrappers);
            }

            if(!sendbirdChatEvents.isEmpty()) {
                List<Database.SaveResult> saveResults = EventBus.publish(sendbirdChatEvents);
                CDdErrorUtilities.publishException(CDdSupportConstants.CASE_OBJECT_LABEL , 'processSendbirdChats', saveResults);
            }
            if(!sendbirdMulesoftChatEvents.isEmpty()) {
                List<Database.SaveResult> saveResults = EventBus.publish(sendbirdMulesoftChatEvents);
                CDdErrorUtilities.publishException(CDdSupportConstants.CASE_OBJECT_LABEL , 'processMulesoftSendbirdChats', saveResults);
            }
        } catch (Exception ex) {
            CDdErrorUtilities.publishException('CDdCaseTriggerHelperV2', 'notifyTHQ', ex);
            throw ex;
        } finally {
            if(shouldLog) {
                List<Database.SaveResult> apiLogsInsertResult  = Database.Insert(apiLogsToInsert);
                CDdErrorUtilities.publishException(CDdSupportConstants.CASE_OBJECT_LABEL , 'processSendbirdChats-APILOG', apiLogsInsertResult);
            }
        }


    }

    /**
     * @author      Jeegar
     * @date        2021-03
     * @description Checks if this is a sendbird case.
     *              If Recordtype = 'Support' AND Origin = 'Chat' AND Channel__c = 'DoorDash App - Sendbird'
     *              then the case is a sendbird case.
     * @param       String origin
     *              String channel
     *              Id recordTypeId
     * @return      boolean
     */
    public static boolean isSendbirdCase(String origin, String channel, Id recordTypeId) {
        return String.isNotBlank(origin) && String.isNotBlank(channel)
            && recordTypeId == CDdGenericTriggerOptimizationHelper.supportRecordTypeId
            && origin.equalsIgnoreCase(CDdSupportConstants.CASE_ORIGIN_CHAT)
            && channel.equalsIgnoreCase(CDdSupportConstants.CASE_CHANNEL_CHAT_SENDBIRD);
    }


    public static void createPhotoshootCaseOnMenuChange(List<Case> newCaseList, Map<Id,Case> oldCaseMap) {
        Id marketPlaceRTId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeId(CDdSupportConstants.RECORDTYPE_NAME_MARKETPLACE_ONBOARDING);
		Id caviarOnboardingRTId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeId(CDdSupportConstants.RECORDTYPE_NAME_CAVIAR_ONBOADING);

        Map<Id,Account> accMap = CDdCaseTriggerOptimizationHelper.getAccountMap();
        Map<Id,Opportunity> oppMap = CDdCaseTriggerOptimizationHelper.getOpportunityMap();

        List<Case> ocusCasesToBeCreated = new List<Case>();
        Set<Id> oppIdsForPhotoshootCase = new Set<Id>();

        for(Case caseRec : newCaseList){

            Account acc = accMap.containsKey(caseRec.AccountId) ? accMap.get(caseRec.AccountId) : null;
            Opportunity opp = oppMap.containsKey(caseRec.Opportunity_Name__c) ? oppMap.get(caseRec.Opportunity_Name__c) : null;
            Boolean isPassCountryCriteria = acc != null && CDdOCUSAPIConstants.OCUS_COUNTRY_CODES.contains(acc.BillingCountryCode);
            Boolean isPassSubmarketCriteria = acc != null && CDdOCUSAPIConstants.OCUS_SUBMARKET_ENABLED_COUNTRY_CODES.contains(acc.BillingCountryCode) &&
                acc?.RealZip__RealZip__r?.Submarket_lookup__r?.Photoshoot_Vendor__c == CDdOCUSAPIConstants.OCUS;
            Boolean isPassCaviarCriteria = acc != null && CDdOCUSAPIConstants.OCUS_CAVIAR_ENABLED_COUNTRY_CODES.contains(acc.BillingCountryCode) &&
                opp != null && (opp.Platform__c == 'Caviar' || opp.Platform__c == 'Caviar and DoorDash');

            if((caseRec.RecordtypeId == marketPlaceRTId || (caseRec.RecordtypeId == caviarOnboardingRTId && isPassCaviarCriteria)) &&
                String.isNotBlank(caseRec.Menu_Preview_Links__c) &&
                isFieldUpdated(caseRec, oldCaseMap, 'Menu_Preview_Links__c') &&
                acc != null && opp != null &&
                !acc.PhotoshootCaseCreated__c &&
                opp.Mx_Requesting_Photoshoot__c != null &&
                opp.Mx_Requesting_Photoshoot__c.equalsIgnoreCase(CDdCoreConstants.STRING_YES) &&
                (String.isBlank(acc.Business_Vertical__c) || acc.Business_Vertical__r.Menu_UI_Type__c == CDdSupportConstants.BUSINESS_VERTICAL_RESTAURANT)){

                    if(isPassCountryCriteria || isPassSubmarketCriteria){
                        ocusCasesToBeCreated.add(caseRec);
                    }else if(isSnapperPhotoshootConditionMatch(opp, acc)){
                        oppIdsForPhotoshootCase.add(opp.Id);
                    }
            }
        }

        if(!ocusCasesToBeCreated.isEmpty()){
            createPhotoshootCaseForIntnl(ocusCasesToBeCreated);
        }

        if(!oppIdsForPhotoshootCase.isEmpty()){
            CDdGenericPlatformEventHelper.publishEvents(CDdGenericPlatformEventHelper.PlatformEventType.PHOTOSHOOT_CASE, oppIdsForPhotoshootCase);
        }
    }

    private static Boolean isSnapperPhotoshootConditionMatch(Opportunity opp, Account acc){
        if (opp.RecordTypeId == CDdGenericTriggerOptimizationHelper.getOpportunityRecordTypeIdByDevName(CDdOpportunityConstants.RECORD_TYPE_OPPORTUNITY_DEV_NAME_MARKETPLACE)
            && opp.Type != CDdOpportunityConstants.OPPORTUNITY_TYPE_NEW_NIMDA_OLD_MENU
            && opp.Type != CDdOpportunityConstants.OPPORTUNITY_TYPE_NEW_NIMDA_NEW_MENU
            && acc.RealZip__RealZip__c != null
            && acc.RealZip__RealZip__r.Submarket_lookup__c != null
            && acc.RealZip__RealZip__r.Submarket_lookup__r.Region__c != null
            && opp.Platform__c != CDdSupportConstants.LEAD_PLATFORM_CAVIAR
            && ((!CDdI18nUtility.isCountryJAPAN(acc.BillingCountryCode) && !CDdI18nUtility.isCountryGermany(acc.BillingCountryCode) && !CDdI18nUtility.isCountryCANADA(acc.BillingCountryCode) && !CDdI18nUtility.isCountryUSA(acc.BillingCountryCode)) ||
                (CDdI18nUtility.isCountryCANADA(acc.BillingCountryCode) && acc.RealZip__RealZip__r.Submarket_lookup__r.Photoshoot_Vendor__c == CDdOpportunityConstants.PHOTOSHOOT_VENDOR_SNAPPR) ||
                (CDdI18nUtility.isCountryUSA(acc.BillingCountryCode) && acc.RealZip__RealZip__r.Submarket_lookup__r.Photoshoot_Vendor__c == CDdOpportunityConstants.PHOTOSHOOT_VENDOR_SNAPPR))) {
                return true;
        }
        return false;
    }

    public static void createPhotoshootCaseForIntnl(List<Case> caseList){
        List<Case> newPhotoshootCaseList = new List<Case>();

        Map<Id,Account> accMap = CDdCaseTriggerOptimizationHelper.getAccountMap();
        Map<Id,Opportunity> oppMap = CDdCaseTriggerOptimizationHelper.getOpportunityMap();

        BusinessHours defaultbusinessHours = CDdGenericTriggerOptimizationHelper.getDefaultBusinessHour();

        Id photoshootRecordTypeId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeIdByDevName('Photoshoot_Processing');

        for (Case onboardingCase : caseList){
            Account acc = accMap.get(onboardingCase.AccountId);
            Opportunity opp = oppMap.get(onboardingCase.Opportunity_Name__c);

            Case newCase = new Case();
            newCase.BusinessHoursId = defaultbusinessHours.Id;
            newCase.AccountId = onboardingCase.AccountId;
            newCase.ContactId = opp.Decision_Maker__c;
            newCase.Language__c = opp.Preferred_Language__c;
            newCase.Opportunity_Name__c = onboardingCase.Opportunity_Name__c;
            newCase.Origin = 'Photoshoot Request';
            newCase.Photo_Provider__c = 'OCUS';
            newCase.Priority = 'Medium';
            newCase.RecordTypeId = photoshootRecordTypeId;
            newCase.Menu_Preview_Links__c = onboardingCase.Menu_Preview_Links__c;
            //BASD-42481 Adding Photoshoot_date__c and Photoshoot_Time__c mapping
            newCase.Photoshoot_Date__c = opp.Photoshoot_Date__c;
            newcase.Photoshoot_Time__c = opp.Photoshoot_Time__c;

            if (acc.BillingCountryCode == 'JP'){
                newCase.OwnerId = CDdGenericTriggerOptimizationHelper.getQueueIdByDevName('Photoshoot_cases_Japan_OCUS');
                newCase.Return_Shipping_Address_Street__c = acc.Kanji_Street__c;
                newCase.Return_Shipping_Address_City__c = acc.Kanji_City__c;
                newCase.Return_Shipping_Address_State__c = acc.Kanji_State__c;
                newCase.Shipping_Address_Country__c = acc.Kanji_Country__c;
                newCase.Return_Shipping_Address_Zip__c = acc.Kanji_Zip__c;
                newCase.Return_Shipping_Address_Suite_Apt_etc__c = acc.Kanji_Address2__c;
            } else {
                if(CDdI18nUtility.isCountryCANADA(acc.BillingCountryCode)) {
                    newCase.OwnerId = CDdGenericTriggerOptimizationHelper.getQueueIdByDevName('Photoshoot_cases_Canada_OCUS');
                } else if(CDdI18nUtility.isCountryGermany(acc.BillingCountryCode)) {
                    newCase.OwnerId = CDdGenericTriggerOptimizationHelper.getQueueIdByDevName('Photoshoot_cases_Germany_OCUS');
                } else if(CDdI18nUtility.isCountryUSA(acc.BillingCountryCode)){
                    if(CDdI18nUtility.isStatePR(acc.BillingState)){
                       newCase.OwnerId = CDdGenericTriggerOptimizationHelper.getQueueIdByDevName('Photoshoot_cases_PR_OCUS');
                    } else if((opp.Platform__c == 'Caviar' || opp.Platform__c == 'Caviar and DoorDash') &&
                              (opp.DRN__c == 'Ace' || opp.DRN__c == 'King' || opp.DRN__c == 'Ace of Spades' || opp.DRN__c == 'King of Spades')){
                       newCase.OwnerId = CDdGenericTriggerOptimizationHelper.getQueueIdByDevName('Photoshoot_cases_caviar_US_OCUS');
                    } else {
                       newCase.OwnerId = CDdGenericTriggerOptimizationHelper.getQueueIdByDevName('Photoshoot_cases_US_OCUS');
                    }
                }
                if(acc != null) {
                    newCase.Photo_Review_Notes__c = acc.Notes__c;
                    newCase.Return_Shipping_Address_Street__c = acc.BillingStreet;
                    newCase.Return_Shipping_Address_City__c = acc.BillingCity;
                    newCase.Return_Shipping_Address_State__c = acc.BillingState;
                    newCase.Shipping_Address_Country__c = acc.BillingCountry;
                    newCase.Return_Shipping_Address_Zip__c = acc.BillingPostalCode;
                    newCase.Return_Shipping_Address_Suite_Apt_etc__c = acc.Address2__c;
                }
            }

            newCase.Status = 'Open';
            newPhotoshootCaseList.add(newCase);

            CDdCaseTriggerOptimizationHelper.setSobjectToUpdate('Account',acc.Id,'PhotoshootCaseCreated__c',true);
        }
        if (!newPhotoshootCaseList.isEmpty()) {
            CDdCaseTriggerOptimizationHelper.setSObjectToInsert('Case',newPhotoshootCaseList);
        }
    }

    public static void updateSalesNotesOnOCUSPortal(List<Case> newCaseList, Map<Id,Case> oldCaseMap) {
        if (ranUpdateSalesNotesOnOCUSPortal) return;

        Id photoshootRecordTypeId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeIdByDevName('Photoshoot_Processing');
        Map<Id,Account> accMap = CDdCaseTriggerOptimizationHelper.getAccountMap();

        Set<Id> caseIdSet = new Set<Id>();

        for(Case caseRec : newCaseList) {
            Account acc = accMap.containsKey(caseRec.AccountId) ? accMap.get(caseRec.AccountId) : null;
            Boolean isPassCountryCriteria = acc != null && CDdOCUSAPIConstants.OCUS_COUNTRY_CODES.contains(acc.BillingCountryCode);
            Boolean isPassSubmarketCriteria = acc != null && CDdOCUSAPIConstants.OCUS_SUBMARKET_ENABLED_COUNTRY_CODES.contains(acc.BillingCountryCode) &&
                acc?.RealZip__RealZip__r?.Submarket_lookup__r?.Photoshoot_Vendor__c == CDdOCUSAPIConstants.OCUS;
            if(caseRec.Kodakit_Job_Id__c != null &&
                caseRec.RecordtypeId == photoshootRecordTypeId &&
                (isPassCountryCriteria || isPassSubmarketCriteria) &&
                (isFieldUpdated(caseRec, oldCaseMap, 'Menu_Preview_Links__c') ||
                isFieldUpdated(caseRec, oldCaseMap, 'Photo_Review_Notes__c'))
            ){
                caseIdSet.add(caseRec.Id);
            }
        }
        if (caseIdSet.size() > 0){
            CDdOCUSAPIHandler.handleOCUSPhotoshoot(caseIdSet,false);
        }
    }

    /**
     * @author      Mahesh Chouhan
     * @date        Dec 2021
     * @jira        https://doordash.atlassian.net/browse/BIZS-835
     * @description Prevent MXP to close Case if Reopen Reason is blank
     *              Allow Case status changes for Merchant Support cases only if Reopened Date has value and status is not closed
     */
    public static void preventCaseClosingWithoutReopenReasonForMxp(List<Case> newCaseList, Map<Id,Case> oldCaseMap) {
        Set<Id> mxpAccountIds = new Set<Id>();
        Set<String> closeCaseStatus = new Set<String>{CDdSupportConstants.CLOSED_STATUS, CDdSupportConstants.SOLVED_STATUS};
        List<Case> casesToProcess = new List<Case>();

        for(Case cs : newCaseList){
            Boolean missingReopenReason = preventCaseClosingWithoutReopenReasonForMxp_MissingReopenReason(cs,oldCaseMap,closeCaseStatus);
            Boolean invalidStatusChange = preventCaseClosingWithoutReopenReasonForMxp_InvalidStatusChange(cs,oldCaseMap);

            if (cs.AccountId != null && (missingReopenReason || invalidStatusChange)) {
                mxpAccountIds.add(cs.AccountId);
                casesToProcess.add(cs);
            }
        }

        if (casesToProcess.isEmpty()) return;

        List<AccountTeamMember> mxpTeamMembers = [SELECT UserId, AccountId
                                                  FROM AccountTeamMember
                                                  WHERE TeamMemberRole = :CDdSupportConstants.MXP_ROLE_NAME AND AccountId IN :mxpAccountIds];

        Map<Id, Set<Id>> mxpUserMap = new Map<Id, Set<Id>>();
        for(AccountTeamMember mxp : mxpTeamMembers){
            if(!mxpUserMap.containsKey(mxp.AccountId)){
                mxpUserMap.put(mxp.AccountId, new Set<Id>());
            }
            mxpUserMap.get(mxp.AccountId).add(mxp.UserId);
        }

        for(Case cs : casesToProcess){
            Boolean missingReopenReason = preventCaseClosingWithoutReopenReasonForMxp_MissingReopenReason(cs,oldCaseMap,closeCaseStatus);
            Boolean invalidStatusChange = preventCaseClosingWithoutReopenReasonForMxp_InvalidStatusChange(cs,oldCaseMap);

            Boolean isAccountMxp = mxpUserMap.containsKey(cs.AccountId) && mxpUserMap.get(cs.AccountId).contains(UserInfo.getUserId());
            Boolean isCurrentCaseOwnerMxp = mxpUserMap.containsKey(cs.AccountId) && mxpUserMap.get(cs.AccountId).contains(cs.OwnerId);

            if (isAccountMxp && missingReopenReason && isCurrentCaseOwnerMxp) {
               cs.addError(REOPEN_REASON_ERROR_MESG);
            }

            if (isAccountMxp && invalidStatusChange){
                cs.addError(CASE_STATUS_UPDATE_NOT_ALLOWED_ERROR_MESG);
            }
        }
    }

    private static Boolean preventCaseClosingWithoutReopenReasonForMxp_MissingReopenReason(Case cs, Map<Id,Case> oldCaseMap, Set<String> closeCaseStatus) {
        return (oldCaseMap.get(cs.Id).Status == CDdSupportConstants.REOPEN_STATUS &&
            closeCaseStatus.contains(cs.Status) &&
            String.isBlank(cs.Reopen_Reason__c));
    }

    private static Boolean preventCaseClosingWithoutReopenReasonForMxp_InvalidStatusChange(Case cs, Map<Id,Case> oldCaseMap) {
        return isFieldUpdated(cs,oldcaseMap,'Status') &&
            cs.Customer_Type__c == CDdSupportConstants.CUSTOMER_TYPE_MERCHANT &&
            cs.RecordTypeId == CDdGenericTriggerOptimizationHelper.supportRecordTypeId &&
            cs.Reopened_Date__c != null &&
            cs.Status == CDdSupportConstants.CLOSED_STATUS &&
            cs.ParentId == null;
    }

    /**
     * @author      Sahil
     * @date        December 2021
     * @jira        https://doordash.atlassian.net/browse/BASD-16630
     * @description for mxp E2C, attach the most recently created contact and it's parent account with the case
    */
    public static void mxpE2CAttachContact(List<Case> newCaseList) {
        //feature flag
        if (!CDdExperimentSvc.getSupportFeatureFlag('MXP_Support_E2C_Linking__c')) {
            return;
        }
        try {
            List<String> suppEmailList = new List<String>();
            Map<String,Contact> caseEmailToContactMap = new Map<String,Contact>();
            List<Case> casesToUpdate = new List<Case>();
            //filter cases meeting the criteria, and get customer emails
            for (Case caseVar : newCaseList) {
                if (String.isNotBlank(caseVar.SuppliedEmail) && String.isNotBlank(caseVar.Priority)
                        && String.isNotBlank(caseVar.Origin) && caseVar.AccountId == null
                        && caseVar.ContactId == null && caseVar.Priority == CDdSupportConstants.MEDIUM_PRIORITY
                        && caseVar.Origin == CDdSupportConstants.ORIGIN_EMAIL_MXP
                    ) {
                    suppEmailList.add(caseVar.SuppliedEmail.toLowerCase());
                    casesToUpdate.add(caseVar);
                }
            }
            if (suppEmailList.isEmpty()) {
                return;
            }

            CDdCaseTriggerOptimizationHelper.setContactMap(suppEmailList);
            Map<String,List<Contact>> contactByEmailMap = CDdCaseTriggerOptimizationHelper.getContactByEmailMap();

            for (Case caseVar : casesToUpdate) {
                if (!contactByEmailMap.containsKey(caseVar.SuppliedEmail.toLowerCase())) {
                    continue;
                }
                List<Contact> contacts = contactByEmailMap.get(caseVar.SuppliedEmail.toLowerCase());
                List<Contact> contactsToCheck = new List<Contact>();
                for (Contact c : contacts) {
                    if (!c.IsPersonAccount && c.AccountId != null && !c.Account.IsPersonAccount) {
                        contactsToCheck.add(c);
                    }
                }
                if (contactsToCheck.isEmpty()) {
                    return;
                }
                Contact c = CDdCaseTriggerOptimizationHelper.getLastContactByDate(contactsToCheck,'CreatedDate');
                caseVar.AccountId = c.AccountId;
                caseVar.ContactId = c.Id;
            }
        } catch (Exception e) {
            CDdErrorUtilities.publishException('CDdCaseTriggerHelperV2','mxpE2CAttachContact', e);
        }
    }
    /**
     * @author      Sriram
     * @date        Dec 2021
     * @jira        https://doordash.atlassian.net/browse/BZAP-12797
     * @description On a POS Integration Case, associate Partner Integration record that corresponds to POS Integration Type Value
     */
    public static void associatePartnerIntegrationRecord(List<Case> cases, Map<Id, Case> oldCaseMap){
        if (CDdCustomMetaData.isDisabled('CDdCaseTriggerHelper_assocPartnerIntegration') || ranAssociatePartnerIntegrationRecord) {
            return;
        }

        Map<Id, Account> caseAccountMap = CDdCaseTriggerOptimizationHelper.getAccountMap();

        List<Case> casesToProcess = new List<Case>();
        for (Case c : cases){
            if (CDdMxSxCaseHelper.PARTNER_INTEGRATION_ASSOC_CASE_RECORD_TYPES.contains(c.RecordTypeId)){
                if( isNewOrFieldUpdated(c, oldCaseMap, 'POS_Integration_Type__c') ){
                    casesToProcess.add(c);
                }
            }
        }
        if (!casesToProcess.isEmpty()) {
            CDdMxSxCaseHelper.associatePartnerIntegrationRecord(casesToProcess, caseAccountMap);
            ranAssociatePartnerIntegrationRecord = true;
        }
    }

    /**
    * @author      Nayana
    * @date        Jan 2022
    * @jira        https://doordash.atlassian.net/browse/BIZS-676
    * @description Removing logic from Reopen to MxSx - Mx Success Associate wf rule and handling Mxp Reopen scenario(By an agent/By customer)
    */
    public static void processMxPReopenCases(List<Case> newCaseList,Map<Id,Case> oldCaseMap) {
        //check if feature is enabled
        if (CDdCustomMetaData.isDisabled('CDdCaseTriggerHelper_processMxPReopen')){
          return;
        }
        List<Case> mxpCases = new List<Case>();
        //check if case status is changed and it is reopened and if case is Mxp Case
        for (Case CaseObj : newCaseList) {
            if (CaseObj.Case_Routing_Override__c == CDdSupportConstants.QUEUE_MX_SUCCESSASSOCIATE &&
                isFieldUpdated(CaseObj,oldCaseMap,'Status') && CaseObj.Status == CDdSupportConstants.REOPEN_STATUS &&
                CaseObj.Issue__c != CDdSupportConstants.ISSUE_CHARGEBACK_DISPUTE ) {
                //call metadata framework to check routing criteria based on case data
                CDdIssueBasedRoutingHelper.RoutingInfo routingInfo =
                CDdIssueBasedRoutingHelper.getRoutingInfo(CaseObj);
                if(routingInfo.routingDestination == CDdSupportConstants.MX_SUCCESS_ASSOCIATE){
                    mxpCases.add(CaseObj);
                }
            }
        }
        //If Mxp cases then check ATM/if not then assign Mx Success Assosciate queue
        if(!mxpCases.isEmpty()){
            CDdAcctTeamMemberReopenHandler atmHandler = new CDdAcctTeamMemberReopenHandler();
            atmHandler.reopenHandler(mxpCases);
        }
    }

     /**
    * @author      Nayana Kapse
    * @date        Dec 2021
    * @jira        https://doordash.atlassian.net/browse/BIZS-833
    * @description This is moved from Post-Sale Handoff- Rejected PB
    */
    public static void postHandOffRecordType(List<Case> newCaseList, Map<Id,Case> oldCaseMap) {
        if (CDdCustomMetaData.isDisabled('CDdCaseTriggerHelper_postHandOffRD')){
            return;
        }
        String onboardingManagerHandoffRTId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeId(CDdSupportConstants.RECORDTYPE_ONBOARDING_MGR_HANDOFF);

        String postHandOffOwnerIdVal = Label.Post_Sale_Handoff_PB_OwnerIds;
        Set<String> seOwnerIds = String.isNotBlank(postHandOffOwnerIdVal) ? new Set<String>(postHandOffOwnerIdVal.split(CDdCoreConstants.DELIMITER_SEMICOLON)): new Set<String>();

        Id pmQueueId = CDdGenericTriggerOptimizationHelper.getQueueIdByName(QUEUE_PM_QUEUE);

        Case oldCase = new Case();
        Map<Id,Opportunity> oppMap = CDdCaseTriggerOptimizationHelper.getOpportunityMap();
        Map<Id,Account> accMap = CDdCaseTriggerOptimizationHelper.getAccountMap();

        for(Case c : newCaseList){
            Opportunity opp = oppMap.containsKey(c.Opportunity_Name__c) ? oppMap.get(c.Opportunity_Name__c) : null;
            Account acc = accMap.containsKey(c.AccountId) ? accMap.get(c.AccountId) : null;

            if (isFieldUpdated(c,oldCaseMap,'Status') && c.Status == CDdSupportConstants.STATUS_REQUEST_DENIED) {
                if (c.RecordTypeId == onboardingManagerHandoffRTId) {
                    if (opp != null) {
                        Map<String,Object> oppFieldsToUpdate = new Map<String,Object>{
                            'PB_WF_Flow_Ran__c' => ONBOARDING_MGR_PBRUN,
                            'Requesting_Account_Management__c' => REQUESTING_ACC_MGMT_UNMANGED
                        };

                        if (opp.AC_PB_Change__c) {
                            oppFieldsToUpdate.put('AC_PB_Change__c',false);
                            oppFieldsToUpdate.put('Activate_Centrally_2__c',CDdCoreConstants.STRING_YES);
                            oppFieldsToUpdate.put('Activate_Centrally_No_Validation__c',null);
                        }
                        CDdCaseTriggerOptimizationHelper.setSobjectToUpdate('Opportunity', opp.Id, oppFieldsToUpdate);
                    }

                    if (acc != null) {
                        CDdCaseTriggerOptimizationHelper.setSobjectToUpdate('Account',acc.Id,'Requesting_Account_Management__c',REQUESTING_ACC_MGMT_UNMANGED);
                    }
                }
            }
        }
    }

    /**
     * @author      Mahesh
     * @date        Jan 2021
     * @jira        https://doordash.atlassian.net/browse/BASD-18394
     * @description Assign Japan Reopen cases to Tokyo Escalations Queue
     */
    public static void reopenJapanCasesToTokyoEscalations(List<Case> cases, Map<Id, Case> oldCaseMap){
        for(Case cs : cases){
            if(isFieldUpdated(cs, oldCaseMap, 'Status')
               && cs.Country__c == CDdSupportConstants.COUNTRY_NAME_JAPAN
               && cs.Status == CDdSupportConstants.REOPEN_STATUS
               && cs.Origin == CDdSupportConstants.CASE_ORIGIN_PHONE){
                cs.OwnerId = CDdGenericTriggerOptimizationHelper.getQueueIdByName(QUEUE_TOKYO_ESCALATIONS);
            }
        }
    }

    /**
     * @author      Sharvani Sri
     * @date        Jan 2022
     * @jira        https://doordash.atlassian.net/browse/BASD-18658
     * @description If Case Owner is changed, then “Contract Verification Date” attributes must be cleared
     */
    public static void updateContractVerificationDate(List<Case> newCaseList,Map<Id,Case> oldCaseMap ) {
        String bulkUploadRequestRTId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeId(CDdSupportConstants.RECORDTYPE_NAME_BULK_UPLOAD_REQUEST);
        for(case caseRec: newCaseList){
            if(isFieldUpdated(caseRec, oldCaseMap, 'OwnerId') && caseRec.RecordTypeID == bulkUploadRequestRTId){
                caseRec.Contract_Verification_Date__c=null;
            }
        }
    }
    /**
    * @author      Abhijeet K
    * @date        Feb 2022
    * @jira        BZAP-13371
    * @description Default Shipping Type picklist update for NZ
    */
    public static void populateDefaultValues(List<Case> newCaseList, Map<Id,Case> oldCaseMap) {
        if(CDdCustomMetaData.isDisabled('CDdCaseTriggerHelper_populateDefaultValu')){
            return;
        }
        List<Case> casesToProcess = new List<Case>();
        for(Case caseObj:newCaseList) {
            if(CDdI18nUtility.isCountryNewZealand(caseObj.Shipping_Address_Country__c)) {
                casesToProcess.add(caseObj);
            }
        }
        if(!casesToProcess.isEmpty()) {
            CDdI18nDefaultValueMappingUtil.setDefaultValuesBasedOnCountry(casesToProcess, 'Shipping_Address_Country__c');
        }
    }

    /**
    * @author      Nayana Kapse
    * @date        Feb 2022
    * @jira        https://doordash.atlassian.net/browse/BIZS-1051
    * @description Auto creation of Case Shadow Object
    */
    public static void autoCaseShadowCreation(List<Case> newCaseList,Map<Id,Case> oldCaseMap) {
        if (CDdCustomMetaData.isDisabled('CDdCaseTriggerHelper_autoCaseShadowCreat')){
            return;
        }
        List<Case_Detail__c> lstCaseDetails = new List<Case_Detail__c>();
        for(Case caseObj:newCaseList){
            if(CDdCaseDetailCreationHelper.isAutoCreateShadowRecord(caseObj)){
                Case_Detail__c cDetail = new Case_Detail__c();
                cDetail.Case__c = caseObj.Id;
                cDetail.Case_Origin__c = caseObj.Origin;
                cDetail.Case_Customer_Type__c = caseObj.Customer_Type__c;
                CDetail.Case_RecordType__c = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeDevNameById(caseObj.RecordTypeId);
                CDetail.Case_Owner_ID__c = caseObj.OwnerId;
                lstCaseDetails.add(cDetail);
            }
        }
        if (!lstCaseDetails.isEmpty()){
            CDdGenericPlatformEventHelper.publishEvents(CDdGenericPlatformEventHelper.PlatformEventType.CASE_DETAIL_CREATION,
                                                        null,JSON.serialize(lstCaseDetails));
        }
    }

    /**
    * @author Sriram
    * @date 2022-03
    * @description Process Merchant Order
    */
    public static void processCasesForMxSx(List<Case> newCases, Map<Id,Case> oldCaseMap){
        if (CDdCustomMetaData.isDisabled('CDdCaseTriggerHelper_processCasesForMxSx')) { return; }
        CDdMxSxCaseHandler.processCasesForMxSx(newCases, oldCaseMap);
    }

    /**
    * @description Conversion of Case Claimed At Workflow
    * @author Jose Vega | 05-02-2022
    * @param List<Case> newCases
    * @param Map<Id Case> oldCaseMap
    **/
    public static void caseClaimedAt(List<Case> newCases, Map<Id,Case> oldCaseMap) {
        // (Case: Date/Time Case Claimed EQUALS null)
        // AND (Case: Case Origin NOT EQUAL TO Dasher Apply,Closed Won - New Mx Kit,Photoshoot Request,Photos Sent,Formstack)
        // AND (Case: Case Record Type NOT EQUAL TO Caviar Support,Caviar Onboarding)
        // Update Status
        // - Case:Status = Open
        // Update Date/Time Claimed
        // - Case: Date/Time Case Claimed = NOW()
        Set<String> ignoreRoutingDestination = new Set<String>{
            'Spam_Cases'
        };
        Set<String> origins = new Set<String>{
            CDdSupportConstants.ORIGIN_DASHER_APPLY,
            CDdSupportConstants.ORIGIN_PHOTOSHOOT_REQUEST,
            CDdSupportConstants.ORIGIN_PHOTOS_SENT,
            CDdSupportConstants.ORIGIN_FORMSTACK,
            CDdSupportConstants.ORIGIN_CLOSED_WON_NEW_MX_KIT
        };

        Set<Id> recordTypes = new Set<Id>{
            CDdGenericTriggerOptimizationHelper.caviarSupportRecordTypeId,
            CDdGenericTriggerOptimizationHelper.caviarOnboardingRecordTypeId
        };

        for(Case caseObj:newCases){
            if(caseObj.Case_Claimed__c == null &&
            !recordTypes.contains(caseObj.recordTypeId) &&
            !origins.contains(caseObj.Origin) &&
            !ignoreRoutingDestination.contains(caseObj.Routing_Destination__c)
            ){
                caseObj.Status = CDdSupportConstants.OPEN_STATUS;
                caseObj.Case_Claimed__c = System.Now();
            }
        }
    }

    /**
    * @description Conversion of Owned Case To Open At Workflow
    * For Talkdesk and Live Agent Chats to make cases Open, not New
    * @author Jose Vega | 05-02-2022
    * @param List<Case> newCases
    * @param Map<Id Case> oldCaseMap
    **/
    public static void ownedCaseToOpen(List<Case> newCases, Map<Id,Case> oldCaseMap) {
        //AND(
        //ISPICKVAL(Status,"New"),
        //Case_Record_Type__c = "Support",
        //LEFT(Owner:Queue.Id,3) <> "00G"
        //)
        // Status is Open
        // - Case:Status = Open
        if(RAN_OPEN_TO_NEW){
            return;
        }
        List<Case> casesToUpdate = new List<Case>();

        for(Case caseObj:newCases){
            if(caseObj.Status == CDdSupportConstants.NEW_STATUS &&
            (caseObj.Case_Record_Type__c == 'Support')
            && !String.valueOf(caseObj.OwnerId).startsWith('00G')){
                caseObj.Status = CDdSupportConstants.OPEN_STATUS;
            }
        }

        RAN_OPEN_TO_NEW = true;
    }

    /**
    * @description Conversion of Populate Date/Time Case Became Workable and Populate Date/Time Case Became Workable with Reopen Date At Workflow
    * BZAP-5334 - The Menu updates team uses this field for when a Case was
    * opened - they leave it editable in case they need to adjust it
    * (which you can't do with the standard Date/Time opened field). We are
    * populating it on creation so that it's consistent.
    * @author Jose Vega | 05-02-2022
    * @param List<Case> newCases
    * @param Map<Id Case> oldCaseMap
    **/
    public static void populateDateTimeCaseBecameWorkable(List<Case> newCases, Map<Id,Case> oldCaseMap) {
        // AND (ISBLANK( Date_Time_Case_Became_Workable__c ), RecordType.DeveloperName <> "Storefront_Onboarding" )
        // Update Case Date/Time Became Workable
        // - Case: Date/Time Case Became Workable = NOW()
        // PB/Workflow Date Case Became Workable
        // - Case: PB/WF/Flow Ran = "WF: Stamp Date Case Became Workable on Creation"
        Id menuUpdateRTId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeId('Menu Update');
        Id storeFrontRTId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeId(CDdSupportConstants.RECORDTYPE_NAME_STOREFRONT_ONBOARDING);
        Id bulkUploadRTId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeId(CDdSupportConstants.RECORDTYPE_NAME_BULK_UPLOAD_REQUEST);
        String weekEnds = System.Label.Menu_Update_Case_Weekends;
        List<String> spadeDeckRanks = new List<String>{CDdMxSxConstants.DECK_RANK_ACE_OF_SPADES,CDdMxSxConstants.DECK_RANK_KING_OF_SPADES};
        List<String> weekEndDays = new List<String>{'Friday','Sunday'};
        DateTime now = DateTime.now();
        String dayOfWeek;
        String dayFormat = 'EEEE';

        if(Test.isRunningTest()){
            dayOfWeek = weekEndDays[1];
        } else{
            dayOfWeek = now.format(dayFormat);
        }

        if(RAN_WORKABLE || CDdCustomMetaData.isDisabled('CDdCaseTriggerHelper_fillDateTimeWorkable')){
            return;
        }

        for(Case caseObj:newCases){
            if((caseObj.Date_Time_Case_Became_Workable__c == null && caseObj.RecordTypeId != storeFrontRTId && caseObj.RecordTypeId != menuUpdateRTId)
               || (oldCaseMap != null && caseObj.RecordTypeId == bulkUploadRTId && isNewOrFieldUpdated(caseObj, oldCaseMap, 'Status') && caseObj.Status == CDdSupportConstants.REOPEN_STATUS)){
                   caseObj.Date_Time_Case_Became_Workable__c = System.NOW();
               }

            //BASD-28353- If case got created/reopened after 4PM on friday then set Date/Time Case Became workable field to upcoming monday 7AM
            if(caseObj.RecordTypeId == menuUpdateRTId && (oldCaseMap == null || (oldCaseMap != null && isNewOrFieldUpdated(caseObj, oldCaseMap, 'Status') && caseObj.Status == CDdSupportConstants.REOPEN_STATUS))){
               if(((dayOfWeek == weekEndDays[0] && (now.hour() >= 16)) || weekEnds.contains(dayOfWeek))
                  && (spadeDeckRanks.contains(caseObj.Account_Deck_Rank__c) || spadeDeckRanks.contains(caseObj.Parent_Deck_Rank__c))){
                   if(dayOfWeek == weekEndDays[1]){
                       caseObj.Date_Time_Case_Became_Workable__c = DateTime.newInstance(Date.today().addDays(1),Time.newInstance(7, 0, 0, 0));
                   } else{
                       caseObj.Date_Time_Case_Became_Workable__c = DateTime.newInstance(Date.today().toStartofWeek().addDays(8),Time.newInstance(7, 0, 0, 0));
                   }
               } else{
                  caseObj.Date_Time_Case_Became_Workable__c = System.NOW();
                  }
             }
            RAN_WORKABLE = true;
        }
    }

    /**
    * @author      Jitendra Baghela
    * @date        April 2022
    * @jira        BZAP-14469
    * @description Attach Menus from Opportunity to Marketplace Onboarding case
    */
    public static void processAttachmentFromOpp(List<Case> newCases) {
        if(CDdCustomMetaData.isDisabled('CDdCaseTriggerHelper_processAttachmentFromOpp')){
            return;
        }
        String mpRTId = Schema.SObjectType.Case
                               .getRecordTypeInfosByName()
                               .get('Marketplace Onboarding')
                               .getRecordTypeId();

        Map<Id, Id> oppCaseMap = new Map<Id, Id> ();
        for (Case c : newCases){
            if(c.RecordTypeId == mpRTId && c.Opportunity_Name__c != null)
            {
                oppCaseMap.put(c.Opportunity_Name__c, c.Id);
            }
        }

        Map<Id, Id> contentDocumentIdOppIdMap = new  Map<Id, Id>();
        List<opportunity> oppList = [SELECT id, (SELECT id, ContentDocumentId FROM ContentDocumentLinks WHERE ContentDocument.Description = 'Menu' OR ContentDocument.Title like '%menu%')
                                     FROM Opportunity
                                     WHERE Id in :oppCaseMap.keyset() AND StageName = 'Closed Won'];

        List<ContentDocumentLink> cdlListToUpdate = new List<ContentDocumentLink>();
        for(opportunity opp :oppList)
        {
            for(ContentDocumentLink cdl : opp.ContentDocumentLinks)
            {
                Id caseId = oppCaseMap.get(opp.Id);
                ContentDocumentLink cdlCopy = new ContentDocumentLink(); // Content Document Link to share the file with Case record
                cdlCopy.LinkedEntityId = caseId; // Case ID
                cdlCopy.ContentDocumentId = cdl.ContentDocumentId; //Content Dcoument ID
                cdlCopy.ShareType = 'V';
                cdlCopy.Visibility = 'AllUsers';
                cdlListToUpdate.add(cdlCopy);
            }
        }
        if(cdlListToUpdate.size() > 0)
        {
            insert cdlListToUpdate; // Insert Content Document Link to share the file with cases.
        }
    }

    /**
    * @author      Mahesh Chouhan
    * @date        May 2022
    * @jira        BASD-27729
    * @description Create Closed Case for Offenders
    */
    public static void handleOffenders(List<Case> newCases) {
        try {
            List<Case> toProcess = new List<Case>();
            for (Case cse : newCases){
                if(cse.Customer_Segment__c == CDdSupportConstants.CUSTOMER_SEGMENT_OFFENDER){
                    toProcess.add(cse);
                }
            }

            if(toProcess.isEmpty()) {
                return;
            }

            for (Case cse : toProcess){
                cse.Status = CDdSupportConstants.CLOSED_STATUS;
                cse.Customer_Type__c = CDdSupportConstants.CUSTOMER_TYPE_MERCHANT;
                cse.Resolution_Type__c = CDdSupportConstants.RESOLUTION_TYPE_ACCOUNT_MANAGEMENT_MX;
                cse.Resolution__c = CDdSupportConstants.RESOLUTION_DIRECTED_TO_MX_PORTAL_T3;
                cse.Issue_Type__c = CDdSupportConstants.ISSUE_TYPE_PAY_MANAGEMENT_MX;
                cse.Issue__c = CDdSupportConstants.ISSUE_CHARGEBACK_DISPUTE;
                cse.Routing_Destination__c = CDdSupportConstants.CUSTOMER_SEGMENT_OFFENDER;
                cse.OwnerId = CDdCustomMetadata.getIdValueFor('Tools_Admin_User');
            }
        } catch (Exception ex) {
            CDdErrorUtilities.publishException('CDdCaseTriggerHelperV2','handleOffenders', ex);
        }
    }

    /**
     * @author      Mahesh Chouhan
     * @date        May 2022
     * @jira        https://doordash.atlassian.net/browse/BASD-30021
     * @description Prevent Invalid Escalations by Tx
     */
    public static void preventInvalidEsc(List<Case> newCaseList, Map<Id,Case> oldCaseMap){
        if(CDdCustomMetaData.isDisabled('CDdCaseTriggerHelper_preventInvalidEsc')){
            return;
        }

        if (CDdCaseTransferValidationHelper.BYPASS_CASE_TRANSFER_VALIDATION_FOR_THIS_TXN) {
            return;
        }

        //Key is Case record and Value is Validation Error
        Map<Case, String> toProcess = new Map<Case, String>();

        List<String> blockedIssues = new List<String>{CDdSupportConstants.ISSUE_UPDATE_EMAIL, CDdSupportConstants.ISSUE_UPDATE_PHONE};
        Set<Id> blockedQueueIds = new Set<Id>{
            CDdGenericTriggerOptimizationHelper.getQueueIdByDevName(QUEUE_SF_DASHER),
            CDdGenericTriggerOptimizationHelper.getQueueIdByDevName(QUEUE_CDMX_DASHER)
        };

        for (Case cse: newCaseList){
            //BASD-30021
            if(isFieldUpdated(cse, oldCaseMap, 'OwnerId') && blockedQueueIds.contains(cse.OwnerId) && String.isNotBlank(cse.Customer_Type__c) && cse.Customer_Type__c == CDdSupportConstants.CUSTOMER_TYPE_DASHER
                && blockedIssues.contains(cse.Issue__c)){
                toProcess.put(cse, System.Label.Case_Invalid_Escalation_Issue_Type);
            }
        }

        if(toProcess.isEmpty()){
            return;
        }

        for(Case cse : toProcess.keySet()) {
            cse.addError(toProcess.get(cse));
        }
    }

    /**
     * @date        April 2022
     * @jira        https://doordash.atlassian.net/browse/BIZS-961
     * @description calling dispatch for sendbird cases
     */
    public static void dispatchIfResponseIsPopulated(List<Case> newList) {
        if (!CDdExperimentSvc.getSupportFeatureFlag('Enable_Dispatch_for_Sendbird__c') ){
            return;
        }

        Dispatch_Settings__c apiSettings = Dispatch_Settings__c.getInstance();

        for(Case cObj : newList) {
            if ( String.isBlank(cObj.DispatchRQResponse__c)) {
                continue;
            }

            try {
                VDeliveryInformation res;

                if(apiSettings.Use_ERS_API__c){
                    List<VDeliveryInformation> response = CDdDispatchDeliveryInformation.deserialize(cObj.DispatchRQResponse__c);
                    res = response.isEmpty() ? null : response[0];
                }
                else {
                    res = VDeliveryInformation.deserialize(cObj.DispatchRQResponse__c);
                }

                if(res != null){
                    if(cObj.Customer_Type__c == CDdSupportConstants.CUSTOMER_TYPE_CONSUMER) {
                        res.liveAgentCustomerId = res.customerId;
                    } else if(cObj.Customer_Type__c == CDdSupportConstants.CUSTOMER_TYPE_DASHER) {
                        res.liveAgentDasherId = res.dasherId;
                    } else if(cObj.Customer_Type__c == CDdSupportConstants.CUSTOMER_TYPE_MERCHANT) {
                        res.liveAgentMerchantId = res.merchantId;
                    }

                    res.salesforceCase = cObj;
                    res.salesforceCase.DispatchRQStatus__c = 'Success';
                    res.salesforceCase = VDeliveryInformation.populateCustomerSegment(res, res.salesforceCase);

                    CDdDispatchRecordService svc = new CDdDispatchRecordService();
                    svc.upsertDeliveryInfo(new List<VDeliveryInformation> { res });
                }
                else {
                    throw new CDdException(Label.DispatchBlankSalesforceAudienceInfo);
                }
            }
            catch(Exception ex) {
                String dispatchException = ex.getMessage() +
                    ' Stack trace =  ' + ex.getStackTraceString();
                if(dispatchException.length() > 2047) {
                    dispatchException = dispatchException.substring(0,2027);
                }
                cObj.DispatchCalloutException__c = dispatchException;
                cObj.DispatchRQStatus__c = 'Failure';
                cObj.recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support').getRecordTypeId();
            }
        }
    }

    /**
     * @author      Sid Agarwal
     * @date        July 2022
     * @jira        https://doordash.atlassian.net/browse/BIZS-1478 - EPIC
     * @description Perform validations on Case 'Pending Reason' picklist field values
     */
    public static void validationsCasePendingReason(List<Case> newCaseList, Map<Id,Case> oldCaseMap)
    {
        // bypass validation for all profiles, using Batch_and_Trigger_Setting__mdt settings
        // bypass validation for logged in user's profile, using Validation_Bypass__c settings
        if (CDdCustomMetaData.isDisabled('CDdCaseTriggerHelper_validationsPendingReason') || Validation_Bypass__c.getInstance(UserInfo.getProfileId()).Bypass_Case_Validations__c) {
            return;
        }

        //get support record type
        Id supportRecordTypeId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeIdByDevName(CDdSupportConstants.RECORDTYPE_NAME_CUSTOMER);

        //build a list of cases which meet the criteria
        List<Case> tempCaseList = new List<Case>();
        Map<String,String> cacheKeySetMap = new Map<String,String>(); // key is cachekey, value is old case owner queue id

        // loop through incoming cases and perform custom validations
        for (Case caseVar : newCaseList)
        {
            if (caseVar.RecordtypeId == supportRecordTypeId && isFieldUpdated(caseVar, oldCaseMap, 'Pending_Reason__c') && String.isNotBlank(caseVar.Pending_Reason__c))
            {
                // validation 1: BIZS-1506 MxP Pending to Solve Automated Delay
                if (caseVar.Pending_Reason__c.equals(CDdSupportConstants.CASE_MXP_PENDING_REASON_SOLVE_WITH_DELAY)) {
                    // don't run on test classes, as the running user may not have required PSs / CPs
                    if(!test.isRunningTest() && !FeatureManagement.checkPermission(CDdCustomPermissionConstants.CASE_MXP_SOLVE_WITH_DELAY_PERM)) {
                        caseVar.addError(CDdNameValuePairHelper.getTextValue(CDdNameValuePairConstants.CASE_VR_PENDING_SOLVE_MISSING_PERM));
                    }
                    else if(!caseVar.Status.equals(CDdSupportConstants.CASE_STATUS_PENDING)) {
                        caseVar.addError(CDdNameValuePairHelper.getTextValue(CDdNameValuePairConstants.CASE_VR_PENDING_SOLVE_WRONG_STATUS));
                    }
                }

                // validation 2: BIZS-1539 [Q3] POS Reporting Optimization
                if (caseVar.Pending_Reason__c.equals(CDdSupportConstants.CASE_MXP_PENDING_REASON_WAITING_ON_POS_PROVIDER)) {
                    if(String.isBlank(caseVar.Issue_Type__c) || !caseVar.Issue_Type__c.equals(CDdSupportConstants.CASE_ISSUE_TYPE_POINT_OF_SALE)) {
                        caseVar.addError(CDdNameValuePairHelper.getTextValue(CDdNameValuePairConstants.CASE_VR_PENDING_POS_WRONG_FIELD));
                    }
                    else if(String.isBlank(caseVar.POS_Integration_Type__c)) {
                        caseVar.addError(CDdNameValuePairHelper.getTextValue(CDdNameValuePairConstants.CASE_VR_PENDING_POS_MISSING_FIELD));
                    }
                }
            }
        }
    }

    /**
     * @author      Sahil
     * @date        August 2022
     * @jira        https://doordash.atlassian.net/browse/BIZS-1609
     * @description handle phone cases which were marked unresolved contact.
     *              typically marked by teammates to callback customers using phone
    */
    public static void handleUnresolvedContactPhoneCases(List<Case> newCaseList, Map<Id,Case> oldCaseMap) {
        try {
            if (!CDdExperimentSvc.getSupportFeatureFlag('Publish_AWS_Events__c')){ //feature flag to enable event publishing
                return;
            }
            List<Case> casesToProcess = new List<Case>();
            for (Case c : newCaseList) {
                Boolean issueStartsWithUnresolvedContact = String.isNotBlank(c.Issue__c) && isFieldUpdated(c, oldCaseMap, 'Issue__c') &&
                                                            c.Issue__c.startsWithIgnoreCase(CDdNameValuePairHelper.getTextValue(CDdNameValuePairConstants.UNRESOLVED_CONTACT));
                Boolean resolutionStartsWithUnresolvedContact = String.isNotBlank(c.Resolution__c) && isFieldUpdated(c, oldCaseMap, 'Resolution__c') &&
                                                                c.Resolution__c.startsWithIgnoreCase(CDdNameValuePairHelper.getTextValue(CDdNameValuePairConstants.UNRESOLVED_CONTACT));
                if (String.isNotBlank(c.Origin) && c.Origin == CDdSupportConstants.CASE_ORIGIN_PHONE
                    && (issueStartsWithUnresolvedContact || resolutionStartsWithUnresolvedContact)) {
                    casesToProcess.add(c);
                }
            }
            if (casesToProcess.isEmpty()) {
                return;
            }
            List<AWS_Event__e> awsEventToPublishList = new List<AWS_Event__e>();
            for (Case c : casesToProcess) {
                awsEventToPublishList.add(CDdAWSEventHelper.createAWSEvent(c));
            }
            if(!awsEventToPublishList.isEmpty()) {
                List<Database.SaveResult> saveResults = EventBus.publish(awsEventToPublishList);
                CDdErrorUtilities.publishException(CDdSupportConstants.CASE_OBJECT_LABEL , 'handleUnresolvedContactPhoneCases', saveResults);
            }
        } catch (Exception e) {
            CDdErrorUtilities.publishException('CDdCaseTriggerHelperV2','handleUnresolvedContactPhoneCases', e);
        }
    }

    /**
    * @author      Nayana Kapse
    * @date        Sep 2022
    * @jira        https://doordash.atlassian.net/browse/BIZS-1886
    * @description Auto creation of Case Shadow Object
    */
    public static void proactiveCaseCreation(List<Case> newCaseList,System.TriggerOperation operationType) {
        if (CDdCustomMetaData.isDisabled('CDdCaseTriggerHelper_proactiveCaseCreati')){
            return;
        }
        if(ranProactiveCase){
            return;
        }
        CDdProactiveCaseCreationHelper.checkProactiveCaseCreationFlow(newCaseList,operationType);
        ranProactiveCase= true;
    }
    /**
     * @author          Jeegar
     * @date            May 2023
     * @jira            https://doordash.atlassian.net/browse/BIZS-2587
     * @description     Merge case after close
     * @param           List<Case> newCaseList, Map<Id, Case> OldCaseMap
     * @return          void
     */

    public static void mergeCaseAfterSolved(List<Case> newCaseList, Map<Id, Case> oldCaseMap) {
        try {
            if(CDdExperimentSvc.getSupportFeatureFlag('Disable_Auto_Merge_Cases__c') || ranMergeCaseAfterSolved) {
                return;
            }
            Map<Id, List<Case>> accountIdCaseMap;
            Map<Id, Id> caseIdDuplicateCaseIdMap;
            Set<Id> accountIds = new Set<Id>();
            Id supportRecordTypeId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeIdByDevName(CDdSupportConstants.RECORDTYPE_NAME_CUSTOMER);
            for(Case currCase : newCaseList) {
                if( isFieldUpdated(currCase, oldCaseMap, 'Status')
                    && isMergeCandidate(currCase, supportRecordTypeId)) {
                    accountIds.add(currCase.AccountId);
                }
            }
            if(accountIds.size() > 0 ) {
                accountIdCaseMap = getPotentialDuplicateCases(accountIds);
                if(accountIdCaseMap != null
                            && accountIdCaseMap.keySet().size() > 0 ){
                        caseIdDuplicateCaseIdMap = matchDuplicateCases(newCaseList, accountIdCaseMap);
                }
                if(caseIdDuplicateCaseIdMap != null
                        && caseIdDuplicateCaseIdMap.keySet().size() > 0 ) {
                    for(Case currCase : newCaseList) {
                        if(caseIdDuplicateCaseIdMap.containsKey(currCase.id)) {
                            currCase.ParentId = caseIdDuplicateCaseIdMap.get(currCase.id);
                            if (currCase.Customer_Type__c.equals(CDdSupportConstants.CUSTOMER_TYPE_CONSUMER)) {
                                currCase.Resolution_Type__c = CDdSupportConstants.RESOLUTION_TYPE_OTHER_CX;
                            } else if (currCase.Customer_Type__c.equals(CDdSupportConstants.CUSTOMER_TYPE_DASHER)) {
                                currCase.Resolution_Type__c = CDdSupportConstants.RESOLUTION_TYPE_OTHER_DX;
                            } else if (currCase.Customer_Type__c.equals(CDdSupportConstants.CUSTOMER_TYPE_MERCHANT)) {
                                currCase.Resolution_Type__c = CDdSupportConstants.RESOLUTION_TYPE_OTHER_MX;
                            } else {
                                currCase.Resolution_Type__c = CDdSupportConstants.RESOLUTION_TYPE_OTHER;
                            }
                            currCase.Resolution__c = CDdSupportConstants.CASE_RESOLUTION_AUTOMATED_MERGE_DUPLICATE;
                            currCase.Status = CDdSupportConstants.CLOSED_STATUS;
                        }
                    }
                    ranMergeCaseAfterSolved = true;
                }
            }
        } catch (Exception Ex) {
            CDdErrorUtilities.publishException('CddCaseTriggerHelperV2', 'mergeCaseAfterSolved', ex);
            throw Ex;
        } finally {

        }
    }

    /**
     * @author          Jeegar
     * @date            May 2023
     * @jira            https://doordash.atlassian.net/browse/BIZS-2587
     * @description     Get a list of potential duplicate cases.
     *                  Cases with status Solved, Closed or Pending that were modified in last 24 hours
     * @param           Set<Id> account Ids
     * @return          Map<Id, List<Case>> account id, case list map
     */

    private static Map<Id, List<Case>> getPotentialDuplicateCases(Set<Id> accountIds) {
        Map<id, List<Case>> accountIdCaseMap = new Map<Id, List<Case>>();
        Set<String> caseStatusToQuery = new Set<String>();
        caseStatusToQuery.add(CDdSupportConstants.SOLVED_STATUS);
        caseStatusToQuery.add(CDdSupportConstants.CLOSED_STATUS);
        List<Case> potentialMatches = [SELECT Id, accountId, parentId, recordtypeid, customer_type__c,
                                                DeliveryUUID__c, Issue__c
                                        FROM Case
                                        WHERE Solved_At__c >= :CDdUtilities.addHoursToTime(null,-24)
                                            AND recordTYpeId = :CDdGenericTriggerOptimizationHelper.getCaseRecordTypeIdByDevName(CDdSupportConstants.RECORDTYPE_NAME_CUSTOMER)
                                            AND ParentId = ''
                                            AND accountId in :accountIds
                                            AND Status in :caseStatusToQuery
                                            ORDER BY CreatedDate
                                            DESC
                                            limit 50];
        List<Case> tempList;

        for(Case currCase : potentialMatches) {
            if(accountIdCaseMap.containsKey(currCase.AccountId)) {
                tempList = accountIdCaseMap.get(currCase.AccountId);
            } else {
                tempList = new List<Case>();
            }
            tempList.add(currCase);
            accountIdCaseMap.put(currCase.AccountId, tempList);
        }
        return accountIdCaseMap;
    }
    /**
     * @author          Jeegar
     * @description     checks if this case is a mergeable case or not
     * @param           Case    currentCase
     *                  Id      recordType Id to match on
     * @return          boolean
     * @jira            https://doordash.atlassian.net/browse/BIZS-2587
     */

    private static boolean isMergeCandidate(Case currCase, Id supportRecordTypeId){
        if(currCase.recordTypeId == supportRecordTypeId
            && currCase.ParentId == null
            && currCase.AccountId != null
            && String.isNotBlank(currCase.DeliveryUUID__c)
            && String.isNotBlank(currCase.Origin)
            && String.isNotBlank(currCase.Customer_Type__c)
            && ( CDdSupportConstants.ALL_CUSTOMER_TYPES.contains(currCase.Customer_Type__c))
            && (currCase.Origin.equals(CDdSupportConstants.CASE_ORIGIN_CHAT)
                || currCase.Origin.equals(CDdSupportConstants.CASE_ORIGIN_PHONE))
            && (currCase.Status.equals(CDdSupportConstants.SOLVED_STATUS)
                || currCase.Status.equals(CDdSupportConstants.CLOSED_STATUS))) {

            return true;
        }

        return false;

    }
    /**
     * @author          Jeegar
     * @date            May 2023
     * @jira            https://doordash.atlassian.net/browse/BIZS-2587
     * @description     Match duplicate cases, if the case has same
     *                      Issue__c,
     *                      DeliveryUUID__c,
     *                      Customer_Type__c,
     *                      AccountId it is a match
     * @param           List<case> newCaseList, Map<Id, List<Case>> account id, case list map
     * @return
     */

    private static Map<Id,Id> matchDuplicateCases (List<Case> newCaseList, Map<Id, List<Case>> accountIdCaseMap) {
        Map<Id,Id> caseIdDuplicateCaseIdMap = new Map<Id,Id> ();
        List<Case> tempCaseList;
        for(Case currCase : newCaseList) {
            if(accountIdCaseMap.containsKey(currCase.AccountId)) {
                tempCaseList = accountIdCaseMap.get(currCase.AccountId);
            }
            if(tempCaseList != null) {
                for(Case potentialDupe : tempCaseList) {
                    if(currCase.AccountId == potentialDupe.AccountId
                            && currCase.Id != potentialDupe.Id
                            && currCase.Customer_Type__c.equals(potentialDupe.Customer_Type__c)
                            && ((String.isBlank(currCase.Issue__c)
                                && String.isBlank(currCase.Issue__c))
                                || ((String.isNotBlank(currCase.Issue__c)
                                    && String.isNotBlank(currCase.Issue__c)
                                    && currCase.Issue__c.equals(potentialDupe.Issue__c) ))
                            && (( String.isNotBlank(currCase.DeliveryUUID__c)
                                    && String.isNotBlank(potentialDupe.DeliveryUUID__c)
                                    && currCase.DeliveryUUID__C.equals(potentialDupe.DeliveryUUID__c))))) {

                        caseIdDuplicateCaseIdMap.put(currCase.id, potentialDupe.id);
                        break;
                    }
                }
            }
        }
        return caseIdDuplicateCaseIdMap;
    }
    /**
     * @author      Nayana Kapse, Sugan
     * @date        Dec 2022
     * @jira        https://doordash.atlassian.net/browse/BIZS-2325
     * @description Automate Chargeback Process
     * Context      afterInsert
     */
    public static void mxChargebackProcessing(List<Case> newCaseList){

        // bypass logic using Batch_and_Trigger_Setting__mdt settings
        if (CDdCustomMetaData.isDisabled('CDdCaseTriggerHelper_mxChargebackCheckDuplicate') || CDdToolsAdminCallout.chargebackQueued){
            return;
        }
        List<CDdRestJSONObj.ChargeBackSubmission> lstChargeBackSubmissions = prepareChargeBackSubmissionRecords(newCaseList);
        String actionName = getChargeBackSubmissionType(lstChargeBackSubmissions);
        //Phase 2 here call queueable to make an API Call remove PE code for now.
        if(!lstChargeBackSubmissions.isEmpty() && !String.isBlank(actionName)){
            System.enqueueJob(new CDdToolsAdminCalloutQueuable(actionName,lstChargeBackSubmissions));
            CDdToolsAdminCallout.chargebackQueued = true;
        }
    }
    @testVisible
    private static String getChargeBackSubmissionType( List<CDdRestJSONObj.ChargeBackSubmission> lstChargeBackSubmissions){
        /* every transaction can only contain one or the other - Error charge disputes or cancelled order refunds
        we use this parameter to determine the appropriate custom mdt record to use */
        for(CDdRestJSONObj.ChargeBackSubmission rec : lstChargeBackSubmissions){
            if(rec.merchantPaymentAdjustmentReason == CDdChargeBackSubmissionCallout.EC_DISPUTE_REASON){
                return 'ChargeBackSubmission_EC_Dispute';
            }else if(rec.merchantPaymentAdjustmentReason == CDdChargeBackSubmissionCallout.CO_REFUND_REASON){
                return 'ChargeBackSubmission_CO_Refund';
            }
        }
        return '';
    }

    @testVisible
    /**
     * Helper to prepare chargeback processing records based on incoming case records
     */
    private static List<CDdRestJSONObj.ChargeBackSubmission> prepareChargeBackSubmissionRecords(List<Case> newCaseList){
        //get support record type
        Id supportRecordTypeId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeIdByDevName(CDdSupportConstants.RECORDTYPE_NAME_CUSTOMER);
        List<CDdRestJSONObj.ChargeBackSubmission> lstChargeBackSubmissions = new List<CDdRestJSONObj.ChargeBackSubmission>();
        // this is the temporary queue the new Cases getting assigned to using 'mission control'
        Id QUEUE_MX_PARKING_Id = CDdGenericTriggerOptimizationHelper.getQueueIdByName(QUEUE_MX_PARKING);

        // check for Cases assigned to the above queue in BeforeInsert context
        for(Case caseVar : newCaseList) {
            if(caseVar.OwnerId == QUEUE_MX_PARKING_Id && caseVar.Customer_type__c == 'Merchant' && caseVar.Status != 'Closed') {
                CDdRestJSONObj.ChargeBackSubmission request = new CDdRestJSONObj.ChargeBackSubmission();
                request.caseId = caseVar.Id;
                request.description = caseVar.Id;
                request.deliveryUuidShort = caseVar.Delivery_UUID_8_Digit__c;
                request.storeId = caseVar.Store_ID__c;
                if(caseVar.Formstack_Subcategory__c != null && CDdChargeBackSubmissionCallout.MAP_OF_FORMSTACK_CATEGORY_TO_ADJUSTMENT_REASON.containsKey(caseVar.Formstack_Subcategory__c )){
                    request.merchantPaymentAdjustmentReason =  CDdChargeBackSubmissionCallout.MAP_OF_FORMSTACK_CATEGORY_TO_ADJUSTMENT_REASON.get(caseVar.Formstack_Subcategory__c);
                }
                //we are currently using Rachel Marx's Id as provided by business - this should eventually be replaced with a generic dd integration user id
                request.ddUserId = CDdNameValuePairHelper.getTextValue(CDdNameValuePairConstants.DD_USERID_FOR_CHARGEBACK_SUBMISSION);
                if(caseVar.Description != null){
                    request.storeRefund = getRefundAmount(caseVar.Description);
                    request.contactName = getContactName(caseVar.Description);
                    request.contactEmail = getContactEmail(caseVar.Description);
                    lstChargeBackSubmissions.add(request);
                }
                request.idempotencyKey = request.deliveryUuidShort + '_' + request.storeId + '_' + request.storeRefund ;
            }
        }
        return lstChargeBackSubmissions;
    }
    private static Integer getRefundAmount(String caseDescription)
    {
        // Adding try/catch so to prevent Case submissions failures from FormStack when Case Description contain invalid format/characters
        // In these Cases, we do not have to run the duplicate logic, as Delivery id is not present
        try {
            // as per the current format, the Refund amount will be sent in the description after the below label
            String amt = caseDescription.substringBetween('Error Charge Amount:','\n').trim().replaceAll('$','');
            Decimal chargeBackAmt =  Decimal.valueOf(amt);
            return Integer.valueOf(chargeBackAmt * 100); //API needs the amount in this format. So multiplying by 100
        }
        catch (exception e) {
            return 0;
        }
    }

    /**
     * Helper method to fetch contact name from case description
     */
    private static String getContactName(String caseDescription){
       return caseDescription.substringBetween('Contact Name:','\n');
    }
    private static String getContactEmail(String caseDescription){
        return caseDescription.substringBetween('Contact Email:','\n');
    }

    /*
     * @author          Ila Maheshwari
     * @created         28 / 10 / 2022
     * @description     BASD-39057 Prevent manual selection of Case Status ‘In Rescue’ on  ‘POS Integrations’ case record type if there are no corresponding milestone records in 'In Rescue’ status
    */
    public static void preventInRescueStatusOnCase(List<Case> newList, Map<Id, Case> oldMap) {
        Boolean allowCaseStatusUpdateInRescue = CDdMilestone.allowCaseStatusUpdateInRescue;

        // bypass validation for logged in user's profile, using Validation_Bypass__c settings and if profile is Operations Team Manager
        if (UserInfo.getProfileId() == CDdNameValuePairHelper.getTextValue(CDdNameValuePairConstants.OPS_TEAM_MANAGER_PROFILE_ID) || Validation_Bypass__c.getInstance(UserInfo.getProfileId()).Bypass_Case_Validations__c || allowCaseStatusUpdateInRescue) {
            return;
        }

        Map<Id,Case> posCases = new Map<Id,Case>();
        Id posRecordTypeId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeIdByDevName(CDdSupportConstants.RECORDTYPE_NAME_POS_INTEGRATIONS);

        for (Case newCase: newList){
            if(newCase.RecordTypeId == posRecordTypeId && newCase.Status == CDdSupportConstants.INRESCUE_STATUS && isFieldUpdated(newCase,oldMap,'Status')){
                posCases.put(newCase.Id, newCase);
            }
        }

        for(Milestone__c m: [SELECT Id, Status__c, Status_Reason__c, Case__c, OwnerId FROM Milestone__c WHERE Case__c IN :posCases.keySet() AND Status__c = 'In Rescue']){
            if(m.Status__c == CDdSupportConstants.INRESCUE_STATUS){
                posCases.remove(m.Case__c);
            }
        }

        //Add error to cases which does not have any milestone In Rescue status
        if(!posCases.isEmpty()){
            for (Case newCase: posCases.values()){
                newCase.addError(CDdNameValuePairHelper.getTextValue(CDdNameValuePairConstants.CASE_TRIGGER_VALIDATE_INRESCUE_STATUS_ERROR_MSG));
            }
        }
    }
    // split new phone case into its own method?
    @TestVisible private static boolean shouldSendTHQAlert(Case newCase, Case oldCase) {
        Boolean sendTHQAlert = false;

        if(CDdExperimentSvc.getSupportFeatureFlag('Disable_THQ_Callouts__c')) {
            return false;
        }
        // THQ support API and Support recordtypes.
        if(newCase.recordTypeId == CDdGenericTriggerOptimizationHelper.supportRecordTypeId
            || newCase.recordTypeId == CDdGenericTriggerOptimizationHelper.getCaseRecordTypeIdByDevName(
                CDdSupportConstants.RECORDTYPE_NAME_API)) {


            if(oldCase != null
                && getActiveTHQOrigins().contains(newCase.Origin)) {
                // Send Notification for Support Phone, Chat, Web, Email and API cases not just sendbird cases.

                sendTHQAlert = true;
            } else if ( oldCase == null
                    && newCase.Origin != CDdSupportConstants.CASE_ORIGIN_CHAT) {
                // sendnotification for new "non chat" cases

                sendTHQAlert = true;
            }
        }
        return sendTHQAlert;
    }

    /**
     * @author      Jeegar
     * @date        Feb 2023
     * @jira        BIZS-2566
     * @description Get Active Origins for THQ
     */
    private static List<String> getActiveTHQOrigins() {
        List<String> activeTHQOrigins = new List<String>();
        List<THQ_Case_Origin__mdt> thqOrigins = THQ_Case_Origin__mdt.getAll().values();
        for(THQ_Case_Origin__mdt thqOrigin : thqOrigins) {
            if(thqOrigin.Is_Active__c) {
                activeTHQOrigins.add(thqOrigin.Origin__c);
            }
        }
        return activeTHQOrigins;
    }

    /**
     * @author      Swedhaa Sri M
     * @date        Nov 2022
     * @jira        https://doordash.atlassian.net/browse/BASD-39912
     * @description set case owner based on Hibernated and Suspended POS Values
     */

    public static void setCaseOwnerBasedOnHibernatedOrSuspended (List<Case> newCaseList, Map<Id,Case> oldCaseMap){
        Id posIntegrationRTId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeIdByDevName('POS_Integrations');
        Id marketplaceOnboardingRTId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeIdByDevName('Marketplace_Onboarding');

        Id hibernatedPOSProvidersQueueId = CDdGenericTriggerOptimizationHelper.getQueueIdByName(QUEUE_HIBERNATED_POS_PROVIDERS);
        Id suspendedPOSProvidersQueueId = CDdGenericTriggerOptimizationHelper.getQueueIdByName(QUEUE_SUSPENDED_POS_PROVIDERS);

        String ONBOARDING_POS_QUEUE_IDS = CDdNameValuePairHelper.getTextValue('Onboarding_POS_Queue_Ids');
        String HIBERNATED_POS_PROVIDER_VALUES = CDdNameValuePairHelper.getLongTextValue('Hibernated_POS_Providers');
        String SUSPENDED_POS_PROVIDER_VALUES = CDdNameValuePairHelper.getLongTextValue('Suspended_POS_Providers');
        Id previousCaseOwnerId;

        Set<String> milestonesToComplete = new Set<String>{'Review & Triage', 'Setup Store', 'Setup Business', 'Grant Portal Access'};
        Map<Id,Integer> caseIdToMilestoneCount= new Map<Id,Integer>();

        List<Case> casestoProcess = new List<Case>();
        for (Case caseObj: newCaseList){
            previousCaseOwnerId = (oldCaseMap == null ? caseObj.OwnerId : oldCaseMap.get(caseObj.Id).OwnerId);
            if(caseObj.POS_Integration_Type__c != null
               && caseObj.OwnerId != null
               && previousCaseOwnerId != hibernatedPOSProvidersQueueId && previousCaseOwnerId != suspendedPOSProvidersQueueId
               && caseObj.Status != 'Closed'
               && isNewOrFieldUpdated(caseObj, oldCaseMap, 'POS_Integration_Type__c')
               && (caseObj.RecordTypeId == posIntegrationRTId || (caseObj.RecordTypeId == marketplaceOnboardingRTId
               && (previousCaseOwnerId != null && ONBOARDING_POS_QUEUE_IDS.contains(previousCaseOwnerId))))){
                   casestoProcess.add(caseObj);
            }
        }

        if (casestoProcess.isEmpty()) {
            return;
        }

        for(AggregateResult arr: [SELECT Count(Id) numberOfMilestones, Case__c FROM Milestone__c WHERE Case__c IN :casestoProcess
                                  AND Status__c = 'Complete' AND Case__r.RecordTypeId =: marketplaceOnboardingRTId AND Milestone_Type__c IN :milestonesToComplete GROUP BY Case__c]){
 				caseIdToMilestoneCount.put((Id)arr.get('Case__c'), (Integer)arr.get('numberOfMilestones'));
        }

        for(Case c : casestoProcess){
            Integer reqMilestonesCount = caseIdToMilestoneCount.get(c.Id);
            previousCaseOwnerId = (oldCaseMap == null ? c.OwnerId : oldCaseMap.get(c.Id).OwnerId);
            if(c.RecordTypeId == posIntegrationRTId || (c.RecordTypeId == marketplaceOnboardingRTId && reqMilestonesCount == 4
                && (previousCaseOwnerId != null && ONBOARDING_POS_QUEUE_IDS.contains(previousCaseOwnerId)))){
                    if(HIBERNATED_POS_PROVIDER_VALUES.contains(c.POS_Integration_Type__c)) {
                        c.OwnerId = hibernatedPOSProvidersQueueId;
                    }
                    else if(SUSPENDED_POS_PROVIDER_VALUES.contains(c.POS_Integration_Type__c)) {
                        c.OwnerId = suspendedPOSProvidersQueueId;
                    }
            }
        }
    }

    /**
     * @author      Mahesh Chouhan
     * @date        March 2023
     * @jira        https://doordash.atlassian.net/browse/BASD-43689
     * @description check if created case fulfil Disaster Prevention Criteria
     * @param   List<Case> newCaseList - Case in trigger.new
     * @param   Map<Id, Case> oldCaseMap - trigger.oldMap
     * @return
     */
    public static void checkForDisasterPreventionCase(List<Case> newCaseList, Map<Id,Case> oldCaseMap) {
        if (CDdCustomMetaData.isDisabled('CDdCaseTriggerHelperV2_checkForDisasterP')){
            return;
        }
        List<Case> toProcess = new List<Case>();
        Set<String> customerTypes = new Set<String>{CDdSupportConstants.CUSTOMER_TYPE_CONSUMER,
            CDdSupportConstants.CUSTOMER_TYPE_DASHER, CDdSupportConstants.CUSTOMER_TYPE_MERCHANT};

        for(Case caseRecord : newCaseList){
            if(customerTypes.contains(caseRecord.Customer_Type__c) && caseRecord.Previous_Queue__c != null
                && !CDdSupportHelper.isLiveQueue(caseRecord.Previous_Queue_ID__c)){
                toProcess.add(caseRecord);
            }
        }

        if (toProcess.isEmpty()) {
            return;
        }

        CDdCaseEventTriggerHelper.publishEvents(CDdCaseEventTriggerHelper.PlatformEventType.CHECK_DISASTER_ESCALATION, toProcess, oldCaseMap);
    }

    /**
     * @author      Mahesh Chouhan
     * @date        April 2023
     * @jira        https://doordash.atlassian.net/browse/BASD-43689
     * @description Update Inbound_Count__c field on Account
     */
    public static void updateInboundCounter(List<Case> newCaseList){
        if (CDdCustomMetaData.isDisabled('CDdCaseTriggerHelperV2_updateInboundCoun')){
            return;
        }

        Set<Id> accountIds = new Set<Id>();
        for(Case caseRecord : newCaseList){
            if(caseRecord.AccountId != null){
                accountIds.add(caseRecord.AccountId);
            }
        }

        if(accountIds.isEmpty()){
            return;
        }

        if(System.IsBatch() || System.isFuture()) {
            updateInboundCounter(accountIds);
        }
        else {
            updateInboundCounterFuture(accountIds);
        }
    }

    /**
     * @author      Mahesh Chouhan
     * @date        April 2023
     * @jira        https://doordash.atlassian.net/browse/BASD-43689
     * @description Update Inbound_Count__c field on Account asynchronously
     */
    @future
    public static void updateInboundCounterFuture(Set<Id> accountIds){
        try {
            //Key is AccountId, Value is Inbound Count
            Map<Id, Integer> accountInboundCountMap = new Map<Id, Integer>();
            List<AggregateResult> groupedResults = [SELECT AccountId, COUNT(Id)
                                                    FROM Case
                                                    WHERE AccountId IN :accountIds AND CreatedDate =LAST_N_DAYS:30 GROUP BY AccountId];

            for(AggregateResult ar : groupedResults){
                if(ar.get('AccountId') != null){
                    accountInboundCountMap.put(String.valueOf(ar.get('AccountId')), Integer.valueOf(ar.get('expr0')));
                }
            }

            List<Account> accList = new List<Account>();
            for(Id accountId : accountInboundCountMap.keySet()){
                accList.add(new Account(Id = accountId, Inbound_Count__c = accountInboundCountMap.get(accountId)));
            }

            update accList;
        } catch (Exception e) {
            CDdErrorUtilities.publishException('CDdCaseTriggerHelperV2','updateInboundCounterFuture', e);
        }
    }

    /**
     * @author      Mahesh Chouhan
     * @date        May 2023
     * @jira        https://doordash.atlassian.net/browse/BASD-43689
     * @description Update Inbound_Count__c field on Account
     */
    public static void updateInboundCounter(Set<Id> accountIds){
        try {
            //Key is AccountId, Value is Inbound Count
            Map<Id, Integer> accountInboundCountMap = new Map<Id, Integer>();
            List<AggregateResult> groupedResults = [SELECT AccountId, COUNT(Id)
                                                    FROM Case
                                                    WHERE AccountId IN :accountIds AND CreatedDate =LAST_N_DAYS:30 GROUP BY AccountId];

            for(AggregateResult ar : groupedResults){
                if(ar.get('AccountId') != null){
                    accountInboundCountMap.put(String.valueOf(ar.get('AccountId')), Integer.valueOf(ar.get('expr0')));
                }
            }

            List<Account> accList = new List<Account>();
            for(Id accountId : accountInboundCountMap.keySet()){
                accList.add(new Account(Id = accountId, Inbound_Count__c = accountInboundCountMap.get(accountId)));
            }

            update accList;
        } catch (Exception e) {
            CDdErrorUtilities.publishException('CDdCaseTriggerHelperV2','updateInboundCounter', e);
        }
    }

    /**
     * @author      Mahesh Chouhan
     * @date        April 2023
     * @jira        https://doordash.atlassian.net/browse/BASD-43689
     * @description Create Case Note for Disaster Escalation Case on insert
     */
    public static void createDisasterEscalationNote(List<Case> newCaseList, Map<Id, List<String>> disasterEscIndicator, Map<Id,Case> oldCaseMap){
        List<FeedItem> lstCaseFeedItems = new List<FeedItem>();
        Set<Id> caseIds = new Set<Id>();

        for(Case caseRecord : newCaseList){
            if(caseRecord.Disaster_Escalation_Case__c){
                caseIds.add(caseRecord.Id);
            }
        }

        if(caseIds.isEmpty()){
            return;
        }

        for(Id caseId : caseIds){
            String prefix = oldCaseMap.containsKey(caseId) && oldCaseMap.get(caseId).Disaster_Escalation_Case__c ? DISASTER_ESC_ADD_CRITERIA_ERROR
                : DISASTER_ESC_MARKING_CASE_ERROR;
            FeedItem cFeed = new FeedItem();
            cFeed.Title = DISASTER_ESC_CASE_FEED_TITLE;
            cFeed.ParentId = caseId;
            cFeed.Body = disasterEscIndicator != null && disasterEscIndicator.containsKey(caseId) ? prefix + String.join(disasterEscIndicator.get(caseId), '\n')
                : null;
            lstCaseFeedItems.add(cFeed);
        }

        if(!lstCaseFeedItems.isEmpty()){
            CDdGenericPlatformEventHelper.publishEvents(CDdGenericPlatformEventHelper.PlatformEventType.CREATE_CASE_FEED,
                                                    null,JSON.serialize(lstCaseFeedItems));
        }
    }

    /**
     * @author      Swedhaa Sri M
     * @date        Feb 2023
     * @jira        https://doordash.atlassian.net/browse/BASD-42481
     * @description CaseTrigger will call this to validate OCUS Photoshoot Data.
     */
    public static void validateOCUSPhotoshootData(List<Case> newCaseList, Map<Id,Case> oldCaseMap){
        Id photoshootRecordTypeId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeIdByDevName('Photoshoot_Processing');
        Boolean isInsert = oldCaseMap == null ? true : false;
        List<Case> casesToCheck = new List<Case>();
        for (Case caseRec : newCaseList){
            if(caseRec.RecordtypeId == photoshootRecordTypeId && caseRec.Photo_Provider__c == 'OCUS' &&
               (caseRec.Opportunity_Name__c == null || caseRec.Menu_Preview_Links__c == null ||
                (caseRec.Photoshoot_Date__c == null && caseRec.Photoshoot_Time__c != null) ||
                (caseRec.Photoshoot_Date__c != null && caseRec.Photoshoot_Time__c == null))){
                    casesToCheck.add(caseRec);
                }
        }
        if(!casesToCheck.isEmpty()){
            CDdOCUSAPIHandler.validateOCUSData(casesToCheck, isInsert);
        }
    }

    /**
    * @author      Lathika
    * @date        Feb 2023
    * @jira        BZAP-19359,
    * @description  Coverting the before flow: 'Complete case when Activation date' to Trigger
    * called before insert and before update:
    * set the Case status to Closed based on certain conditions
    * case recordtype Id not equals: (Marketplace, Tablet, Pos Integrations), Case Status != closed
    * (Activation_Date__c, Contract_Verification_Date__c, Deactivation_Date__c) date checks
    */
    public static void setCaseStatusToClosed(List<Case> newCaseList, Map<Id,Case> oldCaseMap){
        if (ransetCaseStatusToClosed) {
            return;
        }
        Id caviarOnboardingRTId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeId(CDdSupportConstants.RECORDTYPE_NAME_CAVIAR_ONBOADING);
        Id bulkUploadRequestsRTId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeId(CDdSupportConstants.RECORDTYPE_NAME_BULK_UPLOAD_REQUEST);
        Map<Id,Opportunity> oppMap = CDdCaseTriggerOptimizationHelper.getOpportunityMap();
        // caseToprocessForNonCaviarAndDoordash
        List<Case> caseListToProcess = new List<Case>();
        // caseToprocessForCaviarAndDoordash
        List<Case> caviarOnboardingCaseOfPlatformCaviarAndDoordash = new List<Case>();

        Boolean caviarOnboardingPlatformCaviarAndDoordash = false;
        Boolean dateFieldsEligible = false;
        Boolean deactivationDateNotNull = false;
        Boolean activationDateNotNull = false;
        Boolean recordtypeNotEqualToBulkUploadRequest = false;
        Boolean isBulkUploadRequestRecEligible = false;

        for(Case newCase: newCaseList){
            Opportunity opp = oppMap.containsKey(newCase.Opportunity_Name__c) ? oppMap.get(newCase.Opportunity_Name__c) : null;
            // checking for CaviarOnboardingCase of Platform Doordash And Caviar
            caviarOnboardingPlatformCaviarAndDoordash = false;
            dateFieldsEligible = false;
            if (newCase.RecordtypeId == caviarOnboardingRTId  && opp != null && String.isNotBlank(opp.Platform__c)
                && CDdMxSxConstants.OPPORTUNITY_PLATFORM_CAVIAR_AND_DOORDASH.equals(opp.Platform__c)) {
                caviarOnboardingPlatformCaviarAndDoordash = true;
            }
            deactivationDateNotNull = newCase.Deactivation_Date__c != null; //1
            activationDateNotNull = newCase.Activation_Date__c != null; //2
            recordtypeNotEqualToBulkUploadRequest = !bulkUploadRequestsRTId.equals(newCase.RecordTypeId);//3
            isBulkUploadRequestRecEligible = bulkUploadRequestsRTId.equals(newCase.RecordTypeId) && newCase.Contract_Verification_Date__c != null; //4
            // 1 OR (2  && ( 3 OR 4))
            if (deactivationDateNotNull || (activationDateNotNull
                                      && (recordtypeNotEqualToBulkUploadRequest || isBulkUploadRequestRecEligible))) {
                dateFieldsEligible = true;
            }

            if(!CDdMxSxConstants.CASE_CLOSED_NOT_ELIGIBLE_RECORDTYPES.contains(newCase.RecordTypeId)
                && !CDdMxSxConstants.CASE_STATUS_CLOSED.equals(newCase.Status)
                && (isNewOrFieldUpdated(newCase, oldCaseMap, 'Activation_Date__c') || isNewOrFieldUpdated(newCase, oldCaseMap, 'Contract_Verification_Date__c'))
                && dateFieldsEligible){

                if(caviarOnboardingPlatformCaviarAndDoordash){
                    caviarOnboardingCaseOfPlatformCaviarAndDoordash.add(newCase);
                }else {
                    caseListToProcess.add(newCase);
                }
            }
        }
        // setting the case status = Closed
        if(!caseListToProcess.isEmpty()){
            for (Case caseToProcess : caseListToProcess){
                caseToProcess.Status = CDdMxSxConstants.CASE_STATUS_CLOSED;
            }
        }
        // for Caviar Onboarding of Platform: Doordash and caviar:cases, check the condition for Ads and promo
        if(!caviarOnboardingCaseOfPlatformCaviarAndDoordash.isEmpty()){
            CDdMxSxCaviarOnboardingCaseHelper.setCaviarOnboardingCaseStatusToClosedForPlatformCaviarAndDoordash(caviarOnboardingCaseOfPlatformCaviarAndDoordash);
        }
        ransetCaseStatusToClosed = true;
    }

    /**
    * @author      Sanidhya Jain
    * @date        June 2022
    * @jira        https://doordash.atlassian.net/browse/BASD-46039
    * @description Check for required field for Trust & Safety Case before we mark case as closed or solved.
    */
    public static void checkValidEscalatedTrustSaftyCase(List<Case> newCaseList, Map<Id,Case> oldCaseMap){
        if (CDdCustomMetaData.isDisabled('CDdCaseTriggerHelper_checkValTrustSafty')){
            return;
        }

        //Record type Id Set
        Set<Id> recordTypeIds = new Set<Id>{
            CDdGenericTriggerOptimizationHelper.getCaseRecordTypeId(CDdSupportConstants.RECORDTYPE_NAME_SUPPORT),
            CDdGenericTriggerOptimizationHelper.getCaseRecordTypeId(CDdSupportConstants.RECORDTYPE_NAME_API)
        };

        //Trust & Safety Queue Id Set
        Set<Id> trustSafetyQueueId = new Set<Id>{
            CDdGenericTriggerOptimizationHelper.getQueueIdByName(CDdSupportConstants.QUEUE_P0_SPANISH_TRUST_AND_SAFETY),
            CDdGenericTriggerOptimizationHelper.getQueueIdByName(CDdSupportConstants.QUEUE_P0_TRUST_AND_SAFETY),
            CDdGenericTriggerOptimizationHelper.getQueueIdByName(CDdSupportConstants.QUEUE_P1_SPANISH_TRUST_AND_SAFETY),
            CDdGenericTriggerOptimizationHelper.getQueueIdByName(CDdSupportConstants.QUEUE_P1_TRUST_AND_SAFETY),
            CDdGenericTriggerOptimizationHelper.getQueueIdByName(CDdSupportConstants.QUEUE_P2_SPANISH_TRUST_AND_SAFETY),
            CDdGenericTriggerOptimizationHelper.getQueueIdByName(CDdSupportConstants.QUEUE_P2_TRUST_AND_SAFETY),
            CDdGenericTriggerOptimizationHelper.getQueueIdByName(CDdSupportConstants.QUEUE_M_ESCALATIONS),
            CDdGenericTriggerOptimizationHelper.getQueueIdByName(CDdSupportConstants.QUEUE_M_ESCALATIONS_JAPAN)
        };

        Set<Id> caseDetailsId = new Set<Id>();
        List<Case> casetoProcess = new List<Case>();

        //Getting the Case Detail Id in set if stage is changes to close or solved for current case.
        for(Case cs : newCaseList){
            if(oldCaseMap != null && cs.Case_Detail__c != null &&
               isFieldUpdated(cs, oldCaseMap, 'Status') &&
               recordTypeIds.contains(cs.RecordTypeId) &&
               (cs.Status == CDdSupportConstants.CLOSED_STATUS ||
                cs.Status == CDdSupportConstants.SOLVED_STATUS)){
                    caseDetailsId.add(cs.Case_Detail__c);
                    casetoProcess.add(cs);
                }
        }

        if(caseDetailsId != null && !caseDetailsId.isEmpty()){
            //Setting the Case Detail Map
            CDdCaseTriggerOptimizationHelper.setCaseDetailMap(caseDetailsId);

                for(Case cs : casetoProcess){
                    Case_Detail__c csd = CDdCaseTriggerOptimizationHelper.getcaseDetailMapById(cs.Case_Detail__c);
                    //Checking if current case deatil reocrds with the required field missing
                    if(csd != null && caseDetailsId.contains(cs.Case_Detail__c) &&
                       trustSafetyQueueId.contains(csd.Case_Owner_ID__c) &&
                       !csd.Transfered_De_Escalated__c &&
                       (String.isBlank(csd.Primary_Incident_Type__c) ||
                       String.isBlank(csd.Secondary_Incident_Type__c) ||
                       String.isBlank(csd.Reporter__c) ||
                       String.isBlank(csd.Incident_History__c) ||
                       String.isBlank(csd.Actions_Taken__c) ||
                        String.isBlank(csd.Account_Sharing_Not_My_Dasher__c))){
                            cs.addError(System.Label.Valid_Error_Message_For_Trust_Safelty);
                       }
                }
        }
    }
}