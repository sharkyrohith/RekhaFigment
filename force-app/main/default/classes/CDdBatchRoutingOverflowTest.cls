/**
 * CDdBatchRoutingOverflowTest
 *
 * @author  Nayana Kapse
 * @date  09/12/2021
 * @decription Test class for CDdBatchRoutingOverflow
 * Note: Salesforce don't allow to insert test data in UserServicePresence/AgentWork object. It rely on org data. So need to use SeeAllData=True
 */

@isTest(SeeAllData=true)
public with sharing class CDdBatchRoutingOverflowTest {

    /**
    * @author    Nayana
    * @date  Sept 2021
    * @decription Test method for CDdBatchRoutingOverflow constructor
    */
    static testMethod void testCDdBatchRoutingOverflow() {
        Test.startTest();
        ID batchProcessdId = Database.executeBatch(new CDdBatchRoutingOverflow());
        Test.stopTest();
    }

    
    /**
    * @author    Nayana
    * @date  Sept 2021
    * @decription Test method for CDdBatchRoutingOverflow overloaded constructor
    */
    static testMethod void testCDdBatchRoutingOverflowOverloaded() {
        Test.startTest();
        ID batchProcessdId = Database.executeBatch(new CDdBatchRoutingOverflow(new List<Id>()));
        Test.stopTest();
    }

    /**
    * @author    Nayana
    * @date  Sept 2021
    * @decription Test method for CDdBatchRoutingOverflow schedular
    */
    static testMethod void testCDdBatchRoutingOverflowSchedular() {
        String cronExp = '0 0 0 15 3 ? 2099';
        Test.startTest();
        String jobId = System.schedule('ScheduledApexTest', cronExp, new CDdBatchRoutingOverflow(new List<Id>()));   
        Test.stopTest();
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(cronExp, ct.CronExpression);
    }
}