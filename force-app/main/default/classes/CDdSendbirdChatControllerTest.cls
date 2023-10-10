/**
 * CDdSendbirdChatControllerTest
 *
 * @author     Sahil
 * @date  2021-03-31
 * @decription Test class for CDdSendbirdChatController
 */
@isTest(seeAllData=false)
public with sharing class CDdSendbirdChatControllerTest {
  /**
   * @author     Sahil
   * @date  2021-03-30
   * @decription test setup
   * @param   None
   * @return  None
   */
  @TestSetup
  static void makeData() {
    //setup data here
    //insert quick text
    QuickText qt = new QuickText(
      Name = 'Test',
      Channel = CDdSupportConstants.LIVEAGENT_CHANNEL,
      Message = 'test message'
    );
    insert qt;

    //insert sendbird custom settings
    insert new Sendbird_Settings__c(Callout_Retries__c = 3);

    //insert integration settings
    Integration_Settings__c intSettings = new Integration_Settings__c();
    intSettings.Name = 'Agent Chat Users';
    intSettings.Endpoint__c = '/agent_chat_users';
    intSettings.Timeout__c = 33000;
    insert intSettings;
  }

  /**
   * @author     Sahil
   * @date  2021-03-30
   * @decription test standard controller of the vf page
   * @param   None
   * @return  None
   */
  @isTest
  static void testStandardController() {
    //create a case and pass into the controller
    List<Case> casesToTest = TDdCaseFactory.createCaseRecords(
      1,
      CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER
    );
    casesToTest[0]
      .ChatKey__c = 'sendbird_group_channel_8642_5a9d6c930f464908d6aaacb9a606d69cac1f169b';
    insert casesToTest;
    Case c = casesToTest[0];
    Test.startTest();
    CDdSendbirdChatController controller = new CDdSendbirdChatController(
      new Apexpages.StandardController(c)
    );
    Test.stopTest();
    //verify the case inserted
    List<Case> casesFromDB = [SELECT Id FROM Case];
    System.assertEquals(1, casesFromDB.size(), '1 case should be returned');
  }

  /**
   * @author     Sahil
   * @date  2021-03-30
   * @decription test get agent chat user sendbird endpoint
   * @param   None
   * @return  None
   */
  @isTest
  static void testGetAgentChatUser() {
    // Create the mock response based on a static resource
    StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    mock.setStaticResource('mockResponse_Sendbird_agentChatUsers');
    mock.setStatusCode(200);//success response code
    mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
    // Associate the callout with a mock response
    Test.setMock(HttpCalloutMock.class, mock);
    //create user
    User u = TDdUserFactory.createUsers(1)[0];
    insert u;
    String channelUrl = 'test_channelUrl';
    // Call method to test
    Test.startTest();
    String responseFromAPIUsingVF = CDdSendbirdChatController.getAgentChatUser(u.Id,channelUrl);
    String responseFromAPIUsingAura = CDdSendbirdChatController.getAgentChatUserAura(u.Id,channelUrl);
    //test with null user ids
    String negativeResponseVF = CDdSendbirdChatController.getAgentChatUser(null,null);
    String negativeResponseAura = CDdSendbirdChatController.getAgentChatUserAura(null,null);
    //test lightning
    Map<String,String> chatInfoMap = new Map<String,String>{
      'userId' => u.Id,
      'sendbirdChannelUrl' => channelUrl
    };
    Object responseLightning = CDdSendbirdChatController.processSendbirdActionCacheableAura('chat_info',chatInfoMap);
    Test.stopTest();
    //assert response
    System.assertEquals(String.isNotBlank(responseFromAPIUsingVF), true, 'callout should return mock response');
    System.assertEquals(String.isNotBlank(responseFromAPIUsingAura), true, 'callout should return mock response');
  }

  /**
   * @author     Sahil
   * @date  2021-03-30
   * @decription negative test get agent chat user sendbird endpoint
   * @param   None
   * @return  None
   */
  @isTest
  static void testGetAgentChatUserNegative() {
    // Create the mock response based on a static resource
    StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    mock.setStaticResource('mockResponse_Empty');
    mock.setStatusCode(500); //server error code
    mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
    // Associate the callout with a mock response
    Test.setMock(HttpCalloutMock.class, mock);
    User u = TDdUserFactory.createUsers(1)[0];
    insert u;
    String channelUrl = 'test_channelUrl';
    Test.startTest();
    Boolean isError = false;
    try {
      String responseFromAPIUsingVF = CDdSendbirdChatController.getAgentChatUser(u.Id,channelUrl);
    } catch (Exception e) {
      isError = true;
    }
    Test.stopTest();
     //assert exception
    System.assertEquals(true, isError, 'an exception should be thrown');
  }

  /**
   * @author     Sahil
   * @date  2021-03-30
   * @decription test end chat sendbird endpoint
   * @param   None
   * @return  None
   */
  @isTest
  static void testEndChat() {
    // Create the mock response based on a static resource
    StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    mock.setStaticResource('mockResponse_Empty');//empty response
    mock.setStatusCode(200);//success 
    mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
    // Associate the callout with a mock response
    Test.setMock(HttpCalloutMock.class, mock);
    String channelUrl = 'sendbird_group_channel_8642_5a9d6c930f464908d6aaacb9a606d69cac1f169b';
    Test.startTest();
    String responseFromAPIUsingVF = CDdSendbirdChatController.endChat(
      channelUrl
    );
    String responseFromAPIUsingAura = CDdSendbirdChatController.endChatAura(
      channelUrl
    );
    //Test with null channel url
    String negativeResponseVF = CDdSendbirdChatController.endChat(null);
    String negativeResponseAura = CDdSendbirdChatController.endChatAura(null);
    //test lightning
    Map<String,String> endChatMap = new Map<String,String>{
      'channelUrl' => channelUrl
    };
    Object responseLightning = CDdSendbirdChatController.processSendbirdActionCacheableAura('end_chat',endChatMap);
    Test.stopTest();
    //assert response
    System.assertEquals('', responseFromAPIUsingVF, 'callout should return a blank body');
    System.assertEquals('', responseFromAPIUsingAura, 'callout should return a blank body');
  }

  /**
   * @author     Sahil
   * @date  2021-03-30
   * @decription test get quick text 
   * @param   None
   * @return  None
   */
  @isTest
  static void testQuickText() {
    Test.startTest();
    List<QuickText> quickTextVF = CDdSendbirdChatController.getQuickText();
    //second time, record will be returned from cache
    List<QuickText> quickTextAura = CDdSendbirdChatController.getQuickTextAura();
    Test.stopTest();
    //assert
    System.assertEquals(1,quickTextVF.size(),'Visualforce: 1 quicktext record should be returned');
    System.assertEquals(1,quickTextAura.size(),'Aura: 1 quicktext record should be returned');
  }

  /**
   * @author     Sahil
   * @date  2021-03-30
   * @decription test get contact for lightning component
   * @param   None
   * @return  None
   */
  @isTest
  static void testGetContactAura() {
   List<Account> accountsToInsert = TDdAccountFactory.createAccounts('Test Account', 1);
   insert accountsToInsert;

   List<Contact> contactsToInsert = TDdAccountFactory.createContacts(1, accountsToInsert[0].Id);
   insert contactsToInsert;

   Test.startTest();
   CDdSendbirdChatController.getContactAura(contactsToInsert[0].Id);
   //negative test with null contact
   CDdSendbirdChatController.getContactAura(null);
    //test lightning
    Map<String,String> quickTextMap = new Map<String,String>{
      'contactId' => contactsToInsert[0].Id
    };
    Object responseLightning = CDdSendbirdChatController.processSendbirdActionCacheableAura('quick_text',quickTextMap);
   Test.stopTest();
   //assert
   List<Contact> contactFromDBList = [SELECT Id FROM Contact WHERE Id =:contactsToInsert];
   System.assertEquals(1, contactFromDBList.size(), '1 contact should be returned from database');
  }

  /**
   * @author     Sahil
   * @date  2021-05-05
   * @decription test should connect to chat remote action method
   * @param   None
   * @return  None
   */
  @isTest
  static void testShouldConnectToChat() {
    List<Case> casesToTest = TDdCaseFactory.createCaseRecords(
      1,
      CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER
    );
    casesToTest[0]
      .ChatKey__c = 'sendbird_group_channel_8642_5a9d6c930f464908d6aaacb9a606d69cac1f169b';
    casesToTest[0].Channel__c = CDdSupportConstants.CASE_CHANNEL_CHAT_SENDBIRD;
    casesToTest[0].Origin = CDdSupportConstants.CASE_ORIGIN_CHAT;
    insert casesToTest;
    Case c = casesToTest[0];
    Test.startTest();
    Boolean shouldChatconnectResPositive = CDdSendbirdChatController.shouldConnectToChat(c.Id, UserInfo.getUserId());
    Boolean shouldChatconnectResNegative = CDdSendbirdChatController.shouldConnectToChat(c.Id, c.OwnerId);
    //test lightning
    Map<String,String> shouldConnectMap = new Map<String,String>{
      'caseId' => c.Id,
      'agentUserId' => UserInfo.getUserId()
    };
    Object responseLightning = CDdSendbirdChatController.processSendbirdActionCacheableAura('should_connect',shouldConnectMap);
    Test.stopTest();
    //assert
    System.assertEquals(false, shouldChatconnectResNegative, 'Method should return false');
    System.assertEquals(true, shouldChatconnectResPositive, 'Method should return true');
  }

  /**
   * @author     Sahil
   * @date  2021-11-03
   * @decription test get chat queues from custom metadata
   * @param   None
   * @return  None
   */
  @isTest
  static void testGetChatQueues() {
    Test.startTest();
    String chatQueuesFromDB = CDdSendbirdChatController.getChatQueues();
    //test lightning
    Map<String,String> transferQMap = new Map<String,String>{};//no payload passed from client
    Object responseLightning = CDdSendbirdChatController.processSendbirdActionCacheableAura('transfer_queues',transferQMap);
    Test.stopTest();
    System.assertNotEquals(CDdCoreConstants.HTTP_NO_RESP, chatQueuesFromDB,
                         'No custom metadata records returned from database');
  }

  /**
   * @author     Sahil
   * @date  2021-11-03
   * @decription test transfer of case from client
   * @param   None
   * @return  None
   */
  @isTest
  static void testTransferCase() {
    List<Case> casesToTest = TDdCaseFactory.createCaseRecords(
      1,
      CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER
    );
    casesToTest[0]
      .ChatKey__c = 'sendbird_group_channel_8642_5a9d6c930f464908d6aaacb9a606d69cac1f169b';
    casesToTest[0].Channel__c = CDdSupportConstants.CASE_CHANNEL_CHAT_SENDBIRD;
    casesToTest[0].Origin = CDdSupportConstants.CASE_ORIGIN_CHAT;
    casesToTest[0].Issue__c = CDdSupportConstants.CASE_ISSUE_ACCT_SETTINGS;
    casesToTest[0].Issue_Type__c = CDdSupportConstants.CASE_ISSUE_ACCT_MGMT;
    Test.startTest();
    insert casesToTest;
    Case testCase = casesToTest[0];
    //get queues from database for setting new owner on case. 
    //this will mimic the remote action call the client makes
    List<Sendbird_Chat_Queue__mdt> chatQueuesFromDB = CDdSupportHelper.sbChatQueues;
    String newOwnerId;
    for (Sendbird_Chat_Queue__mdt sbCQVar : chatQueuesFromDB) {
      newOwnerId = chatQueuesFromDB[0].Queue_ID__c;
      if (String.isNotBlank(newOwnerId)) {
        //new owner selected by the client - break out
        break;
      }
    }
    //now transfer the case by calling remote action
    //if update is successful, case Id is returned
    String updatedCaseOwnerId = CDdSendbirdChatController.transferChat(testCase.Id, newOwnerId);
    //assert that the owner changed
    System.assertEquals(testCase.Id, updatedCaseOwnerId, 'Inserted test case Id should be returned');
    //test exceptions
    Boolean isError = false;
    try {
      List<Case> errorCases = TDdCaseFactory.createCaseRecords(
        1, CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER);
      insert errorCases;
      updatedCaseOwnerId = CDdSendbirdChatController.transferChat(errorCases[0].Id, newOwnerId);
    } catch (Exception e) {
      isError = true;
    }
     //test lightning
     Map<String,String> transferCaseMap = new Map<String,String>{
      'caseId' => testCase.Id,
      'newOwnerId' => newOwnerId
    };
    Object responseLightning = CDdSendbirdChatController.processSendbirdActionNonCacheableAura('transfer_chat',transferCaseMap);
    Test.stopTest();
    //assert error
    System.assertEquals(true, isError, 'An exception should be thrown');
  }
}