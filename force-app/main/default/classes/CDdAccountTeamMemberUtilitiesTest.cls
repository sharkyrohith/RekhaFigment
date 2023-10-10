/**
* @author Kody Hungenberg
* @date  2021-06-15
* @decription Test class for CDdAccountTeamMemberUtilities
*/
@IsTest
public class CDdAccountTeamMemberUtilitiesTest {
/*****************************************************************************************************************************
*
* Constants & Private Variables
*
*****************************************************************************************************************************/
private static Id caseRecordTypeId = CDdRecordTypeCase.customer();
private static Integer s_num = 1;
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
    List<Account> accts = TDdAccountFactory.createAccounts('test acct', 3);

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

    insert acctList;

    /*** test account team member setup ***/
    AccountTeamMember atm0 = new AccountTeamMember();
    atm0.AccountId = acct0.Id;
    atm0.UserId = testUser0.Id;
    atm0.TeamMemberRole = CDdSupportConstants.MXP_ROLE_NAME;
    atmList.add(atm0);

    AccountTeamMember atm1 = new AccountTeamMember();
    atm1.AccountId = acct0.Id;
    atm1.UserId = testUser1.Id;
    atm1.TeamMemberRole = CDdSupportConstants.MXP_ROLE_NAME;
    atmList.add(atm1);

