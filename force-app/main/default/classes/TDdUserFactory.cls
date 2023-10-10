/*******************************************************************************************
 * @Name         TDdUserFactory
 * @Author       Sahil
 * @Date         2021-03-26
 * @Group        Bizapps Support
 * @Description  Test class for case notes/feed controller
 *******************************************************************************************/
/* MODIFICATION LOG
 * Version          Developer          Date               Description
 *-------------------------------------------------------------------------------------------
 *  1.0              Sahil              2021-03-26          Initial creation
 *******************************************************************************************/
public with sharing class TDdUserFactory {
  /**
   * @author      Sahil
   * @date        March 2021
   * @jira        https://doordash.atlassian.net/browse/BZAPSUP-1095
   * @description creates test users
   */
    public static List<User> createUsers(Integer numberOfUsers) {
      List<User> usersToBeCreated = createUsers(numberOfUsers, null, null,false);
      return usersToBeCreated;
    }

  /**
   * @author      Sahil
   * @date        March 2021
   * @jira        https://doordash.atlassian.net/browse/BZAPSUP-1095
   * @description Method to create multiple users with a given profile ID and a role Id
                  If the userProfileId is null, it will use Sys Admin profile.
                  BIZS-805 - Raju Lakshman - If roleId is null, it will find any existing user role in the org to link to user
                           - Inserting new dummy user roles was erroring out with UNABLE_TO_LOCK_ROW ¯\_(ツ)_/¯
    */
    public static List<User> createUsers(Integer numberOfUsers, Id userProfileId, Id roleId, Boolean doDML) {
      List<User> usersToBeCreated = new List<User>();
      if (userProfileId == null) {
        userProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
      }

      if (roleId == null) {
        List<UserRole> userRoles = [SELECT Id,DeveloperName,LastModifiedDate, Name FROM UserRole ORDER BY LastModifiedDate asc LIMIT 1];
        if (userRoles.isEmpty()) {
          throw new CDdException('Unable to find User Role to assign to test user');
        }
        roleId = userRoles[0].id;
      }

      for (Integer i = 0; i < numberOfUsers; i++) {
        User u = new User(
          ProfileId = userProfileId,
          LastName = 'TestUser' + i,
          Email = 'puser000' + i + '@doordash.com',
          Username = 'puser000' + i + '@doordash.com' + System.currentTimeMillis(),
          CompanyName = 'TEST',
          Title = 'TestTitle',
          Alias = 'alias' + i,
          TimeZoneSidKey = 'America/Los_Angeles',
          EmailEncodingKey = 'UTF-8',
          LanguageLocaleKey = 'en_US',
          LocaleSidKey = 'en_US',
          UserRoleId = roleId
        );
        usersToBeCreated.add(u);
      }
      if (doDML && usersToBeCreated.size()>0) {
        insert usersToBeCreated;
      }
      return usersToBeCreated;
    }

    /**
   * @author      Sahil
   * @date        March 2021
   * @jira        https://doordash.atlassian.net/browse/BZAPSUP-1095
   * @description Method to create multiple users with a given profile ID without role
                  If the userProfileId is null, it will use Sys Admin profile.
    */
    public static List<User> createUsersWithoutRole(Integer numberOfUsers, Id userProfileId, Boolean doDML) {
      List<User> usersToBeCreated = new List<User>();
      if (userProfileId == null) {
        userProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
      }

      for (Integer i = 0; i < numberOfUsers; i++) {
        User u = new User(
          ProfileId = userProfileId,
          LastName = 'TestUser' + i,
          Email = 'puser000' + i + '@doordash.com',
          Username = 'puser000' + i + '@doordash.com' + System.currentTimeMillis(),
          CompanyName = 'TEST',
          Title = 'TestTitle',
          Alias = 'alias' + i,
          TimeZoneSidKey = 'America/Los_Angeles',
          EmailEncodingKey = 'UTF-8',
          LanguageLocaleKey = 'en_US',
          LocaleSidKey = 'en_US'
        );
        usersToBeCreated.add(u);
      }
      if (doDML && usersToBeCreated.size()>0) {
        insert usersToBeCreated;
      }
      return usersToBeCreated;
    }

    public static Id getUserRole(String developerName) {
      return [SELECT Id
        FROM UserRole
        WHERE DeveloperName = :developerName].Id;
    }

    /**
     * @params      userList List of users
     *              permissionSetId Permission Set Id to assign to the list of users
     *              doInsert boolean value to do insert or not. 
     * @author      Jeegar
     * @date        October 2022
     * @description Create permission set assignment for users
     */
    public static List<PermissionSetAssignment> createPermSetAssignment(List<User> userList, Id permissionSetId, Boolean doInsert) {
      List <PermissionSetAssignment> permAssignments = new List<PermissionSetAssignment>();
      PermissionSetAssignment psAss;
      for(User userInfo : userList) {
        psAss = new PermissionSetAssignment(); 
        psAss.AssigneeId = userInfo.id;
        psAss.PermissionSetId = permissionSetId;

        permAssignments.add(psAss);
      }
      if(doInsert) {
        database.insert(permAssignments);
      }
      return permAssignments; 
    }
}