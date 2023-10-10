/*
*
* @author: Narender Kurapati
* @date: 2021-04-12
* @description : THis batch class is used for deleting SObject records
*
*/

global class CDdBatchDeleteRecords implements Database.Batchable<sObject>, Database.Stateful, Schedulable{
    // variables
    global String query;
    global List<Id> recordIds;
    global integer totalNoOfRecords = 0;
    global integer noOfRecordsDeleted = 0;
    global string objName;
    global List<string> errorMessages = new List<string>();
    public static Map<String, Schema.SObjectType> SOBJECT_TYPES = Schema.getGlobalDescribe();

    // Constructor
    global CDdBatchDeleteRecords(String qry, string objectName) {
        query  = qry;
        objName = objectName;
        system.debug('Query...'+query);
        system.debug('Delete Batch Job of '+objectName+' isRunning');
    }
    // Constructor
    global CDdBatchDeleteRecords(List<Id> recIds, string objectName) {
        recordIds  = recIds;
        objName = objectName;
        system.debug('recordIds...'+recordIds.size()+',   '+recordIds);
        system.debug('Delete Batch Job of '+objectName+' isRunning');
    }

    // Start
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String finalQuery = '';

        if(String.isNotBlank(objName) && !objName.contains('__mdt')){
            SObjectType sObjectType = SOBJECT_TYPES.get(objName);
            if(sObjectType.getDescribe().isDeletable()){
                if(String.isBlank(query) && !recordIds.isEmpty()){
                    finalQuery = 'Select Id From '+objName+' where ID IN :recordIds';
                } else if(String.isNotBlank(query)){
                    finalQuery = query;
                }
            } else{
                errorMessages.add('User DO not have Delete permission on provided object : CDdBatchDeleteRecords Batch Job');
            }
        } else{

            if(String.isBlank(objName)){
                errorMessages.add('Provided object Name is blank in CDdBatchDeleteRecords Batch Job');
            }else if(objName.contains('__mdt')){
                errorMessages.add('Provided object is Custom Metadata Object and not allowed to Delete+ CDdBatchDeleteRecords Batch Job');
            }


        }
        // if errors create apex logs
        if(!errorMessages.isEmpty()){
            CDdErrorUtilities.createApexLogs(errorMessages, 'CDdBatchDeleteRecords');
            errorMessages.clear();
            System.abortJob(bc.getJobId());
            return null;

        }

        return Database.getQueryLocator(finalQuery);
    }

    // Execute
    global void execute( Database.BatchableContext bc, List<Sobject> scope) {
        try{
            List<Database.DeleteResult> drList = Database.delete(scope, false);
            List<string> deleteIds = new List<string>();

            // Iterate through each returned result
            for(Database.DeleteResult dr : drList) {
                if (dr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    deleteIds.add(dr.getId());
                }else{
                    // get the error details
                    for(Database.Error err : dr.getErrors()) {
                        errorMessages.add(err.getStatusCode() + ' : ' + err.getMessage() + ' : Fields : ' + err.getFields());
                    }
                }

            }
            // if errors create apex logs
            if(!errorMessages.isEmpty()){
                CDdErrorUtilities.createApexLogs(errorMessages, 'CDdBatchDeleteRecords');
                errorMessages.clear();
            }

            noOfRecordsDeleted = noOfRecordsDeleted + deleteIds.size();
            totalNoOfRecords = totalNoOfRecords + scope.size();
        }catch( exception e){
            system.debug('error message '+e.getMessage());

        }
    }
    // Finish
    global void finish(Database.BatchableContext bc) {
        system.debug('totalNoOfRecords....'+totalNoOfRecords);
        system.debug('noOfRecordsDeleted....'+noOfRecordsDeleted);
    }
    // Schedulable exceute method
    global void execute(SchedulableContext sc) {
        // custom setting
        Map<String, DeleteJobController__c> DelJobConMap = DeleteJobController__c.getAll();
        for(DeleteJobController__c delJobRec : DelJobConMap.values()){
            // if custom setting isRun__c is true and object api is not custom metadta  than only schedule the job
            if(delJobRec.isRun__c == true && !delJobRec.Object_Api_Name__c.contains('__mdt')){
                // Invoke the batch class and passe the Query and object API name
                CDdBatchDeleteRecords delRec = new CDdBatchDeleteRecords(delJobRec.Query__c, delJobRec.Object_Api_Name__c);
                database.executebatch(delRec, 200);
            }
        }
    }
}