/**
  * @author:Naren K
  * @date  07/20/2021
  * @decription: Test class for CDdUserNestingCtrl
  */
@isTest
public class CDdUserNestingCtrlTest {
    public static final Id TEST_ROLE_ID;
    public static final Id HQ_TEAM_PROFILE_ID;
    public static final Id CHANNEL_ID;
    public static final String LIVE_AGNT_CHNL = 'Live_Agent';
    public static final String TEST_ROLE_NAME = 'COO';
    public static final String TEST_HQ_PROFILE = 'HQ Team';
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    public static final String TEST_HQ_RUN_USERNAME = 'testhq.runninguser@doordash.com';
    static {
        TEST_ROLE_ID = [SELECT Id 
                        FROM UserRole 
                        WHERE DeveloperName =: TEST_ROLE_NAME].Id;
        HQ_TEAM_PROFILE_ID = [SELECT Id 
                              FROM Profile 
                              WHERE Name =: TEST_HQ_PROFILE].Id;
        CHANNEL_ID = [SELECT Id 
                      FROM PresenceUserConfig 
                      WHERE DeveloperName =: LIVE_AGNT_CHNL].Id;
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
            testRunUser = TDdUserFactory.createUsers(1, null, TEST_ROLE_ID, false)[0]; 
            testRunUser.Username = TEST_DD_RUN_USERNAME;
        }
        return testRunUser;
    }
    
    private static User getHQTeamTestRunUser() {
        User testRunHQTeamUser = null;
        for (User u : [SELECT Id 
                       FROM User 
                       WHERE UserName = :TEST_HQ_RUN_USERNAME]){
            testRunHQTeamUser = u;
        }
        if (testRunHQTeamUser == null){
            testRunHQTeamUser = TDdUserFactory.createUsers(1, null, TEST_ROLE_ID, false)[0];
            testRunHQTeamUser.Username = TEST_HQ_RUN_USERNAME;
            testRunHQTeamUser.profileId = HQ_TEAM_PROFILE_ID;
        }
        return testRunHQTeamUser;
    }
    
    @testSetup
    static void testSetup() {
        List<User> testUsers = TDdUserFactory.createUsers(1,HQ_TEAM_PROFILE_ID,TEST_ROLE_ID, false);
        insert testUsers;
    }
    
    @isTest
    public static void testGetUserPerm1(){
        System.runAs(getTestRunUser()){
            Test.startTest();
            boolean result = CDdUserNestingCtrl.getUserPerm();
            System.assertEquals(true, result, 'Current user has the permission to show the lwc component LWCDdUserNesting to current user.');
            Test.stopTest();
        }
    }
    
    @isTest
    public static void testGetUserPerm2(){
        System.runAs(getHQTeamTestRunUser()){
            Test.startTest();
            boolean result = CDdUserNestingCtrl.getUserPerm();
            System.assertEquals(false, result, 'Current user has not the permission to show the lwc component LWCDdUserNesting to current user.');
            Test.stopTest();
        }
    }
    
    @isTest
    public static void testGetChannelNames(){
        System.runAs(getTestRunUser()){
            Test.startTest();
            List<presenceUserConfig> presUserConfigLst = CDdUserNestingCtrl.getChannelNames();
            // Checking channel 
            System.assert(presUserConfigLst.size()>0,'Getting the channels');
            Test.stopTest();
        }
    }
    
    @isTest
    public static void testGetUsers(){
        System.runAs(getTestRunUser()){
            Test.startTest();
            // wrong filter
            List<User> systemUserLst1 = CDdUserNestingCtrl.getUsers('TestUser', 'doordash', 'System', 'TestRole');
            system.assertEquals(0, systemUserLst1.size(),'System Admin profile is not available in the Nesting profile list, then return list count is zero.');
            
            // Correct Filter
            List<User> systemUserLst2 = CDdUserNestingCtrl.getUsers('TestUser', '', 'HQ', 'COO');
            system.assertEquals(1, systemUserLst2.size(),'Only One user has the HQ Team profile, then return list count is one.');
            
            // No filter 
            List<User> systemUserLst3 = CDdUserNestingCtrl.getUsers('', '', '', '');
            system.assert(systemUserLst3.size()>0, 'Returned users list.');
            Test.stopTest();
        }
    }
    
    @isTest
    public static void testAddUserToChannel(){
        System.runAs(getTestRunUser()){
            Test.startTest();
            List<User> userRecList = [SELECT Id 
                                      FROM User 
                                      WHERE ProfileId=:HQ_TEAM_PROFILE_ID];
            boolean resultData1 = CDdUserNestingCtrl.addUserToChannel(userRecList, 'Live_Agent');
            System.assertEquals(true, resultData1, '"Live_Agent" channel is available in the salesforce.');
            
            boolean resultData2 = CDdUserNestingCtrl.addUserToChannel(userRecList, '');
            System.assertEquals(false, resultData2, 'Channel is blank as argument.');
            
            boolean resultData3 = CDdUserNestingCtrl.addUserToChannel(userRecList, 'Testing');
            System.assertEquals(false, resultData3, 'Channel is not found.');
            
            Test.stopTest();
        }
    }
    
    @isTest
    public static void testRemoveUserFromChannel(){
        System.runAs(getTestRunUser()){
            Test.startTest();
            User userRec = [Select Id 
                            FROM User 
                            WHERE ProfileId=:HQ_TEAM_PROFILE_ID 
                            LIMIT 1];
            
            List<PresenceUserConfigUser> presUserConfigUserList= new List<PresenceUserConfigUser>();
            PresenceUserConfigUser presUserCnfRec = new PresenceUserConfigUser();
            presUserCnfRec.UserId = userRec.Id;
            presUserCnfRec.PresenceUserConfigId = CHANNEL_ID;
            presUserConfigUserList.add(presUserCnfRec);
            boolean resp = CDdUserNestingCtrl.removeUserFromChannel(presUserConfigUserList);
            System.assertEquals(false, resp,'No record found in PresenceUserConfigUser.');
            Test.stopTest();
        }
    }
    
    @isTest
    public static void testGetPresUserConfigUser(){
        System.runAs(getTestRunUser()){
            Test.startTest();
            
            List<PresenceUserConfigUser> presUserCnfUserLst1 = CDdUserNestingCtrl.getPresUserConfigUser('TestUser', 'doordash', 'HQ', 'TestRole','Live_Agent');
            system.assertEquals(0, presUserCnfUserLst1.size(),'No users are tagged with Live_Agent channel.');
            
            List<PresenceUserConfigUser> presUserCnfUserLst2 = CDdUserNestingCtrl.getPresUserConfigUser('', '', '', '','');
            system.assert(presUserCnfUserLst2.size()>0, 'PresenceUserConfigUser records are returned.');
            
            Test.stopTest();
        }
    }
    // Success Scenario
    @isTest
    public static void testReadCSVFile1(){
        System.runAs(getTestRunUser()){
            Test.startTest();
            String action1 = 'Insert';
            User userRec = [Select Id From User Where ProfileId=:HQ_TEAM_PROFILE_ID limit 1];
            
            String csv1 = 'UserId,PresenceUserConfigId,Action\n';
            csv1 += userRec.Id + ',' + CHANNEL_ID + ',' + action1.escapeCsv() + '\n';
            
            //Create Document
            ContentVersion cvRec1 = new ContentVersion();
            cvRec1.Title = 'TestDocument.csv';
            cvRec1.PathOnClient = '/TestDocument.csv';
            cvRec1.VersionData = Blob.valueOf( csv1 );
            cvRec1.IsMajorVersion = true;
            Insert cvRec1;
            
            //Get Content Version
            List<ContentVersion> cvList = [SELECT Id, ContentDocumentId 
                                           FROM ContentVersion 
                                           WHERE Id = :cvRec1.Id];
            Map<String,List<String>> resRetMap = CDdUserNestingCtrl.readCSVFile(cvList[0].ContentDocumentId);
            system.assert(resRetMap.keySet().contains('Success'),'No error in file');
            
            Test.stopTest();
        }
    }
    // Error Scenario
    @isTest
    public static void testReadCSVFile2(){
        System.runAs(getTestRunUser()){
            Test.startTest();
            String action = 'Test';
            User userRec = [SELECT Id 
                            FROM User 
                            WHERE ProfileId=:HQ_TEAM_PROFILE_ID 
                            LIMIT 1];
            String csv = 'UserId,PresenceUserConfigId,Action\n';
            csv += CHANNEL_ID + ',' + userRec.Id + ',' + action.escapeCsv() + '\n';
            csv += CHANNEL_ID+'0000' + ',' + userRec.Id + ',' + action.escapeCsv() + '\n';
            
            //Create Document
            ContentVersion cvRec = new ContentVersion();
            cvRec.Title = 'TestDocument.csv';
            cvRec.PathOnClient = '/TestDocument.csv';
            cvRec.VersionData = Blob.valueOf( csv );
            cvRec.IsMajorVersion = true;
            Insert cvRec;
            
            //Get Content Version
            List<ContentVersion> cvList = [SELECT Id, ContentDocumentId 
                                           FROM ContentVersion 
                                           WHERE Id = :cvRec.Id];
            Map<String,List<String>> resRetMap = CDdUserNestingCtrl.readCSVFile(cvList[0].ContentDocumentId);
            system.assert(resRetMap.keySet().contains('Error'),'Error in file.');
            
            Test.stopTest();
        }
    }
    
    // Error Scenario
    @isTest
    public static void testReadCSVFile3(){
        System.runAs(getTestRunUser()){
            Test.startTest();
            Id conId =null;
            Map<String,List<String>> resRetMap = CDdUserNestingCtrl.readCSVFile(conId);
            system.assert(resRetMap.keySet().contains('Error'),'There is an error in uplaoding csv file.');
            Test.stopTest();
        }
    }
    
}