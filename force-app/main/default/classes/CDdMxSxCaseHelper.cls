/********************************************************************************************************************
* @author Sriram
* @date 11/01/2021
*
* @group Merchant Services
*
* @description Helper class for Case related operations
*
**************************************************************************************************************************************/
public class CDdMxSxCaseHelper {
    public static final String CLASS_NAME = 'CDdMxSxCaseHelper';
    public static final List<Case_Partner_Integration_Attr_Mapping__mdt> casePartnerIntegrationAttrMappings = Case_Partner_Integration_Attr_Mapping__mdt.getAll().values();
    public static String PARTNER_INTEGRATION_ASSOC_PARTNER_INTEGRATION_SOQL_QUERY = ' SELECT {0} FROM Partner_Integration__c WHERE Provider_Type__c IN :providerTypes AND RecordTypeId = :pointOfSalePartIntRTId';
    public static Set<Id> PARTNER_INTEGRATION_ASSOC_CASE_RECORD_TYPES = new Set<Id>{CDdSchemaUtils.CASE_RT.posIntegrationsId()};
    public static final Id pointOfSalePartIntRTId = CDdSchemaUtils.getRecordTypeIdByDeveloperName('Partner_Integration__c','Point_Of_Sale');
    static {
        List<String> PARTNER_INTEGRATION_ASSOC_SELECT_FIELDS = new List<String>{'Provider_Type__c'};
        for (Case_Partner_Integration_Attr_Mapping__mdt m : casePartnerIntegrationAttrMappings){
            PARTNER_INTEGRATION_ASSOC_SELECT_FIELDS.add(m.Source_API_Field__c);
        }
        PARTNER_INTEGRATION_ASSOC_PARTNER_INTEGRATION_SOQL_QUERY = String.format(
            PARTNER_INTEGRATION_ASSOC_PARTNER_INTEGRATION_SOQL_QUERY,
            new List<String>{String.join(PARTNER_INTEGRATION_ASSOC_SELECT_FIELDS, ',')}
        );
    }

    // Gets the feature flag for determining which logic we use to advance Storefront Onboarding Cases to the Under Review queue.
    // Permits overwriting the metadata setting in test contexts, for example.
    @TestVisible private static Boolean assignStorefrontCasesWhenSingleStoreIsActive {get {
        if(assignStorefrontCasesWhenSingleStoreIsActive == null) {
            assignStorefrontCasesWhenSingleStoreIsActive = CDdExperimentSvc.getFeatureFlag('Assign_Storefront_Cases_One_Active_Store__c');
        }

        return assignStorefrontCasesWhenSingleStoreIsActive;
    } set;}

