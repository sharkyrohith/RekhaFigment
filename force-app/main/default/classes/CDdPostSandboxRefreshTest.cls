/**
 * @author: Jeegar
 * @date: 11-2019
 * @description Test class for CDdPostSandboxRefresh.
 */

@isTest
class CDdPostSandboxRefreshTest {

    @isTest
    static void testUserUpdatesAfterRefresh() {
        List<Profile_Values__mdt> profileValues = [SELECT MasterLabel, Profile_Id__c FROM Profile_Values__mdt
                                                    WHERE MasterLabel in ('BizApps Team')];

        Id nonSystemAdminProfile = Id.valueOf(profileValues[0].Profile_Id__c);
        List<User> bizAppUsers = TDdAccountFactory.createUsers(4, nonSystemAdminProfile, null);

        Test.startTest();
        CDdPostSandboxRefresh.changeUserProfiles(false);
        Test.stopTest();

        List<User> bizAppUsersCount = [SELECT Id, ProfileID, Username
                                        FROM User
                                        WHERE ProfileID =: nonSystemAdminProfile
                                        AND IsActive = TRUE];

        System.assertEquals(0, bizAppUsersCount.size(), 'All users should have been moved to Sys Admin profile');
    }

    @isTest
    static void testUserUpdatesAfterRefreshWithRetry() {
        List<Profile_Values__mdt> profileValues = [SELECT MasterLabel, Profile_Id__c FROM Profile_Values__mdt
                                                    WHERE MasterLabel in ('BizApps Team')];

        Id nonSystemAdminProfile = Id.valueOf(profileValues[0].Profile_Id__c);
        List<User> bizAppUsers = TDdAccountFactory.createUsers(4, nonSystemAdminProfile, null);

        Test.startTest();
        CDdPostSandboxRefresh.changeUserProfiles(true);
        Test.stopTest();

        List<User> bizAppUsersCount = [SELECT Id, ProfileID, Username
                                        FROM User
                                        WHERE ProfileID =: nonSystemAdminProfile
                                        AND IsActive = TRUE];

        System.assertEquals(0, bizAppUsersCount.size(), 'All users should have been moved to Sys Admin profile');
    }



    @isTest
    static void testDeleteSSOEnabledPermissionSetAssignment() {
        List<PermissionSet> permSets = new List<PermissionSet>();
        List<PermissionSetAssignment> permAssignments;
        permSets = [Select Id, Name, Label from PermissionSet where name = 'SSO_Enabled'];
        if(permSets.size() > 0 ) {
            List<User> testUsers = TDdUserFactory.createUsers(1);
            for(User testUser : testUsers){
                insert testUser;
            }
            TDdUserFactory.createPermSetAssignment(testusers,permsets[0].id, true);
        }
        Integer currentSSOPermSetAssignments  = 0;
        permAssignments = [Select id from PermissionSetAssignment where PermissionSet.name = 'SSO_Enabled'];
        if(permAssignments != null) {
            currentSSOPermSetAssignments = permAssignments.size();
        }
        System.assert(currentSSOPermSetAssignments > 0, 'Should have more than 0 Permission Set Assignments for SSO Enabled Profile' );
        Test.startTest();
        CDdPostSandboxRefresh.deleteSSOEnabledPermissionSetAssignment();
        Test.stopTest();
        permAssignments = null;
        permAssignments = [Select id from PermissionSetAssignment where PermissionSet.name = 'SSO_Enabled'];
        if(permAssignments == null || permAssignments.size() == 0) {
            currentSSOPermSetAssignments = 0;
        }
        System.assertEquals(0, currentSSOPermSetAssignments, 'Permission Set Assignments are not deleted');

    }

    @isTest
    static void testInsertSeedData() {
        Integer subMarketCount = [Select id from Submarket__c].size();
        Integer realZipsCount = [Select id from RealZip__RealZips__c].size();
        Integer rzCountryCount = [Select id from RealZip__RealZip_Country__c].size();
        Integer rzCountryNameCount = [Select id from RealZip__RealCountry_Name__c].size();
        Integer rzObjectCount = [Select id from RealZip__RealObject__c].size();
        Integer rzTerritoryCount = [Select id from RealTerritory__c].size();

        System.assertEquals(0, subMarketCount, 'Should have 0 Submarkets');
        System.assertEquals(0, realZipsCount, 'Should have 0 RealZips');
        System.assertEquals(0, rzCountryCount, 'Should have 0 Countries');
        System.assertEquals(0, rzCountryNameCount, 'Should have 0 CountryNames');
        System.assertEquals(0, rzObjectCount, 'Should have 0 RZ Objects');
        System.assertEquals(0, rzTerritoryCount, 'Should have 0 Territories');

        Test.startTest();

        CDdPostSandboxRefresh.insertSeedData();

        Test.stopTest();
        subMarketCount = [Select id from Submarket__c].size();
        realZipsCount = [Select id from RealZip__RealZips__c].size();
        rzCountryCount = [Select id from RealZip__RealZip_Country__c].size();
        rzCountryNameCount = [Select id from RealZip__RealCountry_Name__c].size();
        rzObjectCount = [Select id from RealZip__RealObject__c].size();
        rzTerritoryCount = [Select id from RealTerritory__c].size();

        System.assertNotEquals(0, subMarketCount, 'Should have inserted Submarkets');
        System.assertNotEquals(0, realZipsCount, 'Should have inserted RealZips');
        System.assertNotEquals(0, rzCountryCount, 'Should have inserted Countries');
        System.assertNotEquals(0, rzCountryNameCount, 'Should have inserted CountryNames');
        System.assertNotEquals(0, rzObjectCount, 'Should have inserted RZ Objects');
        System.assertNotEquals(0, rzTerritoryCount, 'Should have inserted Territories');
    }
}