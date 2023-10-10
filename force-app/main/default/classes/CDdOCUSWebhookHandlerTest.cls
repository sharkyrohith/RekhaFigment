/*
*@Description: Test class to test CDdOCUSWebhookHandler class
@Author : Veera Maddukuri
@Date : 2021-11
*/
@isTest
private class CDdOCUSWebhookHandlerTest {

    public static final String photoshootRecordTypeId = CDdRecordTypeCase.photoshootProcessing();
    public static String responseBody = '{"data":{"type":"mission","id":"53f96fba-40e6-11ec-b9e5-0eb76324be16","attributes":{"reference_id":"53f96fba-40e6-11ec-b9e5-0eb76324be16","name":"test","current_status":"WAITING_MEDIA_TREATMENT","public_status":"DELIVERED","description":"null,gooogle.commmm","product_types":["PHOTO"],"short_id":94730378,"is_legacy":false,"approved_appointment":"2021-11-30T00:00:00+00:00","internal_reference":"5000r000006tGYTAA2","operator_density":null,"expires_in":33119,"selected_at":"2021-11-24T10:55:33+00:00","attributed_at":"2021-11-24T10:55:34+00:00","started_at":"2021-11-23T16:25:34+00:00","created_at":"2021-11-23T16:25:33+00:00","updated_at":"2021-11-24T11:10:35+00:00","assignment_id":"53f96fba-40e6-11ec-b9e5-0eb76324be16"},"relationships":{"archives":{"data":[{"type":"mission_media_file_archives","id":"953d3110-4d15-11ec-9210-7af2e1e241cd","attributes":{"type":"announcer_delivery","current_status":"DONE","built_at":"2021-11-24T10:59:23+00:00","url":"https://ocus-app-fs-testing-media.s3-accelerate.amazonaws.com/sandbox-customer/organizations/d3a64e90-9dfd-11eb-affe-8a094ca0282a/missions/53f96fba-40e6-11ec-b9e5-0eb76324be16/archive/953d3110-4d15-11ec-9210-7af2e1e241cd.zip?response-content-disposition=attachment%3Bfilename%3Dphotos_94730378_1637751563.zip&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEJz%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEaCWV1LXdlc3QtMyJHMEUCIQDYhhhe6OctmJjEDh%2F%2B4RPKdUW7aYj2teGrGn0knYRpgQIgB5CK1IOpeXrQgxp3sSlpjbIoEj5NZjhWHyVwZF8I8HQq9AMIZRADGgw3NTk5MjY2NzYxNzAiDMeYXsD8wTb8%2Fkf7wCrRA15dVqVKnzg7nwOVidhIB5y2cwKUAxje0jD%2FpFOP%2FCWXRyFCS7FdwdNCm98WWqBXgTdJSv7nQx3sVQHTzLezzYivwe6bc3UYTgUiZNzgcIsrAgOkOnQ5Z50RMR%2BgS7kZVigh4iGd3t8C0IwRlX7l2NVT%2BJTeyubnBL9wqnAT6XlVqGkik%2B%2BSozjq3nMWTpKojKw6Bqcys6zxEm1ia3LyZ8xg7Qe0Qjogl4YG%2F3qfbMa%2FH1a1sqJdB1SuiPGQYgzinj1zeq69mStgIiUf0jawMgbchPuga2hoPCWUQ8ZOxcRgTYEif8danj4zG%2B0SO4C%2BHRCSb%2FHlqEzJUenzSEsfymlBnEjSJdcMm8Yg8QemB4oOV3k6TN0iL7Cz%2FN%2BjbCG9xvbCiR5prk5VWEq6MuLv2%2FShsA%2FZFhmT77XCIsGSk4pFhtCvyTDVWcYQN7LO53Ns820oWJohyZf%2Bg6WBNhh4Mov6zcj8OBcXkvccxmAIzTr%2B0nmB4K689%2FhMPbbV%2FdxxsppXwClSCbyA6QJt3bzr8CtgC5NFClRZXNyNHsjZm4M144Mg%2FD%2F53%2BHntIBN%2F8z4K7SYtoKb7o0m9tGYVtUIBr63PZHe21BbA%2BBdm29WJpw49zD2sfqMBjqlAS9PQRULRnZDa43Ru8e256vntREwgMuknEuVOoNdCbPqIWZoqAOPeyBLhMIFw1Od3XfN3t6%2BrH318wtjkQU5lwo0pEvMSywmCEYJO78VwwuOIR6ndMxZPPyiWq%2BLWkoizXqGEycoV3wuZTzT1s0qhBvYN9m9tBD7Uxze%2B2pxPoGPl09Bfg8vh0JR61nRgQAolXv0vBc18836h4%2FMcwQPyB6sNH5OBw%3D%3D&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIA3B3ZI3LFCDXHK4NE%2F20211124%2Feu-west-3%2Fs3%2Faws4_request&X-Amz-Date=20211124T202233Z&X-Amz-SignedHeaders=host&X-Amz-Expires=604799&X-Amz-Signature=c6a3cdbd70ebefd10202aa99fe69c81ad26aa1c4a59562631ffca9e9c883eb9b"}},{"type":"mission_media_file_archives","id":"952822d4-4d15-11ec-99b1-7af2e1e241cd","attributes":{"type":"customer_delivery","current_status":"DONE","built_at":"2021-11-24T10:59:23+00:00","url":"https://ocus-app-fs-testing-media.s3-accelerate.amazonaws.com/sandbox-customer/organizations/d3a64e90-9dfd-11eb-affe-8a094ca0282a/missions/53f96fba-40e6-11ec-b9e5-0eb76324be16/archive/952822d4-4d15-11ec-99b1-7af2e1e241cd.zip?response-content-disposition=attachment%3Bfilename%3Dphotos_94730378_1637751563.zip&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEJz%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEaCWV1LXdlc3QtMyJHMEUCIQDYhhhe6OctmJjEDh%2F%2B4RPKdUW7aYj2teGrGn0knYRpgQIgB5CK1IOpeXrQgxp3sSlpjbIoEj5NZjhWHyVwZF8I8HQq9AMIZRADGgw3NTk5MjY2NzYxNzAiDMeYXsD8wTb8%2Fkf7wCrRA15dVqVKnzg7nwOVidhIB5y2cwKUAxje0jD%2FpFOP%2FCWXRyFCS7FdwdNCm98WWqBXgTdJSv7nQx3sVQHTzLezzYivwe6bc3UYTgUiZNzgcIsrAgOkOnQ5Z50RMR%2BgS7kZVigh4iGd3t8C0IwRlX7l2NVT%2BJTeyubnBL9wqnAT6XlVqGkik%2B%2BSozjq3nMWTpKojKw6Bqcys6zxEm1ia3LyZ8xg7Qe0Qjogl4YG%2F3qfbMa%2FH1a1sqJdB1SuiPGQYgzinj1zeq69mStgIiUf0jawMgbchPuga2hoPCWUQ8ZOxcRgTYEif8danj4zG%2B0SO4C%2BHRCSb%2FHlqEzJUenzSEsfymlBnEjSJdcMm8Yg8QemB4oOV3k6TN0iL7Cz%2FN%2BjbCG9xvbCiR5prk5VWEq6MuLv2%2FShsA%2FZFhmT77XCIsGSk4pFhtCvyTDVWcYQN7LO53Ns820oWJohyZf%2Bg6WBNhh4Mov6zcj8OBcXkvccxmAIzTr%2B0nmB4K689%2FhMPbbV%2FdxxsppXwClSCbyA6QJt3bzr8CtgC5NFClRZXNyNHsjZm4M144Mg%2FD%2F53%2BHntIBN%2F8z4K7SYtoKb7o0m9tGYVtUIBr63PZHe21BbA%2BBdm29WJpw49zD2sfqMBjqlAS9PQRULRnZDa43Ru8e256vntREwgMuknEuVOoNdCbPqIWZoqAOPeyBLhMIFw1Od3XfN3t6%2BrH318wtjkQU5lwo0pEvMSywmCEYJO78VwwuOIR6ndMxZPPyiWq%2BLWkoizXqGEycoV3wuZTzT1s0qhBvYN9m9tBD7Uxze%2B2pxPoGPl09Bfg8vh0JR61nRgQAolXv0vBc18836h4%2FMcwQPyB6sNH5OBw%3D%3D&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIA3B3ZI3LFCDXHK4NE%2F20211124%2Feu-west-3%2Fs3%2Faws4_request&X-Amz-Date=20211124T202233Z&X-Amz-SignedHeaders=host&X-Amz-Expires=604800&X-Amz-Signature=3a0e7215fb832ce3c4be38f9a357aeb0cdcc1ce32c08767973704284b5c69b97"}}]},"organization":{"type":"organization","id":"d3a64e90-9dfd-11eb-affe-8a094ca0282a","attributes":{"name":"DoorDash - Japan","short_id":49062109,"country_code":"JP","vertical":"FOOD","url":null,"description":null,"created_at":"2021-04-15T15:18:26+00:00","updated_at":"2021-10-22T01:37:35+00:00","parent_organization_id":null,"missions_visibility":false,"ready":false,"next_available_appointment":"2021-11-29T20:22:33+00:00"},"relationships":{"owner":{"type":"member","id":"2af9bb7c-d83d-11eb-9ef7-d251dd0c4c88","attributes":{"firstname":"Arun","lastname":"manjappan","email":"amanjappan@doordash.com","email_verified_at":"2021-06-28T18:17:59+00:00","email_unreachable":false,"hubspot_id":null,"locale":"en","position":null,"rate":null,"role":"owner"},"relationships":{"roles":{"data":[{"type":"role","id":3,"attributes":{"name":"customer","locked":true,"created_at":"2020-09-25T12:53:58+00:00","updated_at":"2020-09-25T12:53:58+00:00"},"relationships":[]}]}}},"roles":{"data":[{"type":"role","id":3,"attributes":{"name":"customer","locked":true,"created_at":"2020-09-25T12:53:58+00:00","updated_at":"2020-09-25T12:53:58+00:00"},"relationships":[]}]},"role":{"type":"role","id":3,"attributes":{"name":"customer","locked":true,"created_at":"2020-09-25T12:53:58+00:00","updated_at":"2020-09-25T12:53:58+00:00"},"relationships":[]}}}}}}';
    public static String webhookResponse = '{"type":"event","id":"mission.status.updated","attributes":{"mission_id":"53f96fba-40e6-11ec-b9e5-0eb76324be16","mission_reference_id"  :"53f96fba-40e6-11ec-b9e5-0eb76324be16","organization_id":"d3a64e90-9dfd-11eb-affe-8a094ca0282a","public_status":"DELIVERED"}}';
    public static String webhookBlockedResponse = '{"type":"event","id":"mission.blocker.set","attributes":{"mission_id":"53f96fba-40e6-11ec-b9e5-0eb76324be16","mission_reference_id"  :"53f96fba-40e6-11ec-b9e5-0eb76324be16","organization_id":"d3a64e90-9dfd-11eb-affe-8a094ca0282a"}}';
    public static string missionId = '53f96fba-40e6-11ec-b9e5-0eb76324be16';
    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';

