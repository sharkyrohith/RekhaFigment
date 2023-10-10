/**
 * @author:     Mahesh Chouhan
 * @date:       July 2023
 * @description Use Project Horizon for performing Workflow updates
 */
public without sharing class CTrClaimProjectHorizon extends CDdTriggerHandler {

    /**
     * @description Constructor
     */
    public CTrClaimProjectHorizon() {}

    List<Claim__c> newList = (List<Claim__c>)triggerList;
    Map<Id, Claim__c> oldMap = (Map<Id, Claim__c>)triggerOldMap;

    /**
     * @description Overriden event handlers..
     */
    public override void beforeInsert() {
        CDdWorkflowConfigEvaluator.executeWorkflows(newList, null);
    }

    public override void beforeUpdate() {
        CDdWorkflowConfigEvaluator.executeWorkflows(newList, oldMap);
    }

    public override void afterInsert() {
        CDdWorkflowConfigEvaluator.executeWorkflows(newList, null);
    }

    public override void afterUpdate() {
        CDdWorkflowConfigEvaluator.executeWorkflows(newList, oldMap);
    }
}