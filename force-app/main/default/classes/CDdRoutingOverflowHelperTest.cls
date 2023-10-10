/**
 * CDdRoutingOverflowHelperTest
 *
 * @author  Nayana Kapse
 * @date  09/12/2021
 * @decription Test class for CDdRoutingOverflowHelper
 * Note: Salesforce don't allow to insert test data in UserServicePresence object. It rely on org data
 */

@isTest
public with sharing class CDdRoutingOverflowHelperTest {
    @testSetup
    public static void testSetup() {

        Id queuConfigId = [SELECT Id FROM QueueRoutingConfig LIMIT 1].Id;

        System.runAs(new User(Id=UserInfo.getUserId()))
        {
             //Create Parent Group
            Group testGroup = new Group(Name='CDdRoutingOverflowHelperTest Group1', Type='Queue',QueueRoutingConfigId = queuConfigId);
            insert testGroup;

            //Associating queue with group AND to the Case object
            QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = 'Case');
            insert testQueue;

             //Create Group Member
            GroupMember grpMem1 = new GroupMember();
            grpMem1.UserOrGroupId = UserInfo.getUserId();
            grpMem1.GroupId = testGroup.Id;
            insert grpMem1;

        }

    }

    /**
     * @author      Nayana
     * @date        Sept 2021
     * @description Data will be quried once and can be used in test methods
     */
    public class TestContext
    {
        public List<Group> lstGrp;
        public TestContext(){
            lstGrp = [SELECT Id,Name,DeveloperName from Group WHERE Name = 'CDdRoutingOverflowHelperTest Group1'];
        }
    }

    /**
    * @author    Nayana
    * @date  Sept 2021
    * @decription Test method for getUserPresence
    */
    static testMethod void testgetUserPresence() {
        String queryWherClause = CDdRoutingOverflowHelper.mapQueueMetadata.containsKey('Query_Filter') ? CDdRoutingOverflowHelper.mapQueueMetadata.get('Query_Filter').Value__c : '';
        Test.startTest();
        String queryStr = CDdRoutingOverflowHelper.getUserPresence(queryWherClause);
        Test.stopTest();
        System.assertEquals(true, String.isNotBlank(queryStr), 'Query string should not be blank');
    }

    /**
    * @author    Nayana
    * @date  Sept 2021
    * @decription Test method for getUserCapacity
    */
    static testMethod void testgetUserCapacity() {
        CDdRoutingOverflowHelper cRoutingHelper = new CDdRoutingOverflowHelper();
        List<UserServicePresence> lstUserPresence = [SELECT Id,configuredCapacity FROM UserServicePresence WHERE CreatedDate = Today AND iscurrentstate = true AND isaway = FALSE LIMIT 10];
        Test.startTest();
        Map<Id,Double> mapUserCapacity = cRoutingHelper.getUserCapacity(lstUserPresence);
        Test.stopTest();
    }

    /**
    * @author    Nayana
    * @date  Sept 2021
    * @decription Test method for getOmniEnabledGroups
    */
    static testMethod void testgetOmniEnabledGroups() {
        Set<String> setObjects = new Set<String>();
        setObjects.add('Case');
        Test.startTest();
        Map<Id,Group> mapQueueIdData = CDdRoutingOverflowHelper.getOmniEnabledGroups(setObjects);
        Test.stopTest();
        System.assertEquals(true, mapQueueIdData.size()>0, 'Queues enabled for Case ');
    }

     /**
    * @author    Nayana
    * @date  Sept 2021
    * @decription Test method for getUserGroups
    */
    static testMethod void testgetUserGroups() {
        Set<Id> userId = new Set<Id>();
        userId.add(UserInfo.getUserId());
        TestContext context = new TestContext();
        Map<Id,CDdRoutingOverflowHelper.QueueInfoWrapper> mapQueueInfoWrapper = new Map<Id,CDdRoutingOverflowHelper.QueueInfoWrapper>();
        CDdRoutingOverflowHelper.QueueInfoWrapper qWrap = new CDdRoutingOverflowHelper.QueueInfoWrapper();
        qWrap.queueId = context.lstGrp[0].Id;
        qWrap.queueActiveUserId = new Set<Id>{UserInfo.getUserId()};
        qWrap.queueAvailableAgentsCount = 1;
        qWrap.queueTotalCapacity = 10;
        mapQueueInfoWrapper.put(qWrap.queueId,qWrap);
        Test.startTest();
        CDdRoutingOverflowHelper cRoutingHelper = new CDdRoutingOverflowHelper();
        Map<Id,List<Id>> mapUserIdQueueId = cRoutingHelper.getUserGroups(userId);
        mapQueueInfoWrapper = cRoutingHelper.getQueueAvailableAgents(mapQueueInfoWrapper,userId,mapUserIdQueueId);
        Test.stopTest();
        System.assertEquals(true, mapUserIdQueueId.size()>0, 'Queue should have 1 user');
    }

     /**
    * @author    Nayana
    * @date  Sept 2021
    * @decription Test method for getQueueTotalCapacity
    */
    static testMethod void testgetQueueTotalCapacity() {
        Map<Id,Double> mapUserCapacity = new Map<Id,Double>();
        mapUserCapacity.put(UserInfo.getUserId(),10.0);
        TestContext context = new TestContext();
        Map<Id,CDdRoutingOverflowHelper.QueueInfoWrapper> mapQueueInfoWrapper = new Map<Id,CDdRoutingOverflowHelper.QueueInfoWrapper>();
        CDdRoutingOverflowHelper.QueueInfoWrapper qWrap = new CDdRoutingOverflowHelper.QueueInfoWrapper();
        qWrap.queueId = context.lstGrp[0].Id;
        qWrap.queueActiveUserId = new Set<Id>{UserInfo.getUserId()};
        qWrap.queueAvailableAgentsCount = 1;
        qWrap.queueWeight = 5;
        mapQueueInfoWrapper.put(qWrap.queueId,qWrap);
        Test.startTest();
        CDdRoutingOverflowHelper cRoutingHelper = new CDdRoutingOverflowHelper();
        Map<Id,CDdRoutingOverflowHelper.QueueInfoWrapper> mapQueueInfoWrapperNew = cRoutingHelper.getQueueTotalCapacity(mapQueueInfoWrapper,mapUserCapacity);
        Test.stopTest();
        System.assertEquals(10, mapQueueInfoWrapperNew.get(context.lstGrp[0].Id).queueTotalCapacity, 'There is only 1 user available with capacity =10');
    }

    /**
    * @author    Nayana
    * @date  Sept 2021
    * @decription Test method for getQueueUsedCapacity
    */
    static testMethod void testgetQueueUsedCapacity() {
        Set<Id> userId = new Set<Id>();
        userId.add(UserInfo.getUserId());
        TestContext context = new TestContext();
        Map<Id,CDdRoutingOverflowHelper.QueueInfoWrapper> mapQueueInfoWrapper = new Map<Id,CDdRoutingOverflowHelper.QueueInfoWrapper>();
        CDdRoutingOverflowHelper.QueueInfoWrapper qWrap = new CDdRoutingOverflowHelper.QueueInfoWrapper();
        qWrap.queueId = context.lstGrp[0].Id;
        qWrap.queueActiveUserId = new Set<Id>{UserInfo.getUserId()};
        qWrap.queueAvailableAgentsCount = 1;
        qWrap.queueTotalCapacity = 10;
        mapQueueInfoWrapper.put(qWrap.queueId,qWrap);
        Test.startTest();
        CDdRoutingOverflowHelper cRoutingHelper = new CDdRoutingOverflowHelper();
        List<AggregateResult> lstAgResult = [SELECT AVG(CapacityWeight) queueCapacity ,Count(Id) numberOfPendingChats, OriginalQueueId
                                             FROM AgentWork WHERE CreatedDate = today GROUP BY OriginalQueueId LIMIT 2];
        Map<Id,CDdRoutingOverflowHelper.QueueInfoWrapper> mapQueueInfoWrapperNew = cRoutingHelper.getQueueUsedCapacity(lstAgResult);
        Test.stopTest();
        System.assertEquals(true, mapQueueInfoWrapper.size()>0, 'Wrapper should have 1 queue info');
    }

    /**
    * @author    Nayana
    * @date  Sept 2021
    * @decription Test method for findOverflowQueue and createQueueConfig
    */
    static testMethod void testfindOverflowQueueAndcreateQueueConfig() {
        TestContext context = new TestContext();
        Map<Id,CDdRoutingOverflowHelper.QueueInfoWrapper> mapQueueInfoWrapper = new Map<Id,CDdRoutingOverflowHelper.QueueInfoWrapper>();
        CDdRoutingOverflowHelper.QueueInfoWrapper qWrap = new CDdRoutingOverflowHelper.QueueInfoWrapper();
        qWrap.queueId = context.lstGrp[0].Id;
        qWrap.queueActiveUserId = new Set<Id>{UserInfo.getUserId()};
        qWrap.queueAvailableAgentsCount = 1;
        qWrap.queueTotalCapacity = 10;
        qWrap.queueUsedCapacity = 10;
        mapQueueInfoWrapper.put(qWrap.queueId,qWrap);
        Test.startTest();
        CDdRoutingOverflowHelper cRoutingHelper = new CDdRoutingOverflowHelper();
        Map<Id,CDdRoutingOverflowHelper.QueueInfoWrapper> mapQueueInfoWrapperNew = cRoutingHelper.findOverflowQueue(mapQueueInfoWrapper);
        cRoutingHelper.createQueueConfig(mapQueueInfoWrapperNew);
        Test.stopTest();
        System.assertEquals(true, mapQueueInfoWrapperNew.get(context.lstGrp[0].Id).queueOverflow, 'As Queue total capacity = Used Capacity, overlow flag should be true');
        List<Queue_Overflow_Configuration__c> lstQueueConfig = [SELECT Id,Queue_Id__c FROM Queue_Overflow_Configuration__c];
        System.assertEquals(context.lstGrp[0].Id, lstQueueConfig[0].Queue_Id__c, 'Queue Overflow record for the queue should get created');
    }


    /**
    * @author    Nayana
    * @date  Sept 2021
    * @decription Test method for builOverflowCache and getQueueCacheData
    */
    static testMethod void testbuilOverflowCache() {
        List<Queue_Overflow_Configuration__c> lstQueueOverflow = new List<Queue_Overflow_Configuration__c>();
        TestContext context = new TestContext();
        Queue_Overflow_Configuration__c qConfig = new Queue_Overflow_Configuration__c();
        qConfig.Queue_Id__c = context.lstGrp[0].Id;
        qConfig.Queue_Developer_Name__c = context.lstGrp[0].DeveloperName;
        qConfig.Queue_Capacity_Total__c = 10;
        qConfig.Occupied_Queue_Capacity__c = 10;
        qConfig.Agent_Work_Count__c = 1;
        qConfig.Queue_Weight__c = 5;
        qConfig.Is_Queue_At_Capacity__c = true;
        qConfig.Is_Active__c = true;
        qConfig.Overflow_Queue_Id__c = context.lstGrp[0].Id;
        lstQueueOverflow.add(qConfig);
        insert lstQueueOverflow;
        Test.startTest();
        CDdRoutingOverflowHelper.builOverflowCache(lstQueueOverflow);
        Map<Id,CDdRoutingOverflowHelper.QueueCacheWrapper> mapQueueCache = CDdRoutingOverflowHelper.getQueueCacheData();
        Test.stopTest();
        System.assertEquals(true, mapQueueCache.size()>0, 'Queue Wrapper should have 1 queue info');
    }
}