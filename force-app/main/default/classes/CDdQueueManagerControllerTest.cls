/**
 * @author: Tia Xuan
 * @date: 04-2021
 * @description Test class for CDdQueueManagerController.
 */

@isTest
public class CDdQueueManagerControllerTest {

    public static final String TEST_SUPERVISOR_ROLE = 'Bengaluru Supervisor';
    public static final String TEST_AGENT_ROLE = 'Bengaluru Agent';

    @TestSetup
    static void setupData(){
        Group queue =  [select Id from Group where Type = 'Queue' limit 1];
        QM_Queue_Setting__c queueSetting = new QM_Queue_Setting__c();
        queueSetting.Name = 'test';
        queueSetting.Queue_Id__c = queue.Id;
        insert queueSetting;

        QM_Role_Setting__c roleSetting = new QM_Role_Setting__c();
        roleSetting.Name = TEST_SUPERVISOR_ROLE;
        roleSetting.Parent_Role_Name__c = TEST_SUPERVISOR_ROLE;
        roleSetting.Role_Name__c = TEST_AGENT_ROLE;
        insert roleSetting;
    }

    @isTest
    static void getFilterCriteriaTest() {
        User supervisorUser = [select Id, UserRoleId, Email from User where IsActive =true and UserRole.Name =: TEST_SUPERVISOR_ROLE limit 1];
        Test.startTest();
        System.runAs(supervisorUser) {
            CDdQueueManagerController.QueueManagerWrapper wrp = CDdQueueManagerController.getFilterCriteria();
            System.assertEquals(wrp.queueList.size(), 1, 'No queues defined');
            System.assertEquals(wrp.roleList.size(), 1, 'No roles defined');
        }
        Test.stopTest();
    }

    @isTest
    static void getUsersTest() {
        User supervisorUser = [select Id, UserRoleId, Email from User where IsActive =true and UserRole.Name =: TEST_SUPERVISOR_ROLE limit 1];
        User agentUser = [select Id, UserRoleId, Email from User where IsActive =true and UserRole.Name =: TEST_AGENT_ROLE limit 1];

        Test.startTest();
        System.runAs(supervisorUser) {
            List<String> roles = new List<String>{TEST_AGENT_ROLE};
            List<String> emails = new List<String>{agentUser.Email};
            List<String> userIds = new List<String>{agentUser.Id};
            List<CDdQueueManagerController.UserWrapper> usrList = CDdQueueManagerController.getUsers(roles, emails,userIds, 'role');
            System.assert(usrList.size() > 1, 'No users found');

            usrList = CDdQueueManagerController.getUsers(roles, emails, userIds,'refreshData');
            System.assertEquals(usrList.size(), 1, 'No users found');
        }
        Test.stopTest();
    }

    @isTest
    static void updateQueuesTest() {
        User supervisorUser = [select Id, UserRoleId, Email from User where IsActive =true and UserRole.Name =: TEST_SUPERVISOR_ROLE limit 1];
        User agentUser = [select Id, UserRoleId, Email from User where IsActive =true and UserRole.Name =: TEST_AGENT_ROLE limit 1];

        QM_Queue_Setting__c queueSetting = [select Id, Queue_Id__c from QM_Queue_Setting__c limit 1];

        GroupMember gm = new GroupMember();
        gm.UserOrGroupId = agentUser.Id;
        gm.GroupId = queueSetting.Queue_Id__c;
        insert gm;

        Test.startTest();

        List<String> userIds = new List<String>{agentUser.Id};
        List<String> queueList = new List<String>{queueSetting.Queue_Id__c};

        CDdQueueManagerController.updateQueues(userIds, queueList);
        List<GroupMember> grpMembers = [select Id, GroupId from GroupMember where UserOrGroupId =: agentUser.Id and GroupId =: queueSetting.Queue_Id__c];
        System.assertEquals(grpMembers.size(), 1, 'No group membership found');
        Test.stopTest();

        List<Queue_Manager_Audit__c> audits = [select Id from Queue_Manager_Audit__c where User__c =: agentUser.Id];
        System.assertEquals(audits.size(), 2, 'No audits found');

        Boolean qmCache = (Boolean) CDdCacheService.getFromOrgCache(CDdSupportConstants.QUEUE_MONITOR_PREFIX + agentUser.Id);
        System.assertEquals(qmCache, true, 'No cache value found');
    }
}