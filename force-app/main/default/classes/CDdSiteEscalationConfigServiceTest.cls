/**
 * CDdSiteEscalationConfigServiceTest
 *
 * @author     Sahil
 * @date  2020-03-17
 * @decription Test class for Site Escalation Config Service
 */
@isTest(seeAllData=false)
public class CDdSiteEscalationConfigServiceTest {

    public static final String TEST2_QUEUE_LABEL = 'Test2 Queue';
    public static final String TEST3_QUEUE_LABEL = 'Test3 Queue';
    public static final String TEST4_QUEUE_LABEL = 'Test4 Queue';
    @testSetup
    static void setup() {
        //Creating Group
        Group testGroup = new Group(Name = CDdSupportConstants.TEST_QUEUE_LABEL, Type = CDdSupportConstants.GROUP_QUEUE);
        insert testGroup;
        QueuesObject testQueue;
        
        //Creating Group2
        
        Group testGroup2 = new Group(Name = TEST2_QUEUE_LABEL, Type = CDdSupportConstants.GROUP_QUEUE);
        insert testGroup2;
        QueuesObject test2Queue;

        //Creating Group3
        Group testGroup3 = new Group(Name = TEST3_QUEUE_LABEL, Type = CDdSupportConstants.GROUP_QUEUE);
        insert testGroup3;
        QueuesObject test3Queue;

        //Creating Group4
        Group testGroup4 = new Group(Name = TEST4_QUEUE_LABEL, Type = CDdSupportConstants.GROUP_QUEUE);
        insert testGroup4;
        QueuesObject test4Queue;
        
        System.runAs(new User(Id=UserInfo.getUserId())) {
            //Associating queue with group AND to the Case object
            testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = CDdSupportConstants.CASE_OBJECT_LABEL);
            insert testQueue;
            test2Queue = new QueueSObject(QueueID = testGroup2.id, SObjectType = CDdSupportConstants.CASE_OBJECT_LABEL);
            insert test2Queue;
            test3Queue = new QueueSObject(QueueID = testGroup3.id, SObjectType = CDdSupportConstants.CASE_OBJECT_LABEL);
            insert test3Queue;
            test4Queue = new QueueSObject(QueueID = testGroup4.id, SObjectType = CDdSupportConstants.CASE_OBJECT_LABEL);
            insert test4Queue;
        }
        
        //create configs
        Site_Escalation_Config__c escConfigObj = 
                                new Site_Escalation_Config__c (Name = CDdSupportConstants.ROLE_HQ_SUPERVISOR,
                                                                Queue_Id__c = testGroup.Id,
                                                               From_Queue_Id__c='',
                                                                Queue_Label__c = CDdSupportConstants.TEST_QUEUE_LABEL,
                                                                Site_Role_Name__c = CDdSupportConstants.ROLE_HQ_SUPERVISOR,
                                                                IsEscalation__c = true);
        insert escConfigObj;
        
         Site_Escalation_Config__c escConfigObj2 = 
                                new Site_Escalation_Config__c (Name = CDdSupportConstants.ROLE_HQ_SUPERVISOR,
                                                                Queue_Id__c = testGroup.Id,
                                                                From_Queue_Id__c=testGroup2.Id,
                                                               Site_Role_Name__c ='',
                                                                Queue_Label__c = TEST2_QUEUE_LABEL,
                                                                IsEscalation__c = true);
        insert escConfigObj2;
      
        Site_Escalation_Config__c escConfigObj3 = new Site_Escalation_Config__c (Name = TEST3_QUEUE_LABEL,
                                                                                 Queue_Id__c = testGroup3.Id,
                                                                                 Queue_Label__c = TEST3_QUEUE_LABEL,
                                                                                 IsTransfer__c = true);
        insert escConfigObj3;
        
