/**
 * @author: Pranil
 * @ticketNo BIZS - 167
 * @date: 07-19-2021
 * @description This Class contains test data for CDdMXPManagerController class.
 */
@isTest(SeeAllData=false)
public class CDdMXPManagerControllerTest {
    
   /*****************************************************************************************************************************
    *
    * Constants & Private Variables
    *
    *****************************************************************************************************************************/
    private static final Map<String, Schema.RecordTypeInfo> ACCOUNT_RECTYPE_MAP = Account.SobjectType.getDescribe().getRecordTypeInfosByName();

   /*****************************************************************************************************************************
    *
    * Public/Global Variables
    *
    *****************************************************************************************************************************/
    public static final Id ACCOUNT_RECORDTYPE_ID = ACCOUNT_RECTYPE_MAP.get(CDdSupportConstants.RECORDTYPE_NAME_MARKETPLACE).getRecordTypeId();
    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    public static final String TEST_DD_NON_SYSADMIN_USERNAME = 'test.nonsysadminuser@doordash.com';
    static {
        TEST_ROLE_ID = TDdUserFactory.getUserRole('COO');    
    }
    
    /** 
     * @description Prepare and return the test running user with System Admin Profile
     */
    private static User getTestRunUser() {
        User testRunUser = null;
        for(User u : [ SELECT Id FROM User WHERE UserName = :TEST_DD_RUN_USERNAME]){
            testRunUser = u;
        }
        if(testRunUser == null){
            testRunUser = TDdUserFactory.createUsers(1, null, TEST_ROLE_ID, false)[0]; 
            testRunUser.Username = TEST_DD_RUN_USERNAME;
        }
        return testRunUser;
    }
    
    /** 
     * @description Prepare and return the test running user with Non System Admin Profile
     */    
    private static User getTestRunUserNonSysAdmin() {
        User testRunUser = null;
        Profile userProfile = [SELECT ID FROM Profile WHERE Name = 'Account Manager'];
        for(User u : [ SELECT Id FROM User WHERE UserName = :TEST_DD_NON_SYSADMIN_USERNAME]){
            testRunUser = u;
        }
        if(testRunUser == null){
            testRunUser = TDdUserFactory.createUsers(1, userProfile.Id, TEST_ROLE_ID, false)[0]; 
            testRunUser.Username = TEST_DD_NON_SYSADMIN_USERNAME;
            insert testRunUser;
        }
        PermissionSet mxpTeamManagerPS = [SELECT ID FROM PermissionSet WHERE Name = :CDdSupportConstants.MXP_TEAM_MANAGER];
        PermissionSetAssignment mxpTeamManagerPSAssigment = new PermissionSetAssignment(AssigneeId = testRunUser.Id, PermissionSetId = mxpTeamManagerPS.Id);
        insert mxpTeamManagerPSAssigment;
        return testRunUser;
    }
    
    /** 
     * @description Prepare test data
     */ 
    @testSetup
    static void testSetUpData(){
        List<User> testUsers = TDdUserFactory.createUsers(1);
        insert testUsers;
        system.runAs(getTestRunUser()){        
            List<Account> accList = CDdTestDataFactory.createSObjectList('Account', 1, false);            
            for(Integer index = 0; index < accList.size(); index++){                
                if(index == 0){
                    accList[index].Name = 'Test Acc';
                    accList[index].phone = '0256157848';
                    accList[index].BillingCountryCode = 'US';
                    accList[index].Case_Routing_Override__c = 'Mx Success Associate Queue';
                    accList[index].Market_Area__c = 'Northern California - East Bay';
                    accList[index].Business_ID__c = 123456;
                    accList[index].Formstack_Version__c = 'New Store';
                    accList[index].RecordTypeId = ACCOUNT_RECORDTYPE_ID;
                }       
            }        
            insert accList;
            
            AccountTeamMember accTeamMember= new AccountTeamMember();        
            accTeamMember.AccountId = accList[0].Id;
            accTeamMember.UserId = testUsers[0].Id;
            accTeamMember.TeamMemberRole = 'MXP';                           
            insert accTeamMember;
        }
    }

