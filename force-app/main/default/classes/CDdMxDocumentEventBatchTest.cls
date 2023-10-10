@isTest
public class CDdMxDocumentEventBatchTest {
    @testSetup
    static void loaddata(){
        Id oppRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Marketplace').getRecordTypeId();
        Id marketplaceOnboardingRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Marketplace Onboarding').getRecordTypeId();

        // insert account
        Account testAcc = TDdAccountFactory.createAccounts('Default Values', 1, 'Marketplace')[0];
        testAcc.BillingCountryCode = 'US';
        testAcc.BillingCountry = 'United States';
        testAcc.BillingState = 'CA';
        testAcc.BillingPostalCode = '91367';
        testAcc.Phone = '120456789';
        testAcc.CurrencyISOCode = 'USD';
        testAcc.Restaurant_ID__c = '222222';
        insert testAcc;

        // Create Opportunity
        Opportunity recOpp = new Opportunity(AccountId = testAcc.Id,Name = 'Test Opportunity',CloseDate= System.Today(),RecordtypeId=oppRecTypeId,
                                          StageName='Prospecting',Pricebook2Id = Test.getStandardPricebookId());
        insert recOpp;


        Case recCase = new Case(AccountId = testAcc.Id, RecordTypeId = marketplaceOnboardingRecordTypeId, Type='My Type',
                                Origin='My Origin', Status='Open', Opportunity_Name__c = recOpp.Id);
        insert recCase;
        
        CDdMxDocumentService.checkMxDocumentContentFolder(CDdMxDocumentService.getMxDocumentLibrary());

    }

    @isTest
    static void testAddMxDocumentEvent_Success(){

        List<ContentVersion> contVersionList = new List<ContentVersion>();
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'Passport';
        contentVersion.PathOnClient = 'passport document.pdf';
        contentVersion.VersionData = Blob.valueOf('Test Data');
        contentVersion.Origin = 'C';
        contentVersion.Mx_Store_Id__c = '222222';
        contentVersion.Mx_Document_Type__c = 'Passport';
        contentVersion.Mx_Country__c = 'US';
        contVersionList.add(contentVersion);

        contentVersion = new ContentVersion();
        contentVersion.Title = 'Food License';
        contentVersion.PathOnClient = 'License Document.pdf';
        contentVersion.VersionData = Blob.valueOf('Test Data');
        contentVersion.Origin = 'C';
        contentVersion.Mx_Store_Id__c = '222222';
        contentVersion.Mx_Document_Type__c = 'Food License';
        contentVersion.Mx_Country__c = 'US';
        contVersionList.add(contentVersion);

        insert contVersionList;

        Test.startTest();
        SSMOFraudDocEventMockHttpResponse mockInstance = new SSMOFraudDocEventMockHttpResponse('',200,'Ok');
        Test.setMock(HttpCalloutMock.class, mockInstance);
        List<Mx_Document_Event__c> eventRecords = [SELECT Id,Name,Store_Id__c,SObject_Id__c
                                                   FROM Mx_Document_Event__c
                                                    WHERE Store_Id__c = :contentVersion.Mx_Store_Id__c
                                                        AND Status__c = 'New'];
        System.assert(eventRecords.size() == 2);

        Database.executeBatch(new CDdMxDocumentEventBatch());
        Test.stopTest();

        eventRecords = [SELECT Id,Name,Store_Id__c,SObject_Id__c
                                                   FROM Mx_Document_Event__c
                                                    WHERE Store_Id__c = :contentVersion.Mx_Store_Id__c
                                                    AND Status__c = 'Completed'];
        System.assert(eventRecords.size() == 2);

    }

    /**
    * @description Create Http Mock Response for SSMO Fraud Send Mx Document Event API call
    */
    public class SSMOFraudDocEventMockHttpResponse implements HttpCalloutMock {
        private String body;
        private Integer code;
        private String statusMsg;

        // constructor
        public SSMOFraudDocEventMockHttpResponse(String body,Integer code, String statusMsg){
            this.body = body;
            this.code = code;
            this.statusMsg = statusMsg;
        }
        // Implement this interface method
        public HTTPResponse respond(HTTPRequest req) {
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(this.body);
            res.setStatus(this.statusMsg);
            res.setStatusCode(this.code);
            return res;
        }
    }
}