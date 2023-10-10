@istest
public with sharing class CDdDenaliV2HandlerTest {
    public static final Id TEST_ROLE_ID;
    public static final Id SYSTEM_ADMIN_PROFILE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    static {
        TEST_ROLE_ID = [SELECT Id FROM UserRole WHERE DeveloperName = 'COO'].Id;
        SYSTEM_ADMIN_PROFILE_ID = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;        
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
    
	public class CDdDenaliV2ValidMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            if (req.getEndpoint().contains('getbusinessobjectsummary')) {
                res.setBody('[{"busObId":123,"hasError":false,"errorMessage":"test"}]');
            } else {
                res.setBody('{"busObId":123, "busObRecId":123, "hasError":false,"errorMessage":"test", "relatedBusinessObjects":[{"busObRecId":123}], "groups":[{"hasError":false, "simpleResultsListItems":[{"busObId":123, "busObRecId":12346}]}]}');
            }
            res.setStatusCode(200);
            return res;
        }
    }
    
    @TestSetup
    public static void createCaseWithContactAccount() {
        System.runAs(getTestRunUser()){
            CDdContactTriggerHelper.insertCampaign();
            Record_Type_Values__mdt caseRecordType = [SELECT QualifiedApiName, Record_Type_Id__c 
                                                            FROM Record_Type_Values__mdt
                                                            WHERE QualifiedApiName  = 'Case_Tablet_Requests'];
            String rtId = caseRecordType.Record_Type_Id__c;
            
            Account testAccount = new Account();
            //testAccount.Name = 'John Doe';
            testAccount.LastName = 'Doe 3';
            testAccount.FirstName = 'John 3';
            testAccount.Phone = '855-973-1040';
            testAccount.Restaurant_ID__c = '123456789';
            testAccount.iPad_Username__c = 'John3';
            testAccount.iPad_Password__c = 'Doe3';
            insert testAccount;
    
            Contact testContact = new Contact();
            testContact.Email = 'john3.doe3@doordash.com';
            testContact.Phone = '855-973-1040';
            testContact.LastName = 'Doe3';
            insert testContact;
    
            Opportunity opp = new Opportunity();
            opp.Name = 'Test Opp 3';
            opp.AccountId = testAccount.Id;
            opp.StageName = 'New';
            opp.CloseDate = System.today();
            opp.Region_Type__c = 'Live Region';
            opp.ForecastCategoryName  = 'Pipeline ';
            
            insert opp;
    
            Case testCase = new Case();
            testCase.AccountId = testAccount.Id;
            testCase.ContactId = testContact.Id;
            testCase.Return_Shipping_Address_Suite_Apt_etc__c = '';
            testCase.Shipping_Address_Country__c = 'USA';
            testCase.Send_To_Denali__c = true;
            testCase.Status = 'Approved';
            testCase.RecordTypeId = rtId;
            testCase.Return_Shipping_Address_Street__c  = '2196 NE 61ST CT';
            testCase.Return_Shipping_Address_City__c = 'Fort Lauderdale';
            testCase.Return_Shipping_Address_Zip__c = '33308';
            testCase.Return_Shipping_Address_State__c  = 'FL';
            testCase.Request_Type__c = 'Ship to Merchant (New Tablet)';
            testCase.Opportunity_Name__c = opp.Id;
    
            insert testCase;
    
            testCase.Status = 'Approved';
            update testCase;
        }
    }

    @IsTest
    public static void testQueryDenaliCase(){
        Case testCase = [SELECT Id From Case LIMIT 1];
        Case populatedTestCase;
        Test.startTest();
        populatedTestCase = CDdDenaliV2Handler.queryDenaliCase(testCase.Id);
        Test.stopTest();
        System.assertEquals(populatedTestCase.Contact.Phone, '855-973-1040', 'Body should be sanitize');
    }
    
    @IsTest
    public static void testSanatizeBody(){
        Case testCase = [SELECT Id From Case LIMIT 1];
        Test.startTest();
        Case populatedTestCase = CDdDenaliV2Handler.queryDenaliCase(testCase.Id);
        CDdDenaliV2RequestObject.CherwellBody body = new CDdDenaliV2RequestObject.CherwellBody();
        CDdDenaliV2RequestObject.generateJSON(body, populatedTestCase);
        Boolean isSanitize = body.sanatizeBody();      
        Test.stopTest();

        System.assertEquals(isSanitize, true, 'Body should be sanitize');
    }

    @IsTest
    public static void testGetOperation(){
        Case testCase = [SELECT Id From Case LIMIT 1];
        String operation;
        Test.startTest();
        Case populatedTestCase = CDdDenaliV2Handler.queryDenaliCase(testCase.Id);
        CDdDenaliV2RequestObject.CherwellBody body = new CDdDenaliV2RequestObject.CherwellBody();
        operation = CDdDenaliV2RequestObject.getOperation(populatedTestCase);
        Test.stopTest();

        System.assertEquals(operation, 'New', 'Operation should be new since no Denali Record Id');
    }

    @IsTest
    public static void testGetOperationUpdate(){
        Case testCase = [SELECT Id From Case LIMIT 1];
        testCase.Denali_Record_Id__c = 'test';
        update testCase;

        String operation;
        Test.startTest();
        Case populatedTestCase = CDdDenaliV2Handler.queryDenaliCase(testCase.Id);
        CDdDenaliV2RequestObject.CherwellBody body = new CDdDenaliV2RequestObject.CherwellBody();
        operation = CDdDenaliV2RequestObject.getOperation(populatedTestCase);
        Test.stopTest();

        System.assertEquals(operation, 'Update', 'Operation should be new since no Denali Record Id');
    }
    
    @IsTest
    public static void testSaveCaseToDenali(){
        Case testCase = [SELECT Id From Case LIMIT 1];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CDdDenaliV2ValidMock());
        CDdDenaliV2Handler.saveCaseToDenali(testCase.Id, true);
        Test.stopTest();

        Case sentCase = [SELECT Send_To_Denali__c FROM Case WHERE Id =: testCase.Id];
        System.assert(sentCase.Send_To_Denali__C == false, 'Sent_to_Denali__c fields was not updated');
    }
    
    @IsTest
    public static void testSaveCasesToDenali(){
        List<Id> caseIds = new List<Id>();
        Case testCase = [SELECT Id From Case LIMIT 1];
        caseIds.add(testCase.Id);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CDdDenaliV2ValidMock());
        CDdDenaliV2Handler.saveCasesToDenali(caseIds);
        Test.stopTest();
        
        Case sentCase = [SELECT Send_To_Denali__c FROM Case WHERE Id =: testCase.Id];
        System.assert(sentCase.Send_To_Denali__C == false, 'Sent_to_Denali__c fields was not updated');
    }
    
    @IsTest
    public static void testGenerateAccessToken() {
        String expected = 'VVNFUk5BTUU6UEFTU1dPUkQ=';
        Test.startTest();
        String accessToken = CDdDenaliV2Handler.generateAccessToken('USERNAME', 'PASSWORD');
        Test.stopTest();
        
        System.assertEquals(expected, accessToken, 'GenerateAccessToken failure');
    }
    
    @IsTest
    public static void testDenaliV2Batch() {
        System.runAs(getTestRunUser()){
            Case testCase = [SELECT Id From Case LIMIT 1];
            ID batchId;
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new CDdDenaliV2ValidMock());
            batchId = Database.executeBatch(new CDdDenaliV2Batch());
            Test.stopTest();
            
            //Case sentCase = [SELECT Send_To_Denali__c FROM Case WHERE Id =: testCase.Id];
            //System.assert(sentCase.Send_To_Denali__C == false, 'Sent_to_Denali__c fields was not updated');
            AsyncApexJob aaj = [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors 
                    FROM AsyncApexJob WHERE ID =: batchId ];
			System.assert(batchId != null, 'BatchId was not created');
            System.assert(aaj != null, 'BatchId was not created');
        }
    }

    @IsTest
    public static void testDenaliV2BatchSched() {
        Case testCase = [SELECT Id From Case LIMIT 1];
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CDdDenaliV2ValidMock());
        CDdDenaliV2Sched.setSchedule();
        Test.stopTest();

        ApexClass self = [SELECT Id FROM ApexClass WHERE Name = 'CDdDenaliV2Sched'];  //get the ID of this class
        List<CronTrigger> ct = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name like 'CDdDenaliV2Sched%' OR CronJobDetail.Name = :self.Id];
        System.assert(ct.size() > 0, 'Schedule was not set for Denali V2 Batch');
    }

    @IsTest
    public static void testDenaliV2InvalidField() {
        System.runAs(getTestRunUser()){
           CDdDenaliV2RequestObject.CherwellBody body = new CDdDenaliV2RequestObject.CherwellBody();
            Map<String, String> toCheck = new Map<String, String>{
                'A' => '1',
                'B' => '2',
                'C' => ''
            };
           Boolean containsKey = body.invalidField(toCheck, 'A');
           Boolean isBlank = body.invalidField(toCheck, 'C');
           Boolean notExist = body.invalidField(toCheck, 'D');
           System.assert(containsKey == false, 'A should exist in toCheck');
           System.assert(isBlank == true, 'A should exist in toCheck');
           System.assert(notExist == true, 'A should exist in toCheck');
        }
    }

}