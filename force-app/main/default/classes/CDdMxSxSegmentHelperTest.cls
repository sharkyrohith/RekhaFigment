/**
 * CDdMxSxSegmentHelperTest
**/
@isTest
public class CDdMxSxSegmentHelperTest {
    private static vCS__c testSettings;
    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    public static final String TEST_OPPORTUNITY_NAME_FOR_CPQ = 'MxSx_Test_Opp_123';
    public static final String TEST_OPP_PACTSAFE_CONTRACT_TYPE = 'English Sign Up Sheet';
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
            Disable_Declarative_Automation__c disableAuto = new Disable_Declarative_Automation__c();
            disableAuto.Case__c = true;
            insert disableAuto;

            Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
            validation.Bypass_Opportunity_Validations__c = true;
            validation.Bypass_Account_Validations__c = true;
            //validation.Bypass_Case_Validations__c = true;
            insert validation;

            testSettings = VTestUtil.createVeltigSettings();
            insert testSettings ;

            Test.startTest();
            //Insert Milestone Templates
            CDdMilestoneTemplate.insertMilestoneTemplates();

            Submarket__c submarket = TDdCPQTestDataFactory.createSubmarket('New York', 'NEW YORK', 10, null, true);
            RealZip__RealZips__c realZip = TDdCPQTestDataFactory.createRealZip(submarket, false);
            realZip.Alcohol_Eligibility__c = 'Pickup';
            insert realZip;

            Account account = TDdAccountFactory.createAccounts('Account', 1)[0];
            account.RealZip__RealZip__c = realZip.Id;
            account.Business_ID__c = 1234567;
            insert account;

            Contact contact = TDdAccountFactory.createContacts(1, account.Id)[0];
            insert contact;

            CDdMxSxTestCPQSetup.insertCPQProducts();
            CDdMxSxTestCPQSetup.insertCPQPriceBookEntries();

            Opportunity opp = TDdOpportunityFactory.createOpportunityByDevRT(TEST_OPPORTUNITY_NAME_FOR_CPQ, account.Id, contact.Id, 'Closed Won', 'ML_Inside_Sales');
            opp.Commission__c = 15;
            opp.In_App_Pickup_Commission__c = 15;
            opp.DashPass_Only_Commission__c = 15;
            opp.Referred_Delivery_Commission__c = 15;
            opp.Referred_Pickup_Commission__c = 15;
            opp.Weekly_Printer_Subscription_Fee__c = '$0';
            opp.Activation_Fee__c = '$0';
            opp.Weekly_Tablet_Subscription_Fee__c = '$3';
            opp.PactSafe_Contract_Type__c = TEST_OPP_PACTSAFE_CONTRACT_TYPE;
            insert opp;

            SBQQ__Quote__c quote = TDdCPQTestDataFactory.createQuote(opp, account, contact, false);
            quote.SBQQ__StartDate__c = Date.today().addDays(-30);
            quote.PactSafe_Contract_Type__c ='';
            insert quote;

            opp.SBQQ__PrimaryQuote__c = quote.Id;
            update opp;

            Test.stopTest();

            SBQQ.TriggerControl.disable();
            CDdMxSxTestCPQSetup.insertQuoteLines(quote);
            SBQQ.TriggerControl.enable();

