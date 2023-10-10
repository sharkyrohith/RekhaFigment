@isTest 
public class VChatMonitorTest {

    public class MockHttpResponseGenerator implements HttpCalloutMock{
        
        public HttpResponse respond(HTTPRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            VDeliveryInformation info = new VDeliveryInformation();
            info.callAttempts = 3;
            String result='{"active_date":"2015-08-28","consumer":{"phone_number":"(323) 363-8831","first_name":"Cary","last_name":"K.","id":7063160,"email":"carykrowne@yahoo.com"},"id":1795993,"store":{"phone_number":"(310) 275-9444","id":3450,"name":"Dan Tanas"},"dasher":{"phone_number":"(347) 885-1569","first_name":"Strashimir","last_name":"Gigov","id":19692,"email":"most_import@yahoo.com"}}';
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

    @isTest(seeAllData=false)
    static void testPositive() {
        // create custom setting for test class 
        Dispatch_Settings__c dpSettings = new Dispatch_Settings__c();
        dpSettings.Caviar_Deployment_IDs__c = '5722L000000k9bNQAQ;5726C000000Kz15QAC';
        dpSettings.Caviar_Case_Record_Type_ID__c ='0122L000000sc46';
        dpSettings.Case_Record_Type_ID__c='0121a0000006Qog';
        
        insert dpSettings;
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
            RequestTime=datetime.newInstance(2014, 9, 15, 13, 30, 0), DasherNo__c=2345, CustomerNo__c=35463,
            DeliveryNo__c=64754, DeliveryUUID__c='64754',  Issue__c='test', Issue_Details__c='test', LiveChatButtonId = btn.Id);
            
        insert tx;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());     
        
        PageReference pageRef = Page.ChatMonitor;
        //pageRef.getParameters().put('id',c1.Id);
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(cs);
        VChatMonitor chat = new VChatMonitor(sc);
        System.assertNotEquals(null, VChatMonitor.createCase('123', 12345, '12345', 12345, 12345, 132112, '5731a00000005i4', ''));

        VChatMonitor.getChat(tx.Id);
        
        Test.stopTest();
    }

    static testMethod void testNegative() {
        // emulate an exception
        RecordType rt = [SELECT id,name from Recordtype where SobjectType='case' AND name='Support' LIMIT 1];
        
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
            RequestTime=datetime.newInstance(2014, 9, 15, 13, 30, 0), DasherNo__c=2345, CustomerNo__c=35463,
            DeliveryNo__c=64754, DeliveryUUID__c='64754', Issue__c='test', Issue_Details__c='test', LiveChatButtonId = btn.Id);
            
