/**
 * @author: Raju Lakshman
 * @date: Dec 2021
 * @description Optimized Case Trigger Handler - Called from TDdCaseTrigger
 */

/*
 _     _    ___    _____   _____           ____    _       _____       __       ____    _____       ____    _____       __       ____
|  \  | |  / _ \  |_   _| |  ___|         |  _ \  | |     |  ___|     /  \     /  __|  |  ___|     |  _ \  |  ___|     /  \     |  _ \
|   \ | | | | | |   | |   | |_     _      | |_) | | |     | |_       / /\ \    | |__   | |_        | |_) | | |_       / /\ \    | | | |
| |\ \| | | | | |   | |   |  _|   (_)     |  __/  | |     |  _|     / /__\ \   \___ \  |  _|       |    /  |  _|     / /__\ \   | | | |
| | \   | | |_| |   | |   | |___   _      | |     | |___  | |___   /  ____  \   ___) | | |___      | |\ \  | |___   /  ____  \  | |_| |
|_|  \__|  \___/    |_|   |_____| (_)     |_|     |_____| |_____| /__/    \__\ |____/  |_____|     |_| \_\ |_____| /__/    \__\ |____/

This class uses the Trigger Optimizations in conjunction with CDdCaseTriggerHelperV2 / CDdCaseTriggerOptimizationHelper.

Use the optimization code to
> Access related entities like accounts, opportunitnities, contacts
> Access queues
> Access record types
> Access the 'single dml per entity' framework

The Constructor calls CDdCaseTriggerOptimizationHelper to do a lot of the optimization heavy lifting, so as to avoid repeated queries within the trigger transaction.

Documentation for this can be found here: <TO DO>

>>>> To combine all queue queries into a single one, please add the queue names to the code in the constructor
>>>> Dont forget to use shouldRunMethod and logCpuUsage.

*/
public class CDdCaseTriggerHandlerV2 {
    public static final Boolean doDebug = CDdExperimentSvc.getCustomSettingFeatureFlag('Enable_Debug_Logs__c');
    public static final Boolean doCPUTimeCheck = CDdExperimentSvc.getCustomSettingFeatureFlag('Enable_CPU_Time_Check__c');
    public static final Boolean doHeapSizeCheck = CDdExperimentSvc.getCustomSettingFeatureFlag('Enable_Heap_Size_Check__c');
    public static final String BEFORE_INSERT = '><><><><>CDdCaseTriggerHandlerV2.beforeInsert()';
    public static final String BEFORE_UPDATE = '><><><><>CDdCaseTriggerHandlerV2.beforeUpdate()';
    public static final String AFTER_INSERT = '><><><><>CDdCaseTriggerHandlerV2.afterInsert()';
    public static final String AFTER_UPDATE = '><><><><>CDdCaseTriggerHandlerV2.afterUpdate()';
    public static final String BEFORE_DELETE = '><><><><>CDdCaseTriggerHandlerV2.beforedelete()';
    public static Integer cpuUsageCaseTriggerHandler = 0;

    // Set to true, if its a Case Insert transaction.
    // Could be used in Shield etc frameworks to fire/bypass certain logic
    public static Boolean IS_CASE_INSERT = false;

    public Set<String> runMethods;
    public Boolean runAllMethods;

