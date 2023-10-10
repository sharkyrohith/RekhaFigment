/**
 *
 * @author: Tia Xuan
 * @date: 2019-08
 * @description Test class for CDdChatMonitorController
 *
 */
@isTest
public class CDdChatMonitorControllerTest {
     @TestSetup
    static void makeData(){
        Support_Feature_Flag__c featureFlag = Support_Feature_Flag__c.getOrgDefaults();
        featureFlag.Enable_Sendbird_API_Callouts__c = true;
        upsert featureFlag;

        insert new Sendbird_Settings__c(Callout_Retries__c = 1);
    }
    public class MockHttpResponseGenerator implements HttpCalloutMock{

        public HttpResponse respond(HTTPRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            VDeliveryInformation info = new VDeliveryInformation();
            info.callAttempts = 3;
            String result='{"active_date":"2019-10-16","consumer":{"phone_number":"0452 604 471","first_name":"Veni","last_name":"Are","email":"veni.are@gmail.com","phone_number_components":{"formatted_national_number":"0452 604 471","national_number":"452604471","formatted_international_number":"+61 452 604 471","country_code":"61","international_number":"+61452604471","country_shortname":"AU"},"id":161737491},"id":330501679,"store":{"phone_number":"(03) 9041 9899","name":"Sankranti Australia ( Barkly St)","business":{"description":"","id":325642,"name":"Sankranti Australia"},"address":{"city":"Footscray","subpremise":"","id":62353076,"printable_address":"SANKRANTI AUSTRALIA, 250 Barkly St, Footscray VIC 3011, Australia","state":"Victoria","street":"250 Barkly Street","country":"Australia","lat":-37.7990611,"lng":144.8961249,"shortname":"SANKRANTI AUSTRALIA","zip_code":"3011"},"submarket":{"id":2279,"name":"Melbourne"},"order_protocol":"IPAD","id":700840,"is_partner":false},"dasher":null}';
            res.setBody(result);
            return res;
        }
    }

    public class MockNegativeHttpResponseGenerator implements HttpCalloutMock{

        public HttpResponse respond(HTTPRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            VDeliveryInformation info = new VDeliveryInformation();
            info.callAttempts = 3;
            String result='{}';
            res.setBody(result);
            return res;
        }
    }

    @isTest
    static void testPositive() {
        // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
        Dispatch_Settings__c settings = VTestUtil.createDispatchSettings();
        insert settings;

        Case cs = new Case(
            subject = 'Test Case',
            origin = 'Web',
            chatkey__c = '230948-10239-12039-12039'
        );
        insert cs;

        LiveChatVisitor visitor = new LiveChatVisitor();
        insert visitor;


        LiveChatButton btn = [select Id from LiveChatButton where WindowLanguage != null limit 1];

        // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
        LiveChatTranscript tx = new LiveChatTranscript(
            chatKey = '123', liveChatVisitorId = visitor.id, Status='Completed',
            StartTime= datetime.newInstance(2017, 9, 15, 12, 30, 0), EndTime=datetime.newInstance(2017, 9, 15, 13, 30, 0),
            RequestTime=datetime.newInstance(2014, 9, 15, 13, 30, 0), DasherNo__c=2345, CustomerNo__c=35463,
            DeliveryNo__c=64754, DeliveryUUID__c='64754', MerchantNo__c =123, Issue__c='test', Issue_Details__c='test', LiveChatButtonId=btn.Id);
        insert tx;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        System.assertNotEquals(null, CDdChatMonitorController.CreateCase(tx.Id));

        Test.stopTest();
    }

    @isTest
    static void testNegative() {
        // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
        Dispatch_Settings__c settings = VTestUtil.createDispatchSettings();
        insert settings;

        Trigger_Control_Panel__c tcp=new Trigger_Control_Panel__c();
        tcp.Name='Control Panel';
        tcp.Account_Trigger_Enabled__c=True;
        insert tcp;

        Account acc = new Account(Name='DoorDash HQ (123 street)'); //,Market_Area__c='ATL - Atlanta');
        insert acc;

        Entitlement ent = new Entitlement(Name='Testing',
                                        AccountId=acc.Id, StartDate=Date.valueof(System.now().addDays(-2)),
                                        EndDate=Date.valueof(System.now().addYears(2)));
        insert ent;

        Case cs = new Case(
            subject = 'Test Case',
            origin = 'Web',
            chatkey__c = '023948-129038-12938-12398'
        );

        insert cs;

        LiveChatVisitor visitor = new LiveChatVisitor();
        insert visitor;

        LiveChatButton btn = [select Id from LiveChatButton where WindowLanguage != null limit 1];

        // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
        LiveChatTranscript tx = new LiveChatTranscript(
            chatKey = '123', liveChatVisitorId = visitor.id, Status='Completed',
            StartTime= datetime.newInstance(2017, 9, 15, 12, 30, 0), EndTime=datetime.newInstance(2017, 9, 15, 13, 30, 0),
            RequestTime=datetime.newInstance(2014, 9, 15, 13, 30, 0) , Issue__c='test', Issue_Details__c='test', LiveChatButtonId = btn.Id);

        insert tx;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockNegativeHttpResponseGenerator());

        Case cse = CDdChatMonitorController.CreateCase(tx.Id);
        cse = [select Id, Subject from Case where Id = :cse.Id];

        System.assert(cse.Subject.contains('Error Creating case'));

        Test.stopTest();
    }

    @isTest
    static void testPreviousQueue() {
        Case cs = new Case(
            subject = 'Test Case',
            origin = 'Web',
            chatkey__c = '023948-129038-12938-12398'
        );

        insert cs;

        Test.startTest();

        CDdChatMonitorController.stampPreviousQueue(cs.Id);

        Test.stopTest();
    }

    @isTest
    static void testTakeOwnership() {

        User u = [select Id from User where isActive = true and Profile.Name = 'System Administrator' limit 1];
        Case cs = new Case(
            subject = 'Test Case',
            origin = 'Phone',
            OwnerId = u.Id
        );

        insert cs;

        Test.startTest();

        CDdChatMonitorController.takeOwnership(cs.Id);

        Case c = [select Id, OwnerId from Case where Id =: cs.Id];

        System.assertEquals(c.OwnerId, UserInfo.getUserId());

        Test.stopTest();
    }

    @isTest
    static void testTreatPreviousQueueMulesoftPE() {
        Test.setMock(HttpCalloutMock.class, TDdCaseFactory.getSendbirdMockResponse());
        List<Case> sendbirdCases = TDdCaseFactory.createSendbirdCase(1, null, null);
        insert sendbirdCases;

        Test.startTest();
        //Need to insert CaseHistory record in Test class. DML action doesn't give history record.
        //Newvalue and oldvalue fields are readonly
        CaseHistory cHist = new CaseHistory();
        cHist.caseId = sendbirdCases[0].Id;
        cHist.field ='Owner';
        insert cHist;
        CDdChatMonitorController.treatPreviousQueue(sendbirdCases[0].Id);
        Test.getEventBus().deliver();
        Test.stopTest();
        Test.getEventBus().deliver();
        CaseHistory cHistRefresh =[SELECT CreatedDate FROM CaseHistory WHERE caseId =: sendbirdCases[0].Id];
     	Case c = [SELECT Id,Previous_Queue_Change__c FROM Case WHERE Id =: sendbirdCases[0].Id];
        System.assertEquals(c.Previous_Queue_Change__c, cHistRefresh.CreatedDate, 'Both dates should match');
    }
}