    /**
     * @description Move Storefront Onboarding Case to active Queue when all Child Accounts are Onboarded and Active
     * @param Set<Id> parentAccountIds - Collection of Parent Account Record Identifiers
     * @return void
     */
    public static void updateStorefrontOnboardingCaseToActiveQueue(Set<Id> parentAccountIds){
        String METHOD_NAME = 'updateStorefrontOnboardingCaseToActiveQueue';
        Map<Id, Case> casesToUpdateForParentAccountId = new Map<Id, Case>();
        List<String> errorMessages = new List<String>();
        try {
            CDdMxSxParentAccountHelper parentAccountHelper = new CDdMxSxParentAccountHelper(parentAccountIds);

            for (Id parentAccountId : parentAccountIds) {
                if (shouldCaseGoToUnderReviewQueue(parentAccountHelper, parentAccountId)) {
                    Case c = parentAccountHelper.getActiveStorefrontOnboardingCase(parentAccountId, null);
                    casesToUpdateForParentAccountId.put(parentAccountId, new Case(Id = c.Id, OwnerId = CDdMxSxConstants.QUEUE_ID_STOREFRONT_UNDER_REVIEW_MXS, Date_Time_Case_Became_Workable__c = System.now()));
                }
            }
            if (!casesToUpdateForParentAccountId.isEmpty()){
                List<Database.SaveResult> sResults = Database.update(casesToUpdateForParentAccountId.values(), false);
                errorMessages = CDdErrorUtilities.processSaveResults(sResults, errorMessages);
                CDdMxSxException.logDmlErrors(CDdMxSxException.DML_OPERATION_UPDATE, CLASS_NAME, METHOD_NAME, String.valueOf(CDdMxSxConstants.MXSX_EVENT.STORE_ACTIVE), LoggingLevel.ERROR, CDdMxSxConstants.SOBJECT_TYPE_ACCOUNT, 'AccountId', errorMessages, CDdMxSxException.getSObjectsAfterUpdate(sResults, casesToUpdateForParentAccountId.values(), true));
            }
        } catch (Exception e) {
            errorMessages.add(e.getStackTraceString());
            throw new CDdMxSxException(e);
        } finally {
        }
    }
    /**
     * @description BZAP-12797 - Associate Partner Integration record and attributes to POS Integration Case
     * Perform the following for Cases with record types (such as POS Integrations) that are eligible for association with Partner Integration record
     * 1. To begin with, always default the Partner Integration related fields to null values on the Case record
     *      Reason - Even if a POS Integration Type exists, there may not be a corresponding Partner Integration record in the custom object
     * 2. Collect the Cases to process (group by POS Integration Type), for linking with specific Partner Integration record
     * 3. Set the Account Segment on the Case records for ones that have a linked account
     * 4. Walk through the collection of Cases to process and link/populate the specific Partner Integration record
     * @param List<Case> cases - Collection of Case records
     * @param Map<Id, Account> caseAccountMap - Map collection of Case related Account
     * @return void
     */
    public static void associatePartnerIntegrationRecord(List<Case> cases, Map<Id, Account> caseAccountMap){
        Map<String, List<Case>> casesGroupedByProviderType = new Map<String, List<Case>>();
        for (Case c : cases){
            if (PARTNER_INTEGRATION_ASSOC_CASE_RECORD_TYPES.contains(c.RecordTypeId)){
                // Step 1
                for (Case_Partner_Integration_Attr_Mapping__mdt m : casePartnerIntegrationAttrMappings){
                    c.put(m.Target_API_Field__c, null);
                }
                // Step 2
                if (String.isNotBlank(c.POS_Integration_Type__c)){
                    if (casesGroupedByProviderType.containsKey(c.POS_Integration_Type__c)){
                        casesGroupedByProviderType.get(c.POS_Integration_Type__c).add(c);
                    } else {
                        casesGroupedByProviderType.put(c.POS_Integration_Type__c, new List<Case>{c});
                    }

                }
                // Step 3
                if (String.isNotBlank(c.AccountId) && caseAccountMap.containsKey(c.AccountId)){
                    Account account = caseAccountMap.get(c.AccountId);
                    c.Segment__c = getSegment(account);
                }
            }
        }
        // Step 4
        if (!casesGroupedByProviderType.isEmpty()){
            Set<String> providerTypes = casesGroupedByProviderType.keySet();
            for (Partner_Integration__c pi : Database.query(PARTNER_INTEGRATION_ASSOC_PARTNER_INTEGRATION_SOQL_QUERY)){
                for (Case c : casesGroupedByProviderType.get(pi.Provider_Type__c)){
                    for (Case_Partner_Integration_Attr_Mapping__mdt m : casePartnerIntegrationAttrMappings){
                        c.put(m.Target_API_Field__c, pi.get(m.Source_API_Field__c));
                    }
                }
            }
        }
    }
    /**
     * @description Return the segment (Enterprise or Local) for the associated account on the Case record
     * @param Account account
     * @return String
     */
    public static String getSegment(Account account){
        if (account == null) { return null; }
        Boolean isEnterpriseSegment = false;
        if (CDdMxSxConstants.RECORD_TYPE_ID_ACCOUNT_ENTERPRISE_MARKETPLACE.equals(account.RecordTypeId)
            ||
            new Set<String>{CDdMxSxConstants.DECK_RANK_ACE_OF_SPADES, CDdMxSxConstants.DECK_RANK_KING_OF_SPADES}.contains(account.Deck_Rank__c)){
            isEnterpriseSegment = true;
        }
        if (!isEnterpriseSegment && String.isNotBlank(account.ParentId)){
            isEnterpriseSegment = (String.isNotBlank(account.Parent.Deck_Rank__c) && account.Parent.Deck_Rank__c.contains(CDdMxSxConstants.DECK_RANK_OF_SPADES));
        }
        return (isEnterpriseSegment ? CDdMxSxConstants.SEGMENT_ENTERPRISE : (account.Local_Premium__c ?  CDdMxSxConstants.SEGMENT_LOCAL_PREMIUM : CDdMxSxConstants.SEGMENT_LOCAL));
    }
    /**
     * @description Return the Collection of Case records (grouped by Opportunity Record Id), associated with input Collection of Opportunity Record Ids
     * @param Set<Id> opportunityIds
     * @return Map<Id, List<Case>> Collection of Case records grouped by Opportunity Record Id
     */
    public static Map<Id, List<Case>> getCasesForOpportunities(Set<Id> opportunityIds){
        Map<Id, List<Case>> casesForOpportunities = new Map<Id, List<Case>>();
        for (Case c : [ SELECT Id, AccountId, Opportunity_Name__c, Subject, Type, Status,
                        Account.OwnerId, Opportunity_Name__r.OwnerId, Account_Owner__c, Op_Owner__c
                        FROM Case
                        WHERE Opportunity_Name__c IN :opportunityIds]){
            if (casesForOpportunities.containsKey(c.Opportunity_Name__c)){
                casesForOpportunities.get(c.Opportunity_Name__c).add(c);
            } else {
                casesForOpportunities.put(c.Opportunity_Name__c, new List<Case>{c});
            }
        }
        return casesForOpportunities;
    }