    public CDdCaseTriggerHandlerV2(List<Case> newList) {

        CDdUtilities.debug(LoggingLevel.DEBUG,'CDdCaseTriggerHandlerV2.CDdCaseTriggerHandler()',doDebug);
        Map<Id,Case> oldMap = trigger.isUpdate ? (Map<Id,Case>)trigger.oldMap : null;
        Set<Id> caseIds = new Set<Id>();
        Set<Id> oppIds = new Set<Id>();
        Set<Id> accIds = new Set<Id>();
        Set<Id> userIds = new Set<Id>{
            UserInfo.getUserId()
        };
        Set<Id> conIds = new Set<Id>();
        Set<Id> queueIds = new Set<Id>();

        List<String> queueNames = new List<String> {
            CDdCaseTriggerHelperV2.QUEUE_MENU_READY_FOR_QA,
            CDdCaseTriggerHelperV2.QUEUE_MENU_VENDOR_ALLOCATION,
            CDdCaseTriggerHelperV2.QUEUE_NEW_PARTNER_ESCALATIONS,
            CDdCaseTriggerHelperV2.QUEUE_SSME_PENDING,
            CDdCaseTriggerHelperV2.QUEUE_TRAINING_SUPPORT,
            CDdCaseTriggerHelperV2.QUEUE_CAVIAR_ONBOARDING,
            CDdCaseTriggerHelperV2.QUEUE_POS_INTEGRATION,
            CDdCaseTriggerHelperV2.QUEUE_POS_INTEGRATION_ENTERPRISE,
            CDdCaseTriggerHelperV2.QUEUE_PM_QUEUE,
            CDdCaseTriggerHelperV2.QUEUE_SPM_POST_SALE,
            CDdCaseTriggerHelperV2.QUEUE_TOKYO_ESCALATIONS,
            CDdCaseTriggerHelperV2.QUEUE_SF_DASHER,
            CDdCaseTriggerHelperV2.QUEUE_CDMX_DASHER,
            CDdSupportConstants.QUEUE_DEVNAME_MXP_FALLBACK,
            CDdCaseTriggerHelperV2.QUEUE_SOCIAL_VIP,
            CDdCaseTriggerHelperV2.QUEUE_TIER_3_SOCIAL,
            CDdCaseTriggerHelperV2.QUEUE_SOCIAL_INSTAGRAM_POST,
            CDdCaseTriggerHelperV2.QUEUE_SOCIAL_FACEBOOK_DM,
            CDdCaseTriggerHelperV2.QUEUE_SOCIAL_FACEBOOK_POST,
            CDdCaseTriggerHelperV2.QUEUE_SOCIAL_TWITTER_DM,
            CDdCaseTriggerHelperV2.QUEUE_SOCIAL_TWITTER_POST,
            CDdCaseTriggerHelperV2.QUEUE_HIBERNATED_POS_PROVIDERS,
            CDdCaseTriggerHelperV2.QUEUE_SUSPENDED_POS_PROVIDERS,
            CDdSupportConstants.QUEUE_P0_SPANISH_TRUST_AND_SAFETY,
            CDdSupportConstants.QUEUE_P0_TRUST_AND_SAFETY,
            CDdSupportConstants.QUEUE_P1_SPANISH_TRUST_AND_SAFETY,
            CDdSupportConstants.QUEUE_P1_TRUST_AND_SAFETY,
            CDdSupportConstants.QUEUE_P2_SPANISH_TRUST_AND_SAFETY,
            CDdSupportConstants.QUEUE_P2_TRUST_AND_SAFETY,
            CDdSupportConstants.QUEUE_M_ESCALATIONS,
            CDdSupportConstants.QUEUE_M_ESCALATIONS_JAPAN
        };

        // new list can be null for Beofre Delete trigger.
        // do not run the logic below if it is null.
        if(newList!= null) {
            for (Case cse : newList){
                if (cse.Id != null) {
                    caseIds.add(cse.Id);
                }
                if (cse.Opportunity_Name__c != null){
                    oppIds.add(cse.Opportunity_Name__c);
                }
                if (cse.AccountId != null){
                    accIds.add(cse.AccountId);
                }
                if (cse.Requester__c != null){
                    userIds.add(cse.Requester__c);
                }
                if (cse.OwnerId != null) {
                    if (String.valueOf(cse.OwnerId).startsWith('005')) {
                        userIds.add(cse.OwnerId);
                    } else {
                        queueIds.add(cse.OwnerId);
                    }
                }
                if (cse.Previous_Queue_ID__c != null) {
                    queueIds.add(cse.Previous_Queue_ID__c);
                }
                if (String.isNotBlank(cse.Previous_Queue__c)) {
                    queueNames.add(cse.Previous_Queue__c);
                }
                if (cse.ContactId != null){
                    conIds.add(cse.ContactId);
                }
                if (oldMap != null) {
                    Case oldCase = oldMap.get(cse.Id);
                    if (oldCase.OwnerId != null) {
                        if (String.valueOf(oldCase.OwnerId).startsWith('005')) {
                            userIds.add(oldCase.OwnerId);
                        } else {
                            queueIds.add(oldCase.OwnerId);
                        }
                    }
                    if (oldCase.Previous_Queue_ID__c != null) {
                        queueIds.add(oldCase.Previous_Queue_ID__c);
                    }
                    if (String.isNotBlank(oldCase.Previous_Queue__c)) {
                        queueNames.add(oldCase.Previous_Queue__c);
                    }
                }
            }

            // This keeps the opptunity/account/user/contact cache updated, but adds a soql to the txn for every trigger context (before/after etc)
            // Keeping this here as commented, looking at optimizing other ways.
            // CDdCaseTriggerOptimizationHelper.setCaseMap(caseIds);
            CDdCaseTriggerOptimizationHelper.setOpportunityMap(oppIds);
            CDdCaseTriggerOptimizationHelper.setAccountMap(accIds);
            CDdCaseTriggerOptimizationHelper.setUserMap(userIds);
            CDdCaseTriggerOptimizationHelper.setContactMap(conIds);

            queueNames.addAll(CDdOCUSAPIConstants.queueDeveloperNames);
            String dasherEscalationQueue = CDdNameValuePairHelper.getTextValue(CDdNameValuePairConstants.CASE_TRIGGER_VALIDATE_DASHER_ESCALATION_QUEUE);
            if (String.isNotBlank(dasherEscalationQueue)) {
                queueNames.addAll(dasherEscalationQueue.split(CDdCoreConstants.DELIMITER_SEMICOLON));
            }

            CDdGenericTriggerOptimizationHelper.setQueueMap(queueNames,queueIds);

        } // END: if(newList!= null) {
        runMethods = CDdTriggerBypassSettings.getExecutedMethods('Case');
        runAllMethods = (runMethods.size() == 0);
    }

    private void logCpuUsage(String triggerContext,String method) {
        cpuUsageCaseTriggerHandler = CDdUtilities.calculateCPUUsage(triggerContext,(method.endsWith('= ') ? method : method + '= '),cpuUsageCaseTriggerHandler,doCPUTimeCheck);
        if (method == 'End' || method == 'Start') {
            String heapSizeCheckMsg = doHeapSizeCheck ? 'Heap: ' + Limits.getHeapSize() + CDdCoreConstants.DELIMITER_FORWARD_SLASH + Limits.getLimitHeapSize()
                                        + CDdCoreConstants.NEW_LINE : '';
            String msg = 'CPU: ' + Limits.getCpuTime() + CDdCoreConstants.DELIMITER_FORWARD_SLASH + Limits.getLimitCpuTime() + CDdCoreConstants.NEW_LINE + heapSizeCheckMsg +
                'SOQL: ' + Limits.getQueries() + CDdCoreConstants.DELIMITER_FORWARD_SLASH + Limits.getLimitQueries() + CDdCoreConstants.NEW_LINE +
                'DML Row: ' + Limits.getDmlRows() + CDdCoreConstants.DELIMITER_FORWARD_SLASH + Limits.getLimitDmlRows() + CDdCoreConstants.NEW_LINE +
                'DML Statement: ' + Limits.getDmlStatements() + CDdCoreConstants.DELIMITER_FORWARD_SLASH + Limits.getDmlStatements();
            CDdUtilities.debug(LoggingLevel.WARN, triggerContext + ' LIMITS LOGGER ' + method + ' = ' + CDdCoreConstants.NEW_LINE + msg, true);
        }
    }

