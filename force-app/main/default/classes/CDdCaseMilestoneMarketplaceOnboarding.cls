/********************************************************************************************************************
* @author Sriram
* @date 08/05/2021
*
* @group Milestone
*
* @description Implementation class of Milestone generation for sObject Type Case and record type Marketplace Onboarding
* This class is primarily responsible to determime the eligibility of conditional milestones
* 
* Updates
* 06/29/2022    Nathalie Mendezona          Added 'Alcohol license' in the switch statement - BZAP-15925
**************************************************************************************************************************************/
public class CDdCaseMilestoneMarketplaceOnboarding extends CDdMilestoneGeneratorImpl {
    public static final String CLASS_NAME = 'CDdCaseMilestoneMarketplaceOnboarding';
    public static final List<String> COMPLETED_BY_NOT_ELIGIBLE_SM_MILESTONE = new List<String> { 'Account Owner', 'None - Menu Setup Complete' };
    public static final List<String> ORDER_PROTOCOLS_FOR_DELIVER_TABLET = new List<String> {
            'Tablet (DoorDash Owns)',
            'Tablet and Printer (DoorDash Owns)',
            'POS and and Tablet (DoorDash Owns)',
            'POS and Tablet Return Label'
    };
    public static final String POS_INTEGRATION_TYPE_NON_INTEGRATED_MX = 'non_integrated_mx';
    public static final String MENU_UI_TYPE_RETAIL = 'Retail';
    public static Map<Id, Business_Vertical__c> BUSINESS_VERTICAL_MAP = CDdAccountHelperMethods.BUSINESS_VERTICAL_MAP;
    public CDdMxSxOpportunityHelper opportunityHelper;

    // Marketplace Onboarding Milestone names
    public static final String REVIEW_TRIAGE = 'Review & Triage';
    public static final String SETUP_STORE = 'Setup Store';
    public static final String SETUP_BANKING = 'Setup Banking';
    public static final String SETUP_CUSTOM_DELIVERY_RADIUS = 'Setup Custom Delivery Radius';
    public static final String SETUP_BUSINESS = 'Setup Business';
    public static final String SETUP_MENU = 'Setup Menu';
    public static final String SETUP_CATALOG = 'Setup Catalog';
    public static final String GRANT_PORTAL_ACCESS = 'Grant Portal Access';
    public static final String SETUP_POS_INTEGRATION = 'Setup POS Integration';
    public static final String STORE_POS_INT_SETUP = 'Store & POS Integration Setup';
    public static final String INGEST_POS_MENU = 'Ingest POS Menu';
    public static final String DELIVER_TABLET = 'Deliver Tablet';
    public static final String ACTIVATIONS_CHECKLIST = 'Activations Checklist';
    public static final String POS_TEST_METHOD = 'POS Test Method';
    public static final String ACTIVATION_OUTREACH = 'Activation Outreach';
    public static final String ACTIVATE_STORE = 'Activate Store';
    public static final String ALCOHOL_LICENSE = 'Alcohol License';
    public static final String ADS_PROMOS = 'Ads & Promos';

    // @TODO: BZAP-18330 - Needs to removed once we have the Logic to identify the products to exclude for Ads & Promos
    public static final List<String> ADS_PROMOS_PRODUCTS_IDS_TO_EXCLUDE = System.Label.Mx_Ads_Promos_Products_to_Exclude.split(',');

    public static final String SETUP_POS_RT_DEV_NAME = 'Setup_POS_Integration';

    /**
     * Default constructor
     */        
    public CDdCaseMilestoneMarketplaceOnboarding() {
    }
    /**
     * @description Return the implementation class name
     * @return String
     */      
    public override String getClassName(){
        return CLASS_NAME;
    }   
    /**
     * @description Return the conditional milestones for the parent sObject Ids
     * 1. Retrieve the eligible conditional milestone templates
     * 2. For each Parent sObject record
     * a. Run a comparison check of the milestone templates against existing milestone templates
     * b. Prepare a collection of miletone templates that do not already exist for that Parent sObject record
     * c. Prepare and return the Collection of milestone records for the milestone templates from previous step
     * @return List<Milestone__c>  
     */      
    public override List<Milestone__c> getConditionalMilestones() {
        List<Milestone__c> milestones = new List<Milestone__c>();
        Map<Id, List<Milestone_Template__c>> conditionalMilestoneTemplates = getConditionalMilestoneTemplates();
        for (Id parentSObjectId : this.parentSObjectIds){
            if (conditionalMilestoneTemplates.containskey(parentSObjectId) && !conditionalMilestoneTemplates.get(parentSObjectId).isEmpty()){
                milestones.addAll(getMilestones(parentSObjectId, conditionalMilestoneTemplates.get(parentSObjectId)));
            }            
        }
        return milestones;        
    }

