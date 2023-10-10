@isTest
private with sharing class MxSelfOnboardingEscalationSchedTest {
  @isTest static void testSchedule(){
    Test.startTest();
    MxSelfOnboardingEscalationSchedulable.schedule(MxSelfOnboardingEscalationSchedulable.cronSchedule);
    Test.stopTest();
    system.assertEquals(1, [SELECT count() FROM CronTrigger 
        WHERE CronJobDetail.Name like 'MxSelfOnboardingEscalationSchedulable%' 
        OR CronJobDetail.Name = :MxSelfOnboardingEscalationSchedulable.batchClassId]);
  }
}