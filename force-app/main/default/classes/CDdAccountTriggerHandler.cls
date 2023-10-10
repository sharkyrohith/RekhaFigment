/**
* @author: aamrute
* @date: 2018-11-29
* @description Trigger handler for Account.
*/
public class CDdAccountTriggerHandler {

    public static final Feature_Flags__c featureFlag = Feature_Flags__c.getInstance();
    public static Boolean ACCT_TRIGGER_RUN_ONCE = false;

    public static final String BEFORE_INSERT = '><><><><>CDdAccountTriggerHandler.beforeInsert()';
    public static final String BEFORE_UPDATE = '><><><><>CDdAccountTriggerHandler.beforeUpdate()';
    public static final String AFTER_INSERT = '><><><><>CDdAccountTriggerHandler.afterInsert()';
    public static final String AFTER_UPDATE = '><><><><>CDdAccountTriggerHandler.afterUpdate()';
    public static final String AFTER_DELETE = '><><><><>CDdAccountTriggerHandler.afterDelete()';
    public static Integer cpuUsageAcctTriggerHandler = 0;

    public void beforeDelete(Map<Id, Account> oldMap) {
        System.debug('Entered into beforeDelete() method: $$$$$$$$$$$$$: ' + oldMap.keyset());
        // this trigger wasn't running
        // CDdAccountHelperMethods.preventMasterDeletion(oldMap);
        CDdAccountHelperMethods.deleteAllMxCategories(oldMap);

        System.debug('Entered into beforeDelete() method: ****************** Permission Vlaue: ' + FeatureManagement.checkPermission('Allow_Opportunity_Deletion_for_Restricted_Status'));
        /* Get the custome Lable for Allow_Opportunity_Deletion_for_Restricted_Status value and store in a variable */
        if(!FeatureManagement.checkPermission('Allow_Opportunity_Deletion_for_Restricted_Status')){

            System.debug('Entered into beforeDelete() method: $$$$$$$$$$$$$ The Permission is False:');

       	 	/* Apply the business Rules befor deleting the Accounts. */
        	preventAccountDeletion(oldMap);
        }
    }

