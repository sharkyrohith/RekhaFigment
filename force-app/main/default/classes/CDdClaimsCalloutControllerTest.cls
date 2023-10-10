/**
 * @author  Mahesh Chouhan
 * @date    July 2023
 * @description Test class for CDdClaimsCalloutController
 */

@isTest
public class CDdClaimsCalloutControllerTest {
    public static final String NAMED_CREDENTAIL_LIBERTYMUTUAL = 'LibertyMutualAuth';
    public static final String ENDPOINT_FNOL_AU = '/fnol/au';
    public static final String ENDPOINT_CLAIM_DOC = '/claims/docs';
    public static final String ENDPOINT_AWS = 's3.amazonaws.com';
    public static final String RESPONSE_ACCESS_TOKEN = '{"access_token": "testToken"}';
    public static final String RESPONSE_CLAIM_NUMBER = '{"claimNumber":"111111111"}';
    public static final String RESPONSE_DOCUMENTS = '{"documentURLs":[{"name":"testfile","url":"https://s3.amazonaws.com/'
        + 'ci-fnol-api-docs-test-547584663312-us-east-1/AUTOB/111111111/Customer/testfile/f5882876-da3e-4dda-b17d-e09a10bb897c.doc?'
        + 'X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Date=20230710T153809Z&X-Amz-SignedHeaders=host&X-Amz-Expires=1800&X-Amz-Credential'
        + '=AKIAX67UW34IFGMJUZWW%2F20230710%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Signature=a9cfe7ce087bf22581757668cd9a2ad301abded9bbbe8762a119a335296dec81"}], "error":null}';

    @TestSetup
    static void makeData(){
        List<Account> acct = TDdAccountFactory.createAccounts('Test Dahser', 1, 'Consumer or Dasher');
        acct[0].PersonEmail = 'test.dasher@test.com';
        insert acct;

        List<Case> cases = TDdCaseFactory.createCaseRecords(1, 'Support');
        cases[0].AccountId = acct[0].Id;
        insert cases;

        List<Claim__c> claims = new List<Claim__c>();

        for(Integer index = 0; index < 2; index++){
            Claim__c claimRecord = new Claim__c();
            claimRecord.Facts_of_Loss__c = index == 0 ? 'Claim With Documents' : 'Claim Without Documents';
            claimRecord.Case__c = cases[0].Id;
            claimRecord.Claim_Type__c = 'Auto';
            claimRecord.Reporting_Party_Name__c = acct[0].Id;
            claimRecord.Date_of_Loss__c = DateTime.now();
            claimRecord.Loss_Location_Street__c = '116 New Montgomery St,';
            claimRecord.Loss_Location_City__c = 'San Francisco ';
            claimRecord.Loss_Location_State_Province__c = 'US-CA';
            claimRecord.Loss_Location_Country__c = 'USA';
            claimRecord.Loss_Location_Zip_Postal_Code__c = '94107';
            claimRecord.Dasher_FirstName__c = 'Test';
            claimRecord.Dasher_LastName__c = 'Dasher';
            claimRecord.Dasher_Email__c = 'test.dasher@test.com';
            claimRecord.Dasher_City__c = 'San Francisco';
            claimRecord.Dasher_State_Province__c = 'US-CA';
            claimRecord.Dasher_Country__c = 'USA';
            claimRecord.Delivery_UUID__c = 'testDeliveryUuid';
            claimRecord.Drive_Partner__c = 'Test Dasher';
            claimRecord.Dasher_ID__c = 1234567;
            claims.add(claimRecord);
        }
        insert claims;

        Attachment attachment = new Attachment();
        attachment.Body = Blob.valueOf('Test Body');
        attachment.Name = String.valueOf('testfile.txt');
        attachment.ParentId = claims[0].Id;
        insert attachment;
        
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Document';
        cv.PathOnClient = 'TestDocument.pdf';
        cv.VersionData = Blob.valueOf('Test Content');
        cv.IsMajorVersion = true;
        insert cv;

        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;

        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = claims[0].Id;
        cdl.ContentDocumentId = conDocId;
        cdl.shareType = 'V';
        Insert cdl;
    }

