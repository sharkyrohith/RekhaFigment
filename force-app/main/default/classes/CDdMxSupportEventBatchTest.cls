/********************************************************************************************************************
* @author Veera
* @date 04/28/2022
*
* @group Merchant Services
*
* @description Test class for CDdMxSupportEventBatch
*
**************************************************************************************************************************************/
@isTest
public class CDdMxSupportEventBatchTest {
   
    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    public static final String TEST_INTERFACE_NAME = 'CDdMxSupportEventInterfaceTest';
    public static String CRON_EXP = '0 0 0 15 5 ? 2025';
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

    /** 
    * @description Prepare test data
    */
    @TestSetup
    static void setup() {
        System.runAs(getTestRunUser()){
            createEventConfig('Case', 0);
            Case testCase = TDdCaseFactory.createSolveableSupportCase(1,CDdRecordTypeCase.customer())[0];
            testCase.Subject = 'testSubject';
            testCase.Status = 'New';
            insert testCase;
        }
    }

    /** 
    * @description to check the batch class coverage
    */
    @isTest
    static void testBatchClassAndConfigMethods() {
        System.runAs(getTestRunUser()){
            CDdMxSupportEventEnum firstEvent = CDdMxSupportEventConfig.getFirstMxSupportEvent();
            if(firstEvent != null){
                CDdMxSupportEventBatch supportBatch = new CDdMxSupportEventBatch(firstEvent);
                Database.executeBatch(supportBatch,CDdMxSupportEventConfig.getBatchSize(firstEvent));
            }
        }
    }

     /** 
    * @description to check the chain batching when more than 1 Mx_Support_Event_Config__c records
    */
    @isTest
    static void testChainBatching() {
        System.runAs(getTestRunUser()){
            createEventConfig('Case', 1);
            Test.startTest();
            CDdMxSupportEventEnum firstEvent = CDdMxSupportEventConfig.getFirstMxSupportEvent();
            if(firstEvent != null){
                CDdMxSupportEventBatch supportBatch = new CDdMxSupportEventBatch(firstEvent);
                Database.executeBatch(supportBatch, CDdMxSupportEventConfig.getBatchSize(firstEvent));
            }
            test.stopTest();
            System.assertEquals(true, CDdMxSupportEventConfig.hasNextMxSupportEvent(firstEvent));
        }
    }

     /**
     * @description To cover the test coverage for 'CDdMxSupportEventScheduler' scheduleable class
     */   
    @isTest
    private static void testscheduleClass() {
        System.runAs(getTestRunUser()){
            Test.startTest();
            String jobId = System.schedule('CDdMxSupportEventScheduler', CRON_EXP, new CDdMxSupportEventScheduler());
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
            Test.stopTest();
            System.assertEquals(CRON_EXP, ct.CronExpression);
            System.assertEquals(0, ct.TimesTriggered);
            System.assertEquals('2025-05-15 00:00:00',  String.valueOf(ct.NextFireTime));
        }
	}
    
    /**
     * @description Test all the methods in CDdMxSupportEventConfig class
     * inserting config records and see if it returns correct data based on event, sequence
     */    
    @isTest
    private static void testSupportEventConfigMethods() {
        System.runAs(getTestRunUser()){
            Test.startTest();
            createEventConfig('Case', 1);
            Test.stopTest();           
            CDdMxSupportEventEnum eventEnum = CDdMxSupportEventEnum.values()[0];           
            System.assertEquals(10, CDdMxSupportEventConfig.getBatchSize(eventEnum));
            System.assertEquals(2, CDdMxSupportEventConfig.getQueryLastNDays(eventEnum));
            System.assertEquals('Case', CDdMxSupportEventConfig.getQuerySObjectType(eventEnum));
            System.assertEquals(CDdMxSupportEventEnum.values()[0], CDdMxSupportEventConfig.getFirstMxSupportEvent());
            System.assertEquals(true, CDdMxSupportEventConfig.hasNextMxSupportEvent(eventEnum));
            System.assertEquals(CDdMxSupportEventEnum.values()[1], CDdMxSupportEventConfig.getNextMxSupportEvent(eventEnum));
            System.assertNotEquals(null, CDdMxSupportEventConfig.getMxSupportInstance(eventEnum));
            System.assertEquals(10, CDdMxSupportEventConfig.getQueryLimit(eventEnum));

            CDdMxSupportEventEnum nextEventEnum = CDdMxSupportEventConfig.getNextMxSupportEvent(eventEnum);  
            System.assertEquals(2, CDdMxSupportEventConfig.getQueryLastNDays(nextEventEnum));
            System.assertEquals(10, CDdMxSupportEventConfig.getBatchSize(nextEventEnum));
            System.assertEquals(10, CDdMxSupportEventConfig.getQueryLimit(nextEventEnum));
        }
    }