    /** 
     * @description Test method for updateUsersOOO method
     */
    @isTest
    static void testUpdateUsersOOO(){
        Map<String, Object> savedUsersMap;
        Date outOfOfficeDate = Date.today();
        System.runAs(getTestRunUserNonSysAdmin()){
            User testUser = [SELECT Id FROM User WHERE LastName ='TestUser0' LIMIT 1];
            testUser.Is_Out_Of_Office__c = true;
            testUser.Out_Of_Office_End_Date__c = outOfOfficeDate;
            String userString = JSON.serialize(new List<User>{testUser});
            
            Test.startTest();
            savedUsersMap = CDdMXPManagerController.updateUsersOOO(userString);
            Test.stopTest();
        }
        
        List<User> actualUsers = (List<User>) savedUsersMap.get('users');
        System.assertEquals(true, actualUsers[0].Is_Out_Of_Office__c, 'Out of Office Status for User is not updated as expected.');
        System.assertEquals(outOfOfficeDate, actualUsers[0].Out_Of_Office_End_Date__c, 'Out of Office Date for User is not updated as expected.');
    }
    
    /** 
     * @description Test method for updateUsersOOO method with Exception
     */
    @isTest
    static void testUpdateUsersOOOException(){
        Date outOfOfficeDate = Date.today();
        Boolean exceptionOccured;
        String exceptionType;
        System.runAs(getTestRunUserNonSysAdmin()){
            User testUser = [SELECT Id FROM User WHERE LastName ='TestUser0' LIMIT 1];
            testUser.Is_Out_Of_Office__c = true;
            testUser.Out_Of_Office_End_Date__c = outOfOfficeDate;
            String userString  = null;
            Map<String, Object> savedUsersMap;
            try{
                Test.startTest();            
                savedUsersMap = CDdMXPManagerController.updateUsersOOO(userString);              
                Test.stopTest();
            }catch(Exception e){
                exceptionOccured = true;
                exceptionType = e.getTypeName();
            }
        }
        
        System.assertEquals(true, exceptionOccured, 'Exception was not thrown as expected.');
        System.assertEquals('System.AuraHandledException', exceptionType, 'Exception Type is not same as expected.');
    }
    
    /** 
     * @description Test method for upsertOrRemoveAccountTeams method for Adding account team members
     */
    @isTest
    static void testUpsertOrRemoveAccountTeamsAdd(){                 
        System.runAs(getTestRunUserNonSysAdmin()){
            AccountTeamMember accTeamMember = [ SELECT Id, 
                                               AccountId, 
                                               UserId,
                                               TeamMemberRole
                                               FROM AccountTeamMember
                                               WHERE Account.Name = 'Test Acc'];
            String accountTeamString = JSON.serialize(new List<AccountTeamMember>{accTeamMember});
            Test.startTest();
            Map<String, Object> accTeamMap = CDdMXPManagerController.upsertOrRemoveAccountTeams(accountTeamString, 'Add');
            Test.stopTest();
            
            List<AccountTeamMember> actualTeamMember = (List<AccountTeamMember>) accTeamMap.get('atmStr');
            System.assertEquals(accTeamMember.AccountId, actualTeamMember[0].AccountId, 'Account of AccountTeamMember is not same as expected.');
            System.assertEquals(accTeamMember.UserId, actualTeamMember[0].UserId, 'User of AccountTeamMember is not same as expected.');
        }
    }
    
