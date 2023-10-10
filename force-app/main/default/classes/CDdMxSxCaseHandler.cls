/********************************************************************************************************************
* @author Veera maddukuri
* @date 08/30/2022
*
* @group Merchant Services
*
* @description Handler class for Case related operations
*
**************************************************************************************************************************************/
public class CDdMxSxCaseHandler {

    public static Set<Id> caseEventsProcessedOnInsert = new Set<Id>();
    public static Set<Id> caseEventsProcessedOnUpdate = new Set<Id>();

    /**
     * @description Process Cases for Merchant Services
     * @param List<Case> newCases
     * @param List<Case> oldMap
     * @return Boolean
    */
    public static void processCasesForMxSx(List<Case> newCases, Map<Id, Case> oldCaseMap){
        List<Case> casesToProcessForMxOrder = new List<Case>();
        List<Case> casesToProcessForPOSIntegration = new List<Case>();
        List<Case> casesToProcessForMarketplaceOboarding = new List<Case>();
        List<Case> casesToProcessForCaviarOnboarding = new List<Case>();

        Boolean isInsert = oldCaseMap == null;

        for (Case c : newCases){
            Boolean isSupportCase = CDdMxSxCaseOriginHandler.isEquipmentRequestSupportCase(c.origin);
            if (CDdMxOrderEventHelper.getSourceSObjectRecordTypeIds(CDdMxSxConstants.SOBJECT_TYPE_CASE).contains(c.RecordTypeId) && ((Trigger.isExecuting && Trigger.isUpdate) || !isSupportCase)){
                casesToProcessForMxOrder = addCaseToProcessList(c, casesToProcessForMxOrder, isInsert);
            }
            if (c.RecordTypeId == CDdSchemaUtils.CASE_RT.posIntegrationsId()){
                casesToProcessForPOSIntegration = addCaseToProcessList(c, casesToProcessForPOSIntegration, isInsert);
            }
            if (c.RecordTypeId == CDdSchemaUtils.CASE_RT.marketplaceOnboardingId()){
                casesToProcessForMarketplaceOboarding = addCaseToProcessList(c, casesToProcessForMarketplaceOboarding, isInsert);
            }
            if(c.RecordTypeId == CDdSchemaUtils.CASE_RT.caviarOnboardingId()) {
                casesToProcessForCaviarOnboarding = addCaseToProcessList(c, casesToProcessForCaviarOnboarding, isInsert);
            }
        }

        // MX ORDER CASES
        if(!casesToProcessForMxOrder.isEmpty()) {
            if(isInsert) {
                CDdMxOrderEventHelper.publishGenerateMxOrderEvents(casesToProcessForMxOrder);
            } else {
                CDdMxOrderEventHelper.publishMxOrderEvents(casesToProcessForMxOrder, oldCaseMap);
            }
        }

        // POS INTEGRATIONS CASES
        if(!casesToProcessForPOSIntegration.isEmpty() && !isInsert) {
            publishMxSxEventsForPOSIntegrationCases(casesToProcessForPOSIntegration, oldCaseMap);
        }

        // MARKETPLACE ONBGOARDING CASES
        if(!casesToProcessForMarketplaceOboarding.isEmpty()) {
            if(isInsert) {
                publishMxSxEventsForMarketplaceOnboardingCaseInsert(casesToProcessForMarketplaceOboarding);
            } else {
                publishMxSxEventsForMarketplaceOnboardingCaseUpdate(casesToProcessForMarketplaceOboarding, oldCaseMap);
            }
        }
        
        // CAVIAR CASES
        if(!casesToProcessForCaviarOnboarding.isEmpty()) {
            if(isInsert) {
                publishMxSxEventsForCaviarOnboardingCaseInsert(casesToProcessForCaviarOnboarding);
            } else {
                publishMxSxEventsForCaviarOnboardingCaseUpdate(casesToProcessForCaviarOnboarding, oldCaseMap);
            }
        }
    }
    