    /**
    *  @author: Raheem
    *  @purpose: Before deleting an account, check the opportunity status and few more BS rules, if not valid restrict the Account deletion
    *  @Story: Jira# BZAP-11138
    *  1) Accounts should not be deleted if they have an Opportunity that is in "Ready for Signature", "Out for Signature" and "Contract Signed" etc stages.
    *  2) Deletion is allowed when the user is a member of "Business Applications team" or "the Data operation team".
    *  3) Deletion is allowed when the user when the permission set to bypass account Deletion is “Bypass_Account_Deletion“ is met.
    */
    public void preventAccountDeletion(Map<Id, Account> oldMap) {

        System.debug('Entered into preventAccountDeletion() method: $$$$$$$$$$$$$ The preventAccountDeletion Entered');

        /* if oldMap is empty do nothing */
        if(oldMap.isEmpty()){
            return;
        }

        /* Get the custome Label */
        String oppStageNamesString = System.Label.Restricted_Stage_To_Delete_Account;
        String opportunityRestrictedUserIdsStr = System.Label.Account_Deletion_Restricted_Created_By_Ids;
        String accountDeleteValidationErrorMsg = System.Label.Account_Delete_Validation_Error;

        List<String> opportunityStageList = oppStageNamesString.remove(' ').Split(',');
        List<String> accountDelRestrictedCreatedByIds = opportunityRestrictedUserIdsStr.Split(',');

        System.debug('Entered into oppStageNamesString() method: $$$$$$$$$$$$$ Got the Custome Labels for oppStageNamesString: ' + oppStageNamesString + ' opportunityRestrictedUserIdsStr: ' +opportunityRestrictedUserIdsStr + ' accountDeleteValidationErrorMsg: ' +accountDeleteValidationErrorMsg);

        /* Opprtunites are not in the restricrted stages or opprtunity restricted users list is empty, do nothing*/
        if(String.isBlank(oppStageNamesString) || String.isBlank(opportunityRestrictedUserIdsStr)){
            return;
        }

        /* Retrive all the opprtunities for the account(s) and where Opportunity is in restricted to delete stage*/
        List<Opportunity> opportunitieList = [SELECT Id, StageName, AccountId, CreatedById FROM Opportunity WHERE AccountId IN: oldMap.keySet()];

        System.debug('Entered into oppStageNamesString() method: $$$$$$$$$$$$$ opportunity :' + opportunitieList.toString());

        /** Apply theh StageName filter from the custome label to Retrived List from SF */
        List<Opportunity> optFinalList = new List<Opportunity>();
        if(opportunitieList !=null){

        	for(Opportunity optLsitFromSF: opportunitieList){
                for(String stgName: opportunityStageList){

                    System.debug('Entered into oppStageNamesString() method: $$$$$$$$$$$$$ inside the loop optLsitFromSF.StageName :' + optLsitFromSF.StageName.remove(' '));

                    if(optLsitFromSF.StageName.remove(' ') == stgName) {
                       optFinalList.add(optLsitFromSF);
                       System.debug('Entered into oppStageNamesString() method: $$$$$$$$$$$$$ Added to the ListoptFinalList :' + optLsitFromSF.id);
                    }

                    System.debug('Entered into oppStageNamesString() method: $$$$$$$$$$$$$ inside the loop stgName of the Label :' + stgName);

                }

       		 }
        }

        System.debug('Entered into oppStageNamesString() method: $$$$$$$$$$$$$ Ran the Oppt Retriva by AccountID Query');

        /* Create a set to add the account ids found for the oppotunites in restricted stage */
        Set<id> accountWithOpptID = new Set<id>();

        /*
        * If opprtunities are found, then loop through the opprtunites to get the accoindIds then add to the set,
        * The Set is used to apply additional busness rules
        */
        if(optFinalList != null) {

			System.debug('Entered into oppStageNamesString() method: $$$$$$$$$$$$$ the opportunitieList != null: ' + optFinalList.size());

            for(Opportunity opportunityRec: optFinalList) {
                accountWithOpptID.add(opportunityRec.AccountId);

                System.debug('Entered into oppStageNamesString() method: $$$$$$$$$$$$$ the opportuniteis AccountIDD: '+opportunityRec.AccountId + 'CreatedById :'+opportunityRec.CreatedById +' Oppty StageNAme: '+ opportunityRec.StageName);
            }
        }

        /* Loop through the Account map to evaluate found opprtunities are part of the restridctions and the CreatedById falls under the error condtions,
        * if the above condtions are met then, set the Error conditon on the Account object.
        */

  		System.debug('Entered into oppStageNamesString() method: $$$$$$$$$$$$$ the 12345');

        for(Account accountRec: oldMap.values()) {

            if(accountWithOpptID.contains(accountRec.id) || accountDelRestrictedCreatedByIds.contains(accountRec.CreatedById)) {
                 accountRec.addError(accountDeleteValidationErrorMsg);

                 System.debug('Entered into oppStageNamesString() method: $$$$$$$$$$$$$ the accountRec.CreatedById : '+accountRec.CreatedById);
            }
        }
    }

    public void beforeInsert(List<Account> newList) {
        cpuUsageAcctTriggerHandler = 0;
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_INSERT,cpuUsageAcctTriggerHandler,'Start');