                /** 
* @description Test method for upsertOrRemoveAccountTeams method with Exception
*/
    @isTest
    static void testUpsertOrRemoveAccountTeamsAddException(){
        Boolean exceptionOccured;
        String exceptionType;
        System.runAs(getTestRunUserNonSysAdmin()){
            AccountTeamMember accTeamMember = [SELECT Id, 
                                               AccountId, 
                                               UserId,
                                               TeamMemberRole
                                               FROM AccountTeamMember
                                               WHERE Account.Name = 'Test Acc'];
            String accountTeamString = JSON.serialize(accTeamMember);
            try{
                Test.startTest();
                Map<String, Object> accTeamMap = CDdMXPManagerController.upsertOrRemoveAccountTeams(accountTeamString, 'Add');
                Test.stopTest();
            }catch(Exception e){
                exceptionOccured = true;
                exceptionType = e.getTypeName();
            }
        }

        System.assertEquals(true, exceptionOccured, 'Exception was not thrown as expected.');
        System.assertEquals('System.AuraHandledException', exceptionType, 'Exception Type is not same as expected.');
    }
    
    /** 
     * @description Test method for upsertOrRemoveAccountTeams method for Adding & Removing account team members
     */
    @isTest
    static void testUpsertOrRemoveAccountTeamsMix(){        
        System.runAs(getTestRunUserNonSysAdmin()){
            AccountTeamMember accTeamMember = [SELECT Id, 
                                               AccountId, 
                                               UserId,
                                               TeamMemberRole
                                               FROM AccountTeamMember 
                                               WHERE Account.Name = 'Test Acc'];
            CDdMXPManagerController.AccountTeamMemberWrapper wrapAccTeam = new CDdMXPManagerController.AccountTeamMemberWrapper();
            wrapAccTeam.accountId = accTeamMember.AccountId;
            wrapAccTeam.userId = accTeamMember.UserId;
            wrapAccTeam.change = 'Add';
            wrapAccTeam.teamMemberRole = accTeamMember.TeamMemberRole;
            String accountTeamWrapString = JSON.serialize(new List<CDdMXPManagerController.AccountTeamMemberWrapper>{wrapAccTeam}); 
            Test.startTest();
            Map<String, Object> accTeamMap = CDdMXPManagerController.upsertOrRemoveAccountTeams(accountTeamWrapString, 'mix');
            Test.stopTest();
            
            List<AccountTeamMember> actualTeamMember = (List<AccountTeamMember>) accTeamMap.get('response1');
            System.assertEquals(accTeamMember.AccountId, actualTeamMember[0].AccountId, 'Account of AccountTeamMember is not same as expected.');
            System.assertEquals(accTeamMember.UserId, actualTeamMember[0].UserId, 'User of AccountTeamMember is not same as expected.');
        }
    }
    
    /** 
     * @description Test method for upsertOrRemoveAccountTeams method for Adding & Removing account team members
     */
    @isTest
    static void testUpsertOrRemoveAccountTeamsMixTwo(){        
        System.runAs(getTestRunUserNonSysAdmin()){
            AccountTeamMember accTeamMember = [SELECT Id, 
                                               AccountId, 
                                               UserId,
                                               TeamMemberRole
                                               FROM AccountTeamMember 
                                               WHERE Account.Name = 'Test Acc'];            
            CDdMXPManagerController.AccountTeamMemberWrapper wrapAccTeam = new CDdMXPManagerController.AccountTeamMemberWrapper();
            wrapAccTeam.accountId = accTeamMember.AccountId;
            wrapAccTeam.userId = accTeamMember.UserId;
            wrapAccTeam.change = 'Remove';
            wrapAccTeam.teamMemberRole = accTeamMember.TeamMemberRole;
            String accountTeamWrapString = JSON.serialize(new List<CDdMXPManagerController.AccountTeamMemberWrapper>{wrapAccTeam}); 
            Test.startTest();
            Map<String, Object> accTeamMap = CDdMXPManagerController.upsertOrRemoveAccountTeams(accountTeamWrapString, 'mix');
            Test.stopTest();
            
            List<AccountTeamMember> actualTeamMember = (List<AccountTeamMember>) accTeamMap.get('response2');
            System.assertEquals(accTeamMember.AccountId, actualTeamMember[0].AccountId, 'AccountTeamMember is not same as expected.');
        }
    }
    
