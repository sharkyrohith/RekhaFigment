@isTest
public without sharing class ApiLoggerServiceImplTest {
    @IsTest
    static void whenLogIsCalledForSendbirdCreateALog(){
        fflib_ApexMocks mocks = new fflib_ApexMocks();

        // create an instance of fflib_SObjectUnitOfWork class part of apex mock framework.
		IApiLoggerGateSelector gateSelectorMock = (IApiLoggerGateSelector) mocks.mock(IApiLoggerGateSelector.class);

        Id mockCaseId = Fake.generateId( Case.class );
        Id mockOwnerId = Fake.generateId( User.class );
        Api_Logger_Gate__c gate = createApiLoggerGate(true,mockCaseId,mockOwnerId);

        mocks.startStubbing();
        mocks.when(gateSelectorMock.sObjectType()).thenReturn(API_Logger_Gate__c.SObjectType);
        mocks.when(gateSelectorMock.getOrgDefaults()).thenReturn(gate);
		mocks.stopStubbing();

        fflib_SObjectUnitOfWork mockUOW = (fflib_SObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);
        Application.UnitOfWork.setMock(mockUOW);
        Application.selector.setMock(gateSelectorMock);
        Test.startTest();
        ApiLoggerService.log('Sendbird','ApiLoggerServiceImplTest',mockCaseId,mockOwnerId,'ABC','PQR');
        System.assert(true,'No error should occur');
        Test.stopTest();

        verifyInsert(mocks, mockUOW,mockCaseId,mockOwnerId);
    }

    @IsTest
    static void whenLogIsCalledForSomethingOtherThanSendbirdThenDontCreateALog(){
        fflib_ApexMocks mocks = new fflib_ApexMocks();

        // create an instance of fflib_SObjectUnitOfWork class part of apex mock framework.
		IApiLoggerGateSelector gateSelectorMock = (IApiLoggerGateSelector) mocks.mock(IApiLoggerGateSelector.class);

        Id mockCaseId = Fake.generateId( Case.class );
        Id mockOwnerId = Fake.generateId( User.class );
        Api_Logger_Gate__c gate = createApiLoggerGate(true,mockCaseId,mockOwnerId);

        mocks.startStubbing();
        mocks.when(gateSelectorMock.sObjectType()).thenReturn(API_Logger_Gate__c.SObjectType);
        mocks.when(gateSelectorMock.getOrgDefaults()).thenReturn(gate);
		mocks.stopStubbing();

        fflib_SObjectUnitOfWork mockUOW = (fflib_SObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);
        Application.UnitOfWork.setMock(mockUOW);
        Application.selector.setMock(gateSelectorMock);
        Test.startTest();
        ApiLoggerService.log('SomethingOtherThanSendbird','ApiLoggerServiceImplTest',mockCaseId,mockOwnerId,'ABC','PQR');
        System.assert(true,'No error should occur');
        Test.stopTest();

        verifyNoInsert(mocks, mockUOW);
    }

    @isTest
    static void whenLogWithPlatformEventIsCalledForSendbirdThenCreateLogFromPlatformEvent() {
        fflib_ApexMocks mocks = new fflib_ApexMocks();

        // create an instance of fflib_SObjectUnitOfWork class part of apex mock framework.
		IApiLoggerGateSelector gateSelectorMock = (IApiLoggerGateSelector) mocks.mock(IApiLoggerGateSelector.class);

        Id mockCaseId = Fake.generateId( Case.class );
        Id mockOwnerId = Fake.generateId( User.class );
        Api_Logger_Gate__c gate = createApiLoggerGate(true,mockCaseId,mockOwnerId);

        mocks.startStubbing();
        mocks.when(gateSelectorMock.sObjectType()).thenReturn(API_Logger_Gate__c.SObjectType);
        mocks.when(gateSelectorMock.getOrgDefaults()).thenReturn(gate);
		mocks.stopStubbing();

        fflib_SObjectUnitOfWork mockUOW = (fflib_SObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);
        Application.UnitOfWork.setMock(mockUOW);
        Application.selector.setMock(gateSelectorMock);
        Test.startTest();
        List<API_Logger__e> logPEList = new List<API_Logger__e> {
            ApiLoggerService.createApiLoggerEvent('Sendbird','ApiLoggerServiceImplTest',mockCaseId,mockOwnerId,'ABC','PQR')
        };
        ApiLoggerService.log(logPEList);
        System.assert(true,'No error should occur');
        Test.stopTest();

        verifyInsert(mocks, mockUOW,mockCaseId,mockOwnerId);
    }

    @isTest
    static void whenLogWithPlatformEventIsCalledForSomethingOtherThanSendbirdThenDontCreateALog() {
        fflib_ApexMocks mocks = new fflib_ApexMocks();

        // create an instance of fflib_SObjectUnitOfWork class part of apex mock framework.
		IApiLoggerGateSelector gateSelectorMock = (IApiLoggerGateSelector) mocks.mock(IApiLoggerGateSelector.class);

        Id mockCaseId = Fake.generateId( Case.class );
        Id mockOwnerId = Fake.generateId( User.class );
        Api_Logger_Gate__c gate = createApiLoggerGate(true,mockCaseId,mockOwnerId);

        mocks.startStubbing();
        mocks.when(gateSelectorMock.sObjectType()).thenReturn(API_Logger_Gate__c.SObjectType);
        mocks.when(gateSelectorMock.getOrgDefaults()).thenReturn(gate);
		mocks.stopStubbing();

        fflib_SObjectUnitOfWork mockUOW = (fflib_SObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);
        Application.UnitOfWork.setMock(mockUOW);
        Application.selector.setMock(gateSelectorMock);
        Test.startTest();
        List<API_Logger__e> logPEList = new List<API_Logger__e> {
            createApiLoggerEvent('SomethingOtherThanSendbird','ApiLoggerServiceImplTest',mockCaseId,mockOwnerId,'ABC','PQR')
        };
        ApiLoggerService.log(logPEList);
        System.assert(true,'No error should occur');
        Test.stopTest();

        verifyNoInsert(mocks, mockUOW);
    }

    @isTest
    static void whenCreateApiLoggerEventIsCalledForSendbirdThenReturnPlatformEvent() {
        fflib_ApexMocks mocks = new fflib_ApexMocks();

        // create an instance of fflib_SObjectUnitOfWork class part of apex mock framework.
		IApiLoggerGateSelector gateSelectorMock = (IApiLoggerGateSelector) mocks.mock(IApiLoggerGateSelector.class);

        Id mockCaseId = Fake.generateId( Case.class );
        Id mockOwnerId = Fake.generateId( User.class );
        Api_Logger_Gate__c gate = createApiLoggerGate(true,mockCaseId,mockOwnerId);

        mocks.startStubbing();
        mocks.when(gateSelectorMock.sObjectType()).thenReturn(API_Logger_Gate__c.SObjectType);
        mocks.when(gateSelectorMock.getOrgDefaults()).thenReturn(gate);
		mocks.stopStubbing();

        fflib_SObjectUnitOfWork mockUOW = (fflib_SObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);
        Application.UnitOfWork.setMock(mockUOW);
        Application.selector.setMock(gateSelectorMock);
        Test.startTest();
        API_Logger__e evt = ApiLoggerService.createApiLoggerEvent('Sendbird','ApiLoggerServiceImplTest',mockCaseId,mockOwnerId,'ABC','PQR');
        System.assertNotEquals(evt,null,'Platform event object was not returned');
        Test.stopTest();
    }

    @isTest
    static void whenCreateApiLoggerEventIsCalledForSomethingOtherThanSendbirdThenReturnDontPlatformEvent() {
        fflib_ApexMocks mocks = new fflib_ApexMocks();

        // create an instance of fflib_SObjectUnitOfWork class part of apex mock framework.
		IApiLoggerGateSelector gateSelectorMock = (IApiLoggerGateSelector) mocks.mock(IApiLoggerGateSelector.class);

        Id mockCaseId = Fake.generateId( Case.class );
        Id mockOwnerId = Fake.generateId( User.class );
        Api_Logger_Gate__c gate = createApiLoggerGate(true,mockCaseId,mockOwnerId);

        mocks.startStubbing();
        mocks.when(gateSelectorMock.sObjectType()).thenReturn(API_Logger_Gate__c.SObjectType);
        mocks.when(gateSelectorMock.getOrgDefaults()).thenReturn(gate);
		mocks.stopStubbing();

        fflib_SObjectUnitOfWork mockUOW = (fflib_SObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);
        Application.UnitOfWork.setMock(mockUOW);
        Application.selector.setMock(gateSelectorMock);
        Test.startTest();
        API_Logger__e evt = ApiLoggerService.createApiLoggerEvent('SomethingOtherThanSendbird','ApiLoggerServiceImplTest',mockCaseId,mockOwnerId,'ABC','PQR');
        System.assertEquals(evt,null,'Platform event object was returned');
        Test.stopTest();
    }

    @isTest
    static void testShouldLog1() {
        fflib_ApexMocks mocks = new fflib_ApexMocks();

        // create an instance of fflib_SObjectUnitOfWork class part of apex mock framework.
		IApiLoggerGateSelector gateSelectorMock = (IApiLoggerGateSelector) mocks.mock(IApiLoggerGateSelector.class);

        Id mockCaseId = Fake.generateId( Case.class );
        Id mockOwnerId = Fake.generateId( User.class );

        Id mockCaseId2 = Fake.generateId( Case.class );
        Id mockOwnerId2 = Fake.generateId( User.class );

        Api_Logger_Gate__c gate = createApiLoggerGate(true,mockCaseId,mockOwnerId);

        mocks.startStubbing();
        mocks.when(gateSelectorMock.sObjectType()).thenReturn(API_Logger_Gate__c.SObjectType);
        mocks.when(gateSelectorMock.getOrgDefaults()).thenReturn(gate);
		mocks.stopStubbing();
        Application.selector.setMock(gateSelectorMock);

        System.assertEquals(false,ApiLoggerServiceImplHelper.shouldLog('Something other than Sendbird'));
        System.assertEquals(true,ApiLoggerServiceImplHelper.shouldLog('Sendbird'));

        System.assertEquals(false,ApiLoggerServiceImplHelper.shouldLog('Something other than Sendbird',mockCaseId,mockOwnerId));
        System.assertEquals(true,ApiLoggerServiceImplHelper.shouldLog('Sendbird',mockCaseId,mockOwnerId));
        System.assertEquals(false,ApiLoggerServiceImplHelper.shouldLog('Sendbird',mockCaseId2,mockOwnerId2));
        System.assertEquals(false,ApiLoggerServiceImplHelper.shouldLog('Sendbird',mockCaseId,mockOwnerId2));
    }

    @isTest
    static void testShouldLog2() {
        fflib_ApexMocks mocks = new fflib_ApexMocks();

        // create an instance of fflib_SObjectUnitOfWork class part of apex mock framework.
		IApiLoggerGateSelector gateSelectorMock = (IApiLoggerGateSelector) mocks.mock(IApiLoggerGateSelector.class);

        Id mockCaseId = Fake.generateId( Case.class );
        Id mockOwnerId = Fake.generateId( User.class );

        mocks.startStubbing();
        mocks.when(gateSelectorMock.sObjectType()).thenReturn(API_Logger_Gate__c.SObjectType);
        mocks.when(gateSelectorMock.getOrgDefaults()).thenReturn(null);
		mocks.stopStubbing();

        Application.selector.setMock(gateSelectorMock);

        System.assertEquals(false,ApiLoggerServiceImplHelper.shouldLog('Sendbird'));
        System.assertEquals(false,ApiLoggerServiceImplHelper.shouldLog('Sendbird',mockCaseId,mockOwnerId));
    }

    @isTest
    static void testShouldLog3() {
        fflib_ApexMocks mocks = new fflib_ApexMocks();

        // create an instance of fflib_SObjectUnitOfWork class part of apex mock framework.
		IApiLoggerGateSelector gateSelectorMock = (IApiLoggerGateSelector) mocks.mock(IApiLoggerGateSelector.class);

        Id mockCaseId = Fake.generateId( Case.class );
        Id mockOwnerId = Fake.generateId( User.class );

        Api_Logger_Gate__c gate = createApiLoggerGate(false,null,null);

        mocks.startStubbing();
        mocks.when(gateSelectorMock.sObjectType()).thenReturn(API_Logger_Gate__c.SObjectType);
        mocks.when(gateSelectorMock.getOrgDefaults()).thenReturn(gate);
		mocks.stopStubbing();
        Application.selector.setMock(gateSelectorMock);

        System.assertEquals(false,ApiLoggerServiceImplHelper.shouldLog('Sendbird'));
        System.assertEquals(false,ApiLoggerServiceImplHelper.shouldLog('Sendbird',mockCaseId,mockOwnerId));
    }

    @isTest
    static void testApiLoggerEventTrigger() {
        fflib_ApexMocks mocks = new fflib_ApexMocks();

        // create an instance of fflib_SObjectUnitOfWork class part of apex mock framework.
		IApiLoggerGateSelector gateSelectorMock = (IApiLoggerGateSelector) mocks.mock(IApiLoggerGateSelector.class);

        Id mockCaseId = Fake.generateId( Case.class );
        Id mockOwnerId = Fake.generateId( User.class );
        Api_Logger_Gate__c gate = createApiLoggerGate(true,null,null);

        mocks.startStubbing();
        mocks.when(gateSelectorMock.sObjectType()).thenReturn(API_Logger_Gate__c.SObjectType);
        mocks.when(gateSelectorMock.getOrgDefaults()).thenReturn(gate);
		mocks.stopStubbing();

        fflib_SObjectUnitOfWork mockUOW = (fflib_SObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);
        Application.UnitOfWork.setMock(mockUOW);
        Application.selector.setMock(gateSelectorMock);
        Test.startTest();
        List<API_Logger__e> logPEList = new List<API_Logger__e> {
            createApiLoggerEvent('Sendbird','ApiLoggerServiceImplTest',mockCaseId,mockOwnerId,'ABC','PQR')
        };
        EventBus.publish(logPEList);
        System.assert(true,'No error should occur');
        Test.stopTest();

        verifyInsert(mocks, mockUOW,mockCaseId,mockOwnerId);
    }

    public static void verifyInsert(fflib_ApexMocks mocks, fflib_SObjectUnitOfWork mockUOW,String recordId,String recordOwnerId) {
        ((fflib_SObjectUnitOfWork) mocks.verify(mockUOW, mocks.times(1)))
        .registerNew(
            fflib_Match.sObjectWith(
                new Map<SObjectField, Object>{
                    Api_Log__c.Calling_Code__c => 'ApiLoggerServiceImplTest',
                    Api_Log__c.Related_To_Id__c => recordId,
                    Api_Log__c.Related_To_Owner_Id__c => recordOwnerId,
                    Api_Log__c.Request__c => 'ABC',
                    Api_Log__c.Response__c => 'PQR'
                }
            )
        );
    }

    public static void verifyNoInsert(fflib_ApexMocks mocks, fflib_SObjectUnitOfWork mockUOW ) {
        ((fflib_SObjectUnitOfWork) mocks.verify(mockUOW, fflib_ApexMocks.NEVER))
        .registerNew(new Api_Log__c());
    }

    public static Api_Logger_Gate__c createApiLoggerGate(Boolean gateFlag,String recordId,String recordOwnerId) {
        Api_Logger_Gate__c gate = (Api_Logger_Gate__c)new Fake(Api_Logger_Gate__c.class)
            .setFakeId()
            .setField(Api_Logger_Gate__c.Enable_Sendbird_Logging__c,gateFlag)
            .setField(Api_Logger_Gate__c.Sendbird_Record_Id__c,recordId)
            .setField(Api_Logger_Gate__c.Sendbird_Record_Owner_Id__c,recordOwnerId)
            .toSObject();
        return gate;
    }

    public static API_Logger__e createApiLoggerEvent(String productOrToolName,String callingCode,String relatedToId,String relatedToOwnerId,String requestOrLog,String response) {
        return new API_Logger__e(
            Product_Or_Tool_Name__c = productOrToolName,
            Calling_Code__c = callingCode,
            Related_To_Id__c = relatedToId,
            Related_To_Owner_Id__c = relatedToOwnerId,
            Request__c = requestOrLog,
            Response__c = response
        );
    }
}