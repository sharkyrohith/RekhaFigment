/*
 * @author Knick
 * @Date June 2020
 * @Description: Test Class for CDdUserTriggerHelper
*/
@isTest
public class CDdUserTriggerHelperTest {

    public static List<User> TEST_USER;
    public static List<User> lightningUserList;
    public static Id LicenseId;
    public static Id PackageId;
    public static Id agentProfileId;
    public static List<Id> lightningProfileIdList = new List<Id>();
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    public static final Id TEST_ROLE_ID;

    static {
        List<User_License__mdt> checkList = CDdCustomMetadata.getUserLicenseList();
        system.assertEquals(1, checkList.size(), 'Problem with required metadata.');
        List<Id> ProfileIDs = new List<Id>(CDdCustomMetadata.profileIDs(checkList[0].Profiles__c, ','));
        LicenseId = [SELECT Id, MasterLabel FROM PermissionSetLicense WHERE MasterLabel = :checklist[0].Permission_Set_Licenses__c].Id;
        PackageId = [SELECT Id, NamespacePrefix FROM PackageLicense WHERE NamespacePrefix = :checklist[0].Package_Licenses__c].Id;
        TEST_USER = TDdAccountFactory.createUsers(2, ProfileIDs[0], null);
        TEST_USER[0].IsActive = false;
        TEST_USER[1].IsActive = true;
        insert TEST_USER;
        TEST_ROLE_ID = [SELECT Id FROM UserRole WHERE DeveloperName = 'COO'].Id;

        //insert a lightning profile user
        List<String> profileIdList = CDdNameValuePairHelper.getTextValue(CDdNameValuePairConstants.LIGHTNING_SUP_PROFILEIDS).split(CDdCoreConstants.DELIMITER_COMMA);
        for (String profileVar : profileIdList) {
            lightningProfileIdList.add(CDdUtilities.returnValidId(profileVar));
        }
        lightningUserList = TDdUserFactory.createUsers(1);
        lightningUserList[0].ProfileId = lightningProfileIdList[0];
        System.runAs(getTestRunUser()) {
            insert lightningUserList;
        }

        //get agent profile Id from DB
        List<Profile> profileIdListAgent = [SELECT Id,Name FROM Profile WHERE Name = 'Agent'];
        if (!profileIdListAgent.isEmpty()) {
            agentProfileId = profileIdListAgent[0].Id;
        }

        System.runAs(getTestRunUser()) {
            Support_Feature_Flag__c featureFlag = Support_Feature_Flag__c.getOrgDefaults();
            featureFlag.Revert_to_Lightning_Profile__c = true;
            upsert featureFlag;
        }
        CDdRecursionUtils.resetRecursion('TDdUserTrigger');
    }

    private static User getTestRunUser() {
        User testRunUser = null;
        for (User u : [SELECT Id FROM User WHERE UserName = :TEST_DD_RUN_USERNAME]){
            testRunUser = u;
        }
        if (testRunUser == null){
            testRunUser = TDdAccountFactory.createUsers(1, null, TEST_ROLE_ID)[0];
            testRunUser.Username = TEST_DD_RUN_USERNAME;
        }
        return testRunUser;
    }

