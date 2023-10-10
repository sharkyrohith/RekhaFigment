/**
 * @author: Jeegar
 * @date: 11-2019
 * @description:  Post Sandbox refresh apex Script.
 */

global class CDdPostSandboxRefresh implements SandboxPostCopy{

    global void runApexClass(SandboxContext context) {
        System.debug('CDdPostSandboxRefresh.runApexClass');
        changeUserProfiles(false);
        insertSeedData();
        deleteSSOEnabledPermissionSetAssignment();
    }

    /**
    * @author: Jeegar
    * @date: 11-2019
    * @description Updates the Users in BizApps Team profile and changes them to System Admin and changes email by removing '.invalid'.
                    Added Boolean retry param to test for retry logic
    */
    public static void changeUserProfiles(Boolean retry) {
        System.debug('CDdPostSandboxRefresh.changeUserProfiles');

        List<Profile_Values__mdt> profileValues = [SELECT MasterLabel, Profile_Id__c FROM Profile_Values__mdt
        WHERE MasterLabel in ('BizApps Team', 'System Administrator')];

        List<User> bizAppUsers;
        Id bizAppsProfileId;
        Id systemAdminProfileId;
        List<User> usersToUpdate = new List<User>();

        for (Profile_Values__mdt profileValue : profileValues) {
            if (profileValue.MasterLabel == 'BizApps Team') {
                bizAppsProfileId = Id.valueOf(profileValue.Profile_Id__c);
            } else if (profileValue.MasterLabel == 'System Administrator') {
                systemAdminProfileId = Id.valueOf(profileValue.Profile_Id__c);
            }
        }

        bizAppUsers = [SELECT Id, ProfileId, Email, Username
            FROM User
            WHERE IsActive = TRUE
            AND ProfileId =: bizAppsProfileId];

        for (User bizAppUser : bizAppUsers) {
            bizAppUser.ProfileId = systemAdminProfileId;
            bizAppUser.Email = bizAppUser.Email.removeEndIgnoreCase('.invalid');
            usersToUpdate.add(bizAppUser);
        }

        List<Database.SaveResult> results = Database.update(usersToUpdate, false);

        for (Database.SaveResult result : results) {
            if (!result.isSuccess()) {
                retry = true;
            }
        }

        if (retry) {
            List<User> usersToUpdateRetry = new List<User>();
            for (User bizAppUser : usersToUpdate) {
                bizAppUser.Username = bizAppUser.Username + 'a';
                usersToUpdateRetry.add(bizAppUser);
            }

            List<Database.SaveResult> retryResults = Database.update(usersToUpdateRetry, false);

            for (Database.SaveResult result : retryResults) {
                for (Database.Error error : result.getErrors()) {
                    System.debug('CDdPostSandboxRefresh.changeUserProfiles, retryError: ' + error);
                }
            }
        }
    }

    @Future // to avoid mixed DML error
    public static void insertSeedData() {
        System.debug('CDdPostSandboxRefresh.insertSeedData');

        CDdMilestoneTemplate.insertMilestoneTemplates();

        CDdCSVReader csv;
        List<StaticResource> resources = [
                select Id, Name, Body from StaticResource where Name in (
                        'refreshRealTerritory',
                        'refreshRealZipRealCountryName',
                        'refreshRealZipRealObject',
                        'refreshRealZipRealZipCountry',
                        'refreshRealZipRealZips',
                        'refreshRealZipRZ',
                        'refreshSubmarket'
                )];

        Map<String, String> csvs = new Map<String, String>();
        for (StaticResource resource : resources) {
            csvs.put(resource.Name, resource.Body.toString());
        }

        csv = new CDdCSVReader(csvs.get('refreshSubmarket'), 'Submarket__c');
        insert csv.objects;
        System.debug('CDdPostSandboxRefresh.refreshSubmarket complete');

        Map<Id, Id> submarkets = new Map<Id, Id>();
        for (Integer i = 0; i < csv.objects.size(); i++) {
            submarkets.put(csv.ctx.ids[i], csv.objects[i].Id);
        }

        csv = new CDdCSVReader(csvs.get('refreshRealZipRZ'), 'RealZip__RZ__c');
        //insert reader.objects;

        csv = new CDdCSVReader(csvs.get('refreshRealZipRealZips'), 'RealZip__RealZips__c');
        for (RealZip__RealZips__c realZip : (List<RealZip__RealZips__c>) csv.objects) {
            realZip.Submarket__c = submarkets.get(realZip.Submarket__c);
        }
        insert csv.objects;
        System.debug('CDdPostSandboxRefresh.refreshRealZipRealZips complete');

        csv = new CDdCSVReader(csvs.get('refreshRealZipRealZipCountry'), 'RealZip__RealZip_Country__c');
        insert csv.objects;
        System.debug('CDdPostSandboxRefresh.refreshRealZipRealZipCountry complete');

        Map<Id, Id> countries = new Map<Id, Id>();
        for (Integer i = 0; i < csv.objects.size(); i++) {
            countries.put(csv.ctx.ids[i], csv.objects[i].Id);
        }

        csv = new CDdCSVReader(csvs.get('refreshRealZipRealCountryName'), 'RealZip__RealCountry_Name__c');
        for (RealZip__RealCountry_Name__c name : (List<RealZip__RealCountry_Name__c>) csv.objects) {
            name.RealZip__RealCountry__c = countries.get(name.RealZip__RealCountry__c);
        }
        insert csv.objects;
        System.debug('CDdPostSandboxRefresh.refreshRealZipRealCountryName complete');

        csv = new CDdCSVReader(csvs.get('refreshRealZipRealObject'), 'RealZip__RealObject__c');
        insert csv.objects;
        System.debug('CDdPostSandboxRefresh.refreshRealZipRealObject complete');

        csv = new CDdCSVReader(csvs.get('refreshRealTerritory'), 'RealTerritory__c');
        insert csv.objects;
        System.debug('CDdPostSandboxRefresh.refreshRealTerritory complete');
    }


    public static void deleteSSOEnabledPermissionSetAssignment() {
        List<PermissionSetAssignment> ssoEnabledPermissionSetAssignments = new List<PermissionSetAssignment>();
        // Should return only 1 Permission Set because Name is unique
        List<PermissionSet> ssoEnabledPermissionSet = new List<PermissionSet>();
        ssoEnabledPermissionSet = [Select Id, Name, Label from PermissionSet where name = 'SSO_Enabled'];
        // Get permission Set assignments using the above list;
        if (ssoEnabledPermissionSet.size() == 0) {
            return;
        } else {
            ssoEnabledPermissionSetAssignments = [SELECT Id
                                                    FROM permissionSetAssignment
                                                    WHERE PermissionSetId =: ssoEnabledPermissionSet[0].Id];
            if(ssoEnabledPermissionSetAssignments.size() > 0) {
                System.debug('CDdPostSandboxRefresh.deleteSSOEnabledPermissionSet deleting '
                    + ssoEnabledPermissionSetAssignments.size()
                    + ' assignments for '
                    + ssoEnabledPermissionSet[0].Name
                    + ' Permission set');
                List<Database.DeleteResult> results = Database.delete(ssoEnabledPermissionSetAssignments);
                for (Database.DeleteResult result : results) {
                    for (Database.Error error : result.getErrors()) {
                        System.debug(LoggingLevel.ERROR, 'CDdPostSandboxRefresh.deleteSSOEnabledPermissionSet Error Deleting: ' +error);
                    }
                }
            }
        }


    }
}