    public class ClaimsCalloutMock implements HttpCalloutMock{
        public HttpResponse respond(HTTPRequest req){
            HttpResponse res = new HttpResponse();
            res.setStatus('success');

            if (req.getEndpoint().contains(NAMED_CREDENTAIL_LIBERTYMUTUAL)) {
                res.setStatusCode(200);
                res.setBody(RESPONSE_ACCESS_TOKEN);
            } else if (req.getEndpoint().endsWith(ENDPOINT_FNOL_AU)) {
                res.setStatusCode(201);
                res.setBody(RESPONSE_CLAIM_NUMBER);
            } else if (req.getEndpoint().endsWith(ENDPOINT_CLAIM_DOC)) {
                res.setStatusCode(201);
                res.setBody(RESPONSE_DOCUMENTS);
            } else if (req.getEndpoint().contains(ENDPOINT_AWS)) {
				res.setStatusCode(200);
            }

            return res;
        }
    }

    /**
     * @description - Test Claim Submission API
     */
    @isTest
    static void testMakeClaimAPICallout(){
        List<Claim__c> claims = [SELECT Id FROM Claim__c];

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ClaimsCalloutMock());

        CDdClaimInformation.ClaimResponse claimResponse = CDdClaimsCalloutController.makeClaimAPICallout(claims[0].Id);
        CDdClaimInformation.ClaimResponse secondClaimResponse = CDdClaimsCalloutController.makeClaimAPICallout(claims[0].Id);
        Test.stopTest();

