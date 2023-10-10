/**
* @author: Tia Xuan
* @date: 2020-02
* @description Neverbound treatment batch
*/
public class CDdNeverbounceTreatmentBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Schedulable  {

    public static final Map<String, Schema.SObjectType> SOBJECT_TYPES = Schema.getGlobalDescribe();

    public void execute(SchedulableContext sc) {
        CDdNeverbounceTreatmentBatch batch = new CDdNeverbounceTreatmentBatch();
        Database.executeBatch(batch, 1);
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        String qry = 'Select Id, Job_ID__c, Status__c, Type__c ';
        qry += ' from Neverbounce_Task__c ';
        qry += ' where Status__c NOT IN (\'complete\',\'failed\')';
        return Database.getQueryLocator(qry);
    }

    public void execute(Database.BatchableContext BC, List<Neverbounce_Task__c> scope) {
        Map<String, SObject> objToUpdate = new Map<String,SObject>();
        List<String> errorMessages = new List<String>();
        for (Neverbounce_Task__c item : scope){
            String jobStatus = CDdNeverbounceHandler.getJobStatus(item.Job_ID__c);
            objToUpdate.put(item.Id, new Neverbounce_Task__c(Id = item.Id, Status__c = jobStatus));
            switch on jobStatus {
                when 'complete' {
                    Map<String, String> results = CDdNeverbounceHandler.getJobResults(item.Job_ID__c);
                    if (results != null){
                        for (String key : results.keySet()){
                            SObject obj = SOBJECT_TYPES.get(item.Type__c).newSObject();
                            obj.put('Id', key);
                            obj.put('Email_Verification_Status__c', results.get(key));
                            obj.put('Email_Updated__c', false);
                            objToUpdate.put(obj.Id, obj);
                        }
                    }
                }
                when else {}
            }
        }

        if (objToUpdate.size() > 0){
            Database.SaveResult[] updateResults = Database.update(objToUpdate.values(), false);
            errorMessages = CDdErrorUtilities.processSaveResults(updateResults, errorMessages);
            if(!errorMessages.isEmpty()){
                CDdErrorUtilities.createApexLogs(errorMessages, 'CDdNeverbounceTreatmentBatch');
            }
        }
    }

    public void finish(Database.BatchableContext BC) {
        CDdNeverbounceHandler.cleanupNeverbounceTasks();
    }

}