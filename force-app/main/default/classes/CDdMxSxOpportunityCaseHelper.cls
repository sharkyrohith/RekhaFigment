/********************************************************************************************************************
* @author Sriram
* @date 11/04/2021
*
* @group Merchant Services
*
* @description Helper class to create/manage Cases for Opportunity records
* 
**************************************************************************************************************************************/
public class CDdMxSxOpportunityCaseHelper {
    public static final String CLASS_NAME = 'CDdMxSxOpportunityCaseHelper';
    /**
     * Define class variables here
     */
    private Set<Id> opportunityIds;
    private CDdMxSxOpportunityHelper opportunityHelper;
    private CDdMxSxParentAccountHelper parentAccountHelper;
    /** 
     * @description Single argument constructor
     * @param Set<Id> opportunityIds - Collection of Opportunity Ids
     * @return void
     */        
    public CDdMxSxOpportunityCaseHelper(Set<Id> opportunityIds) {
        this.opportunityIds = opportunityIds;
        this.opportunityHelper = new CDdMxSxOpportunityHelper(opportunityIds);
        this.parentAccountHelper = new CDdMxSxParentAccountHelper(this.opportunityHelper.getParentAccountIds());
    }
    /** 
     * @description Create Storefront Onboarding Cases
     * - Ensure Opportunity is in Closed Won stage and has Net-New Storefront Pricing
     * - Ensure the Opportunity does not have an active Storefront Onboarding Case at the Parent Account level
     * @param 
     * @return void
     */ 
    public void createStorefrontOnboardingCases(){
        String METHOD_NAME = 'createStorefrontOnboardingCases';
        Map<Id, Case> caseForParentId = new Map<Id, Case>();
        List<String> errorMessages = new List<String>();
        try {
            for (Id opportunityId : this.opportunityIds){
                if (opportunityHelper.isClosedWon(opportunityId)
                    && opportunityHelper.hasNetNewStorefrontPricing(opportunityId)
                    && opportunityHelper.hasParentAccountId(opportunityId)
                    && !caseForParentId.containsKey(opportunityHelper.getParentAccountId(opportunityId))
                    && !parentAccountHelper.hasActiveStorefrontOnboardingCase(opportunityHelper.getParentAccountId(opportunityId), opportunityHelper.getCloseDate(opportunityId))  
                    ){
                    Opportunity opportunity = opportunityHelper.getOpportunity(opportunityId);
                    Product2 product = opportunityHelper.getStorefrontPackage(opportunityId);
                    OrderItem orderItem = opportunityHelper.hasCPQProducts(opportunityId) ? opportunityHelper.getCPQStorefrontPackage(opportunityId) : null;                    
                    caseForParentId.put(opportunityHelper.getParentAccountId(opportunityId),
                        new Case(
                            RecordTypeId = CDdMxSxConstants.RECORD_TYPE_ID_CASE_STOREFRONT_ONBOARDING,
                            Opportunity_Name__c = opportunityId,
                            AccountId = opportunityHelper.getParentAccountId(opportunityId),
                            Origin = opportunityHelper.isSelfServe(opportunityId) ? CDdMxSxConstants.CASE_ORIGIN_OPP_CLOSED_WON_SSMO : CDdMxSxConstants.CASE_ORIGIN_OPP_CLOSED_WON,
                            Op_Owner__c = opportunity.OwnerId,
                            Decision_Maker__c = opportunity.Decision_Maker__c,
                            ContactId = opportunity.Store_Manager__c,
                            Status = CDdMxSxConstants.CASE_STATUS_OPEN,
                            Stage__c = CDdMxSxConstants.CASE_STAGE_NOT_STARTED,
                            Segment__c = opportunityHelper.getSegment(opportunityId),
                            ProductId = product.Id,
                            Product_Family_Text__c = product.Family,
                            Product_Name_Text__c = product.Name,
                            Order_Product__c = (orderItem != null ? orderItem.Id : null),                            
                            OwnerId = (opportunityHelper.isSelfServe(opportunityId) && !opportunityHelper.isPactSafeContractTypeSSMOSignUpSheet(opportunityId))
                                        ? CDdMxSxConstants.QUEUE_ID_STOREFRONT_IMPLEMENTATION_CALL_MOS
                                        : CDdMxSxConstants.RECORD_TYPE_ID_OPPORTUNITY_POST_SALE.equals(opportunity.RecordTypeId)? 
                                          CDdMxSxConstants.QUEUE_ID_STOREFRONT_UNDER_REVIEW_MXS : CDdMxSxConstants.QUEUE_ID_STOREFRONT_CASE_HOLDING_QUEUE,
                            Date_Time_Case_Became_Workable__c = ((opportunityHelper.isSelfServe(opportunityId) && !opportunityHelper.isPactSafeContractTypeSSMOSignUpSheet(opportunityId)) || CDdMxSxConstants.RECORD_TYPE_ID_OPPORTUNITY_POST_SALE.equals(opportunity.RecordTypeId)) ? System.now() : null
                        )
                    );
                }
            }
            if (!caseForParentId.isEmpty()){
                List<Database.SaveResult> sResults = Database.insert(caseForParentId.values(), false);
                errorMessages = CDdErrorUtilities.processSaveResults(sResults, errorMessages); 
                CDdMxSxException.logDmlErrors(CDdMxSxException.DML_OPERATION_INSERT, CLASS_NAME, METHOD_NAME, String.valueOf(CDdMxSxConstants.MXSX_EVENT.OPPORTUNITY_CLOSED_WON), LoggingLevel.ERROR, CDdMxSxConstants.SOBJECT_TYPE_OPPORTUNITY, 'Opportunity_Name__c', errorMessages, caseForParentId.values());        
            }
        } catch (Exception e) {
            errorMessages.add(e.getStackTraceString());
            throw new CDdMxSxException(e);
        } finally {
            if (!errorMessages.isEmpty()) { CDdErrorUtilities.createApexLogs(errorMessages, CLASS_NAME, METHOD_NAME, LoggingLevel.ERROR); }
        }            
    }
    /** 
     * @description Create Post-Sale Activation Cases
     * - Ensure Opportunity is in Closed Won stage and has Renegotiated Storefront Pricing
     * - Do not generate Post Activation Case, if Bulk Activation is set on the Opportunity
     * @param 
     * @return void
     */ 
    public void createPosActivationCases(){
        String METHOD_NAME = 'createPosActivationCases';
        Map<Id, Case> caseForOpportunityId = new Map<Id, Case>();
        List<String> errorMessages = new List<String>();
        try {        
            for (Id opportunityId : this.opportunityIds){
                Opportunity opportunity = opportunityHelper.getOpportunity(opportunityId);
                if (opportunityHelper.isClosedWon(opportunityId)
                    && !opportunity.Bulk_Activation__c
                    && !opportunityHelper.hasPostSalesActivationCaseForStorefrontBundle(opportunityId)
                    && opportunityHelper.hasRenegotiatedStorefrontPricing(opportunityId)
                ){
                    Product2 product = opportunityHelper.getStorefrontPackage(opportunityId);
                    OrderItem orderItem = opportunityHelper.hasCPQProducts(opportunityId) ? opportunityHelper.getCPQStorefrontPackage(opportunityId) : null;
                    Case caseObj = new Case(
                            RecordTypeId = CDdMxSxConstants.RECORD_TYPE_ID_CASE_POST_SALE_ACTIVATIONS,
                            Opportunity_Name__c = opportunityId,
                            AccountId = opportunity.AccountId,
                            ContactId = opportunity.Decision_Maker__c,
                            OwnerId = CDdMxSxConstants.QUEUE_ID_STOREFRONT_POST_SALE_ACTIVATIONS,
                            Origin = opportunityHelper.isSelfServe(opportunityId) ? CDdMxSxConstants.CASE_ORIGIN_OPP_CLOSED_WON_SSMO : CDdMxSxConstants.CASE_ORIGIN_OPP_CLOSED_WON,
                            Op_Owner__c = opportunity.OwnerId,
                            Decision_Maker__c = opportunity.Decision_Maker__c,
                            Activation_Notes__c = opportunity.Notes__c,
                            BusinessHoursId = CDdMxSxConstants.BUSINESS_HOURS_DEFAULT.Id,
                            ProductId = product.Id,
                            Product_Family_Text__c = product.Family,
                            Product_Name_Text__c = product.Name,
                            Priority = product.Priority_for_Activation__c,
                            Order_Product__c = (orderItem != null ? orderItem.Id : null)
                    );
                    if ((orderItem == null) || (orderItem.SBQQ__QuoteLine__r.SBQQ__Quote__r.Contract_Signed_Date__c == null) || (orderItem.SBQQ__QuoteLine__r.SBQQ__Quote__r.Contract_Signed_Date__c < Date.today())) {
                        caseObj.Due_Date__c = Date.today().addDays(2);                    
                    } else {
                        caseObj.Due_Date__c = orderItem.SBQQ__QuoteLine__r.SBQQ__Quote__r.Contract_Signed_Date__c.addDays(2);                    
                    }
                    caseForOpportunityId.put(opportunityId, caseObj);                    
                }            
            }
            if (!caseForOpportunityId.isEmpty()){
                List<Database.SaveResult> sResults = Database.insert(caseForOpportunityId.values(), false);
                errorMessages = CDdErrorUtilities.processSaveResults(sResults, errorMessages); 
                CDdMxSxException.logDmlErrors(CDdMxSxException.DML_OPERATION_INSERT, CLASS_NAME, METHOD_NAME, String.valueOf(CDdMxSxConstants.MXSX_EVENT.OPPORTUNITY_CLOSED_WON), LoggingLevel.ERROR, CDdMxSxConstants.SOBJECT_TYPE_OPPORTUNITY, 'Opportunity_Name__c', errorMessages, caseForOpportunityId.values());        
            }
        } catch (Exception e) {
            errorMessages.add(e.getStackTraceString());
            throw new CDdMxSxException(e);
        } finally {
            if (!errorMessages.isEmpty()) { CDdErrorUtilities.createApexLogs(errorMessages, CLASS_NAME, METHOD_NAME, LoggingLevel.ERROR); }
        }              
    }
    /** 
     * @description Update Case records
     * - BZAP-12008 - Update Cases records with Opportunity Owner, if Op Owner is indicated on the Case and does not match with corresponding Opportunity Owner
     * @param 
     * @return void
     */ 
    public void updateCases(){
        String METHOD_NAME = 'updateCases';
        Map<Id, List<Case>> casesForOpportunities  = CDdMxSxCaseHelper.getCasesForOpportunities(this.opportunityIds);
        List<Case> casesToUpdate = new List<Case>();
        List<String> errorMessages = new List<String>();
        try {        
            for (Id opportunityId : casesForOpportunities.keySet()){
                Opportunity opportunity = opportunityHelper.getOpportunity(opportunityId);
                for (Case c : casesForOpportunities.get(opportunityId)){
                    Case caseToUpdate = new Case(Id = c.Id);
                    Boolean updateCase = false;
                    if (String.isNotBlank(c.Op_Owner__c) && !opportunity.OwnerId.equals(c.Op_Owner__c)){
                        caseToUpdate.Op_Owner__c = opportunity.OwnerId;
                        updateCase = true;
                    }
                    if (updateCase){
                        casesToUpdate.add(caseToUpdate);
                    }
                }
            }
            if (!casesToUpdate.isEmpty()){
                List<Database.SaveResult> sResults = Database.update(casesToUpdate, false);
                errorMessages = CDdErrorUtilities.processSaveResults(sResults, errorMessages); 
                CDdMxSxException.logDmlErrors(CDdMxSxException.DML_OPERATION_UPDATE, CLASS_NAME, METHOD_NAME, String.valueOf(CDdMxSxConstants.MXSX_EVENT.OPPORTUNITY_RELATED_CASE_UPDATES), LoggingLevel.ERROR, CDdMxSxConstants.SOBJECT_TYPE_OPPORTUNITY, 'Opportunity_Name__c', errorMessages, casesToUpdate);        
            }
        } catch (Exception e) {
            errorMessages.add(e.getStackTraceString());
            throw new CDdMxSxException(e);
        } finally {
            if (!errorMessages.isEmpty()) { CDdErrorUtilities.createApexLogs(errorMessages, CLASS_NAME, METHOD_NAME, LoggingLevel.ERROR); }
        }              
    }    
}