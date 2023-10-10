/********************************************************************************************************************
* @author criticalriver
* @date 06/2022
* @description Batch class to reassign the Open cases to previous queue
**************************************************************************************************************************************/

public with sharing class CDdDeactivateUserCaseAssign implements Database.Batchable<sObject> {
    public list<Id> userIds;
    private List<String> errors;

    public CDdDeactivateUserCaseAssign(List<Id> deactivatedUserIds) {
        userIds = new list<Id>();
        errors = new List<String>();
        this.userIds=deactivatedUserIds;
    }
    public Database.QueryLocator start(Database.BatchableContext BC)
    {
        //Getting record Id for Tablet Request Case
        Id tabletRequestRecordId = CDdGenericTriggerOptimizationHelper.tabletRequestRecordTypeId;

        String query =  'SELECT ' +
                'Id, OwnerId, Previous_Queue_ID__c, Initial_Queue__c '+
                'FROM Case '+
                'WHERE OwnerId IN: userIds '+
                'AND (Previous_Queue_ID__c != null '+
                'OR Initial_Queue__c != null) '+
                'AND ((Status NOT IN ( \'Closed\',\'Solved\',\'Received\') AND RecordTypeId !=: tabletRequestRecordId)'+
            	'OR (Status NOT IN ( \'Shipped\',\'Received\',\'Duplicate\',\'Error\',\'Dead\',\'Rejected\') AND RecordTypeId =: tabletRequestRecordId))';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC,List<sObject> scope)
    {
        list<Case> updateCaseRecords = new List<Case>();
        List<String> errorMessages = new List<String>();
        for(case s: (list<case>) scope)
        {
            if(s.Previous_Queue_ID__c != null){
                s.OwnerId = s.Previous_Queue_ID__c;
                updateCaseRecords.add(s);
            }else if(s.Initial_Queue__c != null){
                s.OwnerId = s.Initial_Queue__c;
                updateCaseRecords.add(s);
            }
        }
        try{
            if(!updateCaseRecords.isEmpty() && updateCaseRecords != null){
                Database.SaveResult[] caseUpdates = Database.update(updateCaseRecords,false);
                errorMessages = CDdErrorUtilities.processSaveResults(caseUpdates, errorMessages);
             }
        }
        catch(Exception ex) {
            CDdErrorUtilities.createApexLogs(new List<String>{ex.getMessage()}, 'CDdDeactivateUserCaseAssign', 'CDdDeactivateUserCaseAssign', LoggingLevel.ERROR);
        }
        if(!errorMessages.isEmpty()){
            this.errors.addAll(errorMessages);
        }
    }
    public void finish(Database.BatchableContext BC)
    {
        if(!this.errors.isEmpty()){
            CDdErrorUtilities.createApexLogs(this.errors, 'CDdDeactivateUserCaseAssign');
        }
    }
}