        Site_Escalation_Config__c escConfigObj4 = new Site_Escalation_Config__c (Name = CDdSupportConstants.ROLE_HQ_SUPERVISOR,
                                                                                Queue_Id__c = testGroup4.Id,
                                                                                From_Queue_Id__c='',
                                                                                Queue_Label__c = TEST4_QUEUE_LABEL,
                                                                                Site_Role_Name__c = CDdSupportConstants.ROLE_HQ_SUPERVISOR,
                                                                                IsEscalation__c = true);
        insert escConfigObj4;
    }
  
    /**
     * @author      Sahil
     * @date        March 2021
     * @jira        https://doordash.atlassian.net/browse/BZAPSUP-1095
     * @description Method for testing get site escalations by logged in user's role id
    */ 
    @isTest
    static void testGetConfigsByRole() {
        User runningUser = TDdUserFactory.createUsersWithoutRole(1,null,false)[0];
        Id userRoleId = [SELECT Id, DeveloperName, Name FROM UserRole
                        WHERE DeveloperName =: CDdSupportConstants.ROLE_HQ_SUPERVISOR_DEV_NAME LIMIT 1].Id;
        runningUser.UserRoleId = userRoleId;
        System.runAs(runningUser) {
            Map<string,String> cacheKeySetMap = new Map<string,String>();
            
             if(userRoleId != null){
        
        cacheKeySetMap.put(CDdSiteEscalationConfigService.SITE_CONFIGS+String.valueOf(userRoleId),String.valueof(userRoleId));
        }
      
        Test.startTest();
        CDdSiteEscalationConfigService.getCachedSiteEscConfigsByUserRoleId(runningUser.UserRoleId,cacheKeySetMap);
        //run 2nd time to retrieve from cache
        CDdSiteEscalationConfigService.getCachedSiteEscConfigsByUserRoleId(runningUser.UserRoleId,cacheKeySetMap);
        Test.stopTest();
        
        System.assertEquals(1,CDdSiteEscalationConfigService.getCachedSiteEscConfigsByUserRoleId(runningUser.UserRoleId,cacheKeySetMap).size(),
                            '1 config should be returned from Database');
        }
    }

    /**
     * @author      Sahil
     * @date        March 2021
     * @jira        https://doordash.atlassian.net/browse/BZAPSUP-1095
     * @description Negative test for get site escalations by logged in user's role id
    */ 
    @isTest
    static void testGetConfigsNegative() {
        Id userRoleId = [SELECT Id, DeveloperName, Name FROM UserRole
                            WHERE DeveloperName = 'Account_Manager' LIMIT 1].Id;
        User runningUser = TDdUserFactory.createUsers(1,null,userRoleId,false)[0];
        System.runAs(runningUser) {
             Map<string,String> cacheKeySetMap = new Map<string,String>();
            
             if(userRoleId != null){
        
        cacheKeySetMap.put(CDdSiteEscalationConfigService.SITE_CONFIGS+String.valueOf(userRoleId),String.valueof(userRoleId));
        }
            Test.startTest();
        CDdSiteEscalationConfigService.getCachedSiteEscConfigsByUserRoleId(runningUser.UserRoleId,cacheKeySetMap);
        Test.stopTest();
        

        System.assertEquals(0,CDdSiteEscalationConfigService.getCachedSiteEscConfigsByUserRoleId(runningUser.UserRoleId,cacheKeySetMap).size(),
                            'No configs should be returned from Database');
        }
    }
    
     @isTest
    static void testInvalidTransfer() {
         //Creating Group
         Group testGroup = new Group(Name='Test Queue', Type = CDdSupportConstants.GROUP_QUEUE);
         insert testGroup;
         QueuesObject testQueue;
         System.runAs(new User(Id=UserInfo.getUserId())) {
             //Associating queue with group AND to the Case object
             testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = CDdSupportConstants.CASE_OBJECT_LABEL);
             insert testQueue;

             //create configs
             Site_Escalation_Config__c escConfigObj = new Site_Escalation_Config__c( Name = CDdSupportConstants.ROLE_HQ_SUPERVISOR,
                                                             Queue_Id__c = testQueue.Id,
                                                             Queue_Label__c = CDdSupportConstants.ROLE_CEBU_ESC_DEV_NAME,
                                                             Site_Role_Name__c = CDdSupportConstants.ROLE_HQ_SUPERVISOR_DEV_NAME,
                                                             IsEscalation__c = true,
                                                             IsTransfer__c = true
                                                             );
            insert escConfigObj;
         }

          Id newOwnerId = [SELECT Id FROM Group WHERE Type =: CDdSupportConstants.GROUP_QUEUE
                            AND DeveloperName =: CDdSupportConstants.ROLE_CEBU_ESC_DEV_NAME LIMIT 1].Id;

          User runningUser = TDdUserFactory.createUsersWithoutRole(1,null,false)[0];
          Boolean isError = false; 
          System.runAs(runningUser) {
              List<Case> testCaseList = TDdCaseFactory.createCaseRecords(1, CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER);
              Case testCase = testCaseList[0];
              try{
                insert testCase;
                //assert the test case was created
                List<Case> testCaseFromDBList = [SELECT Id FROM Case WHERE Id =:testCase.Id];
                System.assertEquals(1,testCaseFromDBList.size(),'1 test case should be returned from Database');
                testCase.OwnerId = testQueue.Id;
                testCase.Issue__c = CDdSupportConstants.CASE_ISSUE_ACCT_SETTINGS;
                testCase.Issue_Type__c = CDdSupportConstants.CASE_ISSUE_ACCT_MGMT;
                testCase.Escalation_Reason__c = CDdSupportConstants.CASE_ESC_REASON_SUP_OPS;
                Test.startTest();
                update testCase;
              } catch (Exception e) {
                 
                isError = true;
              }
              Test.stopTest();
              System.assertEquals(true,isError,'An exception should be thrown');
          }
    }
    
    /**
     * @author      Mahesh Chouhan
     * @date        Feb 2022
     * @jira        https://doordash.atlassian.net/browse/BASD-13723
     * @description Method for testing get site escalations by logged in user without role
    */ 
    @isTest
    static void testGetConfigsWithoutRole() {
        User runningUser = TDdUserFactory.createUsersWithoutRole(1, null, false)[0];
        List<Group> testQueue1 = [SELECT Id FROM Group WHERE Name = :CDdSupportConstants.TEST_QUEUE_LABEL];
        List<Group> testQueue2 = [SELECT Id FROM Group WHERE Name = :TEST2_QUEUE_LABEL];
        List<Group> testQueue3 = [SELECT Id FROM Group WHERE Name = :TEST3_QUEUE_LABEL];
        System.runAs(runningUser) {
            Map<string, String> cacheKeySetMap = new Map<string, String>();
            cacheKeySetMap.put(CDdSiteEscalationConfigService.SITE_CONFIGS+String.valueOf(testQueue1[0].Id) + String.valueOf(testQueue2[0].Id),
                                String.valueOf(testQueue1[0].Id) + '0KY0' + String.valueOf(testQueue2[0].Id));
            cacheKeySetMap.put(CDdSiteEscalationConfigService.SITE_CONFIGS+String.valueOf(testQueue3[0].Id),String.valueOf(testQueue3[0].Id));
        
        Test.startTest();
        CDdSiteEscalationConfigService.getCachedSiteEscConfigsByUserRoleId(runningUser.UserRoleId,cacheKeySetMap);
        //run 2nd time to retrieve from cache
        CDdSiteEscalationConfigService.getCachedSiteEscConfigsByUserRoleId(runningUser.UserRoleId,cacheKeySetMap);
        Test.stopTest();
        
        System.assertEquals(2, CDdSiteEscalationConfigService.getCachedSiteEscConfigsByUserRoleId(runningUser.UserRoleId,cacheKeySetMap).size(),
                            '2 config should be returned from Database');
        }
    }
}