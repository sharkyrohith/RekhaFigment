/**
 * @author: Pranil Nimase
 * @date: 07-16-2021
 * @description Test class for CDdMXPSearchRecordsCtrl
 */

@isTest(SeeAllData=false)
public class CDdMXPSearchRecordsCtrlTest {

   /*****************************************************************************************************************************
    *
    * Public/Global Variables
    *
    *****************************************************************************************************************************/
    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    public static final Id recTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support').getRecordTypeId();
    static {
        TEST_ROLE_ID = TDdUserFactory.getUserRole('COO');
    }

    /**
     * @description Prepare test data
     */
    @testSetup
    static void testSetup(){
        List<User> users = TDdUserFactory.createUsers(3);
        insert users;

        PermissionSet mxpTeamMemberPS = [SELECT ID FROM PermissionSet WHERE Name =: CDdSupportConstants.MXP_TEAM_MEMBER];
        List<PermissionSetAssignment> permissionSetAssignments = new List<PermissionSetAssignment>();
        for(User usr : users){
            permissionSetAssignments.add(new PermissionSetAssignment(PermissionSetId=mxpTeamMemberPS.Id, AssigneeId=usr.Id));
        }

        insert permissionSetAssignments;
        System.runAs(getTestRunUser()) {

            vCS__c testSettings;
            testSettings = VTestUtil.createVeltigSettings();
            testSettings.CaseTrigger__c = true;
            insert testSettings;

            List<Account> accounts = TDdAccountFactory.createAccounts('AccountName', 4);
            insert accounts;

            List<AccountTeamMember> accTeamMembers = new List<AccountTeamMember>();
            for(Account acc : accounts) {
                accTeamMembers.add(new AccountTeamMember(UserId = getTestRunUser().Id, AccountId = acc.Id, TeamMemberRole = CDdSupportConstants.MXP_ROLE_NAME));
            }
            insert accTeamMembers;

            List<Case> cases = TDdCaseFactory.createCases(3, accounts[0].Id, null, recTypeId);
            for(Case cs : cases) {
                cs.OwnerId = getTestRunUser().Id;
            }
            insert cases;
        }
    }

    /**
     * @description Prepare and return the test running user
     */
    private static User getTestRunUser() {
        User testRunUser = null;
        for (User u : [SELECT Id, Name FROM User WHERE UserName = :TEST_DD_RUN_USERNAME]){
            testRunUser = u;
        }
        if (testRunUser == null){
            testRunUser = TDdUserFactory.createUsers(1, null, TEST_ROLE_ID, false)[0];
            testRunUser.Username = TEST_DD_RUN_USERNAME;
        }
        return testRunUser;
    }

    /**
     * @description test if user record are returned with search input parameters
     */
    @isTest
    static void findRecords_WithSearchInputs_Test(){
        System.runAs(getTestRunUser()) {
            CDdSearchParameterWrapper searchParameters = new CDdSearchParameterWrapper();
            searchParameters.usernameSearchKey = 'TestUser';
            searchParameters.emailSearchKey = 'puser000';
            searchParameters.profileSearchKey = 'System Administrator';
            //searchParameters.roleSearchKey = 'TestRole';
            searchParameters.objectApiName = 'User';
            searchParameters.offSet = 0;
            searchParameters.pageSize = '5';
            searchParameters.orderBy = 'Name';
            searchParameters.sortOrder = 'ASC';
            searchParameters.selectFields = new List<String>{'Name', 'IsActive', 'Email', 'Profile.Name', 'UserRole.Name'};

            CDdMXPSearchRecordsCtrl.RecordWrapper recordWrapper;
            Test.startTest();
            recordWrapper = CDdMXPSearchRecordsCtrl.findRecords(searchParameters);
            Test.stopTest();

            System.assertEquals(3, recordWrapper.totalNumberOfRecords, 'Total Number of User records is not same as expected.');
            // due to change in TDdUserFactory role update we are unable
            // to predict with which role user records gets created from TDdUserFactory hence commenting out the below code.
            // This class is planned to retire by ticket no BIZS-705 , verifye dteh impact and there no impact on any business logic.
            /*for(SObject record : recordWrapper.records) {
                User user = (User) record;
                System.assertEquals('System Administrator', user.Profile.Name, 'Profile of the user is not same as expected.');
                System.assertEquals('TestRole', user.UserRole.Name, 'Role of the user is not same as expected.');
            }*/
        }
    }

