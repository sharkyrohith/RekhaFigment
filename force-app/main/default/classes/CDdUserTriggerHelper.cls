/********************************************************************************************************************
* @author Knick
* @date 06/2020
*
* @group Trigger Helper
*
* @description Trigger helper for user object
**************************************************************************************************************************************/
public without sharing class CDdUserTriggerHelper {

    // This provides a map of ProfileId to a Set of desired license IDs for the profile
    public static final Map<Id, Set<Id>> licensesByProfile = CDdCustomMetadata.getProfileLicenseMap();

    // This provides a map of Role Name to a Set of desired license IDs for the role
    public static final Map<String, Set<Id>> licensesByRole = CDdCustomMetadata.getRoleLicenseMap();

    public static final String pslPrefix = PermissionSetLicense.sObjectType.getDescribe().getKeyPrefix();
    public static final String plPrefix = PackageLicense.sObjectType.getDescribe().getKeyPrefix();

    public static final String keyPipe = '|';
    public static final String regExp = '\\|';
    public static String licenseKey(Id userId, Id licenseId) {
        return (String) userId + keyPipe + (String) licenseId;
    }

    private static final Integer PROFILE_HISTORY_TEXT_SIZE = 131072;
    private static final Integer CALLCENTER_HISTORY_TEXT_SIZE = 32768;

    public static final String SPM_TITLE = 'Strategic Partner Manager';
    public static Support_Settings__c SUPPORT_SETTINGS = Support_Settings__c.getInstance() == null ?
                                                            new Support_Settings__c() : Support_Settings__c.getInstance();
    public static Integer CASE_UPDATE_BATCH_SIZE = Integer.valueOf(SUPPORT_SETTINGS.Case_Bulk_Update_Batch_Size__c != null ?
                                                        SUPPORT_SETTINGS.Case_Bulk_Update_Batch_Size__c : 30);

    /**
     * @description  Determines if a field has been updated on the record
     * @param   User u - User in trigger.new
     *          Map<Id, User> oldMap - trigger.oldMap
     *          String fieldName - field to check if it has been updated
     * @return  Boolean
     */
    public static Boolean isFieldUpdated(User u,Map<Id, User> oldMap,String fieldName) {
        return (oldMap != null && u.get(fieldName) != oldMap.get(u.Id).get(fieldName));
    }

    /**
     * @description  Determines if the record is a new record or if a field has been updated on the record
     * @param   User u - User in trigger.new
     *          Map<Id, User> oldMap - trigger.oldMap
     *          String fieldName - field to check if it has been updated
     * @return  Boolean
     */
    public static Boolean isNewOrFieldUpdated(User u,Map<Id, User> oldMap,String fieldName) {
        return trigger.isInsert || isFieldUpdated(u,oldMap,fieldName);
    }

    /**
    *  @description - check Licenses for User Inserts, User Updates, User Upsert Events
    */
    public static void checkLicenses(List<User> users, Boolean fromEvent) {
        Set<Id> usersToCheck = new Set<Id>();
        for (User u : users) usersToCheck.add(u.Id);
        Set<Id> pslIdsToCheck = new Set<Id>();              // Permission Set Licenses
        Set<Id> plIdsToCheck = new Set<Id>();               // Package Licenses
        for (Set<Id> idSet : licensesByProfile.values()) {
            for (Id id : idSet) {
                if (((String)id).startsWith(pslPrefix)) pslIdsToCheck.add(id);
                if (((String)id).startsWith(plPrefix)) plIdsToCheck.add(id);
            }
        }
        for (Set<Id> idSet : licensesByRole.values()) {
            for (Id id : idSet) {
                if(!pslIdsToCheck.contains(id)){
                    if (((String)id).startsWith(pslPrefix)) pslIdsToCheck.add(id);
                }
                if(!plIdsToCheck.contains(id)){
                    if (((String)id).startsWith(plPrefix)) plIdsToCheck.add(id);
                }
            }
        }
        Set<String> existingLicenses = new Set<String>();   // All Licenses
        Map<String, PermissionSetLicenseAssign> pslaMap = new Map<String, PermissionSetLicenseAssign>();
        Map<String, UserPackageLicense> uplMap = new Map<String, UserPackageLicense>();
        if (pslIdsToCheck.size() > 0) {
            List<PermissionSetLicenseAssign> existingPSLAs = [
                SELECT Id, PermissionSetLicenseId, AssigneeId
                FROM PermissionSetLicenseAssign
                WHERE PermissionSetLicenseId IN :pslIdsToCheck
                AND AssigneeId IN :usersToCheck
            ];
            for (PermissionSetLicenseAssign psla : existingPSLAs) {
                String key = licenseKey(psla.AssigneeId, psla.PermissionSetLicenseId);
                existingLicenses.add(key);
                pslaMap.put(key, psla);
            }
        }
        if (plIdsToCheck.size() > 0) {
            List<UserPackageLicense> existingUPLs = [
                SELECT Id, PackageLicenseId, UserId
                FROM UserPackageLicense
                WHERE PackageLicenseId IN :plIdsToCheck
                AND UserId IN :usersToCheck
            ];
            for (UserPackageLicense upl : existingUPLs) {
                String key = licenseKey(upl.UserId, upl.PackageLicenseId);
                existingLicenses.add(key);
                uplMap.put(key, upl);
            }
        }
        // For each user, determine what licenses need to be added / deleted
        Set<String> licensesToAdd = new Set<String>();

        for (User u :  users){
            Set<String> userRequiredLicenses = new Set<String>();
            if (licensesByProfile.containsKey(u.ProfileId)) {
                for (Id licenseId : licensesByProfile.get(u.ProfileId)) {
                    if (u.IsActive) userRequiredLicenses.add(licenseKey(u.Id, licenseId));
                }
            }
            if(licensesByRole.containsKey(u.User_Role__c)){
                for (Id licenseId : licensesByRole.get(u.User_Role__c)) {
                    if (u.IsActive) userRequiredLicenses.add(licenseKey(u.Id, licenseId));
                }
            }

            for (String key : userRequiredLicenses) {
                if (!existingLicenses.contains(key)) licensesToAdd.add(key);
            }
        }
        // Make the required adds (these are done by the event handler)
        if (licensesToAdd.size() > 0) {
            List<PermissionSetLicenseAssign> newPSLAs = new List<PermissionSetLicenseAssign>();
            List<UserPackageLicense> newUPLs = new List<UserPackageLicense>();
            Map<Id, User_Upsert_Event__e> eventMap = new Map<Id, User_Upsert_Event__e>();
            for (String license : licensesToAdd) {
                List<String> keyTokens = license.split(regExp);
                if (fromEvent) {
                    if (keyTokens[1].startsWith(pslPrefix))
                        newPSLAs.add(new PermissionSetLicenseAssign(
                            AssigneeId = keyTokens[0], PermissionSetLicenseId = keyTokens[1]
                        ));
                    if (keyTokens[1].startsWith(plPrefix))
                        newUPLs.add(new UserPackageLicense(
                            UserId = keyTokens[0], PackageLicenseId = keyTokens[1]
                        ));
                }
                else {
                    eventMap.put(keyTokens[0], new User_Upsert_Event__e(User_Id__c = keyTokens[0]));
                }
                existingLicenses.add(license);
            }
            if (newPSLAs.size() > 0) insert newPSLAs;
            if (newUPLs.size() > 0) insert newUPLs;
            if (eventMap.size() > 0) EventBus.publish(eventMap.values());
        }
    }

    /**
    *  @description - handler for User Upsert Events
    */
    public static void handleUserUpsertEvents(List<User_Upsert_Event__e> userUpsertEvents) {
       Set<Id> UserIds = new Set<Id>();
        for (User_Upsert_Event__e event : userUpsertEvents) {
            UserIds.add(event.User_Id__c);
        }
        List<User> Users = [SELECT Id, IsActive, ProfileId, User_Role__c FROM User WHERE Id IN :UserIds];
        checkLicenses(Users, true);
    }

    /**
     * @Author - Raju
     * @Date - Nov 8 2021
     * @description - BASD-13870 - Logging Profile changes which can help with debugging what was the user profile at any point of time
    */
    public static void logProfileChange(List<User> newList, Map<Id,User> oldMap) {
        String dt = System.now().format();
        String currentUserId = UserInfo.getUserId();
        for (User u : newList) {
            User oldUser = oldMap.get(u.Id);
            if (isFieldUpdated(u,oldMap,'ProfileId')) {
                String log = (oldUser.ProfileId + CDdCoreConstants.DELIMITER_UNDERSCORE + currentUserId + CDdCoreConstants.DELIMITER_UNDERSCORE + dt +
                    (String.isBlank(u.Profile_Change_History__c) ? CDdCoreConstants.BLANK_STRING :
                        CDdCoreConstants.DELIMITER_SEMICOLON + CDdCoreConstants.DELIMITER_SPACE + u.Profile_Change_History__c)
                    ).left(PROFILE_HISTORY_TEXT_SIZE);
                u.Profile_Change_History__c = log;
            }
        }
    }
    /**
     * @Author - Raja
     * @Date - Jun 28 2022
     * @description - BASD-3623 - Call Batch to reassign open cases to previous queue when agent is deactivated
    */
    public static void deActivateUsersCaseReassign(List<User> newList, Map<Id,User> oldMap)
    {
        list<Id> deActivateAccounts = new list<Id>();
        for (User u : newList)
        {
            User oldUser = oldMap.get(u.Id);
            if(u.ProfileId != null &&
                Agent_Setting__c.getInstance(u.ProfileId).Is_Agent__c &&
                !u.isActive &&
                isFieldUpdated(u,oldMap,'isActive')){
                deActivateAccounts.add(u.Id);
            }
        }
        if(!deActivateAccounts.isEmpty() && deActivateAccounts != null)
        {
            database.executeBatch(new CDdDeactivateUserCaseAssign(deActivateAccounts),CASE_UPDATE_BATCH_SIZE);
        }
    }
    /**
     * @Author - Raju
     * @Date - Apr 2022
     * @description - BASD-13499 - Update Call Center based on Profile and Role
    */
    public static void updateCallCenter(List<User> newList, Map<Id,User> oldMap) {
        List<User> toProcess = new List<User>();
        for (User usr : newList) {
            if (isNewOrFieldUpdated(usr,oldMap,'ProfileId') || isNewOrFieldUpdated(usr,oldMap,'UserRoleId')) {
                if (usr.UserRoleId != null) {
                    toProcess.add(usr);
                } else {
                    usr.CallCenterId = null;
                }
            }
        }
        if (toProcess.isEmpty()) {
            return;
        }
        Map<Id,Map<Id,Id>> userProfileToRoleToCallCenterMap = new Map<Id,Map<Id,Id>>();
        for (Call_Center_Assignment__mdt cca : Call_Center_Assignment__mdt.getAll().values()) {
            Id profileId = CDdUtilities.returnValidId(cca.Profile_Id__c);
            Id userRoleId = CDdUtilities.returnValidId(cca.UserRole_Id__c);
            Id callCenterId = CDdUtilities.returnValidId(cca.Call_Center_Id__c);
            if (profileId == null || userRoleId == null || callCenterId == null) {
                continue;
            }
            if (!userProfileToRoleToCallCenterMap.containsKey(profileId)) {
                userProfileToRoleToCallCenterMap.put(profileId,new Map<Id,Id>());
            }
            userProfileToRoleToCallCenterMap.get(profileId).put(userRoleId,callCenterId);
        }
        for (User usr : toProcess) {
            if (userProfileToRoleToCallCenterMap.containsKey(usr.ProfileId) &&
                userProfileToRoleToCallCenterMap.get(usr.ProfileId).containsKey(usr.UserRoleId)
            ) {
                usr.CallCenterId =  userProfileToRoleToCallCenterMap.get(usr.ProfileId).get(usr.UserRoleId);
            } else {
                usr.CallCenterId = null;
            }
        }
    }

    /**
     * @Author - Raju
     * @Date - Apr 2022
     * @description - BASD-13499 - Update Call Center based on Profile and Role
    */
    public static void logCallCenterChange(List<User> newList, Map<Id,User> oldMap) {
        String dt = System.now().format();
        String currentUserId = UserInfo.getUserId();
        for (User u : newList) {
            User oldUser = oldMap.get(u.Id);
            if (isFieldUpdated(u,oldMap,'CallCenterId')) {
                String log = (oldUser.CallCenterId + CDdCoreConstants.DELIMITER_UNDERSCORE + currentUserId + CDdCoreConstants.DELIMITER_UNDERSCORE + dt +
                    (String.isBlank(u.Call_Center_Change_Log__c) ? CDdCoreConstants.BLANK_STRING :
                        CDdCoreConstants.DELIMITER_SEMICOLON + CDdCoreConstants.DELIMITER_SPACE + u.Call_Center_Change_Log__c)
                    ).left(CALLCENTER_HISTORY_TEXT_SIZE);
                u.Call_Center_Change_Log__c = log;
            }
        }
    }

    /**
     * @Author - Raju
     * @Date - Apr 2022
     * @description - BASD-13499 - Above Code moved 90% of 'Incorporate all changes - User Object' PB, just this thing was left... so moving this as well to trigger.
    */
    public static void updateAccountOwnerRole(List<User> newList, Map<Id,User> oldMap) {
        for (User u : newList) {
            if (isNewOrFieldUpdated(u,oldMap,'Title') && SPM_TITLE.equalsIgnoreCase(u.Title)) {
                u.Account_Manager_Role__c = SPM_TITLE;
            }
        }
    }

    /**
     * @author      Sahil
     * @date        October 2022
     * @jira        https://doordash.atlassian.net/browse/BIZS-2057
     * @description revert back to lightning profile and callcenter if switched to a classic profile.
     *              this is an optional feature to handle unintented changes made by integration users.
    */
    public static void revertToLightningProfile(List<User> newList, Map<Id,User> oldMap) {
        try {
            if (!CDdExperimentSvc.getSupportFeatureFlag('Revert_to_Lightning_Profile__c')){
                return;
            }
            Set<Id> profilesToCheckSet = new Set<Id>();
            List<String> profileIdList = CDdNameValuePairHelper.getTextValue(CDdNameValuePairConstants.LIGHTNING_SUP_PROFILEIDS).split(CDdCoreConstants.DELIMITER_COMMA);
            //loop through profile Ids to add to the set
            for (String profileIdVar : profileIdList) {
                profilesToCheckSet.add(CDdUtilities.returnValidId(profileIdVar));
            }
            //check users whose profiles changed from lightning to classic
            //revert their profile and call center Id
            for (User usr : newList) {
                User oldUser = oldMap.get(usr.Id);
                if (isFieldUpdated(usr,oldMap,'ProfileId')
                    && profilesToCheckSet.contains(oldUser.ProfileId)
                    && !profilesToCheckSet.contains(usr.ProfileId)) {
                    usr.ProfileId = oldUser.ProfileId;
                    usr.CallCenterId = oldUser.CallCenterId;
                }
            }
        } catch (Exception e) {
            CDdErrorUtilities.publishException('CDdUserTriggerHelper','revertToLightningProfile', e);
        }
    }

     /**
     * @author      Krishna Sanisetty
     * @date        Feb 2023
     * @jira        https://doordash.atlassian.net/browse/BZAP-19322
     * @description When a user is deactivated, remove all the userpackagelicenses assigned to the user.  This can be an immediate action.
    */
    public static void removeUserPackageLicenseOnUserDeActivation(List<User> newList, Map<Id,User> oldMap){
        try{
            Set<Id> decativatedUserIds = new Set<Id>(); 
            for(User newUser: newList){
                if(isUserDeactivated(newUser, oldMap.get(newUser.Id))){
                    decativatedUserIds.add(newUser.Id);
                }
            }
            List<UserPackageLicense> userPackages = [SELECT Id FROM UserPackageLicense WHERE UserId IN: decativatedUserIds AND PackageLicenseId <> null];
            delete userPackages;
        } catch (Exception e) {
            CDdErrorUtilities.publishException('CDdUserTriggerHelper','removeUserPackageLicenseOnUserDeActivation', e);
        }
    }
    
    private static boolean isUserDeactivated(User newUser, User oldUser){
        return !newUser.isActive && newUser.isActive <> oldUser.isActive;
    }
}