    private boolean shouldRunMethod(String methodName) {
        return (runAllMethods || runMethods.contains(methodName));
    }

    public void beforeInsert(List<Case> newList, System.TriggerOperation operationType){
        cpuUsageCaseTriggerHandler = 0;
        logCpuUsage(BEFORE_INSERT,'Start');
        IS_CASE_INSERT = true;

        if (shouldRunMethod('processStopSpamCase')){
            CDdCaseTriggerHelperV2.processStopSpamCase(trigger.new);
            logCpuUsage(BEFORE_INSERT,'processStopSpamCase');
        }
        if (shouldRunMethod('dispatchIfResponseIsPopulated')){
            CDdCaseTriggerHelperV2.dispatchIfResponseIsPopulated(newList);
            logCpuUsage(BEFORE_INSERT,'dispatchIfResponseIsPopulated');
        }
        if (shouldRunMethod('setAccountId')){
            CDdCaseTriggerHelperV2.setAccountId(newList, null);
            logCpuUsage(BEFORE_INSERT,'setAccountId');
        }
        // new methods, add to custom setting
        if (shouldRunMethod('addPersonAccounts')){
            CDdCaseTriggerHelperV2.addPersonAccounts(newList);
            logCpuUsage(BEFORE_INSERT,'addPersonAccounts');
        }
        if (shouldRunMethod('populateDateTimeCaseBecameWorkable')){
            CDdCaseTriggerHelperV2.populateDateTimeCaseBecameWorkable(newList, null);
            logCpuUsage(BEFORE_INSERT,'populateDateTimeCaseBecameWorkable');
        }
        if (shouldRunMethod('updateTabletDeliveredOnOpp')){
            CDdCaseTriggerHelperV2.updateTabletDeliveredOnOpp(newList, null);
            logCpuUsage(BEFORE_INSERT,'updateTabletDeliveredOnOpp');
        }
        if (shouldRunMethod('includeMarketingKitTabletRequest')){
            CDdCaseTriggerHelperV2.includeMarketingKitTabletRequest(newList);
            logCpuUsage(BEFORE_INSERT,'includeMarketingKitTabletRequest');
        }

        if (shouldRunMethod('generalCaseUpdates')){
            CDdCaseTriggerHelperV2.generalCaseUpdates(newList, null);
            logCpuUsage(BEFORE_INSERT,'generalCaseUpdates');
        }
        if (shouldRunMethod('updateCasesFromSupportFormMxPortal')){
            CDdCaseTriggerHelperV2.updateCasesFromSupportFormMxPortal(newList);
            logCpuUsage(BEFORE_INSERT,'updateCasesFromSupportFormMxPortal');
        }
        if (shouldRunMethod('updateAccountOwnerFromHandoffCases')){
            CDdCaseTriggerHelperV2.updateAccountOwnerFromHandoffCases(newList, null);
            logCpuUsage(BEFORE_INSERT,'updateAccountOwnerFromHandoffCases');
        }
        if (shouldRunMethod('fillSubjectCaviarChat')){
            CDdCaseTriggerHelperV2.fillSubjectCaviarChat(newList);
            logCpuUsage(BEFORE_INSERT,'fillSubjectCaviarChat');
        }
        if (shouldRunMethod('fillContactOnCase')){
            CDdCaseTriggerHelperV2.fillContactOnCase(newList, null);
            logCpuUsage(BEFORE_INSERT,'fillContactOnCase');
        }
        if (shouldRunMethod('caviarCaseCreationFlow')){
            CDdCaseTriggerHelperV2.caviarCaseCreationFlow(newList,null);
            logCpuUsage(BEFORE_INSERT,'caviarCaseCreationFlow');
        }
        if (shouldRunMethod('populateRecommendedKBArticles')){
            CDdCaseTriggerHelperV2.populateRecommendedKBArticles(newList,null);
            logCpuUsage(BEFORE_INSERT,'populateRecommendedKBArticles');
        }
        if (shouldRunMethod('updatePOSIntegrationsGoLiveDate')){
            CDdCaseTriggerHelperV2.updatePOSIntegrationsGoLiveDate(trigger.new);
            logCpuUsage(BEFORE_INSERT,'updatePOSIntegrationsGoLiveDate');
        }
        if (shouldRunMethod('populateDecisionMakerEmail')){
            CDdCaseTriggerHelperV2.populateDecisionMakerEmail(trigger.new, null);
            logCpuUsage(BEFORE_INSERT,'populateDecisionMakerEmail');
        }
        if (shouldRunMethod('setCaseOwner')){
            CDdCaseTriggerHelperV2.setCaseOwner(newList,operationType);
            logCpuUsage(BEFORE_INSERT,'setCaseOwner');
        }
        if (shouldRunMethod('requeryQueueInformation')){
            CDdCaseTriggerHelperV2.requeryQueueInformation(newList);
            logCpuUsage(BEFORE_INSERT,'requeryQueueInformation');
        }
        if (shouldRunMethod('postInternalChatterFeedBeforeInsert')){
            CDdCaseTriggerHelperV2.postInternalChatterFeedBeforeInsert(newList);
            logCpuUsage(BEFORE_INSERT,'postInternalChatterFeedBeforeInsert');
        }
        if (shouldRunMethod('setTrainingCaseOwner')){
            CDdCaseTriggerHelperV2.setTrainingCaseOwner(newList);
            logCpuUsage(BEFORE_INSERT,'setTrainingCaseOwner');
        }
        if (shouldRunMethod('processMxMarketingCase')){
            CDdCaseTriggerHelperV2.processMxMarketingCase(newList);
            logCpuUsage(BEFORE_INSERT,'processMxMarketingCase');
        }
        if (shouldRunMethod('caseSubjectAutomation')){
            CDdCaseTriggerHelperV2.caseSubjectAutomation(newList,null);
            logCpuUsage(BEFORE_INSERT,'caseSubjectAutomation');
        }
        if (shouldRunMethod('caseReopenedDate')){
            CDdCaseTriggerHelperV2.caseReopenedDate(newList,null);
            logCpuUsage(BEFORE_INSERT,'caseReopenedDate');
        }
        if (shouldRunMethod('updateContactId')){
            CDdCaseTriggerHelperV2.updateContactId(newList,null);
            logCpuUsage(BEFORE_INSERT,'updateContactId');
        }
        if (shouldRunMethod('mxpE2CAttachContact')){
            CDdCaseTriggerHelperV2.mxpE2CAttachContact(newList);
            logCpuUsage(BEFORE_INSERT,'mxpE2CAttachContact');
        }
        if (shouldRunMethod('associatePartnerIntegrationRecord')){
            CDdCaseTriggerHelperV2.associatePartnerIntegrationRecord(newList,null);
            logCpuUsage(BEFORE_INSERT,'associatePartnerIntegrationRecord');
        }
        if (shouldRunMethod('populateDefaultValues')){
            CDdCaseTriggerHelperV2.populateDefaultValues(newList, null);
            logCpuUsage(BEFORE_INSERT,'populateDefaultValues');
        }
        if (shouldRunMethod('ownedCaseToOpen')){
            CDdCaseTriggerHelperV2.ownedCaseToOpen(newList, null);
            logCpuUsage(BEFORE_INSERT,'ownedCaseToOpen');
        }
        if (shouldRunMethod('processCaseTouchCount')){
            CDdCaseTriggerHelperV2.processCaseTouchCount(newList, null);
            logCpuUsage(BEFORE_INSERT,'processCaseTouchCount');
        }
        if (shouldRunMethod('caseClaimedAt')){
            CDdCaseTriggerHelperV2.caseClaimedAt(newList, null);
            logCpuUsage(BEFORE_INSERT,'caseClaimedAt');
        }
        if (shouldRunMethod('handleOffenders')){
            CDdCaseTriggerHelperV2.handleOffenders(newList);
            logCpuUsage(BEFORE_INSERT,'handleOffenders');
        }
        if(shouldRunMethod('setCaseOwnerBasedOnHibernatedOrSuspended')){
            CDdCaseTriggerHelperV2.setCaseOwnerBasedOnHibernatedOrSuspended(newList, null);
            logCpuUsage(BEFORE_INSERT,'setCaseOwnerBasedOnHibernatedOrSuspended');
        }
        if (shouldRunMethod('executeWorkflows')){
            CDdWorkflowConfigEvaluator.executeWorkflows(newList, null);
            logCpuUsage(BEFORE_INSERT,'executeWorkflows');
        }
        if (shouldRunMethod('validateOCUSPhotoshootData')){
            CDdCaseTriggerHelperV2.validateOCUSPhotoshootData(newList, null);
            logCpuUsage(BEFORE_INSERT,'validateOCUSPhotoshootData');
        }
        if (shouldRunMethod('setCaseStatusToClosed')){
            CDdCaseTriggerHelperV2.setCaseStatusToClosed(newList, null);
            logCpuUsage(BEFORE_INSERT,'setCaseStatusToClosed');
        }
        if (shouldRunMethod('processBackToQueue')){
            CDdCaseTriggerHelperV2.processBackToQueue(newList);
            logCpuUsage(BEFORE_INSERT,'processBackToQueue');
        }

        logCpuUsage(BEFORE_INSERT,'End');
    }