    /**
     * Retrieve the eligible conditional milestone templates for the individual Case records
     * @return Map<Id, List<Milestone_Template__c>> Return a collection of eligible conditional milestone templates for each Case record
     */       
    public Map<Id, List<Milestone_Template__c>> getConditionalMilestoneTemplates(){
        Map<Id, List<Milestone_Template__c>> eligibleConditionalMilestoneTemplatesForCase = new Map<Id, List<Milestone_Template__c>>(); 
        List<Case> cases = getCases();
        Set<Id> opportunityIds = getOpportunityIdsFromCases(cases);
        opportunityHelper = new CDdMxSxOpportunityHelper(opportunityIds);
        for (Case c : cases){
            eligibleConditionalMilestoneTemplatesForCase.put(c.Id, new List<Milestone_Template__c>());

            for (Milestone_Template__c template : CONDITIONAL_MILESTONE_TEMPLATES_BY_VERSION.get(milestoneVersionIdByParentId.get(c.Id)).values()) {
                if (this.isTemplateApplicable(template, c)){
                    eligibleConditionalMilestoneTemplatesForCase.get(c.Id).add(template);
                }
            }
        }
        return eligibleConditionalMilestoneTemplatesForCase;
    }
    /**
     * Retrieve the Case records to determine the eligibility for conditional milestones
     * @return Map<Id, Case> Return a collection of Case record
     */    
    public List<Case> getCases(){
        return new List<Case>(
            [
                SELECT
                Activate_Centrally2__c,
                Opportunity_Name__r.Account.Alcohol_Addendum_Signed__c,
                Opportunity_Name__r.Account_Billing_Country__c,
                Opportunity_Name__r.Activate_Centrally_2__c,
                Opportunity_Name__r.Menu_to_be_completed_by__c,
                Opportunity_Name__r.Mx_Requested_Custom_Radius_Demand_Gen__c,
                Opportunity_Name__r.Order_Protocol__c,
                Opportunity_Name__r.POS_Integration_Type__c,
                Opportunity_Name__r.Tablet_Delivery_Method__c,
                Opportunity_Name__c,
                RecordTypeId,
                Segment__c,
                Account.Parent.Business_Vertical__c
                FROM Case
                WHERE Id IN :this.parentSObjectIds
                AND RecordTypeId = :this.parentSObjectRecordTypeId
            ]
        );
    }
    