    /**
        @author: Dan Thoreson
        @date: 04-Aug-2022
        @description: Determines if the Storefront Onboarding Case is in a position where it can be advanced to the Under Review Queue.
                      This is based off the activation statuses of the Stores under the Parent Account.
    **/
    public static Boolean shouldCaseGoToUnderReviewQueue(CDdMxSxParentAccountHelper parentAccountHelper, Id parentAccountId) {
        // Assign Case to Storefront Under Review queue (from the Holding queue) if ANY of the Stores become active
        if(assignStorefrontCasesWhenSingleStoreIsActive) {
            return parentAccountHelper.hasActiveStorefrontOnboardingCaseInHoldingQueue(parentAccountId, null) && parentAccountHelper.hasAnyActiveStores(parentAccountId);
        // Use legacy logic where ALL Stores must be active before Case can move to Storefront Under Review
        } else {
            return !parentAccountHelper.hasInactiveStores(parentAccountId) &&  parentAccountHelper.hasStores(parentAccountId) && parentAccountHelper.hasActiveStorefrontOnboardingCaseInHoldingQueue(parentAccountId, null);
        }
    }

    /**
     * @author: Veera
     * @date: 25-Aug-2022
     * @description: Update Opportunity when POS Integration case is closed
    **/
    public static void updateOpportunityOnPOSIntegrationCaseClosed(Set<Id> caseIds){
        Map<Id, Case> accounIdVsCaseMap= new Map<Id, Case>();
        List<String> recordtypeDeveloperNames = Label.MX_PROCESS_POS_INTG_ID_OPP_REC_TYPES.split(',');
        List<String> exclusionKeyWordsForPOSIntegrationsId = Label.MX_PROCESS_POS_INTG_ID_EXCLUSION_RULE.split(';');

        List<Case> cases = getCasesByIdAndAccountRecordTypes(caseIds, new Set<Id>{CDdMxSxConstants.RECORD_TYPE_ID_ACCOUNT_ENTERPRISE_MARKETPLACE, CDdMxSxConstants.RECORD_TYPE_ID_ACCOUNT_MARKETPLACE});
        for(Case caseRec : cases){
            if (isValidPosIntegrationId(caseRec, exclusionKeyWordsForPOSIntegrationsId)) {
                accounIdVsCaseMap.put(caseRec.AccountId, caseRec);
            }
        }

        if(!accounIdVsCaseMap.isEmpty()){
            List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
            Set<Id> processedAccounts = new Set<Id>();
            List<Opportunity> opportunities = getOpportunitiesByRecordTypesAndAccountIds(accounIdVsCaseMap.keySet(), recordtypeDeveloperNames);

            for(Opportunity opp : opportunities){
                if (accounIdVsCaseMap.containsKey(opp.AccountId) && !processedAccounts.contains(opp.AccountId)){
                    if (opp.Platform__c == CDdMxSxConstants.OPPORTUNITY_PLATFORM_CAVIER){
                        //update Opportunity POS Integration fields for Caviar
                        if (opp.Caviar_Order_Protocol__c.containsIgnoreCase(CDdMxSxConstants.OPPORTUNITY_POS)){
                            opp.POS_Integration_ID__c = accounIdVsCaseMap.get(opp.AccountId).POS_Integration_ID__c;
                            opp.Caviar_POS_Integration_Type__c = accounIdVsCaseMap.get(opp.AccountId).POS_Integration_Type__c;
                            opportunitiesToUpdate.add(opp);
                        }
                    }else if (opp.Platform__c == CDdMxSxConstants.OPPORTUNITY_PLATFORM_DOORDASH) {
                        //update Opportunity POS Integration fields for DoorDash platform
                        if (opp.Order_Protocol__c.containsIgnoreCase(CDdMxSxConstants.OPPORTUNITY_POS)){
                            opp.POS_Integration_ID__c = accounIdVsCaseMap.get(opp.AccountId).POS_Integration_ID__c;
                            opp.POS_Integration_Type__c = accounIdVsCaseMap.get(opp.AccountId).POS_Integration_Type__c;
                            opportunitiesToUpdate.add(opp);
                        }
                    }
                    processedAccounts.add(opp.AccountId);
                }
            }

            if(!opportunitiesToUpdate.isEmpty()){
                update opportunitiesToUpdate;
            }
        }
    }

