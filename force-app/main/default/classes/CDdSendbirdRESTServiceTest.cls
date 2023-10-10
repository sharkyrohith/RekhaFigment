/**
 * CDdSendbirdRESTServiceTest
 *
 * @author     Sahil
 * @date  2022-07-19
 * @decription Test class for CDdSendbirdRESTService
 */
@isTest
private class CDdSendbirdRESTServiceTest {
    /*****************************************************************************************************************************
    *
    * Private Methods
    *
    *****************************************************************************************************************************/
    /**
    * @author     Sahil
    * @date  2022-07-19
    * @decription test setup
    * @param   None
    * @return  None
    */
    @TestSetup
    static void makeData() {
        //insert a test case
        List<Case> testCaseList = TDdCaseFactory.createCaseRecords(1, CDdSupportConstants.RECORDTYPE_NAME_SUPPORT);
        testCaseList[0].ChatKey__c = 'sendbird_group_channel_8642_5a9d6c930f464908d6aaacb9a606d69cac1f169b';
        testCaseList[0].Channel__c = CDdSupportConstants.CASE_CHANNEL_CHAT_SENDBIRD;
        testCaseList[0].Origin = CDdSupportConstants.CASE_ORIGIN_CHAT;
        testCaseList[0].Issue__c = CDdSupportConstants.CASE_ISSUE_ACCT_SETTINGS;
        testCaseList[0].Issue_Type__c = CDdSupportConstants.CASE_ISSUE_ACCT_MGMT;
        insert testCaseList;
        //insert a test queue to transfer the case to
        System.runAs(new User(Id=UserInfo.getUserId())) {
            //Create Parent Group
            List<Group> lstGrp = new List<Group>();
            Group testGroup1 = new Group(Name='TestQueue', Type='Queue');
            lstGrp.add(testGroup1);
            insert lstGrp;

            //Associating queue with group AND to the Case object
            List<QueuesObject> lstQueueObj = new List<QueuesObject>();
            lstQueueObj.add(new QueueSObject(QueueID = lstGrp[0].id, SObjectType = 'Case'));
            insert lstQueueObj;
        }

        //insert quick text
        QuickText qt = new QuickText(Name = 'Test',
                                    Channel = CDdSupportConstants.LIVEAGENT_CHANNEL,
                                    Message = 'test message');
        insert qt;

        //insert queue overflow config
        Queue_Overflow_Configuration__c qOvFConfig = new Queue_Overflow_Configuration__c(
                                                            Average_Wait_Time__c = 123,
                                                            Queue_Id__c = '00G2L0000020h8TUAQ');
        insert qOvFConfig;
    }

    /**
    * @author     Sahil
    * @date  2022-07-19
    * @decription test getting quick text via api
    * @param   None
    * @return  None
    */
    @isTest
    static void testGetQuickText() {
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/chatservice';
        req.params.put('action', 'quick_text');
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        CDdSendbirdRESTService.ResponseWrapper response = CDdSendbirdRESTService.doGet();
        //assert positive scenario
        System.assertEquals(false, String.isBlank(response.items), 'quick text should be returned in the response');

        //remove parameter and assert negative test
        Boolean isError = false;
        try {
            req.params.put('action', null);
            CDdSendbirdRESTService.ResponseWrapper responseNegative = CDdSendbirdRESTService.doGet();
        } catch (Exception e) {
            isError = true;
        }
        Test.stopTest();
        //assert
        System.assertEquals(true, isError, 'exception should be returned in the response');
    }

    /**
    * @author     Sahil
    * @date  2022-07-19
    * @decription test getting transfer queues via api
    * @param   None
    * @return  None
    */
    @isTest
    static void testGetTransferQueues() {
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/chatservice';
        req.params.put('action', 'transfer_queues');
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        CDdSendbirdRESTService.ResponseWrapper response = CDdSendbirdRESTService.doGet();
        Test.stopTest();
        //assert
        System.assertEquals(false, String.isBlank(response.items), 'queues for transfer should be returned in the response');
    }

    /**
    * @author     Sahil
    * @date  2022-07-19
    * @decription test transferring a sendbird chat via api
    * @param   None
    * @return  None
    */
    @isTest
    static void testTransferChat() {
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/chatservice';
        req.params.put('action', 'transfer_chat');
        req.params.put('caseId', [SELECT Id FROM Case LIMIT 1].Id);
        req.params.put('newOwnerId', [SELECT Id FROM Group WHERE Name = 'TestQueue' LIMIT 1].Id);
        req.httpMethod = 'PATCH';
        req.requestBody = Blob.valueOf('{}');
        RestContext.request = req;
        RestContext.response = res;
        CDdSendbirdRESTService.ResponseWrapper response = CDdSendbirdRESTService.handlePatch();
        //assert
        System.assertEquals(false, String.isBlank(response.items), 'items with a case Id should be returned in the response');

         //remove parameter and assert negative test
         Boolean isError = false;
         try {
            req.params.put('action', 'transfer_chat');
            req.params.put('caseId', '123');
            req.params.put('newOwnerId', '123');
            req.requestBody = null;
            CDdSendbirdRESTService.ResponseWrapper responseNegative = CDdSendbirdRESTService.handlePatch();
         } catch (Exception e) {
             isError = true;
         }
         Test.stopTest();
         //assert
         System.assertEquals(true, isError, 'exception should be returned in the response');
    }

    /**
    * @author     Sahil
    * @date  2022-11-09
    * @decription test create case with wait time
    * @param   None
    * @return  None
    */
    @isTest
    static void testCreateCaseWaitTime() {
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/chatservice';
        req.params.put('action', 'create_case');
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"RecordTypeId":"0121a0000006QogAAE","Origin":"Chat","Channel__c":"DoorDash App - Sendbird","Customer_Type__c":"Consumer","OwnerId":"00G2L0000020h8TUAQ"}');
        RestContext.request = req;
        RestContext.response = res;
        CDdSendbirdRESTService.ResponseWrapper response = CDdSendbirdRESTService.doPost();
        Test.stopTest();
        //assert that the API returned a response
        System.assertEquals(false, String.isBlank(response.items), 'no response from API');
    }

    /**
    * @author     Sahil
    * @date  2022-11-09
    * @decription test create case with wait time (negative test)
    * @param   None
    * @return  None
    */
    @isTest
    static void testCreateCaseWaitTimeNegative() {
        Boolean isError = false;
        Test.startTest();
        try {
            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();
            req.requestURI = '/services/apexrest/chatservice';
            req.params.put('action', 'create_case');
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueOf('{"RecordTypeId":"0121a0000006QogAAE","Origin":"Chat","Channel__c":"DoorDash App - Sendbird","Customer_Type__c":"Consumer","OwnerId":"00G2L00h8TUAQ"}');
            RestContext.request = req;
            RestContext.response = res;
            CDdSendbirdRESTService.ResponseWrapper response = CDdSendbirdRESTService.doPost();
        } catch (Exception e) {
            isError = true;
        }
        Test.stopTest();
        //assert that the API threw an error
        System.assertEquals(true, isError, 'case creation via API should throw an error');
    }
}