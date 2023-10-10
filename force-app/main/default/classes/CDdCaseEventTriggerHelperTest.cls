/**
 * @author Mahesh Chouhan
 * @date June 2023
 * @description Test class for Handler for Case Event Platform Event
 **/
@isTest
public class CDdCaseEventTriggerHelperTest {

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