    private static List<Case> getCasesByIdAndAccountRecordTypes(Set<Id> caseIds, Set<Id> accountRecordtypesIds){
        return [SELECT Id, AccountId, POS_Integration_ID__c, POS_Integration_Type__c FROM Case
                WHERE Id IN :caseIds
                AND Account.RecordTypeId IN :accountRecordtypesIds];
    }

    private static List<Opportunity> getOpportunitiesByRecordTypesAndAccountIds(Set<Id> accountIds, List<String> recordtypeDeveloperNames){
        return [SELECT Id, AccountId, Order_Protocol__c, Caviar_Order_Protocol__c, Platform__c FROM Opportunity
                WHERE AccountId IN :accountIds
                AND StageName = :CDdMxSxConstants.OPPORTUNITY_STAGE_CLOSED_WON
                AND RecordType.DeveloperName IN :recordtypeDeveloperNames
                ORDER BY CloseDate Desc];
    }

    private static Boolean isValidPosIntegrationId(Case caseRec, List<String> exclusionKeyWordsForPOSIntegrationsId){
        Boolean isValidPOSId = true;
        if (String.isNotBlank(caseRec.POS_Integration_ID__c) &&
            String.isNotBlank(caseRec.POS_Integration_Type__c)) {
                for (String exclusionKey : exclusionKeyWordsForPOSIntegrationsId) {
                    if (caseRec.POS_Integration_ID__c.containsIgnoreCase(exclusionKey)) {
                        isValidPOSId = false;
                        break;
                    }
                }
            }
            return isValidPOSId;
    }

