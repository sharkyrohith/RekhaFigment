/**
 * @author Mahesh Chouhan
 * @date   Jan 2023
 * @decription Wrapper used by Project Horizon to Store Workflow Action for Email Alert and Task Creation
 */

public class CDdWorkflowAction {
    //Generic fields
    @AuraEnabled
    public String type;
    @AuraEnabled
    public String objectApiName;

    //Task fields
    @AuraEnabled
    public String taskStatus;
    @AuraEnabled
    public String taskSubject;
    @AuraEnabled
    public String taskPriority;
    @AuraEnabled
    public String taskComments;
    @AuraEnabled
    public Date taskDueDate;
    @AuraEnabled
    public String taskOwner;

    //Email fields
    @AuraEnabled
    public String emailAlertName;
}