    /** 
     * @description Test method for upsertOrRemoveAccountTeams method for Removing account team members
     */
    @isTest
    static void testremoveAccountTeams(){
        System.runAs(getTestRunUserNonSysAdmin()){
            AccountTeamMember accTeamMember = [SELECT Id, 
                                               AccountId, 
                                               UserId,
                                               TeamMemberRole
                                               FROM AccountTeamMember 
                                               WHERE Account.Name = 'Test Acc'];
            Test.startTest();
            Map<String, Object> deleteAccountTeamMap = CDdMXPManagerController.removeAccountTeams(new List<Id>{accTeamMember.Id});
            Test.stopTest();
            
            System.assert(deleteAccountTeamMap.keySet().contains('deletedATM'), 'Response does not contain deletedATM key.');
            System.assertEquals(1, deleteAccountTeamMap.size(), 'The size of deleteAccountTeamMap is not same as expected.');
        } 
    }
    
    /** 
     * @description Test method for testGetUserPerm method for Admin User
     */
    @isTest
    public static void testGetUserPerm(){
        System.runAs(getTestRunUser()){
            Test.startTest();
            boolean result = CDdMXPManagerController.getUserPerm();
            Test.stopTest();
            
            System.assertEquals(true, result, 'User permission is not same as expected.');
        }
    }
    
    /** 
     * @description Test method for testGetUserPerm method for Non Admin User
     */
    @isTest
    public static void testGetUserPermNonSysAdmin(){
        System.runAs(getTestRunUserNonSysAdmin()){
            Test.startTest();
            boolean result = CDdMXPManagerController.getUserPerm();
            Test.stopTest();
            
            System.assertEquals(true, result, 'User permission is not same as expected.');
        }
    }
    
    /** 
     * @description Test method for getExistingAcccountTeams method
     */
    @isTest
    public static void testGetExistingAcccountTeams(){
        System.runAs(getTestRunUserNonSysAdmin()){
            Account accList = [SELECT Id, 
                               Name,
                               Case_Routing_Override__c 
                               FROM Account 
                               WHERE Name = 'Test Acc' LIMIT 1];
            User testUsers = [SELECT Id FROM User WHERE LastName ='TestUser0' LIMIT 1];
            Test.startTest();
            Map<String,AccountTeamMember> atmMap = CDdMXPManagerController.getExistingAcccountTeams(new List<String>{testUsers.Id} , new List<String>{accList.Id});
            Test.stopTest();
            
            System.assertEquals(accList.Id, atmMap.get(testUsers.Id + CDdCoreConstants.BLANK_STRING + accList.Id).AccountId, 'AccountId of AccountTeamMember is not same as expected.');
        }
    }
    
    /** 
     * @description Test method for updateAccountsCRO method
     */
    @isTest
    public static void testUpdateAccountsCRO(){
        System.runAs(getTestRunUserNonSysAdmin()){
            Account accList = [SELECT Id, 
                               Name,
                               Case_Routing_Override__c 
                               FROM Account 
                               WHERE Name = 'Test Acc' LIMIT 1];
            String accRecString = JSON.serialize(new List<Account>{accList});
            Test.startTest();
            Map<String,Object> accountDataMap = CDdMXPManagerController.updateAccountsCRO(accRecString);
            Test.stopTest();
            
            System.assert(accountDataMap.keySet().contains('accounts'), 'Response does not contain accounts key.');
            System.assertEquals('Mx Success Associate Queue', accList.Case_Routing_Override__c, 'Case Routing Override is not same as expected.');
        }
    }
    