    @isTest static void assignPermissionsTest() {
        User checkUser = [SELECT Id, IsActive FROM User WHERE Id = :TEST_USER[0].Id];
        system.assertEquals(false, checkUser.IsActive, 'User should be inactive before activation.');
        AggregateResult[] existingLicenses = [
            SELECT Count(Id) theCount FROM PermissionSetLicenseAssign
            WHERE PermissionSetLicenseId = :LicenseId
            AND AssigneeId = :TEST_USER[0].Id
        ];
        system.assertEquals(0, existingLicenses[0].get('theCount'), 'User should have 0 licenses before activation.');
        AggregateResult[] existingPackages = [
            SELECT COUNT(Id) theCount FROM UserPackageLicense
            WHERE PackageLicenseId = :PackageId
            AND UserId = :TEST_USER[0].Id
        ];
        system.assertEquals(0, existingPackages[0].get('theCount'), 'User should have 0 packages before activation.');
        test.startTest();
            User u = new User(Id = TEST_USER[0].Id, IsActive = true);
            system.debug('Updating user: ' + u); update u;
            test.getEventBus().deliver();
        test.stopTest();
        checkUser = [SELECT Id, IsActive FROM User WHERE Id = :TEST_USER[0].Id];
        system.assertEquals(true, checkUser.IsActive, 'User should be active after activation.');
        existingLicenses = [
            SELECT Count(Id) theCount FROM PermissionSetLicenseAssign
            WHERE PermissionSetLicenseId = :LicenseId
            AND AssigneeId = :TEST_USER[0].Id
        ];
        system.assertEquals(1, existingLicenses[0].get('theCount'), 'User should have 1 license after activation.');
        existingPackages = [
            SELECT COUNT(Id) theCount FROM UserPackageLicense
            WHERE PackageLicenseId = :PackageId
            AND UserId = :TEST_USER[0].Id
        ];
        system.assertEquals(1, existingPackages[0].get('theCount'), 'User should have 1 package after activation.');
        u = new User(Id = TEST_USER[0].Id, IsActive = false);
        system.debug('Updating user: ' + u); update u;
        update u;
        checkUser = [SELECT Id, IsActive FROM User WHERE Id = :TEST_USER[0].Id];
        system.assertEquals(false, checkUser.IsActive, 'User should be inactive after de-activation.');
        existingLicenses = [
            SELECT Count(Id) theCount FROM PermissionSetLicenseAssign
            WHERE PermissionSetLicenseId = :LicenseId
            AND AssigneeId = :TEST_USER[0].Id
        ];
        existingPackages = [
            SELECT COUNT(Id) theCount FROM UserPackageLicense
            WHERE PackageLicenseId = :PackageId
            AND UserId = :TEST_USER[0].Id
        ];
        system.assertEquals(0, existingPackages[0].get('theCount'), 'User should not have any package after de-activation.');
    }

    @isTest static void profileChangeTest() {
        String currentProfileId = TEST_USER[0].ProfileId;
        String currentUserId = UserInfo.getUserId();

        Profile p = [SELECT Id FROM Profile WHERE Name = :CDdSupportConstants.PROFILE_SYS_ADM LIMIT 1];
        TEST_USER[0].ProfileId = p.Id;
        Test.startTest();
        update TEST_USER[0];
        Test.stopTest();

        User toVerify = [SELECT Id,ProfileId,Profile_Change_History__c FROM User Where Id=:TEST_USER[0].Id];
        system.assert(toVerify.Profile_Change_History__c != null && toVerify.Profile_Change_History__c.startsWith(currentProfileId + CDdCoreConstants.DELIMITER_UNDERSCORE + currentUserId),
            'Incorrect Profile Change History: ' + toVerify.Profile_Change_History__c);
    }

    @isTest static void callCenterChangeTest() {
        String currentCallCenterId = TEST_USER[0].CallCenterId;
        String currentUserId = UserInfo.getUserId();

        List<Call_Center_Assignment__mdt> mdtList = [SELECT Id,Profile_Id__c,UserRole_Id__c,Call_Center_Id__c FROM Call_Center_Assignment__mdt LIMIT 1];

        if (!mdtList.isEmpty()) {
            Call_Center_Assignment__mdt mdt = mdtList[0];
            TEST_USER[0].ProfileId = mdt.Profile_Id__c;
            TEST_USER[0].UserRoleId = mdt.UserRole_Id__c;
            Test.startTest();
            update TEST_USER[0];
            Test.stopTest();

            User toVerify = [SELECT Id,CallCenterId,Call_Center_Change_Log__c FROM User WHERE Id=:TEST_USER[0].Id];
            system.assertEquals(mdt.Call_Center_Id__c,toVerify.CallCenterId,'Call Center id does not match');
            system.assert(toVerify.Call_Center_Change_Log__c != null && toVerify.Call_Center_Change_Log__c.startsWith(currentCallCenterId + CDdCoreConstants.DELIMITER_UNDERSCORE + currentUserId),
                'Incorrect Profile Change History: ' + toVerify.Call_Center_Change_Log__c);
        }
    }

    @isTest static void accountRoleUpdateTest() {
        TEST_USER[0].Title = CDdUserTriggerHelper.SPM_TITLE;
        Test.startTest();
        update TEST_USER[0];
        Test.stopTest();

        User toVerify = [SELECT Id,Account_Manager_Role__c FROM User WHERE Id=:TEST_USER[0].Id];
        system.assertEquals(CDdUserTriggerHelper.SPM_TITLE,toVerify.Account_Manager_Role__c,'Account Manager Role does not match');
    }

