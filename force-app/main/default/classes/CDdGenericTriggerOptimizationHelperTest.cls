/**
 * CDdGenericTriggerOptimizationHelperTest
 *
 * @author     Sahil
 * @date  2022-01-19
 * @decription Test class for CDdGenericTriggerOptimizationHelper
 * 
 */
@isTest(seeAllData=false)
public class CDdGenericTriggerOptimizationHelperTest {
     /**
    * @author     Sahil
    * @date  2022-01-19
    * @decription test getting and setting queues
    * @param   None
    * @return  None
    */
    @isTest
    static void testQueues() {
        Group queueFromDb = [SELECT Id, DeveloperName, Name FROM Group WHERE Type = 'QUEUE' LIMIT 1];
        List<String> queueNames = new List<String> {queueFromDb.Name};
        Set<Id> queueIds = new Set<Id> {queueFromDb.Id};
        CDdGenericTriggerOptimizationHelper.setQueueMap(queueNames,queueIds);
        CDdGenericTriggerOptimizationHelper.setQueueMap(queueIds);
        CDdGenericTriggerOptimizationHelper.setQueueMap(queueNames);

        //get queues from database
        System.assertNotEquals(null, CDdGenericTriggerOptimizationHelper.getQueueNameToIdMap(),
                                                    'Queues should be returned from Database');
        System.assertEquals(queueFromDb.Id, CDdGenericTriggerOptimizationHelper.getQueueIdByDevName(queueFromDb.DeveloperName),
                                                    'queried Queue should be returned from Database');     
        System.assertEquals(queueFromDb.Id, CDdGenericTriggerOptimizationHelper.getQueueIdByName(queueFromDb.Name),
                                                    'queried Queue should be returned from Database');
        System.assertNotEquals(null, CDdGenericTriggerOptimizationHelper.getQueueDevNameToIdMap(),
                                                    'Queues should be returned from Database'); 
        System.assertNotEquals(null, CDdGenericTriggerOptimizationHelper.getQueueMap(),
                                                    'Queues should be returned from Database');                                
        System.assertEquals(queueFromDb, CDdGenericTriggerOptimizationHelper.getQueue(queueFromDb.Id),
                                                    'queried Queue should be returned from Database'); 
    }

     /**
    * @author     Sahil
    * @date  2022-01-19
    * @decription test getting and setting business hours
    * @param   None
    * @return  None
    */
    @isTest
    static void testBusinessHours() {
        System.assertNotEquals(null, CDdGenericTriggerOptimizationHelper.getBusinessHours(), 'Business Hours should be returned');
        BusinessHours businessHour = [SELECT Id, Name, IsDefault from BusinessHours WHERE IsDefault = true Limit 1];
        System.assertEquals(businessHour, CDdGenericTriggerOptimizationHelper.getDefaultBusinessHour(), 'Default Business Hour should be returned');
    }

      /**
    * @author     Sahil
    * @date  2022-01-19
    * @decription test getting and setting record types
    * @param   None
    * @return  None
    */
    @isTest
    static void testRecordTypes() {
        //Opportunity
        RecordType oppRecType = [SELECT Id,Name,DeveloperName from RecordType WHERE SobjectType = 'Opportunity' limit 1];
        System.assertEquals(oppRecType.Id, CDdGenericTriggerOptimizationHelper.getOpportunityRecordTypeId(oppRecType.Name),
                                             'Opportunity record type Id should be returned');
        System.assertEquals(oppRecType.Id, CDdGenericTriggerOptimizationHelper.getOpportunityRecordTypeIdByDevName(oppRecType.DeveloperName),
                                             'Opportunity record type Id should be returned');
        //Account
        RecordType accountRecType = [SELECT Id,Name,DeveloperName from RecordType WHERE SobjectType = 'Account' limit 1];
        System.assertEquals(accountRecType.Id, CDdGenericTriggerOptimizationHelper.getAccountRecordTypeId(accountRecType.Name),
                                                'Account record type id should be returned');
        System.assertEquals(accountRecType.Id, CDdGenericTriggerOptimizationHelper.getAccountRecordTypeIdByDevName(accountRecType.DeveloperName),
                                                'Account record type id should be returned');
        //Milestone
        RecordType milestoneRecType = [SELECT Id,Name,DeveloperName from RecordType WHERE SobjectType = 'Milestone__c' limit 1];
        System.assertEquals(milestoneRecType.Id, CDdGenericTriggerOptimizationHelper.getMilestoneRecordTypeId(milestoneRecType.Name),
                                                'Milestone record type id should be returned');
        System.assertEquals(milestoneRecType.Id, CDdGenericTriggerOptimizationHelper.getMilestoneRecordTypeIdByDevName(milestoneRecType.DeveloperName),
                                                'Milestone record type id should be returned');
    }
}