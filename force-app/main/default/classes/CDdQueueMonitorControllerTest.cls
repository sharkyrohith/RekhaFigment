/**
 * @author: Tia Xuan
 * @date: 04-2021   
 * @description Test class for CDdQueueManagerController. 
 */ 
@isTest
public class CDdQueueMonitorControllerTest {

    @TestSetup
    static void setupData(){
        Group queue =  [select Id from Group where Type = 'Queue' limit 1];
        QM_Queue_Setting__c queueSetting = new QM_Queue_Setting__c();
        queueSetting.Name = 'test';
        queueSetting.Queue_Id__c = queue.Id;
        insert queueSetting;

        Support_Settings__c supportSetting = Support_Settings__c.getInstance();
        supportSetting.QM_Interval_Time__c = 50000;
        supportSetting.QM_Interval_Cache_Time__c = 50000;
        insert supportSetting;
    } 

    @isTest
    static void initQMTest() {
        User cUser = [select Id, UserPermissionsLiveAgentUser from User where Id =: UserInfo.getUserId()];
        QM_Queue_Setting__c queueSetting = QM_Queue_Setting__c.getAll().values()[0];
        GroupMember gm = new GroupMember();
        gm.UserOrGroupId = UserInfo.getUserId();
        gm.GroupId = queueSetting.Queue_Id__c;
        insert gm;

        Test.startTest(); 
            CDdQueueMonitorController.QueueMonitorWrapper wrp = CDdQueueMonitorController.initQM();
            System.assertEquals(wrp.isLiveAgentUser, cUser.UserPermissionsLiveAgentUser, 'Live Agent Permissions missing');
            System.assertNotEquals(wrp.queueMemberships, null, 'Error with queue Memberships');
        Test.stopTest();
    }

    @isTest
    static void checkCurrentQueueMembershipTest() {
        CDdCacheService.putInOrgCache(CDdQueueMonitorController.QM_CACHE_KEY, true);
        QM_Queue_Setting__c queueSetting = QM_Queue_Setting__c.getAll().values()[0];
        GroupMember gm = new GroupMember();
        gm.UserOrGroupId = UserInfo.getUserId();
        gm.GroupId = queueSetting.Queue_Id__c;
        insert gm;

        Test.startTest(); 
        String gms =  CDdQueueMonitorController.checkCurrentQueueMembership('');
        System.assertNotEquals(gms, null, 'Queue memberships missing');

        Test.stopTest();
    }
}