        insert tx;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockNegativeHttpResponseGenerator());     
        
        PageReference pageRef = Page.ChatMonitor;
        //pageRef.getParameters().put('id',c1.Id);
        Test.setCurrentPage(pageRef);
        
        
        ApexPages.StandardController sc = new ApexPages.StandardController(cs);
        VChatMonitor chat = new VChatMonitor(sc);        
        
        Case cse = VChatMonitor.createCase('123', null, null, null, null, null, null, '');
        cse = [select Id, Subject from Case where Id = :cse.Id];

        System.assert(cse.Subject.contains('Error Creating case'));
        
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

        VChatMonitor.takeOwnership(cs.Id);

        Case c = [select Id, OwnerId from Case where Id =: cs.Id];

        System.assertEquals(c.OwnerId, UserInfo.getUserId());

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

        VChatMonitor.stampPreviousQueue(cs.Id);

        Test.stopTest();
       
    }
    
    static testMethod void testSendBirdNegative() {
        List<Case> sendbirdCases = TDdCaseFactory.createSendbirdCase(1, null, null); 
        sendbirdCases[0].DeliveryUUID__c = 'test';
        insert sendbirdCases; 

        Support_Feature_Flag__c settings = Support_Feature_Flag__c.getOrgDefaults();
        settings.Enable_Dispatch_for_Sendbird__c = true;
        insert settings;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockNegativeHttpResponseGenerator());     
        
        PageReference pageRef = Page.ChatMonitor;
        //pageRef.getParameters().put('id',c1.Id);
        Test.setCurrentPage(pageRef);
        
        
        ApexPages.StandardController sc = new ApexPages.StandardController(sendbirdCases[0]);
        VChatMonitor chat = new VChatMonitor(sc);        
        
        Case cse = VChatMonitor.SendbirdCaseToDispatch(sendbirdCases[0].Id);
        cse = [select Id, Subject from Case where Id = :cse.Id];

        System.assert(cse.Subject.contains('Error Creating case'));
        
        Test.stopTest();
    }

    @isTest
    static void testPositiveWithCaseSave() {
        
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
            RequestTime=datetime.newInstance(2014, 9, 15, 13, 30, 0), DasherNo__c=2345, CustomerNo__c=35463,
            DeliveryNo__c=64754, DeliveryUUID__c='64754',  Issue__c='test', Issue_Details__c='test', LiveChatButtonId = btn.Id);
            
        insert tx;

        Support_Feature_Flag__c features = Support_Feature_Flag__c.getInstance();
        features.Enable_Chat_Monitor_Case_Save__c = true;
        insert features;

        Dispatch_Settings__c apiSettings = Dispatch_Settings__c.getInstance();
        apiSettings.API_Case_Callout_At_Insert__c = false;
        apiSettings.Case_API_Record_Type_ID__c = '0121a0000006Qoq';
        apiSettings.Case_Default_Business_Hours__c = '01m1a000000Hru1';
        apiSettings.Case_Object_Send_To_Dispatch__c = false;
        apiSettings.Case_Record_Type_ID__c = '0121a0000006Qog';
        apiSettings.Caviar_Case_Record_Type_ID__c = '0122L000000sc46';
        apiSettings.Caviar_Deployment_IDs__c = '5722L000000k9bNQAQ;5726C000000Kz15QAC';
        apiSettings.Caviar_Diner_Chat_Button_ID__c = '5732L000000blJOQAY';
        apiSettings.Caviar_Diner_Web_Chat_Button_ID__c = '5732L000000blJO';
        apiSettings.Create_Case_Record__c = true;
        apiSettings.Customer_PA_Upsert__c = true;
        apiSettings.Dasher_PA_Upsert__c = true;
        apiSettings.Delivery_Upsert__c = true;
        apiSettings.Disabled__c = false;
        apiSettings.Dispatch_Case_Update_Endpoint__c = 'https://api.doordash.com/v1/support_salesforce_case_records';
        apiSettings.Dispatch_ID_Endpoint_Prefix__c = 'https://api.doordash.com/v2/deliveries/';
        apiSettings.Dispatch_ID_Endpoint_Suffix__c = '/salesforce_info/';
        apiSettings.Dispatch_Token__c = 'c0b31c2eaaab54f1a9e680d9e3377d6643283878';
        apiSettings.Dispatch_Token_Prefix__c = 'Bearer';
        apiSettings.Dispatch_UUID_Endpoint_Prefix__c = 'https://api.doordash.com/v4/deliveries/';
        apiSettings.Dispatch_UUID_Endpoint_Suffix__c = '/salesforce_info/';
        apiSettings.Fire_On_Omni_Events__c = true;
        apiSettings.Get_From_Dispatch_Retries__c = 1;
        apiSettings.Merchant_Account_Record_Type_ID__c = '0121a000000Qg1V';
        apiSettings.Merchant_Upsert__c = true;
        apiSettings.Send_To_Dispatch_Retries__c = 1;
        apiSettings.Use_UUID__c = true;
        upsert apiSettings;


        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());     
        
        PageReference pageRef = Page.ChatMonitor;
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(cs);
        VChatMonitor chat = new VChatMonitor(sc);
        System.assertNotEquals(null, VChatMonitor.createCase('123', 12345, '12345', 12345, 12345, 132112, '5731a00000005i4', ''));

        VChatMonitor.getChat(tx.Id);
        
        Test.stopTest();
    }

    @isTest
    static void testIsDispatchSuccessful() {
        Case cs = new Case(
            subject = 'Test Case',
            origin = 'Web',
            chatkey__c = '023948-129038-12938-12398'
        );

        insert cs;

        Test.startTest();
        PageReference pageRef = Page.ChatMonitor;
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(cs);
        VChatMonitor chat = new VChatMonitor(sc);
        Test.stopTest();
        System.assertEquals(false, VChatMonitor.isDispatchSuccessful(cs.Id), 'DispatchRQStatus__c on Case is not same as expected.');
    }
}