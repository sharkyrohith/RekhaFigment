global with sharing class MxSelfOnboardingEscalationSchedulable implements system.Schedulable {
  @testVisible static final String cronSchedule = '0 19 7,12,16 * * ?'; // 7:19am, 12:19pm and 4:19pm
  @testVisible static final Id batchClassId = [SELECT Id FROM ApexClass WHERE Name = 'MxSelfOnboardingEscalationSchedulable'].Id;
  global void execute(system.SchedulableContext ctx){
    Database.executeBatch(new MxSelfOnboardingEscalationBatch(),1);
  }
  global static void schedule(String cronString){
    for(CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name like 'MxSelfOnboardingEscalationSchedulable%' OR CronJobDetail.Name = :batchClassId]){
      system.abortjob(ct.id); 
    }
    system.schedule('MxSelfOnboardingEscalationSchedulable/'+ cronString, cronString, new MxSelfOnboardingEscalationSchedulable());
  }
}