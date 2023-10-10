@isTest
private class PSBulkSendControllerTest {

    @TestSetup
    static void setup(){
        // Create and insert Account
        Account acct = VTestUtil.createAccount('Test Account One', true, false);
        insert acct;

        // Create and insert Signer One (Decision Maker)
        Contact dm = VTestUtil.createContact('TestFirstName', 'TestLastName', acct);
        dm.Email = 'tim@pactsafe.com';
        insert dm;

        // Lists to hold parent and child opps for insertion
        List<Opportunity> opps = new List<Opportunity>();
        List<Opportunity> parentOpps = new List<Opportunity>();

        // Create parent opportunity
        Opportunity parentOpp = TDdOpportunityFactory.createOpportunity('Parent Opty', acct.Id, dm.Id, 'Ready for Signature');
        parentOpps.add(parentOpp);
        insert parentOpps;

        List<Opportunity> parentOppsIds = [SELECT Id, Name FROM Opportunity WHERE Name = 'Parent Opty'];

         // Create first opportunity
        Opportunity optyOne = TDdOpportunityFactory.createOpportunity('Opty One', acct.Id, dm.Id, 'Ready for Signature');
        optyOne.Parent_Opportunity__c = parentOppsIds[0].Id;

        // Create second opportunity
        Opportunity optyTwo = TDdOpportunityFactory.createOpportunity('Opty Two', acct.Id, dm.Id, 'Ready for Signature');
        optyOne.Parent_Opportunity__c = parentOppsIds[0].Id;

        opps.add(optyOne);
        opps.add(optyTwo);

        insert opps;
    }

    @istest static void testGetOpps() {
        List<Opportunity> testInsertedOpps = [SELECT Id FROM Opportunity WHERE id != null];
        System.assertEquals(3, testInsertedOpps.size(), 'Unexpected number of inserted test opportunities.');

        String oppIds = testInsertedOpps[0].Id + ',' + testInsertedOpps[1].Id + ',' + testInsertedOpps[2].Id;
        List<Opportunity> opps = PSBulkSendController.getOpportunitiesData(oppIds);
        System.assertEquals(3, opps.size(), 'Unexpected number of opportunities returned.');
    }

    @istest static void testGetExpirationDate() {
        String testExpiresDate = PSBulkSendController.getExpirationGmtTime();
        System.assertNotEquals(null, testExpiresDate, 'Unexpected return of expiration time.');
        System.assertNotEquals('', testExpiresDate, 'Unexpected return of empty date string.');
    }

    @istest static void testPsResponse() {
        PSBulkSendController.PSAPIResponse apiResponse = new PSBulkSendController.PSAPIResponse();
        apiResponse.message = 'Success';
        apiResponse.success = true;
        System.assertEquals(true, apiResponse.success);
    }

    @istest static void testGetCustomData() {
        PSBulkSendController.PSCustomData customDataObjects = PSBulkSendController.getCustomDataObjects();
        System.assertNotEquals(null, customDataObjects, 'Unable to get custom data objects');
    }

    @istest static void testGetAccessToken() {
        String accessToken = PSBulkSendController.getPsAccessToken();
        System.assertNotEquals(null, accessToken, 'Unable to get access token.');
    }

    @istest static void testGetEndpoint() {
        String settingsEndpoint = PSBulkSendController.getPsAPIEndpoint();
        System.assertNotEquals(null, settingsEndpoint, 'Unable to get PactSafe endpoint');
    }

    @istest static void testPayloadGeneration() {
        String contractId = '30';
        Boolean contractExpires = false;
        Boolean requestAutomatedReminders = false;

        List<Opportunity> opps = [SELECT Id, Name, StageName, Account.Name, Decision_Maker__r.Email, Decision_Maker__r.FirstName, Decision_Maker__r.LastName, Decision_Maker__r.Title, Decision_Maker__r.MobilePhone, Owner.Email, Owner.CompanyName, Owner.FirstName, Owner.LastName, Owner.Title, Owner.DID_Phone_Number__c, Parent_Opportunity__r.Name
                                    FROM Opportunity WHERE Id != null LIMIT 2];

        String oppIds = opps[0].Id + ',' + opps[1].Id;

        String jsonPayload = PSBulkSendController.pactSafeJSONPayload(oppIds, contractId, contractExpires, requestAutomatedReminders);

        System.assertNotEquals(null, jsonPayload, 'Unexpectedly received a null JSON payload.');
    }

    @istest static void testProcessingRequest() {
        List<Opportunity> opps = [SELECT Id, Name, StageName, Account.Name, Decision_Maker__r.Email, Decision_Maker__r.FirstName, Decision_Maker__r.LastName, Decision_Maker__r.Title, Decision_Maker__r.MobilePhone, Owner.Email, Owner.CompanyName, Owner.FirstName, Owner.LastName, Owner.Title, Owner.DID_Phone_Number__c, Parent_Opportunity__r.Name
                                    FROM Opportunity WHERE Id != null LIMIT 2];

        String contractId = '30';
        Boolean contractExpires = false;
        Boolean requestAutomatedReminders = false;
        String oppIds = opps[0].Id + ',' + opps[1].Id;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PSBulkSendControllerTestMockCallout());

        String processingRequestOutput = PSBulkSendController.processRequest(oppIds, contractId, contractExpires, requestAutomatedReminders);
        System.assertNotEquals(null, processingRequestOutput, 'Unexpected response from test HTTP request.');
        Test.stopTest();
    }

}