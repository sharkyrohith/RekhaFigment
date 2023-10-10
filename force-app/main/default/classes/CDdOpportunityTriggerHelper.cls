/**
* @author: Jeegar Brahmakshatriya
* @date: 2019-08
* @description: Trigger Helper for Opportunity.
*               Moving code from Handler to Opportunity.
*
* Updates:
* Nathalie Mendezona        01/19/2022          Adding isFieldUpdated() and isNewOrFieldUpdated() following Case optimization format
*/
public with sharing class CDdOpportunityTriggerHelper {

    public static final Boolean doDebug = CDdExperimentSvc.getCustomSettingFeatureFlag('Enable_Debug_Logs__c');
    public static final Boolean doCPUTimeCheck = CDdExperimentSvc.getCustomSettingFeatureFlag('Enable_CPU_Time_Check__c');
    public static final vCS__c SETTINGS = vCS__c.getInstance();
    public static Boolean runOnce = CDdExperimentSvc.getFeatureFlag('Run_Once__c');
    public static Boolean BFF_CALLOUT_RUN_ONCE = false;
    public static boolean ranUpdateMOCaseAndMilestones = false;
    public static boolean ranCreateLiquorLicenseTask = false;
    public static boolean ranCreateMilestonesPostOppClose = false;
    public static boolean ranUpdateOppAsynchronous = false;
    public static Id corporateRTId = CDdSchemaUtils.OPPORTUNITY_RT.corporateId();
    public static Id postSaleRecId = CDdSchemaUtils.OPPORTUNITY_RT.postSaleId();
    public static Id marketplaceRecordTypeId = CDdSchemaUtils.OPPORTUNITY_RT.mlInsideSalesId();
    public static Id enterpriseMarketplaceRecordTypeId = CDdSchemaUtils.OPPORTUNITY_RT.enterpriseMarketplaceId();

    // Please use the below way to retrieve RT Ids going forward
    public static Id oppCorporateRTId = CDdGenericTriggerOptimizationHelper.getOpportunityRecordTypeIdByDevName('Corporate');
    public static Id oppPostSaleRTId = CDdGenericTriggerOptimizationHelper.getOpportunityRecordTypeIdByDevName('Post_Sale');
    public static Id oppMarketplaceRTId = CDdGenericTriggerOptimizationHelper.getOpportunityRecordTypeIdByDevName('ML_Inside_Sales');
    public static Id oppEnterpriseMarketplaceRTId = CDdGenericTriggerOptimizationHelper.getOpportunityRecordTypeIdByDevName('Enterprise_Marketplace');

    public static final Map<String, Schema.RecordTypeInfo> ACCOUNT_RECORD_TYPE_INFO_BY_DEV_NAME
                                                = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();
    public static final Map<String, Schema.RecordTypeInfo> OPP_RT_INFO_BY_NAME = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
    public static final Map<String, Schema.RecordTypeInfo> MILESTONES_RT_INFO = Schema.SObjectType.Milestone__c.getRecordTypeInfosByName();
    public static final Map<String, Schema.RecordTypeInfo> CASE_RT_INFO = Schema.SObjectType.Case.getRecordTypeInfosByName();
    public static final List<String> completedBysNotEligibleSMMilestone = new List<String> { 'Account Owner', 'None - Menu Setup Complete' };
    public static final Id onboardingCaseRTId = CASE_RT_INFO.get('Marketplace Onboarding').getRecordTypeId();
    public static final String RECORD_TYPE_DEV_NAME_PARENT_ACCOUNT = 'Parent_Account';
    public static Boolean CREATE_ASSET_ONCE = false;
    public static Boolean leadMergePerformed = false;
    public static Boolean ranMatchOnFormstackStoreId = false;
    public static Boolean ranProcessFormStackOpportunities = false;
    public static Boolean ranProcessContactRole = false;
    public static Boolean ranDonotAllowCreationOfOpportunities = false;
    public static Boolean ranCopyRequestAccountManagementToParentAccount = false;
    public static Boolean ranSetBusinessVerificationDocumentAttached = false;
    public static Boolean ranSetDashPassEligible = false;
    public static Boolean ranAccountReparent = false;
    public static Boolean ranSSMOOpportunityUpdate = false;
    public static Boolean ranSendEmailToSSMOOpportunityOwner = false;
    public static Boolean ranCreatePreSaleImplementationRequest = false;
    public static Boolean disableSSMOClosedWonOpportunityOwnerEmail = CDdExperimentSvc.getCustomSettingFeatureFlag('Disable_SSMO_ClosedOwn_Owner_Email__c');
    public static Boolean disablePreSaleImplementationRequest = CDdExperimentSvc.getCustomSettingFeatureFlag('Disable_PreSale_Implementation_Request__c');//BZAP-18107
    public static Boolean enablePreSaleImplementationRequestAsync = CDdExperimentSvc.getCustomSettingFeatureFlag('Enable_Implementation_Request_Async__c');//BZAP-18107

    public static final String STAGE_NAME_MEETING_RAN_NEGOTIATED = 'Meeting Ran / Negotiated';
    public static final String STAGE_NAME_READY_FOR_SIGNATURE = 'Ready for Signature';
    public static final String STAGE_NAME_CLOSED_WON = 'Closed Won';
    public static final String STAGE_NAME_CLOSED_LOST = 'Closed Lost';
    public static final String STAGE_NAME_OUT_FOR_SIGNATURE = 'Out for Signature';
    public static final String STAGE_NAME_CONTRACT_SIGNED = 'Contract Signed';
    public static final String OPPORTUNITY_TYPE_CHANGE_OF_OWNERSHIP = 'Change of Ownership';
    public static final String OPPORTUNITY_CHANGE_OF_OWNERSHIP_BUSINESS_OPTION_NEW_OWNER = 'New Store';
    public static final String BILLING_COUNTRY_NEW_ZEALAND = 'New Zealand'; //BZAP-12637
    public static final String LIQUOR_LICENSE_COLLECTION = 'Liquor license collection';
    public static final String TASK_STATUS_COMPLETED = 'Completed';
    public static Boolean formstackDeprecated = CDdExperimentSvc.getCustomSettingFeatureFlag('Form_Stack_Deprecated__c');//BZAP-13640
    public static final String TASK_STATUS_OPEN = 'Open';
    public static Boolean disableSSMOOpptyAttribution = CDdExperimentSvc.getCustomSettingFeatureFlag('Disable_SSMO_Opportunity_Attribution__c');//BZAP-14951

    public static final String OPPORTUNITY_CONTACT_ROLE_PRIMARY_ONBOARDING_CONTACT = 'Primary Onboarding Contact';
    public static final String OPPORTUNITY_CONTACT_ROLE_IT_POC = 'IT POC';
    public static final Set<String> PACTSAFE_CONTRACT_TYPE_SSMO_SELF_ONBOARD = new Set<String>{ 'SSMO Self Onboard', 'SSMO Sign Up Sheet'};
    public static final String DOORDASH_CPQ_USER = 'DoorDash CPQ';

    public static final Opportunity_Trigger_Helper_Settings__c helperSetting =
        Opportunity_Trigger_Helper_Settings__c.getOrgDefaults();

        public static final Product_Trial_Commission__c productTrialCommission =
        Product_Trial_Commission__c.getOrgDefaults();

    public static Id formstackUserId;
    public static Id selfServeUserId;
    public static List<Id> selfServeUserIds = new List<Id>();
    public static Map<Id, Opportunity> packageTrialParentOpps = new Map<Id, Opportunity>();
    public static Map<String, Package_Trial_Settings__c> trials = Package_Trial_Settings__c.getAll();
    public static Map<String, Package_Trial_Products__c> trialProducts = Package_Trial_Products__c.getAll();
    public static Set<String> netsuiteOppRecordTypeIds = new Set<String>();
    static {
        for (Opp_NetSuite_Account_Record_Type__mdt config : [SELECT Id, Label,
                                                            Record_Type_Developer_Name__c, Record_Type_Id__c
                                                            FROM Opp_NetSuite_Account_Record_Type__mdt
                                                            Where Is_Active__c = true]){
            netsuiteOppRecordTypeIds.add(config.Record_Type_Id__c);
        }
        List<Self_Serve_Users__c> selfServeUsers = Self_Serve_Users__c.getAll().values();
        for(Self_Serve_Users__c ssUser : selfServeUsers) {
            if(ssUser.name.contains('formstack')){
                formstackUserId = ssUser.User_Id__c;
            } else if (ssUser.name.contains('mx-eng-api')) {
                selfServeUserId = ssUser.User_Id__c;
            }
            selfServeUserIds.add(ssUser.User_Id__c);
        }
    }

    public static Set<String> bbotRecordTypeIds = new Set<String>{
        oppMarketplaceRTId, postSaleRecId
    };

    /**
     * @description  Determines if a field has been updated on the record
     * @param   Opportunity newOpp - Opportunity in trigger.new
     *          Map<Id, Opportunity> oldMap - trigger.oldMap
     *          String fieldName - field to check if it has been updated
     * @return  Boolean
     */
    public static Boolean isFieldUpdated(Opportunity newOpp,Map<Id, Opportunity> oldMap, String fieldName) {
        return (oldMap != null && newOpp.get(fieldName) != oldMap.get(newOpp.Id).get(fieldName));
    }

    /**
     * @description  Determines if the record is a new record or if a field has been updated on the record
     * @param   Opportunity newOpp - Opportunity in trigger.new
     *          Map<Id, Opportunity> oldMap - trigger.oldMap
     *          String fieldName - field to check if it has been updated
     * @return  Boolean
     */
    public static Boolean isNewOrFieldUpdated(Opportunity newOpp, Map<Id, Opportunity> oldMap, String fieldName) {
        return trigger.isInsert || isFieldUpdated(newOpp, oldMap, fieldName);
    }


    /**
    * @description BZAP-4235 - Match opportunities to accounts based on Formstack Store ID
    */
    public Static void matchOnFormstackStoreId(List<Opportunity> newList) {
        // if runOnce feature is enabled and if the method has already ran once, do not run the method again.
        if(runOnce && ranMatchOnFormstackStoreId) {
            return;
        }
        Map<String, Opportunity> storeToOpptIdMap = new Map<String, Opportunity>();
        Map<String, Id> storeToAccountIdMap = new Map<String, Id>();
        Set<Id> recordTypeIdFilterSet = new Set<Id>{
            ACCOUNT_RECORD_TYPE_INFO_BY_DEV_NAME.get(RECORD_TYPE_DEV_NAME_PARENT_ACCOUNT).getRecordTypeId()
        };
        for (Opportunity opp : newList){
            if (String.isNotBlank(opp.Formstack_Store_ID__c)){
                storeToOpptIdMap.put(opp.Formstack_Store_ID__c.trim(), opp);
            }
        }
        for (Account a : [  SELECT Id, Restaurant_ID__c
                            FROM Account
                            WHERE Restaurant_ID__c IN :storeToOpptIdMap.keySet()
                            AND RecordTypeId NOT IN :recordTypeIdFilterSet
                        ]){
            storeToAccountIdMap.put(a.Restaurant_ID__c.trim(), a.Id);
        }
        for (String storeId : storeToAccountIdMap.keySet()){
            if (storeToOpptIdMap.containsKey(storeId)){
                storeToOpptIdMap.get(storeId).AccountId = storeToAccountIdMap.get(storeId);
            }
            ranMatchOnFormstackStoreId = true;
        }
    }

    public Static void processContactRole(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        // if runOnce feature is enabled and if the method has already ran once, do not run the method again.
        if(runOnce && ranProcessContactRole) {
            return;
        }
        Set<Id> opportunityIds = new Set<Id>();
        Map<Id,Id> roleMap = new Map<Id,Id>();
        List<Opportunity> opportunities = new List<Opportunity>();
        List<OpportunityContactRole> crList = new List<OpportunityContactRole>();

        for(Opportunity currOpp : newList) {
            if(oldmap == null && currOpp.Decision_Maker__c != null) {
                opportunities.add(currOpp);
                roleMap.put(currOpp.id, currOpp.Decision_Maker__c);
            } else if (currOpp.Decision_Maker__c != null && oldMap.get(currOpp.id).Decision_Maker__c == null) {
                opportunities.add(currOpp);
                roleMap.put(currOpp.id, currOpp.Decision_Maker__c);
            }

        }
        if(roleMap.keySet().size() > 0) {
            crList = [SELECT ContactId FROM OpportunityContactRole WHERE ContactId IN :roleMap.values() AND OpportunityID IN :roleMap.keySet()];
            if(crList.size() < 1){
                for(Opportunity o : opportunities){
                    OpportunityContactRole cr = new OpportunityContactRole();
                    cr.OpportunityId = o.id;
                    cr.ContactId = o.Decision_Maker__c;
                    cr.Role = 'Decision Maker';
                    crList.add(cr);
                }
                insert crList;
                ranProcessContactRole = true;
            }
        }
    }

    /*
     * @author:     Jeegar
     * @description: Moving legacy code into trigger Helper. This code creates an Opportunity Contact Role for the decision maker.
     *
     */
    // public static void addContactRole(List<Opportunity> opList) {

    //     List<OpportunityContactRole> crList = new List<OpportunityContactRole>();
    //     Map<Id,Id> roleMap = new Map<Id,Id>();

    //     // List<opportunity> opList = [SELECT Id, Decision_Maker__c FROM Opportunity WHERE Id IN: opportunities];

    //     for(Opportunity o : opList){
    //         roleMap.put(o.id, o.Decision_Maker__c);
    //     }

    //     crList = [SELECT ContactId FROM OpportunityContactRole WHERE ContactId IN :roleMap.values() AND OpportunityID IN :roleMap.keySet()];

    //     if(crList.size() < 1){
    //         for(Opportunity o : opList){
    //             OpportunityContactRole cr = new OpportunityContactRole();
    //             cr.OpportunityId = o.id;
    //             cr.ContactId = o.Decision_Maker__c;
    //             cr.Role = 'Decision Maker';
    //             crList.add(cr);
    //         }
    //         insert crList;
    //     }
    // }
    /*
     * @author:      Jeegar Brahmakshatriya
     * @date:        2019-08
     * @description: BZAP-4629 Create asset records from Opportunity Line Items for Opportunities that are closed won.
     */

    public Static void createAssetsFromProducts(List<Opportunity> newOpportunities, Map<Id, Opportunity> oldOpportunities) {

        Boolean createAsset = CDdExperimentSvc.getFeatureFlag('Enable_Asset_Creation__c');
        Opportunity_Trigger_Helper_Settings__c helperSettings = Opportunity_Trigger_Helper_Settings__c.getInstance();
        List<String> errorMessages = new List<String>();

        if(createAsset) {
            Map<Id, List<OpportunityLineItem>> oppOppLineItemMap = new Map<Id, List<OpportunityLineItem>>();
            List<OpportunityLineItem> opportunityLineItems = new List<OpportunityLineItem>();
            List<OpportunityLineItem> oppLineItemsToUpdate = new List<OpportunityLineItem>();
            List<Opportunity> closedWonOpportunities = new List<Opportunity>();
            List<Asset> assetsToInsert = new List<Asset>();
            Asset newAsset;
            Opportunity oldOpp;
            for(Opportunity currOpp : newOpportunities) {
                if(oldOpportunities!= null) {
                    oldOpp = oldOpportunities.get(currOpp.id);
                    if(currOpp.StageName == 'Closed Won' && oldOpp.StageName != 'Closed Won' && currOpp.SBQQ__PrimaryQuote__c == null) {
                        closedWonOpportunities.add(currOpp);
                    }
                }
            }

            if (closedWonOpportunities.size() < 1) return;

            opportunityLineItems = [SELECT Description, Id, ListPrice, Name, PricebookEntryId, Product2Id, Product2.Name, ProductCode,
                                        TotalPrice, UnitPrice, End_Date__c, Fee__c, Length_of_Trial__c, Marketing_Only_Commission__c,
                                        Start_Date__c, Trial_Fee__c, Trial_Type__c, Quantity, Max_Discount__c, Order_Cart_Minimum__c,
                                        OpportunityId, Opportunity.AccountId, Opportunity.OwnerId, Opportunity.Decision_Maker__r.AccountId,
                                        Max_Amount_From_Marketing_Percent__c, Discount_Percentage__c,
                                        Opportunity.Decision_Maker__c, Estimated_Gross_Margin__c, Weekly_Estimated_Gross_Profit__c, Weekly_Revenue__c,
                                        GOV__c, Service_Rate__c, Discount, Type__c, Commission_Rate__c, Flat_Fee__c, Trial_Fee_Currency__c,
                                        Trial_Commission__c, Duration_Type__c, Duration__c, One_Time_Setup_Fee__c,
                                        Subscription_Fee__c, Billing_Frequency__c, Payment_Processing_Fee__c,
                                        Payment_Processing_Rate__c, Estimated_Total_Investment__c, Service_Fee__c,
                                        Pricing_Tier__c, Platform__c, Commission_If_Terms_Violated__c,
                                        Terms_Verified_Date__c, Max_Delivery_Radius__c, Payment_Protocol__c,
                                        Auto_Renews__c, Renewal_Term_Length__c, Order_Type__c, Service_Type__c,
                                        Flat_Discount_Amount_for_Consumer__c, Max_Number_of_Redemptions__c, Target_Cx_Audience__c,
                                        Order_Service_Type__c, Menu_Item_Minimum_Quantity__c, Menu_Item_Name_Item_ID_Option_ID__c,
                                        Opportunity.DashPass_Eligible__c
                                    FROM OpportunityLineItem
                                    WHERE OpportunityId in : closedWonOpportunities and Asset_Created__c = false];

            for(OpportunityLineItem oppLineItem : opportunityLineItems) {
                newAsset = new Asset();
                newAsset.AccountId = oppLineItem.Opportunity.AccountId;
                newAsset.Auto_Renews__c = oppLineItem.Auto_Renews__c;
                newAsset.Billing_Frequency__c = oppLineItem.Billing_Frequency__c;
                newAsset.Commission_If_Terms_Violated__c = oppLineItem.Commission_If_Terms_Violated__c;
                newAsset.Commission_Rate__c = oppLineItem.Commission_Rate__c;
                newAsset.DashPass_Eligible__c = oppLineItem.Opportunity.DashPass_Eligible__c;
                newAsset.Description = oppLineItem.Description;
                newAsset.Discount_Percentage__c = oppLineItem.Discount_Percentage__c;
                newAsset.Duration_Type__c = oppLineItem.Duration_Type__c;
                newAsset.Duration__c = oppLineItem.Duration__c;
                newAsset.End_Date__c = oppLineItem.End_Date__c;
                newAsset.Estimated_Total_Investment__c = oppLineItem.Estimated_Total_Investment__c;
                newAsset.Fee__c = oppLineItem.Fee__c;
                newAsset.Flat_Discount_Amount_for_Consumer__c = oppLineItem.Flat_Discount_Amount_for_Consumer__c;
                newAsset.Flat_Fee__c = oppLineItem.Flat_Fee__c;
                newAsset.Length_of_Trial__c = oppLineItem.Length_of_Trial__c;
                newAsset.List_Price__c = oppLineItem.ListPrice;
                newAsset.Marketing_Only_Commission__c = oppLineItem.Marketing_Only_Commission__c;
                newAsset.Max_Amount_From_Marketing_Percent__c = oppLineItem.Max_Amount_From_Marketing_Percent__c;
                newAsset.Max_Delivery_Radius__c = oppLineItem.Max_Delivery_Radius__c;
                newAsset.Max_Discount__c = oppLineItem.Max_Discount__c;
                newAsset.Max_Number_of_Redemptions__c = oppLineItem.Max_Number_of_Redemptions__c;
                newAsset.Menu_Item_Minimum_Quantity__c = oppLineItem.Menu_Item_Minimum_Quantity__c;
                newAsset.Menu_Item_Name_Item_ID_Option_ID__c = oppLineItem.Menu_Item_Name_Item_ID_Option_ID__c;
                newAsset.Name = oppLineItem.Product2.Name;
                newAsset.One_Time_Setup_Fee__c = oppLineItem.One_Time_Setup_Fee__c;
                newAsset.Opportunity__c = oppLineItem.OpportunityId;
                newAsset.Order_Cart_Minimum__c = oppLineItem.Order_Cart_Minimum__c;
                newAsset.Order_Service_Type__c = oppLineItem.Order_Service_Type__c;
                newAsset.Order_Type__c = oppLineItem.Order_Type__c;
                newAsset.Payment_Processing_Fee__c = oppLineItem.Payment_Processing_Fee__c;
                newAsset.Payment_Processing_Rate__c = oppLineItem.Payment_Processing_Rate__c;
                newAsset.Payment_Protocol__c = oppLineItem.Payment_Protocol__c;
                newAsset.Platform__c = oppLineItem.Platform__c;
                newAsset.Pricing_Tier__c = oppLineItem.Pricing_Tier__c;
                newAsset.Product2Id = oppLineItem.Product2Id;
                newAsset.Quantity = oppLineItem.Quantity;
                newAsset.Renewal_Term_Length__c = oppLineItem.Renewal_Term_Length__c;
                newAsset.Sales_Price__c = oppLineItem.UnitPrice;
                newAsset.Service_Fee__c = oppLineItem.Service_Fee__c;
                newAsset.Service_Type__c = oppLineItem.Service_Type__c;
                newAsset.Start_Date__c = oppLineItem.Start_Date__c;
                newAsset.Status = helperSettings.New_Asset_Status__c;
                newAsset.Subscription_Fee__c = oppLineItem.Subscription_Fee__c;
                newAsset.Target_Cx_Audience__c = oppLineItem.Target_Cx_Audience__c;
                newAsset.Terms_Verified_Date__c = oppLineItem.Terms_Verified_Date__c;
                newAsset.Total_Price__c = oppLineItem.TotalPrice;
                newAsset.Trial_Commission__c = oppLineItem.Trial_Commission__c;
                newAsset.Trial_Fee_Currency__c = oppLineItem.Trial_Fee_Currency__c;
                newAsset.Trial_Fee__c = oppLineItem.Trial_Fee__c;
                newAsset.Trial_Type__c = oppLineItem.Trial_Type__c;
                newAsset.Type__c = oppLineItem.Type__c;
                newAsset.Weekly_Revenue__c = oppLineItem.Weekly_Revenue__c;
                if(oppLineItem.Opportunity.Decision_Maker__r.AccountId != null) {
                    newAsset.ContactId = oppLineItem.Opportunity.Decision_Maker__c;
                }

                assetsToInsert.add(newAsset);
                CDdUtilities.debug(LoggingLevel.DEBUG,'Assets to be created For Loop= '+assetsToInsert.size(),doDebug);
                oppLineItem.Asset_Created__c = true;
                oppLineItemsToUpdate.add(oppLineItem);
            }

            try {
                CDdUtilities.debug(LoggingLevel.DEBUG,'Createasset once = '+CREATE_ASSET_ONCE,doDebug);
                if(!assetsToInsert.isEmpty() && !CREATE_ASSET_ONCE) {
                    CDdUtilities.debug(LoggingLevel.DEBUG,'Assets to be created = '+assetsToInsert.size(),doDebug);
                    List<Database.SaveResult> sResults = Database.insert(assetsToInsert, false);
                    errorMessages = CDdErrorUtilities.processSaveResults(sResults, errorMessages);
                    CREATE_ASSET_ONCE = true;

                    Integer i = 0;
                    for (Database.SaveResult result : sResults) {
                        if (!result.isSuccess()) {
                            oppLineItemsToUpdate.remove(i);//BZAP-19480
                        }else {
                            i++;
                        }
                    }

                    sResults = Database.Update(oppLineItemsToUpdate, false);
                    errorMessages.addAll(CDdErrorUtilities.processSaveResults(sResults,errorMessages));
                }

            } catch (Exception e) {
                errorMessages.add(e.getMessage());
                CDdErrorUtilities.createApexLogs(errorMessages, 'CDdOpportunityTriggerHelper',
                        'createAssetsFromProducts',LoggingLevel.ERROR);
                throw e;
            }
            if(!errorMessages.isEmpty()) {
                CDdUtilities.debug(LoggingLevel.DEBUG,'ERRORS = '+errorMessages,doDebug);
                CDdErrorUtilities.createApexLogs(errorMessages, 'CDdOpportunityTriggerHelper',
                        'createAssetsFromProducts',LoggingLevel.ERROR);
            }
        }

    }

    /**
     * @author: Tia Xuan
     * @date 06/12/2019
     * @description: BZAP-5470 Moving legacy code from account to opportunity --
     *  This function finds all the accounts that were auto-imported using Formstack
     *  and then converts the unconverted formstack Leads
     *
     */
    public static void processFormStackOpportunities(List<Opportunity> newOpps){
        Integer formStackOpptyCPUUsage = 0;
        // if runOnce feature is enabled and if the method has already ran once, do not run the method again.
        if(runOnce && ranProcessFormStackOpportunities) {
            return;
        }
        List<String> errorMessages = new List<String>();
        formStackOpptyCPUUsage = CDdUtilities.calculateCPUUsage('><><><><> CDdOpportunityTriggerHelper.processFormStackOpportunities',' Start =  ',formStackOpptyCPUUsage,doCPUTimeCheck);

        List<Account> formstackAccs = new List<Account>();
        Set<Id> formstackAcctIds = new Set<Id>();
        Map<Id, Opportunity> formstackOppForAcctMap = new Map<Id, Opportunity>();
        List<Lead> leadsWithError = new List<Lead>();
        Address leadAddress;
        Address acctAddress;
        Boolean enableMergeLeads = CDdExperimentSvc.getFeatureFlag('SelfServe_Merge_Leads__c');
        Boolean setOpportunityOnLead = CDdExperimentSvc.getFeatureFlag('SelfServe_Set_Opp_On_Lead__c');
        Boolean convertLeadOnOpportunity = CDdExperimentSvc.getFeatureFlag('Convert_Formstack_Lead_on_Opportunity__c');

        if ((!Test.isRunningTest() && !convertLeadOnOpportunity) ||
            (Test.isRunningTest() && CDdAccountHelperMethods.testingAccountFormStack)){
            return;
        }

        Set<Id> newAcctIds = new Set<Id>();
        Set<Id> newOpportunityIds = new Set<Id>();
        List<Lead> leadsAfterDuplicateMerge = new List<Lead>();

        if(Test.isrunningtest()) {
            enableMergeLeads = true;
        }

        Set<Id> survivingLeadIds =  new Set<Id>();
        for (Opportunity opp : newOpps) {
            if(String.isNotBlank(opp.Converted_Lead_ID__c)
                && (opp.Converted_Lead_ID__c instanceof Id)){
                    survivingLeadIds.add(opp.Converted_Lead_ID__c);
            }
            if ((selfServeUserIds.contains(opp.CreatedById)) || Test.isRunningTest()) {
                newAcctIds.add(opp.AccountId);
            }
        }
        if (newAcctIds.size() == 0) return;

        formStackOpptyCPUUsage = CDdUtilities.calculateCPUUsage('><><><><> CDdOpportunityTriggerHelper.processFormStackOpportunities','before Quering Accounts {List=>queriedAccts}= ',formStackOpptyCPUUsage,doCPUTimeCheck);

        List<Account> queriedAccts =   [SELECT
                                            Id, Name, BillingAddress, BillingStreet, BillingCity, BillingState, BillingPostalCode,
                                            BillingCountryCode, Phone, Formstack_Mobile_Phone__c, Formstack_Email__c,
                                            L30_Total_Sales__c, Account_Type__c, OwnerId, CreatedById,
                                            (Select Id from Contacts where CreatedById in : selfServeUserIds)
                                            // should there be a limit of 1 records for getting contacts above?
                                        FROM
                                            Account
                                        WHERE Id IN :newAcctIds
                                        and CreatedById in : selfServeUserIds];
                                        // should there be another where clause for Account_Type__c Auto-Onboarding?

        formStackOpptyCPUUsage = CDdUtilities.calculateCPUUsage('><><><><> CDdOpportunityTriggerHelper.processFormStackOpportunities','After Quering Accounts {List=>queriedAccts}= ',formStackOpptyCPUUsage,doCPUTimeCheck);

        for (Account acct : queriedAccts) {
            if (acct.Account_Type__c != null
                    && acct.Account_Type__c.equalsIgnoreCase('Auto-Onboard')) {
                formstackAccs.add(acct);
                formstackAcctIds.add(acct.Id);
            }
        }

        formStackOpptyCPUUsage = CDdUtilities.calculateCPUUsage('><><><><> CDdOpportunityTriggerHelper.processFormStackOpportunities','After processing Accounts {List=>queriedAccts}= ',formStackOpptyCPUUsage,doCPUTimeCheck);

        if (formstackAccs.size() > 0) {
            List<String> possiblePhoneNumbers = new List<String>();
            Map<String, Account> emailToAcctMap = new Map<String, Account>();

            for (Account currAcct : formstackAccs) {
                String formattedPhoneNum = String.isNotBlank(currAcct.Formstack_Mobile_Phone__c)
                                                    ? CDdStringUtil.formatPhoneNum(currAcct.Formstack_Mobile_Phone__c)
                                                    : '';
                if (!String.isBlank(formattedPhoneNum) && !String.isBlank(currAcct.Formstack_Email__c)) {
                    emailToAcctMap.put(currAcct.Formstack_Email__c.toLowerCase(), currAcct);
                    possiblePhoneNumbers.addAll(CDdStringUtil.getListOfPotentialPhoneNums(formattedPhoneNum));
                }
            }

            formStackOpptyCPUUsage = CDdUtilities.calculateCPUUsage('><><><><> CDdOpportunityTriggerHelper.processFormStackOpportunities','After processing Accounts {List => formstackAccs}= ',formStackOpptyCPUUsage,doCPUTimeCheck);

            errorMessages.add('><> emails = ' + emailToAcctMap.keySet());
            errorMessages.add('><> Possible Phone #s = ' + possiblePhoneNumbers);
            Map<Id, Lead> convertingLeadsMap = new Map<Id,Lead>([
                    SELECT Id, Name, Email, Phone, IsConverted, SDR_Owner__c, Deck_Rank__c, Address, OwnerId,
                            Recent_Qualified_Activity_Date__c, createdDate, LeadSource, Lead_Source_Detail__c,
                            Owner.Type, CreatedById
                        FROM Lead
                        WHERE RecordType.DeveloperName = 'Master_Lead'
                        AND Email IN :emailToAcctMap.keyset()
                        AND Phone IN :possiblePhoneNumbers
                        AND IsConverted = false]);

            formStackOpptyCPUUsage = CDdUtilities.calculateCPUUsage('><><><><> CDdOpportunityTriggerHelper.processFormStackOpportunities','After querying Leads {Map => convertingLeadsMap} = ',formStackOpptyCPUUsage,doCPUTimeCheck);

            List<Database.LeadConvert> leadsToConvert = new List<Database.LeadConvert>();
            List<Account> acctUpdates = new List<Account>();

            // run merge leads only if the feature flag is enabled.
            errorMessages.add('><> convertingLeadsMap.values() ' + convertingLeadsMap.values());
            errorMessages.add('emableMergeLeads = ' + enableMergeLeads);
            if(enableMergeLeads && convertingLeadsMap.values() != null && convertingLeadsMap.values().size()>1){
                leadsAfterDuplicateMerge.addAll(CDdAccountHelperMethods.findAndMergeDuplicateLeads(convertingLeadsMap.values(),survivingLeadIds));
            } else {
                leadsAfterDuplicateMerge = convertingLeadsMap.values();
            }

            formStackOpptyCPUUsage = CDdUtilities.calculateCPUUsage('><><><><> CDdOpportunityTriggerHelper.processFormStackOpportunities','After Duplicate Leads merge = ',formStackOpptyCPUUsage,doCPUTimeCheck);

            // BZAP-5217 - CW Opps with missing Lead IDs
            // Query for Opportunities, if formstackAcctIds is not empty and leadsAfterDuplicateMerge is not empty
            if (setOpportunityOnLead && !leadsAfterDuplicateMerge.isEmpty() && !formstackAcctIds.isEmpty()){
                // we already have the opportunities. should we use the current opportunity?
                // this gets the latest created opportunity sicne it is indecending order and putting it in a map.
                for (Opportunity opp : [SELECT Id, AccountId
                                        FROM Opportunity
                                        WHERE AccountId IN :formstackAcctIds
                                        ORDER BY CreatedDate DESC]){
                    if (!formstackOppForAcctMap.containsKey(opp.AccountId)){
                        formstackOppForAcctMap.put(opp.AccountId, opp);
                    }
                }
            }

            formStackOpptyCPUUsage = CDdUtilities.calculateCPUUsage('><><><><> CDdOpportunityTriggerHelper.processFormStackOpportunities','After querying Opportunities = ',formStackOpptyCPUUsage,doCPUTimeCheck);

            ranProcessFormStackOpportunities = true;
            for (Lead currLead : leadsAfterDuplicateMerge) {
                // BZAP-6291 change owner to default when owner is Queue
                // BZAP-6705 Change owner to self service
                CDdUtilities.debug(LoggingLevel.DEBUG,'><> Lead ownerId 1 = '+currLead.OwnerId,doDebug);
                if(currLead.OwnerId == null || currLead.Owner.Type == 'Queue'){
                    if (currLead.CreatedById == Label.Formstack_Self_Service_Integration_User_ID){
                        currLead.OwnerId = currLead.CreatedById;
                    } else {
                        currLead.OwnerId = Id.Valueof(Label.Formstack_Self_Service_Integration_User_ID);
                    }
                }
                leadAddress = currLead.Address;
                // TODO Add error handling when email doesn't exist
                Account currAcct = emailToAcctMap.get(currLead.Email.toLowerCase());
                // if merge was performed, do not do an address check.
                errorMessages.add('><> currAccount = ' + currAcct);
                errorMessages.add('><> Lead = ' + currLead);
                CDdUtilities.debug(LoggingLevel.DEBUG,'><> Lead = '+currLead,doDebug);
                CDdUtilities.debug(LoggingLevel.DEBUG,'><> Lead ownerId= '+currLead.OwnerId,doDebug);
                if(leadMergePerformed && currAcct != NULL) {
                    errorMessages.add('><> Lead after merge = ' + currLead);
                    CDdUtilities.debug(LoggingLevel.DEBUG,'><> Lead after merge = '+currLead,doDebug);
                    Database.LeadConvert lc = new Database.LeadConvert();

                    lc.setLeadId(currLead.Id);
                    lc.setAccountId(currAcct.Id);
                    if (currAcct.Contacts.size() > 0){
                        lc.setContactId(currAcct.Contacts[0].Id);
                    }
                    lc.setOpportunityId((setOpportunityOnLead && formstackOppForAcctMap.containsKey(currAcct.Id)) ? formstackOppForAcctMap.get(currAcct.Id).Id : null);
                    lc.setConvertedStatus('Meeting Ran / Negotiated');
                    if (lc.getOpportunityId() == null){
                        lc.setDoNotCreateOpportunity(true);
                    }
                    CDdUtilities.debug(LoggingLevel.DEBUG,'Lead OwnerId = '+lc.OwnerId,doDebug);
                    leadsToConvert.add(lc);

                } else if (currAcct != NULL) {

                    acctAddress = currAcct.BillingAddress;
                    errorMessages.add('><> Lead Address = ' + leadAddress + ' ><> acct Address = ' + acctAddress);
                    CDdUtilities.debug(LoggingLevel.DEBUG,'><> Lead Address = '+leadAddress+' ><> acct Address = '+acctAddress,doDebug);
                    if(CDdStringUtil.compareAddress(leadAddress,acctAddress)){

                        errorMessages.add('><> Lead after no merge= ' + currLead);
                        CDdUtilities.debug(LoggingLevel.DEBUG,'><> Lead after no merge= '+currLead,doDebug);
                        Database.LeadConvert lc = new Database.LeadConvert();

                        lc.setLeadId(currLead.Id);
                        lc.setAccountId(currAcct.Id);
                        if (currAcct.Contacts.size() > 0){
                            lc.setContactId(currAcct.Contacts[0].Id);
                        }
                        lc.setOpportunityId((setOpportunityOnLead && formstackOppForAcctMap.containsKey(currAcct.Id)) ? formstackOppForAcctMap.get(currAcct.Id).Id : null);
                        lc.setConvertedStatus('Meeting Ran / Negotiated');
                        if (lc.getOpportunityId() == null){
                            lc.setDoNotCreateOpportunity(true);
                        }
                        CDdUtilities.debug(LoggingLevel.DEBUG,'Lead OwnerId = '+lc.OwnerId,doDebug);
                        leadsToConvert.add(lc);
                    }
                }
            }

            formStackOpptyCPUUsage = CDdUtilities.calculateCPUUsage('><><><><> CDdOpportunityTriggerHelper.processFormStackOpportunities','After lead Merge loop = ',formStackOpptyCPUUsage,doCPUTimeCheck);

            List<Database.LeadConvertResult> lcResults;
            try{
                lcResults = Database.convertLead(leadsToConvert);
            } catch (DmlException dmlEx) {
                CDdErrorUtilities.createApexLogs(new List<String>{'Lead conversion DMLException: ' + dmlEx.getMessage()}, 'CDdOpportunityTriggerHelper',
                        'processFormStackOpportunities', LoggingLevel.ERROR);
                if(dmlEx.getMessage().contains('Converted objects can only be owned by users.')) {
                    CDdUtilities.debug(LoggingLevel.DEBUG,' ######I am inside DML Exception',doDebug);
                    for(Database.LeadConvert tempLeadConvert : leadsToConvert) {
                        tempLeadConvert.setOwnerId(Id.valueOf(Label.Formstack_Self_Service_Integration_User_ID));
                    }
                    lcResults = Database.convertLead(leadsToConvert);
                } else {
                    throw dmlEx;
                }
            } catch(Exception ex) {
                CDdErrorUtilities.createApexLogs(new List<String>{'Lead conversion Exception: ' + ex.getMessage()}, 'CDdOpportunityTriggerHelper',
                        'processFormStackOpportunities', LoggingLevel.ERROR);
                CDdUtilities.debug(LoggingLevel.DEBUG,'################WOAH',doDebug);
                throw ex;
            }

            formStackOpptyCPUUsage = CDdUtilities.calculateCPUUsage('><><><><> CDdOpportunityTriggerHelper.processFormStackOpportunities','After lead Conversion =  ',formStackOpptyCPUUsage,doCPUTimeCheck);

            for (Integer i = 0; i < lcResults.size(); i++) {
                Lead currLead = convertingLeadsMap.get(leadsToConvert.get(i).getLeadID());

                if (!lcResults.get(i).isSuccess() || Test.isRunningTest()) {
                    currLead.Auto_Conversion_Failed__c = true;
                    errorMessages.add('Lead conversion ' + currLead.id + 'failed: ' + lcResults.get(i).getErrors());
                    leadsWithError.add(currLead);
                }
            }
            if (leadsWithError.size() > 0 && !Test.isRunningTest()) {
                upsert(leadsWithError);
            }

            formStackOpptyCPUUsage = CDdUtilities.calculateCPUUsage('><><><><> CDdOpportunityTriggerHelper.processFormStackOpportunities','After errored Lead update =  ',formStackOpptyCPUUsage,doCPUTimeCheck);

            // upsert acctUpdates;
            // nothing is being added to acctUpdates
            if(errorMessages.size() > 0) {
                CDdErrorUtilities.createApexLogs(errorMessages, 'CDdOpportunityTriggerHelper',
                        'processFormStackOpportunities', LoggingLevel.ERROR);
            }

            formStackOpptyCPUUsage = CDdUtilities.calculateCPUUsage('><><><><> CDdOpportunityTriggerHelper.processFormStackOpportunities','After error Util inserts =  ',formStackOpptyCPUUsage,doCPUTimeCheck);

        }
    }

    /*
     * @author:      Jeegar Brahmakshatriya
     * @date:        2019-08
     * @description: BZAP-5474 Do not allow creation of marketplace Opportunities on Accounts that have an active Lead attached.
     */

    public static void donotAllowCreationOfOpportunities(List<Opportunity> newOpportunities) {
        // if runOnce feature is enabled and if the method has already ran once, do not run the method again.
        if(runOnce && ranDonotAllowCreationOfOpportunities) {
            return;
        }

        Map<Id, Id> opportunityIdAccountIdMap = new Map<Id,Id>();
        Map<Id, Integer> accountIdLeadCountMap = new Map<Id,Integer>();
        Set<Id> accountIdSet = new Set<Id>();
        Id marketPlaceRTId;
        Id masterLeadRTId;
        List<String> leadStatus = Label.DonotAllowOppWithLeadStatuses.split(',');
        List<Lead> leads;
        Set<Id> leadIdSet = new Set<Id>();
        Id formstackUserId;
        Id selfServeUserId;
        List<Id> selfServeUserIds = new List<Id>();

        List<Self_Serve_Users__c> selfServeUsers = Self_Serve_Users__c.getAll().values();
        for(Self_Serve_Users__c ssUser : selfServeUsers) {
            if(ssUser.name.contains('formstack')){
                formstackUserId = ssUser.User_Id__c;
            } else if (ssUser.name.contains('mx-eng-api')) {
                selfServeUserId = ssUser.User_Id__c;
            }
            selfServeUserIds.add(ssUser.User_Id__c);
        }

        List<Record_Type_Values__mdt> recordTypes = [SELECT QualifiedApiName, Record_Type_Id__c
                                                        FROM Record_Type_Values__mdt
                                                        WHERE QualifiedApiName in ('Opportunity_Marketplace' , 'Lead_Master_Lead')];
        for(Record_Type_Values__mdt recordType : recordTypes) {
            if(recordType.QualifiedApiName == 'Opportunity_Marketplace') {
                marketPlaceRTId = Id.valueOf(recordType.Record_Type_Id__c);
            } else if(recordType.QualifiedApiName == 'Lead_Master_Lead') {
                masterLeadRTId = Id.valueOf(recordType.Record_Type_Id__c);
            }
        }

        for(Opportunity currOpp : newOpportunities) {
            if(currOpp.RecordTypeId == marketPlaceRTId
                    && currOpp.AccountId != null
                    && !selfServeUserIds.contains(currOpp.CreatedById) ) {
                opportunityIdAccountIdMap.put(currOpp.AccountId, currOpp.Id);
                accountIdSet.add(currOpp.AccountId);
            }
        }

        leads = [SELECT Id, Account__c FROM Lead where RecordTypeId = :masterLeadRTId
                                                    AND Account__c in :accountIdSet
                                                    AND isconverted = false
                                                    AND Status NOT IN :leadStatus];

        for(Lead currLead : leads) {

            if(accountIdLeadCountMap.containsKey(currLead.Account__c)) {
                accountIdLeadCountMap.put(currLead.Account__c, accountIdLeadCountMap.get(currLead.Account__c) + 1);
            } else {
                accountIdLeadCountMap.put(currLead.Account__c, 1);
            }
        }

        for(Opportunity currOpp : newOpportunities){
            ranDonotAllowCreationOfOpportunities = true;
            if(currOpp.RecordTypeId == marketPlaceRTId
                    && currOpp.AccountId != null) {
                if(accountIdLeadCountMap.get(currOpp.AccountId) > 1) {
                    currOpp.addError(Label.DonotAllowOppWithLeadError);
                } else if(accountIdLeadCountMap.get(currOpp.AccountId) == 1
                        && currOpp.Converted_Lead_Id__c != null
                        && leadIdSet.contains(Id.valueOf(currOpp.Converted_Lead_Id__c))) {
                    currOpp.addError(Label.DonotAllowOppWithLeadError);
                }
            }
        }
    }
    /**
     * @author: Tia Xuan
     * @date 03/2020
     * @description: BZAP-5959 APEX timeout error on case_post_sale_handoff PB
     * @author: Knick (updated)
     * @date 03/2020
     * @description: BZAP-6564 Update Opportunity Amount from Account Amount
     * @author: Tia Xuan (updated)
     * @date 05/2020
     * @description: BZAP-7488 "Requesting Account Management" Code Copy adjustment
     *
     */
    public static void copyRequestAccountManagementToParentAccount(List<Opportunity> newOpps, Map<Id, Account>accMap) {
        // if runOnce feature is enabled and if the method has already ran once, do not run the method again.
        if (runOnce && ranCopyRequestAccountManagementToParentAccount) return;
        else ranCopyRequestAccountManagementToParentAccount = true;

        String marketRTId = CDdSchemaUtils.OPPORTUNITY_RT.mlInsideSalesId();

        List<Opportunity> oppList = new List<Opportunity>();
        List<Id> accountIdList = new List<Id>();
        for (Opportunity opp : newOpps){
            if (opp.RecordTypeId == marketRTId
                && opp.AccountId != null
                // && opp.IsClosed == false // BZAP-6564 check later
                && opp.StageName != 'Closed Lost'){
                oppList.add(opp);
                accountIdList.add(opp.AccountId);
            }
        }

        if (accountIdList.size() > 0) {
            // BZAP-7488
            List<Account> accToUpdate = new List<Account>();
            for (Opportunity opp : oppList) {   // Next pass is checking divergent criteria
                if (accMap.containsKey(opp.AccountId)) {
                    Account acc = accMap.get(opp.AccountId);
                    if (acc.ParentId != null
                        && opp.IsClosed == false        // BZAP-6564
                        && acc.Parent.Requesting_Account_Management__c != null
                        && opp.Requesting_Account_Management__c != acc.Parent.Requesting_Account_Management__c) {
                            // BZAP-7488
                            if (opp.Requesting_Account_Management__c == 'No'){
                                Account accParent = new Account();
                                accParent.Id = acc.ParentId;
                                accParent.Requesting_Account_Management__c = opp.Requesting_Account_Management__c;
                                accToUpdate.add(accParent);
                            } else {
                                opp.Requesting_Account_Management__c = acc.Parent.Requesting_Account_Management__c;
                            }
                    }
                }
            }

            // BZAP-7488
            if (accToUpdate.size() > 0) {
                update accToUpdate;
            }
        }

    }

    /**
     * @author: Tia Xuan
     * @date 03/2020
     * @description: BZAP-6950 Changing PB to Trigger -- Stamp Pricing Tier and Package Values on Closed Won
     *
     */
    public static void stampPricingTierPackageOnClosedWon(List<Opportunity> newOpps, Map<Id, Opportunity> oldOpportunities, Map<Id, Account> accMap){
        String marketRTId = Schema.SObjectType.Opportunity
                                .getRecordTypeInfosByName().get('Marketplace')
                                .getRecordTypeId();
        String postSaleRTId = Schema.SObjectType.Opportunity
                                .getRecordTypeInfosByName().get('Post Sale')
                                .getRecordTypeId();
        String enterpriseMarketplaceRTId = Schema.SObjectType.Opportunity
                                .getRecordTypeInfosByName().get('Enterprise Marketplace')
                                .getRecordTypeId();
        Set<String> recordIdList = new Set<String>{marketRTId, postSaleRTId, enterpriseMarketplaceRTId};

        List<Opportunity> affectedOpps = new List<Opportunity>();
        List<Account> accToUpdate = new List<Account>();
        for (Opportunity opp : newOpps){
            Account acc = new Account();

            if (opp.Trial_Package__c <> null) {
                opp.Package_Sold__c = opp.Trial_Package__c;
            }

            if (accMap.containsKey(opp.AccountId))
                acc = accMap.get(opp.AccountId);
            if ((oldOpportunities == null || opp.StageName != oldOpportunities.get(opp.Id).StageName)
                    && opp.StageName == 'Closed Won'
                    && recordIdList.contains(opp.RecordTypeId)
                    && opp.AccountId != null
                    && opp.Commission__c != null
                    && String.isNotBlank(acc.RealZip__RealZip__c)
                    && String.isNotBlank(opp.Pricing_Tier_New__c)
                    && opp.Service_Fee_New__c != null
                    && String.isNotBlank(opp.Qualified_Package__c)) {
                opp.Basic_Floor_CW__c = opp.Basic_Floor__c;
                opp.DashPass_Eligible_CW__c = opp.DashPass_Eligible__c;
                opp.DashPass_Floor_CW__c = opp.DashPass_Floor__c;
                opp.Deck_Rank_CW__c = acc.Deck_Rank__c;
                opp.Package_Sold__c = opp.Qualified_Package__c;
                opp.Premium_Floor_CW__c = opp.Premium_Floor__c;
                opp.Pricing_Tier_CW__c = opp.Pricing_Tier_New__c;
                opp.Service_Fee_CW__c = opp.Service_Fee_New__c;
                opp.Trial_Pricing_Tier_CW__c = opp.Trial_Pricing_Tier__c;
                //opp.Trial_Service_Fee_CW__c = opp.Trial_Service_Fee_CW__c;
                opp.UCR_Floor_Commission_CW__c = opp.UCR_Floor_Commission__c;

                acc.Package_Sold__c = opp.Qualified_Package__c;
                accToUpdate.add(acc);
            }
        }

        if (accToUpdate.size() > 0){
            update accToUpdate;
        }
    }

    /**
     * @author: Tia Xuan
     * @date 03/2020
     * @description: BZAP-6950 Changing PB to Trigger -- CW Opp Sets Delivery Fee
     *
     */
    public static void cwOppSetsDeliveryFee(List<Opportunity> newOpps, Map<Id, Opportunity> oldOpportunities){

        for (Opportunity opp : newOpps){
            if (oldOpportunities == null ||
                opp.Package_Sold__c != oldOpportunities.get(opp.Id).Package_Sold__c) {

                if (opp.Package_Sold__c == 'Premier'){
                    opp.Delivery_Fee_CW__c = opp.Premium_Delivery_Fee__c;
                } else if (opp.Package_Sold__c == 'Plus'){
                    opp.Delivery_Fee_CW__c = opp.Basic_Delivery_Fee__c;
                } else {
                    opp.Delivery_Fee_CW__c = null;
                }
            }
        }
    }

   /**
     * @author: Tia Xuan
     * @date 03/2020
     * @description: BZAP-6950 Changing PB to Trigger -- Formstack - Update Order Protocol
     *
     */
    public static void formstackUpdateOrderProtocol(List<Opportunity> newOpps, Map<Id, Account> accMap){
        if (formstackDeprecated) {
            return;
        }
        for (Opportunity opp : newOpps){
            Account acc = new Account();
            if (accMap.containsKey(opp.AccountId))
                acc = accMap.get(opp.AccountId);
            if (opp.Order_Protocol__c != null
                && opp.AccountId != null
                && acc.BillingCountryCode == 'CA'
                && acc.Formstack_Version__c != null
                && (acc.Formstack_Version__c  == 'New Store'
                    || acc.Formstack_Version__c  == 'SSMO Redirect')
                && opp.Formstack_Order_Protocol__c != 'french') {
                opp.Order_Protocol_Email__c = opp.Formstack_Order_Protocol_Email__c;
                opp.Order_Protocol_Fax__c = opp.Formstack_Order_Protocol_Fax__c;
                opp.PactSafe_Contract_Type__c = 'English Canada Sign Up Sheet';
                opp.Tablet_Delivery_Method__c = '';

                opp.Weekly_Printer_Subscription_Fee__c = '';
                if (opp.Order_Protocol__c == 'Tablet and Printer (DoorDash Owns)'){
                    opp.Weekly_Printer_Subscription_Fee__c = helperSetting.Weekly_Printer_Sub_Fee__c;
                }
                opp.Weekly_Tablet_Subscription_Fee__c = '';
                if (opp.Order_Protocol__c == 'Tablet (DoorDash Owns)' ||
                    opp.Order_Protocol__c == 'Tablet and Printer (DoorDash Owns)'){
                    opp.Weekly_Tablet_Subscription_Fee__c = helperSetting.Weekly_Tablet_Sub_Fee__c;
                }
            }

            if (opp.Formstack_Order_Protocol__c != null
                && opp.AccountId != null
                && acc.Formstack_Version__c != null
                && (acc.Formstack_Version__c  == 'New Store'
                    || acc.Formstack_Version__c  == 'SSMO Redirect')
                && opp.Formstack_Order_Protocol__c != 'french') {
                opp.Order_Protocol__c = opp.Formstack_Order_Protocol__c;
                opp.Tablet_Delivery_Method__c = '';
                if (opp.Formstack_Order_Protocol__c == 'Tablet (DoorDash Owns)' ||
                    opp.Formstack_Order_Protocol__c == 'Tablet and Printer (DoorDash Owns)'){
                    opp.Tablet_Delivery_Method__c = 'Drop-ship';
                }
                opp.Weekly_Printer_Subscription_Fee__c = '';
                if (opp.Formstack_Order_Protocol__c == 'Tablet and Printer (DoorDash Owns)'){
                    opp.Weekly_Printer_Subscription_Fee__c = helperSetting.Formstack_Weekly_Printer_Sub_Fee__c;
                }
                opp.Weekly_Tablet_Subscription_Fee__c = '';
                if (opp.Formstack_Order_Protocol__c == 'Tablet (DoorDash Owns)' ||
                    opp.Formstack_Order_Protocol__c == 'Tablet and Printer (DoorDash Owns)'){
                    opp.Weekly_Tablet_Subscription_Fee__c = helperSetting.Formstack_Weekly_Tablet_Sub_Fee__c;
                }

            }

            if ( opp.Formstack_Order_Protocol__c == 'french'
                        && (opp.Order_Protocol__c == 'Tablet (DoorDash Owns)'
                            || opp.Order_Protocol__c == 'Tablet and Printer (DoorDash Owns)')){
                opp.Weekly_Printer_Subscription_Fee__c = '';
                if (opp.Order_Protocol__c == 'Tablet and Printer (DoorDash Owns)'){
                    opp.Weekly_Printer_Subscription_Fee__c = helperSetting.French_Weekly_Printer_Sub_Fee__c;
                }
                opp.Weekly_Tablet_Subscription_Fee__c = helperSetting.French_Weekly_Tablet_Sub_Fee__c;
            }
        }
    }

    /**
     * @author: Knick
     * @date 04/2020
     * @description: BZAP-6564 Changing PB to Trigger -- Formstack - Related McDs DM to Account
     *
     */
    public static void FormstackRelatedUpdates (List<Opportunity> newOpps, Map<Id, Opportunity> oldOpportunities) {
        List<Account> Accounts = new List<Account>();
        List<Contact> Contacts = new List<Contact>();
        if (formstackDeprecated) {
            return;
        }
        for (Opportunity opp : newOpps) {
            Opportunity oldOpp = (oldOpportunities == null) ? null : oldOpportunities.get(opp.Id);
            if ((opp.Franchise_Formstack__c == true)
            && (opp.Decision_Maker__c != null)
            && (opp.Formstack_Submission_ID__c != null)
            && (opp.Account_Number__c != null)
            && (opp.Routing_Number__c != null)
            && (opp.EIN__c != null)
            && (opp.Legal_Business_Name__c != null)
            && ((oldOpp == null) ||
                (opp.Account_Number__c != oldOpp.Account_Number__c) ||
                (opp.Routing_Number__c != oldOpp.Routing_Number__c) ||
                (opp.EIN__c != oldOpp.EIN__c) ||
                (opp.Legal_Business_Name__c != oldOpp.Legal_Business_Name__c))
               ) {
                Account newAccount = new Account(Id = opp.AccountId);
                newAccount.Bank_Account_Number_Encrypted__c = opp.Account_Number__c;
                newAccount.Bank_Routing_Number_Encrypted__c = opp.Routing_Number__c;
                newAccount.EIN_Encrypted__c = opp.EIN__c;
                newAccount.Legal_Business_Name__c = opp.Legal_Business_Name__c;
                Accounts.add(newAccount);
                Contact newContact = new Contact(Id = opp.Decision_Maker__c);
                newContact.AccountId = opp.AccountId;
                Contacts.add(newContact);
            }
        }
        if (Accounts.size() > 0) update Accounts;
        if (Contacts.size() > 0) update Contacts;
    }

    /**
     * @author: Knick
     * @date 04/2020
     * @description: BZAP-6564 Changing PB to Trigger -- Formstack - SSMO Trial
     *  MOST OF THIS HAS MOVED TO WORKFLOW except for setting the Primary Campaign Source which cannot be done in workflow
     */
    public static void FormstackSSMOtrial (List<Opportunity> newOpps) {
        for (Opportunity opp : newOpps) {
            if (opp.Notes__c == helperSetting.Caviar_Promo_Notes__c) {      // Caviar Promo
                opp.CampaignId = helperSetting.Caviar_Promo_Campaign_Id__c;
            }
        }
    }

    public static void updateManager(List<Opportunity> opps, Map<Id, Opportunity> oldMap){
        Set<Id> oppsOwnerIds = new Set<Id>();
        List<Opportunity> oppsWithNewOwners = new List<Opportunity>();
        for (Opportunity opp : opps) {
            if (opp.OwnerId != oldMap.get(opp.Id).OwnerId) {
                oppsOwnerIds.add(opp.OwnerId);
                oppsWithNewOwners.add(opp);
            }
        }
        if(oppsWithNewOwners.isEmpty()){
            return;
        }
        Map<Id, User> newOwners = new Map<Id, User>([SELECT Id, ManagerId FROM User WHERE Id IN :oppsOwnerIds]);
        for(Opportunity opp: oppsWithNewOwners){
            opp.Manager__c = newOwners.get(opp.OwnerId).ManagerId;
        }
    }

    public static void createNetSuiteAccount(List<Opportunity> newOpps, Map<Id, Opportunity> oldOpportunities){
        if(!Test.isRunningTest() && (system.isBatch() || system.isFuture() || system.isQueueable() || system.isScheduled())){
           return;
        }
        boolean createNSAccount = false;
        Map<String, String> oppIdToAccountId = new Map<String, String>();
        for(Opportunity opp: newOpps){
            createNSAccount = opp.StageName == 'Contract Signed' &&
                (opp.StageName != oldOpportunities.get(opp.Id).StageName || opp.Payment_Account__c != oldOpportunities.get(opp.Id).Payment_Account__c) &&
                opp.Payment_Protocol__c == 'Invoicing' && opp.PactSafe_Record__c != null && opp.Payment_Account__c != null &&
                (opp.Payment_Account_NetSuite_ID__c == null || (opp.RecordTypeId == oppMarketplaceRTID && opp.Legal_Entity__c == 'US - G&C')) && netsuiteOppRecordTypeIds.contains(opp.RecordTypeId);
            if(createNSAccount){
                oppIdToAccountId.put(opp.Payment_Account__c, opp.AccountId);
            }
        }
        if(oppIdToAccountId.isEmpty()){
            return;
        }
        NetSuiteRequestHandler.sendPaymentAccountCreationRequest(oppIdToAccountId);
    }

    /**
     * @author: Knick
     * @date 04/2020
     * @description: BZAP-7363 Convert Opportunity PBs to trigger -- Activate Centrally for Enterprise
     */
    public static void ActivateCentrallyForEnterprise (List<Opportunity> opps, Map<Id, Opportunity> oldMap, Map<Id, Account> accMap) {
        if (CDdCustomMetaData.isDisabled('CDdOpportunityTrigger_ActivateCentrally')) return;
        for (Opportunity opp : opps) {
            if ((opp.AccountId != null)
            &&  (opp.RecordTypeId == enterpriseMarketplaceRecordTypeId)
            &&  (opp.StageName == STAGE_NAME_CLOSED_WON)) {

                Account acc = (accMap == null) ? null : accMap.get(opp.AccountId);
                Opportunity oldOpp = (oldMap == null) ? null : oldMap.get(opp.Id);
                Boolean oppStageHasChanged = ((oldOpp != null) && (oldOpp.StageName != STAGE_NAME_CLOSED_WON));

                if ((acc != null)
                &&  (oppStageHasChanged)
                &&  ((acc.In_Coverage__c == 'No') || (acc.In_Coverage__c == 'Unknown'))) {
                    opp.Activate_Centrally_2__c = 'No';
                    opp.Activate_Centrally_No_Validation__c = 'Not in coverage';
                }
            }
        }
    }


    /**
     * @author: Knick
     * @date 11/2020
     * @description: BZAP-7363 Convert Opportunity PBs to trigger -- Formstack Canada Contract Type
    */
    public static void formstackCanadaContractType(List<Opportunity> opps, Map<Id, Account> accMap) {
        if (formstackDeprecated) {
            return;
        }
        if (CDdCustomMetaData.isDisabled('CDdOpportunityTrigger_formstackCanadaCT')) return;
        for (Opportunity opp : opps) {
            if ((opp.AccountId != null)
            &&  (opp.StageName != 'Closed Won')
            &&  (opp.StageName != 'Closed Lost')
            &&  (opp.Lead_Source_Detail__c != 'GYS')
            &&  (opp.RecordTypeId == oppMarketplaceRTID)) {
                Account acc = (accMap == null) ? null : accMap.get(opp.AccountId);
                if ((acc != null)
                &&  (acc.Formstack_Version__c == 'Sales Rep')
                &&  (acc.BillingCountryCode == 'Canada')) {
                    opp.PactSafe_Contract_Type__c = 'English Canada Sign Up Sheet';
                }
            }
        }
    }
    /**
     * BZAP-8973: Concatenate Marketing_UUID__c
     */
    public static void concatenateMarketingUUID(List<Opportunity> opps, Map<Id, Opportunity> oldMap) {
        List<String> newMarketingUUIDs = new List<String>();
        for (Opportunity opp : opps) {
            String oldUUID = oldMap.get(opp.Id).Marketing_UUID__c;
            String newUUID = opp.Marketing_UUID__c;
            if (newUUID != null && oldUUID != null && !newUUID.equals(oldUUID)) {
                for (String currUUID : oldUUID.split(',')) {
                    newMarketingUUIDs.add(currUUID.trim());
                }
                for (String currUUID : newUUID.split(',')) {
                    currUUID = currUUID.trim();
                    if (!newMarketingUUIDs.contains(currUUID)) {
                        newMarketingUUIDs.add(currUUID);
                    }
                }
                opp.Marketing_UUID__c = String.join(newMarketingUUIDs, ', ' );
            }
            newMarketingUUIDs.clear();
        }
    }

    /**
    * BZAP-9821: Default picklist values
    * @Author: Mani
    * 21th April, 2021
    * Modified on 2nd Aug 2021, To include Germany default value changes - BZAP-11287
    */
    public static void setDefaultPicklistValuesBasedOnCountry(List<Opportunity> opps) {
        if (CDdCustomMetaData.isDisabled('CDdOpportunityTrigger_setDefaultValue')) return;
        CDdI18nDefaultValueMappingUtil.setDefaultValuesBasedOnCountry(opps, 'Lead_Country__c');
    }

    public static void setDefaultValueOnMarketplaceOpps(List<Opportunity> opps){
        if (CDdCustomMetaData.isDisabled('CDdOpportunityTrigger_setDefaultValue')) return;
        boolean isNewPartnerMarketplaceOpp = false;
        for(Opportunity opp: opps){
            if(opp.recordTypeId == oppMarketplaceRTId)
            {
               opp.SQO_Date__c = Date.Today();
            }
            isNewPartnerMarketplaceOpp = opp.Type == 'New Partner' &&
                    (OPP_RT_INFO_BY_NAME.get('Marketplace').getRecordTypeId() == opp.RecordTypeId ||
                    OPP_RT_INFO_BY_NAME.get('Enterprise Marketplace').getRecordTypeId() == opp.RecordTypeId);
            if(!isNewPartnerMarketplaceOpp){
                continue;
            }
            if( String.isBlank(opp.Menu_To_Be_Completed_By__c)){
                opp.Menu_to_be_Completed_By__c = 'DoorDash Onboarding Team';
                opp.Menu_Setup_Method__c = 'Create New Menu(s) using Menu Source';
            }
            if(opp.Tablet_Delivery_Method__c == 'Drop-ship' && String.isBlank(opp.Tablet_Kit_Type__c)){
                opp.Tablet_Kit_Type__c  = 'Standard';
            }
        }
    }

    public static void updateMOCaseAndMilestones(List<Opportunity> opps, Map<Id, Opportunity> oldMap){
        if (CDdCustomMetaData.isDisabled('CDdOpportunityTrigger_SSME')) return;
        if (ranUpdateMOCaseAndMilestones) return;
        Set<Id> mpRTIds = new Set<Id>{
            OPP_RT_INFO_BY_NAME.get('Marketplace').getRecordTypeId(),
            OPP_RT_INFO_BY_NAME.get('Enterprise Marketplace').getRecordTypeId()
        };
        Id onboardingCaseRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Marketplace Onboarding').getRecordTypeId();
        boolean isClosedWonMarketplaceOpp = false;
        boolean hasMxOptedForSelfOnboarding = false;
        boolean hasMxSelfOnboardingDeadlineExpired = false;
        Set<Id> ssOppIds = new Set<Id>();
        Set<Id> mxOptedInOppIds = new Set<Id>();
        Set<Id> mxSelfOnboardExpiredOppIds = new Set<Id>();
        Map<Id, Case> onboardingCases = new Map<Id, Case>();
        Id selfOnboardingQueueId;
        Id ssmePendingQueueId;
        Id selfOnboardingEscalationQueueId;
        for(Group q: [SELECT Id, Name FROM Group WHERE Type = 'QUEUE' AND Name IN ('Onboarding - SSME Pending','Onboarding - Menu Ready for QA','Onboarding - New Partner Escalations')]){
            if(q.Name == 'Onboarding - Menu Ready for QA'){
                selfOnboardingQueueId = q.Id;
            }
            else if (q.Name == 'Onboarding - SSME Pending') {
                ssmePendingQueueId = q.Id;
            }
            else{
                selfOnboardingEscalationQueueId = q.Id;
            }
        }
        for(Opportunity opp: opps){
            isClosedWonMarketplaceOpp = opp.StageName == 'Closed Won'
                &&  mpRTIds.contains(opp.RecordTypeId);
            if(!isClosedWonMarketplaceOpp){
                continue;
            }
            hasMxOptedForSelfOnboarding = opp.SSME_Menu_Completion_Date_Time__c != oldMap.get(opp.Id).SSME_Menu_Completion_Date_Time__c
                && opp.SSME_Menu_Completion_Date_Time__c != null
                && opp.Menu_to_be_completed_by__c == 'Merchant';
            hasMxSelfOnboardingDeadlineExpired = opp.SSME_Escalation_Date_Time__c != oldMap.get(opp.Id).SSME_Escalation_Date_Time__c
                && opp.SSME_Escalation_Date_Time__c != null
                && opp.Menu_to_be_completed_by__c == 'DoorDash Onboarding Team';
            if(hasMxOptedForSelfOnboarding){
                ssOppIds.add(opp.Id);
                mxOptedInOppIds.add(opp.Id);
            }
            if(hasMxSelfOnboardingDeadlineExpired){
                ssOppIds.add(opp.Id);
                mxSelfOnboardExpiredOppIds.add(opp.Id);
            }
        }
        if(ssOppIds.isEmpty()){
            return;
        }
        for(Case c: [SELECT Id, OwnerId, Opportunity_Name__c FROM Case WHERE RecordTypeId = :onboardingCaseRTId
                AND Status != 'Blocked' AND IsClosed = false AND Opportunity_Name__c IN :ssOppIds AND ownerId = :ssmePendingQueueId FOR UPDATE]){
            if(mxOptedInOppIds.contains(c.Opportunity_Name__c)){
                c.OwnerId = selfOnboardingQueueId;
            }
            if(mxSelfOnboardExpiredOppIds.contains(c.Opportunity_Name__c)){
                c.OwnerId = selfOnboardingEscalationQueueId;
            }
            onboardingCases.put(c.Id,c);
        }
        Database.DMLOptions dmlOp = new Database.DMLOptions();
        dmlOp.assignmentRuleHeader.useDefaultRule = false;
        dmlOp.assignmentRuleHeader.assignmentRuleId = null;
        Database.update(onboardingCases.values(), dmlOp);
        CDdGenericPlatformEventHelper.publishEvents(
            CDdGenericPlatformEventHelper.PlatformEventType.SETUP_MENU_MILESTONE, ssOppIds);
        ranUpdateMOCaseAndMilestones = true;
    }

    public static void handleSetupMenuMilestones(List<Generic_Platform_Event__e> smEvents){
        if (CDdCustomMetaData.isDisabled('CDdOpportunityTrigger_SSME')) return;
        Set<Id> oppIds = new Set<Id>();
        List<Milestone__c> milestonesToUpdate = new List<Milestone__c>();
        Id smRT = MILESTONES_RT_INFO.get('Setup Menu').getRecordTypeId();
        for (Generic_Platform_Event__e e : smEvents) {
            oppIds.add(e.sObjectId__c);
        }
        for(Milestone__c m: [SELECT Status__c, Status_Reason__c, Case__r.Opportunity_Name__r.Menu_to_be_completed_by__c FROM Milestone__c
                WHERE RecordTypeId = :smRT AND Case__r.Opportunity_Name__c IN :oppIds]){
            if(m.Case__r.Opportunity_Name__r.Menu_to_be_completed_by__c == 'Merchant'){
                m.Status__c = 'Ready for QA';
                m.Status_Reason__c = null;
            }else if(m.Case__r.Opportunity_Name__r.Menu_to_be_completed_by__c == 'DoorDash Onboarding Team'){
                m.Status__c = 'Escalated';
                m.Status_Reason__c = 'SSME to Doordash';
            }
            milestonesToUpdate.add(m);
        }
        update milestonesToUpdate;
    }
    /**
     * @description BZAP-11227 - Improve automation that generates missing Milestones
     */
    public static void createMissingMilestonesPostOppClose(List<Opportunity> opps, Map<Id, Opportunity> oldMap){
        Set<Id> eligibleRecordTypeIds = new Set<Id>{OPP_RT_INFO_BY_NAME.get('Marketplace').getRecordTypeId(), OPP_RT_INFO_BY_NAME.get('Enterprise Marketplace').getRecordTypeId()};
        Set<Id> opportunityIdsToProcess = new Set<Id>();
        Set<Id> caseIds = new Set<Id>();
        for(Opportunity opp : opps){
            if (eligibleRecordTypeIds.contains(opp.RecordTypeId) && (opp.StageName == 'Closed Won' && opp.StageName == oldMap.get(opp.Id).StageName)){
                opportunityIdsToProcess.add(opp.Id);
            }
        }
        if (!opportunityIdsToProcess.isEmpty()){
            for(Case c:  [SELECT Id FROM Case WHERE Opportunity_Name__c IN :opportunityIdsToProcess]){
                caseIds.add(c.Id);
            }
            if (!caseIds.isEmpty()){
                CDdMilestoneGeneratorSetting.createMilestones('Case', caseIds);
            }
            ranCreateMilestonesPostOppClose = true;
        }
    }
    /**
     * BZAP-9681: Set Business Verification Document Attached flag on the opportunity records for eligible Account Identifiers
     * Process the following Opportunities
     * 1. Opportunties inserted/created
     * 2. Opoortunties updated but Business_Verification_Document_Attached__c flag was not changed
     *
     */
    public static void setBusinessVerificationDocumentAttached(List<Opportunity> newOpps, Map<Id, Opportunity> oldOpps, Map<Id, Account> accMap) {
        if (ranSetBusinessVerificationDocumentAttached) { return; }
        Set<Id> accountIdsToProcess = new Set<Id>();
        for (Opportunity newOpp : newOpps){
            if (oldOpps == null
                ||
                (newOpp.Business_Verification_Document_Attached__c ==  oldOpps.get(newOpp.Id).Business_Verification_Document_Attached__c)){
                if (String.isNotBlank(newOpp.AccountId) && accMap.containsKey(newOpp.AccountId) && accMap.get(newOpp.AccountId).Merchant_Documents__r!=null && !accMap.get(newOpp.AccountId).Merchant_Documents__r.isEmpty()){
                    accountIdsToProcess.add(newOpp.AccountId);
                }
            }
        }
        if (!accountIdsToProcess.isEmpty()){
            CDdGenericPlatformEventHelper.publishEvents(
                CDdGenericPlatformEventHelper.PlatformEventType.OPP_BIZ_VERIFICATION_DOC_ATTACHED, accountIdsToProcess);
            ranSetBusinessVerificationDocumentAttached = true;
        }
    }
    /**
     * @description: BZAP-10239 - Set the DashPass eligible fields on the Opportunity
     * Applies to the Opportunity record that belongs to
     * - Record Type - Marketplace, Enterprise Marketplace or Post Sale
     * - Stage Name - Meeting Ran / Negotiated or Ready for Signature
     * Note: This method is executed in the Before Trigger event (applies to insert and update)
     * @param List<Opportunity> Collection of new Opportunity records
     * @param List<Opportunity> Collection of old Opportunity records (applied to update trigger events)
     * @param Map<Id, Account> Collection of pre-queried Account records (relevant field - DashPass_Eligibility_Override__c)
     * @return
     */
    public static void setDashPassEligible(List<Opportunity> newOpps, Map<Id, Opportunity> oldOpportunities, Map<Id, Account> accountMap){
        if (ranSetDashPassEligible) { return; }
        Set<Id> dashPassEligibleRecordTypeIds = new Set<Id>{marketplaceRecordTypeId, enterpriseMarketplaceRecordTypeId, postSaleRecId};
        Set<String> dashPassEligibleStageNames = new Set<String>{STAGE_NAME_MEETING_RAN_NEGOTIATED, STAGE_NAME_READY_FOR_SIGNATURE};
        Set<String> marketPlaceExcludedStageNames = new Set<String>{STAGE_NAME_CONTRACT_SIGNED,STAGE_NAME_CLOSED_WON, STAGE_NAME_CLOSED_LOST};
        Set<String> enterpriseMarketPlaceExcludedStageNames = new Set<String>{STAGE_NAME_CLOSED_WON, STAGE_NAME_CLOSED_LOST};
        Set<String> dashPassEligibleFieldApiNamesToEvaluate = new Set<String>{'RecordTypeId','StageName','AccountId','Commission__c','DashPass_Only_Commission__c','DashPass_Flat_Fee__c','DealDesk_Approved_del__c','DashPass_Eligibility_Override_Approved__c'};
        List<String> BILLING_COUNTRY = new List<String>{'Japan'};

        Boolean enableDashPassCheckNew = CDdExperimentSvc.getCustomSettingFeatureFlag('Enable_Dash_Pass_Check_New__c');

        for (Opportunity newOpp : newOpps){
            Boolean dashPassCheckMet = false;

            if (enableDashPassCheckNew) {
                // BASD-29889 Bypass the DashPass eligible fields population for Japan Opportunities
                if ((oldOpportunities ==  null ||
                        (newOpp.RecordTypeId == marketplaceRecordTypeId && !marketPlaceExcludedStageNames.contains(newOpp.StageName)) ||
                        (newOpp.RecordTypeId == enterpriseMarketplaceRecordTypeId && !enterpriseMarketPlaceExcludedStageNames.contains(newOpp.StageName))) && !BILLING_COUNTRY.contains(newOpp.Account_Billing_Country__c)) {
                    dashPassCheckMet = true;
                }
            } else if (dashPassEligibleRecordTypeIds.contains(newOpp.RecordTypeId) && dashPassEligibleStageNames.contains(newOpp.StageName) && !BILLING_COUNTRY.contains(newOpp.Account_Billing_Country__c) ) {
                dashPassCheckMet = true;
            }

            if (dashPassCheckMet){
                if (hasFieldValueChanged(newOpp,
                        ((oldOpportunities!=null && String.isNotBlank(newOpp.Id) && oldOpportunities.containsKey(newOpp.Id)) ? oldOpportunities.get(newOpp.Id) : null),
                        dashPassEligibleFieldApiNamesToEvaluate)){
                    Boolean isDashPassEligible = false;
                    if (newOpp.DashPass_Floor__c != null){
                        if (newOpp.Commission__c != null && newOpp.Commission__c >= newOpp.DashPass_Floor__c){
                            isDashPassEligible = true;
                        }
                        if (newOpp.DashPass_Only_Commission__c != null && newOpp.DashPass_Only_Commission__c >= newOpp.DashPass_Floor__c){
                            isDashPassEligible = true;
                        }
                    }
                    if (newOpp.DashPass_Flat_Fee__c != null){
                        isDashPassEligible = true;
                    }
                    if (String.isNotBlank(newOpp.AccountId) && accountMap.containsKey(newOpp.AccountId) && accountMap.get(newOpp.AccountId).DashPass_Eligibility_Override__c){
                        isDashPassEligible = true;
                    }
                    if (String.isNotBlank(newOpp.DealDesk_Approved_del__c) && 'Yes'.equals(newOpp.DealDesk_Approved_del__c)){
                        isDashPassEligible = true;
                    }
                    if (String.isNotBlank(newOpp.DashPass_Eligibility_Override_Approved__c) && 'Yes'.equals(newOpp.DashPass_Eligibility_Override_Approved__c)){
                        isDashPassEligible = true;
                    }
                    if (String.isNotBlank(newOpp.RecordTypeId) && enterpriseMarketplaceRecordTypeId.equals(newOpp.RecordTypeId)){
                        isDashPassEligible = true;
                    }
                    newOpp.DashPass_Eligible_CW__c = isDashPassEligible ? 'Yes' : 'No';
                    newOpp.DashPass_Eligible__c = isDashPassEligible ? 'Yes' : 'No';
                    ranSetDashPassEligible = true;
                }
            }
        }
    }
    /**
     * @description has the field value changed on ANY ONE of the field api names on the Opportunity record
     * Note: This method returns true if the oldOpportunity record is null
     * i.e. insert trigger event where the old Opportunity record does not exist
     * @param Opportunity new Opportunity record
     * @param Opportunity old Opportunity record
     * @param Set<String> field api names
     * @return Boolean has the field value changed on the Opportunity record? true or false
     */
    public static Boolean hasFieldValueChanged(Opportunity newOpportunity, Opportunity oldOpportunity, Set<String> fieldApiNames){
        for (String fieldApiName : fieldApiNames){
            if (hasFieldValueChanged(newOpportunity, oldOpportunity, fieldApiName)){
                return true;
            }
        }
        return false;
    }
    /**
     * @description has the field value changed on the Opportunity record
     * Note: This method returns true if the oldOpportunity record is null
     * i.e. insert trigger event where the old Opportunity record does not exist
     * @param Opportunity new Opportunity record
     * @param Opportunity old Opportunity record
     * @param String field api name
     * @return Boolean has the field value changed on the Opportunity record? true or false
     */
    public static Boolean hasFieldValueChanged(Opportunity newOpportunity, Opportunity oldOpportunity, String fieldApiName){
        return (oldOpportunity==null)
            ||
            (newOpportunity.get(fieldApiName)!=null && oldOpportunity.get(fieldApiName)==null)
            ||
            (newOpportunity.get(fieldApiName)==null && oldOpportunity.get(fieldApiName)!=null)
            ||
            (newOpportunity.get(fieldApiName) != oldOpportunity.get(fieldApiName));
    }

    /**
     *@ author : lalit
     *@purpose : check the opportunity status and if not valid restrict the user from deletion
     *@params  : 1)List of Old opportunities
     *return   : -
     */
    public static void validateOpportunityToDelete(List<Opportunity> oldOpportunityList){

        Boolean hasCustomPermission = FeatureManagement.checkPermission('Allow_Opportunity_Deletion_for_Restricted_Status');
        String opportunityStagesStr = System.Label.Restricted_Stages_To_Delete_Opportunity;
        String opportunityRestrictedUserIdsStr = System.Label.Opportunity_Deletion_Restricted_Created_By_Ids ;

        if(String.isBlank(opportunityStagesStr) || String.isBlank(opportunityRestrictedUserIdsStr)){
            return;
        }

        List<String> opportunityStageList = opportunityStagesStr.remove(' ').split(',');
        List<String> opportunityRestrictedUserIdsList = opportunityRestrictedUserIdsStr.remove(' ').split(',');

        for(Opportunity opportunityRec : oldOpportunityList){
            //check if restricted stages
            Boolean isRestrictedStage = opportunityRec.StageName != null && opportunityStageList.indexOf(opportunityRec.StageName.remove(' ')) >= 0;

            //check if created by formstack user
            Boolean isCreatedByRestrictedUser = opportunityRec.CreatedById != null && opportunityRestrictedUserIdsList.indexOf(opportunityRec.CreatedById) >= 0;

            if(!hasCustomPermission && (isRestrictedStage || isCreatedByRestrictedUser)) {
                opportunityRec.addError(System.Label.Opp_Delete_Validation_Error);
            }
        }

    }
    /**
     * @author: Ila Maheshwari
     * @date: 14-09-2021
     * @description BASD-14188 This method is wiping three fields on DDFB opportunity when it is getting cloned
     */
    public static void setBlankValueOnClonedDDFBOpp(List<Opportunity> newOpportunityList){
        String DoordashForBusinessRTID = CDdSchemaUtils.OPPORTUNITY_RT.doorDashForBusinessId();

        for(Opportunity opp: newOpportunityList){
            if(DoordashForBusinessRTID == opp.RecordTypeId && opp.isClone()){
                opp.PactSafe_Activity_ID__c = NULL;
                opp.PactSafe_Record__c = NULL;
             	  opp.Contract_Signed_Date__c = NULL;
            }
        }

    }

    /**
     * @date 08/2021
     * @description: BZAP-11331 Changing PB to Trigger -- Stamp Pricing Tier and Package Values on Closed Won. The field Alcohol Addendum Signed on account is
     * being updated in this PB which is migrated to below method to fully deprecate(delete) the PB.
     * @param List<Opportunity> Collection of new Opportunity records
     * @param List<Opportunity> Collection of old Opportunity records
     * @return
     */
    public static void updateAlcoholAddendumSigned(List<Opportunity> newOpps, Map<Id, Opportunity> oldOpportunities){

        if(!CDdRecursionUtils.isRunnable('CDdOpportunityTriggerHelper_updateAASign')){
            return;
        }
        Map<Id,Account> accToUpdateMap = new Map<Id,Account>();
        List<String> alcoholProductIds = new List<String>();

        if(!String.isBlank(Label.DdAlcohol_Product_ID))
            alcoholProductIds = Label.DdAlcohol_Product_ID.split(';');

        for (Opportunity opp : newOpps){

            if (opp.AccountId == null)
                continue;

            if (opp.StageName == 'Closed Won' && opp.Product_IDs__c != null){
                for(String prodId:alcoholProductIds){
                    if(!String.isBlank(prodId) && opp.Product_IDs__c.contains(prodId.trim())){
                        Account acc = new Account(Id=opp.AccountId,Alcohol_Addendum_Signed__c=true);
                        accToUpdateMap.put(opp.AccountId,acc);
                        break;
                    }
                }
            }
        }
        if (accToUpdateMap.size() > 0){
            update accToUpdateMap.values();
        }
    }
    /**
     * @description: BZAP-12136 - Re-parent Account for Opportunity with criteria as follows
     * 1. Type 'Change of Ownership'
     * 2. Stage Name 'Closed Won'
     * 3. Change of Ownership Business Option 'New Store'
     * 4. Record previously had blank 'Original Store Id'
     * 5. Record currently has a valid value in 'Original Store Id'
     * 6. Opportunity.Change_of_Ownership_Business_Id__c equals Account.Business_Id__c
     * Note: This method is executed in the After Trigger event (applies to update event only)
     * @param List<Opportunity> Collection of new Opportunity records
     * @param List<Opportunity> Collection of old Opportunity records (applied to update trigger events)
     * @param Map<Id, Account> Collection of pre-queried Account records (relevant field - Business_Id__c)
     * @return
     */
    public static void accountReparent(List<Opportunity> newOpps, Map<Id, Opportunity> oldOpportunities, Map<Id, Account> accountMap){
        if (ranAccountReparent) { return; }
        Set<Id> accountReparentCollection = new Set<Id>();
        Set<String> accountReparentEligibleTypes = new Set<String>{OPPORTUNITY_TYPE_CHANGE_OF_OWNERSHIP};
        Set<String> accountReparentEligibleStageNames = new Set<String>{STAGE_NAME_CLOSED_WON};
        for (Opportunity newOpp : newOpps){
            if (accountReparentEligibleTypes.contains(newOpp.Type)
                &&
                accountReparentEligibleStageNames.contains(newOpp.StageName)
                &&
                OPPORTUNITY_CHANGE_OF_OWNERSHIP_BUSINESS_OPTION_NEW_OWNER.equals(newOpp.Change_of_Ownership_Business_Option__c)
                &&
                oldOpportunities!=null && oldOpportunities.containsKey(newOpp.Id) && String.isBlank(oldOpportunities.get(newOpp.Id).Original_Store_ID__c)
                &&
                String.isNotBlank(newOpp.Original_Store_ID__c)){
                Account account = String.isNotBlank(newOpp.AccountId) && accountMap.containsKey(newOpp.AccountId) ? accountMap.get(newOpp.AccountId) : null;
                Decimal accountBusinessId = (account != null && account.Business_Id__c != null) ? account.Business_ID__c.stripTrailingZeros() : null;
                Decimal changeOfOwnershipBusinessId = (newOpp.Change_of_Ownership_Business_Id__c != null) ? newOpp.Change_of_Ownership_Business_Id__c.stripTrailingZeros() : null;
                if (accountBusinessId !=null && changeOfOwnershipBusinessId != null && accountBusinessId == changeOfOwnershipBusinessId){
                    accountReparentCollection.add(newOpp.AccountId);
                }
            }
        }
        if (!accountReparentCollection.isEmpty()) {
            CDdGenericPlatformEventHelper.publishEvents(CDdGenericPlatformEventHelper.PlatformEventType.ACCOUNT_REPARENT, accountReparentCollection);
            ranAccountReparent = true;
        }
    }

    /**
     * @author Nathalie Mendezona
     * @date 2022-01-05
     * @description BZAP-13015 - Migrate PB "Opportunity - Marketplace Updates" to Trigger
     * @param List<Opportunity> Collection of new Opportunity records
     * @param List<Opportunity> Collection of old Opportunity records (applied to update trigger events)
     * @return
     */
    public static void marketplaceUpdates(List<Opportunity> newOpps, Map<Id, Opportunity> oldOpportunities) {

        for (Opportunity opp: newOpps) {
            if (opp.StageName != STAGE_NAME_CLOSED_WON) {
                continue;
            }
            Opportunity oldOpp = oldOpportunities != null ? oldOpportunities.get(opp.Id) : null;
            Boolean isChangedDateOfActivation = opp.Proposed_Date_of_Activation__c != null
                                            && isNewOrFieldUpdated(opp, oldOpportunities, 'Proposed_Date_of_Activation__c');
            Boolean isChangedDateOfMenu = opp.Proposed_Date_of_Menu__c != null
                                            && isNewOrFieldUpdated(opp, oldOpportunities, 'Proposed_Date_of_Menu__c')
                                            && opp.Proposed_Date_of_Menu_Original__c == null;
            Boolean isChangedDateOfTablet = opp.Proposed_Date_of_Tablet__c != null
                                            && isNewOrFieldUpdated(opp, oldOpportunities, 'Proposed_Date_of_Tablet__c')
                                            && opp.Proposed_Date_of_Tablet_Original__c == null;
            if (isChangedDateOfActivation) {
                if (opp.Proposed_Date_of_Activation_Original__c == null) {
                    opp.Proposed_Date_of_Activation_Original__c = opp.Proposed_Date_of_Activation__c;
                } else if (oldOpp?.Proposed_Date_of_Activation_Original__c != null) {
                    opp.PDOA_Change_Count__c = opp.PDOA_Change_Count__c == null ? 1 : opp.PDOA_Change_Count__c + 1;
                }
            }
            if (isChangedDateOfMenu) {
                opp.Proposed_Date_of_Menu_Original__c = opp.Proposed_Date_of_Menu__c;
            }
            if (isChangedDateOfTablet) {
                opp.Proposed_Date_of_Tablet_Original__c = opp.Proposed_Date_of_Tablet__c;
            }
        }
    }

    /**
     * @author Nathalie Mendezona
     * @date 2022-01-05
     * @description BZAP-13015 - Migrate PB "Formstack - McDs Canada" to Trigger
     * @param List<Opportunity> Collection of new Opportunity records
     * @param List<Opportunity> Collection of old Opportunity records (applied to update trigger events)
     * @param Map<Id, Account> Collection of pre-queried Account records (relevant field - Business_Id__c)
     * @return
     */
    public static void formstackMcDsCanada(List<Opportunity> newOpps, Map<Id, Opportunity> oldOpportunities, Map<Id, Account> accountMap) {
        List<Account> accountsToUpdate = new List<Account>();
        List<String> errorMessages = new List<String>();
        if (formstackDeprecated) {
            return;
        }
        for (Opportunity opp: newOpps) {
            if (!opp.Franchise_Formstack__c || String.IsBlank(opp.Institution_Number__c) || opp.AccountId == null) {
                continue;
            }
            Opportunity oldOpp = oldOpportunities != null ? oldOpportunities.get(opp.Id) : null;
            Account oppAccount = (accountMap == null) ? null : accountMap.get(opp.AccountId);
            if (oppAccount.BillingCountry == 'Canada' && String.isBlank(oldOpp?.Institution_Number__c)
                && oppAccount?.Bank_Institution_Number_Encrypted__c != opp.Institution_Number__c) {
                oppAccount.Bank_Institution_Number_Encrypted__c = opp.Institution_Number__c;
                accountsToUpdate.add(oppAccount);
            }
        }
        if (accountsToUpdate.size() > 0) {
            try {
                List<Database.SaveResult> sResults = Database.update(accountsToUpdate, false);
                errorMessages = CDdErrorUtilities.processSaveResults(sResults, errorMessages);
            } catch (Exception e) {
                errorMessages.add(e.getMessage());
                CDdErrorUtilities.createApexLogs(errorMessages, 'CDdOpportunityTriggerHelper',
                                                'formstackMcDsCanada',LoggingLevel.ERROR);
                throw e;
            }
        }
    }

    /**
     * @author Nathalie Mendezona
     * @date 2022-01-05
     * @description BZAP-13015 - Migrate PB "Update Parent Account with Requesting Account Management Status" to Trigger
     * @param List<Opportunity> Collection of new Opportunity records
     * @param List<Opportunity> Collection of old Opportunity records (applied to update trigger events)
     * @param Map<Id, Account> Collection of pre-queried Account records (relevant field - Business_Id__c)
     * @return
     */
    public static void accountMgmtStatusUpdate(List<Opportunity> newOpps, Map<Id, Account> accountMap) {
        List<Account> accountsToUpdate = new List<Account>();
        List<String> errorMessages = new List<String>();
        List<Id> oppIds = new List<Id>();

        for (Opportunity opp: newOpps) {
            oppIds.add(opp.Id);
        }
        List<Opportunity> newOppsRelatedFields = CDdOpportunityCaseHelper.queryRelatedData(oppIds);

        for (Opportunity opp: newOppsRelatedFields) {
            if (opp.Account?.ParentId == null || String.isEmpty(opp.Requesting_Account_Management__c)
                || opp.RecordTypeId != oppMarketplaceRTId || opp.CreatedById == selfServeUserId) {
                continue;
            }
            if (opp.Account.Parent.Requesting_Account_Management__c != opp.Requesting_Account_Management__c) {
                Account parentAccount = new Account(Id = opp.Account.ParentId, Requesting_Account_Management__c = opp.Requesting_Account_Management__c);
                accountsToUpdate.add(parentAccount);
            }
        }
        if (accountsToUpdate.size() > 0) {
            try {
                List<Database.SaveResult> sResults = Database.update(accountsToUpdate, false);
                errorMessages = CDdErrorUtilities.processSaveResults(sResults, errorMessages);
                System.debug(LoggingLevel.ERROR, 'CDdOpportunityTriggerHelper.accountMgmtStatusUpdate: ' + errorMessages);
            } catch (Exception e) {
                errorMessages.add(e.getMessage());
                CDdErrorUtilities.createApexLogs(errorMessages, 'CDdOpportunityTriggerHelper',
                                                'accountMgmtStatusUpdate',LoggingLevel.ERROR);
                System.debug(LoggingLevel.ERROR, 'CDdOpportunityTriggerHelper.accountMgmtStatusUpdate: ' + errorMessages);
                throw e;
            }
        }
    }

     /**
    *@ author : Lalitkumar Motiray
    *@description BZAP-12637 - Set Opportunity Default Values for New zealand opportunity by Order Protocol
    * BZAP-12834 : set currency iso code NZD for ent markeplace and corporate opportunity
    */
    public static void setDefaultValueForNZByOrderProtocolForTabShipping(List<Opportunity> newList){


        Set<String> NZDropShip = new Set<String>{'Tablet (DoorDash Owns)', 'Tablet and Printer (DoorDash Owns)', 'POS and Tablet (DoorDash Owns)'};

        Set<Id> accountIdSet = new Set<Id>();

        for(Opportunity opptyRec : newList) {
            if(opptyRec.AccountId != NULL) {
                accountIdSet.add(opptyRec.AccountId);
            }
        }

        Map<Id,Account> accountMap = new Map<Id,Account>([SELECT Id,Name,BillingCountry
                                                          FROM Account
                                                          WHERE Id IN:accountIdSet AND BillingCountry=: BILLING_COUNTRY_NEW_ZEALAND]);

        for(Opportunity newOpp : newList){

            if(accountMap.containsKey(newOpp.AccountId)){

                //BZAP-12834
                if(newOpp.RecordTypeId == enterpriseMarketplaceRecordTypeId || newOpp.RecordTypeId == corporateRTId){
                    newOpp.CurrencyISOCode = 'NZD';
                    newOpp.Legal_Entity__c = 'NZL';
                }

                //BZAP-12637
                if(newOpp.RecordTypeId != marketplaceRecordTypeId || String.isBlank(newOpp.Order_Protocol__c)){
                    continue;
                }

                if(newOpp.Order_Protocol__c == 'POS'){

                    newOpp.Tablet_Delivery_Method__c = '';
                    newOpp.Shipping__c ='';
                    newOpp.Tablet_Kit_Type__c = '';

                }

            }
        }
    }

    /**
    *@ author : Sanidhya Jain
    *@description BASD-22667 - Set Opportunity Default Values for Tablet Delivery Method by Order Protocol
    */
    public static void updateTabletDeliveryMethod(List<Opportunity> newList , Map<id,Opportunity> oldMap){
        Set<String> orderProtocalTabletValue = new Set<String>{'Tablet (DoorDash Owns)', 'Tablet and Printer (DoorDash Owns)', 'POS and and Tablet (DoorDash Owns)'};
        for(Opportunity newOpp : newList){
            if(newOpp.RecordTypeId != marketplaceRecordTypeId && newOpp.RecordTypeId != enterpriseMarketplaceRecordTypeId){
                continue;
            }
            if((oldMap == null || newOpp.Order_Protocol__c != oldMap.get(newOpp.id).Order_Protocol__c || (newOpp.StageName != oldMap.get(newOpp.id).StageName && newOpp.StageName == 'Closed Won')) && orderProtocalTabletValue.contains(newOpp.Order_Protocol__c) && newOpp.Tablet_Delivery_Method__c == null){
                newOpp.Tablet_Delivery_Method__c = 'Drop-ship';
                if(String.isBlank(newOpp.Shipping__c)) {
                    newOpp.Shipping__c ='Standard';
                }
                if(String.isBlank(newOpp.Tablet_Kit_Type__c)) {
                	newOpp.Tablet_Kit_Type__c = 'Standard';
                }
            }
        }
    }

    /**
    *@ author : Abhijeet K
    *@description BZAP-14108 - Update Notes on Account When there is change in Opportunity Notes for OCUS
    */
    public static void updateNotesOnAccountOnChangeofOpportunityNotes(List<Opportunity> newList , Map<id,Opportunity> oldMap) {
        Map<Id, Account> accountMap = new Map<Id, Account>();
        for(Opportunity newOpp : newList) {
            if((newOpp.RecordTypeId == marketplaceRecordTypeId)
                && (newOpp.StageName != STAGE_NAME_CLOSED_WON)
                && !String.isBlank(newOpp.Notes__c)
                && isNewOrFieldUpdated(newOpp, oldMap, 'Notes__c')
            ) {
                if(!accountMap.containsKey(newOpp.accountId)) {
                    accountMap.put(newOpp.accountId, new Account(Id=newOpp.accountId, Notes__c = newOpp.Notes__c));
                }
            }
        }
        update accountMap.values();
    }

    private static List<Task> getLiquorLicenseTaksRelatedToParentAccount(Set<Id> accountIdSet) {
        return [
            SELECT Id, Subject, Type, WhatId, AccountId FROM Task
            WHERE What.Type = 'Account' AND Type = :LIQUOR_LICENSE_COLLECTION
            AND Status != :TASK_STATUS_COMPLETED
            AND WhatId IN :accountIdSet
        ];
    }

    /**
     * @date 07/22
     * @ author : Jitendra Singh
     * @description: BZAP-16104 CW validation to ensure liquor license is collected
     * @param List<Opportunity> Collection of new Opportunity records
     * @param List<Opportunity> Collection of old Opportunity records
     * @return
     */
    public static void validateCWLiquorLicenseCollectionTask(List<Opportunity> newOpps, Map<Id, Opportunity> oldOpportunities){

        List<String> alcoholProductIds = new List<String>();
        if(!String.isBlank(Label.DdAlcohol_Product_ID))
        {
            alcoholProductIds = Label.DdAlcohol_Product_ID.split(';');
        }
        List<Opportunity> oppToWorkList = new List<Opportunity>();
        Set<Id> accountIdSet = new Set<Id>();
        for (Opportunity newOpp : newOpps)
        {
            if(newOpp.StageName == STAGE_NAME_CLOSED_WON
                && newOpp.StageName != oldOpportunities.get(newOpp.Id).StageName
                && newOpp.Product_IDs__c != null
                && newOpp.AccountId != null
                && CDdI18nUtility.isCountryNewZealand(newOpp.Account_Billing_Country__c)
                && (newOpp.RecordTypeId == marketplaceRecordTypeId
                || newOpp.RecordTypeId == corporateRTId
                || newOpp.RecordTypeId == postSaleRecId))
            {
                for(String prodId : alcoholProductIds)
                {
                    if(!String.isBlank(prodId) && newOpp.Product_IDs__c.contains(prodId.trim()))
                    {
                        oppToWorkList.add(newOpp);
                        accountIdSet.add(newOpp.accountId);
                    }
                }
            }
        }

        Map<Id, Task> accountIdTaskMap = new Map<Id, Task>();
        if(accountIdSet.size() > 0)
        {
            for(Task tk: getLiquorLicenseTaksRelatedToParentAccount(accountIdSet))
            {
                accountIdTaskMap.put(tk.AccountId, tk);
            }
        }

        for(Opportunity opp : oppToWorkList)
        {
            if(accountIdTaskMap.containsKey(opp.accountId) && accountIdTaskMap.get(opp.accountId) != null)
            {
                opp.addError(System.Label.CW_LiquorLicenseCollectionTask_Validation_Error);
            }
        }
    }


    /**
    *@ author : Abhijeet K
    *@description BZAP-16101 - Task for Sales team to collect liquor license
    */
    public static void createLiquorLicenseTask(List<Opportunity> newList , Map<id,Opportunity> oldMap, Map<Id, Account> accountMap) {
        if(ranCreateLiquorLicenseTask) { return;}
        Set<Id> opportunityIdSet = new Set<Id>();
        Set<Id> parentAccountIdSet = new Set<Id>();
        Set<Id> preOrPostSaleRecordTypeIds = new Set<Id> {
            oppCorporateRTId,oppPostSaleRTId, oppMarketplaceRTId
        };
        List<Task> taskListToInsert = new List<Task>();
        for(Opportunity newOpp : newList) {
            Account parentAccountRecord = accountMap.get(newOpp.accountId);
            Boolean isBillingCountryNZ = parentAccountRecord != null &&
                CDdI18nUtility.isCountryNewZealand(parentAccountRecord.BillingCountryCode);
            Boolean isSelfServUser = CDdOpportunityCaseHelper.selfServIntegrationUser == newOpp.OwnerId ||
                CDdOpportunityCaseHelper.mulesoftIntegrationUser == newOpp.OwnerId;

            if(preOrPostSaleRecordTypeIds.contains(newOpp.recordTypeId) &&
               isNewOrFieldUpdated(newOpp, oldMap, 'StageName') && newOpp.StageName == STAGE_NAME_CONTRACT_SIGNED &&
               hasAlcoholProduct(newOpp) && isBillingCountryNZ && !isSelfServUser
            ) {
                parentAccountIdSet.add(newOpp.accountId);
                opportunityIdSet.add(newOpp.Id);
            }
        }
        if(!opportunityIdSet.isEmpty()) {
            createLiquorLicenseTaskAsync(opportunityIdSet, parentAccountIdSet);
        }
        ranCreateLiquorLicenseTask = true;
    }

    @future
    public static void createLiquorLicenseTaskAsync(Set<Id> opportunityIdSet, Set<Id> accountIdSet) {
        List<Task> taskListToInsert = new List<Task>();
        Set<Id> accountIdsContainingLiquorLicenseTask = getAccountIdsContainingLiquorLicenseTask(accountIdSet);
        for(Opportunity oppRecord: [
            SELECT Id, Name, recordTypeId, StageName, closeDate, AccountId, Account.RecordTypeId, ownerId, Account.OwnerId, Owner.Name, Account.Owner.Name
            FROM Opportunity
            WHERE Id IN :opportunityIdSet
        ]) {
            String expectedTaskSubjectName = 'Collect liquor license for '+ oppRecord.Name + ' Opportunity';
            Boolean isPreSalesOpportunity = oppRecord.recordTypeId == oppCorporateRTId || oppRecord.recordTypeId == oppMarketplaceRTId;
            if(!accountIdsContainingLiquorLicenseTask.contains(oppRecord.AccountId)) {
                taskListToInsert.add(new Task(
                    Subject = expectedTaskSubjectName,
                    OwnerId = isPreSalesOpportunity ? oppRecord.OwnerId : oppRecord.Account.OwnerId,
                    ActivityDate = oppRecord.CloseDate,
                    Status = TASK_STATUS_OPEN,
                    WhatId = oppRecord.accountId,
                    Task_Comments__c = oppRecord.Id,
                    Type = LIQUOR_LICENSE_COLLECTION
                ));
            }
        insert taskListToInsert;
        }
    }

    private static Boolean hasAlcoholProduct(Opportunity oppRecord) {
        Boolean hasAlcoholProduct = false;
        List<String> alcoholProductIds = Label.DdAlcohol_Product_ID.split(';');
        for(String alcoholProductId: alcoholProductIds) {
            if(oppRecord.Product_IDs__c != null && oppRecord.Product_IDs__c.contains(alcoholProductId.trim())) {
                hasAlcoholProduct = true;
                break;
            }
        }
        return hasAlcoholProduct;
    }

    private static Set<Id> getAccountIdsContainingLiquorLicenseTask(Set<Id> accountIdSet) {
        Set<Id> accountIdsContainingLiquorLicenseTask = new Set<Id>();
        for(Task taskRecord: [
            SELECT Id, Subject, Type, WhatId, AccountId FROM Task
            WHERE What.Type = 'Account' AND Type = :LIQUOR_LICENSE_COLLECTION
            AND WhatId IN :accountIdSet
        ]) {
           accountIdsContainingLiquorLicenseTask.add(taskRecord.WhatId);
        }
        return accountIdsContainingLiquorLicenseTask;
    }

    /**
     *
     *@description BZAP-14951 - Find the SOT on closed won opportunities when there are multiple opportunities in the system
     */
    public static void processSSMOOpportunities(List<Opportunity> newList, Map<id,Opportunity> oldMap){

        if(ranSSMOOpportunityUpdate && !Test.isRunningTest()){
            return;
        }

        if(disableSSMOOpptyAttribution && !Test.isRunningTest()){
            return;
        }

        List<SSMO_Opportunity_Attribution_Event__e> ssmoAttributionEvents = new List<SSMO_Opportunity_Attribution_Event__e>();

        for (Opportunity opptyRecordNew : newList) {
            Opportunity opptyRecordOld = oldMap.get(opptyRecordNew.Id);

            if (String.isNotBlank(opptyRecordNew.Product_IDs__c) &&
                    (opptyRecordNew.Product_IDs__c != opptyRecordOld.Product_IDs__c || (opptyRecordNew.StageName != opptyRecordOld.StageName && opptyRecordNew.StageName == 'Meeting Ran / Negotiated'))) {
                ssmoAttributionEvents.add(new SSMO_Opportunity_Attribution_Event__e(Opportunity_ID__c=opptyRecordNew.Id));
            }
        }

        if (!ssmoAttributionEvents.isEmpty()) {
            ranSSMOOpportunityUpdate = true;
            EventBus.publish(ssmoAttributionEvents);
        }
    }

    /*
     * This can be moved to another class if it makes sense to reuse
     **/
    public static Boolean skipValidation(String fieldToCheck) {
        String userId = UserInfo.getUserId();
        String profileId = UserInfo.getProfileId();
        String queryString = 'SELECT Id, ' + fieldToCheck
                       + ' FROM Validation_Bypass__c'
                       + ' WHERE SetupOwnerId =: userId'
                       + '    OR SetupOwnerId =: profileId';
        List<Sobject> skipValidation = Database.query(queryString);
        if (skipValidation.size() > 0 && skipValidation.get(0).get(fieldToCheck) == true) {
            return true;
        }
        return false;
    }

    /*
    * Description: Validate the Bbot Opp fields when opportunity stage is set to "Ready for Signature"
    * Abhijeet K for BZAP-16917
    */
    public static void validateBbotOpportunityOnContractCreation(List<Opportunity> newList , Map<id,Opportunity> oldMap){
        Set<Id> bBotOpptyIdSet = new Set<Id>();
        Set<Id> bBotOpptyIdPSSet = new Set<Id>();
        Set<Id> psAccountIdSet = new Set<Id>();
        Map<Id, Account> accountMap = new Map<Id ,Account>();

        if (skipValidation('Bypass_Opportunity_Validations__c')) {
            return;
        }

        for (Opportunity opp: newList) {
            if (bbotRecordTypeIds.contains(opp.recordTypeId) &&
                opp.Has_Bbot_Product__c &&
                isNewOrFieldUpdated(opp, oldMap, 'StageName') &&
                opp.StageName == STAGE_NAME_READY_FOR_SIGNATURE
                ) {
                bBotOpptyIdSet.add(opp.Id);
            }
            if(opp.recordTypeId == oppPostSaleRTId &&
                opp.Has_Bbot_Product__c &&
                isNewOrFieldUpdated(opp, oldMap, 'StageName') &&
                opp.StageName == STAGE_NAME_READY_FOR_SIGNATURE)
            {
                bBotOpptyIdPSSet.add(opp.Id);
                psAccountIdSet.add(opp.accountId);
            }
        }
        Map<Id, Set<String>> opptyIdToOpptyContactRolesMap = new Map<Id, Set<String>>();
        if(!bBotOpptyIdSet.isEmpty()) {
            for(Opportunity oppRecord: [
                SELECT Id, Name,
                (SELECT Id, Role FROM OpportunityContactRoles)
                FROM Opportunity
                WHERE Id IN :bBotOpptyIdSet
            ]) {
                Set<String> opptyContactRoles = new Set<String>();
                for(OpportunityContactRole opptyContactRoleRecord: oppRecord.OpportunityContactRoles) {
                    if(!String.isBlank(opptyContactRoleRecord.Role)) {
                        opptyContactRoles.add(opptyContactRoleRecord.Role);
                    }
                }
                opptyIdToOpptyContactRolesMap.put(oppRecord.Id, opptyContactRoles);
            }
        }

        if(!bBotOpptyIdPSSet.isEmpty() && !psAccountIdSet.isEmpty())
        {
            accountMap = new Map<Id, Account>([SELECT Id, POS_System__c, Bbot_Category__c, Bbot_Sub_Category__c
                                                FROM Account
                                                WHERE Id IN: psAccountIdSet]);
        }

        for (Opportunity opp: newList) {
            String errorMessage = '';
            if(!bBotOpptyIdSet.isEmpty() && bBotOpptyIdSet.contains(opp.Id)) {
                Boolean hasRequiredFieldsBlank = String.isBlank(opp.Decision_Maker__c) ||
                    String.isBlank(opp.Cuisine_Categories__c) || String.isBlank(opp.Integrations_Required__c);
                Boolean isValidOpptyContactRole = opptyIdToOpptyContactRolesMap.get(opp.Id) != null &&
                    opptyIdToOpptyContactRolesMap.get(opp.Id).contains(OPPORTUNITY_CONTACT_ROLE_PRIMARY_ONBOARDING_CONTACT) &&
                    opptyIdToOpptyContactRolesMap.get(opp.Id).contains(OPPORTUNITY_CONTACT_ROLE_IT_POC);

                if(hasRequiredFieldsBlank) {
                    errorMessage = errorMessage + Label.Bbot_Opportunity_Required_Fields_for_Contract_Creation + '\n';
                }
                if(!isValidOpptyContactRole) {
                    errorMessage = errorMessage + Label.Bbot_Opportunity_Contact_Roles_Validation_Message + '\n';
                }

            }
            if(!bBotOpptyIdPSSet.isEmpty()) {
                Boolean hasRequiredAccountFieldsBlank = false;
                Account acc = accountMap.containsKey(opp.AccountId) ? accountMap.get(opp.accountId) : null;
                if(acc != null)
                {
                    hasRequiredAccountFieldsBlank = String.isBlank(acc.POS_System__c) || String.isBlank(acc.Bbot_Category__c) || String.isBlank(acc.Bbot_Sub_Category__c);
                }

                if(hasRequiredAccountFieldsBlank) {
                    errorMessage = errorMessage + Label.Bbot_Opportunity_Required_Fields_for_Contract_Creation_For_Post_Sale + '\n';
                }
            }
            if (String.isNotBlank(errorMessage)) {
                opp.addError(errorMessage);
            }
        }
    }

    /**
     *
     *@description BZAP-16931 - Add Email Alert to Opportunity Owner when Rep EnabledSSMO deal gets moved to closed won
    */
    public static void sendEmailToSSMOOpportunityOwner(List<Opportunity> newList, Map<id,Opportunity> oldMap){
        if(ranSendEmailToSSMOOpportunityOwner && !Test.isRunningTest()){
            return;
        }

        if(disableSSMOClosedWonOpportunityOwnerEmail && !Test.isRunningTest()){
            return;
        }

        List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
        List<Opportunity> finalOpptyList = new List<Opportunity>();
        for (Opportunity opRecNew : newList) {
            Opportunity opRecOld = oldMap.get(opRecNew.Id);
            if(String.isNotBlank(opRecNew.PactSafe_Contract_Type__c) && opRecNew.PactSafe_Contract_Type__c.contains('Rep Enabled SSMO Sign Up Sheet') &&
                opRecOld != null && opRecNew.StageName == 'Closed Won' && opRecNew.StageName != opRecOld.StageName){
                    finalOpptyList.add(opRecNew);
            }
        }

        if(!finalOpptyList.isEmpty()){
            List<EmailTemplate> emailTemplates = [SELECT Id,DeveloperName FROM EmailTemplate WHERE DeveloperName  IN ('SSMO_Closed_Won_Owner_Email_Template')];
            Map<Id,Opportunity> opptyMap = new Map<Id,Opportunity>([SELECT Id,Owner.Email FROM Opportunity WHERE Id IN :finalOpptyList]);

            for(Opportunity opRec : finalOpptyList){
                Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
                emailMessage.setTemplateId(emailTemplates != null && emailTemplates.size() > 0?emailTemplates[0].Id:null);
                emailMessage.setToAddresses(new List<String>{opptyMap.get(opRec.Id).Owner.Email});
                emailMessage.setTargetObjectId(opRec.Decision_Maker__c);
                emailMessage.setTreatTargetObjectAsRecipient(false);
                emailMessage.setWhatId(opRec.Id);
                emailMessage.setSaveAsActivity(false);
                emailMessage.setUseSignature(false);
                emailMessages.add(emailMessage);
            }
        }

        if (!emailMessages.isEmpty() && !Test.isRunningTest()) {
            ranSendEmailToSSMOOpportunityOwner = true;
            Messaging.SendEmailResult[] emailResults = Messaging.sendEmail(emailMessages,false);
            List<String> messages = new List<String>();
            for(Messaging.SendEmailResult emailResult:emailResults){
                if(!emailResult.isSuccess()){
                    messages.add('Error while sending email to Opportunity Owner '+emailResult.getErrors()[0].getMessage() +' '+emailResult.getErrors()[0].getTargetObjectId());
                }
            }
            CDdErrorUtilities.createApexLogs(messages,'CDdOpportunityTriggerHandler','sendEmailToSSMOOpportunityOwner',LoggingLevel.ERROR);
        }
    }

    /*
    * Description: Automatically move the Bbot Opp to Close Won if the Stage is set to "Contract Signed"
    * Nathalie Mendezona for BZAP-16703
    * Nathalie Mendezona BZAP-18883 - adding behavior for SSMO
    */
    public static void contractSignedAutoMoveToCloseWon(List<Opportunity> newList , Map<id,Opportunity> oldMap){
        if (ranUpdateOppAsynchronous) {return;}
        Map<Id, Opportunity> oppMapWithLineItems = getOppsWithLineItems(newList);
        List<Id> oppIdsToUpdate = new List<Id>();
        String newOwnerId = null;

        for (Opportunity opp: newList) {
            Boolean autoClose = false;
            Integer bbotCount = 0;

            if (bbotRecordTypeIds.contains(opp.recordTypeId) &&
                isNewOrFieldUpdated(opp, oldMap, 'StageName') &&
                opp.StageName == STAGE_NAME_CONTRACT_SIGNED
                ) {

                // SSMO Logic
                if (opp.Integration_Auto_Close__c && opp.CreatedById == CDdOpportunityCaseHelper.mulesoftIntegrationUser) {
                    autoClose = true;
                    //newOwnerId = CDdOpportunityCaseHelper.selfServIntegrationUser;
                    oppIdsToUpdate.add(opp.Id);
                }

                // Bbot Logic
                if (oppMapWithLineItems != null && oppMapWithLineItems.get(opp.Id) != null
                    && oppMapWithLineItems.get(opp.Id).OpportunityLineItems.size() > 0) {

                    for (OpportunityLineItem oli: oppMapWithLineItems.get(opp.Id).OpportunityLineItems) {
                    if (oli.PricebookEntry.Product2.Family != null && oli.PricebookEntry.Product2.Family.contains(CDdOpportunityLineItemHelperMethods.PRODUCT_FAMILY_BBOT)) {
                            bbotCount++;
                        }
                    }
                    if (oppMapWithLineItems.get(opp.Id).OpportunityLineItems.size() == bbotCount) {
                        autoClose = true;
                        oppIdsToUpdate.add(opp.Id);
                    }
                }
                // SSMO Logic running from batch CDdQuoteStatusCheckBatch
                if (opp.Integration_Auto_Close__c && opp.CreatedById == CDdOpportunityCaseHelper.mulesoftIntegrationUser
                   && System.isBatch() && UserInfo.getName() == DOORDASH_CPQ_USER) {
                    opp.StageName = STAGE_NAME_CLOSED_WON;
                }
            }
        }

        if(oppIdsToUpdate.size() > 0 && !System.isBatch() && UserInfo.getName() != DOORDASH_CPQ_USER) {
            updateOppAsynchronous(oppIdsToUpdate, STAGE_NAME_CLOSED_WON, newOwnerId);
        }
        ranUpdateOppAsynchronous = true;
    }

    /**
     * Using a future call, because there is a Flow called "Bbot Send Oppty Id to Tray"
     * that expects an opp to be in 'Contract Signed' status in order to send an outbound
     * message. If the Stage is updated to Closed Won in the same context, the Flow will not
     * fire. We also don't want to fire the outbound message for both Contract Signed and CW
     */
    @future
    public static void updateOppAsynchronous(List<Id> oppIds, String stageName, String ownerId) {
        List<Opportunity> opps = new List<Opportunity>();
        for (Id oppId: oppIds) {
            if (ownerId == null) {
                opps.add(new Opportunity(Id=oppId, StageName = stageName));
            } else {
                opps.add(new Opportunity(Id=oppId, StageName = stageName, OwnerId = ownerId));
            }
        }
        try{
            update opps;
        } catch(Exception e){
            CDdErrorUtilities.createApexLogs(new List<String>{e.getMessage()}, 'CDdOpportunityTriggerHelper', 'updateOppAsynchronous',LoggingLevel.ERROR);
        }
    }

    /**
     * Utility method to return OpportunityLineItems that belong to given Opportunities
     */
    public static Map<Id, Opportunity> getOppsWithLineItems(List<Opportunity> opportunities) {
        Set<String> oppIds = new Set<String>();
        for (Opportunity opp: opportunities) {
            oppIds.add(opp.Id);
        }
        return new Map<Id, Opportunity>([SELECT Id, Has_Bbot_Product__c, RecordTypeId, StageName,
                	  (SELECT Id, Product2Id, PricebookEntry.Product2.Family FROM OpportunityLineItems)
                FROM Opportunity
                WHERE Id in: oppIds]);
    }

    /*
    * Description: Sales Qualified Opportunity Date (SQO)
    * Jitendra Baghela for BZAP-16803
    */
    public static void updateSQODateForPostSale(List<Opportunity> newList , Map<id,Opportunity> oldMap)
    {
        for(Opportunity opp : newList)
        {
            if (isNewOrFieldUpdated(opp, oldMap, 'StageName')
                    && opp.StageName == STAGE_NAME_MEETING_RAN_NEGOTIATED
                    && opp.recordTypeId == oppPostSaleRTId)
                {
                    opp.SQO_Date__c = Date.Today();
                }
        }
    }

    /**
     *
     *@description BZAP-18107 - Create Pre Sale Implementation request and OSA assignment
    */
    public static void createPreSaleImplementationRequest(List<Opportunity> newList, Map<id,Opportunity> oldMap){
        if(ranCreatePreSaleImplementationRequest && !Test.isRunningTest()){
            return;
        }

        if(disablePreSaleImplementationRequest && !Test.isRunningTest()){
            return;
        }

        List<Opportunity> finalOpptyList = new List<Opportunity>();
        for(Opportunity oppRec:newList){
            if(oppRec.RecordTypeId == oppMarketplaceRTID && oppRec.StageName == 'Contract Signed' && (oldMap == null || oppRec.StageName != oldMap.get(oppRec.Id).StageName)){
                finalOpptyList.add(oppRec);
            }
        }

        if(!finalOpptyList.isEmpty()){
            ranCreatePreSaleImplementationRequest = true;
            CDdImplementationRequestQueueable implRequestQueueble = new CDdImplementationRequestQueueable(finalOpptyList);
            if(enablePreSaleImplementationRequestAsync){
            	System.enqueueJob(implRequestQueueble);
            }else{
                implRequestQueueble.createImplementationRequest();
            }
        }
    }

    /**
    *@ author : Ganesh D
    *@description BZAP-15711 - Update Subsidiary mapping logic between SFDC<> NetSuite
    */
    public static void updatePaymentAccount(List<Opportunity> newList , Map<id,Opportunity> oldMap) {

        if (Vertical_Category_Trigger_Setting__c.getInstance(Userinfo.getUserId()).Disable_Payment_Account__c) return;

        Set<Id> paymentAccountSet = new Set<Id>();
        List<Opportunity> processList = new List<Opportunity>();
        for(Opportunity newOpp : newList) {
            if(newOpp.Payment_Account__c != null
                && isFieldUpdated(newOpp, oldMap, 'Payment_Account__c')
            ) {
                paymentAccountSet.add(newOpp.Payment_Account__c);
                processList.add(newOpp);
            }
        }

        if(processList.isEmpty()){
            return ;
        }

        List<string> doorDashProducts = Label.DD_Drive_Products.split(',');
        Map<Id,Opportunity> oppMap = new Map<Id, Opportunity>([SELECT Id, Account.Primary_Merchant_Category__c,
                               (SELECT Id, Product2.Name,OpportunityId FROM OpportunityLineItems
                                        WHERE Product2.Name IN:doorDashProducts)
                                 FROM Opportunity WHERE Id IN:processList]);

        Map<Id, Payment_Account__c> paymentAccountMap = new Map<Id, Payment_Account__c>(
                                                            [SELECT Id FROM Payment_Account__c
                                                                WHERE Id IN:paymentAccountSet
                                                                AND NetSuite_ID__c = null]);

        List<Payment_Account__c> paymentAccountUpdate = new List<Payment_Account__c>();
        for(Opportunity newOpp : processList) {
            if(paymentAccountMap.containsKey(newOpp.Payment_Account__c)){

                Payment_Account__c pAcc = new Payment_Account__c(Id = newOpp.Payment_Account__c, Primary_Opportunity__c = newOpp.Id);

                if(oppMap.containsKey(newOpp.Id)
                    && oppMap.get(newOpp.Id).OpportunityLineItems.size() == 0
                    && oppMap.get(newOpp.Id).Account.Primary_Merchant_Category__c != null
                    && Label.DD_G_C_Primary_Categories.contains(oppMap.get(newOpp.Id).Account.Primary_Merchant_Category__c)){

                    pAcc.Subsidiary_Details__c = Label.DD_G_C;
                }
                paymentAccountUpdate.add(pAcc);
            }
        }

        if(!paymentAccountUpdate.isEmpty()){
            List<Database.Error> errors = new List<Database.Error>();
            List<Database.SaveResult> cdlSaveResults = Database.update(paymentAccountUpdate, false);
            for (Database.SaveResult cdlSaveResult : cdlSaveResults) {
                errors.addAll(cdlSaveResult.getErrors());
            }
            if(!errors.isEmpty()){
                insertApexLogs(errors,'updatePaymentAccount');
            }
        }
    }

    private static void insertApexLogs(List<Database.Error> errors, string methodName) {
        List<Apex_Log__c> logs = new List<Apex_Log__c>();
        for (Database.Error error : errors) {
            Apex_Log__c log = new Apex_Log__c();
            log.Class_Name__c = 'CDdOpportunityTriggerHelper';
            log.Method_Name__c = methodName;
            log.Log_Level__c = 'Error';
            log.Log__c = error.getMessage();
            logs.add(log);
        }
        insert logs;
    }

    /**
     * @author: Ila Maheshwari
     * @date 08/2023
     * @description: BZAP-52638 Update Base Points for CAN Pre-Sale
     *
     */
    public static void populateCampaignNameOnOpportunity(List<Opportunity> newOpps, Map<Id, Opportunity> oldMap){
        Set<Id> campaignIds = new Set<Id>();
        List<Opportunity> filteredOpps = new List<Opportunity>();

        for (Opportunity opp : newOpps){
		    if (oldMap == null || isFieldUpdated(opp, oldMap, 'CampaignId')) {
                campaignIds.add(opp.CampaignId);
                filteredOpps.add(opp);
            }
        }

        Map<Id, Campaign> campaignMap = new Map<Id, Campaign>([SELECT Name FROM Campaign WHERE ID IN :campaignIds]);

        for(Opportunity opp : filteredOpps){
            opp.Primary_Campaign_Name__c = String.isBlank(opp.CampaignId) ? null : campaignMap.get(opp.CampaignId).Name;
        }
    }
}