    static {
        TEST_ROLE_ID = [SELECT Id FROM UserRole WHERE DeveloperName = 'COO'].Id;
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

    @TestSetup
    static void testSetup() {
        System.runAs(getTestRunUser()){
            CDdContactTriggerHelper.insertCampaign();
            List<Account> accountsToInsert = new List<Account>();

            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
            validation.Bypass_Opportunity_Validations__c = true;
            validation.Bypass_Case_Validations__c  = true;
            insert validation;

            List<Account> acclist = CDdTestDataFactory.createSObjectList('Account', 1, false);
            for (Integer i = 0; i < acclist.size(); i++) {
                acclist[i].Name = 'Test Acc';
                acclist[i].BillingStreet = 'Rotebühlstraße 121';
                acclist[i].BillingCity = 'Stuttgart';
                acclist[i].BillingPostalCode = '70178';
                acclist[i].BillingCountryCode = 'DE';
                acclist[i].BillingCountry = 'Germany';
                acclist[i].Legal_Business_Name__c = 'German';
                acclist[i].Market_Area__c = 'Northern California - East Bay';
                acclist[i].Business_ID__c = 123456;
                acclist[i].Language__c = 'German';
                acclist[i].RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Marketplace').getRecordTypeId();
                accountsToInsert.add(acclist[i]);
            }
            insert accountsToInsert;

            Contact con1 = (Contact)CDdTestDataFactory.createSObject('Contact', new Map<String,Object>{
                'AccountId' => accountsToInsert[0].Id
                    }, false);
            insert con1;

            Opportunity opp2 = TDdOpportunityFactory.createOpportunity('CloseWonOpp', con1.AccountId, con1.id, 'Closed Won');
            opp2.Tablet_Received_Date__c = null;

            insert opp2;

            List<Case> cslist1 = CDdTestDataFactory.createSObjectList('Case', 1, false);
            for(Integer i = 0; i < 1; i++){
                cslist1[i].Store_ID__c = '' +i;
                cslist1[i].BusinessHours =null;
                cslist1[i].Subject = 'setAccountIdUpdateTest'+i;
                cslist1[i].RecordTypeId = photoshootRecordTypeId;
                cslist1[i].Photo_Provider__c = 'OCUS';
                cslist1[i].Photo_Review_Notes__c = 'OCUS';
                cslist1[i].Language__c = 'German';
                cslist1[i].Menu_Preview_Links__c = 'Menu preview links';
                cslist1[i].AccountId = accountsToInsert[0].Id;
            }
            insert cslist1;
        }
    }

    @isTest
    static void testHandleNotification() {
        String secretKeyValue = 'SalesforcewebhookSecretKey';
        String algorithmName = 'HmacSHA256';

        Case cs = [SELECT Id FROM Case WHERE RecordTypeId = :photoshootRecordTypeId LIMIT 1];
        cs.Kodakit_Job_Id__c = missionId;
        update cs;

        CDdRestJSONObj.OCUSMissionResponse response = (CDdRestJSONObj.OCUSMissionResponse)JSON.deserialize(responseBody, CDdRestJSONObj.OCUSMissionResponse.class);
        Test.startTest();
        CDdMockHttpResponse mock = new CDdMockHttpResponse(JSON.serialize(response));
        Test.setMock(HttpCalloutMock.class, mock);

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        Blob hmacData = Crypto.generateMac(algorithmName, Blob.valueof(webhookResponse), Blob.valueOf(secretKeyValue));
        String generatedHmacData = EncodingUtil.convertToHex(hmacData);

        req.requestURI = '/services/apexrest/api/OCUSWebhook';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(webhookResponse);
        req.addHeader('Signature',generatedHmacData);
        RestContext.request = req;
        RestContext.response= res;

        CDdOCUSWebhookHandler.handleNotification();

        cs = [SELECT Id, Kodakit_Job_Id__c,Kodakit_Event__c,Kodakit_Pictures_URL__c FROM Case WHERE Id = :cs.Id LIMIT 1];
        System.assertEquals('DELIVERED', cs.Kodakit_Event__c);
        Test.stopTest();
    }

    @isTest
    static void testHandleNotificationUnAuthorized() {
        String secretKeyValue = 'SalesforcewebhookSecretKey';
        String algorithmName = 'HmacSHA256';

        Case cs = [SELECT Id FROM Case WHERE RecordTypeId = :photoshootRecordTypeId LIMIT 1];
        CDdRestJSONObj.OCUSMissionResponse response = (CDdRestJSONObj.OCUSMissionResponse)JSON.deserialize(responseBody, CDdRestJSONObj.OCUSMissionResponse.class);
        response.data.attributes.internal_reference = cs.Id;
        Test.startTest();
        CDdMockHttpResponse mock = new CDdMockHttpResponse(JSON.serialize(response));
        Test.setMock(HttpCalloutMock.class, mock);

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        Blob hmacData = Crypto.generateMac(algorithmName, Blob.valueof(webhookResponse), Blob.valueOf('error'));
        String generatedHmacData = EncodingUtil.convertToHex(hmacData);

        req.requestURI = '/services/apexrest/api/OCUSWebhook';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(webhookResponse);
        req.addHeader('Signature',generatedHmacData);
        RestContext.request = req;
        RestContext.response= res;

        CDdOCUSWebhookHandler.handleNotification();

        cs = [SELECT Id, Kodakit_Job_Id__c,Kodakit_Event__c,Kodakit_Pictures_URL__c FROM Case WHERE Id = :cs.Id LIMIT 1];
        System.assertNotEquals('DELIVERED', cs.Kodakit_Event__c);
        Test.stopTest();
    }

    @isTest
    static void testHandleNotificationCompleted() {
        String secretKeyValue = 'SalesforcewebhookSecretKey';
        String algorithmName = 'HmacSHA256';

        Case cs = [SELECT Id FROM Case WHERE RecordTypeId = :photoshootRecordTypeId LIMIT 1];
        cs.Kodakit_Job_Id__c = missionId;
        update cs;
        CDdRestJSONObj.OCUSWebhookResponse webhookResp = (CDdRestJSONObj.OCUSWebhookResponse)JSON.deserialize(webhookResponse, CDdRestJSONObj.OCUSWebhookResponse.class);
        webhookResp.attributes.public_status = 'COMPLETED';
        CDdRestJSONObj.OCUSMissionResponse response = (CDdRestJSONObj.OCUSMissionResponse)JSON.deserialize(responseBody, CDdRestJSONObj.OCUSMissionResponse.class);
        Test.startTest();
        CDdMockHttpResponse mock = new CDdMockHttpResponse(JSON.serialize(response));
        Test.setMock(HttpCalloutMock.class, mock);
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        Blob hmacData = Crypto.generateMac(algorithmName, Blob.valueof(JSON.serialize(webhookResp)), Blob.valueOf(secretKeyValue));
        String generatedHmacData = EncodingUtil.convertToHex(hmacData);

        req.requestURI = '/services/apexrest/api/OCUSWebhook';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(JSON.serialize(webhookResp));
        req.addHeader('Signature',generatedHmacData);
        RestContext.request = req;
        RestContext.response= res;

        CDdOCUSWebhookHandler.handleNotification();

        cs = [SELECT Id, Kodakit_Job_Id__c,Kodakit_Event__c,Kodakit_Pictures_URL__c FROM Case WHERE Id = :cs.Id LIMIT 1];
        System.assertEquals('COMPLETED', cs.Kodakit_Event__c);
        System.assertNotEquals(null, cs.Kodakit_Pictures_URL__c);
        Test.stopTest();
    }

    @isTest
    static void testBlockedNotification() {
        String secretKeyValue = 'SalesforcewebhookSecretKey';
        String algorithmName = 'HmacSHA256';

        Case cs = [SELECT Id FROM Case WHERE RecordTypeId = :photoshootRecordTypeId LIMIT 1];
        cs.Kodakit_Job_Id__c = missionId;
        update cs;

        CDdRestJSONObj.OCUSMissionResponse response = (CDdRestJSONObj.OCUSMissionResponse)JSON.deserialize(responseBody, CDdRestJSONObj.OCUSMissionResponse.class);
        Test.startTest();
        CDdMockHttpResponse mock = new CDdMockHttpResponse(JSON.serialize(response));
        Test.setMock(HttpCalloutMock.class, mock);

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        Blob hmacData = Crypto.generateMac(algorithmName, Blob.valueof(webhookBlockedResponse), Blob.valueOf(secretKeyValue));
        String generatedHmacData = EncodingUtil.convertToHex(hmacData);

        req.requestURI = '/services/apexrest/api/OCUSWebhook';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(webhookBlockedResponse);
        req.addHeader('Signature',generatedHmacData);
        RestContext.request = req;
        RestContext.response= res;

        CDdOCUSWebhookHandler.handleNotification();
        Test.stopTest();

        cs = [SELECT Id, Kodakit_Job_Id__c,Kodakit_Event__c,Kodakit_Message__c FROM Case WHERE Id = :cs.Id LIMIT 1];
        System.assertEquals( CDdOCUSAPIConstants.BLOCKED_STATUS, cs.Kodakit_Event__c);
    }
}