        Claim__c expectedClaim = [SELECT Id, Claim_Number__c, API_Status_Code__c, API_Status__c, First_Notice_of_Loss_Date__c, Response_Payload__c
                                  FROM Claim__c
                                  WHERE Id = :claims[0].Id];
        System.assertEquals('111111111', expectedClaim.Claim_Number__c, 'Claim Number on claim is not same as expected.');
        System.assertEquals(CDdSupportConstants.SUCCESS_LABEL, claimResponse.status, 'Claim Submission status should be Success.');
        System.assertEquals(Date.today(), expectedClaim.First_Notice_of_Loss_Date__c, 'First Date of Notice on Claim is not same as expected.');
        System.assertEquals('201', expectedClaim.API_Status_Code__c, 'API Status Code on Claim is not same as expected.');
        System.assertEquals('success', expectedClaim.API_Status__c, 'API Status on Claim is not same as expected.');
        System.assertEquals(RESPONSE_CLAIM_NUMBER, expectedClaim.Response_Payload__c, 'Response Payload on Claim is not same as expected.');
        System.assertEquals(secondClaimResponse.message, CDdClaimsCalloutController.CLAIM_ALREADY_SUBMITTED_MESG, 'Claim Already submitted message is not same as expected.');
    }

    /**
     * @description - Test Document Submission API
     */
    @isTest
    static void testMakeClaimDocumentAPICallout(){
        List<Claim__c> claims = [SELECT Id, Facts_of_Loss__c, Case__c
                                 FROM Claim__c];
        Id failureClaimId;
        Id successClaimId;
        for(Claim__c claim : claims){
            if(claim.Facts_of_Loss__c == 'Claim With Documents'){
                successClaimId = claim.Id;
            }
            else if(claim.Facts_of_Loss__c == 'Claim Without Documents'){
                failureClaimId = claim.Id;
            }
        }

        Test.setMock(HttpCalloutMock.class, new ClaimsCalloutMock());
        CDdClaimsCalloutController.makeClaimAPICallout(claims[0].Id);

        Test.startTest();
        CDdClaimInformation.ClaimResponse failureResponse = CDdClaimsCalloutController.makeClaimDocumentAPICallout(failureClaimId);
        CDdClaimInformation.ClaimResponse successResponse = CDdClaimsCalloutController.makeClaimDocumentAPICallout(successClaimId);
        Test.stopTest();

        Claim__c expectedClaim = [SELECT Id, Claim_Number__c, API_Status_Code__c, API_Status__c,
                                  First_Notice_of_Loss_Date__c, Response_Payload__c
                                  FROM Claim__c
                                  WHERE Id = :claims[0].Id];
        System.assertEquals('111111111', expectedClaim.Claim_Number__c, 'Claim Number on claim is not same as expected.');
        System.assertEquals(CDdSupportConstants.SUCCESS_LABEL, successResponse.status, 'Claim Submission status should be Success.');
        System.assertEquals(Date.today(), expectedClaim.First_Notice_of_Loss_Date__c, 'First Date of Notice on Claim is not same as expected.');
        System.assertEquals('200', expectedClaim.API_Status_Code__c, 'API Status Code on Claim is not same as expected.');
        System.assertEquals('success', expectedClaim.API_Status__c, 'API Status on Claim is not same as expected.');
        System.assertEquals(RESPONSE_CLAIM_NUMBER + ';' + RESPONSE_DOCUMENTS + ';', expectedClaim.Response_Payload__c, 'Response Payload on Claim is not same as expected.');
        System.assertEquals(failureResponse.message, CDdClaimsCalloutController.CLAIM_NOT_SUBMITTED_MESG, 'Response message is not same as expected.');
    }

    /**
     * @description - Test Add Email Attachments to transfer Email Attachments to Claim
     */
    @isTest
    static void testSyncDocuments(){
        List<Claim__c> claims = [SELECT Id, Facts_of_Loss__c, Case__c FROM Claim__c];
        Claim__c claimRecord;
        for(Claim__c claim : claims){
            if(claim.Facts_of_Loss__c == 'Claim Without Documents'){
                claimRecord = claim;
            }
        }

        EmailMessage email = new EmailMessage();
        email.FromAddress = 'test@abc.org';
        email.Incoming = True;
        email.ToAddress= 'test@xyz.org';
        email.Subject = 'Test email';
        email.HtmlBody = 'Test email body';
        email.RelatedToId = claimRecord.Case__c;
        insert email;

        Attachment attachment = new Attachment();
        attachment.Body = Blob.valueOf('Test Body');
        attachment.Name = String.valueOf('testfile.txt');
        attachment.ParentId = email.Id;
        insert attachment;

        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Document';
        cv.PathOnClient = 'TestDocument.pdf';
        cv.VersionData = Blob.valueOf('Test Content');
        cv.IsMajorVersion = true;
        insert cv;

        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;

        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = claimRecord.Case__c;
        cdl.ContentDocumentId = conDocId;
        cdl.shareType = 'V';
        Insert cdl;

        Test.startTest();
        String successResult = CDdClaimsCalloutController.syncDocuments(claimRecord.Id);
        Test.stopTest();

        List<Attachment> claimAttachments = [SELECT Id, Name FROM Attachment WHERE ParentId = :claimRecord.Id];
        System.assertEquals(CDdSupportConstants.SUCCESS_LABEL, successResult, 'Result should be success.');
        System.assert(claimAttachments.size() > 0, 'No Attachments found on Claim.');
        System.assertEquals('testfile.txt', claimAttachments[0].Name, 'Attachment Name is not same as expected.');
    }

    /**
     * @description - Test Add Email Attachments if No Attachments exists
     */
    @isTest
    static void testSyncDocumentsException(){
        List<Claim__c> claims = [SELECT Id, Facts_of_Loss__c FROM Claim__c LIMIT 1];

        Boolean exceptionFound;
        try{
            Test.startTest();
            CDdClaimsCalloutController.syncDocuments(claims[0].Id);
            Test.stopTest();
        }catch(Exception ex){
            exceptionFound = true;
        }

        System.assert(exceptionFound, 'Exception is expected.');
    }
}