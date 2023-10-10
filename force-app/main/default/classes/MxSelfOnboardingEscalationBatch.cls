global without sharing class MxSelfOnboardingEscalationBatch implements Database.Batchable<SObject> {
  @testVisible static final Map<String, RecordTypeInfo> OPP_RT_INFO = 
      Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
  Id escalationQueueId = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Onboarding - New Partner Escalations'].Id;
  
  global Database.QueryLocator start(Database.BatchableContext ctx){
    return Database.getQueryLocator([SELECT Id, Name, RecordTypeId, Menu_to_be_completed_by__c, SSME_Menu_Completion_Date_Time__c, 
            SSME_Expiration_Date_Time__c, SSME_Escalation_Date_Time__c
        FROM Opportunity
        WHERE RecordTypeId IN (:OPP_RT_INFO.get('Marketplace').getRecordTypeId(), :OPP_RT_INFO.get('Enterprise Marketplace').getRecordTypeId())
            AND Menu_To_Be_Completed_By__c = 'Merchant'
            AND StageName = 'Closed Won'
            AND SSME_Menu_Completion_Date_Time__c = null
            AND SSME_Expiration_Date_Time__c != null
            AND SSME_Expiration_Date_Time__c <= :system.now()]);
  }

  global void execute(Database.BatchableContext ctx, List<Opportunity> opps){
    DateTime now = system.now();
    for(Opportunity opp: opps){
      opp.Menu_to_be_completed_by__c = 'DoorDash Onboarding Team'; 
      opp.SSME_Escalation_Date_Time__c = now;
    }
    List<Database.SaveResult> results = Database.update(opps, false);
    CDdErrorUtilities.createApexLogs(CDdErrorUtilities.processSaveResults(results), 
        'MxSelfOnboardingEscalationBatch', 'execute',LoggingLevel.INFO);
  }
  global void finish(Database.BatchableContext ctx){}
}