    /**
        @author: Dan Thoreson
        @date: 02-Feb-2023
        @description: Updates the recursive-guarding boolean to Sets, so that duplicative processing can be stopped more granularly
    **/
    public static List<Case> addCaseToProcessList(Case thisCase, List<Case> listToProcess, Boolean isInsert) {
        // If we are processing Cases on insert and this has not been done already for this Case, add to our process list
        if(isInsert && !caseEventsProcessedOnInsert.contains(thisCase.Id)) {
            caseEventsProcessedOnInsert.add(thisCase.Id);
            listToProcess.add(thisCase);
        // If we are processing Cases on update and this has not been done already for this Case, add to our process list
        } else if(!isInsert && !caseEventsProcessedOnUpdate.contains(thisCase.Id)) {
            caseEventsProcessedOnUpdate.add(thisCase.Id);
            listToProcess.add(thisCase);
        }

        return listToProcess; // Return the process list we inputted, potentially including the Case if it was not processed already
    }

    /**
     * @description Publish relevant MxSx Events for updated POS Integration Case records
     * @param List<Case> newCases
     * @param List<Case> oldMap
     * @return Boolean
    */
    public static Boolean publishMxSxEventsForPOSIntegrationCases(List<Case> newCases, Map<Id, Case> oldMap){
        Set<Id> changedStatusPosCaseIds = new Set<Id>();
        Set<String> statusesToMonitor = new Set<String>{
            CDdMxSxConstants.CASE_STATUS_CLOSED,
            CDdMxSxConstants.CASE_STATUS_BLOCKED,
            CDdMxSxConstants.CASE_STATUS_IN_PROGRESS,
            CDdMxSxConstants.CASE_STATUS_ESCALATED,
            CDdMxSxConstants.CASE_STATUS_RE_OPENED
        };

        Boolean publishedMxSxEvents = false;

        for (Case newCase : newCases) {
            Case oldCase = oldMap.get(newCase.Id);

            if(!CDdMxSxTriggerHelper.hasFieldValueChanged(newCase, oldCase, CDdMxSxConstants.CASE_FIELD_API_NAME_STATUS)) {
                continue;
            }

            if(statusesToMonitor.contains(newCase.Status)) {
                changedStatusPosCaseIds.add(newCase.Id);
            }
        }

        if(!changedStatusPosCaseIds.isEmpty()) {
            if(!changedStatusPosCaseIds.isEmpty()) {
                CDdMxSxEventPublisher.publishEventsPosIntegrationCaseStatusUpdated(CDdMxSxConstants.MXSX_EVENT.POS_INTEGRATION_CASE_STATUS_CHANGE, CDdMxSxConstants.SOBJECT_TYPE_CASE, changedStatusPosCaseIds);
            }

            publishedMxSxEvents = true;
        }

        return publishedMxSxEvents;
    }

