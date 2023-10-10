/**
 * @description       : Implementation class of Milestone generation for sObject Type Case and record type Storefront Onboarding
 * @author            : @ebby
 * @group             : Milestone
 * @last modified on  : 11-01-2021
**/
public with sharing class CDdCaseMilestoneStorefrontOnboarding extends CDdMilestoneGeneratorImpl {
    public static final String CLASS_NAME = 'CDdCaseMilestoneStorefrontOnboarding';
    public static final Id SELFSERVINTEGRATIONUSER = [SELECT Id, Name, alias FROM User WHERE alias = 'selfserv'].Id;

    public static final String STOREFRONT_RT_NAME = 'Storefront';

    public static final Id PRODUCT_DETAILS_STOREFRONT_RT {get {
        if(PRODUCT_DETAILS_STOREFRONT_RT == null) {
            PRODUCT_DETAILS_STOREFRONT_RT = Schema.SObjectType.Product_Detail__c.getRecordTypeInfosByDeveloperName().get(STOREFRONT_RT_NAME).getRecordTypeId();
        }
        
        return PRODUCT_DETAILS_STOREFRONT_RT;
    } set;}

    // Storefront Implementation Types
    public static final String GOOGLE_FOOD = 'Google Food Ordering Only';
    public static final String SOCIAL_MEDIA = 'Social Media Implementation Only';
    public static final String SMART_BTN = 'Smart Button Implementation';
    public static final String WEBSITE = 'Website Link Implementation';

    public static Map<Id, Product_Detail__c> storefrontDetailsPerOpportunity = new Map<Id, Product_Detail__c>(); 

    // Milestone Names
    public static final String REVIEW_TRIAGE = 'Review & Triage';
    public static final String SETUP_STORE_PRICING = 'Setup Store Pricing';
    public static final String SETUP_STOREFRONT_PAGE = 'Setup Storefront Page';
    public static final String IMPLEMENTATION_CALL = 'Implementation Call';
    public static final String LINK_IMPLEMENTATION = 'Link Implementation';
    public static final String LINK_OPTIMIZATION = 'Link Optimization';    
    
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
        for (Case c : getCases()){
            eligibleConditionalMilestoneTemplatesForCase.put(c.Id, new List<Milestone_Template__c>());

            Id templateVersionId = milestoneVersionIdByParentId.get(c.Id);
            List<Milestone_Template__c> templates = CONDITIONAL_MILESTONE_TEMPLATES_BY_VERSION.get(templateVersionId).values();

            for (Milestone_Template__c template : templates) {
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
                Id,
                RecordTypeId,
                Origin,
                Opportunity_Name__c,
                Opportunity_Name__r.PactSafe_Contract_Type__c 
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
        Boolean isApplicable = true;
        
        Product_Detail__c storefrontDetails = getStorefrontDetailsFromCase(c.Opportunity_Name__c);
        Boolean isGoogleFood = storefrontDetails.Implementation_Type__c == GOOGLE_FOOD;
        Boolean isSocialMedia = storefrontDetails.Implementation_Type__c == SOCIAL_MEDIA;
        Boolean isSmartButton = storefrontDetails.Implementation_Type__c == SMART_BTN;
        Boolean isWebsite = storefrontDetails.Implementation_Type__c == WEBSITE;
        // Sometimes, at the time of creation, there will not be an Implementation Type. These Cases should receive 
        // ALL the Milestones, and then be re-evaluated later when Implementation Type changes.
        Boolean noImplementationType = String.isBlank(storefrontDetails.Implementation_Type__c);
        
        switch on template.Milestone_Type__c {
            when 'Implementation Call' {
                isApplicable = isSocialMedia || isSmartButton || isWebsite || noImplementationType;
            }
            when 'Link Implementation' {
                isApplicable = isSocialMedia || isSmartButton || isWebsite || noImplementationType;
            }
            when 'Link Optimization' {
                isApplicable = isSmartButton || isWebsite || noImplementationType;
            }
        }

        return isApplicable;
    }

    /**
        @author: Dan Thoreson
        @date: 13-Sep-2022
        @description: From an inputted Case, retrieve the Product_Detail__c record from the Storefront 
                      Opportunity. These are linked to Storefront Opportunities in a 1:1 manner. 
    **/
    public static Product_Detail__c getStorefrontDetailsFromCase(Id opportunityId) {
        if(storefrontDetailsPerOpportunity.containsKey(opportunityId)) {
            return storefrontDetailsPerOpportunity.get(opportunityId);
        }

        List<Product_Detail__c> productDetails = new List<Product_Detail__c>();

        productDetails = [SELECT Id, Name, CurrencyIsoCode, Implementation_Owner__c, Implementation_Type__c, Mx_Website_Link__c, Opportunity__c,
                                Partnership_Type__c, RecordTypeId, Storefront_Proposed_Date_of_Activation__c, Web_Provider__c, Website_Creation_Needed__c
                            FROM Product_Detail__c
                            WHERE Opportunity__c = :opportunityId
                            AND RecordTypeId = :PRODUCT_DETAILS_STOREFRONT_RT
                            ORDER BY CreatedDate DESC];

        // Add to static map so we don't have to retrieve it each time
        Product_Detail__c storefrontDetailsForOpp = (!productDetails.isEmpty()) ? productDetails[0] : new Product_Detail__c();
        storefrontDetailsPerOpportunity.put(opportunityId, storefrontDetailsForOpp);

        return storefrontDetailsForOpp;
    }
}