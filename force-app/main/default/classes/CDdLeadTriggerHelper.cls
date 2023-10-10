/**
 * @description       : Trigger Helper for Lead object
 * @author            : Jose Vega
 * @last modified on  : 10-24-2022
 * @last modified by  : Jose Vega
**/
public with sharing class CDdLeadTriggerHelper {

    public static Boolean runOnce = CDdExperimentSvc.getFeatureFlag('Run_Once__c');
    public static Boolean isInsertOperation = false;
    public static boolean ranSetAccountId = false;
    public static boolean ranMarkEmailChange = false;
    public static boolean ranValidateLeadConversion = false;
    public static boolean ranCheckLeadCoverage = false;
    public static boolean ranUpdateTaskCount = false;
    public static boolean ranUpdateOpportunityFieldsForConvertedLeads = false;
    public static boolean ranUpdateAccountForConvertedLeads = false;
    public static boolean ranVerifyEmail = false;
    public static boolean ranMapLatinToKanjiInsert = false;
    public static boolean ranmapLatinToKanjiUpdate = false;
    public static boolean isLeadVerticalCategoryConvert = false;
    public static boolean ranPopulateLeadStage = false;
    public static boolean ranUpdateCamapignOnCFCLeads = false;
    public static boolean ranUpdateLeadOwnerToPrevOwner = false;

    public static Boolean LEAD_TRIGGER_RUN_ONCE = false;
    public static boolean matchLeadMissingParentAccountFlag = false;
    public static Boolean COPY_PARENT_ACCOUNT_TO_LEAD = false;

    public static final vCS__c SETTINGS = vCS__c.getInstance();
    public static Map<Id, Group> UNASSIGNED_QUEUE;
    public static final String ERROR_MSG_UNASSIGNED_LEAD_CONVERSION = System.label.ERROR_MSG_UNASSIGNED_LEAD_CONVERSION;
    public static final Boolean VALIDATE_UNASSIGNED_LEAD_CONVERSION = CDdExperimentSvc.getFeatureFlag('Validate_Unassigned_Lead_Conversion__c');
    public static final Boolean FEATURE_LEAD_VERIFY_EMAIL_ENABLED = CDdExperimentSvc.getFeatureFlag('Lead_Verify_Email__c');
    public static final Set<String> EMAILS_INVALID = CDdNeverbounceHandler.EMAILS_INVALID;
    public static final String EMAIL_VERIFICATION_STATUS_INVALID = CDdNeverbounceHandler.EMAIL_VERIFICATION_STATUS_INVALID;
    public static final String SOBJECT_TYPE_ACCOUNT = 'Account';
    public static final String SOBJECT_TYPE_LEAD = 'Lead';

    public static final Map<String, Schema.RecordTypeInfo> RECORD_TYPE_INFO_BY_DEV_NAME
        = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName();
    public static final String RECORD_TYPE_DEV_NAME_MASTER_LEAD = 'Master_Lead';
    public static Id RECORD_TYPE_ID_MASTER_LEAD;
    public static final List<Self_Serve_Users__c> SELF_SERVE_USERS;
    public static final Set<String> SELF_SERVE_USER_IDS;

    public static Id oppdoorDashDriveRTId = CDdSchemaUtils.OPPORTUNITY_RT.doorDashDriveId();
    public static Id accDoorDashDriveRTId = CDdSchemaUtils.ACCOUNT_RT.doorDashDriveId();
    public static Id leadDoorDashDriveRTId = CDdSchemaUtils.LEAD_RT.doorDashDriveLeadsId();
    public static Id leadDoorDashForBusinessRTId = CDdSchemaUtils.LEAD_RT.doorDashForBusinessId();
    public static boolean ranUpdateRecordTypeOnDriveLeadConversion = false;
    public static boolean ranOutreachLeadCurrentSequence = false;
    public static final Boolean enableUpdate_RT_OnDriveLeadConversion = CDdExperimentSvc.getCustomSettingFeatureFlag('Enable_Update_Record_Type_on_Drive_Lead__c');
    public static final Boolean disableUpdateCampaignOnCFCLeads = CDdExperimentSvc.getCustomSettingFeatureFlag('Disable_Update_Campaign_On_CFC_Leads__c');
    public static final Boolean disableOutreachLeadCurrentSequence = CDdExperimentSvc.getCustomSettingFeatureFlag('Disable_Outreach_Lead_Current_Sequence__c');

    static {
        UNASSIGNED_QUEUE = new Map<Id, Group>([SELECT Id, Name from Group where Type = 'Queue' AND NAME = 'Unassigned']);
        RECORD_TYPE_ID_MASTER_LEAD = RECORD_TYPE_INFO_BY_DEV_NAME.get(RECORD_TYPE_DEV_NAME_MASTER_LEAD).getRecordTypeId();
        SELF_SERVE_USERS = Self_Serve_Users__c.getAll().values();
        SELF_SERVE_USER_IDS = new Set<String>();
        for (Self_Serve_Users__c selfServeUser : SELF_SERVE_USERS){
            SELF_SERVE_USER_IDS.add(selfServeUser.User_Id__c);
        }
    }

    /**
    * @description BZAP-3547 Match Missing Parent Account
    */
    public static void matchMissingParentLead(List<Lead> newLeads) {
        if (!SETTINGS.parentAccMatchFlag__c || matchLeadMissingParentAccountFlag) return;

        Lead currLead;
        Decimal businessId;
        Map<Decimal, Lead> businessToLeadIdMap = new Map<Decimal, Lead>();
        List<Id> recTypes = new List<Id>();

        Id enterpriseMarktetplaceId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Master_Lead').getRecordTypeId();
        recTypes.add(enterpriseMarktetplaceId);

        for (Lead l : newLeads) {
            if (recTypes.contains(l.RecordTypeId) && l.Parent_Account__c == null && l.Business_ID__c != null) {
                businessToLeadIdMap.put((l.Business_ID__c).stripTrailingZeros(), l);
            }
        }

        if (businessToLeadIdMap.isEmpty()) return;

        for (Account parentAcc : [SELECT Id, Business_ID__c FROM Account WHERE RecordType.DeveloperName = 'Parent_Account' AND Business_ID__c in :businessToLeadIdMap.keySet()]) {
            businessId = parentAcc.Business_ID__c != null ? (parentAcc.Business_ID__c).stripTrailingZeros() : null;
            if (businessToLeadIdMap.get(businessId) != null) {
                currLead = businessToLeadIdMap.get(businessId);
                currLead.Parent_Account__c = parentAcc.Id;
                matchLeadMissingParentAccountFlag = true;
            }
        }
    }
    /**
    * @author Tia Xuan
    * @date 2019-04
    * @description BZAP-3689 Check lead coverage
    */
    @future(callout=true)
    public static void checkLeadCoverage(String newLeadsString) {
        // if runOnce feature is enabled and if the method has already ran once, do not run the method again.
        if(runOnce && ranCheckLeadCoverage) {
            return;
        }

        List<Lead> newLeads = (List<Lead>) JSON.deserialize(newLeadsString, List<Lead>.class);

        List<Id> leadIds = new List<Id>();
        for (Lead l : newLeads){
            if (String.isNotBlank(l.street)
                && String.isNotBlank(l.city)
                && String.isNotBlank(l.stateCode)
                && String.isNotBlank(l.PostalCode)
                && String.isNotBlank(l.countryCode)){
                    leadIds.add(l.Id);
                }

        }

        if (leadIds.size() > 0){
            CDdCoverageCheckSvcV2.checkLeadCoverage(leadIds);
            ranCheckLeadCoverage = true;
        }

    }
    /**
    * @author Sriram
    * @date 2019-05
    * @description BZAP-3902 - update account for converted leads
    *              BZAP-7780 - Sriram - Update nTam
    */
    public static void updateAccountForConvertedLeads(List<Lead> convertedLeads){
        // if runOnce feature is enabled and if the method has already ran once, do not run the method again.
        if(runOnce && ranUpdateAccountForConvertedLeads) {
            return;
        }

        List<Account> accountsToUpdate = new List<Account>();
        Set<Id> accountIds = new Set<Id>();
        for (Lead l : convertedLeads) if (!accountIds.contains(l.ConvertedAccountId)) { // First Lead wins in the case of multiples per Account
            Map<String,Object> accountFieldToUpdate = new Map<String,Object>();
            /*
            Account a = new Account(
                Id = l.ConvertedAccountId
                , Converted_Lead_ID__c = l.Lead_ID18__c
                , BypassValidationForProcessBuilder__c = true
            );
            */
            accountFieldToUpdate.put('Converted_Lead_ID__c', l.Lead_ID18__c);
            accountFieldToUpdate.put('BypassValidationForProcessBuilder__c', true);

            if (l.High_AOV__c){
                // a.High_AOV__c = l.High_AOV__c;
                accountFieldToUpdate.put('High_AOV__c', l.High_AOV__c);
            }
            if (l.Lead_List__c!= null){
                // a.Lead_List__c = l.Lead_List__c;
                accountFieldToUpdate.put('Lead_List__c', l.Lead_List__c);
            }
            if (l.Store_ID__c!= null){
                // a.Restaurant_ID__c = l.Store_ID__c;
                accountFieldToUpdate.put('Restaurant_ID__c', l.Store_ID__c);
            }
            if (l.Business_ID__c!= null){
                // a.Business_ID__c = l.Business_ID__c;
                accountFieldToUpdate.put('Business_ID__c', l.Business_ID__c);
            }
            if (l.ARR__c != null){
                // a.ARR__c = l.ARR__c;
                accountFieldToUpdate.put('ARR__c', l.ARR__c);
            }
            Decimal nTam = getNTamAmount(l);
            if (nTam != null){
                // a.Amount__c = nTam;
                accountFieldToUpdate.put('Amount__c', nTam);
            }
            if (String.isNotBlank(l.Lead_Type__c)){
                // a.Lead_Type_mapped__c = l.Lead_Type__c;
                accountFieldToUpdate.put('Lead_Type_mapped__c', l.Lead_Type__c);
            }
            if (String.isNotBlank(l.Deck_Rank__c)){
                // a.Deck_Rank__c = l.Deck_Rank__c;
                accountFieldToUpdate.put('Deck_Rank__c', l.Deck_Rank__c);
            }
            if (String.isNotBlank(l.Starting_Point__c)){
                // a.Starting_Point__c = l.Starting_Point__c;
                accountFieldToUpdate.put('Starting_Point__c', l.Starting_Point__c);
            }
            if (l.Starting_Point_ID__c != null){
                // a.Starting_Point_ID__c = l.Starting_Point_ID__c;
                accountFieldToUpdate.put('Starting_Point_ID__c', l.Starting_Point_ID__c);
            }
            if (String.isNotBlank(l.Deactivation_Note__c)){
                // a.Deactivation_Notes__c = l.Deactivation_Note__c;
                accountFieldToUpdate.put('Deactivation_Notes__c', l.Deactivation_Note__c);
            }
            if (String.isNotBlank(l.Deactivation_Code__c)){
                // a.Deactivated_Reason__c = l.Deactivation_Code__c;
                accountFieldToUpdate.put('Deactivated_Reason__c', l.Deactivation_Code__c);
            }
            if (String.isNotBlank(l.Phone)){
                // a.Phone = l.Phone;
                accountFieldToUpdate.put('Phone', l.Phone);
            }
            if (String.isNotBlank(l.Type__c)){
                // a.Account_Type__c = l.Type__c;
                accountFieldToUpdate.put('Account_Type__c', l.Type__c);
            }
            if (String.isNotBlank(l.Launch_Deck_Rank__c)){
                // a.Launch_Deck_Rank__c = l.Launch_Deck_Rank__c;
                accountFieldToUpdate.put('Launch_Deck_Rank__c', l.Launch_Deck_Rank__c);
            }
            if (String.isNotBlank(l.ConvertedContactId)){
                // a.Decision_Maker__c = l.ConvertedContactId;
                accountFieldToUpdate.put('Decision_Maker__c', l.ConvertedContactId);
            }
            if (String.isNotBlank(l.Merchant_Categories__c)){
                // a.Merchant_Categories__c = l.Merchant_Categories__c;
                accountFieldToUpdate.put('Merchant_Categories__c', l.Merchant_Categories__c);
                // a.Primary_Merchant_Category__c = l.Primary_Merchant_Category__c;
                accountFieldToUpdate.put('Primary_Merchant_Category__c', l.Primary_Merchant_Category__c);
                isLeadVerticalCategoryConvert = true;
            }
            //accountsToUpdate.add(a);
            CDdTriggerOptimizationHelper.setSobjectToUpdate('Account', l.ConvertedAccountId, accountFieldToUpdate);
            accountIds.add(l.ConvertedAccountId);
        }

        // update accountsToUpdate;

        if(CDdLeadTriggerHelper.isAsyncOk()) {
            resetBypassValidationFlagOnAccount(accountIds);
        }
        ranUpdateAccountForConvertedLeads = true;
    }
    /**
    * @author Sriram
    * @date 2019-05
    * @description BZAP-3902 - reset bypass validation flag
    */
    @future
    public static void resetBypassValidationFlagOnAccount(Set<Id> accountIds){
        List<Account> accountsToUpdate = new List<Account>();
        for (Id accountId : accountIds){
            // accountsToUpdate.add(new Account(
            //     Id = accountId
            //     , BypassValidationForProcessBuilder__c = false
            // ));
            Map<String,Object> fieldVal = new Map<String,Object>{
                'BypassValidationForProcessBuilder__c' => false
            };
            CDdTriggerOptimizationHelper.setSobjectToUpdate('Account', accountId, fieldVal);
        }
        CDdTriggerOptimizationHelper.executeSObjectDML();
        // update accountsToUpdate;
    }
    /**
    * @author Sriram
    * @date 2019-06-08
    * @description BZAP-3455 - validate lead conversion
    */
    public static void validateLeadConversion(Map<Id, Lead> newMap, Map<Id, Lead> oldMap){
        // if runOnce feature is enabled and if the method has already ran once, do not run the method again.
        if(runOnce && ranValidateLeadConversion) {
            return;
        }

        for (Id leadId : newMap.keySet()){
            if (newMap.get(leadId).IsConverted && !oldMap.get(leadId).IsConverted){
                if (VALIDATE_UNASSIGNED_LEAD_CONVERSION && UNASSIGNED_QUEUE.containsKey(oldMap.get(leadId).OwnerId)){
                    newMap.get(leadId).OwnerId.addError(ERROR_MSG_UNASSIGNED_LEAD_CONVERSION);
                }
            }
        }
        ranValidateLeadConversion = true;
    }

    /**
    * @author Sriram
    * @date 2019-06-24
    * @description BZAP-4027 - Automatically populate "Decision Maker" field in an opportunity from a lead being converted
    *              BZAP-6747 - Knick -- Optimization
    * Mar 19 - Jeegar merged this code with updateOpportunityFieldsForConvertedLeads.
    */
    // public static void updateOpportunityForConvertedLeads(List<Lead> convertedLeads, Map<Id, Opportunity> updateMap) {
    // for (Lead l : convertedLeads){
    //     if ((String.isNotBlank(l.ConvertedOpportunityId)) && (String.isNotBlank(l.ConvertedContactId))) {
    //         Opportunity opp = updateMap.get(l.ConvertedOpportunityId);
    //         if (opp == null) opp = new Opportunity();
    //         opp.Id = l.ConvertedOpportunityId;
    //         opp.Decision_Maker__c = l.ConvertedContactId;
    //         updateMap.put(opp.Id, opp);
    //     }
    // }
    // }


    /**
    * @author Tia Xuan
    * @date 2019-11
    * @description BZAP-5470 Update Primary Campaign Source on opportunity on lead convert
    *              BZAP-6747 - Knick -- Optimization
    *              BZAP-7780 - Sriram - Update nTam
    */
    public static void updateOpportunityFieldsForConvertedLeads(List<Lead> convertedLeads, Map<Id, Opportunity> updateMap) {
        // if runOnce feature is enabled and if the method has already ran once, do not run the method again.
        if(runOnce && ranUpdateOpportunityFieldsForConvertedLeads) {
            return;
        }

        Map<Id, Id> campaignMap = new Map<Id, Id>();
        Opportunity opp;

        for (Lead l : convertedLeads){
            campaignMap.put(l.Id, null);
        }

        List<CampaignMember> cms = [SELECT Id, CampaignId, LeadId
                                    FROM CampaignMember
                                    WHERE LeadId = : campaignMap.keySet()
                                    ORDER BY LastModifiedDate DESC];

        for (CampaignMember cm : cms){
            if (campaignMap.get(cm.LeadId) == null){
                campaignMap.put(cm.LeadId, cm.CampaignId);
            }
        }

        for (Lead l : convertedLeads){
            if (String.isNotBlank(l.ConvertedOpportunityId)) {
                opp = updateMap.get(l.ConvertedOpportunityId);
                if (opp == null) {
                    opp = new Opportunity(
                        Id = l.ConvertedOpportunityId
                    );
                }
                Decimal nTam = getNTamAmount(l);
                if (nTam != null) {
                    opp.Amount = nTam;
                }
                if (campaignMap.containsKey(l.Id) && campaignMap.get(l.Id) != null) {
                        opp.CampaignId = campaignMap.get(l.Id);
                        updateMap.put(opp.Id, opp);
                }
                if (String.isNotBlank(l.ConvertedContactId)) {
                        opp.Decision_Maker__c = l.ConvertedContactId;
                        updateMap.put(opp.Id, opp);
                }
            }
        }
        ranUpdateOpportunityFieldsForConvertedLeads = true;
    }

    /**
    * @description BZAP-4559 - Copy Parent Account information to master leads (unconverted leads)
    */
    public static void copyFromParentAccountToMasterLeads(List<Lead> newList, Map<Id,Lead> oldMap){
        if (COPY_PARENT_ACCOUNT_TO_LEAD) { return; }
        Set<Id> parentAccountIds = new Set<Id>();
        Set<Id> masterLeadIds = new Set<Id>();
        for (Lead l : newList){
            if (RECORD_TYPE_ID_MASTER_LEAD.equals(l.RecordTypeId) && !l.IsConverted && String.isNotBlank(l.Parent_Account__c)){
                if ( (oldMap == null) || (oldMap.get(l.Id) != null && l.Parent_Account__c != oldMap.get(l.Id).Parent_Account__c)){
                    parentAccountIds.add(l.Parent_Account__c);
                    masterLeadIds.add(l.Id);
                }
            }
        }
        // Retrieve Lead records for update
        List<Lead> leadsToUpdate = (List<Lead>)new CDdSObjectFieldCopyProcessor(
            new CDdSObjectFieldCopyInitializer(SOBJECT_TYPE_ACCOUNT)
            .getFieldCopyObj(SOBJECT_TYPE_LEAD)
            , parentAccountIds
            , masterLeadIds)
            .targetRecords;
        if (!leadsToUpdate.isEmpty()){
            update leadsToUpdate;
            COPY_PARENT_ACCOUNT_TO_LEAD = true;
        }
    }
    /**
    * @author Sriram
    * @date 08/05/2019
    *
    * @description BZAP-4113 Dial Count And Email Count
    */
    public static void updateTaskCount(Map<Id, Lead> newMap, Map<Id, Lead> oldMap) {
        // if runOnce feature is enabled and if the method has already ran once, do not run the method again.
        if(runOnce && ranUpdateTaskCount) {
            return;
        }

        List<Update_Task_Count_Event__e> updateTaskCountEvents = new List<Update_Task_Count_Event__e>();
        for (Lead newLead : newMap.values()){
            if (oldMap!=null && !oldMap.isEmpty() && oldMap.containsKey(newLead.Id)){
                Lead oldLead = oldMap.get(newLead.Id);
                if (!newLead.IsConverted && !newLead.OwnerId.equals(oldLead.OwnerId)){
                    updateTaskCountEvents.add(new Update_Task_Count_Event__e(
                        SObject_Record_Id__c = newLead.Id
                        , SObject_Type__c = SOBJECT_TYPE_LEAD
                    ));
                }
            }
        }
        if (!updateTaskCountEvents.isEmpty()) {
            EventBus.publish(updateTaskCountEvents);
        }
        ranUpdateTaskCount = true;

    }

    /**
    * @author Knick
    * @description BZAP-6347 Move Rollup and Lookup Helper to Trigger - set AccountId based on Lead.Store_ID__c
    */
    public static void setAccountId (List<Lead> leads, Map<Id, Lead> oldMap) {
        // if runOnce feature is enabled and if the method has already ran once, do not run the method again.
        if(runOnce && ranSetAccountId) {
            return;
        }

        if (CDdCustomMetaData.isDisabled('CDdLeadTriggerHandler_setAccountId')) return;

        Set<String> StoreIDs = new Set<String>();
        for (Lead l : leads)
            if ((l.Store_ID__c != null) && ((oldMap == null) || (l.Store_ID__c != oldMap.get(l.Id).Store_ID__c)))
            StoreIDs.add(l.Store_ID__c);

        if (StoreIDs.size() > 0) {

            Map<String, String> AccountIDmap = new Map<String, String>();

            List<Account> Accounts = [SELECT Id, Restaurant_ID__c FROM Account WHERE Restaurant_ID__c IN :StoreIDs];
            for (Account a : Accounts) AccountIDmap.put(a.Restaurant_ID__c, a.Id);

            for (Lead l : leads){
                if ((l.Store_ID__c != null) && ((oldMap == null) || (l.Store_ID__c != oldMap.get(l.Id).Store_ID__c))){
                    l.Account__c = AccountIDmap.get(l.Store_ID__c);
                }
                ranSetAccountId = true;
            }


        }
    }

    /**
    * @author Knick
    * @description BZAP-6347 Move Rollup and Lookup Helper to Trigger - do Rollups from Lead to Account
    */
    public static void doAccountRollups (List<Lead> leads, Map<Id, Lead> oldMap) {

        if (CDdCustomMetaData.isDisabled('CDdLeadTriggerHandler_doAccountRollups')) return;

        Set<Id> ParentAccountIDs = new Set<Id>();
        for (Lead l : leads) {
            if (oldMap == null) {
                if ((l.Parent_Account__c != null) &&                    // new Lead on Account
                    (l.RecordTypeId == RECORD_TYPE_ID_MASTER_LEAD))     // with Master Lead record type
                    ParentAccountIDs.add(l.Parent_Account__c);
            }
            else {
                Lead oldLead = oldMap.get(l.Id);
                if ((l.Parent_Account__c != oldLead.Parent_Account__c) ||       // Account has changed OR
                    (l.RecordTypeId != oldLead.RecordTypeId) ||                 // Record Type has changed OR
                    (l.Deck_Rank_Number__c != oldLead.Deck_Rank_Number__c) ||   // Deck Rank Number has changed OR
                    (l.Deck_Rank__c != oldLead.Deck_Rank__c) ||                 // Underlying Deck Rank has changed OR
                    (l.Amount__c != oldLead.Amount__c) ||                       // Amount has changed OR
                    (l.Has_nTam__c != oldLead.Has_nTam__c) ||                   // Has nTam has changed OR
                    (l.IsConverted != oldLead.IsConverted)) {                   // Lead has been Converted
                        if (l.Parent_Account__c != null)
                            ParentAccountIDs.add(l.Parent_Account__c);         // ... recalculate for Account
                        if (oldLead.Parent_Account__c != null)
                            ParentAccountIDs.add(oldLead.Parent_Account__c);   // ... recalculate for old Account
                    }
            }
        }

        if (ParentAccountIDs.size() > 0) {
            CDdGenericPlatformEventHelper.publishEvents(CDdGenericPlatformEventHelper.PlatformEventType.ACCOUNT_LEAD_ROLLUP, ParentAccountIds);
        }

    }

    /**
    * @author Knick
    * @description BZAP-7644 Lead Conversion CPU timeout (moving Aggregate to Event Handler)
    * @date 2020-05
    */
    public static void handleRollupEvents(List<Generic_Platform_Event__e> rollupEvents) {
        Set<Id> ParentAccountIDs = new Set<Id>();
        for (Generic_Platform_Event__e rollupEvent : rollupEvents) {
            ParentAccountIDs.add(rollupEvent.sObjectId__c);
        }

        if (ParentAccountIDs.size() > 0) {
            AggregateResult[] AggregateLeadResults = [
                SELECT
                    Parent_Account__c,
                    MIN(Deck_Rank_Number__c) minDeckRankNumber,
                    AVG(Amount__c) avgAmount,
                    SUM(Has_nTam__c) sumNtam,
                    COUNT(Id) countLeads
                FROM Lead
                WHERE
                    IsDeleted = false AND IsConverted = false AND Parent_Account__c IN :ParentAccountIDs
                AND RecordTypeId = :RECORD_TYPE_ID_MASTER_LEAD
                GROUP BY Parent_Account__c
            ];

            Map<Id, Account> accountToUpdateMap = new Map<Id, Account>();

            for (AggregateResult ar : AggregateLeadResults) {
                Account account = new Account(
                    Id = (Id)ar.get('Parent_Account__c'),
                    Highest_Lead_Deck_Dank__c = (Decimal)ar.get('minDeckRankNumber'),
                    Average_of_Lead_nTam__c = (Decimal)ar.get('avgAmount'),
                    Leads__c = (Decimal)ar.get('countLeads'),
                    of_Leads_w_nTam__c = (Decimal)ar.get('sumNtam')
                );
                accountToUpdateMap.put(account.Id, account);
            }

            // Update occurs from a Platform Event
            update accountToUpdateMap.values();
        }
    }
    /**
    * @author Tia Xuan
    * @date 2020-01
    * @description BZAP-6479 Concatenate SSMO UUID field on all lead merges
    */
    @future
    public static void concatenateLeadMerge(Set<Id> leadIds) {

        Map<Id, Lead> oldLeads = new Map<Id, Lead>([SELECT Id, SSMO_UUID__c, MasterRecordId FROM Lead WHERE Id IN :leadIds ALL ROWS]);
        Map<Id, Lead> newLeads = new Map<Id, Lead>();
        for(Lead record:oldLeads.values()) {
            newLeads.put(record.MasterRecordId, null);
        }
        newLeads.remove(null);
        if(newLeads.isEmpty()) {
            return;
        }
        newLeads.putAll([SELECT Id, SSMO_UUID__c FROM Lead WHERE Id IN :newLeads.keySet() FOR UPDATE]);
        for(Id oldId: leadIds) {
            Lead oldLead = oldLeads.get(oldId), newLead = newLeads.get(oldLead.MasterRecordId);
            if(String.isBlank(oldLead.SSMO_UUID__c)) {
                continue;
            }
            if(String.isBlank(newLead.SSMO_UUID__c)) {
                newLead.SSMO_UUID__c = '';
            }
            if (String.isBlank(newLead.SSMO_UUID__c)){
                newLead.SSMO_UUID__c += oldLead.SSMO_UUID__c;
            } else {
                newLead.SSMO_UUID__c += ',' +oldLead.SSMO_UUID__c;
            }
        }
        update newLeads.values();
    }

    /**
    * @author Tia Xuan
    * @date 2020-02
    * @description BZAP-5647 Neverbounce API Integration
    */
    public static void markEmailChange(List<Lead> leads, Map<Id, Lead> oldMap) {
        // if runOnce feature is enabled and if the method has already ran once, do not run the method again.
        if(runOnce && ranMarkEmailChange) {
            return;
        }

        Set<String> affectedRTIds = CDdNeverbounceHandler.leadRecordTypeIds;

        for (Lead l : leads){
            if (affectedRTIds.contains(l.RecordTypeId)){
                String newEmail = String.isNotBlank(l.Email) ? l.Email : '';
                String oldEmail = ( oldMap!=null && oldMap.get(l.Id)!=null && String.isNotBlank(oldMap.get(l.Id).Email) ) ? oldMap.get(l.Id).Email : '';
                if (String.isNotBlank(newEmail) && !newEmail.equalsIgnoreCase(oldEmail)){
                    if (EMAILS_INVALID.contains(newEmail.toLowerCase())){
                        l.Email_Updated__c = false;
                        l.Email_Verification_Status__c = EMAIL_VERIFICATION_STATUS_INVALID;
                    } else {
                        l.Email_Updated__c = true;
                    }
                }
            }
        }
        ranMarkEmailChange = true;
    }

    public static void mapLatinToKanjiInsert(List<Lead> newList) {
        // if runOnce feature is enabled and if the method has already ran once, do not run the method again.
        if(runOnce && ranMapLatinToKanjiInsert) {
            return;
        }
        //map for StateCode to State Name
        Map<String, String> MapStateCodeToStateName = new Map<String, String>();
        //map for CountryCode to Country name
        Map<String, String> MapCountryCodeToCountryName = new Map<String, String>();

        Schema.DescribeFieldResult fieldResult = User.statecode.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple){
            MapStateCodeToStateName.put(f.getValue(), f.getLabel());
        }

        Schema.DescribeFieldResult fieldResult2 = User.Countrycode.getDescribe();
        List<Schema.PicklistEntry> ple2 = fieldResult2.getPicklistValues();
        for( Schema.PicklistEntry f : ple2){
            MapCountryCodeToCountryName.put(f.getValue(), f.getLabel());
        }

        for(Lead l: newList){
            String latinCountry = MapCountryCodeToCountryName.get(l.countryCode);
            String latinState = MapStateCodeToStateName.get(l.stateCode);
            //if latin populate, transalte to kanji else check for kanji and translate to latin
            if(latinCountry == 'Japan'){
                system.debug('Kanji Verified Checkbox '+l.Kanji_Address_Verified__c);
                system.debug('Kanji Street '+l.Kanji_Street__c);
                system.debug('Kanji City '+l.Kanji_City__c);
                system.debug('Kanji State '+l.Kanji_State__c);
                system.debug('Kanji Zipcode '+l.Kanji_Zipcode__c);
                system.debug('Kanji Country '+l.Kanji_Country__c);

                if(l.Kanji_Address_Verified__c == false){
                    /*
                    if(l.street != null && l.street != '' && (l.Kanji_Street__c==null || l.Kanji_Street__c=='')){
                        l.Kanji_Street__c =  l.street;
                        system.debug('Mapping Latin Street to Kanji on Insert');
                    }
                    if(l.city != null && l.city != ''&& (l.Kanji_City__c ==null || l.Kanji_City__c =='')){
                        l.Kanji_City__c = l.city;
                        system.debug('Mapping Latin City to Kanji on Insert');
                    }
                    if(latinState != null && latinState != '' && (l.Kanji_State__c==null || l.Kanji_State__c=='')){
                        l.Kanji_State__c = latinState;
                        system.debug('Mapping Latin State to Kanji on Insert');
                    } */
                    if(l.street != null && l.street != ''){
                        l.Kanji_Street__c =  l.street;
                        system.debug('Mapping Latin Street to Kanji on Insert');
                    }
                    if(l.city != null && l.city != ''){
                        l.Kanji_City__c = l.city;
                        system.debug('Mapping Latin City to Kanji on Insert');
                    }
                    if(latinState != null && latinState != ''){
                        l.Kanji_State__c = latinState;
                        system.debug('Mapping Latin State to Kanji on Insert');
                    }

                    if(l.postalcode != null && l.postalcode != ''){
                        l.Kanji_Zipcode__c = l.postalcode;
                        system.debug('Mapping Latin postal to Kanji on Insert');
                    }
                    if(latinCountry != null && latinCountry != ''){
                        l.Kanji_Country__c = latinCountry;
                        system.debug('Mapping Latin country to Kanji');
                    }
                    if(l.address2__c != null && l.address2__c != ''){
                        l.Kanji_Address2__c = l.address2__c;
                    }
                }



            }
        }
        ranMapLatinToKanjiInsert = true;
    }

    public static void mapLatinToKanjiUpdate(Map<Id, Lead> newMap, Map<Id, Lead> oldMap ){
        if(runOnce && ranmapLatinToKanjiUpdate) {
            return;
        }

        //map for StateCode to State Name
        Map<String, String> MapStateCodeToStateName = new Map<String, String>();

        //map for CountryCode to Country name
        Map<String, String> MapCountryCodeToCountryName = new Map<String, String>();

        Schema.DescribeFieldResult fieldResult = User.statecode.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        System.debug('Picklist::'+ple);
        for( Schema.PicklistEntry f : ple){
            MapStateCodeToStateName.put(f.getValue(), f.getLabel());
        }

        Schema.DescribeFieldResult fieldResult2 = User.Countrycode.getDescribe();
        List<Schema.PicklistEntry> ple2 = fieldResult2.getPicklistValues();
        System.debug('Picklist::'+ple2);
        for( Schema.PicklistEntry f : ple2){
            MapCountryCodeToCountryName.put(f.getValue(), f.getLabel());
        }

        // List<Lead> leadsToUpdate = new List<Lead>();
        for(Lead l : newMap.values()){
            string latinCountry = MapCountryCodeToCountryName.get(l.countryCode);
            string latinState = MapStateCodeToStateName.get(l.stateCode);

            //keep both verification fields in sync
            if(l.smartystreets__Address_Verified__c == false){
                l.Kanji_Address_Verified__c = false;
            }
            system.debug('Latin Country '+latinCountry);
            if(latinCountry == 'Japan'){
                system.debug('Kanji Verified Checkbox '+l.Kanji_Address_Verified__c);
                system.debug('Kanji Street '+l.Kanji_Street__c);
                system.debug('Kanji City '+l.Kanji_City__c);
                system.debug('Kanji State '+l.Kanji_State__c);
                system.debug('Kanji Zipcode '+l.Kanji_Zipcode__c);
                system.debug('Kanji Country '+l.Kanji_Country__c);
                system.debug('Address Last verified '+l.smartystreets__Address_Last_Verified__c);
                if(l.smartystreets__Address_Last_Verified__c == oldMap.get(l.id).smartystreets__Address_Last_Verified__c ){

                    if(l.street != null && l.street != '' && (oldMap.get(l.id).street != l.street || String.isBlank(l.Kanji_Street__c))){
                        system.debug('Mapping Latin Street to Kanji on Update');
                        l.Kanji_Street__c =  l.street;
                        l.Kanji_Address_Verified__c = false;
                    }
                    if(l.city != null && l.city != '' && (oldMap.get(l.id).city != l.city || String.isBlank(l.Kanji_City__c))){
                        system.debug('Mapping Latin City to Kanji on Update');
                        l.Kanji_City__c = l.city;
                        l.Kanji_Address_Verified__c = false;
                    }
                    if(latinState != null && latinState != '' && (oldMap.get(l.id).stateCode != l.stateCode || String.isBlank(l.Kanji_State__c)) ){
                        system.debug('Mapping Latin State to Kanji on Update');
                        l.Kanji_State__c = latinState;
                        l.Kanji_Address_Verified__c = false;
                    }
                    if(l.postalcode != null && l.postalcode != '' && (oldMap.get(l.id).postalcode != l.postalcode || String.isBlank(l.Kanji_Zipcode__c))){
                        l.Kanji_Zipcode__c = l.postalcode;
                        l.Kanji_Address_Verified__c = false;

                    }
                    if(latinCountry != null && latinCountry != '' && (oldMap.get(l.id).countryCode != l.countryCode || String.isBlank(l.Kanji_Country__c) ) ){
                        l.Kanji_Country__c = latinCountry;
                        l.Kanji_Address_Verified__c = false;
                    }
                    if(l.Address2__c != null && l.Address2__c != '' && (oldMap.get(l.id).Address2__c != l.Address2__c || String.isBlank(l.Kanji_Address2__c))){
                        system.debug('Mapping Latin Address2 to Kanji on Update');
                        l.Kanji_Address2__c = l.Address2__c;
                        l.Kanji_Address_Verified__c = false;
                    }
                    if(l.Kanji_Address_Verified__c == false)
                    {

                        l.Kanji_Address_Footnotes__c='';
                        l.Kanji_Address_Return_Code__c='';
                        l.Kanji_Address_Last_Verified__c=null;

                    }
            	}


            }






        }

        ranmapLatinToKanjiUpdate = true;
    }

    /**
    * @description Method used to populate country specific fields in the Lead object
    * this uses the i18n custom metadata to find which fields need to be populated
    * based on the Lead's record type and country.
    * @author Jose Vega | 12-07-2021
    * @param List<Lead> leadsToFill
    **/
    public static void setLeadDefaulFieldsByCountry(List<Lead> leadsToFill) {
        CDdI18NDefaultValueMappingUtil.setDefaultValuesBasedOnCountry(leadsToFill);
    }
    /**
    * @author Sriram
    * @date 2020-06
    * @description Return the nTam amount on the lead only if the following conditions are met else return a null value
    * 1. Created By <> Self Serve User
    * 2. Normalized TAM Sales (Amount__c) <> $0.00 (or Blank)
    **/
    private static Decimal getNTamAmount(Lead lead){
        if (!SELF_SERVE_USER_IDS.contains(lead.CreatedById)
            &&
            (lead.Amount__c != null && lead.Amount__c != 0)){
                return lead.Amount__c;
            }
        return null;
    }

    /**
* BZAP-8973: Concatenate Marketing_UUID__c
*/
    public static void concatenateMarketingUUID(List<Lead> leads, Map<Id, Lead> oldMap) {
        List<String> newMarketingUUIDs = new List<String>();
        for (Lead lead : leads) {
            String oldUUID = oldMap.get(lead.Id).Marketing_UUID__c;
            String newUUID = lead.Marketing_UUID__c;
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
                lead.Marketing_UUID__c = String.join(newMarketingUUIDs, ', ' );
            }
            newMarketingUUIDs.clear();
        }
    }
    /**
* @author Sriram
* @date 2021-02
* @description BZAP-9829 Neverbounce Enhancement
*/
    public static void verifyEmail(List<Lead> leads, Map<Id, Lead> oldMap) {
        // if runOnce feature is enabled and if the method has already ran once, do not run the method again.
        if(runOnce && ranVerifyEmail) {
            return;
        }
        Set<String> affectedRTIds = CDdNeverbounceHandler.leadRecordTypeIds;
        Set<Id> verifyEmailLeadIds = new Set<Id>();
        for (Lead l : leads){
            if (affectedRTIds.contains(l.RecordTypeId)){
                String newEmail = String.isNotBlank(l.Email) ? l.Email : '';
                String oldEmail = ( oldMap!=null && oldMap.get(l.Id)!=null && String.isNotBlank(oldMap.get(l.Id).Email) ) ? oldMap.get(l.Id).Email : '';
                if (String.isNotBlank(newEmail) && !newEmail.equalsIgnoreCase(oldEmail)){
                    if (!EMAILS_INVALID.contains(newEmail.toLowerCase())){
                        verifyEmailLeadIds.add(l.Id);
                    }
                }
            }
        }
        if (!verifyEmailLeadIds.isEmpty()) {
            if (Test.isRunningTest() || FEATURE_LEAD_VERIFY_EMAIL_ENABLED) {
                CDdGenericPlatformEventHelper.publishEvents(CDdGenericPlatformEventHelper.PlatformEventType.LEAD_VERIFY_EMAIL, verifyEmailLeadIds);
            }
            ranVerifyEmail = true;
        }
    }
    public static void handleVerifyEmailEvents(List<Generic_Platform_Event__e> verifyEmailEvents) {
        Set<Id> verifyEmailLeadIds = new Set<Id>();
        for (Generic_Platform_Event__e verifyEmailEvent : verifyEmailEvents) {
            verifyEmailLeadIds.add(verifyEmailEvent.sObjectId__c);
        }
        if (!Test.isRunningTest()){
            Database.executeBatch(new CDdNeverbounceWeeklyBatch(verifyEmailLeadIds), Integer.valueOf(CDdNeverbounceHandler.setting.Batch_Size__c));
        }
    }

    /**
    * @author Ed
    * @date 2021-06
    * @description BZAP-11027
    */
    public static void handleMerchantCategories(List<Lead> newList, Map<Id, Lead> oldMap) {
        CDdVerticalCategoryHelper vertCatHelper = new CDdVerticalCategoryHelper(Lead.sObjectType);
        vertCatHelper.handleMerchantCategories(newList, oldMap);

        if (oldMap != null) {
            vertCatHelper.handlePrimaryCategoryUpdate(newList, oldMap);
        }
    }
    /**
    * @author Ed
    * @date 2021-06
    * @description BZAP-11027
    */
    public static void deleteAllMxCategories(Map<Id, Lead> oldMap) {
        CDdVerticalCategoryHelper vertCatHelper = new CDdVerticalCategoryHelper(Lead.sObjectType);
        vertCatHelper.deleteAllMxCategories(oldMap);
    }

    /**
    * @author Ed
    * @date 2021-06
    * @description BZAP-11027
    */
    public static void handleMxCategoryMerge(List<Lead> oldList) {
        CDdVerticalCategoryHelper vertCatHelper = new CDdVerticalCategoryHelper(Lead.sObjectType);
        vertCatHelper.handleMxCategoryMerge(oldList);
    }

    /**
    * @author Kamlesh
    * @date 2021-08
    * @description BASD-12790
    */
    public static void updateEnrichmentAccount(List<Lead> newLeadList,Map<Id,Lead> oldLeadMap){
        Map<String, Lead> CHDIdToLeadRecMap = new Map<String, Lead>();
        Set<String> blankCHDIdLeadSet = new Set<String>();
        for(Lead leadRec: newLeadList){
            if( oldLeadMap == null ){
                if(String.isnotBlank(leadRec.CHD_ID__c)){
                    CHDIdToLeadRecMap.put(leadRec.CHD_ID__c, leadRec);
                }
            }else{
                if( oldLeadMap.containsKey(leadRec.Id) && oldLeadMap.get(leadRec.Id).CHD_ID__c <> leadRec.CHD_ID__c){
                    if( String.isNotBlank(leadRec.CHD_ID__c)){
                        chdIdToLeadRecMap.put(leadRec.CHD_ID__c, leadRec);
                    }else{
                        blankCHDIdLeadSet.add(oldLeadMap.get(leadRec.Id).CHD_ID__c);
                    }
                }
            }
        }

        if(!chdIdToLeadRecMap.isEmpty() || !blankCHDIdLeadSet.isEmpty()){
            List<Enrichment_Account__c> enrichmentAccountList =[ SELECT Id, CHD_ID__c, Lead__c FROM Enrichment_Account__c
                                                                WHERE CHD_ID__c =: CHDIdToLeadRecMap.keySet()
                                                                    OR CHD_ID__c =: blankCHDIdLeadSet
                                                                ];
            List<Enrichment_Account__c> updateEnrichmentAccountList = new List<Enrichment_Account__c>();
            for(Enrichment_Account__c enrichmentAccountRec: enrichmentAccountList){
                // Associates the lead with the appropriate Enrichment Account record
                if( CHDIdToLeadRecMap.containsKey(enrichmentAccountRec.CHD_ID__c)){
                    enrichmentAccountRec.Lead__c = CHDIdToLeadRecMap.get(enrichmentAccountRec.CHD_ID__c).Id;
                    updateEnrichmentAccountList.add( enrichmentAccountRec );
                }else if(blankCHDIdLeadSet.contains(enrichmentAccountRec.CHD_ID__c)) {
                    // If lead.CHD_ID__c update as blank then remove the lead from the appropriate Enrichment Account record.
                    enrichmentAccountRec.Lead__c = null;
                    updateEnrichmentAccountList.add( enrichmentAccountRec );
                }
            }

            update updateEnrichmentAccountList;
        }
    }

    /**
    * @author Nathalie Mendezona
    * @description Parses phone numbers and returns a string without spaces. This applies to non-US/Canada phone numbers
    */
    public static void updateInternationalPhoneNumbers(List<Lead> newList, Map<Id, Lead> oldMap) {
        Boolean isInsert = oldMap == null ? true : false;

        CDdI18nUtility.updateInternationalPhoneNumbers(newList, oldMap, 'Lead', isInsert);
    }

    /**
    * @author Kamlesh
    * @date 2021-09
    * @description BZAP-11554
    */
    public static void UpdateRecordTypeOnDriveLeadConversion(List<Lead> newLeadList,Map<Id,Lead> oldLeadMap){

        // if Feature Flags 'Enable Update Record Type on Drive Lead' is true execute the code or if the method has already ran once, do not run the method again.
        if(!enableUpdate_RT_OnDriveLeadConversion || ranUpdateRecordTypeOnDriveLeadConversion){
            return;
        }
        // List<Opportunity> convertedOppList = new List<Opportunity>();
        // List<Account> convertedAccountList = new List<Account>();
        for(Lead leadRec: newLeadList){
            if(leadRec.RecordTypeId == leadDoorDashDriveRTId && leadRec.IsConverted
               && leadRec.IsConverted != oldLeadMap.get(leadRec.id).IsConverted ){
                    if( leadRec.ConvertedOpportunityId != null ){
                        CDdTriggerOptimizationHelper.setSobjectToUpdate('Opportunity', leadRec.ConvertedOpportunityId, 'RecordTypeId', oppdoorDashDriveRTId);
                        // convertedOppList.add( new Opportunity(id= leadRec.ConvertedOpportunityId,
                        //                                     RecordTypeId = oppdoorDashDriveRTId) );
                    }
                    if(leadRec.ConvertedAccountId != null ){
                        CDdTriggerOptimizationHelper.setSobjectToUpdate('Account', leadRec.ConvertedAccountId, 'RecordTypeId', accDoorDashDriveRTId);
                        //convertedAccountList.add( new Account(id= leadRec.ConvertedAccountId,
                        //                                     RecordTypeId = accDoorDashDriveRTId) );
                    }
               }
        }
        // if(!convertedOppList.isEmpty()){
        //     update convertedOppList;
        // }
        // if(!convertedAccountList.isEmpty()){
        //     update convertedAccountList;
        // }
        ranUpdateRecordTypeOnDriveLeadConversion = true;
    }

     /**
    * @author Veera
    * @date 2021-11
    * @description BZAP-12548
    * To keep special characters on the address when smarty streets to update
    */
    public static void handleSpecialCharsOnLeadChange(List<Lead> newList, Map<Id, Lead> oldMap){
        for(Lead leadRec : newList){
            Boolean keepOldAddress = CDdI18nUtility.handleSpecialCharsOnLeadChange(leadRec.CountryCode, oldMap.get(leadRec.Id)?.Street, leadRec.Street);
            if(keepOldAddress){
                leadRec.Street = oldMap.get(leadRec.Id).Street;
            }
        }
    }

    /**
     * @date 02/2022
     * @description: BZAP-13229 Lead Lifecycle (P0) - Automation Piece
     * @param List<Lead> Collection of new Lead records
     * @param Map<Lead> Map of old Lead records
     * @return
     */
    public static void populateLeadStage(List<Lead> newLeads, Map<Id, Lead> oldMap){

        if (ranPopulateLeadStage) { return; }

        for (Lead leadRec : newLeads){
            if(!String.isBlank(leadRec.Primary_Campaign_Source_Name__c) && leadRec.Primary_Campaign_Source_Name__c.contains('AcqMktg') &&
                leadDoorDashForBusinessRTId == leadRec.RecordTypeId) {

                if(leadRec.IsConverted && String.isNotBlank(leadRec.ConvertedOpportunityId)){
                    leadRec.Lead_Stage__c = 'Sales Qualified Opportunity';
                }else if(leadRec.Status == 'Untouched' || leadRec.Status == 'Contacted' || leadRec.Status == 'Trying to Reach'){
                    leadRec.Lead_Stage__c = 'Marketing Qualified Lead';
                }else if(leadRec.Status == 'DM Found'){
                    leadRec.Lead_Stage__c = 'Sales Qualified Lead';
                }else if(leadRec.Status == 'Meeting Set' || leadRec.Status == 'Meeting Ran / Negotiated'){
                    leadRec.Lead_Stage__c = 'Sales Accepted Lead';
                }else if(leadRec.Status == 'Unqualified'){
                    leadRec.Lead_Stage__c = 'Disqualified';
                }else if(leadRec.Status == 'Converted Dupe'){
                    leadRec.Lead_Stage__c = null;
                }
            }
        }

        ranPopulateLeadStage = true;
    }

    /**
     * @date May 2022
     * @description: BZAP-14577 Lead Sub status update to Reinbounding
     * @param List<Lead> Collection of new Lead records
     * @param Map<Lead> Map of old Lead records
     * @return Void
     */
    public static void populateLeadSubStatusToReinbounding(List<Lead> newLeads, Map<Id, Lead> oldMap)
    {
        for (Lead leadRec : newLeads)
        {
            if (leadRec.RecordTypeId == RECORD_TYPE_ID_MASTER_LEAD && oldMap.get(leadRec.Id).Last_Inbound_Date_Time__c != null && leadRec.Last_Inbound_Date_Time__c != oldMap.get(leadRec.Id).Last_Inbound_Date_Time__c && leadRec.Last_Inbound_Date_Time__c != null)
            {
                if(leadRec.Status == 'Untouched' || leadRec.Status == 'Trying to Reach' || leadRec.Status == 'DM found' || leadRec.Status == 'Meeting Set' || leadRec.Status == 'Meeting Ran / Negotiated')
                {
                    leadRec.Lead_Sub_Status__c = 'Reinbounding';
                }
                else if(leadRec.Status == 'Not Interested - Cool Down' || leadRec.Status == 'Unqualified')
                {
                    leadRec.Status = 'Untouched';
                    leadRec.Lead_Sub_Status__c = 'Reinbounding';
                }
            }
        }
    }

    /**
    * @description Add Leads to Campaign if DDFB and Caviar BZAP-13021
    * @author Jose Vega | 03-30-2022
    * @param List<Lead> newLeads
    **/
    public static void updateCamapignOnCFCLeads(List<Lead> newLeads){
        if (ranUpdateCamapignOnCFCLeads || disableUpdateCampaignOnCFCLeads) { return; }

        List<CampaignMember> campaignMemberList = new List<CampaignMember>();

        for (Lead leadRec : newLeads){
            if(leadRec.Lead_Platform__c == CDdSupportConstants.LEAD_PLATFORM_CAVIAR && leadDoorDashForBusinessRTId == leadRec.RecordTypeId) {
                campaignMemberList.add(new CampaignMember(
                    CampaignId = System.Label.Campaign_ID_for_DDFB_Marketing,
                    LeadId = leadRec.Id));
            }
        }

        if(!campaignMemberList.isEmpty()){
            List<Database.SaveResult> resList = Database.insert(campaignMemberList, false);
            CDdErrorUtilities.publishException('CDdLeadTriggerHandler','updateCamapignOnCFCLeads',resList);
        }

        ranUpdateCamapignOnCFCLeads = true;
    }

    /**
    * @description Update Sequence BZAP-13021
    * @author Jose Vega | 04-27-2022
    * @param List<Lead> newLeads
    * @param Map<Id Lead> oldMap
    **/
    public static void outreachLeadCurrentSequence(List<Lead> newLeads, Map<Id, Lead> oldMap){
        if (ranOutreachLeadCurrentSequence || disableOutreachLeadCurrentSequence) { return; }

        for (Lead leadRec : newLeads){
            if(leadRec.Initial_Sequence_Name__c == null && leadRec.Name_of_Currently_Active_Sequence__c != null) {
                leadRec.Initial_Sequence_Date__c = System.Today();
                leadRec.Initial_Sequence_ID__c = leadRec.ID_of_Currently_Active_Sequence__c;
                leadRec.Initial_Sequence_Name__c = leadRec.Name_of_Currently_Active_Sequence__c;
            }
        }

        ranOutreachLeadCurrentSequence = true;
    }

    /**
     * @author Swedhaa Sri M
     * @date 05/2022
     * @description: BASD-29431 Update Merchant Categories based on Primary Merchant Category on Lead
     */

    public static void updateHubspotMerchantCategories(List<Lead> newLeads, Map<Id, Lead> oldMap){
        CDdVerticalCategoryHelper vertCatHelper = new CDdVerticalCategoryHelper(Lead.sObjectType);
        vertCatHelper.updateHubspotMerchantCategories(newLeads, oldMap);
    }

    private static Boolean isAsyncOk() {
        return !System.isFuture() && !System.isBatch() && !System.isQueueable();
    }

    /**
     * @author Abhijeet K
     * @date 06/2022
     * @description: BZAP-15785 Revert the Lead Owner from Bad Lead Data to prev Owner
    */
    public static void updateLeadOwnerToPrevOwner(List<Lead> newLeads, Map<Id, Lead> oldMap) {
        if (ranUpdateLeadOwnerToPrevOwner) { return; }
        Set<Id> leadIdsToUpdate = new Set<Id>();
        for(Lead newLead: newLeads) {
            Boolean isLeadStatusChangedFromUnqualified = oldMap.get(newLead.Id).Status == 'Unqualified'
                && newLead.Status != 'Unqualified';
            if(isLeadStatusChangedFromUnqualified) {
                leadIdsToUpdate.add(newLead.Id);
            }
        }
        Map<String, LeadHistory> leadIdToLatestHistoryRecord = getLeadIdToPreviousOwnerMap(leadIdsToUpdate);
        for(Lead newLead: newLeads) {
            if(leadIdToLatestHistoryRecord != null && leadIdToLatestHistoryRecord.containsKey(newLead.Id)) {
                newLead.OwnerId = (Id) leadIdToLatestHistoryRecord.get(newLead.Id).OldValue;
            }
        }
        ranUpdateLeadOwnerToPrevOwner = true;
    }

    private static Map<String, LeadHistory> getLeadIdToPreviousOwnerMap(Set<Id> leadIds) {
        Map<String, LeadHistory> leadIdToLatestHistoryRecord = new Map<String, LeadHistory>();
        if(!leadIds.isEmpty()) {
            List<LeadHistory> leadHistoryRecs = [
                SELECT leadId,NewValue, OldValue, createdDate
                FROM LeadHistory
                WHERE leadId in :leadIds
                AND Field = 'Owner'
            ];
            Group queue = [
                SELECT Id from Group where Type = 'Queue'
                AND Name = 'Bad Lead Data' LIMIT 1
            ];
            Set<Id> ownerIdSet = new Set<Id>();
            for(LeadHistory leadHistoryRecord: leadHistoryRecs) {
                if(leadHistoryRecord.NewValue != queue.Id) continue;
                String newOwnerId = String.valueOf(leadHistoryRecord.NewValue);
                ownerIdSet.add(newOwnerId);
                if(leadIdToLatestHistoryRecord.containsKey(LeadHistoryRecord.Id) && newOwnerId.startsWith('00G')) {
                    LeadHistory prevHistoryRecord = leadIdToLatestHistoryRecord.get(LeadHistoryRecord.leadId);
                    if(leadHistoryRecord.CreatedDate > prevHistoryRecord.CreatedDate) {
                        leadIdToLatestHistoryRecord.put(leadHistoryRecord.LeadId, leadHistoryRecord);
                    }
                } else {
                    leadIdToLatestHistoryRecord.put(leadHistoryRecord.LeadId, leadHistoryRecord);
                }
            }
            Set<Id> activeOwnerSet = new Set<Id>();
            for(User u:[SELECT Id, IsActive FROM User WHERE Id IN:ownerIdSet AND IsActive=True]){
                activeOwnerSet.add(u.Id);
            }

            for(String leadId:leadIdToLatestHistoryRecord.keySet()){
                String newOwnerId = String.valueOf(leadIdToLatestHistoryRecord.get(leadId).NewValue);
                if(!activeOwnerSet.contains(newOwnerId)){
                    leadIdToLatestHistoryRecord.remove(leadId);
                }
            }
        }
        return leadIdToLatestHistoryRecord;
    }

    /**
     * @author Ila Maheshwari
     * @date 10/2022
     * @description: BASD-29430 Keep Primary_Merchant_Categories__c and Primary_Merchant_Category__c field value in sync
     */
    public static void syncPrimaryMerchantCategoryFields(List<Lead> newList, Map<Id, Lead> oldMap) {
		CDdVerticalCategoryHelper vertCatHelper = new CDdVerticalCategoryHelper(Lead.sObjectType);
        vertCatHelper.syncPrimaryMerchantCategoryFields(newList, oldMap);
    }
}