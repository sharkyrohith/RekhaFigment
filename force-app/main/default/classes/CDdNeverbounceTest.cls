@isTest
public class CDdNeverbounceTest {
    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    public static final Id SYSTEM_ADMIN_PROFILE_ID;
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
    @testSetup
    static void setup(){
        System.runAs(getTestRunUser()){
            List<Lead> testLeads = TDdLeadFactory.createLeads('Test Lead ', 1, 'Master Lead', false);
            testLeads[0].Email = 'test@test.com';
            testLeads[0].Email_verification_Status__c = 'invalid';
            insert testLeads;
        }
    }
    @isTest
    static void testNeverbounceCreateJob() {
        System.runAs(getTestRunUser()){
            Lead l =[select Id, Email from Lead limit 1];
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new CDdNeverbounceValidMock());     
            String jobId = CDdNeverbounceHandler.createJob(new Map<String, String>{l.Id => l.Email});
            System.assert(jobId != null);
            Test.stopTest();
        }
    }
    @isTest
    static void testNeverbounceGetJobStatus() {
        System.runAs(getTestRunUser()){
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new CDdNeverbounceValidMock());     
            String jobStatus = CDdNeverbounceHandler.getJobStatus('test');
            System.assert(jobStatus == 'complete');
            Test.stopTest();
        }
    }
    @isTest
    static void testNeverbounceGetJobResults() {
        System.runAs(getTestRunUser()){
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new CDdNeverbounceValidMock());     
            Map<String, String> resMap = CDdNeverbounceHandler.getJobResults('test');
            System.assert(resMap != null);
            Test.stopTest();
        }
    }
    @isTest
    static void testNeverbounceWeeklyBatch() {
        System.runAs(getTestRunUser()){
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new CDdNeverbounceValidMock());     
            CDdNeverbounceWeeklyBatch sch = new CDdNeverbounceWeeklyBatch();
            sch.execute(null);
            Test.stopTest();
            List<Neverbounce_Task__c> ntList =[select Id, Job_Id__c, Type__c, Status__c from Neverbounce_Task__c];
            System.assert(ntList.size() == 1);
            System.assert(ntList[0].Job_Id__c == 'test');
            System.assert(ntList[0].Type__c == CDdNeverbounceHandler.SOBJECT_TYPE_LEAD);
            System.assert(ntList[0].Status__c == CDdNeverbounceHandler.NEVERBOUNCE_JOB_STATUS_CREATED);
        }
    }
    @isTest
    static void testNeverbounceTreatmentBatch() {
        System.runAs(getTestRunUser()){
            Neverbounce_Task__c nt = new Neverbounce_Task__c();
            nt.Job_ID__c = 'test';
            nt.Status__c = CDdNeverbounceHandler.NEVERBOUNCE_JOB_STATUS_CREATED;
            nt.Type__c = 'Lead';
            insert nt;
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new CDdNeverbounceValidMock());     
            CDdNeverbounceTreatmentBatch sch = new CDdNeverbounceTreatmentBatch();
            sch.execute(null);
            Test.stopTest();
            Lead l =[select Id, Email, Email_Verification_Status__c from Lead limit 1];
            System.assert(l.Email_Verification_Status__c == 'valid');
            List<Neverbounce_Task__c> neverbounceTasksFromDB = new List<Neverbounce_Task__c>();
            for (Neverbounce_Task__c task : [SELECT Id FROM Neverbounce_Task__c]){
                neverbounceTasksFromDB.add(task);
            }
            System.assert(neverbounceTasksFromDB.isEmpty());
        }
    }
    @isTest
    static void testNeverbounceVerifyEmailSingleCheck() {
        System.runAs(getTestRunUser()){
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new CDdNeverbounceValidMock());     
            Set<Id> recordIds = new Set<Id>();
            for (Lead l : [SELECT Id, Email, Email_Verification_Status__c FROM Lead]){
                recordIds.add(l.Id);
            }
            Database.executeBatch(new CDdNeverbounceWeeklyBatch(recordIds), 1);
            Test.stopTest();
            Lead l =[select Id, Email, Email_Verification_Status__c from Lead limit 1];
            System.assert(l.Email_Verification_Status__c == 'valid');            
        }
    }    
    @isTest
    static void testNeverbounceProcessJobsBatch() {
        System.runAs(getTestRunUser()){
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new CDdNeverbounceValidMock());     
            Database.executeBatch(new CDdNeverbounceProcessJobsBatch(new Set<String>{'test'}), 1);
            Test.stopTest();
            Lead l =[select Id, Email, Email_Verification_Status__c from Lead limit 1];
            System.assert(l.Email_Verification_Status__c == 'valid');
        }        
    }    
    /** Http Callout Mock for Neverbounce */
    public class CDdNeverbounceValidMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            if (req.getEndpoint().contains(CDdNeverbounceHandler.NEVERBOUNCE_URL_JOB_CREATE)) {
                res.setBody('{"job_id":"test"}');
                res.setStatusCode(200);
            } else if (req.getEndpoint().contains(CDdNeverbounceHandler.NEVERBOUNCE_URL_VERIFY_EMAIL)) {
                res.setBody('{"status":"success","result":"valid"}');
                res.setStatusCode(200);                
            } else if (req.getEndpoint().contains(CDdNeverbounceHandler.NEVERBOUNCE_URL_JOB_STATUS)) {
                res.setBody('{"job_status":"complete"}');
                res.setStatusCode(200);
            } else if (req.getEndpoint().contains(CDdNeverbounceHandler.NEVERBOUNCE_URL_JOB_DOWNLOAD)) {
                Lead l = [select Id from Lead limit 1];
                res.setBody(l.Id+',test@test.com,valid');
                res.setStatusCode(200);                               
            } else {
                res.setBody(null);
                res.setStatusCode(500); 
            }
            return res;
        }
    }    

}