/**
* CDdAdminAccessRequestTriggerHelperTest
*
* @author      Nathalie Mendezona
* @date        February 2023
* @decription  BZAP-18836 - Test Class for CDdAdminAccessRequestTriggerHelper
 */
@isTest(seeAllData=false)
public with sharing class CDdAdminAccessRequestTriggerHelperTest {
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    public static final Id TEST_ROLE_ID;
    public static final Id SYSTEM_ADMIN_PROFILE_ID;
    static {
        TEST_ROLE_ID = [SELECT Id FROM UserRole WHERE DeveloperName = 'COO'].Id;
        SYSTEM_ADMIN_PROFILE_ID = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
    }

    /**
     * @author      Nathalie Mendezona
     * @description BZAP-18836 - Initial data setup
     */
    @TestSetup
    static void createData(){
        System.runAs(getTestRunUser()){
            Admin_Access_Request__c req = new Admin_Access_Request__c(Reason_for_Access__c = 'Hotfix / Incident', Duration_of_Access__c = '1',
                                                                  Jira_Ticket_Number__c  = 'BZAP-2000', Status__c = CDdAdminAccessRequestTriggerHelper.STATUS_ACTIVE);
            insert req;
        }
    }

    /**
     * @author      Nathalie Mendezona
     * @description BZAP-18836 - Ensure there can't be 2 active Admin_Access_Request__c for a given user
     *              Tests CDdAdminAccessRequestTriggerHelper.preventDuplicateRequests()
     */
    @isTest
    static void createDuplicateAdminAccessRequest() {
        System.runAs(getTestRunUser()){
            Database.SaveResult insertResult;

            // The fields purposely don't match the ones in the initial record to ensure the duplicate criteria is OwnerId only
            Admin_Access_Request__c duplicateReq = new Admin_Access_Request__c(Reason_for_Access__c = 'Troubleshooting (no metadata change)', Duration_of_Access__c = '4',
                                                                               Jira_Ticket_Number__c  = 'BZAP-2001', Status__c = CDdAdminAccessRequestTriggerHelper.STATUS_ACTIVE);
            Test.startTest();
            try {
                insertResult = Database.insert(duplicateReq, false);
            } catch (Exception e) { }
            Test.stopTest();

            List<Admin_Access_Request__c> requests = [SELECT Id FROM Admin_Access_Request__c];
            System.assertEquals(false, insertResult.isSuccess(), 'Expecting the record insert to fail, see CDdAdminAccessRequestTriggerHelper.preventDuplicateRequests()');
            System.assertEquals(Label.AdminAccessRequest_Duplicate_Error, insertResult.getErrors().get(0).getMessage());
            System.assertEquals(1, requests.size(), 'There should only be one Admin_Access_Request__c created, the one during test setup');
        }
    }

    /**
    * @description Prepare and return the test running user
    */
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
}