    AccountTeamMember atm2 = new AccountTeamMember();
    atm2.AccountId = acct1.Id;
    atm2.UserId = testUser2.Id;
    atm2.TeamMemberRole = '';
    atmList.add(atm2);
    insert atmList;

  }
    /**
  * @author Kody Hungenberg
  * @date  2021-06-15
  * @decription method for creating a fake object Id
  * @param   None
  * @return  None
  */
  private static Id createFakeId(Schema.SObjectType sObj) {
    String result = String.valueOf(s_num++);
    return sObj.getDescribe().getKeyPrefix() +
      '0'.repeat(12 - result.length()) +
      result;
  }
  /**
  * @author Raj Chilukuri
  * @date  2021-06-15
  * @decription test method sets the queue Id for testing
  * @param   None
  * @return  None
  */
  static void setTestQueue(String qName,String qId,Boolean isFallBack,Boolean isReopen){

    Case_Reopen_Queues__mdt crq = new Case_Reopen_Queues__mdt(Queue_Id__c = qId,
                                                              IsFallback__c = isFallBack,
                                                              Queue_Reopen__c = isReopen,
                                                              Queue_Name__c = qName,
                                                              DeveloperName = qName,
                                                              MasterLabel = qName,
                                                              Id = createFakeId(Case_Reopen_Queues__mdt.SObjectType)
                                                              );
	  Map<String,Case_Reopen_Queues__mdt> testQueueMap = new Map<String,Case_Reopen_Queues__mdt>();
	  testQueueMap.put(crq.DeveloperName,crq);
	  CDdAccountTeamMemberUtilities.caseReopenQueueMap = testQueueMap;
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
* Unit Tests
*
*****************************************************************************************************************************/
  /**
  * @author Kody Hungenberg
  * @date  2021-06-15
  * @decription tests method 'getAcctIdsFromCase', should return a set of acct ids
  * @param   None
  * @return  None
  */
  @IsTest
  private static void shouldReturnSetOfAccountIdsFromListOfCases() {
    List<Case> testCases = new List<Case>();
    Id acctId = [SELECT Id, Name FROM Account WHERE Name = :'test acct0'].Id;
    System.assert(acctId != null, ' Account Id should not return null');

    List<Case> caseList = TDdCaseFactory.createSolveableSupportCase(
        5,
        caseRecordTypeId
      );
      
    System.assert(caseList != null, ' Case List should not be null');
    System.assert(caseList.isEmpty() == false, ' Case List should not be empty');
    for (Case c : caseList) {
      if (caseList?.isEmpty() == false) {
        c.AccountId = acctId;
        testCases.add(c);
      }
    }
    System.assert(testCases != null, ' Test Cases should not be null');
    System.assert(testCases.isEmpty() == false, ' Test cases should not be empty');

    Test.startTest();
    CDdAccountTeamMemberUtilities atmUtil = new CDdAccountTeamMemberUtilities();
    Set<Id> testAccountIds = atmUtil.getAcctIdsFromCase(testCases);
    Test.stopTest();

    System.assert(testAccountIds != null, ' testAccount Ids should not be null');
    System.assert(testAccountIds.isEmpty() == false, ' testAccountIds should not be empty');
    System.assertEquals(1, testAccountIds.size(), ' testAccountIds should equal 1');
  }
  /**
  * @author Kody Hungenberg
  * @date  2021-06-15
  * @decription tests method 'getATMByMXPRole', should return a list of accts with account team
  * @param   None
  * @return  None
  */
  @IsTest
  private static void shouldReturnAcctsWithATMs() {
    List<Account> returnedAcctList = new List<Account>();
    Set<Id> acctIdSet = new Set<Id>();
    Account acct = [
      SELECT Id, Case_Routing_Override__c
      FROM Account
      WHERE Name =:'test acct0'
    ][0];

    acctIdSet.add(acct.Id);
    Test.startTest();
    CDdAccountTeamMemberUtilities atmutil = new CDdAccountTeamMemberUtilities();
    returnedAcctList = atmutil.getATMByMXPRole(acctIdSet);
    Test.stopTest();

    System.assert(returnedAcctList != null, ' returnedAcctList should not be null');
    System.assertEquals(1, returnedAcctList.size(), ' returnedAcctList shoud equal one');
    Account returnedAcct = returnedAcctList[0];
    System.assertEquals(1, returnedAcct.AccountTeamMembers.size(), 'returnedAcct account team members should be 1');
  }
  /**
  * @author Kody Hungenberg
  * @date  2021-06-15
  * @decription tests method 'mapUserIdsToAcctIds', should return a map of acctId to 
  * set of acct team member user Ids
  * @param   None
  * @return  None
  */
  @IsTest
  private static void shouldMapUserIdsToAccountsByAccountTeam(){
    List<Case> caseList = new List<Case>();
    Map<Id, Set<Id>> acctIdToATMIds = new Map<Id, Set<Id>>();
    List<Account> acctList = new List<Account>();
    CDdAccountTeamMemberUtilities atmUtil = new CDdAccountTeamMemberUtilities();
    Id caseRecordTypeId = CDdRecordTypeCase.customer();
    List<Case> testCases = TDdCaseFactory.createCases(2,caseRecordTypeId);
    System.assertEquals(2, testCases.size(), ' testCases list should contain 2');

    List<User> testUsers = [SELECT Id, LastName FROM User WHERE LastName = :'Test user'];
    User runUser0 = testUsers[0];
    User runUser1 = testUsers[1];

    Account acct0 = [SELECT Id, Case_Routing_Override__c FROM Account WHERE Name =:'test acct0'][0];
    acctList.add(acct0);
    Account acct1 = [SELECT Id, Case_Routing_Override__c FROM Account WHERE Name =:'test acct1'][0];
    acctList.add(acct1);

    AccountTeamMember atm = [SELECT Id, TeamMemberRole, AccountId, UserId 
                            FROM AccountTeamMember 
                            WHERE AccountId =: acct0.Id][0]; 

    Test.startTest();
    acctIdToATMIds = atmUtil.mapUserIdsToAcctIds(acctList);
    Test.stopTest();

    System.assert(acctIdToATMIds != null, ' acctIdToATMIds should not be null');
    System.assert(acctIdToATMIds.isEmpty() == false, ' acctIdToATMIds should not be empty');
    System.assert(acctIdToATMIds.containsKey(acct1.Id), ' acctIdToATMIds should contain acc1 id');

  }
  /**
  * @author Kody Hungenberg
  * @date  2021-06-15
  * @decription tests method 'getOverrideCases', should return a list of cases where 
  * account.case_routing_override__c is set to 'Mx Success Associate Queue'
  * @param   None
  * @return  None
  */
  @IsTest
  private static void shouldReturnCasesWithOverrideTrue() {
    List<Account> acctList = new List<Account>();
    List<Case> testCases = new List<Case>();
    List<Case> returnedList = new List<Case>();

    
    //Account with routing override true
    Account acct0 = [SELECT Id, Case_Routing_Override__c FROM Account WHERE Name =:'test acct0'][0];
    acctList.add(acct0); 
    //Account with routing override false
    Account acct1 = [SELECT Id, Case_Routing_Override__c FROM Account WHERE Name =:'test acct1'][0];
    acctList.add(acct1);
     
    List<Case> caseList = TDdCaseFactory.createSolveableSupportCase(2,caseRecordTypeId);
    //account override true case
    Case c0 = caseList[0];
    c0.AccountId = acct0.Id;
    c0.Subject = 'test';
    testCases.add(c0);
    //account override false case
    Case c1 = caseList[1];
    c1.AccountId = acct1.Id;
    c1.Subject = 'test';
    testCases.add(c1);
    insert testCases;
   
    List<Case> caseQueryList = [
      SELECT Id, AccountId, Subject, Account.Case_Routing_Override__c
      FROM Case
      WHERE Id IN: testCases
    ]; 

    Test.startTest();
    CDdAccountTeamMemberUtilities atmutil = new CDdAccountTeamMemberUtilities();
    returnedList = atmutil.getOverrideCases(caseQueryList);
    Test.stopTest();
    System.assert(returnedList != null, ' returnedList should not be null');
    System.assert(returnedList.isEmpty() == false, ' returnedList should not be empty');

    Case testCase = returnedList[0];
    System.assertEquals(1, returnedList.size(), ' returnedList size should be 1');
    System.assertEquals(acct0.Id, testCase.AccountId, ' testCase.AccountId should equal acct0.Id');
  }
  /**
  * @author Kody Hungenberg
  * @date  2021-06-15
  * @decription tests method 'getATgetNonOverrideCasesMByMXPRole', should return a list of cases where 
  * account.case_routing_override__c is not set.
  * @param   None
  * @return  None
  */
  @IsTest
  private static void shouldReturnCasesWithOverrideFalse() {
    List<Account> acctList = new List<Account>();
    List<Case> testCases = new List<Case>();
    List<Case> returnedList = new List<Case>();

    //Account with routing override true
    Account acct0 = [SELECT Id, Case_Routing_Override__c FROM Account WHERE Name =:'test acct0'][0];
    acctList.add(acct0); 
    //Account with routing override false
    Account acct1 = [SELECT Id, Case_Routing_Override__c FROM Account WHERE Name =:'test acct1'][0];
    acctList.add(acct1);

    List<Case> caseList = TDdCaseFactory.createSolveableSupportCase(2,caseRecordTypeId);
    //override true case
      Case c0 = caseList[0];
      c0.AccountId = acct0.Id;
      c0.Subject = 'test';
      testCases.add(c0);
      //override false case
      Case c1 = caseList[1];
      c1.AccountId = acct1.Id;
      c1.Subject = 'test';
      testCases.add(c1);
      insert testCases;

    List<Case> caseQueryList = [
      SELECT Id, AccountId, Subject, Account.Case_Routing_Override__c
      FROM Case
      WHERE Id IN: testCases
    ];
    Test.startTest();
    CDdAccountTeamMemberUtilities atmutil = new CDdAccountTeamMemberUtilities();
    returnedList = atmutil.getNonOverrideCases(caseQueryList);
    Test.stopTest();
    Case testCase = returnedList[0];


    System.assert(returnedList.isEmpty() == false, ' returnedList should not be empty');
    System.assertEquals(1, returnedList.size(), ' returnedList size should be 1');
    System.assertEquals(acct1.Id, testCase.AccountId, ' testCase.AccountId should equal acc1.Id');
  }

  /**
  * @author Kody Hungenberg
  * @date  2021-06-15
  * @decription tests method 'fallbackQueueIdSelector', should return the id of the fallback queue from metadata
  * @param   None
  * @return  None
  */
  @IsTest
  public static void shouldReturnFallbackQueueId() {

    String queueName = 'TEST_FALLBACK_QUEUE';
    Id fallbackQueueId = '00G03000000tEST';
	  setTestQueue(queueName,fallbackQueueId,true,false);
      
    Id returnId = CDdAccountTeamMemberUtilities.fallbackQueueIdSelector(queueName);
    System.assert(returnId != null, ' returnId should not be null');
    System.assertEquals(fallbackQueueId, returnId, ' returnId should equal fallbackQueueId');

  }
  @IsTest
  private static void shouldReturnReopenQueueId() {
    CDdAccountTeamMemberUtilities atmUtil = new CDdAccountTeamMemberUtilities();
    String queueName = 'TEST_REOPEN_QUEUE';
    Id reopenQueueId = '00G030000002EST';
    setTestQueue(queueName,reopenQueueId,false,true);  
    Id returnId = atmUtil.reopenQueueIdSelector(queueName);
    System.assert(returnId != null, ' returnId should not be null');
    System.assertEquals(reopenQueueId, returnId, ' returnId should equal reopenQueueId');

  }
  /**
  * @author Kody Hungenberg
  * @date  2021-06-15
  * @decription tests method 'mapUserToCases', should return a map of user Ids to cases 
  * where users are account team members of the account on the case
  * @param   None
  * @return  None
  */
  @IsTest
  private static void shouldReturnMapOfUserIdsToListOfCases(){
    
    CDdAccountTeamMemberUtilities atmUtil = new CDdAccountTeamMemberUtilities();
    Map<Id, List<Case>> returnMap = new Map<Id,List<Case>>();
    Map<Id, Set<Id>> accountIdToUserIdMap = new Map<Id, Set<Id>>();
    List<Case> caseList = new List<Case>();

    List<User> testUsers = [SELECT Id FROM User WHERE LastName = :'Test user'];
    System.assert(testUsers.isEmpty() == false, 'testUsers should contain users');

    Account testAccount0 = [SELECT Id, Name, Case_Routing_Override__c FROM Account WHERE Name =: 'test acct0'][0];
    System.assertEquals('test acct0', testAccount0.Name, 'test acct0 should exist');
    Account testAccount1 = [SELECT Id, Name, Case_Routing_Override__c FROM Account WHERE Name =: 'test acct1'][0];
    System.assertEquals('test acct1', testAccount1.Name, 'test acct1 should exist');
    //positive test case
    accountIdToUserIdMap.put(testAccount0.Id, new Set<Id>());
    accountIdToUserIdMap.get(testAccount0.Id).add(testUsers[0].Id);
    //negative test cases
    accountIdToUserIdMap.put(testAccount1.Id, new Set<Id>());
    accountIdToUserIdMap.get(testAccount1.Id).add(testUsers[2].Id);
    accountIdToUserIdMap.get(testAccount1.Id).add(testUsers[3].Id);

    List<Case> testCaseList = TDdCaseFactory.createSolveableSupportCase(3,caseRecordTypeId);
    
    Case testCase0 = testCaseList[0];
    testCase0.AccountId = testAccount0.Id;
    caseList.add(testCase0);

    Case testCase1 = testCaseList[1];
    testCase1.AccountId = testAccount1.Id;
    caseList.add(testCase1);

    Case testCase2 = testCaseList[2];
    testCase2.AccountId = testAccount1.Id;
    caseList.add(testCase2);

    returnMap = atmUtil.mapUserToCases(caseList,accountIdToUserIdMap);
    System.assert(returnMap.isEmpty() == false, ' returnMap should not be empty');
    System.assertEquals(2,returnMap.size(), ' returnMap size should equal 2');

  }
  /**
  * @author Kody Hungenberg
  * @date  2021-06-15
  * @decription tests method 'getCasesWithoutATM', should return a list of cases without account team members
  * @param   None
  * @return  None
  */
  @IsTest
  private static void shouldReturnCasesWithoutAccountTeamMembers(){
    List<Case> caseList = new List<Case>();
    List<Account> testAccounts = new List<Account>();
    List<Case> returnedCases = new List<Case>();

    CDdAccountTeamMemberUtilities atmUtil = new CDdAccountTeamMemberUtilities();

    Account testAccount0 = [SELECT Id, Name, Case_Routing_Override__c FROM Account WHERE Name =: 'test acct0'][0];
    System.assertEquals('test acct0', testAccount0.Name, 'test acct0 should exist');
    Account testAccount1 = [SELECT Id, Name, Case_Routing_Override__c FROM Account WHERE Name =: 'test acct1'][0];
    System.assertEquals('test acct1', testAccount1.Name, 'test acct1 should exist');
    testAccounts.add(testAccount1);

    List<Case> testCaseList = TDdCaseFactory.createSolveableSupportCase(3,caseRecordTypeId);
    
    Case testCase0 = testCaseList[0];
    testCase0.AccountId = testAccount0.Id;
    caseList.add(testCase0);

    Case testCase1 = testCaseList[1];
    testCase1.AccountId = testAccount1.Id;
    caseList.add(testCase1);

    Case testCase2 = testCaseList[2];
    testCase2.AccountId = testAccount1.Id;
    caseList.add(testCase2);

    returnedCases = atmUtil.getCasesWithoutATM(caseList,testAccounts);
    Case retCase0 = returnedCases[0];
    System.assertEquals(1, returnedCases.size(), 'returnedCases should only contain one case');
    System.assertEquals(testCase0.Id, retCase0.Id, 'Only testCase0 should be returned');

  }
  /**
  * @author Kody Hungenberg
  * @date  2021-06-15
  * @decription tests method 'reopenToAccountTeamMember', should return a list of cases where the owner == the 
  * account team member on the account associated to the case.
  * @param   None
  * @return  None
  */
  @IsTest
  private static void shouldReturnCasesOwnedByAccountTeamMember(){
    CDdAccountTeamMemberUtilities atmUtil = new CDdAccountTeamMemberUtilities();
    Map<Id, List<Case>> userIdCasesMap = new Map<Id, List<Case>>();
    Map<Id, Set<Id>> acctIdToATMIds = new Map<Id, Set<Id>>();
    List<Case> caseList = new List<Case>();

    List<User> testUsers = [SELECT Id FROM User WHERE LastName = :'Test user'];
    System.assert(testUsers.isEmpty() == false, 'testUsers should contain users');

    Account testAccount0 = [SELECT Id, Name, Case_Routing_Override__c FROM Account WHERE Name =: 'test acct0'][0];
    System.assertEquals('test acct0', testAccount0.Name, 'test acct0 should exist');

    acctIdToATMIds.put(testAccount0.Id, new Set<Id>());
    acctIdToATMIds.get(testAccount0.Id).add(testUsers[0].Id);
    acctIdToATMIds.get(testAccount0.Id).add(testUsers[1].Id);

    List<Case> testCaseList = TDdCaseFactory.createSolveableSupportCase(3,caseRecordTypeId);
    
    Case testCase0 = testCaseList[0];
    testCase0.AccountId = testAccount0.Id;

    Case testCase1 = testCaseList[1];
    testCase1.AccountId = testAccount0.Id;

    Case testCase2 = testCaseList[2];
    testCase2.AccountId = testAccount0.Id;

    userIdCasesMap.put(testUsers[0].Id, new List<Case>());
    userIdCasesMap.get(testUsers[0].Id).add(testCase0);
    userIdCasesMap.get(testUsers[0].Id).add(testCase1);
    userIdCasesMap.get(testUsers[0].Id).add(testCase2);

    caseList = atmUtil.setOwnerToAccountTeamMember(userIdCasesMap, acctIdToATMIds);


    System.assert(caseList?.isEmpty() == false, ' caseList should not be null or empty');
    System.assertEquals(3,caseList.size(), ' caseList should contain 3 cases');

    System.assert(caseList.contains(testCase0), ' caseList should contain testCase0');
    Case c0 = caseList[0];
    System.assertEquals(testUsers[0].Id, c0.OwnerId, ' c0.OwnerId should equal testUsers[0].Id');

    System.assert(caseList.contains(testCase1), ' caseList should contain testCase1');
    Case c1 = caseList[1];
    System.assertEquals(testUsers[0].Id, c1.OwnerId,  'c1.OwnerId should equal testUsers[0].Id');

    System.assert(caseList.contains(testCase2), ' caseList should contain testCase2');
    Case c2 = caseList[2];
    System.assertEquals(testUsers[0].Id, c2.OwnerId, ' c2.OwnerId should equal testUsers[0].Id');
  }
  /**
  * @author Kody Hungenberg
  * @date  2021-06-15
  * @decription tests method 'updateCasesToFallBackQueue', should return a list of cases where the owner == the 
  * MXP fallback queue
  * @param   None
  * @return  None
  */
  //test updateCasesToFallBackQueue
  @IsTest
  private static void shouldUpdateCasesToFallbackQueue(){
    CDdAccountTeamMemberUtilities atmUtil = new CDdAccountTeamMemberUtilities();
    List<Case> testCases = new List<Case>();
    String fallbackQueue = 'test fallback queue';
    setTestQueue(fallbackQueue, '00G030000002eDT', true, false);
    List<Case> caseList = TDdCaseFactory.createSolveableSupportCase(3,caseRecordTypeId);


    List<Case> returnCases = atmUtil.updateCasesToFallBackQueue(caseList, fallbackQueue);

    Case c0 = caseList[0];
    Case c1 = caseList[1];
    Case c2 = caseList[2];
    System.assertEquals(3, returnCases.size(), ' returnCases should contain 3 cases');
    System.assert(returnCases.contains(c0), ' returnCases should contain c0 case');
    System.assertEquals('00G030000002eDT',c0.OwnerId, ' c0.OwnerId should equal test fallback queue');
  }
    /**
  * @author Kody Hungenberg
  * @date  2021-06-15
  * @decription tests method 'updateCasesToFallBackQueue', should return a list of cases where the owner == the 
  * MXP fallback queue
  * @param   None
  * @return  None
  */
  //test updateCasesToFallBackQueue
  @IsTest
  private static void shouldUpdateCasesToReopenQueue(){
    CDdCaseReopenHandler reopenHandler = new CDdCaseReopenHandler();
    List<Case> testCases = new List<Case>();
    //Creating Group
    Group testGroup = new Group(Name='Test Queue', Type = CDdSupportConstants.GROUP_QUEUE);
    insert testGroup;
    QueuesObject testQueue;
    System.runAs(new User(Id=UserInfo.getUserId())) {
    //Associating queue with group AND to the Case object
    testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = CDdSupportConstants.CASE_OBJECT_LABEL);
    insert testQueue;
    }
    
    Id reopenQueueId = testQueue.QueueId;
    String reopenQueue = testGroup.Name;
    setTestQueue(reopenQueue, reopenQueueId, false, true);
    List<Case> caseList = TDdCaseFactory.createSolveableSupportCase(3,caseRecordTypeId);
    Case c0 = caseList[0];
    Case c1 = caseList[1];
    c0.Previous_Queue_ID__c = reopenQueueId;
    c0.Previous_Queue__c = reopenQueue;

    testCases.add(c0);
    c1.Previous_Queue_ID__c = '';
    testCases.add(c1);


    List<Case> returnCases = reopenHandler.updateCaseOwner(testCases);

    Case testCase0 = returnCases[0];
    Case testCase1 = returnCases[1];
    // Case c2 = caseList[2];
    System.assertEquals(2, returnCases.size(), ' returnCases should contain 3 cases');
    System.assert(returnCases.contains(testCase0), ' returnCases should contain c0 case');
    System.assertEquals(reopenQueueId,testCase0.OwnerId, ' c0.OwnerId should equal test queue');
  }
}