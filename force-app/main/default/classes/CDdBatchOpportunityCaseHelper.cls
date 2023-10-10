/*
* @Author Knick
* @Date May 2020
* @description BZAP-7419 - Batch Check Opportunity Case Creation
*/
public class CDdBatchOpportunityCaseHelper implements Database.Batchable<sObject>, Schedulable {

    public void execute(SchedulableContext sc) {
        ApexClass thisClass = [SELECT Id FROM ApexClass WHERE Name = 'CDdBatchOpportunityCaseHelper' LIMIT 1];
        Set<String> runningStatus = new Set<String> {'Holding', 'Processing', 'Queued', 'Preparing'};
        AsyncApexJob[] runningJobs = [
            SELECT Id, Status FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
            AND ApexClassId = :thisClass.Id
            AND Status IN :runningStatus
        ];
        system.debug('CDdBatchOpportunityCaseHelper: execute: runningJobs: ' + runningJobs);
        if (runningJobs.size() == 0) {
            CDdBatchOpportunityCaseHelper batch = new CDdBatchOpportunityCaseHelper();
            Database.executeBatch(batch, CDdCustomMetadata.getBatchSize('CDdBatchOpportunityCaseHelper'));
        }
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        Integer lookBack = CDdCustomMetadata.getCustomNumber('CDdBatchOpportunityCaseHelper');
        if (lookBack == null) lookBack = 5;             // Set a default if none was provided
        Date since = Date.Today().addDays(-1 * lookBack);
        system.debug('CDdBatchOpportunityCaseHelper: start: since: ' + since);
        Database.QueryLocator ql = Database.getQueryLocator([
            SELECT Id FROM Opportunity WHERE LastModifiedDate > :since
        ]);
        system.debug('CDdBatchOpportunityCaseHelper: start: ql: ' + ql);
        return ql;
    }

    public void execute(Database.BatchableContext BC, List<Opportunity> scope) {
        system.debug('CDdBatchOpportunityCaseHelper: execute: scope: ' + scope);
        List<Id> oppIds = new List<Id>();
        for (Opportunity opp : scope) oppIds.add(opp.Id);
        CDdOpportunityCaseHelper.checkCases(oppIds);
    }

    public void finish(Database.BatchableContext BC) {} // Nothing to do here

}