/**
 * @author Nayana
 * @date 12/2021
 * @description Test Class for CDdCaseEventHelper
 * */
@isTest
public with sharing class CDdCaseEventHelperTest {

    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';

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

    @testSetup
    public static void testSetup() {
        List<Account> acclist = CDdTestDataFactory.createSObjectList('Account', 1, true);
        Contact photoshootContact1 = TDdAccountFactory.createContacts(1, acclist[0].Id)[0];
        insert photoshootContact1;
        Opportunity photoshootOpportunity1 = TDdOpportunityFactory.createOpportunity('photoShootOpp1', acclist[0].Id,
                                                                                         photoshootContact1.id, 'New');
        photoshootOpportunity1.AC_PB_Change__c = true;
        insert photoshootOpportunity1;
        List<Case> testCaseList = TDdCaseFactory.createCaseRecords(1, CDdSupportConstants.RECORDTYPE_NAME_SUPPORT);
        testCaseList[0].AccountId = acclist[0].Id;
        testCaseList[0].Opportunity_Name__c = photoshootOpportunity1.Id;
        insert testCaseList;
    }

     /**
     * @author      Nayana
     * @date        Dec 2021
     * @description Data will be quried once and can be used in test methods
     */
    public class TestContext
    {
        public List<Opportunity> lstOppty;
        public List<Account> lstAccount;
        public List<Case> lstCase;
        public TestContext(){
            lstCase = [SELECT Id,AccountId,Opportunity_Name__c,Origin,Customer_Type__c,RecordTypeId FROM Case];
            lstAccount = [SELECT Id FROM Account];
            lstOppty = [SELECT Id,AccountId FROM Opportunity];
        }
    }

    /**
     * @author      Nayana
     * @date        Mar 2022
     * @jira        https://doordash.atlassian.net/browse/BIZS-1051
     * @description tests HandleOnBoardinManagerCaseEvent
     */
    @isTest
    static void testHandleCaseDetailCreationEvent() {
        List<Case_Detail__c> lstCaseDetails = new List<Case_Detail__c>();
        TestContext context = new TestContext();
        List<Case> lstCase = context.lstCase;
        Case_Detail__c cDetail = new Case_Detail__c();
        cDetail.Case__c = lstCase[0].Id;
        cDetail.Case_Origin__c = lstCase[0].Origin;
        cDetail.Case_Customer_Type__c = lstCase[0].Customer_Type__c;
        CDetail.Case_RecordType__c = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeDevNameById(lstCase[0].RecordTypeId);
        lstCaseDetails.add(cDetail);
        List<Generic_Platform_Event__e> eList = CDdGenericPlatformEventHelper.createEvents(
            CDdGenericPlatformEventHelper.PlatformEventType.CASE_DETAIL_CREATION,
            null,JSON.serialize(lstCaseDetails));
        Test.startTest();
        CDdCaseEventHelper.handleCaseDetailCreationEvent(eList);
        Test.stopTest();
        System.assertEquals(true,eList.size()>0, 'Event is created successfuly');
    }

    /**
     * @author      Nayana
     * @date        Nov 2022
     * @jira        https://doordash.atlassian.net/browse/BASD-38868
     * @description tests HandleOnBoardinManagerCaseEvent
     */
    @isTest
    static void testCreateCaseFeedItem() {
        List<FeedItem> lstCaseFeedItems = new List<FeedItem>();
        TestContext context = new TestContext();
        List<Case> lstCase = context.lstCase;
        FeedItem cFeed = new FeedItem();
        cFeed.ParentId = lstCase[0].Id;
        cFeed.Body = 'Test note';
        lstCaseFeedItems.add(cFeed);
        List<Generic_Platform_Event__e> eList = CDdGenericPlatformEventHelper.createEvents(
            CDdGenericPlatformEventHelper.PlatformEventType.CREATE_CASE_FEED,
            null,JSON.serialize(lstCaseFeedItems)); //platform event
        Test.startTest();
        CDdCaseEventHelper.createCaseFeedItem(eList);
        Test.stopTest();
        System.assertEquals(true,eList.size()>0, 'Event is created successfuly');
    }

     /**
     * @author      Nayana
     * @date        Nov 2022
     * @jira        https://doordash.atlassian.net/browse/BIZS-1886
     * @description tests HandleOnBoardinManagerCaseEvent
     */
    @isTest
    static void testHandleProactiveCaseInfoRecordCreation() {
        List<CDdProactiveCaseCreationHelper.ProactiveCaseInfo> lstCaseProactive = new List<CDdProactiveCaseCreationHelper.ProactiveCaseInfo>();
        TestContext context = new TestContext();
        List<Case> lstCase = context.lstCase;
        CDdProactiveCaseCreationHelper.ProactiveCaseInfo wrapProactiveCaseInfo = new CDdProactiveCaseCreationHelper.ProactiveCaseInfo();
        wrapProactiveCaseInfo.isProactiveCaseFlow = true;
        wrapProactiveCaseInfo.caseType = 'Item Unavailable';
        wrapProactiveCaseInfo.caseRecordType = CDdSupportConstants.RECORDTYPE_NAME_CUSTOMER;
        wrapProactiveCaseInfo.caseOrigin = 'API';
        wrapProactiveCaseInfo.evaluationCriteria = 'Created';
        wrapProactiveCaseInfo.isProactiveCaseInfoCreation = true ;
        lstCaseProactive.add(wrapProactiveCaseInfo);
        List<Generic_Platform_Event__e> eList = CDdGenericPlatformEventHelper.createEvents(
            CDdGenericPlatformEventHelper.PlatformEventType.PROACTIVE_CASE_INFO_RECORD_CREATION,
            null,JSON.serialize(lstCaseProactive)); //platform event
        Test.startTest();
        CDdCaseEventHelper.handleProactiveCaseInfoRecordCreation(eList);
        Test.stopTest();
        System.assertEquals(true,eList.size()>0, 'Event is created successfuly');
    }

     /**
     * @author      Nayana
     * @date        Nov 2022
     * @jira        https://doordash.atlassian.net/browse/BIZS-1886
     * @description tests HandleOnBoardinManagerCaseEvent
     */
    @isTest
    static void testHandleProactiveCaseRecordCreation() {
        List<CDdProactiveCaseCreationHelper.ProactiveCaseInfo> lstCaseProactive = new List<CDdProactiveCaseCreationHelper.ProactiveCaseInfo>();
        TestContext context = new TestContext();
        List<Case> lstCase = context.lstCase;
        CDdProactiveCaseCreationHelper.ProactiveCaseInfo wrapProactiveCaseInfo = new CDdProactiveCaseCreationHelper.ProactiveCaseInfo();
        wrapProactiveCaseInfo.isProactiveCaseFlow = true;
        wrapProactiveCaseInfo.caseType = 'Item Unavailable';
        wrapProactiveCaseInfo.caseRecordType = CDdSupportConstants.RECORDTYPE_NAME_CUSTOMER;
        wrapProactiveCaseInfo.caseOrigin = 'API';
        wrapProactiveCaseInfo.originalCase = lstCase[0];
        wrapProactiveCaseInfo.customerType = CDdSupportConstants.CUSTOMER_TYPE_DASHER;
        wrapProactiveCaseInfo.fieldsToCopyFromOriginalCase ='AccountId';
        lstCaseProactive.add(wrapProactiveCaseInfo);
        List<Generic_Platform_Event__e> eList = CDdGenericPlatformEventHelper.createEvents(
            CDdGenericPlatformEventHelper.PlatformEventType.PROACTIVE_CASE_CREATION,
            null,JSON.serialize(lstCaseProactive)); //platform event
        Test.startTest();
        CDdCaseEventHelper.handleProactiveCaseRecordCreation(eList);
        Test.stopTest();
        System.assertEquals(true,eList.size()>0, 'Event is created successfuly');
    }

    /**
     * @author      Mahesh Chouhan
     * @date        June 2023
     * @jira        https://doordash.atlassian.net/browse/BASD-43689
     * @description test method for handling Disaster Esalation Case
     */
    @isTest
    static void testCheckForDisasterPreventionCase() {
        Group testGroup = new Group(Name='test group', Type='Queue');
        insert testGroup;
        System.runAs(getTestRunUser())
        {
            QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = 'Case');
            insert testQueue;
        }

        Id fakeCaseId = Fake.generateId(Case.class);

        Case newCaseRecord = (Case) new Fake(Case.class)
            .setField(Case.Id, fakeCaseId)
            .setField(Case.Disaster_Escalation_Case__c, false)
            .setField(Case.Customer_Type__c, 'Merchant')
            .setField(Case.Previous_Queue__c, testGroup.Id)
            .setField(Case.OwnerId, getTestRunUser().Id)
            .setField(Case.Status, 'Open')
            .setField(Case.CreatedDate, System.today())
            .toSObject();

        Case oldCaseRecord = (Case) new Fake(Case.class)
            .setField(Case.Id, fakeCaseId)
            .setField(Case.Disaster_Escalation_Case__c, false)
            .setField(Case.Customer_Type__c, 'Merchant')
            .setField(Case.Previous_Queue__c, testGroup.Id)
            .setField(Case.OwnerId, getTestRunUser().Id)
            .setField(Case.Status, 'New')
            .setField(Case.CreatedDate, System.today())
            .toSObject();

        List<CaseHistory> fakeCaseHistories = new List<CaseHistory>();

        for(Integer index = 0; index < 3; index++){
            CaseHistory ownerChangeHistory = (CaseHistory) new Fake(CaseHistory.class)
                .setField(CaseHistory.Id, Fake.generateId(CaseHistory.class))
                .setField(CaseHistory.DataType, 'EntityId')
                .setField(CaseHistory.Field, 'Owner')
                .setField(CaseHistory.CaseId, fakeCaseId)
                .toSObject();
            fakeCaseHistories.add(ownerChangeHistory);
        }

        for(Integer index = 0; index < 3; index++){
            CaseHistory statusChangeHistory = (CaseHistory) new Fake(CaseHistory.class)
                .setField(CaseHistory.Id, Fake.generateId(CaseHistory.class))
                .setField(CaseHistory.Field, 'Status')
                .setField(CaseHistory.CaseId, fakeCaseId)
                .toSObject();
            fakeCaseHistories.add(statusChangeHistory);
        }

        List<FeedItem> fakeFeedItems = new List<FeedItem>();

        FeedItem ownerChangeHistory = (FeedItem) new Fake(FeedItem.class)
            .setField(FeedItem.Id, Fake.generateId(FeedItem.class))
            .setField(FeedItem.Title, CDdCaseEventHelper.DISASTER_ESC_CASE_FEED_TITLE)
            .setField(FeedItem.Body, String.format(CDdCaseEventHelper.DISASTER_ESC_INBOUND_LIMIT_ERROR,
                new List<Integer>{Integer.valueOf(CDdCaseEventHelper.defaultDPS.Case_Inbound_Limit__c)}))
            .setField(FeedItem.ParentId, fakeCaseId)
            .toSObject();
        fakeFeedItems.add(ownerChangeHistory);

        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork mockUOW = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_ISObjectUnitOfWork.class);
        ICaseHistoriesSelector caseHistorySelectorMock = (ICaseHistoriesSelector) mocks.mock(
            ICaseHistoriesSelector.class
        );
        IFeedItemSelector feedItemSelectorMock = (IFeedItemSelector) mocks.mock(
            IFeedItemSelector.class
        );

        mocks.startStubbing();
        mocks.when(caseHistorySelectorMock.sObjectType()).thenReturn(CaseHistory.SObjectType);
        mocks.when(caseHistorySelectorMock.selectByCaseIdAndFields(new Set<Id>{fakeCaseId}, new Set<String>{'Status', 'Owner'}))
            .thenReturn(fakeCaseHistories);
        mocks.when(feedItemSelectorMock.sObjectType()).thenReturn(FeedItem.SObjectType);
        mocks.when(feedItemSelectorMock.selectTextPostByParentId(new Set<Id>()))
            .thenReturn(new List<FeedItem>());
        mocks.when(feedItemSelectorMock.selectTextPostByParentId(new Set<Id>{fakeCaseId}))
            .thenReturn(fakeFeedItems);
        mocks.stopStubbing();

        Application.UnitofWork.setMock(mockUOW);
        Application.Selector.setMock(caseHistorySelectorMock);
        Application.Selector.setMock(feedItemSelectorMock);

        Test.startTest();
        List<Case_Event__e> caseEvents = CDdCaseEventTriggerHelper.createEvents(CDdCaseEventTriggerHelper.PlatformEventType.CHECK_DISASTER_ESCALATION, new List<Case> {newCaseRecord},
            new Map<Id, Case>{fakeCaseId => oldCaseRecord});
        CDdCaseEventHelper.checkForDisasterPreventionCase(caseEvents);
        
        newCaseRecord.Disaster_Escalation_Case__c = true;
        List<Case_Event__e> updatedCaseEvents = CDdCaseEventTriggerHelper.createEvents(CDdCaseEventTriggerHelper.PlatformEventType.CHECK_DISASTER_ESCALATION, new List<Case> {newCaseRecord},
            new Map<Id, Case>{fakeCaseId => oldCaseRecord});
        CDdCaseEventHelper.checkForDisasterPreventionCase(updatedCaseEvents);
        Test.stopTest();

        ((fflib_ISObjectUnitOfWork) mocks.verify(mockUOW, 2)).commitWork();
        ((fflib_ISObjectUnitOfWork) mocks.verify(mockUOW, 2)).registerDirty(fflib_Match.anySObject());
        ((fflib_ISObjectUnitOfWork) mocks.verify(mockUOW, 2)).registerDirty(fflib_Match.sObjectWith(new Map<SObjectField, Object>{
            Case.Id => fakeCaseId,
            Case.Disaster_Escalation_Case__c => true
        }));
        System.assert(true,'No error should occur - using ffLib mocks.verify as true asserts');
    }
}