        CDdAccountHelperMethods.populateTerritory(newList,null,true);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_INSERT,cpuUsageAcctTriggerHandler,'populateTerritory');

        CDdAccountHelperMethods.updateAcctsWithParentAcctInformation(newList,null,true);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_INSERT,cpuUsageAcctTriggerHandler,'updateAcctsWithParentAcctInformation');

        CDdAccountHelperMethods.matchMissingParentAccount(newList);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_INSERT,cpuUsageAcctTriggerHandler,'matchMissingParentAccount');

        CDdAccountHelperMethods.PopulatePresaleOwner(newList);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_INSERT,cpuUsageAcctTriggerHandler,'PopulatePresaleOwner');

        CDdAccountHelperMethods.populatePreviousOwner(newList, null);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_INSERT,cpuUsageAcctTriggerHandler,'populatePreviousOwner');

        CDdAccountHelperMethods.createLeadOnLeadCreationApproval(newList, null);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_INSERT,cpuUsageAcctTriggerHandler,'createLeadOnLeadCreationApproval');

        CDdAccountHelperMethods.cleanEncryptedFields(newList, null);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_INSERT,cpuUsageAcctTriggerHandler,'cleanEncryptedFields');

        CDdAccountHelperMethods.setLanguage(newList, null);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_INSERT,cpuUsageAcctTriggerHandler,'setLanguage');

        CDdAccountHelperMethods.latinToKanjiMapping(newList);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_INSERT,cpuUsageAcctTriggerHandler,'latinToKanjiMapping');

        CDdAccountHelperMethods.populateBankAccountPrefix(newList, null);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_INSERT,cpuUsageAcctTriggerHandler,'populateBankAccountPrefix');

        CDdAccountHelperMethods.setBusinessVerticalDetails(newList, null);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_INSERT,cpuUsageAcctTriggerHandler,'setBusinessVerticalDetails');

        CDdAccountHelperMethods.handlePostSaleAccountOwnershipRejected(newList, null);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_INSERT,cpuUsageAcctTriggerHandler,'handlePostSaleAccountOwnershipRejected');

        CDdAccountHelperMethods.updateHubspotMerchantCategories(newList, null);

        CDdAccountHelperMethods.updateInternationalPhoneNumbers(newList, null);
        CDdAccountHelperMethods.setDefaultValuesByCountry(newList);
        CDdAccountHelperMethods.populateDeckRankIfBlank(newList);
        CDdAccountHelperMethods.formatPhoneNumber(newList);

        CDdAccountHelperMethods.syncPrimaryMerchantCategoryFields(newList, null);
        CDdAccountHelperMethods.updateMuelsoftExtId(newList);
        CDdUtilities.logCpuUsage(BEFORE_INSERT,cpuUsageAcctTriggerHandler,'End');
    }

    public void beforeUpdate(Map<Id,Account> newMap, Map<Id,Account> oldMap) {
        cpuUsageAcctTriggerHandler = 0;
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_UPDATE,cpuUsageAcctTriggerHandler,'Start');

        CDdAccountHelperMethods.detectDuplicateFlagAndCopySensitiveInfo(newMap.values(), oldMap);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_UPDATE,cpuUsageAcctTriggerHandler,'detectDuplicateFlagAndCopySensitiveInfo');

        CDdAccountHelperMethods.latinToKanjiMappingBeforeUpdate(newMap.values(),oldmap);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_UPDATE,cpuUsageAcctTriggerHandler,'latinToKanjiMappingBeforeUpdate');

        CDdAccountHelperMethods.handleSpecialCharsOnAddressChange(newMap.values(),oldmap);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_UPDATE,cpuUsageAcctTriggerHandler,'handleSpecialCharsOnAddressChange');

        CDdAccountHelperMethods.updateADR(newMap.values(),oldMap);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_UPDATE,cpuUsageAcctTriggerHandler,'updateADR');

        CDdAccountHelperMethods.populateTerritory(newMap.values(),oldMap,false);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_UPDATE,cpuUsageAcctTriggerHandler,'populateTerritory');

        CDdAccountHelperMethods.updateAcctsWithParentAcctInformation(newMap.values(),oldMap,false);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_UPDATE,cpuUsageAcctTriggerHandler,'updateAcctsWithParentAcctInformation');

        CDdAccountHelperMethods.matchMissingParentAccount(newMap.values());
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_UPDATE,cpuUsageAcctTriggerHandler,'matchMissingParentAccount');

        CDdAccountHelperMethods.populatePreviousOwner(newMap.values(), oldMap);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_UPDATE,cpuUsageAcctTriggerHandler,'populatePreviousOwner');

        CDdAccountHelperMethods.updateDeckRankOnParentAccounts(newMap.values(), oldMap);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_UPDATE,cpuUsageAcctTriggerHandler,'updateDeckRankOnParentAccounts');

        CDdAccountHelperMethods.DxMarketingCase(newMap.values(), oldMap);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_UPDATE,cpuUsageAcctTriggerHandler,'DxMarketingCase');

        CDdAccountHelperMethods.copyAccountOwnerToOpportunity(newMap.values(), oldMap);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_UPDATE,cpuUsageAcctTriggerHandler,'copyAccountOwnerToOpportunity');

        CDdAccountHelperMethods.createLeadOnLeadCreationApproval(newMap.values(), oldMap);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_UPDATE,cpuUsageAcctTriggerHandler,'createLeadOnLeadCreationApproval');

        CDdAccountHelperMethods.cleanEncryptedFields(newMap.values(), oldMap);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_UPDATE,cpuUsageAcctTriggerHandler,'cleanEncryptedFields');

        CDdAccountHelperMethods.setLanguage(newMap.values(), oldMap);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_UPDATE,cpuUsageAcctTriggerHandler,'setLanguage');

        CDdAccountHelperMethods.updateHubspotMerchantCategories(newMap.values(), oldMap);

        CDdAccountHelperMethods.syncPrimaryMerchantCategoryFields(newMap.values(), oldMap);

        CDdAccountHelperMethods.handleMerchantCategories(newMap.values(), oldMap);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_UPDATE,cpuUsageAcctTriggerHandler,'handleMerchantCategories');

        CDdAccountHelperMethods.populateBankAccountPrefix(newMap.values(), oldMap);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_UPDATE,cpuUsageAcctTriggerHandler,'populateBankAccountPrefix');

        CDdAccountHelperMethods.setBusinessVerticalDetails(newMap.values(), oldMap);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_UPDATE,cpuUsageAcctTriggerHandler,'setBusinessVerticalDetails');

        CDdAccountHelperMethods.handlePostSaleAccountOwnerApprovalProcess(newMap.values(), oldMap);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_UPDATE,cpuUsageAcctTriggerHandler,'handlePostSaleAccountOwnerApprovalProcess');

        CDdAccountHelperMethods.handlePostSaleAccountOwnershipRejected(newMap.values(), oldMap);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_UPDATE,cpuUsageAcctTriggerHandler,'handlePostSaleAccountOwnershipRejected');

        CDdAccountHelperMethods.updateInternationalPhoneNumbers(newMap.values(), oldMap);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_UPDATE,cpuUsageAcctTriggerHandler,'updateInternationalPhoneNumbers');

    	if(!featureFlag.Disable_Enrichment_Queueable__c){
            CDdAccountHelperMethods.handleAccountChdId(newMap, oldMap);
            cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_UPDATE,cpuUsageAcctTriggerHandler,'handleAccountChdId');
        }

        // GDPR Email CMS
        CDdGDPRCreateContactHelper.treatChangedEmailAudit(newMap.values(),oldMap);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_UPDATE,cpuUsageAcctTriggerHandler,'treatChangedEmailAudit');

        CDdUtilities.logCpuUsage(BEFORE_UPDATE,cpuUsageAcctTriggerHandler,'End');

        CDdAccountHelperMethods.updateMuelsoftExtId(newMap.values());
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(BEFORE_UPDATE,cpuUsageAcctTriggerHandler,'updateMuelsoftExtId');

    }

    public void afterInsert(Map<id,Account> newMap) {
        List<Account> newList = newMap.values();
        cpuUsageAcctTriggerHandler = 0;
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(AFTER_INSERT,cpuUsageAcctTriggerHandler,'Start');

        // NOTE: There is a flaw in ACCT_TRIGGER_RUN_ONCE because nothing gets called in this path after the return check

        CDdAccountHelperMethods.doAccountRollups(newList, null, false);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(AFTER_INSERT,cpuUsageAcctTriggerHandler,'doAccountRollups');

        if (ACCT_TRIGGER_RUN_ONCE) return;
            ACCT_TRIGGER_RUN_ONCE = true;

        CDdAccountHelperMethods.DxMarketingCase(newList, null);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(AFTER_INSERT,cpuUsageAcctTriggerHandler,'DxMarketingCase');

        CDdAccountHelperMethods.copyAccountOwnerToOpportunity(newList, null);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(AFTER_INSERT,cpuUsageAcctTriggerHandler,'copyAccountOwnerToOpportunity');

        CDdAccountHelperMethods.updateOppAmount(newList, null);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(AFTER_INSERT,cpuUsageAcctTriggerHandler,'updateOppAmount');

        CDdAccountHelperMethods.checkAccountCoverage(newList);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(AFTER_INSERT,cpuUsageAcctTriggerHandler,'checkAccountCoverage');

        CDdAccountHelperMethods.handleMerchantCategories(newList, null);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(AFTER_INSERT,cpuUsageAcctTriggerHandler,'handleMerchantCategories');

        CDdAccountHelperMethods.setUltimateParentAfterInsert(newList);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(AFTER_INSERT,cpuUsageAcctTriggerHandler,'setUltimateParentAfterInsert');

        CDdAccountHelperMethods.setupCatalogMilestoneForBusinessVerticalRetail(newList, null);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(AFTER_INSERT,cpuUsageAcctTriggerHandler,'setupCatalogMilestoneForBusinessVerticalRetail');

        CDdAccountHelperMethods.updateChildAcctsInformationAfterInsert(newList);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(AFTER_INSERT,cpuUsageAcctTriggerHandler,'updateChildAcctsInformationAfterInsert');

        if(!featureFlag.Disable_Enrichment_Queueable__c){
            CDdAccountHelperMethods.handleAccountChdId(newMap, null);
            cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(AFTER_INSERT,cpuUsageAcctTriggerHandler,'handleAccountChdId');
        }

        CDdMxSxTriggerHelper.processAccounts(newList, null);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(AFTER_INSERT,cpuUsageAcctTriggerHandler,'processAccounts');

         // GDPR Email CMS
         CDdGDPRCreateContactHelper.createGDPREmailCreateContactEvent(Trigger.New,null);
         cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(AFTER_INSERT,cpuUsageAcctTriggerHandler,'createGDPREmailCreateContactEvent');

         CDdUtilities.logCpuUsage(AFTER_INSERT,cpuUsageAcctTriggerHandler,'End');
    }

    public void afterUpdate(Map<Id, Account> newMap, Map<Id, Account> oldMap){
        cpuUsageAcctTriggerHandler = 0;
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(AFTER_UPDATE,cpuUsageAcctTriggerHandler,'Start');

        CDdAccountHelperMethods.setActivationDateOnOpps(newMap,oldMap);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(AFTER_UPDATE,cpuUsageAcctTriggerHandler,'setActivationDateOnOpps');

        CDdAccountHelperMethods.updateChildAcctsInformation(newMap,oldMap);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(AFTER_UPDATE,cpuUsageAcctTriggerHandler,'updateChildAcctsInformation');

        CDdAccountHelperMethods.copyFieldsToContact(newMap, oldMap);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(AFTER_UPDATE,cpuUsageAcctTriggerHandler,'copyFieldsToContact');

        CDdAccountHelperMethods.updateOppAmount(newMap.values(), oldMap);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(AFTER_UPDATE,cpuUsageAcctTriggerHandler,'updateOppAmount');

        CDdAccountHelperMethods.updateTaskCount(newMap, oldMap);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(AFTER_UPDATE,cpuUsageAcctTriggerHandler,'updateTaskCount');

        CDdAccountHelperMethods.doAccountRollups(newMap.values(), oldMap, false);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(AFTER_UPDATE,cpuUsageAcctTriggerHandler,'doAccountRollups');

        CDdAccountHelperMethods.updateTopMxHighAov(newMap, oldMap);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(AFTER_UPDATE,cpuUsageAcctTriggerHandler,'updateTopMxHighAov');

        CDdAccountHelperMethods.setUltimateParentAfterUpdate(newMap, oldMap);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(AFTER_UPDATE,cpuUsageAcctTriggerHandler,'setUltimateParentAfterUpdate');

        CDdAccountHelperMethods.setupCatalogMilestoneForBusinessVerticalRetail(newMap.values(), oldMap);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(AFTER_UPDATE,cpuUsageAcctTriggerHandler,'setupCatalogMilestoneForBusinessVerticalRetail');

        CDdMxSxTriggerHelper.processAccounts(newMap.values(), oldMap);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(AFTER_UPDATE,cpuUsageAcctTriggerHandler,'processAccounts');

        CDdAccountHelperMethods.updateLeadCreatedFromContact(newMap, oldMap);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(AFTER_UPDATE,cpuUsageAcctTriggerHandler,'updateLeadCreatedFromContact');

        // GDPR Email CMS
        CDdGDPRCreateContactHelper.createGDPREmailCreateContactEvent(Trigger.New,oldMap);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(AFTER_UPDATE,cpuUsageAcctTriggerHandler,'createGDPREmailCreateContactEvent');

        CDdUtilities.logCpuUsage(AFTER_UPDATE,cpuUsageAcctTriggerHandler,'End');
    }

    public void afterDeleteOrUndelete(List<Account> old) {
        cpuUsageAcctTriggerHandler = 0;
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(AFTER_DELETE,cpuUsageAcctTriggerHandler,'Start');

        CDdAccountHelperMethods.doAccountRollups(old, null, true);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(AFTER_DELETE,cpuUsageAcctTriggerHandler,'doAccountRollups');

        CDdAccountHelperMethods.handleMxCategoryMerge(old);
        cpuUsageAcctTriggerHandler = CDdUtilities.logCpuUsage(AFTER_DELETE,cpuUsageAcctTriggerHandler,'handleMxCategoryMerge');

        CDdUtilities.logCpuUsage(AFTER_DELETE,cpuUsageAcctTriggerHandler,'End');
    }
}