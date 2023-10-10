/**
* @author: edward.kim
* @date: 2016-06
* @description Trigger handler for Opportunity.
*/
public with sharing class CDdOpportunityTriggerHandler {
    public static final Boolean doCPUTimeCheck = CDdExperimentSvc.getCustomSettingFeatureFlag('Enable_CPU_Time_Check__c');
    public static final String BEFORE_INSERT = '><><><><>CDdOpportunityTriggerHandler.beforeInsert()';
    public static final String BEFORE_UPDATE = '><><><><>CDdOpportunityTriggerHandler.beforeUpdate()';
    public static final String AFTER_INSERT = '><><><><>CDdOpportunityTriggerHandler.afterInsert()';
    public static final String AFTER_UPDATE = '><><><><>CDdOpportunityTriggerHandler.afterUpdate()';
    public Static Integer cpuUsageOppTriggerHandler = 0;
    public Map<Id, Account> accMap = null;

    public CDdOpportunityTriggerHandler(List<Opportunity> newList) {
        //added by lalit to avoid exception in before delete.
        if(newList == null){
          return;
        }
        List<Id> accIds = new List<Id>();
        for (Opportunity opp : newList)
            if (opp.AccountId != null)
                accIds.add(opp.AccountId);
        accMap = new Map<Id, Account>([
            SELECT Id, Bank_Institution_Number_Encrypted__c, BillingCountryCode, BillingCountry, Business_ID__c,
                Amount__c, Deck_Rank__c, Launch_Deck_Rank__c, Formstack_Version__c, In_Coverage__c, RealZip__RealZip__c,
                ParentId, Parent.Requesting_Account_Management__c, Parent.Business_Vertical__c, DashPass_Eligibility_Override__c,
                Primary_Merchant_Category__c, Is_Test_Store__c, RecordTypeId, OwnerId,
                Store_Details__c, Store_Details__r.Caviar_Catering_Status__c, Store_Details__r.Contractual_Exclusivity_Status_Deliv__c,
                (   SELECT Type__c, Sub_Type__c, Merchant__c, File_URL__c, Document_ID__c
                    FROM Merchant_Documents__r
                )
            FROM Account
            WHERE Id =: accIds
        ]);
    }

    private void logCpuUsage(String triggerContext,String method) {
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage(triggerContext,(method.endsWith('= ') ? method : method + '= '),cpuUsageOppTriggerHandler,doCPUTimeCheck);
        if (method == 'End' || method == 'Start') {
            String msg = 'CPU: ' + Limits.getCpuTime() + CDdCoreConstants.DELIMITER_FORWARD_SLASH + Limits.getLimitCpuTime() + CDdCoreConstants.NEW_LINE +
                'Heap: ' + Limits.getHeapSize() + CDdCoreConstants.DELIMITER_FORWARD_SLASH + Limits.getLimitHeapSize() + CDdCoreConstants.NEW_LINE +
                'SOQL: ' + Limits.getQueries() + CDdCoreConstants.DELIMITER_FORWARD_SLASH + Limits.getLimitQueries() + CDdCoreConstants.NEW_LINE +
                'DML Row: ' + Limits.getDmlRows() + CDdCoreConstants.DELIMITER_FORWARD_SLASH + Limits.getLimitDmlRows() + CDdCoreConstants.NEW_LINE +
                'DML Statement: ' + Limits.getDmlStatements() + CDdCoreConstants.DELIMITER_FORWARD_SLASH + Limits.getDmlStatements();
            CDdUtilities.debug(LoggingLevel.WARN, triggerContext + ' LIMITS LOGGER ' + method + ' = ' + CDdCoreConstants.NEW_LINE + msg, true);
        }
    }

    Opportunity_Trigger_Helper_Settings__c helperSettings = Opportunity_Trigger_Helper_Settings__c.getInstance();
    public void beforeInsert(List<Opportunity> newList){
        cpuUsageOppTriggerHandler = 0;
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.beforeInsert()','Start= ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        if(!helperSettings.Disable_donotAllowCreationOfOpportunitie__c){
            CDdOpportunityTriggerHelper.donotAllowCreationOfOpportunities(newList);
        }
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.beforeInsert()','donotAllowCreationOfOpportunities END = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdOpportunityTriggerHelper.setDefaultValueOnMarketplaceOpps(newList);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.beforeInsert()','setDefaultValueOnMarketplaceOpps END= ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdOpportunityTriggerHelper.setDefaultPicklistValuesBasedOnCountry(newList);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.beforeInsert()','setDefaultPicklistValuesBasedOnCountry END = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdOpportunityTriggerHelper.matchOnFormstackStoreId(newList);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.beforeInsert()','matchOnFormstackStoreId END = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdOpportunityTriggerHelper.copyRequestAccountManagementToParentAccount(newList, accmap);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.beforeInsert()','copyRequestAccountManagementToParentAccount END = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdOpportunityTriggerHelper.stampPricingTierPackageOnClosedWon(newList, null, accMap);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.beforeInsert()','stampPricingTierPackageOnClosedWon END = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdOpportunityTriggerHelper.cwOppSetsDeliveryFee(newList, null);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.beforeInsert()','cwOppSetsDeliveryFee END = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdOpportunityTriggerHelper.formstackUpdateOrderProtocol(newList, accMap);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.beforeInsert()','formstackUpdateOrderProtocol END = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdOpportunityTriggerHelper.FormstackSSMOtrial(newList);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.beforeInsert()','FormstackSSMOtrial END = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdOpportunityTriggerHelper.ActivateCentrallyForEnterprise(newList, null, accMap);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.beforeInsert()','ActivateCentrallyForEnterprise END = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdOpportunityTriggerHelper.formstackCanadaContractType(newList, accMap);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.beforeInsert()','formstackCanadaContractType END = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdOpportunityTriggerHelper.setDashPassEligible(newList, null, accMap);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.beforeInsert()','setDashPassEligible END = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdOpporunityTriggerHelper_CPQ.populateLegalEntityOrCurrencyCode(newList, false,accMap);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.beforeInsert()','populateLegalEntityOrCurrencyCode END= ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdMxSxTriggerHelper.processOpportunities(newList, null, accMap);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.beforeInsert()','CDdMxSxTriggerHelper.processOpportunities END = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdOpportunityTriggerHelper.setBlankValueOnClonedDDFBOpp(newList);

        CDdOpportunityTriggerHelper.updateAlcoholAddendumSigned(newList, null);

        CDdOpportunityTriggerHelper.marketplaceUpdates(newList, null);
        logCpuUsage(BEFORE_INSERT,'marketplaceUpdates');


        //BZAP-12637
        CDdOpportunityTriggerHelper.setDefaultValueForNZByOrderProtocolForTabShipping(newList);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.beforeInsert()','setDefaultValueForNZByOrderProtocolForTabShipping END = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdOpportunityTriggerHelper.updateTabletDeliveryMethod(newList, null);
        logCpuUsage(BEFORE_INSERT,'updateTabletDeliveryMethod');

        CDdOpportunityTriggerHelper.updateNotesOnAccountOnChangeofOpportunityNotes(newList, null);
        logCpuUsage(BEFORE_INSERT,'updateNotesOnAccountOnChangeofOpportunityNotes');

        CDdOpportunityTriggerHelper.contractSignedAutoMoveToCloseWon(newList, null);
        logCpuUsage(BEFORE_INSERT,'contractSignedAutoMoveToCloseWon');

        CDdOpportunityTriggerHelper.populateCampaignNameOnOpportunity(newList, null);
        logCpuUsage(BEFORE_INSERT,'populateCampaignNameOnOpportunity');
    }

    public void beforeUpdate(List<Opportunity> newList, Map<Id,Opportunity> oldMap){
        if(CDdTaskTriggerHandler.isCountingTask || MassUpdater.isMassUpdating){
            return;
        }
        CDdOpportunityValidationHelper.validateClosedDriveOpportunities(newList,oldMap);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.beforeUpdate()','validateClosedDriveOpportunities = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdOpporunityTriggerHelper_CPQ.validateContractSignedOnClosedWon(newList);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.afterInsert()','validateContractSignedOnClosedWon END = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdOpportunityValidationHelper.validateOpportunitiesDoorDashForBusiness(newList);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.beforeUpdate()','validateOpportunitiesDoorDashForBusiness = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdOpportunityValidationHelper.validateCompletionOfStorefrontInfo(newList, oldMap);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.beforeUpdate()','validateCompletionOfStorefrontInfo = ', cpuUsageOppTriggerHandler, doCPUTimeCheck);

        CDdOpportunityTriggerHelper.copyRequestAccountManagementToParentAccount(newList, accMap);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.beforeUpdate()','copyRequestAccountManagementToParentAccount END = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdOpportunityTriggerHelper.stampPricingTierPackageOnClosedWon(newList, oldMap, accMap);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.beforeUpdate()','stampPricingTierPackageOnClosedWon END = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdOpportunityTriggerHelper.cwOppSetsDeliveryFee(newList, oldMap);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.beforeUpdate()','cwOppSetsDeliveryFee END = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdOpportunityTriggerHelper.ActivateCentrallyForEnterprise(newList, oldMap, accMap);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.beforeUpdate()','ActivateCentrallyForEnterprise END = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdOpportunityTriggerHelper.updateManager(newList, oldMap);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.beforeUpdate()','updateManager END = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdOpportunityTriggerHelper.concatenateMarketingUUID(newList, oldMap);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.beforeUpdate()','concatenateMarketingUUID END = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdOpportunityTriggerHelper.setDashPassEligible(newList, oldMap, accMap);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.beforeUpdate()','setDashPassEligible END = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdOpporunityTriggerHelper_CPQ.updateOpportunityStage(newList,oldMap);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.beforeUpdate()','updateOpportunityStage END = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdOpporunityTriggerHelper_CPQ.populateLegalEntityOrCurrencyCode(newList, true,accMap);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.beforeUpdate()','populateLegalEntityOrCurrencyCode END = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdMxSxTriggerHelper.processOpportunities(newList, oldMap, accMap);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.beforeUpdate()','CDdMxSxTriggerHelper.processOpportunities END = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdOpportunityTriggerHelper.updateAlcoholAddendumSigned(newList, oldMap);

        CDdOpportunityTriggerHelper.marketplaceUpdates(newList, oldMap);
        logCpuUsage(BEFORE_UPDATE,'marketplaceUpdates');


        //BZAP-12637
        CDdOpportunityTriggerHelper.setDefaultValueForNZByOrderProtocolForTabShipping(newList);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.beforeUpdate()','setDefaultValueForNZByOrderProtocolForTabShipping END = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdOpportunityTriggerHelper.updateTabletDeliveryMethod(newList, oldMap);
        logCpuUsage(BEFORE_UPDATE,'updateTabletDeliveryMethod');

        CDdOpportunityTriggerHelper.updateNotesOnAccountOnChangeofOpportunityNotes(newList, oldMap);
        logCpuUsage(BEFORE_UPDATE,'updateNotesOnAccountOnChangeofOpportunityNotes');

        CDdOpportunityTriggerHelper.validateCWLiquorLicenseCollectionTask(newList, oldMap);
        logCpuUsage(BEFORE_UPDATE,'validateCWLiquorLicenseCollectionTask');

        CDdOpportunityTriggerHelper.contractSignedAutoMoveToCloseWon(newList, oldMap);
        logCpuUsage(BEFORE_UPDATE,'contractSignedAutoMoveToCloseWon');

        CDdOpportunityTriggerHelper.validateBbotOpportunityOnContractCreation(newList, oldMap);
        logCpuUsage(BEFORE_UPDATE,'validateBbotOpportunityOnContractCreation');

        CDdOpportunityTriggerHelper.updateSQODateForPostSale(newList, oldMap);
        logCpuUsage(BEFORE_UPDATE,'updateSQODateForPostSale');

        CDdOpportunityTriggerHelper.populateCampaignNameOnOpportunity(newList, oldMap);
        logCpuUsage(BEFORE_UPDATE,'populateCampaignNameOnOpportunity');
    }

    public void afterInsert(List<Opportunity> newList) {
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.afterInsert()','Start = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdOpportunityTriggerHelper.processContactRole(newList,null);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.afterInsert()','processContactRole = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdOpportunityTriggerHelper.processFormStackOpportunities(newList);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.afterInsert()','processFormStackOpportunities = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdOpportunityTriggerHelper.FormstackRelatedUpdates(newList, null);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.afterInsert()','FormstackRelatedUpdates END = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdOpportunityTriggerHelper.setBusinessVerificationDocumentAttached(newList, null, accMap);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.afterInsert()','setBusinessVerificationDocumentAttached END = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdOpportunityTriggerHelper.formstackMcDsCanada(newList, null, accMap);
        logCpuUsage(AFTER_INSERT,'formstackMcDsCanada');

        CDdOpportunityTriggerHelper.accountMgmtStatusUpdate(newList, accMap);
        logCpuUsage(AFTER_INSERT,'accountMgmtStatusUpdate');

        CDdOpportunityCaseHelper.createCases(newList, null);    //  NOTE: This should be the last in chain because it performs a record lock
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.afterInsert()','createCases END = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdMxSxTriggerHelper.processOpportunities(newList, null, accMap);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.afterInsert()','CDdMxSxTriggerHelper.processOpportunities END = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdOpportunityTriggerHelper.createLiquorLicenseTask(newList, null, accMap);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.afterInsert()','CDdMxSxTriggerHelper.createLiquorLicenseTask END = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdOpportunityTriggerHelper.createPreSaleImplementationRequest(newList, null);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.afterInsert()','createPreSaleImplementationRequest END = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);
    }

    public void afterUpdate(List<Opportunity> newList, Map<Id,Opportunity> oldMap){
        if(CDdTaskTriggerHandler.isCountingTask || MassUpdater.isMassUpdating){
            return;
        }
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.afterUpdate()','Start = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        if(Test.isRunningTest() || !CDdCustomMetaData.isDisabled('Invoice_Feature')){
            CDdOpportunityTriggerHelper.createNetSuiteAccount(newList,oldMap);
            cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.afterUpdate()','createNetSuiteAccount = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);
        }

        CDdOpportunityTriggerHelper.processContactRole(newList,oldMap);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.afterUpdate()','processContactRole = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdOpportunityTriggerHelper.createAssetsFromProducts(newList, oldMap);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.afterUpdate()','createAssetsFromProducts = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdOpportunityTriggerHelper.FormstackRelatedUpdates(newList, oldMap);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.afterUpdate()','FormstackRelatedUpdates END = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdOpportunityTriggerHelper.setBusinessVerificationDocumentAttached(newList, oldMap, accMap);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.afterUpdate()','setBusinessVerificationDocumentAttached END = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdOpportunityTriggerHelper.updateMOCaseAndMilestones(newList, oldMap);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.afterUpdate()','updateMOCaseAndMilestones END = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdOpportunityTriggerHelper.formstackMcDsCanada(newList, oldMap, accMap);
        logCpuUsage(AFTER_UPDATE,'formstackMcDsCanada');

        CDdOpportunityTriggerHelper.accountMgmtStatusUpdate(newList, accMap);
        logCpuUsage(AFTER_UPDATE,'accountMgmtStatusUpdate');

        CDdOpportunityCaseHelper.createCases(newList, oldMap);  //  NOTE: This should be the last in chain because it performs a record lock
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.afterUpdate()','createCases END = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        if(!CDdOpportunityTriggerHelper.ranCreateMilestonesPostOppClose){
            cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.afterUpdate()','ranCreateMilestonesPostOppClose = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);
            CDdOpportunityTriggerHelper.createMissingMilestonesPostOppClose(newList, oldMap);
            cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.afterUpdate()','createMilestonesPostOppClose END = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);
        }

        CDdOpporunityTriggerHelper_CPQ.updateOrderStartOnActivation(newList, oldMap);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.afterInsert()','updateOrderStartOnActivation END = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdOpporunityTriggerHelper_CPQ.updateAccountCustomPartnershipStatus(newList, oldMap);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.afterInsert()','updateAccountCustomPartnershipStatus END = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdOpportunityTriggerHelper.accountReparent(newList, oldMap, accMap);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.afterUpdate()','accountReparent END = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdMxSxTriggerHelper.processOpportunities(newList, oldMap, accMap);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.afterUpdate()','CDdMxSxTriggerHelper.processOpportunities END = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdOpportunityTriggerHelper.createLiquorLicenseTask(newList, oldMap, accMap);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.afterUpdate()','CDdMxSxTriggerHelper.createLiquorLicenseTask END = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdOpportunityTriggerHelper.processSSMOOpportunities(newList, oldMap);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.afterUpdate()','processSSMOOpportunities END = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdOpportunityTriggerHelper.sendEmailToSSMOOpportunityOwner(newList, oldMap);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.afterUpdate()','sendEmailToSSMOOpportunityOwner END = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdOpportunityTriggerHelper.createPreSaleImplementationRequest(newList, oldMap);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.afterUpdate()','createPreSaleImplementationRequest END = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);

        CDdOpportunityTriggerHelper.updatePaymentAccount(newList, oldMap);
        cpuUsageOppTriggerHandler = CDdUtilities.calculateCPUUsage('><><><><>CDdOpportunityTriggerHandler.afterUpdate()','CDdOpportunityTriggerHelper updatePaymentAccount = ',cpuUsageOppTriggerHandler,doCPUTimeCheck);
    }
    /**
     *@ author : lalit
     *@purpose : Handle the before delete operation on opportunities
     *@params  : 1)List of Old opportunities
     *return   : -
     */
    public void beforeDelete(List<Opportunity> oldOpportunityList){
        CDdOpportunityTriggerHelper.validateOpportunityToDelete(oldOpportunityList);
    }
}