    public void beforeUpdate(List<Case> newList, Map<Id, Case> oldMap, System.TriggerOperation operationType){
        cpuUsageCaseTriggerHandler = 0;
        logCpuUsage(BEFORE_UPDATE,'Start');

        if (shouldRunMethod('setAccountId')){
            CDdCaseTriggerHelperV2.setAccountId(newList, oldMap);
            logCpuUsage(BEFORE_UPDATE,'setAccountId');
        }
        if (shouldRunMethod('populateDateTimeCaseBecameWorkable')){
            CDdCaseTriggerHelperV2.populateDateTimeCaseBecameWorkable(newList, oldMap);
            logCpuUsage(BEFORE_UPDATE,'populateDateTimeCaseBecameWorkable');
        }
        if (shouldRunMethod('updateTabletDeliveredOnOpp')){
            CDdCaseTriggerHelperV2.updateTabletDeliveredOnOpp(newList, oldMap);
            logCpuUsage(BEFORE_UPDATE,'updateTabletDeliveredOnOpp');
        }
        if (shouldRunMethod('generalCaseUpdates')){
            CDdCaseTriggerHelperV2.generalCaseUpdates(newList, oldMap);
            logCpuUsage(BEFORE_UPDATE,'generalCaseUpdates');
        }
        if (shouldRunMethod('updateAccountOwnerFromHandoffCases')){
            CDdCaseTriggerHelperV2.updateAccountOwnerFromHandoffCases(newList, oldMap);
            logCpuUsage(BEFORE_UPDATE,'updateAccountOwnerFromHandoffCases');
        }
        if (shouldRunMethod('fillSubjectCaviarChat')){
            CDdCaseTriggerHelperV2.fillSubjectCaviarChat(newList);
            logCpuUsage(BEFORE_UPDATE,'fillSubjectCaviarChat');
        }
        if (shouldRunMethod('fillContactOnCase')){
            CDdCaseTriggerHelperV2.fillContactOnCase(newList, oldMap);
            logCpuUsage(BEFORE_UPDATE,'fillContactOnCase');
        }
        if (shouldRunMethod('caviarOnboarding')){
            CDdCaseTriggerHelperV2.caviarOnboarding(newList,oldMap);
            logCpuUsage(BEFORE_UPDATE,'caviarOnboarding');
        }
        if (shouldRunMethod('caviarCaseCreationFlow')){
            CDdCaseTriggerHelperV2.caviarCaseCreationFlow(newList,oldMap);
            logCpuUsage(BEFORE_UPDATE,'caviarCaseCreationFlow');
        }
        if (shouldRunMethod('populateRecommendedKBArticles')){
            CDdCaseTriggerHelperV2.populateRecommendedKBArticles(newList,oldMap);
            logCpuUsage(BEFORE_UPDATE,'populateRecommendedKBArticles');
        }
        if (shouldRunMethod('updateCaseStatus')){
            CDdCaseTriggerHelperV2.updateCaseStatus(trigger.new, oldMap);
            logCpuUsage(BEFORE_UPDATE,'updateCaseStatus');
        }
        if (shouldRunMethod('populateDecisionMakerEmail')){
            CDdCaseTriggerHelperV2.populateDecisionMakerEmail(trigger.new, oldMap);
            logCpuUsage(BEFORE_UPDATE,'populateDecisionMakerEmail');
        }
        if (shouldRunMethod('updatePOSIntegrationsRecordType')){
            CDdCaseTriggerHelperV2.updatePOSIntegrationsRecordType(trigger.new, oldMap);
            logCpuUsage(BEFORE_UPDATE,'updatePOSIntegrationsRecordType');
        }
        if (shouldRunMethod('setEntitlements')){
            CDdCaseTriggerHelperV2.setEntitlements(trigger.new, oldMap);
            logCpuUsage(BEFORE_UPDATE,'setEntitlements');
        }
        if (shouldRunMethod('setInitialStage')){
            if (!CDdCustomMetadata.isDisabled('CDdOpportunityCaseHelper_marketplaceOnbo')) {
                CDdCaseMilestone milestone = new CDdCaseMilestone();
                milestone.setInitialStage(Trigger.newMap, Trigger.oldMap);
                logCpuUsage(BEFORE_UPDATE,'setInitialStage');
            }
        }
        if (shouldRunMethod('caseClaimedAt')){
            CDdCaseTriggerHelperV2.caseClaimedAt(newList, oldMap);
            logCpuUsage(BEFORE_UPDATE,'caseClaimedAt');
        }
        if (shouldRunMethod('automateCaseBlockedTime')){
            CDdCaseTriggerHelperV2.automateCaseBlockedTime(trigger.new, oldMap);
            logCpuUsage(BEFORE_UPDATE,'automateCaseBlockedTime');
        }
        if (shouldRunMethod('automateOnboardingKPIs')){
            CDdCaseTriggerHelperV2.automateOnboardingKPIs(trigger.new, oldMap);
            logCpuUsage(BEFORE_UPDATE,'automateOnboardingKPIs');
        }
        if (shouldRunMethod('setOwnership') && CDdRecursionUtils.isRunnable('CDdCaseTriggerHandler_setOwnership')){
            CDdCaseTriggerHelperV2.setOwnership(newList, oldMap);
            logCpuUsage(BEFORE_UPDATE,'setOwnership');
        }
        if (shouldRunMethod('checkValidEscOrTransfer')){
            CDdCaseTriggerHelperV2.checkValidEscOrTransfer(newList, oldMap);
            logCpuUsage(BEFORE_UPDATE,'checkValidEscOrTransfer');
        }
        if (shouldRunMethod('setDefaultEscalationQueue')){
            CDdCaseTriggerHelperV2.setDefaultEscalationQueue(newList, oldMap);
            logCpuUsage(BEFORE_UPDATE,'setDefaultEscalationQueue');
        }
        if(shouldRunMethod('setActualVendor')) {
            CDdCaseTriggerHelperV2.setActualVendor(newList, oldMap);
            logCpuUsage(BEFORE_UPDATE,'setActualVendor');
        }
        if (shouldRunMethod('postInternalChatterFeed')){
            CDdCaseTriggerHelperV2.postInternalChatterFeed(newList, operationType);
            logCpuUsage(BEFORE_UPDATE,'postInternalChatterFeed');
        }
        if (shouldRunMethod('processMxPEscalatedCases')){
            CDdCaseTriggerHelperV2.processMxPEscalatedCases(newList, oldMap);
            logCpuUsage(BEFORE_UPDATE,'processMxPEscalatedCases');
        }
        // new methods, add to custom setting
        if (shouldRunMethod('processMxMarketingCase')){
            CDdCaseTriggerHelperV2.processMxMarketingCase(newList);
            logCpuUsage(BEFORE_UPDATE,'processMxMarketingCase');
        }
        if (shouldRunMethod('processPersonAccountChange')){
            CDdCaseTriggerHelperV2.processPersonAccountChange(newList,oldMap);
            logCpuUsage(BEFORE_UPDATE,'processPersonAccountChange');
        }
        if (shouldRunMethod('caseSubjectAutomation')){
            CDdCaseTriggerHelperV2.caseSubjectAutomation(newList,oldMap);
            logCpuUsage(BEFORE_UPDATE,'caseSubjectAutomation');
        }
        if (shouldRunMethod('processBackToQueue')){
            CDdCaseTriggerHelperV2.processBackToQueue(newList);
            logCpuUsage(BEFORE_UPDATE,'processBackToQueue');
        }
        if (shouldRunMethod('processPreviousQueue')){
            CDdCaseTriggerHelperV2.processPreviousQueue(newList,oldMap);
            logCpuUsage(BEFORE_UPDATE,'processPreviousQueue');
        }
        if (shouldRunMethod('caseReopenedDate') && CDdRecursionUtils.isRunnable('CDdCaseTriggerHelper_caseReopenedDate')){
            CDdCaseTriggerHelperV2.caseReopenedDate(newList,oldMap);
            logCpuUsage(BEFORE_UPDATE,'caseReopenedDate');
        }
        if (shouldRunMethod('updateContactId')){
            CDdCaseTriggerHelperV2.updateContactId(newList,oldMap);
            logCpuUsage(BEFORE_UPDATE,'updateContactId');
        }
        if (shouldRunMethod('routeCaseToDenaliLegacy')){
            CDdCaseTriggerHelperV2.routeCaseToDenaliLegacy(newList,oldMap);
            logCpuUsage(BEFORE_UPDATE,'routeCaseToDenaliLegacy');
        }
        if (shouldRunMethod('assignEquipmentToCase')){
            CDdCaseTriggerHelperV2.assignEquipmentToCase(newList,oldMap);
            logCpuUsage(BEFORE_UPDATE,'assignEquipmentToCase');
        }
        if (shouldRunMethod('preventCaseClosingWithoutReopenReasonForMxp')){
            CDdCaseTriggerHelperV2.preventCaseClosingWithoutReopenReasonForMxp(newList,oldMap);
            logCpuUsage(BEFORE_UPDATE,'preventCaseClosingWithoutReopenReasonForMxp');
        }
        if (shouldRunMethod('associatePartnerIntegrationRecord')){
            CDdCaseTriggerHelperV2.associatePartnerIntegrationRecord(newList,oldMap);
            logCpuUsage(BEFORE_UPDATE,'associatePartnerIntegrationRecord');
        }
        if(shouldRunMethod('processMxPReopenCases')){
            CDdCaseTriggerHelperV2.processMxPReopenCases(newList, oldMap);
            logCpuUsage(BEFORE_UPDATE,'processMxPReopenCases');
        }
        if(shouldRunMethod('reopenJapanCasesToTokyoEscalations')){
            CDdCaseTriggerHelperV2.reopenJapanCasesToTokyoEscalations(newList, oldMap);
            logCpuUsage(BEFORE_UPDATE,'reopenJapanCasesToTokyoEscalations');
        }
        if (shouldRunMethod('updateContractVerificationDate')){
            CDdCaseTriggerHelperV2.updateContractVerificationDate(newList,oldMap);
            logCpuUsage(BEFORE_UPDATE,'updateContractVerificationDate');
        }
        if (shouldRunMethod('populateDefaultValues')){
            CDdCaseTriggerHelperV2.populateDefaultValues(newList, oldMap);
            logCpuUsage(BEFORE_UPDATE,'populateDefaultValues');
        }
        if (shouldRunMethod('setCaseOwner')){
            CDdCaseTriggerHelperV2.setCaseOwner(newList,operationType);
            logCpuUsage(BEFORE_UPDATE,'setCaseOwner');
        }
        if (shouldRunMethod('requeryQueueInformation')){
            CDdCaseTriggerHelperV2.requeryQueueInformation(newList);
            logCpuUsage(BEFORE_UPDATE,'requeryQueueInformation');
        }
        if (shouldRunMethod('preventInvalidEsc')){
            CDdCaseTriggerHelperV2.preventInvalidEsc(newList,oldMap);
            logCpuUsage(BEFORE_UPDATE,'preventInvalidEsc');
        }
        if (shouldRunMethod('ownedCaseToOpen')){
            CDdCaseTriggerHelperV2.ownedCaseToOpen(newList, oldMap);
            logCpuUsage(BEFORE_UPDATE,'ownedCaseToOpen');
        }
        if (shouldRunMethod('processCaseTouchCount')){
            CDdCaseTriggerHelperV2.processCaseTouchCount(newList, oldMap);
            logCpuUsage(BEFORE_UPDATE,'processCaseTouchCount');
        }
        if (shouldRunMethod('validationsCasePendingReason')){ // BIZS-1478 Sid A
            CDdCaseTriggerHelperV2.validationsCasePendingReason(newList, oldMap);
            logCpuUsage(BEFORE_UPDATE,'validationsCasePendingReason');
        }
        if (shouldRunMethod('executeTransferValidation')){
            CDdCaseTransferValidationHelper.executeTransferValidation(newList, oldMap);
            logCpuUsage(BEFORE_UPDATE,'executeTransferValidation');
        }
        if (shouldRunMethod('preventInRescueStatusOnCase')){
            CDdCaseTriggerHelperV2.preventInRescueStatusOnCase(newList, oldMap);
            logCpuUsage(BEFORE_UPDATE,'preventInRescueStatusOnCase');
        }
        if(shouldRunMethod('setCaseOwnerBasedOnHibernatedOrSuspended')){
            CDdCaseTriggerHelperV2.setCaseOwnerBasedOnHibernatedOrSuspended(newList, oldMap);
            logCpuUsage(BEFORE_UPDATE,'setCaseOwnerBasedOnHibernatedOrSuspended');
        }
        if (shouldRunMethod('executeWorkflows')){
            CDdWorkflowConfigEvaluator.executeWorkflows(newList, oldMap);
            logCpuUsage(BEFORE_UPDATE,'executeWorkflows');
        }
        if(shouldRunMethod('mergeCaseAfterSolved')) {
            CDdCaseTriggerHelperV2.mergeCaseAfterSolved(newList, oldMap);
            logCpuUsage(BEFORE_UPDATE, 'mergeCaseAfterSolved');
        }
        if(shouldRunMethod('setCaseStatusToClosed')){
            CDdCaseTriggerHelperV2.setCaseStatusToClosed(newList, oldMap);
            logCpuUsage(BEFORE_UPDATE,'setCaseStatusToClosed');
        }
        if(shouldRunMethod('checkValidEscalatedTrustSaftyCase')){
            CDdCaseTriggerHelperV2.checkValidEscalatedTrustSaftyCase(newList, oldMap);
            logCpuUsage(BEFORE_UPDATE,'checkValidEscalatedTrustSaftyCase');
        }
        logCpuUsage(BEFORE_UPDATE,'End');
    }