            Order order = TDdCPQTestDataFactory.createOrder(account, opp, quote, false);
            order.EffectiveDate = Date.today();
            order.EndDate = null;
            insert order;
            CDdMxSxTestCPQSetup.insertOrderItems(order, quote);
       }
    }
    /**
     * @description Test - Set Up banking Blocked
     */
    @isTest
    public static void testSetUpBankingBlocked() {
        System.runAs (getTestRunUser()) {
            Opportunity opportunity = getCpqOpportunity();
            Set<Id> opportunityIds = new Set<Id>{opportunity.Id};
            CDdMxSxOpportunityHelper opportunityHelper;
            // Pre-event checks
            opportunityHelper = new CDdMxSxOpportunityHelper(opportunityIds);
            System.assertEquals(true, opportunityHelper.isClosedWon(opportunity.Id));
            System.assertEquals(true, opportunityHelper.getStoreAccountId(opportunity.Id)!=null);
            System.assertEquals(true, opportunityHelper.hasCPQProducts(opportunity.Id));
            Test.startTest();
            //CDdMxSxEventPublisher.publishEventsOpportunityClosedWon(opportunityIds);
            Map<Id, Case> milesStonesCases = new Map<Id, Case>([Select Id, RecordTypeId, RecordType.Name from Case where Opportunity_name__c =: opportunity.Id]);
            List<milestone__c> milestones = [Select id, Name, status__c, Status_Reason__c from MileStone__c where Case__c in :milesStonesCases.keySet() AND Milestone_Type__c = 'Setup Banking'];
            Set<Id> setupBankingMilestoneIds = new Set<Id>();
            for(milestone__c mS :milestones){
                mS.Status__c = 'Blocked' ;
                mS.Status_Reason__c = 'Invalid EIN; Invalid IBAN Number' ;
                setupBankingMilestoneIds.add(ms.Id);
            }
            update milestones;
            CDdMxSxSegmentHelper helper = new CDdMxSxSegmentHelper();
            String sValue = (String)helper.getStaticPropertyValue('112233','');
            helper.getStaticPropertyValue('112233','Integer');
            helper.getStaticPropertyValue('112.233','Decimal');
            helper.getStaticPropertyValue('true', 'Boolean');
            helper.getStaticPropertyValue('2021-10-05 20:03:20', 'Datetime');
            System.assertEquals('112233', sValue);
            Test.stopTest();
        }
    }
    @isTest
    public static void testSegmentLogsBatch() {
        System.runAs (getTestRunUser()) {
            Opportunity opportunity = getCpqOpportunity();
            Map<Id, Case> milesStonesCases = new Map<Id, Case>([Select Id, RecordTypeId, RecordType.Name from Case where Opportunity_name__c =: opportunity.Id]);
            List<milestone__c> milestones = [Select id, Name, status__c, Status_Reason__c from MileStone__c where Case__c in :milesStonesCases.keySet() AND Milestone_Type__c = 'Setup Banking'];

            Set<Id> setupBankingMilestoneIds = new Set<Id>();
            for(milestone__c mS :milestones){
                mS.Status__c = 'Blocked' ;
                mS.Status_Reason__c = 'Invalid EIN; Invalid IBAN Number' ;
                setupBankingMilestoneIds.add(ms.Id);
            }

            update milestones;

            List<Segment_logs__c> segmentLogs = new List<Segment_logs__c>();

            for(milestone__c mS :milestones){
                Segment_logs__c sG = new Segment_logs__c();
                sG.SOBJECT_ID__c = mS.Id ;
                sG.status__c = CDdMxSxSegmentConstants.SEGMENT_EVENT_REQUEST_COMPLETE ;
                sG.Retry_Count__c = 6;
                sG.Event__c = 'MILESTONE_BLOCKED';
                segmentLogs.add(sG);
            }

            insert segmentLogs ;


            Test.setMock(HttpCalloutMock.class, new CDdMxSxHttpMockGenerator());

            segmentLogs = [Select Id, Retry_Count__c, Status__c, sObject_Id__c from Segment_Logs__c LIMIT 100];
            Map<String, Segment_logs__c> logIds = new Map<String, Segment_logs__c>();
            for(Segment_logs__c sL :segmentLogs){
                logIds.put(sL.sObject_Id__c, sL);
            }
            update segmentLogs ;
            Test.startTest();
            new CDdMxSxBatchSegmentLogScheduler();
            CDdMxSxBatchSegmentLogScheduler schedulerwithParameters = new CDdMxSxBatchSegmentLogScheduler(5, 5, 0);
            schedulerwithParameters.execute(null);
            CDdMxSxBatchSegmentLogHandler segmentBatch = new CDdMxSxBatchSegmentLogHandler();//Initialize the default constructor
            System.assertEquals(segmentBatch.lastModifiedDays, 3);
            segmentBatch.updateProcessedLog(segmentLogs[0]);
            segmentBatch.sendEmail(CDdMxSxSegmentConstants.NORESPONSEERRORSUBJECT, CDdMxSxSegmentConstants.NORESPONSEERRORBODY);
            Test.stopTest();
            Map<String, Segment_logs__c> segmentLogsByEventFromDB = new Map<String, Segment_logs__c>();
            for (Segment_logs__c l : [  SELECT Id, Event__c, SObject_Id__c, Status__c
                                        FROM Segment_logs__c LIMIT 1000]){
                segmentLogsByEventFromDB.put(l.Event__c, l);
            }
            System.assertEquals(!segmentLogsByEventFromDB.isEmpty(), true);
            System.assertEquals(segmentLogsByEventFromDB.containsKey('MILESTONE_BLOCKED'), true);
        }
    }

    @isTest
    public static void testSegmentLogsArchiveBatch() {
        System.runAs (getTestRunUser()) {
            Opportunity opportunity = getCpqOpportunity();
            Map<Id, Case> milesStonesCases = new Map<Id, Case>([Select Id, RecordTypeId, RecordType.Name from Case where Opportunity_name__c =: opportunity.Id]);
            List<milestone__c> milestones = [Select id, Name, status__c, Status_Reason__c from MileStone__c where Case__c in :milesStonesCases.keySet() AND Milestone_Type__c = 'Setup Banking'];

            Set<Id> setupBankingMilestoneIds = new Set<Id>();
            for(milestone__c mS :milestones){
                mS.Status__c = 'Blocked' ;
                mS.Status_Reason__c = 'Invalid EIN; Invalid IBAN Number' ;
                setupBankingMilestoneIds.add(ms.Id);
            }
            update milestones ;
            List<Segment_logs__c> segmentLogs = new List<Segment_logs__c>();

            for(milestone__c mS :milestones){
                Segment_logs__c sG = new Segment_logs__c();
                sG.SOBJECT_ID__c = mS.Id ;
                sG.status__c = CDdMxSxSegmentConstants.SEGMENT_EVENT_REQUEST_COMPLETE ;
                sG.Retry_Count__c = 6;
                sG.Event__c = 'MILESTONE_BLOCKED';
                segmentLogs.add(sG);
            }

            insert segmentLogs ;

            Test.startTest();
            CDdMxSxBatchSegmentArchiveLogsScheduler abatchScheduler = new CDdMxSxBatchSegmentArchiveLogsScheduler(5, 0);
            abatchScheduler.execute(null);

            Test.stopTest();
            segmentLogs = [Select Id, Retry_Count__c, Status__c, sObject_Id__c from Segment_Logs__c LIMIT 1000];
            System.assert(segmentlogs.size() > 0);
            new CDdMxSxBatchSegmentArchiveLogsScheduler();//default Handler
            new CDdMxSxBatchSegmentArchiveLogsHandler(); //default Handler
           }
    }

    @isTest
    public static void testIsActiveCheckForSegment() {
        System.runAs(getTestRunUser()){
            CDdMxSxSegmentHelper segmentHelper = new CDdMxSxSegmentHelper();
            Map<String,Segment__mdt> segmentMetadataMap = segmentHelper.querySegmentRequestDetails(CDdMxSxConstants.MXSX_SEGMENT_NOTIFICATION_EVENTS.MILESTONE_BLOCKED.name());
            Segment__mdt segmentMetadata = segmentMetadataMap.get(CDdMxSxConstants.MXSX_SEGMENT_NOTIFICATION_EVENTS.MILESTONE_BLOCKED.name());
            segmentMetadata.Is_Active__c = false;
            segmentHelper.segmentMetadataMap = segmentMetadataMap;

            Opportunity oppty = getCpqOpportunity();
            Case onboardingCase = [SELECT Id FROM Case WHERE Opportunity_Name__c = :oppty.Id AND RecordTypeId = :CDdSchemaUtils.CASE_RT.marketplaceOnboardingId() LIMIT 1][0];
            onboardingCase.OwnerId = UserInfo.getUserId();
            update onboardingCase;

            Map<Id,Milestone__c> milestoneMap = new Map<Id,Milestone__c>([SELECT Id,Milestone_Type__c,Status__c FROM Milestone__c WHERE Case__r.Opportunity_Name__c=:oppty.Id AND Case__r.RecordTypeId = :CDdSchemaUtils.CASE_RT.marketplaceOnboardingId() AND Milestone_Type__c = 'Setup Banking']);
            segmentHelper.handleSegmentEvents(milestoneMap.keyset(), CDdMxSxConstants.MXSX_SEGMENT_NOTIFICATION_EVENTS.MILESTONE_BLOCKED.name());
            List<Segment_Logs__c> segmentlogs = [SELECT Id FROM Segment_Logs__c WHERE sObject_Id__c IN :milestoneMap.keySet() AND Event__c = :CDdMxSxConstants.MXSX_SEGMENT_NOTIFICATION_EVENTS.MILESTONE_BLOCKED.name()];
            System.assert(segmentlogs.size() == 0);

            segmentMetadata.Is_Active__c = true;
            segmentHelper.segmentMetadataMap = segmentMetadataMap;
            segmentHelper.handleSegmentEvents(milestoneMap.keyset(), CDdMxSxConstants.MXSX_SEGMENT_NOTIFICATION_EVENTS.MILESTONE_BLOCKED.name());
            segmentlogs = [SELECT Id FROM Segment_Logs__c WHERE sObject_Id__c IN :milestoneMap.keySet() AND Event__c = :CDdMxSxConstants.MXSX_SEGMENT_NOTIFICATION_EVENTS.MILESTONE_BLOCKED.name()];
            System.assert(segmentlogs.size() > 0);

        }

    }

    @isTest
    public static void testSendOnlyOnceLogic() {
        System.runAs(getTestRunUser()){
            CDdMxSxSegmentHelper segmentHelper = new CDdMxSxSegmentHelper();
            Map<String,Segment__mdt> segmentMetadataMap = segmentHelper.querySegmentRequestDetails(CDdMxSxConstants.MXSX_SEGMENT_NOTIFICATION_EVENTS.MILESTONE_BLOCKED.name());
            Segment__mdt segmentMetadata = segmentMetadataMap.get(CDdMxSxConstants.MXSX_SEGMENT_NOTIFICATION_EVENTS.MILESTONE_BLOCKED.name());
            segmentMetadata.Send_Only_Once__c = false;
            segmentHelper.segmentMetadataMap = segmentMetadataMap;

            Opportunity oppty = getCpqOpportunity();
            Case onboardingCase = [SELECT Id FROM Case WHERE Opportunity_Name__c = :oppty.Id AND RecordTypeId = :CDdSchemaUtils.CASE_RT.marketplaceOnboardingId() LIMIT 1][0];
            onboardingCase.OwnerId = UserInfo.getUserId();
            update onboardingCase;

            Map<Id,Milestone__c> milestoneMap = new Map<Id,Milestone__c>([SELECT Id,Milestone_Type__c,Status__c FROM Milestone__c WHERE Case__r.Opportunity_Name__c=:oppty.Id AND Case__r.RecordTypeId = :CDdSchemaUtils.CASE_RT.marketplaceOnboardingId() AND Milestone_Type__c = 'Setup Banking']);
            List<Segment_Logs__c> initialSegmentlogs = [SELECT Id FROM Segment_Logs__c WHERE sObject_Id__c IN :milestoneMap.keySet() AND Event__c = :CDdMxSxConstants.MXSX_SEGMENT_NOTIFICATION_EVENTS.MILESTONE_BLOCKED.name()];
            System.assert(initialSegmentlogs.size() == 0);

            List<Segment_logs__c> segmentLogs = new List<Segment_logs__c>();
            for(milestone__c ms :milestoneMap.values()){
                Segment_logs__c sG = new Segment_logs__c();
                sG.SOBJECT_ID__c = ms.Id ;
                sG.status__c = CDdMxSxSegmentConstants.SUCESS_STATUS ;
                sG.Retry_Count__c = 1;
                sG.Event__c = CDdMxSxConstants.MXSX_SEGMENT_NOTIFICATION_EVENTS.MILESTONE_BLOCKED.name();
                segmentLogs.add(sG);
            }

            insert segmentLogs ;

            List<Segment_Logs__c> segmentlogsAfterDataInsert = [SELECT Id FROM Segment_Logs__c WHERE sObject_Id__c IN :milestoneMap.keySet() AND Event__c = :CDdMxSxConstants.MXSX_SEGMENT_NOTIFICATION_EVENTS.MILESTONE_BLOCKED.name()];
            System.assert(segmentlogsAfterDataInsert.size() != 0);

            Test.startTest();
            segmentMetadata.Is_Active__c = true;
            segmentMetadata.Send_Only_Once__c = false;
            segmentHelper.segmentMetadataMap = segmentMetadataMap;
            segmentHelper.handleSegmentEvents(milestoneMap.keyset(), CDdMxSxConstants.MXSX_SEGMENT_NOTIFICATION_EVENTS.MILESTONE_BLOCKED.name());
            List<Segment_Logs__c> segmentlogsAfterWithSendOnlyFalse  = [SELECT Id FROM Segment_Logs__c WHERE sObject_Id__c IN :milestoneMap.keySet() AND Event__c = :CDdMxSxConstants.MXSX_SEGMENT_NOTIFICATION_EVENTS.MILESTONE_BLOCKED.name()];
            System.assertEquals(segmentlogsAfterWithSendOnlyFalse.size(), segmentlogsAfterDataInsert.size(), 'Expecting No duplicate Events should be created with in '+CDdMxSxSegmentConstants.PREVIOUS_EVENT_CREATED_IN_LAST_N_SECONDS+' seconds');

            segmentMetadata.Send_Only_Once__c = true;
            segmentHelper.segmentMetadataMap = segmentMetadataMap;
            segmentHelper.handleSegmentEvents(milestoneMap.keyset(), CDdMxSxConstants.MXSX_SEGMENT_NOTIFICATION_EVENTS.MILESTONE_BLOCKED.name());
            List<Segment_Logs__c> segmentlogsAfterWithSendOnlyTrue  = [SELECT Id FROM Segment_Logs__c WHERE sObject_Id__c IN :milestoneMap.keySet() AND Event__c = :CDdMxSxConstants.MXSX_SEGMENT_NOTIFICATION_EVENTS.MILESTONE_BLOCKED.name()];
            System.assert(segmentlogsAfterWithSendOnlyTrue.size() == segmentlogsAfterWithSendOnlyFalse.size());
            Test.stopTest();
        }
    }
    /**
     * @description Return the test cpq opportunity record created in the setup method
     */
    private static Opportunity getCpqOpportunity() {
        return [SELECT Id, AccountId, SBQQ__PrimaryQuote__c FROM Opportunity WHERE Name = :TEST_OPPORTUNITY_NAME_FOR_CPQ LIMIT 1];
    }
}