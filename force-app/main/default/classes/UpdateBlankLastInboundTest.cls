@isTest
public with sharing class UpdateBlankLastInboundTest {
    
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
    static void makeData(){
        System.runAs(getTestRunUser()){
            Integer count = 0;
            List<Lead> leads = new List<Lead>();
            List<CampaignMember> camMember = new List<CampaignMember>();
            Campaign testCamp = new Campaign(Name= 'AcqMktg Test', Title__c= 'TestTitle');
            insert testCamp;

            List<Lead> testLeads = TDdLeadFactory.createLeads('Test Lead ', 2, 'Master Lead', true);

            for(Lead lead : testLeads){
                camMember.add(new CampaignMember(CampaignId = testCamp.Id, LeadId= lead.id, Status= 'Sent'));
            }
            insert camMember;

            for (Lead lead : testLeads) {
                lead.Last_Inbound_Date_Time__c = NULL;
            }
            update testLeads;
        }
    }

    @isTest
    static void testUpdateBlankLastInboundBatch(){
        System.runAs(getTestRunUser()){
            Test.startTest();
            UpdateBlankLastInbound updateFields = new UpdateBlankLastInbound();
            Id batchId = Database.executeBatch(updateFields);
            Test.stopTest();
        }

        System.assertEquals(2, [SELECT count() FROM Lead WHERE Last_Inbound_Date_Time__c != null]);
    }

    public static testmethod void testSchedulableUpdateBlankLastInboundBatch(){
        System.runAs(getTestRunUser()){
            Test.startTest();
            // This test runs a scheduled job at every 15 min.
            String CRON_EXP = '0 15 * * * ?';
            // Schedule the test job
            String jobId = System.schedule('UpdateLastInboundField', CRON_EXP, new UpdateBlankLastInbound());
            // Get the information from the CronTrigger API object 
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId]; 
            // Verify the job has not run 
            System.assertEquals(0, ct.TimesTriggered);
            Test.stopTest(); 
        }       
    }
}