    @isTest static void validateCallCenterAssignmentMetadata() {
        Map<Id,Map<Id,Id>> dupeCheckerMap = new Map<Id,Map<Id,Id>>();
        for (Call_Center_Assignment__mdt cca : Call_Center_Assignment__mdt.getAll().values()) {
            Id profileId = CDdUtilities.returnValidId(cca.Profile_Id__c);
            Id userRoleId = CDdUtilities.returnValidId(cca.UserRole_Id__c);
            Id callCenterId = CDdUtilities.returnValidId(cca.Call_Center_Id__c);
            System.assertNotEquals(null,profileId,'Profile Id is invalid for Call_Center_Assignment__mdt record id: ' + cca.Id);
            System.assert(cca.Profile_Id__c.startsWithIgnoreCase('00e'),'Profile Id is invalid for Call_Center_Assignment__mdt record id: ' + cca.Id);
            System.assertNotEquals(null,userRoleId,'User Role Id is invalid for Call_Center_Assignment__mdt record id: ' + cca.Id);
            System.assert(cca.UserRole_Id__c.startsWithIgnoreCase('00E'),'User Role Id is invalid for Call_Center_Assignment__mdt record id: ' + cca.Id);
            System.assertNotEquals(null,callCenterId,'Call Center Id is invalid for Call_Center_Assignment__mdt record id: ' + cca.Id);
            System.assert(cca.Call_Center_Id__c.startsWithIgnoreCase('04v'),'Call Center Id is invalid for Call_Center_Assignment__mdt record id: ' + cca.Id);

            if (!dupeCheckerMap.containsKey(profileId)) {
                dupeCheckerMap.put(profileId,new Map<Id,Id>());
            }
            if (dupeCheckerMap.get(profileId).containsKey(userRoleId)) {
                System.assert(false,'Dupe Call_Center_Assignment__mdt record found - ' + cca.Id + ' and ' + dupeCheckerMap.get(profileId).get(userRoleId));
            } else {
                dupeCheckerMap.get(profileId).put(userRoleId,cca.Id);
            }
        }
    }
    @isTest static void deActivateUsersCaseReassignTest() {
        System.runAs(TEST_USER[1]){createAgentSetting();}
        System.runAs(TEST_USER[1]){createCaseRecords();}

        Test.startTest();
        User cUser=[select id,isactive from user where Id =: TEST_USER[1].Id limit 1];
        cUser.isactive=false;
        Update cUser;
        Test.stopTest();
    }
    private static void createAgentSetting(){
        Id agentProfileId = [select ProfileId from user where Id =: TEST_USER[1].Id limit 1].ProfileId ;
        insert new Agent_Setting__c(SetupOwnerId=agentProfileId , Profile_Name__c='agent',Is_Agent__c=true);
    }
    private static void createCaseRecords(){
        Id previousQueueId=[SELECT ID FROM Group WHERE DeveloperName = :CDdSupportConstants.QUEUE_DEVNAME_MXP_FALLBACK].Id;
        List<Case> caseRecordsToBeInserted = new List<Case>();
        List<Case> caseList = TDdCaseFactory.createCaseRecords(2,'Support');
        for(Integer i = 0; i < caseList.size(); i++){
            caseList[i].Status='New';
            caseList[i].ownerId=TEST_USER[1].Id;
            if(i == 0){
                caseList[i].Previous_Queue_ID__c = previousQueueId;
                caseList[i].Previous_Queue__c = 'Test Queue';
            }
            if(i == 1){
                caseList[i].Initial_Queue__c = previousQueueId;
                caseList[i].Previous_Queue_ID__c = null;
            }
            caseRecordsToBeInserted.add(caseList[i]);
        }
        Insert caseRecordsToBeInserted;
    }

     /**
     * @author      Sahil
     * @date        October 2022
     * @jira        https://doordash.atlassian.net/browse/BIZS-2057
     * @description test method for reverting to lightning experience
     */
    @isTest
    static void test_revertToLightning() {

        //get a lightning profile user and change its profile to classic user profile
        User lightningUser = lightningUserList[0];
        System.assertNotEquals(null, lightningUser, 'Lightning User should exist for testing further');
        //change user's profile to agent. profile change should not happen because feature flag is ON.
        System.assertNotEquals(null, agentProfileId, 'agent profile Id not found');
        lightningUser.ProfileId = agentProfileId;
        Test.startTest();
        update lightningUser;
        Test.stopTest();
        //get user from DB and assert that previous profile Id remains as new profile Id
        List<User> userFromDB = [SELECT ProfileId FROM User WHERE Id =:lightningUser.Id];
        System.assertNotEquals(0, userFromDB.size(), 'User not found in Database');
        System.assertEquals(true, lightningProfileIdList.contains(userFromDB[0].ProfileId) , 'User profile should be lightning');
    }
}