    public void afterInsert(List<Case> newList, System.TriggerOperation operationType) {
        cpuUsageCaseTriggerHandler = 0;
        logCpuUsage(AFTER_INSERT,'Start');
        IS_CASE_INSERT = true;

        if (shouldRunMethod('updateOpActDetails')){
            CDdCaseTriggerHelperV2.updateOpActDetails(newList, null);
            logCpuUsage(AFTER_INSERT,'updateOpActDetails');
        }
        if (shouldRunMethod('createPhotoshootRequest')){
            CDdCaseTriggerHelperV2.createPhotoshootRequest(newList);
            logCpuUsage(AFTER_INSERT,'createPhotoshootRequest');
        }
        if (shouldRunMethod('createCaseMilestones')){ //BZAP-9178
            if (!CDdCustomMetadata.isDisabled('CDdOpportunityCaseHelper_marketplaceOnbo')) {
                CDdCaseMilestone milestones = new CDdCaseMilestone();
                milestones.createMilestones(Trigger.newMap.keySet());
                logCpuUsage(AFTER_INSERT,'createCaseMilestones');
            }
        }
        if (shouldRunMethod('processCasesForMxSx')){
            CDdCaseTriggerHelperV2.processCasesForMxSx(newList, null);
            logCpuUsage(AFTER_INSERT, 'processCasesForMxSx');
        }
        if (shouldRunMethod('processMxPCases')) {
            CDdCaseTriggerHelperV2.processMxPCases(newList,null);
            logCpuUsage(AFTER_INSERT,'processMxPCases');
        }
        if (shouldRunMethod('postInternalChatterFeed')){
            CDdCaseTriggerHelperV2.postInternalChatterFeed(newList, operationType);
            logCpuUsage(AFTER_INSERT,'postInternalChatterFeed');
        }

        if (shouldRunMethod('trackPackages')){
            CDdCaseTriggerHelperV2.trackPackages(newList, null);
            logCpuUsage(AFTER_INSERT,'trackPackages');
        }
        if (shouldRunMethod('autoCaseShadowCreation')){
            CDdCaseTriggerHelperV2.autoCaseShadowCreation(newList, null);
            logCpuUsage(AFTER_INSERT,'autoCaseShadowCreation');
        }

        if (shouldRunMethod('processAttachmentFromOpp')){
            CDdCaseTriggerHelperV2.processAttachmentFromOpp(newList);
            logCpuUsage(AFTER_INSERT,'processAttachmentFromOpp');
        }

        if (shouldRunMethod('executeWorkflows')){
            CDdWorkflowConfigEvaluator.executeWorkflows(newList, null);
            logCpuUsage(AFTER_INSERT,'executeWorkflows');
        }
        if (shouldRunMethod('updateInboundCounter')){
            CDdCaseTriggerHelperV2.updateInboundCounter(newList);
            logCpuUsage(AFTER_INSERT,'updateInboundCounter');
        }
        if(shouldRunMethod('processNonChatCasesForTHQ')) {
            CDdCaseTriggerHelperV2.processNonChatCasesForTHQ(newList);
            logCpuUsage(AFTER_INSERT, 'processNonChatCasesForTHQ');
        }
        CDdCaseTriggerOptimizationHelper.executeSObjectDML();
        logCpuUsage(AFTER_INSERT,'executeSObjectDML');
        logCpuUsage(AFTER_INSERT,'End');
    }

