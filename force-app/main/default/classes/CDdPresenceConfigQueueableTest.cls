/**
  * @author:Naren K
  * @date  07/20/2021
  * @decription: Test class for CDdPresenceConfigQueueable
  */
@isTest
public class CDdPresenceConfigQueueableTest {
    private static final Integer BATCH_SIZE = 200;
    public static final Id TEST_ROLE_ID;
    public static final Id HQ_TEAM_PROFILE_ID;
    public static final Id CHANNEL_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    static {
        TEST_ROLE_ID = [SELECT Id 
                        FROM UserRole 
                        WHERE DeveloperName = 'COO'].Id;
        HQ_TEAM_PROFILE_ID = [SELECT Id 
                              FROM Profile 
                              WHERE Name = 'HQ Team'].Id;
        CHANNEL_ID = [SELECT Id 
                      FROM PresenceUserConfig 
                      WHERE DeveloperName = 'Live_Agent'].Id;
    }
    
/** 
* @description Prepare and return the test running user
*/
    private static User getTestRunUser() {
        User testRunUser = null;
        for (User u : [SELECT Id 
                       FROM User 
                       WHERE UserName = :TEST_DD_RUN_USERNAME]){
            testRunUser = u;
        }
        if (testRunUser == null){
            testRunUser = TDdAccountFactory.createUsers(1, null, TEST_ROLE_ID)[0]; 
            testRunUser.Username = TEST_DD_RUN_USERNAME;
        }
        return testRunUser;
    }
    
    @testSetup
    static void testSetup() {
        List<User> testUsers = TDdAccountFactory.createUsers(1,HQ_TEAM_PROFILE_ID,null);
        insert testUsers;
    }
    
    @isTest
    public static void testInsertPresenceUserConfigUserQueueable(){
        System.runAs(getTestRunUser()){
            
            User userRec = [Select Id 
                            From User 
                            Where ProfileId=:HQ_TEAM_PROFILE_ID 
                            limit 1];
            List<CDdPresenceConfigQueueable.WrapperData> wrplist = new List<CDdPresenceConfigQueueable.WrapperData>();
            CDdPresenceConfigQueueable.WrapperAttributes atr = new CDdPresenceConfigQueueable.WrapperAttributes();
            atr.type = 'PresenceUserConfigUser';
            CDdPresenceConfigQueueable.WrapperData wrpdata = new CDdPresenceConfigQueueable.WrapperData();
            wrpdata.UserId = userRec.id;
            wrpdata.PresenceUserConfigId = CHANNEL_ID;
            wrpdata.attributes = atr;
            wrplist.add(wrpdata);
            
            Test.startTest();
            CDdPresenceConfigQueueable.insertPresenceUserConfigUserQueueable insertPresQueueable = new CDdPresenceConfigQueueable.insertPresenceUserConfigUserQueueable('CDdPresenceConfigQueueable_test', wrplist,BATCH_SIZE,CDdPresenceConfigQueueable.START_INDEX_0);
            Id jobId = System.enqueueJob(insertPresQueueable);
            Test.stopTest();
            system.assert(jobId!=null, 'Job has been submitted.');
        }
    }
    
    @isTest
    public static void testRemoveUserFromChannel(){
        System.runAs(getTestRunUser()){
            
            User userRec = [SELECT Id 
                            From User 
                            WHERE ProfileId=:HQ_TEAM_PROFILE_ID 
                            LIMIT 1];
            List<PresenceUserConfigUser> presUserConfigUserList= new List<PresenceUserConfigUser>();
            PresenceUserConfigUser presUserCnfRec = new PresenceUserConfigUser();
            presUserCnfRec.UserId = userRec.Id;
            presUserCnfRec.PresenceUserConfigId = CHANNEL_ID;
            presUserConfigUserList.add(presUserCnfRec);
            
            List<Id> selectedUserIdLst = new List<Id>{userRec.Id};
            
            Test.startTest();
            CDdPresenceConfigQueueable presQueueable = new CDdPresenceConfigQueueable(presUserConfigUserList,selectedUserIdLst);
            Id jobId = System.enqueueJob(presQueueable);
            Test.stopTest();
            system.assert(jobId!=null, 'Job has been submitted.');
        }
    }

}