    /**
     * @author: Veera
     * @date: 15-Sep-2022
     * @description: Determines if the
     * @param Set<Id> OpportunityIds
     * @return Map<Id,Boolean>
    **/
    public static Map<Id,Boolean> isMxEligibleForPrinter(Set<Id> opportunityIds) {
        Map<Id,Boolean> opportunityVsPrinterEligibleStatus = new Map<Id,Boolean>();
        Map<String,Opportunity> opportunitiesForPartnerIntegrationStatusCheck = new Map<String,Opportunity>();

        //bypass Permission check
        if(byPassSendPrinterValidationsForUser()){
            for(Id oppId : opportunityIds) {
                opportunityVsPrinterEligibleStatus.put(oppId, true);
            }
            return opportunityVsPrinterEligibleStatus;
        }

        for(Opportunity opp : getOpportunitiesByIds(opportunityIds)) {
            opportunityVsPrinterEligibleStatus.put(opp.Id, false);
            if (opp.Account != null &&
                (isTopMxAccountToSendPrinter(opp.Account) || (String.isNotBlank(opp.Platform__c) && opp.Platform__c.containsIgnoreCase(CDdMxSxConstants.OPPORTUNITY_PLATFORM_CAVIER))) &&
                CDdMxSxConstants.MXSX_STORE_ACCOUNT_RECORD_TYPE_IDS.contains(opp.Account.RecordtypeId)){
                    if(String.isNotBlank(opp.Order_Protocol__c) && opp.Order_Protocol__c.containsIgnoreCase(CDdMxSxConstants.OPPORTUNITY_POS)){
                        if (String.isNotBlank(opp.POS_Integration_Type__c)) {
                            opportunitiesForPartnerIntegrationStatusCheck.put(opp.POS_Integration_Type__c, opp);
                        }
                    }else{
                        opportunityVsPrinterEligibleStatus.put(opp.Id, true);
                    }
            }
        }

        return getPrinterEligibleOpportunitiesByProviderType(opportunitiesForPartnerIntegrationStatusCheck,opportunityVsPrinterEligibleStatus);
    }
    /**
     * @author: Veera
     * @date: 25-Aug-2022
     * @description: returns the Eligible opportunities by checking Partner Integration records for given provider types
    **/
    public static Map<Id,Boolean> getPrinterEligibleOpportunitiesByProviderType(Map<String,Opportunity> opportunitiesForPartnerIntegrationStatusCheck,  Map<Id,Boolean> opportunityVsPrinterEligibleStatus){
        if(!opportunitiesForPartnerIntegrationStatusCheck.isEmpty()){
            Map<String,Partner_Integration__c> providertypeVsPartnerIntegration = getPartnerIntegrationTypes(opportunitiesForPartnerIntegrationStatusCheck.keySet());
            for(Opportunity opp : opportunitiesForPartnerIntegrationStatusCheck.values()){
                if(providertypeVsPartnerIntegration.containsKey(opp.POS_Integration_Type__c)){
                    Partner_Integration__c pi = providertypeVsPartnerIntegration.get(opp.POS_Integration_Type__c);
                    if (pi.Menu_Vs_Order_Integration__c == CDdMxSxConstants.PARTNER_INTEG_MENU_ONLY_INTEGRATION) {
                        opportunityVsPrinterEligibleStatus.put(opp.Id, true);
                    }
                }
            }
        }
        return opportunityVsPrinterEligibleStatus;
    }

    private static List<Opportunity> getOpportunitiesByIds(Set<Id> opportunityIds){
        return [SELECT Id, AccountId, Account.Deck_Rank__c, Account.Top_Mx__c, Account.RecordtypeId, Order_Protocol__c, RecordtypeId, Caviar_Order_Protocol__c, POS_Integration_Type__c, Platform__c,Account.BillingCountry
                FROM Opportunity
                WHERE Id IN :opportunityIds];
    }

    /**
     * @author: Veera
     * @date: 25-Aug-2022
     * @description: returns the Partner_Integration__c records for Provider Types
     * @param Set<String> providerTypes
     * @return Map<String,Partner_Integration__c>
    **/
    private static Map<String,Partner_Integration__c> getPartnerIntegrationTypes(Set<String> providerTypes){
        Map<String,Partner_Integration__c> providertypeVsPartnerIntegration = new Map<String,Partner_Integration__c>();
        List<Partner_Integration__c> partnerIntegrations = [SELECT Id, Recordtype.Name, Provider_Type__c, Menu_Vs_Order_Integration__c FROM Partner_Integration__c
                                                            WHERE Provider_Type__c IN :providerTypes AND RecordtypeId =:pointOfSalePartIntRTId];
        for (Partner_Integration__c pi : partnerIntegrations) {
            providertypeVsPartnerIntegration.put(pi.Provider_Type__c, pi);
        }
        return providertypeVsPartnerIntegration;
    }

    /**
     * @author: Veera
     * @date: 22-Sep-2022
     * @description: Profiles and permission sets to bypass printer Validations/checks
    **/
    public static Boolean byPassSendPrinterValidationsForUser(){
        User currentUser = [SELECT Id, ProfileId, Profile.Name,
                            (SELECT Id, PermissionSet.Name FROM PermissionSetAssignments WHERE PermissionSet.Name IN :CDdMxSxConstants.PRINTER_BYPASS_PERMISSIONSETS)
                            FROM User WHERE Id=:Userinfo.getUserId() LIMIT 1];

        return hasUserEligibleToBypassSendPrinterValidations(currentUser, null);
    }