    /**
     * @description To test the event publish and subscriber code
     */    
    @isTest
    private static void testMXSupportEventSubscriberClasses() {
        System.runAs(getTestRunUser()){
            Case caseRec = [SELECT Id FROM Case where Subject = 'testSubject' LIMIT 1];
            Mx_Support_Event__e supportEvent = new Mx_Support_Event__e(Event_Name__c = CDdMxSupportEventConfig.getFirstMxSupportEvent().name(),SObjectType__c = 'Case',SObjectId__c = caseRec.Id);   
            Test.startTest();
            Database.SaveResult sr = EventBus.publish(supportEvent);
            Test.stopTest();
            System.assertEquals(true, sr.isSuccess());
        }
    }

     /**
     * @description To test getDbQueryFilteredBySObjectIds method in CDdMxSupportEventBatch class
     */    
    @isTest
    private static void testDbQueryFilteredBySObjectIds() {
        System.runAs(getTestRunUser()){ 
            Account acc = TDdAccountFactory.createAccount(Schema.SObjectType.Account.getRecordTypeInfosByName().get(CDdSupportConstants.RECORDTYPE_NAME_MARKETPLACE).getRecordTypeId());
            createEventConfig('Contact', 1);
            acc.Deck_Rank__c = 'Ace of Spades';
            insert acc;
            List<Contact> testConsList = TDdAccountFactory.createContacts(2, acc.Id);
            insert testConsList;
            Test.startTest();
            CDdMxSupportEventEnum firstEvent = CDdMxSupportEventConfig.getFirstMxSupportEvent();
            CDdMxSupportEventBatch supportBatch = new CDdMxSupportEventBatch(firstEvent);
            Database.executeBatch(supportBatch, CDdMxSupportEventConfig.getBatchSize(firstEvent));
            Test.stopTest();
        }
    }

    /**
     * @description To test getDbQueryFilteredBySObjectIds method in CDdMxSupportEventBatch class
     */    
    @isTest
    private static void testEmailNotification() {
        System.runAs(getTestRunUser()){ 
            Account acc = TDdAccountFactory.createAccount(Schema.SObjectType.Account.getRecordTypeInfosByName().get(CDdSupportConstants.RECORDTYPE_NAME_MARKETPLACE).getRecordTypeId());
            acc.Deck_Rank__c = 'Ace of Spades';
            insert acc;

            Mx_Support_Event_Config__c config = CDdMxSupportEventConfig.getConfigRecord(CDdMxSupportEventConfig.getFirstMxSupportEvent());
            config.Send_Email__c = true;
            config.Email_Addresses_To_Notify__c = TEST_DD_RUN_USERNAME;
            update config;

            try{
                Test.startTest();
                CDdMxSupportEventEnum firstEvent = CDdMxSupportEventConfig.getFirstMxSupportEvent();
                CDdMxSupportEventBatch supportBatch = new CDdMxSupportEventBatch(firstEvent);
                Database.executeBatch(supportBatch, CDdMxSupportEventConfig.getBatchSize(firstEvent));
                Test.stopTest();
            }catch(Exception ex){
                System.assert(ex.getMessage().contains('NO_MASS_MAIL_PERMISSION'));
            }
            
        }
    }

    private static void createEventConfig(String sObjectType, Integer sequence){
        CDdMxSupportEventEnum event = (sequence == 0) ? CDdMxSupportEventEnum.MX_SUPPORT_TEST_1 : CDdMxSupportEventEnum.MX_SUPPORT_TEST_2;
        Mx_Support_Event_Config__c eventConfig = new Mx_Support_Event_Config__c();
        eventConfig.Apex_Class__c = TEST_INTERFACE_NAME;
        eventConfig.Batch_Size__c = 10;
        eventConfig.Event_Name__c = event.name();
        eventConfig.Is_Active__c = true;
        eventConfig.Query_Last_N_Days__c = 2;
        eventConfig.Query_Limit__c = 10;
        eventConfig.Query_SObject_Type__c = sObjectType;
        eventConfig.Sequence__c = sequence;
        insert eventConfig;
    }
}