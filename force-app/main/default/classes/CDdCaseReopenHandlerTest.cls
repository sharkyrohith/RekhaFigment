/**
* @author Kody Hungenberg
* @date  2021-06-15
* @decription Test class for CDdCaseReopenHandler
*/
@IsTest
public class CDdCaseReopenHandlerTest {


/*****************************************************************************************************************************
*
* Constants & Private Variables
*
*****************************************************************************************************************************/
  private static final String TEST_REOPEN_QUEUE = '00G03000000yFXpEAM'; //'00G03000000yFXp'; //test queue in Case_Reopen_Queues__mdt
  //private static final String TEST_REOPEN_QUEUE = createFakeId(Queue.SObjectType);
  private static Id caseRecordTypeId = CDdRecordTypeCase.customer();

/*****************************************************************************************************************************
*
* Test data setup and test methods
*
*****************************************************************************************************************************/

  @TestSetup
  static void makeData() {
    List<Account> acctList = new List<Account>();
    List<AccountTeamMember> atmList = new List<AccountTeamMember>();
    List<User> insUser = new List<User>();

    /*** test users setup ***/
    List<User> testUsers = TDdAccountFactory.createUsersWithoutRole(3);

    User testUser0 = testUsers[0]; //Valid MXP Agent
    testUser0.Is_Out_Of_Office__c = false;
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

    //test account override true
    List<Account> accts = TDdAccountFactory.createAccounts('test acct', 3);

    Account acct0 = accts[0];
    acct0.Name = 'test acct0';
    acct0.Case_Routing_Override__c = CDdSupportConstants.QUEUE_MX_SUCCESSASSOCIATE;
    acctList.add(acct0);
    //test account override false
    Account acct1 = accts[1];
    acct1.Name = 'test acct1';
    acct1.Case_Routing_Override__c = '';
    acctList.add(acct1);

    Account acct2 = accts[2];
    acct2.Name = 'test acct2';
    acct2.Case_Routing_Override__c = '';
    acctList.add(acct2);

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
  * @decription method for setting the feature flags on/off
  * @param   Boolean, Boolean
  * @return  None
  */
  private static void featureFlag(Boolean reopenBool, Boolean mxpBool){
    Support_Feature_Flag__c featureFlag = Support_Feature_Flag__c.getOrgDefaults();
    featureFlag.EnableReopen__c = reopenBool;
    featureFlag.Disable_THQ_Callouts__c = true;
    upsert featureFlag;

    Support_Feature_Flag__c mxpFlag = Support_Feature_Flag__c.getOrgDefaults();
    mxpFlag.EnableMXPAgentReopens__c = mxpBool;
    upsert mxpFlag;

    vCS__c testSettings;
    testSettings = VTestUtil.createVeltigSettings();
    testSettings.CaseTrigger__c = true;
    insert testSettings;
  }
  /**
  * @author Kody Hungenberg
  * @date  2021-06-15
  * @decription method for creating a fake object Id
  * @param   None
  * @return  None
  */
  private static Id createFakeId(Schema.SObjectType sObj) {
    Integer s_num = 1;
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
/*****************************************************************************************************************************
*
* Unit Tests
*
*****************************************************************************************************************************/
  /**
  * @author Kody Hungenberg
  * @date  2021-06-15
  * @decription tests method 'addCaseIdsToSet', should return set of case Ids from pvet
  * @param   None
  * @return  None
  */
  @IsTest
  private static void shouldAddIdToSet() {
    CDdCaseReopenHandler reopenHandler = new CDdCaseReopenHandler();
    List<Case_Reopen_Event__e> reopenEvents = new List<Case_Reopen_Event__e>();

    Case_Reopen_Event__e caseEvent = new Case_Reopen_Event__e();
    caseEvent.CaseId__c = createFakeId(Case.SObjectType);
    reopenEvents.add(caseEvent);

    Set<Id> returnIds = reopenHandler.addCaseIdsToSet(reopenEvents);
    System.assert(returnIds != null);
    System.assert(returnIds.contains(caseEvent.CaseId__c));
  }

  /**
  * @author Kody Hungenberg
  * @date  2021-06-15
  * @decription tests method 'updateCaseOwner', takes a Set of CaseIds, queries cases with those Ids
  * @param   None
  * @return  None
  */
  @IsTest
  private static void shouldReturnListOfCasesBasedOnIds() {
    Set<Id> caseIds = new Set<Id>();
    Id testId;

    Case testCase = TDdCaseFactory.createSolveableSupportCase(1,caseRecordTypeId)[0];
    insert testCase;

    List<Case> testList = [SELECT Id, Previous_Queue_ID__c FROM Case WHERE Id =: testCase.Id];
    System.assertEquals(1, testList.size(), 'Test list should equal 1 case');
    Case testCase1 = testList[0];
    caseIds.add(testCase1.Id);

    CDdCaseReopenHandler reopenHandler = new CDdCaseReopenHandler();
    List<Case> returnCases = reopenHandler.caseQuery(caseIds);
    Case returnCase = returnCases[0];
    System.assertEquals(1, returnCases.size());
    System.assertEquals(testCase.Id,returnCase.Id, 'Return case.id should equal test case.id');

  }
/*****************************************************************************************************************************
*
* Integration Tests
*
*****************************************************************************************************************************/
  /**
  * @author Kody Hungenberg
  * @date  2021-06-15
  * @decription tests where Account.Case_Routing_Override__c is not set
  * @param   None
  * @return  None
  */
    @IsTest
    private static void shouldReopenCaseToPreviousQueue(){
      //System.debug('<><><><>shouldReopenCaseToPreviousQueue<><><><>');
      featureFlag(true, true);
      List<Case> returnCases = new List<Case>();
      //Creating Group
      Group testGroup = new Group(Name= 'Test Queue', Type = CDdSupportConstants.GROUP_QUEUE);
      insert testGroup;
      System.debug('testGroup ' + testGroup);
      QueuesObject testQueue;
          System.runAs(new User(Id=UserInfo.getUserId())) {
      //Associating queue with group AND to the Case object
          testQueue = new QueueSObject(QueueID = testGroup.Id, SObjectType = CDdSupportConstants.CASE_OBJECT_LABEL);
          insert testQueue;
          }

      Id reopenQueueId = testQueue.QueueId;
      setTestQueue(testGroup.Name,reopenQueueId,false,true);

      //get acct where override is false
      Account acct = [
        SELECT Id, Case_Routing_Override__c
        FROM Account
        WHERE Name =:'test acct2'
      ][0];

      Case testCase = TDdCaseFactory.createSolveableSupportCase(1,caseRecordTypeId)[0];
      testCase.Subject = 'test';
      testCase.AccountId = acct.Id;
      testCase.Status = 'New';
      testCase.Previous_Queue_ID__c = reopenQueueId;
      testCase.Previous_Queue__c = 'Test Queue';
      insert testCase;

      testCase.Status = 'Solved'; //have to update the status to solved after insert
      update testCase;

      Test.startTest();

      Case_Reopen_Event__e cre = new Case_Reopen_Event__e();
      cre.CaseId__c = testCase.Id;
      Database.SaveResult sr = EventBus.publish(cre);
      System.assertEquals(true, sr.isSuccess(), 'Event should publish successfully');

      Test.stopTest();

      List<Case> returnedCaseList = [
        SELECT Id, Status, AccountId, OwnerId, Previous_Queue_Id__c, Previous_Queue__c
        FROM Case
        WHERE Id =:testCase.Id
      ];
      System.debug('returnedCaseList ' + returnedCaseList);

      System.assertEquals(1, returnedCaseList.size(), 'ReturnedCaseList should equal 1');
      Case returnedCase = returnedCaseList[0];
      System.assertEquals('Reopened', returnedCase.Status, 'Returned Case Status should equal Reopened');
      System.assertEquals(reopenQueueId, returnedCase.OwnerId, 'Returned Case owner should equal test queue');

    }
  /**
  * @author Kody Hungenberg
  * @date  2021-06-15
  * @decription tests where reopen to MXP agent feature flag is false - should reopen case
  * @param   None
  * @return  None
  */
    @IsTest
    private static void shouldSetStatusToReopened(){
      //System.debug('<><><><>shouldSetStatusToReopened<><><><>');
      featureFlag(true, false);
      List<Case> returnCases = new List<Case>();
      List<User> testUsers = [SELECT Id, LastName FROM User WHERE LastName = :'Test user' AND FirstName = : 'Non MXP Agent'];
      CDdCaseReopenHandler reopenHandler = new CDdCaseReopenHandler();

      //get acct where override is false
      Account acct = [
        SELECT Id, Case_Routing_Override__c
        FROM Account
        WHERE Name =:'test acct1'
      ][0];


      Case testCase = TDdCaseFactory.createSolveableSupportCase(1,caseRecordTypeId)[0];
      testCase.OwnerId = testUsers[0].Id;
      testCase.Subject = 'test';
      testCase.AccountId = acct.Id;
      testCase.Status = 'New';
      testCase.Previous_Queue_ID__c = '';
      insert testCase;

      testCase.Status = 'Solved'; //have to update the status to solved after insert
      update testCase;

      Test.startTest();

      Case_Reopen_Event__e cre = new Case_Reopen_Event__e();
      cre.CaseId__c = testCase.Id;
      Database.SaveResult sr = EventBus.publish(cre);
      System.assertEquals(true, sr.isSuccess(),'Event should publish successfully');

      Test.stopTest();

      List<Case> returnedCaseList = [
        SELECT Id, Status, AccountId, OwnerId
        FROM Case
        WHERE Id =:testCase.Id
      ];
      System.assertEquals(1, returnedCaseList.size(), 'ReturnedCaseList should equal 1');
      Case returnedCase = returnedCaseList[0];
      System.assertEquals('Reopened', returnedCase.Status,'Returned Case Status should equal Reopened');

    }
  /**
  * @author Kody Hungenberg
  * @date  2021-06-15
  * @decription tests where account override is set and an active account team member is present.
  * @param   None
  * @return  None
  */
  @IsTest
  private static void shouldUpdateOwnerToAccountTeamMember() {
    //set flags:
    featureFlag(true, true);

    User testUser0 = [SELECT Id, FirstName FROM User WHERE FirstName = : CDdSupportConstants.NAME_MXP_AGENT];

    Account acct = [SELECT Id, Case_Routing_Override__c FROM Account WHERE Name =: 'test acct0'][0];
    System.assertEquals('Mx Success Associate Queue', acct.Case_Routing_Override__c, 'Case Routing Override should be set');

    Case testCase = TDdCaseFactory.createSolveableSupportCase(1,caseRecordTypeId)[0];
    //testCase.OwnerId = testUser1.Id;
    testCase.Subject = 'test';
    testCase.AccountId = acct.Id;
    testCase.Status = 'New';
    testCase.Issue__c = null;
    testCase.Issue_Type__c = 'Account Management - MX';
    testCase.Customer_Type__c = 'Merchant';
    testCase.Resolution__c = null;
    testCase.Resolution_Type__c = null;

    Test.startTest();
     insert testCase;
    Test.stopTest();

    List<Case> returnedCaseList = [
      SELECT Id, Status, AccountId, OwnerId
      FROM Case
      WHERE Id = :testCase.Id
    ];
    Case returnedCase = returnedCaseList[0];

    System.assertEquals(1, returnedCaseList.size(), 'returnedCaseList should contain 1 record');
    System.assertEquals('Open', returnedCase.Status, 'returnedCase Status should be Reopened');
    System.assertEquals(testUser0.Id, returnedCase.OwnerId, 'returnedCase owner should be testUser0');
  }
  /**
  * @author Kody Hungenberg
  * @date  2021-06-15
  * @decription tests both feature flag bypasses - should set status to reopened
  * @param   None
  * @return  None
  */
    @IsTest
    private static void shouldUpdateStatusToReopened(){
      //System.debug('<><><><>shouldUpdateStatusToReopened<><><><>');
      featureFlag(false, false);
      List<Case> returnCases = new List<Case>();
      List<User> testUsers = [SELECT Id, LastName FROM User WHERE LastName = :'Test user'];
      CDdCaseReopenHandler reopenHandler = new CDdCaseReopenHandler();

      User testUser = testUsers[0];

      //get acct where override is false
      Account acct = [
        SELECT Id, Case_Routing_Override__c
        FROM Account
        WHERE Name =:'test acct1'
      ][0];

      Case testCase = TDdCaseFactory.createSolveableSupportCase(1,caseRecordTypeId)[0];
      testCase.OwnerId = testUser.Id;
      testCase.Subject = 'test';
      testCase.AccountId = acct.Id;
      testCase.Status = 'New';
      testCase.Previous_Queue_ID__c = TEST_REOPEN_QUEUE;
      insert testCase;

      testCase.Status = 'Solved'; //have to update the status to solved after insert
      update testCase;

      Test.startTest();

      Case_Reopen_Event__e cre = new Case_Reopen_Event__e();
      cre.CaseId__c = testCase.Id;
      Database.SaveResult sr = EventBus.publish(cre);
      System.assertEquals(true, sr.isSuccess(), 'Event should publish successfully');

      Test.stopTest();

      List<Case> returnedCaseList = [
        SELECT Id, Status, AccountId, OwnerId
        FROM Case
        WHERE Id =:testCase.Id
      ];
      System.assertEquals(1, returnedCaseList.size(), 'Returned Case List should equal 1');
      Case returnedCase = returnedCaseList[0];
      System.assertEquals('Reopened', returnedCase.Status, 'Returned Case status should equal reopened');
    }
}