/**
 * @description       : Implementation class of Milestone generation for sObject Type Case and record type POSIntegrations
 * @author            : @lathika
 * @group             : Milestone
 * @last modified on  : 12-12-2021
**/
public with sharing class CDdCaseMilestonePOSIntegrations extends CDdMilestoneGeneratorImpl {
    public static final String CLASS_NAME = 'CDdCaseMilestonePOSIntegrations';
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
                Origin, POS_Integration_Type__c, Activation_Method__c  
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
        return false;
    }       
}