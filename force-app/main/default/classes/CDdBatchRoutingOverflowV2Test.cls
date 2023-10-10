/**
 * CDdBatchRoutingOverflowTest
 *
 * @author  Nayana Kapse
 * @date  05/17/2023
 * @decription Test class for CDdBatchRoutingOverflowV2Test
 * Note: Salesforce don't allow to insert test data in UserServicePresence/AgentWork object. It rely on org data. So need to use SeeAllData=True
 */

 @isTest
 public with sharing class CDdBatchRoutingOverflowV2Test {

     /**
     * @author    Nayana
     * @date  May 2023
     * @decription Test method for CDdBatchRoutingOverflowV2 constructor
     */
     static testMethod void testCDdBatchRoutingOverflow() {
         Test.startTest();
         Set<String> setObjects = new Set<String>();
         setObjects.add('Case');
         Id qIdInProcess;
         for(Id qId: CDdRoutingOverflowHelper.getOmniEnabledGroups(setObjects).keySet()){
             qIdInProcess = qId;
             break;
         }
         CDdBatchRoutingOverflowV2 cbRoute = new CDdBatchRoutingOverflowV2();
         Map<String,Object> myMap = new Map<String,Object> {
            'qId' => (Object)qIdInProcess,
            'agentId' => (Object)UserInfo.getUserId(),
            'totalPerQueue' => (Object)10,
            'avgWaitTime' => (Object)1234
         };
         List<Aggregate> lstAggregate = new List<Aggregate>();
         lstAggregate.add(new Aggregate(myMap));
         cbRoute.setMockAgentAggregateList(lstAggregate);
         Map<String,Object> myMap2 = new Map<String,Object> {
            'queueId' => (Object)qIdInProcess,
            'pendingCound' => (Object)20
         };
         List<Aggregate> lstAggregate2 = new List<Aggregate>();
         lstAggregate2.add(new Aggregate(myMap2));
         cbRoute.setMockPendingServiceAggregateList(lstAggregate);
         ID batchProcessdId = Database.executeBatch(cbRoute);
         System.assert(batchProcessdId!=null);
         Test.stopTest();
     }


     /**
     * @author    Nayana
     * @date  May 2023
     * @decription Test method for CDdBatchRoutingOverflowV2 schedular
     */
     static testMethod void testCDdBatchRoutingOverflowSchedular() {
         String cronExp = '0 0 0 15 3 ? 2099';
         Test.startTest();
         String jobId = System.schedule('ScheduledApexTest', cronExp, new CDdBatchRoutingOverflowV2(new List<Id>()));
         Test.stopTest();
         CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
         System.assertEquals(cronExp, ct.CronExpression);
     }
 }