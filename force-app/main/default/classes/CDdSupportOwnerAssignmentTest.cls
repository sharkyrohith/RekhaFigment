/**
 * CDdSupportOwnerAssignmentTest
 *
 * @author  Nayana Kapse
 * @date  11/03/2021
 * @decription Test class for CDdSupportOwnerAssignment
 */

@isTest
public class CDdSupportOwnerAssignmentTest {
    public static String originalQName ='Original Queue1';
    public static String overflowQName ='Overflow Queue1';
	@testSetup
    public static void testSetup() {

        Id queuConfigId = [SELECT Id FROM QueueRoutingConfig LIMIT 1].Id;
       
        System.runAs(new User(Id=UserInfo.getUserId()))
        {
            //Create Parent Group
            List<Group> lstGrp = new List<Group>();
            Group testGroup1 = new Group(Name=originalQName, Type='Queue',QueueRoutingConfigId = queuConfigId);
            Group testGroup2 = new Group(Name=overflowQName, Type='Queue',QueueRoutingConfigId = queuConfigId);
            lstGrp.add(testGroup1);
            lstGrp.add(testGroup2);
            insert lstGrp; 
        
            //Associating queue with group AND to the Case object
            List<QueuesObject> lstQueueObj = new List<QueuesObject>();
            lstQueueObj.add(new QueueSObject(QueueID = lstGrp[0].id, SObjectType = 'Case'));
            lstQueueObj.add(new QueueSObject(QueueID = lstGrp[1].id, SObjectType = 'Case'));
            insert lstQueueObj;
			
            
            Queue_Overflow_Configuration__c qConfig = new Queue_Overflow_Configuration__c();
            qConfig.Queue_Id__c = lstGrp[0].Id;
            qConfig.Queue_Developer_Name__c = lstGrp[0].Name;
            qConfig.Queue_Capacity_Total__c = 10;
            qConfig.Occupied_Queue_Capacity__c = 10;
            qConfig.Agent_Work_Count__c = 0;
            qConfig.Queue_Weight__c = 5;            
            qConfig.Is_Queue_At_Capacity__c = true;
            qConfig.Is_Active__c = true;
            qConfig.Overflow_Queue_Id__c=lstGrp[1].Id;
            insert qConfig;
        }
 
    }
    
    /**
     * @author      Nayana
     * @date        Sept 2021
     * @description Data will be quried once and can be used in test methods
     */
    public class TestContext
    {
        public Map<String,Id> mapQueueTypeId;
        public List<Queue_Overflow_Configuration__c> lstQueueConfig;
        public TestContext(){
            Set<String> queueName = new Set<String>();
            mapQueueTypeId = new Map<String,Id>();
            queueName.add(originalQName);
            queueName.add(overflowQName);
            for(Group grp:[SELECT Id,Name,DeveloperName from Group WHERE Name IN: queueName]){
                mapQueueTypeId.put(grp.Name,grp.Id);
            }
            lstQueueConfig =[SELECT Id,Is_Queue_At_Capacity__c FROM Queue_Overflow_Configuration__c];
        }
    }
    /**
    * @author    Nayana
    * @date  Sept 2021
    * @decription Test method for getUserPresence
    */
    static testMethod void testReassignmentOverflow() {
        TestContext context = new TestContext();
        Test.startTest();
        	CDdSupportOwnerAssignment cOwnerAssign = new CDdSupportOwnerAssignment();
        	CDdSupportOwnerAssignment.OwnerRoutingInfo cInfo = cOwnerAssign.findFinalOwner(context.mapQueueTypeId.get(originalQName));
        Test.stopTest();
        System.assertEquals(context.mapQueueTypeId.get(overflowQName), cInfo.ownerId, 'As overflow flag is true method should return overflow queue');
        System.assertEquals(CDdSupportOwnerAssignment.overflowReason, cInfo.routingReason, 'As overflow flag is true method should return routing reason');
    }
    
    /**
    * @author    Nayana
    * @date  Sept 2021
    * @decription Test method for getUserPresence
    */
    static testMethod void testOwnerNotOverflow() {
        TestContext context = new TestContext();
        context.lstQueueConfig[0].Is_Queue_At_Capacity__c= false;
		update context.lstQueueConfig[0];
        Id originalQID= context.mapQueueTypeId.get(originalQName);
        Test.startTest();
        	CDdSupportOwnerAssignment cOwnerAssign = new CDdSupportOwnerAssignment();
        	CDdSupportOwnerAssignment.OwnerRoutingInfo cInfo = cOwnerAssign.findFinalOwner(originalQID);
        Test.stopTest();
        System.assertEquals(originalQID, cInfo.ownerId, 'As overflow flag is false method should return same queue Id');
        System.assertEquals('', cInfo.routingReason, 'As overflow flag is false method should return blank routing reason');
    }

}