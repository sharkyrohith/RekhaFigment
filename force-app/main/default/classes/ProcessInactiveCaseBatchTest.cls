/**
 * @author  Mahesh Chouhan
 * @date    May 2023
 * @description Test class for ProcessInactiveCaseBatch
 */
@isTest
public class ProcessInactiveCaseBatchTest {
    /**
     * @author  Mahesh Chouhan
     * @date    May 2023
     * @description test method to handle cases owned by Inactive users
     */
    @isTest
    public static void testHandleCasesWithInactiveOwnerNoErrorMessage() {
        Apex_Log_Settings__c loggerSettings = Apex_Log_Settings__c.getInstance();
        loggerSettings.Enable_Logging__c = true;
        upsert loggerSettings;
        Id supportRecordTypeId = CDdGenericTriggerOptimizationHelper.supportRecordTypeId;

        User inactiveUser = (User) new Fake(User.class)
            .setFakeId()
            .setField(User.LastName, 'TestUser 1')
            .setField(User.Email, 'puser0001@doordash.com')
            .setField(User.Username, 'puser0001@doordash.com')
            .setField(User.Profile.Name, 'HQ')
            .setField(User.UserRole.Name, 'COO')
            .setField(User.IsActive, false)
            .toSObject();

        User activeUser = (User) new Fake(User.class)
            .setFakeId()
            .setField(User.LastName, 'TestUser 1')
            .setField(User.Email, 'puser0001@doordash.com')
            .setField(User.Username, 'puser0001@doordash.com')
            .setField(User.Profile.Name, 'HQ')
            .setField(User.UserRole.Name, 'COO')
            .setField(User.IsActive, true)
            .toSObject();

        List<Case> lstFakeCase = new List<Case>();
        //Creating Merchant Record
        for(Integer i=0;i<2;i++){
            Id mockCaseId = Fake.generateId( Case.class );
            Case fakeCase = (Case) new Fake(Case.class)
                .setField(Case.Id, mockCaseId)
                .setField(Case.RecordTypeId,supportRecordTypeId)
                .setField(Case.Customer_Type__c, 'Merchant')
                .setField(Case.Status, 'Open')
                .setField(Case.OwnerId, inactiveUser.Id)
                .toSObject();
            lstFakeCase.add(fakeCase);
        }
        //Creating Consumer Record
        for(Integer i=0;i<2;i++){
            Id mockCaseId = Fake.generateId( Case.class );
            Case fakeCase = (Case) new Fake(Case.class)
                .setField(Case.Id, mockCaseId)
                .setField(Case.RecordTypeId, supportRecordTypeId)
                .setField(Case.Customer_Type__c, 'Consumer')
                .setField(Case.Status, 'Waiting for DD Internal Team')
                .setField(Case.OwnerId, activeUser.Id)
                .toSObject();
            lstFakeCase.add(fakeCase);
        }

        // create an instance of fflib_ApexMocks class part of apex mock framework.
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        // create an instance of fflib_SObjectUnitOfWork class part of apex mock framework.
       	fflib_ISObjectUnitOfWork mockUOW = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_ISObjectUnitOfWork.class);
        ICasesSelector mockCaseSelector = (ICasesSelector) mocks.mock(
            ICasesSelector.class
        );
        ICloseOpenCasesRequestService serviceMock = (ICloseOpenCasesRequestService) mocks.mock(ICloseOpenCasesRequestService.class);

