/**
* @author Kody Hungenberg
* @date  2021-06-15
* @decription Test class for CDdAcctTeamMemberReopenHandler
*/
@IsTest
public class CDdAcctTeamMemberReopenHandlerTest {
/*****************************************************************************************************************************
*
* Constants & Private Variables
*
*****************************************************************************************************************************/
private static Id caseRecordTypeId = CDdRecordTypeCase.customer();
/*****************************************************************************************************************************
*
* Test data setup and test methods 
*
*****************************************************************************************************************************/

  /**
  * @author Kody Hungenberg
  * @date  2021-06-15
  * @decription test data setup
  * @param   None
  * @return  None
  */
  @TestSetup
  static void makeData() {
    List<Account> acctList = new List<Account>();
    List<AccountTeamMember> atmList = new List<AccountTeamMember>();
    List<User> insUser = new List<User>();

    /*** test users setup ***/
    List<User> testUsers = TDdAccountFactory.createUsersWithoutRole(3);

    User testUser0 = testUsers[0]; //Valid MXP Agent
    testUser0.Is_Out_Of_Office__c = false;
    testUser0.Out_Of_Office_End_Date__c = Date.today() +1;
    testUser0.FirstName = CDdSupportConstants.NAME_MXP_AGENT;
    testUser0.LastName = CDdSupportConstants.NAME_TEST_USER;
    insUser.add(testUser0);

    User testUser1 = testUsers[1]; //OOO MXP Agent
    testUser1.Is_Out_Of_Office__c = true;
    testUser1.Out_Of_Office_End_Date__c = Date.today() +1;
    testUser1.FirstName = 'Out Of Office';
    testUser1.LastName = CDdSupportConstants.NAME_TEST_USER;
    insUser.add(testUser1);

    User testUser2 = testUsers[2]; //non MXP Agent
    testUser2.FirstName = 'Non MXP Agent';
    testUser2.LastName = CDdSupportConstants.NAME_TEST_USER;
    insUser.add(testUser2);

    insert insUser;
    /*** test accounts setup ***/
    
    List<Account> accts = TDdAccountFactory.createAccounts('test acct', 4);
    //test account override true
    Account acct0 = accts[0];
    acct0.Name = 'test acct0';
    acct0.Case_Routing_Override__c = CDdSupportConstants.QUEUE_MX_SUCCESSASSOCIATE;
    acctList.add(acct0);

    //test account override false
    Account acct1 = accts[1];
    acct1.Name = 'test acct1';
    acct1.Case_Routing_Override__c = '';
    acctList.add(acct1);

    //override is true but user is out of office
    Account acct2 = accts[2];
    acct2.Name = 'test acct2';
    acct2.Case_Routing_Override__c = CDdSupportConstants.QUEUE_MX_SUCCESSASSOCIATE;
    acctList.add(acct2);
    //override is true - no mxp account team members
    Account acct3 = accts[3];
    acct3.Name = 'test acct3';
    acct3.Case_Routing_Override__c = CDdSupportConstants.QUEUE_MX_SUCCESSASSOCIATE;
    acctList.add(acct3);

    insert acctList;

    /*** test account team member setup ***/
    AccountTeamMember atm0 = new AccountTeamMember();
    atm0.AccountId = acct0.Id;
    atm0.UserId = testUser0.Id;
    atm0.TeamMemberRole = CDdSupportConstants.MXP_ROLE_NAME;
    atmList.add(atm0);
    
    //override is true but user is out of office
    AccountTeamMember atm2 = new AccountTeamMember();
    atm2.AccountId = acct2.Id;
    atm2.UserId = testUser1.Id;
    atm2.TeamMemberRole = CDdSupportConstants.MXP_ROLE_NAME;
    atmList.add(atm2);

    insert atmList;

  }
  /**
  * @author Kody Hungenberg
  * @date  2021-06-15
  * @decription method for setting the feature flags on/off
  * @param   Boolean, Boolean
  * @return  None
  */
  private static void featureFlag(Boolean reopenBool, Boolean mxpBool){
    Support_Feature_Flag__c featureFlag = Support_Feature_Flag__c.getOrgDefaults();
    featureFlag.EnableReopen__c = reopenBool;
    upsert featureFlag;

    Support_Feature_Flag__c mxpFlag = Support_Feature_Flag__c.getOrgDefaults();
    mxpFlag.EnableMXPAgentReopens__c = mxpBool;
    upsert mxpFlag; 
  }

/*****************************************************************************************************************************
*
* Integration Tests
*
*****************************************************************************************************************************/
  /**
  * @author Kody Hungenberg
  * @date  2021-06-15
  * @decription tests when Override is set on account but no account team member present
  * @param   None
  * @return  None
  */
  @IsTest
  private static void shouldReopenCaseToFallbackQueue() {
    featureFlag(true, true);

    Account acct = [SELECT Id, Case_Routing_Override__c, Name FROM Account WHERE Name =: 'test acct3'][0];
    System.assert(acct != null, 'Account should not be null');
    System.assertEquals(CDdSupportConstants.QUEUE_MX_SUCCESSASSOCIATE,acct.Case_Routing_Override__c, 'acct case routing override should be	Mx Success Associate Queue');
    System.assertEquals('test acct3', acct.Name, 'account name should be test acct3');

    User testUser = [SELECT Id, FirstName FROM User WHERE FirstName =:'Non MXP Agent'][0];
    System.assert(testUser != null, 'testUser should not be null');
    System.assertEquals('Non MXP Agent', testUser.FirstName, 'testUser should be Non MXP Agent');

    Case testCase = TDdCaseFactory.createSolveableSupportCase(1,caseRecordTypeId)[0];
    //testCase.OwnerId = testUser.Id;
    testCase.Subject = 'test';
    testCase.AccountId = acct.Id;
    testCase.Status = 'New';
    insert testCase;

    testCase.Status = 'Solved'; //have to update the status to solved after insert
    update testCase;

    Test.startTest();
    Case_Reopen_Event__e cre = new Case_Reopen_Event__e();
    cre.CaseId__c = testCase.Id;
    Database.SaveResult sr = EventBus.publish(cre);
    System.assertEquals(true, sr.isSuccess(), 'Platform event should publish successfully');

    Test.stopTest();

    List<Case> returnedCaseList = [
      SELECT Id, Status, AccountId, OwnerId, Owner.Name
      FROM Case
      WHERE Id = :testCase.Id
    ];
    Case returnedCase = returnedCaseList[0];
    System.assertEquals(1, returnedCaseList.size(), 'returnedCaseList should contain 1 record');

    String ownerId = returnedCase.OwnerId;
    System.assertEquals('Reopened', returnedCase.Status, 'returnedCase status should be reopened');
    System.assert(ownerId.startsWithIgnoreCase('00G'), 'ownerId should be a queue. Actual: ' + ownerId);
  }
  /**
  * @author Kody Hungenberg
  * @date  2021-06-15
  * @decription tests when Override is set on account and active account team member is present
  * @param   None
  * @return  None
  */
  @IsTest
  private static void shouldReopenAndUpdateOwnerToAccountTeamMember() {
    //set flags:
    featureFlag(true, true);

    User testUser0 = [SELECT Id, FirstName FROM User WHERE FirstName =: CDdSupportConstants.NAME_MXP_AGENT];

    Account acct = [SELECT Id, Case_Routing_Override__c FROM Account WHERE Name =: 'test acct0'][0];
    System.assertEquals(CDdSupportConstants.QUEUE_MX_SUCCESSASSOCIATE, acct.Case_Routing_Override__c, 'Case Routing Override should be set');

    Case testCase = TDdCaseFactory.createSolveableSupportCase(1,caseRecordTypeId)[0];
    //testCase.OwnerId = testUser1.Id;
    testCase.Subject = 'test';
    testCase.AccountId = acct.Id;
    testCase.Status = 'New';
    insert testCase;

    testCase.Status = 'Solved'; //have to update the status to solved after insert
    update testCase;

    Test.startTest();
    Case_Reopen_Event__e cre = new Case_Reopen_Event__e();
    cre.CaseId__c = testCase.Id;
    Database.SaveResult sr = EventBus.publish(cre);
    System.assertEquals(true, sr.isSuccess(), 'Platform event should fire successfully');

    Test.stopTest();

    List<Case> returnedCaseList = [
      SELECT Id, Status, AccountId, OwnerId
      FROM Case
      WHERE Id = :testCase.Id
    ];
    Case returnedCase = returnedCaseList[0];

    System.assertEquals(1, returnedCaseList.size(), 'returnedCaseList should contain 1 record');
    System.assertEquals('Reopened', returnedCase.Status, 'returnedCase Status should be Reopened');
    System.assertEquals(testUser0.Id, returnedCase.OwnerId, 'returnedCase owner should be testUser0');
  }
  /**
  * @author Kody Hungenberg
  * @date  2021-06-15
  * @decription tests when Override is set on account but account team member is OOO
  * @param   None
  * @return  None
  */
  @IsTest 
  private static void shouldNotUpdateOwnerToUser() {
    //set flags:
    featureFlag(true, true);

    List<User> testUsers = [
      SELECT Id,FirstName, Is_Out_Of_Office__c
      FROM User
      WHERE FirstName =: 'Out Of Office'
    ];
    System.assertEquals(1, testUsers.size(), 'Test user list should return only 1 user');

    User testUser1 = testUsers[0]; //MXP user that is OOO
    System.assertEquals(true, testUser1.Is_Out_Of_Office__c, 'Test User should be set Out of office = true');

    Account acct = [SELECT Id, Case_Routing_Override__c FROM Account WHERE Name =: 'test acct2'][0];
    System.assertEquals(CDdSupportConstants.QUEUE_MX_SUCCESSASSOCIATE, acct.Case_Routing_Override__c, 'Case Routing Override should be set');

    AccountTeamMember atm = [
        SELECT Id, AccountId, UserId, TeamMemberRole, Is_Out_Of_Office__c
        FROM AccountTeamMember
        WHERE UserId = :testUser1.Id
      ][0];
    System.assertEquals(true, atm.Is_Out_Of_Office__c, 'ATM should have Out of office set to true');

    Case testCase = TDdCaseFactory.createSolveableSupportCase(1,caseRecordTypeId)[0];
    testCase.Subject = 'test';
    testCase.AccountId = acct.Id;
    testCase.Status = 'New';
    insert testCase;

    testCase.Status = 'Solved'; //have to update the status to solved after insert
    update testCase;

    Test.startTest();
    Case_Reopen_Event__e cre = new Case_Reopen_Event__e();
    cre.CaseId__c = testCase.Id;
    Database.SaveResult sr = EventBus.publish(cre);
    System.assertEquals(true, sr.isSuccess(), 'Platform event should publish successfully');

    Test.stopTest();

    List<Case> returnedCaseList = [
      SELECT Id, Status, AccountId, OwnerId,Owner.Name
      FROM Case
      WHERE Id = :testCase.Id
    ];
    Case returnedCase = returnedCaseList[0];
    String ownerId = returnedCase.OwnerId;

    System.assertEquals(1, returnedCaseList.size(), 'returnedCaseList should contain 1 record');
    System.assertEquals('Reopened', returnedCase.Status, 'returnedCase status should be reopened');
    System.assertNotEquals(testUser1.Id, returnedCase.OwnerId, 'returned case owner should not be testUser1 Id');
    System.assert(ownerId.startsWithIgnoreCase('00G'));
  }
  /**
  * @author Kody Hungenberg
  * @date  2021-06-15
  * @decription tests feature flag to bypass account team member reopening - should default to fallback queue
  * @param   None
  * @return  None
  */
  @IsTest
  private static void shouldBypassAndUpdateToQueue() {
    //set flags:sets feature flag to bypass account team member reopening - default to fallback queue
    featureFlag(true, false);

    Account acct = [SELECT Id, Case_Routing_Override__c FROM Account WHERE Name =: 'test acct0'][0];
    System.assertEquals(CDdSupportConstants.QUEUE_MX_SUCCESSASSOCIATE, acct.Case_Routing_Override__c, 'Case Routing Override should be set');

    Case testCase = TDdCaseFactory.createSolveableSupportCase(1,caseRecordTypeId)[0];
    testCase.Subject = 'test';
    testCase.AccountId = acct.Id;
    testCase.Status = 'New';
    insert testCase;

    testCase.Status = 'Solved'; //have to update the status to solved after insert
    update testCase;

    Test.startTest();
    Case_Reopen_Event__e cre = new Case_Reopen_Event__e();
    cre.CaseId__c = testCase.Id;
    Database.SaveResult sr = EventBus.publish(cre);
    System.assertEquals(true, sr.isSuccess(), 'Platform event should publish successfully');
    Test.stopTest();

    List<Case> returnedCaseList = [
      SELECT Id, Status, AccountId, OwnerId
      FROM Case
      WHERE Id = :testCase.Id
    ];
    Case returnedCase = returnedCaseList[0];
    String ownerId = returnedCase.OwnerId;

    System.assertEquals(1, returnedCaseList.size(), 'returnedCaseList should contain 1 record');
    System.assertEquals('Reopened', returnedCase.Status, 'returnedCase status should be reopened');
    System.assert(OwnerId.startsWithIgnoreCase('00G'), 'OwnerId should be a queue');
  }
}