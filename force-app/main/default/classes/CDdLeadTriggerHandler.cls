/**
* @author Salesforce.com Foundation
* @date 2018-10
*
* @description Trigger Handler on Accounts that handles ensuring the correct system
* flags are set on our special accounts (Household, One-to-One), and also detects
* changes on Household Account that requires name updating
*/


public class CDdLeadTriggerHandler extends CDdTriggerBase {

    public static final String BEFORE_INSERT = '><><><><>CDdLeadTriggerHandler.beforeInsert()';
    public static final String BEFORE_UPDATE = '><><><><>CDdLeadTriggerHandler.beforeUpdate()';
    public static final String BEFORE_DELETE = '><><><><>CDdLeadTriggerHandler.beforeDelete()';
    public static final String AFTER_INSERT = '><><><><>CDdLeadTriggerHandler.afterInsert()';
    public static final String AFTER_UPDATE = '><><><><>CDdLeadTriggerHandler.afterUpdate()';
    public static final String AFTER_DELETE = '><><><><>CDdLeadTriggerHandler.afterDelete()';
    public static Integer cpuUsageLeadTriggerHandler = 0;

    public void beforeInsert(List<Lead> newList) {
        cpuUsageLeadTriggerHandler = 0;
        cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_INSERT,cpuUsageLeadTriggerHandler,'Start');

