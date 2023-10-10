/**
 * Created by Jeremy S. Johnson (Perficient, Inc)
 *
 * Implements BZAP-7091: Scheduled Batch job for opted-in franchise opps (Closed Won)
 * Implements BZAP-7214: Scheduled Batch job for opted-out franchise opps (Closed Lost)
 */
global class CDdBatchOpportunityOptInOut implements Database.Batchable<Opportunity>, System.Schedulable {

    global void execute(System.SchedulableContext ctx) {
        Database.executeBatch(new CDdBatchOpportunityOptInOut(), Integer.valueOf(Label.Opportunity_CW_CL_Batch_Size));
    }

    global List<Opportunity> start(Database.BatchableContext ctx) {
        Id franchiseRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Franchise_Opportunity').getRecordTypeId();
        List<Opportunity> opps = new List<Opportunity>();

        Date optInDays = System.today().addDays(-Integer.valueOf(Label.DdOpportunityOptInDays));
        List<Opportunity> optInOpps = [select Id, StageName from Opportunity where RecordTypeId = :franchiseRecTypeId and StageName = 'Out for Signature' and Docusign_Sent__c < :optInDays and PactSafe_Contract_Type__c = 'Franchisee Opt-Out Addendum'];
        for (Opportunity opp : optInOpps) {
            opp.StageName = 'Closed Won';
        }
        opps.addAll(optInOpps);

        Date optOutDays = System.today().addDays(-Integer.valueOf(Label.DdOpportunityOptOutDays));
        List<Opportunity> optOutOpps = [select Id, StageName, Lost_Reason__c from Opportunity where RecordTypeId = :franchiseRecTypeId and StageName = 'Opt-Out Review' and Docusign_Sent__c < :optOutDays and PactSafe_Contract_Type__c = 'Franchisee Opt-Out Addendum'];
        for (Opportunity opp : optOutOpps) {
            opp.StageName = 'Closed Lost';
            opp.Lost_Reason__c = 'Franchisee Opt-Out';
        }
        opps.addAll(optOutOpps);

        return opps;
    }

    global void execute(Database.BatchableContext ctx, List<Opportunity> opps) {
        List<Database.SaveResult> srs = Database.update(opps, false);

        List<Apex_Log__c> logs = new List<Apex_Log__c>();
        for (Database.SaveResult sr : srs) {
            for (Database.Error error : sr.getErrors()) {
                System.debug(LoggingLevel.ERROR, 'CDdBatchOpportunityOptInOut, error: ' + error);
                Apex_Log__c log = new Apex_Log__c();
                log.Class_Name__c = 'CDdBatchOpportunityOptInOut';
                log.Method_Name__c = 'execute';
                log.Log_Level__c = 'Error';
                log.Log__c = error.getMessage();
                logs.add(log);
            }
        }
        insert logs;
    }

    global void finish(Database.BatchableContext ctx) {}
}