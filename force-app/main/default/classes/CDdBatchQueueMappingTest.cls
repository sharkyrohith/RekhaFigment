/**
 * CDdBatchQueueMappingTest
 *
 * @author  Nayana Kapse
 * @date  05/17/2022
 * @decription Test class for CDdBatchQueueMapping
 */

@isTest(SeeAllData=false)
public class CDdBatchQueueMappingTest {
    @testSetup static void testSetup() {
        List<Support_Assignment_Mapping__c> listSettings =new List<Support_Assignment_Mapping__c>();

        List<amazonconnect__AC_QueueMetrics__c> lstPhoneQueue = new List<amazonconnect__AC_QueueMetrics__c>();
        lstPhoneQueue.add(new amazonconnect__AC_QueueMetrics__c(name='testphone1',amazonconnect__Queue_Id__c='12345'));
        lstPhoneQueue.add(new amazonconnect__AC_QueueMetrics__c(name='testphone2',amazonconnect__Queue_Id__c='12346'));
        insert lstPhoneQueue;
    }
    
	 /**
    * @author    Nayana
    * @date  May 2022
    * @decription Test method for CDdBatchQueueMapping constructor
    */
    static testMethod void testCDdBatchQueueMapping() {
        Test.startTest();
        ID batchProcessdId = Database.executeBatch(new CDdBatchQueueMapping());
        Test.stopTest();
        List<Queue_Mapping__c> queMap = [SELECT Id FROM Queue_Mapping__c];
        System.assertEquals(true, queMap.size()>0, 'Batch job should create records');
    }
    
     /**
    * @author    Nayana
    * @date  May 2022
    * @decription Test method for CDdBatchQueueMapping phone
    */
    static testMethod void testCDdBatchQueueMappingPhone() {
        Test.startTest();
        ID batchProcessdId = Database.executeBatch(new CDdBatchQueueMapping('Ready for ETL'));
        Test.stopTest();
        List<Queue_Mapping__c> phoneQueMap = [SELECT Id FROM Queue_Mapping__c WHERE Queue_Type__c = : CDdBatchQueueMapping.PHONE_QUEUE_TYPE];
        System.assertEquals(2, phoneQueMap.size(), 'Batch job should create records');
    }
    
     /**
    * @author    Nayana
    * @date  May 2022
    * @decription Test method for CDdBatchQueueMapping scheduler
    */
    static testMethod void testCDdBatchQueueMappingScheduler() {
        String cronExp = '0 0 0 15 3 ? 2099';
        Test.startTest();
        String jobId = System.schedule('ScheduledCDdBatchQueueMappingTest', cronExp, new CDdBatchQueueMapping());   
        Test.stopTest();
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(cronExp, ct.CronExpression);
    }
}