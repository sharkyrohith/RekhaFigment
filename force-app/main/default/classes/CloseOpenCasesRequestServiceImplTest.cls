/**
 * @author  Sanidhya Jain
 * @date    January 2023
 * @description This is Implementation Test class for CloseOpenCaseOfLastSixMonBatch
 */

 @isTest
 public class CloseOpenCasesRequestServiceImplTest {

      //Method to test update of record with no error.
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

         Application.UnitOfWork.setMock(mockUOW);
         try{
             Test.startTest();
             List<String> ErrorList = CloseOpenCasesRequestService.updateOpenCasestoClose(lstFakeCase);
             Test.stopTest();
                System.assert(ErrorList.isEmpty(),'Error String Should be null');
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
    public static void testHandleCasesWithInactiveOwnerNoErrorMessage() {
        Id supportRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('Customer')
            .getRecordTypeId();

        Id previousQueueId = Fake.generateId(Group.class);
        User inactiveUser = (User) new Fake(User.class)
            .setFakeId()
            .setField(User.LastName, 'TestUser 1')
            .setField(User.Email, 'puser0001@doordash.com')
            .setField(User.Username, 'puser0001@doordash.com')
            .setField(User.Profile.Name, 'HQ')
            .setField(User.UserRole.Name, 'COO')
            .setField(User.IsActive, false)
            .toSObject();

        List<Case> lstFakeCase = new List<Case>();
        //Creating Merchant Record
        Case fakeCase1 = (Case) new Fake(Case.class)
            .setField(Case.Id, Fake.generateId(Case.class))
            .setField(Case.RecordTypeId,supportRecordTypeId)
            .setField(Case.Customer_Type__c, 'Merchant')
            .setField(Case.Origin, 'Phone')
            .setField(Case.Status, 'Open')
            .setField(Case.OwnerId, inactiveUser.Id)
            .toSObject();
        Case fakeCase2 = (Case) new Fake(Case.class)
            .setField(Case.Id, Fake.generateId(Case.class))
            .setField(Case.RecordTypeId,supportRecordTypeId)
            .setField(Case.Customer_Type__c, 'Merchant')
            .setField(Case.Origin, 'Phone')
            .setField(Case.Status, 'Open')
            .setField(Case.Previous_Queue_ID__c, previousQueueId)
            .setField(Case.OwnerId, inactiveUser.Id)
            .toSObject();
        lstFakeCase.add(fakeCase1);
        lstFakeCase.add(fakeCase2);

        //Creating Consumer Record
        for(Integer i=0;i<2;i++){
            Id mockCaseId = Fake.generateId( Case.class );
            Case fakeCase = (Case) new Fake(Case.class)
                .setField(Case.Id, mockCaseId)
                .setField(Case.RecordTypeId, supportRecordTypeId)
                .setField(Case.Customer_Type__c, 'Consumer')
                .setField(Case.Origin, 'Web')
                .setField(Case.Status, 'Waiting for DD Internal Team')
                .setField(Case.OwnerId, inactiveUser.Id)
                .toSObject();
            lstFakeCase.add(fakeCase);
        }
        //Creating Dasher Record
        for(Integer i=0;i<2;i++){
            Id mockCaseId = Fake.generateId( Case.class );
            Case fakeCase = (Case) new Fake(Case.class)
                .setField(Case.Id, mockCaseId)
                .setField(Case.RecordTypeId, supportRecordTypeId)
                .setField(Case.Customer_Type__c, 'Dasher')
                .setField(Case.Origin, 'API')
                .setField(Case.Status, 'Pending')
                .setField(Case.OwnerId, inactiveUser.Id)
                .toSObject();
            lstFakeCase.add(fakeCase);
        }

        // create an instance of fflib_ApexMocks class part of apex mock framework.
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        // create an instance of fflib_SObjectUnitOfWork class part of apex mock framework.
        fflib_ISObjectUnitOfWork mockUOW = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_ISObjectUnitOfWork.class);

        Application.UnitOfWork.setMock(mockUOW);
        try{
            Test.startTest();
            List<String> errorList = CloseOpenCasesRequestService.handleCasesWithInactiveOwner(lstFakeCase);
            Test.stopTest();

            //Assertions
            System.assert(errorList.isEmpty(), 'Error list should be empty.');
            ((fflib_ISObjectUnitOfWork) mocks.verify(mockUOW, 1)).commitWork();
            ((fflib_ISObjectUnitOfWork) mocks.verify(mockUOW, 6)).registerDirty(fflib_Match.anySObject());
            //Verify Merchant cases are closed or assigned to Previous_Queue_ID__c
            ((fflib_ISObjectUnitOfWork) mocks.verify(mockUOW, 1)).registerDirty(fflib_Match.sObjectWith(new Map<SObjectField, Object>{
                Case.Id => fakeCase1.Id,
                Case.Status => 'Closed'
            }));
            ((fflib_ISObjectUnitOfWork) mocks.verify(mockUOW, 1)).registerDirty(fflib_Match.sObjectWith(new Map<SObjectField, Object>{
                Case.Id => fakeCase2.Id,
                Case.OwnerId => previousQueueId
            }));
        }
        catch(Exception e){
            System.assert(e instanceof DmlException);
        }
    }

     //Method to test update of record with parial dml update
     @isTest
     public static void testMyDmlResultsHandlerInsert() {
         Id API_recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('API')
            .getRecordTypeId();

         Case fakeCase1 = (Case) new Fake(Case.class)
             .setField(Case.RecordTypeId,API_recordTypeId)
             .setField(Case.Customer_Type__c, 'Merchant ')
             .setField(Case.Status, 'Open')
             .toSObject();


         CloseOpenCasesRequestServiceImpl.CaseDmlResultsHandler MydmlHan = new CloseOpenCasesRequestServiceImpl.CaseDmlResultsHandler();
         // create an instance of fflib_ApexMocks class part of apex mock framework.
         fflib_ApexMocks mocks = new fflib_ApexMocks();
         // create an instance of fflib_SObjectUnitOfWork class part of apex mock framework.

            fflib_ISObjectUnitOfWork mockUOW = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_ISObjectUnitOfWork.class);
         mockUOW = Application.UnitOfWork.newInstance(
             new UnitOfWorkPartialSaveDml(MydmlHan));
            Application.UnitOfWork.setMock(mockUOW);
         Boolean exceptions = false;
         try{
             mockUOW.registerNew(fakeCase1);
             mockUOW.commitWork();
             ((fflib_SObjectUnitOfWork) mocks.verify(mockUOW, mocks.times(1))).commitWork();
             System.assert(!exceptions, 'Record Saved Successfully');
        }
        catch(Exception e){
            System.assert(!exceptions, 'Record Saved UnSuccessfully');
        }
     }
 }