     /**
     * @description BZAP-18475 Publish relevant MxSx Events for inserted Marketplace Case records
     * @param List<Case> newCases
     * @param List<Case> oldMap
     * @return Boolean
    */
    public static Boolean publishMxSxEventsForMarketplaceOnboardingCaseInsert(List<Case> newCases){
        Set<Id> marketplaceOnboardingInsertCaseIds = new Set<Id>();
        Boolean publishedMxSxEvents = false;
        for (Case newCase : newCases) {
            if (newCase.Opportunity_Name__c != null){
                marketplaceOnboardingInsertCaseIds.add(newCase.Id);
            }
        }
        if (!marketplaceOnboardingInsertCaseIds.isEmpty()){
            CDdMxSxEventPublisher.publishMxSxEventsForMarketplaceOnboardingCaseInsert(CDdMxSxConstants.SOBJECT_TYPE_CASE, marketplaceOnboardingInsertCaseIds);
            CDdMxSxEventPublisher.publishEventsForPosOpportunities(marketplaceOnboardingInsertCaseIds);

            publishedMxSxEvents = true;
        }
        return publishedMxSxEvents;
    }
    /**
     * @description BZAP-18475 Publish relevant MxSx Events for updated Marketplace Case records
     * There will be more use cases in the future, where updates to Marketplace Onboarding cases will flow through the Merchant Service event frameworks.
     * Here are the criteria for sending events for Marketplace Onboarding Case updates
     *      . when the Marketplace Onboarding Case stage is Changed and equal to 'Ready of Activation'
     * @param List<Case> newCases
     * @param List<Case> oldMap
     * @return Boolean
    */
    public static Boolean publishMxSxEventsForMarketplaceOnboardingCaseUpdate(List<Case> newCases, Map<Id, Case> oldMap){
        Set<Id> marketplaceOnboardingChangeCaseIds = new Set<Id>();
        Boolean publishedMxSxEvents = false;
        for (Case newCase : newCases) {
            Case oldCase = oldMap.get(newCase.Id);
            if (newCase.opportunity_name__c != null
               && String.isNotBlank(newCase.Stage__c)
               && CDdMxSxConstants.CASE_STAGE_READY_FOR_ACTIVATION.equals(newCase.Stage__c)
               && CDdMxSxTriggerHelper.hasFieldValueChanged(newCase, oldCase, CDdMxSxConstants.CASE_FIELD_API_NAME_STAGE)){
                    marketplaceOnboardingChangeCaseIds.add(newCase.Id);
            }
        }
        if (!marketplaceOnboardingChangeCaseIds.isEmpty()){
            CDdMxSxEventPublisher.publishMxSxEventsForMarketplaceOnboardingCaseUpdate(CDdMxSxConstants.SOBJECT_TYPE_CASE, marketplaceOnboardingChangeCaseIds);
            publishedMxSxEvents = true;
        }
        return publishedMxSxEvents;
    }
    /**
     * @description BZAP-19404 Publish relevant MxSx Events for updated Caviar Case records
     * There will be more use cases in the future, where updates to Caviar Onboarding cases will flow through the Merchant Service event frameworks.
     * Here are the criteria for sending events for Caviar Onboarding Case updates
     *      . when the Caviar Onboarding Case MxPHandOffDate is changed, Activation Date != null
     * @param List<Case> newCases
     * @param List<Case> oldMap
     * @return Boolean
    */
    public static Boolean publishMxSxEventsForCaviarOnboardingCaseUpdate(List<Case> newCases, Map<Id, Case> oldMap){
        Set<Id> caviarOnboardingChangeCaseIds = new Set<Id>();
        Boolean publishedMxSxEvents = false;
        for (Case newCase : newCases) {
            Case oldCase = oldMap.get(newCase.Id);
            if (newCase.opportunity_name__c != null
               && newCase.MxP_Handoff_Date__c != null
               && newCase.Activation_Date__c != null
               && CDdMxSxTriggerHelper.hasFieldValueChanged(newCase, oldCase, 'MxP_Handoff_Date__c'))
               {
                caviarOnboardingChangeCaseIds.add(newCase.Id);
            }
        }
        if (!caviarOnboardingChangeCaseIds.isEmpty()){
            CDdMxSxEventPublisher.publishMxSxEventsForCaviarOnboardingCaseUpdate(CDdMxSxConstants.SOBJECT_TYPE_CASE, caviarOnboardingChangeCaseIds);
            publishedMxSxEvents = true;
        }
        return publishedMxSxEvents;
    }

    /**
        @author: Dan Thoreson
        @date: 21-Feb-2023
        @description: When a Caviar Onboarding Case is inserted, check the Opportunity and see if we need to insert a POS Integrations Case, similar
                      to how we create POS Cases for Marketplace Onboarding Cases. 
    **/
    public static void publishMxSxEventsForCaviarOnboardingCaseInsert(List<Case> newCases) {
        Set<Id> caviarCaseIds = new Set<Id>();
        
        for(Case newCase : newCases) {
            if(newCase.Opportunity_Name__c != null) {     
                caviarCaseIds.add(newCase.Id);     
            }
        }
                
        CDdMxSxEventPublisher.publishEventsForPosOpportunities(caviarCaseIds);
    }
}