        CDdLeadTriggerHelper.mapLatinToKanjiInsert(newList);
        cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_INSERT,cpuUsageLeadTriggerHandler,'mapLatinToKanjiInsert');

        CDdLeadTriggerHelper.matchMissingParentLead(newList);
        cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_INSERT,cpuUsageLeadTriggerHandler,'matchMissingParentLead');

        CDdLeadTriggerHelper.setAccountId(newList, null);
        cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_INSERT,cpuUsageLeadTriggerHandler,'setAccountId');

        CDdLeadTriggerHelper.markEmailChange(newList, null);
        cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_INSERT,cpuUsageLeadTriggerHandler,'markEmailChange');

        CDdLeadTriggerHelper.updateInternationalPhoneNumbers(newList, null);
        cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_INSERT,cpuUsageLeadTriggerHandler,'updateInternationalPhoneNumbers');

        CDdLeadTriggerHelper.setLeadDefaulFieldsByCountry(newList);
        cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_INSERT,cpuUsageLeadTriggerHandler,'setDefaultFieldsByCountry');

        CDdLeadTriggerHelper.populateLeadStage(newList, null);
        cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_INSERT,cpuUsageLeadTriggerHandler,'popoulateLeadStage');

        CDdLeadTriggerHelper.outreachLeadCurrentSequence(newList, null);
        cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_INSERT,cpuUsageLeadTriggerHandler,'outreachLeadCurrentSequence');

        CDdLeadTriggerHelper.updateHubspotMerchantCategories(newList, null);

        CDdLeadTriggerHelper.syncPrimaryMerchantCategoryFields(newList, null);

        CDdUtilities.logCpuUsage(BEFORE_INSERT,cpuUsageLeadTriggerHandler,'End');
    }

    public void beforeUpdate(Map<Id,Lead> newMap, Map<Id,Lead> oldMap) {
        if(CDdTaskTriggerHandler.isCountingTask){
            return;
        }

        cpuUsageLeadTriggerHandler = 0;
        cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_UPDATE,cpuUsageLeadTriggerHandler,'Start');

        CDdLeadTriggerHelper.handleSpecialCharsOnLeadChange(newMap.values(), oldMap);
        cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_UPDATE,cpuUsageLeadTriggerHandler,'handleSpecialCharsOnLeadChange');

        CDdLeadTriggerHelper.validateLeadConversion(newMap, oldMap);
        cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_UPDATE,cpuUsageLeadTriggerHandler,'validateLeadConversion');

        CDdLeadTriggerHelper.matchMissingParentLead(newMap.values());
        cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_UPDATE,cpuUsageLeadTriggerHandler,'matchMissingParentLead');

        CDdLeadTriggerHelper.setAccountId(newMap.values(), oldMap);
        cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_UPDATE,cpuUsageLeadTriggerHandler,'setAccountId');

        CDdLeadTriggerHelper.markEmailChange(newMap.values(), oldMap);
        cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_UPDATE,cpuUsageLeadTriggerHandler,'markEmailChange');

        CDdLeadTriggerHelper.concatenateMarketingUUID(newMap.values(), oldMap);
        cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_UPDATE,cpuUsageLeadTriggerHandler,'concatenateMarketingUUID');

        CDdLeadTriggerHelper.mapLatinToKanjiUpdate(newMap, oldMap);
        cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_UPDATE,cpuUsageLeadTriggerHandler,'mapLatinToKanjiUpdate');

        CDdLeadTriggerHelper.updateHubspotMerchantCategories(newMap.values(), oldMap);

        CDdLeadTriggerHelper.syncPrimaryMerchantCategoryFields(newMap.values(), oldMap);

        CDdLeadTriggerHelper.handleMerchantCategories(newMap.values(), oldMap);
        cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_UPDATE,cpuUsageLeadTriggerHandler,'handleMerchantCategories');

        CDdLeadTriggerHelper.updateEnrichmentAccount(newMap.values(), oldMap);
        cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_UPDATE,cpuUsageLeadTriggerHandler,'updateEnrichmentAccount');

        CDdLeadTriggerHelper.updateInternationalPhoneNumbers(newMap.values(), oldMap);
        cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_UPDATE,cpuUsageLeadTriggerHandler,'updateInternationalPhoneNumbers');

        CDdLeadTriggerHelper.populateLeadStage(newMap.values(), oldMap);
        cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_UPDATE,cpuUsageLeadTriggerHandler,'populateLeadStage');

        CDdLeadTriggerHelper.populateLeadSubStatusToReinbounding(newMap.values(), oldMap);
        cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_UPDATE,cpuUsageLeadTriggerHandler,'populateLeadSubStatusToReinbounding');

        CDdLeadTriggerHelper.outreachLeadCurrentSequence(newMap.values(), null);
        cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_UPDATE,cpuUsageLeadTriggerHandler,'outreachLeadCurrentSequence');

        CDdLeadTriggerHelper.updateLeadOwnerToPrevOwner(newMap.values(), oldMap);
        cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_UPDATE,cpuUsageLeadTriggerHandler,'updateLeadOwnerToPrevOwner');

        // GDPR Email CMS
        CDdGDPRCreateContactHelper.treatChangedEmailAudit(newMap.values(),oldMap);
        cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_UPDATE,cpuUsageLeadTriggerHandler,'CDdGDPRCreateContactHelper.treatChangedEmailAudit');

        CDdUtilities.logCpuUsage(BEFORE_UPDATE,cpuUsageLeadTriggerHandler,'End');
    }

    public void beforeDelete(Map<Id, Lead> oldMap) {
        cpuUsageLeadTriggerHandler = 0;
        cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_DELETE,cpuUsageLeadTriggerHandler,'Start');

        CDdLeadTriggerHelper.deleteAllMxCategories(oldMap);
        cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_DELETE,cpuUsageLeadTriggerHandler,'deleteAllMxCategories');

        CDdUtilities.logCpuUsage(BEFORE_DELETE,cpuUsageLeadTriggerHandler,'End');
    }

    /**
    * @description BZAP-3689 added afterInsert to get lead ID
    */
    public void afterInsert(List<Lead> newList) {
        cpuUsageLeadTriggerHandler = 0;
        cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(AFTER_INSERT,cpuUsageLeadTriggerHandler,'Start');

        List<Lead> leadsToCheckCoverage = new List<Lead>();
        // do not check coverage for reopened lead on insert. They will be picked up in a nightly job.
        for(Lead currLead : newList) {
            if (!currLead.Reopened_Lead__c){
                leadsToCheckCoverage.add(currLead);
            }
        }
        if(!leadsToCheckCoverage.isEmpty() && super.isAsyncOk()){
            CDdLeadTriggerHelper.checkLeadCoverage(JSON.serialize(leadsToCheckCoverage));
        }

        cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(AFTER_INSERT,cpuUsageLeadTriggerHandler,'checkLeadCoverage');

        CDdLeadTriggerHelper.copyFromParentAccountToMasterLeads(newList, null);
        cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(AFTER_INSERT,cpuUsageLeadTriggerHandler,'copyFromParentAccountToMasterLeads');

        CDdLeadTriggerHelper.doAccountRollups(newList, null);
        cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(AFTER_INSERT,cpuUsageLeadTriggerHandler,'doAccountRollups');

        CDdLeadTriggerHelper.verifyEmail(newList, null);
        cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(AFTER_INSERT,cpuUsageLeadTriggerHandler,'verifyEmail');

        CDdLeadTriggerHelper.handleMerchantCategories(newList, null);
        cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(AFTER_INSERT,cpuUsageLeadTriggerHandler,'handleMerchantCategories');

        CDdLeadTriggerHelper.updateEnrichmentAccount(newList, null);
        cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(AFTER_INSERT,cpuUsageLeadTriggerHandler,'updateEnrichmentAccount');

        // GDPR Email CMS
        CDdGDPRCreateContactHelper.createGDPREmailCreateContactEvent(Trigger.New,null);
        cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(AFTER_INSERT,cpuUsageLeadTriggerHandler,'CDdGDPRCreateContactHelper.createGDPREmailCreateContactEvent');

        CDdLeadTriggerHelper.updateCamapignOnCFCLeads(newList);
        cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(AFTER_INSERT,cpuUsageLeadTriggerHandler,'updateCampaignOnCFCLeads');

        // *** KEEP THIS AT THE END ***
        CDdUtilities.logCpuUsage(AFTER_INSERT,cpuUsageLeadTriggerHandler,'End');
    }

    /**
    * @description BZAP-3902 - update account for converted leads
    */
    public void afterUpdate(Map<Id,Lead> newMap, Map<Id,Lead> oldMap) {
        if(CDdTaskTriggerHandler.isCountingTask){
            return;
        }

        cpuUsageLeadTriggerHandler = 0;
        cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(AFTER_UPDATE,cpuUsageLeadTriggerHandler,'Start');

        List<Lead> convertedLeads = new List<Lead>();
        for (Lead l : newMap.values()){
            if (l.IsConverted
                && l.IsConverted != oldMap.get(l.id).IsConverted
                && String.isNotBlank(l.ConvertedAccountId)){
                    convertedLeads.add(l);
                }
        }
        if (!convertedLeads.isEmpty() && !UserInfo.getUserId().equals(System.Label.Trigger_Lead_Exclude_Run_User)){
            CDdLeadTriggerHelper.updateAccountForConvertedLeads(convertedLeads);
            cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(AFTER_UPDATE,cpuUsageLeadTriggerHandler,'updateAccountForConvertedLeads');

            Map<Id, Opportunity> updatedOpportunityMap = new Map<Id, Opportunity>();
            // updateOpportunityForConvertedLeads(convertedLeads, updatedOpportunityMap);
            // System.debug('><><><><><><><><><><><><><> CDdLeadTriggerHelper.updateOpportunityForConvertedLeads =  ' + ((Limits.getCpuTime() - cpuUsageLeadTriggerHandler)) );
            // cpuUsageLeadTriggerHandler = Limits.getCpuTime();

            CDdLeadTriggerHelper.updateOpportunityFieldsForConvertedLeads(convertedLeads, updatedOpportunityMap);
            if (updatedOpportunityMap.size() > 0) update updatedOpportunityMap.values();
            cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(AFTER_UPDATE,cpuUsageLeadTriggerHandler,'updateOpportunityFieldsForConvertedLeads');
        }

        CDdLeadTriggerHelper.copyFromParentAccountToMasterLeads(newMap.values(), oldMap);
        cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(AFTER_UPDATE,cpuUsageLeadTriggerHandler,'copyFromParentAccountToMasterLeads');

        CDdLeadTriggerHelper.updateTaskCount(newMap, oldMap);
        cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(AFTER_UPDATE,cpuUsageLeadTriggerHandler,'updateTaskCount');

        CDdLeadTriggerHelper.doAccountRollups(newMap.values(), oldMap);
        cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(AFTER_UPDATE,cpuUsageLeadTriggerHandler,'doAccountRollups');

        CDdLeadTriggerHelper.verifyEmail(newMap.values(), oldMap);
        cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(AFTER_UPDATE,cpuUsageLeadTriggerHandler,'verifyEmail');

        CDdLeadTriggerHelper.UpdateRecordTypeOnDriveLeadConversion(newMap.values(), oldMap);
        cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(AFTER_UPDATE,cpuUsageLeadTriggerHandler,'UpdateRecordTypeOnDriveLeadConversion');

        // GDPR Email CMS
        CDdGDPRCreateContactHelper.createGDPREmailCreateContactEvent(Trigger.New,oldMap);
        cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(AFTER_UPDATE,cpuUsageLeadTriggerHandler,'CDdGDPRCreateContactHelper.createGDPREmailCreateContactEvent');

        CDdTriggerOptimizationHelper.executeSObjectDML();
        cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(AFTER_UPDATE,cpuUsageLeadTriggerHandler,'CDdTriggerOptimizationHelper.executeSObjectDML');

        // *** KEEP THIS AT THE END ***
        CDdUtilities.logCpuUsage(AFTER_UPDATE,cpuUsageLeadTriggerHandler,'End');
    }

    /**
    * @description BZAP-6479 - Concatenate SSMO UUID field on all lead merges
    */
    public void afterDelete(Map<Id,Lead> newMap, Map<Id,Lead> oldMap) {
        cpuUsageLeadTriggerHandler = 0;
        cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(AFTER_DELETE,cpuUsageLeadTriggerHandler,'Start');

        if(super.isAsyncOk()) {
            CDdLeadTriggerHelper.concatenateLeadMerge(oldMap.keySet());
            cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(AFTER_DELETE,cpuUsageLeadTriggerHandler,'concatenateLeadMerge');
        }

        CDdLeadTriggerHelper.handleMxCategoryMerge(oldMap.values());
        cpuUsageLeadTriggerHandler = CDdUtilities.logCpuUsage(AFTER_DELETE,cpuUsageLeadTriggerHandler,'handleMxCategoryMerge');

        CDdUtilities.logCpuUsage(AFTER_DELETE,cpuUsageLeadTriggerHandler,'End');
    }



}