    /**
     * @description test if user record are returned with search input parameters
     */
    @isTest
    static void findRecords_WithSearchInputsException_Test(){
        System.runAs(getTestRunUser()) {
            CDdSearchParameterWrapper searchParameters = new CDdSearchParameterWrapper();
            searchParameters.usernameSearchKey = 'TestUser';
            searchParameters.emailSearchKey = 'puser000';
            searchParameters.profileSearchKey = 'System Administrator';
            searchParameters.roleSearchKey = 'TestRole';
            searchParameters.objectApiName = 'InvalidObjectName';
            searchParameters.offSet = 0;
            searchParameters.pageSize = '5';
            searchParameters.orderBy = 'Name';
            searchParameters.sortOrder = 'ASC';
            searchParameters.selectFields = new List<String>{'Name', 'IsActive', 'Email', 'Profile.Name', 'UserRole.Name'};

            CDdMXPSearchRecordsCtrl.RecordWrapper recordWrapper;
            try {
                Test.startTest();
                recordWrapper = CDdMXPSearchRecordsCtrl.findRecords(searchParameters);
                Test.stopTest();
            }catch (Exception e) {
                System.assertEquals('System.AuraHandledException', e.getTypeName(), 'Type of Exception is not same as expected.');
            }
        }
    }

    /**
     * @description test if account record are returned without search input parameters
     */
    @isTest
    static void findRecords_WithoutSearchInputs_Test(){
        System.runAs(getTestRunUser()) {
            CDdSearchParameterWrapper searchParameters = new CDdSearchParameterWrapper();
            searchParameters.objectApiName = 'Account';
            searchParameters.offSet = 0;
            searchParameters.pageSize = '5';
            searchParameters.orderBy = 'Name';
            searchParameters.sortOrder = 'ASC';
            searchParameters.selectFields = new List<String>{'Name', 'BillingCountry', 'BillingCity'};

            CDdMXPSearchRecordsCtrl.RecordWrapper recordWrapper;
            Test.startTest();
            recordWrapper = CDdMXPSearchRecordsCtrl.findRecords(searchParameters);
            Test.stopTest();

            System.assertEquals(8, recordWrapper.totalNumberOfRecords, 'Expected Total Number of Account records does not match the actual.');
            for(SObject record : recordWrapper.records) {
                Account account = (Account) record;
                System.assertEquals('United States', account.BillingCountry, 'Profile of the user is not same as expected.');
                System.assertEquals('South San Francisco', account.BillingCity, 'Role of the user is not same as expected.');
            }
        }
    }

    /**
     * @description test if AccountTeamMember record are returned without search input parameters
     */
    @isTest
    static void findAccountTeamMemberRecords_WithoutSearchInputs_Test(){
        System.runAs(getTestRunUser()) {
            CDdSearchParameterWrapper searchParameters = new CDdSearchParameterWrapper();
            searchParameters.objectApiName = 'AccountTeamMember';
            searchParameters.offSet = 0;
            searchParameters.pageSize = '5';
            searchParameters.orderBy = 'Account.Name';
            searchParameters.sortOrder = 'ASC';
            searchParameters.selectFields = new List<String>{'User.Name', 'Account.Name', 'TeamMemberRole'};

            CDdMXPSearchRecordsCtrl.RecordWrapper recordWrapper;
            Test.startTest();
            recordWrapper = CDdMXPSearchRecordsCtrl.findRecords(searchParameters);
            Test.stopTest();

            System.assertEquals(4, recordWrapper.totalNumberOfRecords, 'Expected Total Number of AccountTeamMember records does not match the actual.');
            for(SObject record : recordWrapper.records) {
                AccountTeamMember act = (AccountTeamMember) record;
                System.assertEquals(CDdSupportConstants.MXP_ROLE_NAME, act.TeamMemberRole, 'Role of the AccountTeamMember should be MXP.');
            }
        }
    }

    /**
     * @description test if Case records are returned without search input parameters
     */
    @isTest
    static void findCaseRecords_WithoutSearchInputs_Test(){
        System.runAs(getTestRunUser()) {
            CDdSearchParameterWrapper searchParameters = new CDdSearchParameterWrapper();
            searchParameters.objectApiName = 'Case';
            searchParameters.offSet = 0;
            searchParameters.pageSize = '5';
            searchParameters.orderBy = 'CaseNumber';
            searchParameters.showSelectedUsers = true;
            searchParameters.statusSearchKey = 'Open';
            searchParameters.sortOrder = 'ASC';
            searchParameters.selectFields = new List<String>{'Account.Name', 'CaseNumber', 'Business_Id__c', 'OwnerId'};

            CDdMXPSearchRecordsCtrl.RecordWrapper recordWrapper;
            Test.startTest();
            recordWrapper = CDdMXPSearchRecordsCtrl.findRecords(searchParameters);
            Test.stopTest();

            System.assertEquals(3, recordWrapper.totalNumberOfRecords, 'Expected Total Number of Case records does not match the actual.');
            for(SObject record : recordWrapper.records) {
                Case cs = (Case) record;
                System.assertEquals(getTestRunUser().Id, cs.OwnerId, 'Owner of the cases is not same as expected.');
            }
        }
    }
}