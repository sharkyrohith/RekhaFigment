/**
 * @author Mahesh Chouhan
 * @date   Jan 2023
 * @decription Wrapper used by Project Horizon to store workflow action to be performed for a record
 */

public class CDdWorkflowConfigRequest {
    @AuraEnabled
    public String recordId;
    @AuraEnabled
    public List<CDdWorkflowAction> workflowTasks;
}