    public void afterUpdate(List<Case> newList, Map<Id, Case> oldMap){
        cpuUsageCaseTriggerHandler = 0;
        logCpuUsage(AFTER_UPDATE,'Start');

        if (shouldRunMethod('updateOpActDetails')){
            CDdCaseTriggerHelperV2.updateOpActDetails(newList, oldMap);
            logCpuUsage(AFTER_UPDATE,'updateOpActDetails');

        }
        if (shouldRunMethod('checkMilestones')){
            if (!CDdCustomMetadata.isDisabled('CDdOpportunityCaseHelper_marketplaceOnbo')) {
                CDdCaseTriggerHelperV2.checkMilestones(newList, oldMap);
                logCpuUsage(AFTER_UPDATE,'checkMilestones');
            }
        }
        if (shouldRunMethod('updateDeliverTabletMilestone')){
            CDdCaseTriggerHelperV2.updateDeliverTabletMilestone(newList, oldMap);
            logCpuUsage(AFTER_UPDATE,'updateDeliverTabletMilestone');

        }
        if (shouldRunMethod('createMissingCaseMilestones')){
            CDdCaseMilestone milestones = new CDdCaseMilestone();
            milestones.createMissingCaseMilestones(newList, oldMap);
            logCpuUsage(AFTER_UPDATE,'createMissingCaseMilestones');
        }
        if (shouldRunMethod('processPOSCases')){
            CDdCaseTriggerHelperV2.processPOSCases(newList, oldMap);
            logCpuUsage(AFTER_UPDATE,'processPOSCases');
        }
        if (shouldRunMethod('processSendbirdChats')) {
            CDdCaseTriggerHelperV2.processSendbirdChats(newList, oldMap);
            logCpuUsage(AFTER_UPDATE, 'processSendbirdChats');
        }
        if(!CDdRecursionUtils.isRunnable('CDdCaseTrigHelperCPQ_postSaleCaseClose')){
            CDdCaseTriggerHelper_CPQ.postSaleActivationsCaseClosed(newList, oldMap);
            logCpuUsage(AFTER_UPDATE,'postSaleActivationsCaseClosed');
        }
        if (shouldRunMethod('trackPackages')){
            CDdCaseTriggerHelperV2.trackPackages(newList, oldMap);
            logCpuUsage(AFTER_UPDATE,'trackPackages');
        }
        if (shouldRunMethod('processCasesForMxSx')){
            CDdCaseTriggerHelperV2.processCasesForMxSx(newList, oldMap);
            logCpuUsage(AFTER_UPDATE, 'processCasesForMxSx');
        }
        if (shouldRunMethod('createDenaliLogs')){
            CDdCaseTriggerHelperV2.createDenaliLogs(newList, oldMap);
            logCpuUsage(AFTER_UPDATE,'createDenaliLogs');
        }

        if (shouldRunMethod('createPhotoshootCaseOnMenuChange')){
            CDdCaseTriggerHelperV2.createPhotoshootCaseOnMenuChange(newList, oldMap);
            logCpuUsage(AFTER_UPDATE,'createPhotoshootCaseOnMenuChange');
        }

        if (shouldRunMethod('updateSalesNotesOnOCUSPortal')){
            CDdCaseTriggerHelperV2.updateSalesNotesOnOCUSPortal(newList, oldMap);
            logCpuUsage(AFTER_UPDATE,'updateSalesNotesOnOCUSPortal');
        }
        if (shouldRunMethod('postHandOffRecordType')){
            CDdCaseTriggerHelperV2.postHandOffRecordType(newList, oldMap);
            logCpuUsage(AFTER_UPDATE,'postHandOffRecordType');
        }
        if (shouldRunMethod('autoCaseShadowCreation')){
            CDdCaseTriggerHelperV2.autoCaseShadowCreation(newList, oldMap);
            logCpuUsage(AFTER_UPDATE,'autoCaseShadowCreation');
        }
        if (shouldRunMethod('handleUnresolvedContactPhoneCases')){
            CDdCaseTriggerHelperV2.handleUnresolvedContactPhoneCases(newList, oldMap);
            logCpuUsage(AFTER_UPDATE,'handleUnresolvedContactPhoneCases');
        }
        if (shouldRunMethod('proactiveCaseCreation')){
            CDdCaseTriggerHelperV2.proactiveCaseCreation(newList, Trigger.operationType);
            logCpuUsage(AFTER_UPDATE,'proactiveCaseCreation');
        }
        if (shouldRunMethod('processMxPCases')) {
            CDdCaseTriggerHelperV2.processMxPCases(newList,oldMap);
            logCpuUsage(AFTER_UPDATE,'processMxPCases');
        }
        if(shouldRunMethod('sendSurvey')) {
            CDdCaseTriggerHelperV2.sendSurvey(newList, oldmap, !CDdCustomMetadata.isDisabled('Platform_Event_Send_Survey_Trigger'));
            logCpuUsage(AFTER_UPDATE,'sendSurvey');
        }
        if (shouldRunMethod('executeWorkflows')){
            CDdWorkflowConfigEvaluator.executeWorkflows(newList, oldMap);
            logCpuUsage(AFTER_UPDATE,'executeWorkflows');
        }
        if (shouldRunMethod('checkForDisasterPreventionCase')){
            CDdCaseTriggerHelperV2.checkForDisasterPreventionCase(newList, oldMap);
            logCpuUsage(AFTER_UPDATE,'checkForDisasterPreventionCase');
        }
        if (shouldRunMethod('mxChargebackProcessing')){
            CDdCaseTriggerHelperV2.mxChargebackProcessing(newList);
            logCpuUsage(AFTER_UPDATE,'mxChargebackProcessing');
        }
        CDdCaseTriggerOptimizationHelper.executeSObjectDML();
        logCpuUsage(AFTER_UPDATE,'executeSObjectDML');
        logCpuUsage(AFTER_UPDATE,'End');
    }

    public void beforeDelete(List<Case> oldList, System.TriggerOperation operationType){
        cpuUsageCaseTriggerHandler = 0;
        logCpuUsage(BEFORE_DELETE,'Start');

        if (shouldRunMethod('processDeleteCase')){
            CDdCaseTriggerHelperV2.processDeleteCase(oldList);
            logCpuUsage(BEFORE_DELETE,'processDeleteCase');
        }
        logCpuUsage(BEFORE_DELETE,'End');
    }
}