    /** 
     * @description Test method for updateAccountsCRO method with Exception
     */
    @isTest
    public static void testUpdateAccountsCROException(){
        Boolean exceptionOccured;
        String exceptionType;
        System.runAs(getTestRunUserNonSysAdmin()){
            try{
                Account accList = [SELECT Id, 
                                   Name,
                                   Case_Routing_Override__c 
                                   FROM Account 
                                   WHERE Name = 'Test Acc' LIMIT 1];
                accList.Case_Routing_Override__c = 'Expecting exception';
                String accRecString = JSON.serialize(new List<Account>{accList});
                Test.startTest();
                Map<String,Object> accountDataMap = CDdMXPManagerController.updateAccountsCRO(accRecString);
                System.assertEquals('Expecting exception', accList.Case_Routing_Override__c, 'Expecting Bad picklist value exception');
                Test.stopTest();
            } catch(Exception e){
                exceptionOccured = true;
                exceptionType = e.getTypeName();
            }
            
            System.assertEquals(true, exceptionOccured, 'Exception was not thrown as expected.');
            System.assertEquals('System.AuraHandledException', exceptionType, 'Exception Type is not same as expected.');            
        }
    }
    
    /** 
     * @description Test method for getExistingAccountRecords method
     */
    @isTest
    public static void testgetExistingAccountRecords(){
        System.runAs(getTestRunUserNonSysAdmin()){
            Account accList = [SELECT Id, 
                               Name,
                               Case_Routing_Override__c 
                               FROM Account 
                               WHERE Name = 'Test Acc' LIMIT 1];
            Test.startTest();
            Map<String,Object> accountDataMap = CDdMXPManagerController.getExistingAccountRecords(new List<String>{accList.Id});
            Test.stopTest();
        }
    }
    
    /** 
     * @description Test method for updateMxAccountRecords method
     */
    @isTest
    public static void testupdateMxAccountRecords(){
        System.runAs(getTestRunUserNonSysAdmin()){
            Account accList = [SELECT Id, 
                               Name,
                               Case_Routing_Override__c 
                               FROM Account 
                               WHERE Name = 'Test Acc' LIMIT 1];
            
            CDdMXPManagerController.AccountWrapper accWrap= new CDdMXPManagerController.AccountWrapper();
            accWrap.AccountId = accList.Id;
            accWrap.caserouting = accList.Case_Routing_Override__c;
            String accountsDataString = JSON.serialize(new List<CDdMXPManagerController.AccountWrapper>{accWrap});
            Test.startTest();
            Map<String,Object> accountDataMap= CDdMXPManagerController.updateMxAccountRecords(accountsDataString);
            Test.stopTest();
            
            System.assertEquals('Mx Success Associate Queue', accList.Case_Routing_Override__c, 'Case Routing Override is not same as expected.');
        }
    }
    
    /** 
     * @description Test method for updateMxAccountRecords method with Exception
     */
    @isTest
    public static void testupdateMxAccountRecordsException(){
        Boolean exceptionOccured;
        String exceptionType;
        System.runAs(getTestRunUserNonSysAdmin()){
            Account accList = [SELECT Id, 
                                Name,
                                Case_Routing_Override__c 
                                FROM Account 
                                WHERE Name = 'Test Acc' LIMIT 1];
            accList.Case_Routing_Override__c = 'Test exception';
            CDdMXPManagerController.AccountWrapper accWrap= new CDdMXPManagerController.AccountWrapper();
            accWrap.AccountId = accList.Id;
            accWrap.caserouting = accList.Case_Routing_Override__c;
            String accountsDataString = JSON.serialize(new List<CDdMXPManagerController.AccountWrapper>{accWrap});
            try{
                Test.startTest();
                Map<string,Object> accountDataMap= CDdMXPManagerController.updateMxAccountRecords(accountsDataString);
                Test.stopTest();
            }catch(Exception e){
                exceptionOccured = true;
                exceptionType = e.getTypeName();
            }
        }
        System.assertEquals(true, exceptionOccured, 'Exception was not thrown as expected.');
        System.assertEquals('System.AuraHandledException', exceptionType, 'Exception Type is not same as expected.');
    }
}