     /**
     * @author: Veera
     * @date: 20-Nov-2022
     * @description: Profiles and permission sets to bypass printer Validations/checks
    **/
    public static Boolean hasUserEligibleToBypassSendPrinterValidations(User userRec, Set<Id> userIdsWithPrinterByPassPermset){
        if (CDdMxSxConstants.PRINTER_BYPASS_PROFILES.contains(userRec.Profile.Name) ||
            (userRec.PermissionSetAssignments != null && userRec.PermissionSetAssignments.size() > 0) ||
            (userIdsWithPrinterByPassPermset != null && userIdsWithPrinterByPassPermset.contains(userRec.Id))){
                return true;
        }
        return false;
    }

    public static Boolean isTopMxAccountToSendPrinter(Account acc){
        return (CDdMxSxConstants.PRINTER_ELIGIBLE_ACCOUNT_DECK_RANKS.contains(acc.Deck_Rank__c) || acc.Top_Mx__c);
    }
    /**
     * @author: Veera
     * @date: 20-Nov-2022
     * @description: Determines if the MX is eligible for printer from CaseIds
     * @param Set<Id> OpportunityIds
     * @return Map<Id,Boolean>
     */
    public static Map<Id,Boolean> isMxEligibleForPrinterForCases(Set<Id> CaseIds) {
        Set<Id> userIdsWithPrinterByPassPermset = getuserIdsWithPrinterByPassPermset();
        Set<Id> opptiesToBeVerified = new Set<Id>();
        Map<Id,Boolean> opportunityVsPrinterEligibleStatus = new Map<Id,Boolean>();
        for (Case caseRec : getCasesByIds(CaseIds)) {
            if(hasUserEligibleToBypassSendPrinterValidations(caseRec.CreatedBy, userIdsWithPrinterByPassPermset)){
                opportunityVsPrinterEligibleStatus.put(caseRec.Opportunity_Name__c, true);
                continue;
            }else{
                opptiesToBeVerified.add(caseRec.Opportunity_Name__c);
            }
        }
        opptiesToBeVerified.removeAll(opportunityVsPrinterEligibleStatus.keySet());
        opportunityVsPrinterEligibleStatus.putAll(isMxEligibleForPrinter(opptiesToBeVerified));
        return opportunityVsPrinterEligibleStatus;
    }

    public static Set<Id> getUserIdsWithPrinterByPassPermset(){
        Set<Id> userIdsWithPrinterByPassPermset = new Set<Id>();
        for(PermissionSetAssignment psa : [SELECT Id, PermissionSet.Name,AssigneeId, Assignee.Profile.Name FROM PermissionSetAssignment WHERE PermissionSet.Name IN :CDdMxSxConstants.PRINTER_BYPASS_PERMISSIONSETS]){
            userIdsWithPrinterByPassPermset.add(psa.AssigneeId);
        }
        return userIdsWithPrinterByPassPermset;
    }

    private static List<Case> getCasesByIds(Set<Id> caseIds){
        return [SELECT Id,CreatedBy.Id, CreatedBy.Profile.Name, Opportunity_Name__c
                FROM Case
                WHERE Id IN :caseIds];
    }

