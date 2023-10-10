/**
 * @author  Sanidhya Jain
 * @date    January 2023
 * @description This is the test class for CDdCloseOpenCaseOfLastSixMonBatch
 */
@isTest
public class CloseOpenCaseOfLastSixMonBatchTest {
    private static final List<String> CUSTOMER_TYPE = new List<String>{'Consumer','Dasher','Merchant'};
    private static final List<String> REC_TYPE_DEV_NAME = new List<String>{'API','Customer'};
    private static final List<String> CASE_STATUS = new List<String>{'Open','Pending','Waiting for DD Internal Team'};
	private static final List<String> OWNER_LIST = new List<String>{'Legal Claims','Legal Escalations (Japan)','DE - T&S Legal Escalations Queue'};
    private static final Set<String> FIELD_SET = new Set<String>{'Id','Customer_Type__c','Issue_Type__c','Issue__c','Resolution_Type__c','Resolution__c','OwnerId','Status'};

    //Test Method with No error while execution and records should get updated with no error
    @isTest
    public static void testUpdateCaseFromLastSixMonthWithNoErrorMessage() {
        String TOOLS_ADMIN_USER = CDdCustomMetadata.getIdValueFor('Tools_Admin_User');

        Id API_recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
           .get('API')
           .getRecordTypeId();
        Id Support_recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
           .get('Customer')
           .getRecordTypeId();


        Date dt = System.today().addDays(-180);
        Date de = System.today().addDays(-179);

        User user1 = (User) new Fake(User.class)
            .setFakeId()
            .setField(User.LastName, 'TestUser 1')
            .setField(User.Email, 'puser0001@doordash.com')
            .setField(User.Username, 'puser0001@doordash.com')
            .setField(User.Profile.Name, 'HQ')
            .setField(User.UserRole.Name, 'COO')
            .toSObject();

        List<Case> lstFakeCase = new List<Case>();
        //Creating Merchant Record
        for(Integer i=0;i<2;i++){
            Id mockCaseId = Fake.generateId( Case.class );
            Case fakeCase = (Case) new Fake(Case.class)
                .setField(Case.Id, mockCaseId)
                .setField(Case.RecordTypeId,API_recordTypeId)
                .setField(Case.Customer_Type__c, 'Merchant')
                .setField(Case.Status, 'Open')
                .setField(Case.OwnerId, user1.Id)
                .setField(Case.LastModifiedDate, dt)
                .toSObject();
            lstFakeCase.add(fakeCase);
        }
        //Creating Consumer Record
        for(Integer i=0;i<2;i++){
            Id mockCaseId = Fake.generateId( Case.class );
            Case fakeCase = (Case) new Fake(Case.class)
                .setField(Case.Id, mockCaseId)
                .setField(Case.RecordTypeId,API_recordTypeId)
                .setField(Case.Customer_Type__c, 'Consumer')
                .setField(Case.Status, 'Waiting for DD Internal Team')
                .setField(Case.OwnerId, user1.Id)
                .setField(Case.LastModifiedDate, dt)
                .toSObject();
            lstFakeCase.add(fakeCase);
        }
        //Creating Dasher Record
        for(Integer i=0;i<2;i++){
            Id mockCaseId = Fake.generateId( Case.class );
            Case fakeCase = (Case) new Fake(Case.class)
                .setField(Case.Id, mockCaseId)
                .setField(Case.RecordTypeId,Support_recordTypeId)
                .setField(Case.Customer_Type__c, 'Dasher')
                .setField(Case.Status, 'Pending')
                .setField(Case.OwnerId, user1.Id)
                .setField(Case.LastModifiedDate, dt)
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
        	mocks.when(serviceMock1.updateOpenCasestoClose(lstFakeCase)).thenReturn(null);
        mocks.stopStubbing();
        Application.UnitOfWork.setMock(mockUOW);
        Application.selector.setMock(mockCaseSelector);
        Application.SERVICE.setMock(ICloseOpenCasesRequestService.class, serviceMock1);
        try{
            Test.startTest();
            CloseOpenCaseOfLastSixMonBatch batch = new CloseOpenCaseOfLastSixMonBatch();
            batch.start(null);
            batch.execute(null, lstFakeCase);
            batch.finish(null);
            Test.stopTest();
       		System.assert(batch.error_Message.isEmpty(),'As there is No Error while executing Batch, So Error Message Set Should Be Empty');
       }
       catch(Exception e){
           System.assert(e instanceof DmlException);
       }
    }

    //Test Method with Error while execution & update will get fail & return error & create apex log
    @isTest
    public static void testUpdateCaseFromLastSixMonthWithErrorMessage() {
        String TOOLS_ADMIN_USER = CDdCustomMetadata.getIdValueFor('Tools_Admin_User');

        Id API_recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
           .get('API')
           .getRecordTypeId();
        Id Support_recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
           .get('Customer')
           .getRecordTypeId();


        Date dt = System.today().addDays(-180);

        Id user1Id = Fake.generateId(User.SObjectType);
        User user1 = (User) new Fake(User.class)
            .setField(User.Id, user1Id)
            .setField(User.LastName, 'TestUser 1')
            .setField(User.Email, 'puser0001@doordash.com')
            .setField(User.Username, 'puser0001@doordash.com')
            .setField(User.Profile.Name, 'HQ')
            .setField(User.UserRole.Name, 'COO')
            .toSObject();

        List<Case> lstFakeCase = new List<Case>();
        //Creating Merchant Record
        for(Integer i=0;i<2;i++){
            Id mockCaseId = Fake.generateId( Case.class );
            Case fakeCase = (Case) new Fake(Case.class)
                .setField(Case.Id, mockCaseId)
                .setField(Case.RecordTypeId,API_recordTypeId)
                .setField(Case.Customer_Type__c, 'Merchant')
                .setField(Case.Status, 'Open')
                .setField(Case.OwnerId, user1Id)
                .setField(Case.LastModifiedDate, dt)
                .toSObject();
            lstFakeCase.add(fakeCase);
        }
        //Creating Consumer Record
        for(Integer i=0;i<2;i++){
            Id mockCaseId = Fake.generateId( Case.class );
            Case fakeCase = (Case) new Fake(Case.class)
                .setField(Case.Id, mockCaseId)
                .setField(Case.RecordTypeId,API_recordTypeId)
                .setField(Case.Customer_Type__c, 'Consumer')
                .setField(Case.Status, 'Waiting for DD Internal Team')
                .setField(Case.OwnerId, user1Id)
                .setField(Case.LastModifiedDate, dt)
                .toSObject();
            lstFakeCase.add(fakeCase);
        }
        //Creating Dasher Record
        for(Integer i=0;i<2;i++){
            Id mockCaseId = Fake.generateId( Case.class );
            Case fakeCase = (Case) new Fake(Case.class)
                .setField(Case.Id, mockCaseId)
                .setField(Case.RecordTypeId,Support_recordTypeId)
                .setField(Case.Customer_Type__c, 'Dasher')
                .setField(Case.Status, 'Pending')
                .setField(Case.OwnerId, user1Id)
                .setField(Case.LastModifiedDate, dt)
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
        	mocks.when(serviceMock1.updateOpenCasestoClose(lstFakeCase)).thenReturn(new List<String>{'Test Error'});
        mocks.stopStubbing();
        Application.UnitOfWork.setMock(mockUOW);
        Application.selector.setMock(mockCaseSelector);
        Application.SERVICE.setMock(ICloseOpenCasesRequestService.class, serviceMock1);
        try{
            Test.startTest();
            CloseOpenCaseOfLastSixMonBatch batch = new CloseOpenCaseOfLastSixMonBatch();
            batch.start(null);
            batch.execute(null, lstFakeCase);
            batch.finish(null);
            Test.stopTest();
            System.assert(!batch.error_Message.isEmpty(),'As there is Error while executing Batch, So Error Message Set Should Not Be Empty');
       }
       catch(Exception e){
           System.assert(e instanceof DmlException);
       }
    }

    //Test Method to schedule a job
    @IsTest
    public static void testSchedulable() {
        Test.startTest();
        String job_id = System.schedule('CloseOpenCaseOfLastSixMonBatchTest', '20 30 8 10 2 ?', new CloseOpenCaseOfLastSixMonBatch());
        Test.stopTest();
        List<CronTrigger> ct_List = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
                              FROM CronTrigger WHERE id = :job_id];
 		System.assert(ct_List.size()>0, 'Schedule job size should be greater then 0');
    }

}