    /**
     * Evaluate whether a conditional template is applicable to a given parent.
     * @param template the conditional template
     * @param c the parent
     * @return Boolean indicating whether the template is applicable
     */
    public Boolean isTemplateApplicable(Milestone_Template__c template, Case c) {
        Boolean isApplicable = false;
        Opportunity opp = c.Opportunity_Name__r;
        Boolean isPOS = opp.Order_Protocol__c != null && opp.Order_Protocol__c.contains('POS');
        Boolean isPOSNonIntegratedMx = isPOS && String.isNotBlank(opp.POS_Integration_Type__c) && POS_INTEGRATION_TYPE_NON_INTEGRATED_MX.equals(opp.POS_Integration_Type__c);
        Boolean posMilestonesNeeded = isPOS && !isPOSNonIntegratedMx;
        Id businessVerticalId = c.Account.Parent.Business_Vertical__c;
        Boolean isRetail = (businessVerticalId != null) && BUSINESS_VERTICAL_MAP.containsKey(businessVerticalId) && MENU_UI_TYPE_RETAIL.equals(BUSINESS_VERTICAL_MAP.get(businessVerticalId).Menu_UI_Type__c);

        switch on template.Milestone_Type__c {
            when 'Setup Menu' {
                if ((!isPOS && !COMPLETED_BY_NOT_ELIGIBLE_SM_MILESTONE.contains(opp.Menu_to_be_completed_by__c)) || isPOSNonIntegratedMx) {
                    isApplicable = true;
                }
            }
            when 'Setup POS Integration', 'Store & POS Integration Setup', 'Ingest POS Menu' {
                if (posMilestonesNeeded) {
                    isApplicable = true;
                }
            }
            when 'POS Test Method' {
                if(posMilestonesNeeded && CDdI18nUtility.isCountryNewZealand(opp.Account_Billing_Country__c)) {
                    isApplicable = true;
                }
            }
            when 'Setup Custom Delivery Radius' {
                if (opp.Mx_Requested_Custom_Radius_Demand_Gen__c == 'Yes') {
                    isApplicable = true;
                }
            }
            when 'Deliver Tablet' {
                if (opp.Tablet_Delivery_Method__c == 'Drop-Ship' && ORDER_PROTOCOLS_FOR_DELIVER_TABLET.contains(opp.Order_Protocol__c)) {
                    isApplicable = true;
                }
            }
            when 'Activation Outreach' {
                if (c.Segment__c == 'Local' && c.Activate_Centrally2__c == 'Yes') {
                    isApplicable = true;
                }
            }
            when 'Activate Store' {
                if (opp.Activate_Centrally_2__c == 'Yes') {
                    isApplicable = true;
                }
            }
            when 'Setup Catalog' {
                if (isRetail) {
                    isApplicable = true;
                }
            }
            when 'Ads & Promos' {
                if (isApplicableForAdsAndPromos(c.Opportunity_Name__c)){
                        isApplicable = true;
                }
            }               
            // BZAP-15925
            when 'Alcohol License' {
                if (opp.Account.Alcohol_Addendum_Signed__c && 
                    CDdI18nUtility.isCountryNewZealand(opp.Account_Billing_Country__c)) {
                    isApplicable = true;
                }
            }
        }
        
        return isApplicable;
    }    
    
    /**
     * Evaluate whether a conditional template is applicable to a given parent.
     * @param List<Case> cases list
     * @return Set<Id> opporunity Ids
    */
    private static Set<Id> getOpportunityIdsFromCases(List<Case> cases){
        Set<Id> opportunityIds = new Set<Id>();
        for(Case caseRec : cases){
            opportunityIds.add(caseRec.Opportunity_Name__c);
        }
        return opportunityIds;
    }

    public Boolean isApplicableForAdsAndPromos(Id OpportunityId){
        List<String> opportunityRelatedProductFamilies = getOpportunityRelatedProductFamilies(OpportunityId, new Set<Id>(new List<Id>( (List<Id>)ADS_PROMOS_PRODUCTS_IDS_TO_EXCLUDE)));
        for(String productFamily : CDdMxSxConstants.PRODUCT_FAMILIES_ADS_PROMOS){
            if (opportunityRelatedProductFamilies.contains(productFamily) 
                && opportunityRelatedProductFamilies.contains(CDdMxSxConstants.PRODUCT_FAMILY_MARKETPLACE)
                ) {
                    return true;
            }
        }
        return false;
    }

    /**
     * @TODO: BZAP-18330 - productsToExclude param to be removed once we have the Logic to identify the products to exclude for Ads & Promos
     * @description Filter the product familes required for Ads & Promos
     * @param Id opportunityId
     * @return Set<Id> productsToExclude
     */
    public List<String> getOpportunityRelatedProductFamilies(Id opportunityId,Set<Id> productsToExclude){
        List<String> opportunityRelatedProductFamilies = new List<String>();
        if (opportunityHelper.hasCPQProducts(opportunityId)){
            List<OrderItem> orderLineItemsByOpprtunityId = opportunityHelper.getCPQProducts(opportunityId);
            for (OrderItem oi : orderLineItemsByOpprtunityId) {
                if(productsToExclude != null && productsToExclude?.contains(oi.Product2Id)){
                   continue;
                }
                opportunityRelatedProductFamilies.add(oi.Product2.Family);
            }

        }
        return opportunityRelatedProductFamilies;
    }
}