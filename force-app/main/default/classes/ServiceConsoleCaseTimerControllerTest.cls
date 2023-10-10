@isTest
public without sharing class ServiceConsoleCaseTimerControllerTest {

    @IsTest
    static void testCheckAccess(){
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        ISessionTimeService serviceMock = (ISessionTimeService) mocks.mock(
            ISessionTimeService.class
        );

        String msg = 'Unable to access Case objects Id field.';
        mocks.startStubbing();
        mocks.when(serviceMock.checkAccess()).thenReturn(msg);
		mocks.stopStubbing();

        Application.SERVICE.setMock(ISessionTimeService.class, serviceMock);

        String receivedMsg = ServiceConsoleCaseTimerController.checkAccess();
        Assert.areEqual(msg, receivedMsg);
    }

    @IsTest
    static void testNewSession(){

        Id mockCaseId = Fake.generateId( Case.class );

        Session_Time__c session = (Session_Time__c) new Fake(Session_Time__c.class)
            .setField(Session_Time__c.Id , Fake.generateId(Session_Time__c.SObjectType))
            .setField(Session_Time__c.Case__c,mockCaseId)
            .setField(Session_Time__c.Date__c , System.today())
            .setField(Session_Time__c.Duration__c , 100)
            .setField(Session_Time__c.Agent__c , UserInfo.getUserId())
            .setField(Session_Time__c.Manual_Entry__c , false)
            .setField(Session_Time__c.Comments__c , null)
            .setField(Session_Time__c.Name , UserINFO.getName() + ' time of 100s on ' + String.valueOf(System.today()) )
            .setField(Session_Time__c.Case_Status__c , 'Open')
            .setField(Session_Time__c.Omni_Status__c , 'Available')
            .setField(Session_Time__c.New_Case_Status__c , CDdCoreConstants.BLANK_STRING)
            .setField(Session_Time__c.New_Omni_Status__c , 'Lunch')
            .toSObject();

        fflib_ApexMocks mocks = new fflib_ApexMocks();
        ISessionTimeService serviceMock = (ISessionTimeService) mocks.mock(
            ISessionTimeService.class
        );

        mocks.startStubbing();
        mocks.when(serviceMock.insertNewSession(mockCaseId,100000,'Open','Available',CDdCoreConstants.BLANK_STRING,'Lunch')).thenReturn(session);
		mocks.stopStubbing();

        Application.SERVICE.setMock(ISessionTimeService.class, serviceMock);

        Session_Time__c receivedSessionTime = ServiceConsoleCaseTimerController.newSession(mockCaseId,100000,'Open','Available',CDdCoreConstants.BLANK_STRING,'Lunch');
        Assert.areEqual(100,receivedSessionTime.Duration__c);
    }

    @isTest
    static void testNewSessionManual(){

        Id mockCaseId = Fake.generateId( Case.class );
        String dt = '2023-08-10T00:00:00.000Z';
        Date d = Date.valueOf(dt);

        Session_Time__c session = (Session_Time__c) new Fake(Session_Time__c.class)
            .setField(Session_Time__c.Id , Fake.generateId(Session_Time__c.SObjectType))
            .setField(Session_Time__c.Case__c,mockCaseId)
            .setField(Session_Time__c.Date__c , d)
            .setField(Session_Time__c.Duration__c , 100)
            .setField(Session_Time__c.Agent__c , UserInfo.getUserId())
            .setField(Session_Time__c.Manual_Entry__c , true)
            .setField(Session_Time__c.Comments__c , 'Comment')
            .setField(Session_Time__c.Name , UserINFO.getName() + ' time of 100s on ' + String.valueOf(d) )
            .setField(Session_Time__c.Case_Status__c , 'Open')
            .setField(Session_Time__c.Omni_Status__c , 'Available')
            .setField(Session_Time__c.New_Case_Status__c , CDdCoreConstants.BLANK_STRING)
            .setField(Session_Time__c.New_Omni_Status__c , CDdCoreConstants.BLANK_STRING)
            .toSObject();

        fflib_ApexMocks mocks = new fflib_ApexMocks();
        ISessionTimeService serviceMock = (ISessionTimeService) mocks.mock(
            ISessionTimeService.class
        );

        mocks.startStubbing();
        mocks.when(serviceMock.insertNewSessionManual(mockCaseId,'00:01:40',dt,'Comment','Open','Available')).thenReturn(session);
		mocks.stopStubbing();

        Application.SERVICE.setMock(ISessionTimeService.class, serviceMock);

        Session_Time__c receivedSessionTime = ServiceConsoleCaseTimerController.newSessionManual(mockCaseId,'00:01:40',dt,'Comment','Open','Available');
        Assert.areEqual(100,receivedSessionTime.Duration__c);
    }

    @IsTest
    static void testGetSessions(){
        Id mockCaseId = Fake.generateId( Case.class );

        Session_Time__c s1 = (Session_Time__c) new Fake(Session_Time__c.class)
            .setField(Session_Time__c.Id , Fake.generateId(Session_Time__c.SObjectType))
            .setField(Session_Time__c.Case__c,mockCaseId)
            .setField(Session_Time__c.Date__c , System.today())
            .setField(Session_Time__c.Duration__c , 100)
            .setField(Session_Time__c.Agent__c , UserInfo.getUserId())
            .setField(Session_Time__c.Manual_Entry__c , false)
            .setField(Session_Time__c.Comments__c , null)
            .setField(Session_Time__c.Name , UserINFO.getName() + ' time of 100s on ' + String.valueOf(System.today()) )
            .setField(Session_Time__c.Case_Status__c , 'Open')
            .setField(Session_Time__c.Omni_Status__c , 'Available')
            .setField(Session_Time__c.New_Case_Status__c , CDdCoreConstants.BLANK_STRING)
            .setField(Session_Time__c.New_Omni_Status__c , 'Lunch')
            .toSObject();

        Session_Time__c s2 = (Session_Time__c) new Fake(Session_Time__c.class)
            .setField(Session_Time__c.Id , Fake.generateId(Session_Time__c.SObjectType))
            .setField(Session_Time__c.Case__c,mockCaseId)
            .setField(Session_Time__c.Date__c , System.today())
            .setField(Session_Time__c.Duration__c , 500)
            .setField(Session_Time__c.Agent__c , UserInfo.getUserId())
            .setField(Session_Time__c.Manual_Entry__c , false)
            .setField(Session_Time__c.Comments__c , null)
            .setField(Session_Time__c.Name , UserINFO.getName() + ' time of 500s on ' + String.valueOf(System.today()) )
            .setField(Session_Time__c.Case_Status__c , 'Open')
            .setField(Session_Time__c.Omni_Status__c , 'Lunch')
            .setField(Session_Time__c.New_Case_Status__c , CDdCoreConstants.BLANK_STRING)
            .setField(Session_Time__c.New_Omni_Status__c , 'Available')
            .toSObject();

        List<Session_Time__c> sessionTimes = new List<Session_Time__c>{s1,s2};

        fflib_ApexMocks mocks = new fflib_ApexMocks();
        // create an instance of fflib_SObjectUnitOfWork class part of apex mock framework.
        ISessionTimeSelector sessionTimesSelectorMock = (ISessionTimeSelector) mocks.mock(
            ISessionTimeSelector.class
        );
        mocks.startStubbing();
        mocks.when(sessionTimesSelectorMock.sObjectType()).thenReturn(Session_Time__c.SObjectType);
        mocks.when(sessionTimesSelectorMock.selectByCaseId(mockCaseId)).thenReturn(sessionTImes);
		mocks.stopStubbing();

        Application.SELECTOR.setMock(sessionTimesSelectorMock);

        List<Session_Time__c> returnedSessionTimes = ServiceConsoleCaseTimerController.getSessions(mockCaseId);
        Assert.areEqual(2,returnedSessionTimes.size());
    }

    @IsTest
    static void testTotalTime(){

        Id mockCaseId = Fake.generateId( Case.class );
        Double totalTime = 300;
        List<Aggregate> aggResultList = new List<Aggregate>{
            new Aggregate(new Map<String,Object> {
                'Case__c' => mockCaseId,
                'TotalDuration' => totalTime
            })
        };

        fflib_ApexMocks mocks = new fflib_ApexMocks();
        // create an instance of fflib_SObjectUnitOfWork class part of apex mock framework.
        ISessionTimeSelector sessionTimesSelectorMock = (ISessionTimeSelector) mocks.mock(
            ISessionTimeSelector.class
        );
        mocks.startStubbing();
        mocks.when(sessionTimesSelectorMock.sObjectType()).thenReturn(Session_Time__c.SObjectType);
        mocks.when(sessionTimesSelectorMock.getTotalTimeForCaseId(new Set<Id>{mockCaseId})).thenReturn(aggResultList);
		mocks.stopStubbing();

        Application.SELECTOR.setMock(sessionTimesSelectorMock);

        Double returnedTotalTime = ServiceConsoleCaseTimerController.totalTime(mockCaseId);
        Assert.areEqual(totalTime,returnedTotalTime);
    }
}