    /**
        @author: Dan Thoreson
        @date: 01-Dec-2022
        @description: When a POS Integration Case is marked as "Closed", retrieve the related Marketplace Onboarding Case and close it.
                      The caseIds param will be a Set of IDs of Closed POS Integrations Cases.
    **/
    public static void updateMarketplaceOnboardingMilestoneFromPosCase(List<Case> posCases) {
        Map<Id, Case> posCasesByParentMarketplaceCaseIds = new Map<Id, Case>();

        // This holds the Case Statuses and the corresponding Milestone Statuses
        // That is, when a Case gets updated to X Status, Y Status should be set on the Milestone
        // Most of these will be identical or nearly identical - e.g., "Closed" and "Complete" / "Blocked" and "Blocked"
        Map<String, String> milestoneStatusesByCaseStatuses = new Map<String, String>{
            CDdMxSxConstants.CASE_STATUS_CLOSED => CDdMxSxConstants.MILESTONE_STATUS_COMPLETE,
            CDdMxSxConstants.CASE_STATUS_BLOCKED => CDdMxSxConstants.MILESTONE_STATUS_BLOCKED,
            CDdMxSxConstants.CASE_STATUS_IN_PROGRESS => CDdMxSxConstants.MILESTONE_STATUS_IN_PROGRESS,
            CDdMxSxConstants.CASE_STATUS_RE_OPENED => CDdMxSxConstants.MILESTONE_STATUS_IN_PROGRESS,
            CDdMxSxConstants.CASE_STATUS_ESCALATED => CDdMxSxConstants.MILESTONE_STATUS_ESCALATED
        };

        try {
            for (Case updatedCase : posCases) {
                if(updatedCase.ParentId != null && milestoneStatusesByCaseStatuses.containsKey(updatedCase.Status)) {
                    posCasesByParentMarketplaceCaseIds.put(updatedCase.ParentId, updatedCase);
                }
            }

            if(posCasesByParentMarketplaceCaseIds.isEmpty()) {
                return;
            }

            Set<String> posMilestoneRecordTypeDevNames = new Set<String>{ CDdCaseMilestoneMarketplaceOnboarding.SETUP_POS_RT_DEV_NAME };

            List<Milestone__c> posMilestonesToUpdate = MilestonesSelector.newInstance()
                                                                         .selectByCaseIdAndRecordTypeDeveloperName(posCasesByParentMarketplaceCaseIds.keySet(), posMilestoneRecordTypeDevNames);

            if(posMilestonesToUpdate.isEmpty()) {
                return;
            }

            fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();

            for(Milestone__c thisMilestone : posMilestonesToUpdate) {
                Case childPosCase = posCasesByParentMarketplaceCaseIds.get(thisMilestone.Case__c);
                thisMilestone.Status__c = milestoneStatusesByCaseStatuses.get(childPosCase.Status);

                // Set Status Reason if the Milestone is set to Blocked or Escalated
                // Add a message in the Status Reason Details which will populate to the Case level (by default, via other automation) if the Milestone is Blocked.
                // This will surface to the team working the Marketplace Case what is blocking the POS Case.
                if(new Set<String>{ CDdMxSxConstants.MILESTONE_STATUS_BLOCKED, CDdMxSxConstants.MILESTONE_STATUS_ESCALATED }.contains(thisMilestone.Status__c)) {
                    thisMilestone.Status_Reason__c = 'Other';

                    String statusReasonDetailsStr = 'The corresponding POS Integrations Case is ' + childPosCase.Status;

                    if(String.isNotBlank(childPosCase.Status_Reason__c)) {
                        statusReasonDetailsStr += '. Status Reason: ' + childPosCase.Status_Reason__c;

                        if(String.isNotBlank(childPosCase.Status_Reason_Details__c)) {
                            statusReasonDetailsStr += ' - ' + childPosCase.Status_Reason_Details__c;
                        }
                    }

                    thisMilestone.Status_Reason_Details__c = statusReasonDetailsStr;
                } else {
                    thisMilestone.Status_Reason__c = null;
                    thisMilestone.Status_Reason_Details__c = null;
                }

                uow.registerDirty(thisMilestone);
            }

            uow.commitWork();
        } catch (Exception ex) {
            CDdErrorUtilities.publishException('Milestone','CDdMxSxCaseHelper.updateMarketplaceOnboardingMilestoneFromPosCase', ex);
        }
    }
    
    /**
        @author: Dan Thoreson
        @date: 07-Apr-2023
        @description: Runs when POS Integration Case Statuses are updated
    **/
    public static void handlePosIntegrationCaseStatusUpdate(Set<Id> caseIds) {
        List<Case> updatedCases = CasesSelector.newInstance().selectByIdExtraFields(caseIds, new Set<String>{'Status_Reason__c', 'Status_Reason_Details__c'});
        Set<Id> closedCaseIds = new Set<Id>();
        
        for(Case thisCase : updatedCases) {
            if(thisCase.Status == CDdMxSxConstants.CASE_STATUS_CLOSED) {
                closedCaseIds.add(thisCase.Id);
            }
        }
        
        if(!closedCaseIds.isEmpty()) {
            CDdMxSxCaseHelper.updateOpportunityOnPOSIntegrationCaseClosed(closedCaseIds);
        }
        
        CDdMxSxCaseHelper.updateMarketplaceOnboardingMilestoneFromPosCase(updatedCases);
    }
}