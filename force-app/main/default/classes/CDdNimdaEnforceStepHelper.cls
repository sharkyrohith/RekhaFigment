/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 12/25/2019
*
* @group Nimda
*
* @description Helper class for functionality related to enforcing Nimda Steps during Onboarding
*   
**************************************************************************************************************************************/
public class CDdNimdaEnforceStepHelper {
    public static final String SOBJECT_TYPE_ACCOUNT = 'Account';
    public static final String SOBJECT_TYPE_OPPORTUNITY = 'Opportunity';
    private Opportunity opportunity; 
    private Account account; 
    private Account parentAccount;
    private List<Nimda_Enforce_Step__mdt> nimdaEnforceSteps;
    /**
     * Constructor
     */
    public CDdNimdaEnforceStepHelper(String opportunityId, String onboardingStep){
        this.nimdaEnforceSteps = new List<Nimda_Enforce_Step__mdt>();
        Map<String, Set<String>> sObjectTypeFieldMap = new Map<String, Set<String>>{
            SOBJECT_TYPE_ACCOUNT => new Set<String>(),
            SOBJECT_TYPE_OPPORTUNITY => new Set<String>()
        };        
        for (Nimda_Enforce_Step__mdt s : [SELECT Id, MasterLabel, DeveloperName, Active__c, Sequence__c,
                                                    Onboarding__c, Nimda_Step__c, SObjectType__c, SObjectField__c, 
                                                    Enforce_Condition__c, Can_Clear_Field_To_Enforce_Step__c 
                                                    FROM Nimda_Enforce_Step__mdt
                                                    WHERE Active__c = true
                                                    AND Onboarding__c = :onboardingStep 
                                                    ORDER BY Sequence__c ASC]){
            this.nimdaEnforceSteps.add(s);
            sObjectTypeFieldMap.get(s.SObjectType__c).add(s.SObjectField__c);
        }        
        this.opportunity = this.getOpportunity(opportunityId, sObjectTypeFieldMap);
        this.account = (Account)opportunity.getSObject(SOBJECT_TYPE_ACCOUNT);
        if (this.account.isSet('ParentId')){
            this.parentAccount = (Account)account.getSObject('Parent');
        }        
    }
    public List<SObject> prepareSObjectsForOnboarding(Opportunity opportunityToProcess){
        List<SObject> retVal = new List<SObject>();
        Opportunity retOpportunity = opportunityToProcess;
        retOpportunity.Id = this.opportunity.Id;        
        Account retAccount = null;
        for (NimdaStep nimdaStep : this.getNimdaSteps()){
            if (nimdaStep.isStepSkipped && nimdaStep.allowedToClearField){
                for (String sObjectField :  nimdaStep.fieldsResponsibleForSkip){
                    if (CDdNimdaEnforceStepHelper.SOBJECT_TYPE_OPPORTUNITY.equals(nimdaStep.getSObjectType(sObjectField))){
                        retOpportunity.put(nimdaStep.getSObjectFieldApi(sObjectField), null);
                    }
                    if (CDdNimdaEnforceStepHelper.SOBJECT_TYPE_ACCOUNT.equals(nimdaStep.getSObjectType(sObjectField))){
                        if (retAccount == null){
                            retAccount = new Account(Id = this.account.Id);
                        }
                        retAccount.put(nimdaStep.getSObjectFieldApi(sObjectField), null);
                    }                        
                }
            }
        }
        retVal.add(retOpportunity);
        if (retAccount!=null){
            retVal.add(retAccount);
        }
        return retVal;
    }
    public List<NimdaStep> getNimdaSteps(){
        List<NimdaStep> retVal = new List<NimdaStep>();

        Set<String> orderedNimdaSteps = new Set<String>();
        Set<String> nimdaStepsToExecute = new Set<String>();
        Set<String> nimdaStepsToSkip = new Set<String>();

        Map<String, Set<String>> nimdaStepFieldsResponsibleForEnforce = new Map<String, Set<String>>();
        Map<String, Set<String>> nimdaStepFieldsResponsibleForSkip = new Map<String, Set<String>>();
        Map<String, Boolean> nimdaStepAllowedToClearFields = new Map<String, Boolean>();

        for (Nimda_Enforce_Step__mdt s : this.nimdaEnforceSteps){
            SObject sObj;
            String field;
            if (SOBJECT_TYPE_ACCOUNT.equals(s.SObjectType__c)){
                if (s.SObjectField__c.startsWith('Parent.')){
                    sObj = this.parentAccount;
                    field = s.SObjectField__c.substringAfter('.');
                } else {
                    sObj = this.account;
                    field = s.SObjectField__c;
                }
            }
            if (SOBJECT_TYPE_OPPORTUNITY.equals(s.SObjectType__c)){
                sObj = this.opportunity;
                field = s.SObjectField__c;                    
            }
            // Determine when the step will execute and when it will be skipped
            if (sObj!=null && field!=null && sObj.isSet(field)){
                Boolean conditionMetToExecute = false;
                Boolean fieldSetupToExecute = false;
                switch on s.Enforce_Condition__c {
                    when 'IS NULL', 'OR IS NULL' {
                        if (sObj.get(field)==null){
                            conditionMetToExecute = true;
                            fieldSetupToExecute = true;
                        }
                    }
                    when 'IS NOT NULL' {
                        if (sObj.get(field)!=null){
                            conditionMetToExecute = true;
                            fieldSetupToExecute = true;
                        }
                    }
                    when 'AND IS NULL' {
                        if (sObj.get(field)==null){
                            //if already in steps to execute bucket, then good
                            if (nimdaStepsToExecute.contains(s.Nimda_Step__c)){
                                conditionMetToExecute = true;
                            }
                            fieldSetupToExecute = true;
                        } 
                    }
                }
                if (conditionMetToExecute){
                    nimdaStepsToExecute.add(s.Nimda_Step__c);
                    nimdaStepsToSkip.remove(s.Nimda_Step__c);
                } else {
                    nimdaStepsToSkip.add(s.Nimda_Step__c);
                    nimdaStepsToExecute.remove(s.Nimda_Step__c);
                }
                if (fieldSetupToExecute){
                    addNimdaStep(nimdaStepFieldsResponsibleForEnforce, s.Nimda_Step__c, s.SObjectType__c + '.' + s.SObjectField__c);
                } else {
                    addNimdaStep(nimdaStepFieldsResponsibleForSkip, s.Nimda_Step__c, s.SObjectType__c + '.' + s.SObjectField__c);
                }                    
            }
            orderedNimdaSteps.add(s.Nimda_Step__c);
            // Configuration should be setup such that all fields need to clearable for a Nimda Step
            nimdaStepAllowedToClearFields.put(s.Nimda_Step__c, s.Can_Clear_Field_To_Enforce_Step__c);
        }
        for (String nimdaStep: orderedNimdaSteps){
            retVal.add(
                new NimdaStep(
                    nimdaStep, 
                    nimdaStepsToSkip.contains(nimdaStep),
                    nimdaStepFieldsResponsibleForSkip.get(nimdaStep),
                    nimdaStepAllowedToClearFields.get(nimdaStep)
                )
            );            
        }
        return retVal;
    }
    private Opportunity getOpportunity(String opportunityId, Map<String, Set<String>> sObjectTypeFieldMap){
        Opportunity opportunity = null;
        String query = 'SELECT Id, Account.Id ';
        for (String field : sObjectTypeFieldMap.get(SOBJECT_TYPE_OPPORTUNITY)){
            query += ',' + field;
        }
        for (String field : sObjectTypeFieldMap.get(SOBJECT_TYPE_ACCOUNT)){
            query += ',' + SOBJECT_TYPE_ACCOUNT + '.' + field;
        }
        query += ' FROM ' + SOBJECT_TYPE_OPPORTUNITY + ' WHERE Id = :opportunityId';
        for (Opportunity o : Database.query(query)){
            opportunity = o;
        }   
        return opportunity;
    }    
    private void addNimdaStep(Map<String, Set<String>> nimdaStepMap, String nimdaStep, String sObjectTypeAndField){
        if (nimdaStepMap.containsKey(nimdaStep)){
            nimdaStepMap.get(nimdaStep).add(sObjectTypeAndField);
        } else {
            nimdaStepMap.put(nimdaStep, new Set<String>{sObjectTypeAndField});
        }
    }
    public class NimdaStep {
        @AuraEnabled
        public String label { get; set; }
        @AuraEnabled
        public Boolean isStepSkipped { get; set; } 
        @AuraEnabled
        public Set<String> fieldsResponsibleForSkip { get; set; }
        @AuraEnabled
        public Boolean allowedToClearField { get; set; }        
        public NimdaStep(String label, Boolean isStepSkipped, Set<String> fieldsResponsibleForSkip, Boolean allowedToClearField){
            this.label = label;
            this.isStepSkipped = isStepSkipped;
            this.fieldsResponsibleForSkip = fieldsResponsibleForSkip;
            this.allowedToClearField = allowedToClearField;
        }
        public String getSObjectType(String fieldResponsibleForSkip){
            return (String.isNotBlank(fieldResponsibleForSkip) ? fieldResponsibleForSkip.substringBefore('.') : null);
        }
        public String getSObjectFieldApi(String fieldResponsibleForSkip){
            return (String.isNotBlank(fieldResponsibleForSkip) ? fieldResponsibleForSkip.substringAfter('.') : null);
        }        
    }
}