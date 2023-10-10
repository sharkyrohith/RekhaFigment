@IsTest
public without sharing class RealTimeAlertServiceImplTest {
    @IsTest
    static void testWithOneAccountManagementCase() {
        Id mockAccountId = Fake.generateId(Account.class);
        List<Case> fakeCases = getFakeCases(mockAccountId, 1);
        Datetime lookbackdatetime = Datetime.now().addHours(-24);
        Set<Id> recordtypeIds = RealTimeAlertServiceImpl.getSupportRecordTypes();
        Set<String> issueTypes = RealTimeAlertServiceImpl.getAccountManagementIssueTypes();


        fflib_ApexMocks mocks = new fflib_ApexMocks();
        ICasesSelector caseSelector = (ICasesSelector) mocks.mock(ICasesSelector.class);

        mocks.startStubbing();
        mocks.when(caseSelector.selectCasesByAccountIdAndIssueTypeLastnHours(mockAccountId, RealTimeAlertsConstants.LAST_N_HOURS, recordTypeIds, issueTypes)).thenReturn(fakeCases);
        mocks.stopStubbing();

        Application.Selector.setMock(caseSelector);

        List<RealTimeAlertService.RealTimeAlert> returnValue = RealTimeAlertService.getRealTimeAlertsForCase(String.valueOf(mockAccountId));

        System.assertEquals(0, returnValue.size(), 'No Alerts Expected');

    }
    @IsTest
    static void testWithTwoAccountManagementCase() {
        Id mockAccountId = Fake.generateId(Account.class);
        List<Case> fakeCases = getFakeCases(mockAccountId, 2);
        Set<Id> recordtypeIds = RealTimeAlertServiceImpl.getSupportRecordTypes();
        Set<String> issueTypes = RealTimeAlertServiceImpl.getAccountManagementIssueTypes();

        fflib_ApexMocks mocks = new fflib_ApexMocks();
        ICasesSelector caseSelector = (ICasesSelector) mocks.mock(ICasesSelector.class);


        mocks.startStubbing();
        mocks.when(caseSelector.sObjectType()).thenReturn(Case.SObjectType);
        mocks.when(caseSelector.selectCasesByAccountIdAndIssueTypeLastnHours(mockAccountId, 72, recordTypeIds, issueTypes)).thenReturn(fakeCases);
        mocks.stopStubbing();

        Application.Selector.setMock(caseSelector);

        List<RealTimeAlertService.RealTimeAlert> returnValue = RealTimeAlertService.getRealTimeAlertsForCase(String.valueOf(mockAccountId));
        System.assertEquals(1, returnValue.size(), 'One Alerts Expected');
        System.assertEquals('Warning', returnValue[0].severity, 'Expecting Warning severity');

    }
    @IsTest
    static void testWithThreeAccountManagementCase() {
        Id mockAccountId = Fake.generateId(Account.class);
        List<Case> fakeCases = getFakeCases(mockAccountId, 3);
        Datetime lookbackdatetime = Datetime.now().addHours(-24);
        Set<Id> recordtypeIds = RealTimeAlertServiceImpl.getSupportRecordTypes();
        Set<String> issueTypes = RealTimeAlertServiceImpl.getAccountManagementIssueTypes();

        fflib_ApexMocks mocks = new fflib_ApexMocks();
        ICasesSelector caseSelector = (ICasesSelector) mocks.mock(ICasesSelector.class);

        mocks.startStubbing();
        mocks.when(caseSelector.sObjectType()).thenReturn(Case.SObjectType);
        mocks.when(caseSelector.selectCasesByAccountIdAndIssueTypeLastnHours(mockAccountId, 72, recordTypeIds, issueTypes)).thenReturn(fakeCases);
        mocks.stopStubbing();

        Application.Selector.setMock(caseSelector);
        List<RealTimeAlertService.RealTimeAlert> returnValue = RealTimeAlertService.getRealTimeAlertsForCase(String.valueOf(mockAccountId));

        System.assertEquals(1, returnValue.size(), 'One Alerts Expected');
        System.assertEquals('Error', returnValue[0].severity, 'Expecting Error severity');
    }
    private static List<Case> getFakeCases(Id accountId, Integer count) {
        List<Case> fakeCases = new List<Case>();
        Case tempCase;
        for(Integer i=0; i < count; i ++) {
            tempCase = (Case) new Fake(Case.class)
                .setFakeId()
                .setField(Case.Issue_Type__c, CDdSupportConstants.CASE_ISSUE_TYPE_ACCOUNT_MANAGEMENT_CX)
                .setField(Case.RecordTypeId, CDdSchemaUtils.CASE_RT.storefrontOnboardingId())
                .setField(Case.AccountId, accountId)
                .setField(Case.Origin, 'Chat')
                .setField(Case.CreatedDate, Datetime.now().addDays(-1))
                .setField(Case.Subject, 'This is a Test')
                .setField(Case.RecordTypeId, CDdSchemaUtils.CASE_RT.customerId())
                .toSObject();
            fakeCases.add(tempCase);
        }
        return fakeCases;
    }
}