        mocks.startStubbing();
            mocks.when(mockCaseSelector.sObjectType()).thenReturn(Case.SObjectType);
            mocks.when(serviceMock.handleCasesWithInactiveOwner(lstFakeCase)).thenReturn(null);
        mocks.stopStubbing();
        Application.UnitOfWork.setMock(mockUOW);
        Application.selector.setMock(mockCaseSelector);
        Application.SERVICE.setMock(ICloseOpenCasesRequestService.class, serviceMock);
        try{
            Test.startTest();
            ProcessInactiveCaseBatch batch = new ProcessInactiveCaseBatch();
            batch.start(null);
            batch.execute(null, lstFakeCase);
            batch.finish(null);
            Test.stopTest();

            List<Apex_Log__c> errorMessages = [SELECT Id FROM Apex_Log__c];
            System.assert(errorMessages.isEmpty(), 'No Apex Log should be created.');
       }
       catch(Exception e){
           System.assert(e instanceof DmlException);
       }
    }

    /**
     * @author  Mahesh Chouhan
     * @date    May 2023
     * @description test method to handle cases owned by Inactive users with Errors
     */
    @isTest
    public static void testHandleCasesWithInactiveOwnerWithErrorMessage() {
        Apex_Log_Settings__c loggerSettings = Apex_Log_Settings__c.getInstance();
        loggerSettings.Enable_Logging__c = true;
        upsert loggerSettings;
        Id supportRecordTypeId = CDdGenericTriggerOptimizationHelper.supportRecordTypeId;

        Date dt = System.today().addDays(-180);

        Id user1Id = Fake.generateId(User.SObjectType);
        User inactiveUser = (User) new Fake(User.class)
            .setFakeId()
            .setField(User.LastName, 'TestUser 1')
            .setField(User.Email, 'puser0001@doordash.com')
            .setField(User.Username, 'puser0001@doordash.com')
            .setField(User.Profile.Name, 'HQ')
            .setField(User.UserRole.Name, 'COO')
            .setField(User.IsActive, false)
            .toSObject();

        User activeUser = (User) new Fake(User.class)
            .setFakeId()
            .setField(User.LastName, 'TestUser 1')
            .setField(User.Email, 'puser0001@doordash.com')
            .setField(User.Username, 'puser0001@doordash.com')
            .setField(User.Profile.Name, 'HQ')
            .setField(User.UserRole.Name, 'COO')
            .setField(User.IsActive, true)
            .toSObject();

        List<Case> lstFakeCase = new List<Case>();
        //Creating Merchant Record
        for(Integer i=0;i<2;i++){
            Id mockCaseId = Fake.generateId( Case.class );
            Case fakeCase = (Case) new Fake(Case.class)
                .setField(Case.Id, mockCaseId)
                .setField(Case.RecordTypeId,supportRecordTypeId)
                .setField(Case.Customer_Type__c, 'Merchant')
                .setField(Case.Status, 'Open')
                .setField(Case.OwnerId, inactiveUser.Id)
                .toSObject();
            lstFakeCase.add(fakeCase);
        }
        //Creating Consumer Record
        for(Integer i=0;i<2;i++){
            Id mockCaseId = Fake.generateId( Case.class );
            Case fakeCase = (Case) new Fake(Case.class)
                .setField(Case.Id, mockCaseId)
                .setField(Case.RecordTypeId,supportRecordTypeId)
                .setField(Case.Customer_Type__c, 'Consumer')
                .setField(Case.Status, 'Waiting for DD Internal Team')
                .setField(Case.OwnerId, activeUser.Id)
                .toSObject();
            lstFakeCase.add(fakeCase);
        }

        // create an instance of fflib_ApexMocks class part of apex mock framework.
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        // create an instance of fflib_SObjectUnitOfWork class part of apex mock framework.
       	fflib_ISObjectUnitOfWork mockUOW = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_ISObjectUnitOfWork.class);
        ICasesSelector mockCaseSelector = (ICasesSelector) mocks.mock(
            ICasesSelector.class
        );
        ICloseOpenCasesRequestService serviceMock1 = (ICloseOpenCasesRequestService) mocks.mock(ICloseOpenCasesRequestService.class);

        mocks.startStubbing();
        	mocks.when(mockCaseSelector.sObjectType()).thenReturn(Case.SObjectType);
        	mocks.when(serviceMock1.handleCasesWithInactiveOwner(lstFakeCase)).thenReturn(new List<String>{'Test Error'});
        mocks.stopStubbing();
        Application.UnitOfWork.setMock(mockUOW);
        Application.selector.setMock(mockCaseSelector);
        Application.SERVICE.setMock(ICloseOpenCasesRequestService.class, serviceMock1);
        try{
            Test.startTest();
            ProcessInactiveCaseBatch batch = new ProcessInactiveCaseBatch();
            batch.start(null);
            batch.execute(null, lstFakeCase);
            batch.finish(null);
            Test.stopTest();

            List<Apex_Log__c> errorMessages = [SELECT Id FROM Apex_Log__c];
            System.assert(!errorMessages.isEmpty(), 'Apex Log should not be created');
       }
       catch(Exception e){
           System.assert(e instanceof DmlException);
       }
    }

    /**
     * @author  Mahesh Chouhan
     * @date    May 2023
     * @description test method to schedule a job
     */
    @IsTest
    public static void testSchedulable() {
        Test.startTest();
        String job_id = System.schedule('ProcessInactiveCaseBatch Test', '20 30 8 10 4 ?', new ProcessInactiveCaseBatch());
        Test.stopTest();
        List<CronTrigger> ct_List = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
                              FROM CronTrigger WHERE id = :job_id];
        System.assert(ct_List.size()>0, 'Schedule job size should be greater then 0');
    }
}