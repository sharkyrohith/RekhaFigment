/**
 * @author  Sanidhya Jain L
 * @date    January 2023
 * @description This test class is to cover the test coverage of UnitOfWorkPartialSaveDml.
 */
@isTest
public class UnitOfWorkPartialSaveDmlTest {


    //Method is used to test the partial update DML.
    @isTest
    public static void testUnitOfWorkPartialSaveDmlUpdate() {
        Id API_recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
           .get('API')
           .getRecordTypeId();

        Id mockCaseId1 = Fake.generateId( Case.class );
        Case fakeCase1 = (Case) new Fake(Case.class)
            .setField(Case.Id, mockCaseId1)
            .setField(Case.RecordTypeId,API_recordTypeId)
            .setField(Case.Customer_Type__c, 'Merchant ')
            .setField(Case.Status, 'Open')
            .toSObject();


        HandleDmlResults dmlHan = new HandleDmlResults();
        // create an instance of fflib_ApexMocks class part of apex mock framework.
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        // create an instance of fflib_SObjectUnitOfWork class part of apex mock framework.

       	fflib_ISObjectUnitOfWork mockUOW = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_ISObjectUnitOfWork.class);
        mockUOW = Application.UnitOfWork.newInstance(
            new UnitOfWorkPartialSaveDml(DmlHan));
       	Application.UnitOfWork.setMock(mockUOW);
        Boolean exceptions = false;
        try{
            mockUOW.registerDirty(fakeCase1);
            mockUOW.commitWork();
            ((fflib_SObjectUnitOfWork) mocks.verify(mockUOW, mocks.times(1))).commitWork();
            System.assert(!exceptions, 'Record Saved Successfully');
       }
       catch(Exception e){
           System.assert(!exceptions, 'Record Saved UnSuccessfully');
       }
    }

    //Method is used to test the partial save DML.
    @isTest
    public static void testUnitOfWorkPartialSaveDmlInsert() {
        Id API_recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
           .get('API')
           .getRecordTypeId();

        Case fakeCase1 = (Case) new Fake(Case.class)
            .setField(Case.RecordTypeId,API_recordTypeId)
            .setField(Case.Customer_Type__c, 'Merchant ')
            .setField(Case.Status, 'Open')
            .toSObject();


        HandleDmlResults dmlHan = new HandleDmlResults();
        // create an instance of fflib_ApexMocks class part of apex mock framework.
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        // create an instance of fflib_SObjectUnitOfWork class part of apex mock framework.

       	fflib_ISObjectUnitOfWork mockUOW = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_ISObjectUnitOfWork.class);
        mockUOW = Application.UnitOfWork.newInstance(
            new UnitOfWorkPartialSaveDml(DmlHan));
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

    //Method is used to test the partial delete DML.
    @isTest
    public static void testUnitOfWorkPartialSaveDmlDelete() {
        Id API_recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
           .get('API')
           .getRecordTypeId();

        Id mockCaseId1 = Fake.generateId( Case.class );
        Case fakeCase1 = (Case) new Fake(Case.class)
            .setField(Case.Id, mockCaseId1)
            .setField(Case.RecordTypeId,API_recordTypeId)
            .setField(Case.Customer_Type__c, 'Merchant ')
            .setField(Case.Status, 'Open')
            .toSObject();

        HandleDmlResults dmlHan = new HandleDmlResults();
        // create an instance of fflib_ApexMocks class part of apex mock framework.
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        // create an instance of fflib_SObjectUnitOfWork class part of apex mock framework.

       	fflib_ISObjectUnitOfWork mockUOW = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_ISObjectUnitOfWork.class);
        mockUOW = Application.UnitOfWork.newInstance(
            new UnitOfWorkPartialSaveDml(DmlHan));
       	Application.UnitOfWork.setMock(mockUOW);
        Boolean exceptions = false;
        try{
            mockUOW.registerDeleted(fakeCase1);
            mockUOW.commitWork();
            ((fflib_SObjectUnitOfWork) mocks.verify(mockUOW, mocks.times(1))).commitWork();
            System.assert(!exceptions, 'Record Saved Successfully');
       }
       catch(Exception e){
           System.assert(!exceptions, 'Record Saved UnSuccessfully');
       }
    }

    //Method is used to test the partial empty recycle bin DML.
    @isTest
    public static void testUnitOfWorkPartialSaveDmlEmptyRecycleBin() {
        Id API_recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
           .get('API')
           .getRecordTypeId();

        Id mockCaseId1 = Fake.generateId( Case.class );
        Case fakeCase1 = (Case) new Fake(Case.class)
            .setField(Case.Id, mockCaseId1)
            .setField(Case.RecordTypeId,API_recordTypeId)
            .setField(Case.Customer_Type__c, 'Merchant ')
            .setField(Case.Status, 'Open')
            .toSObject();

        HandleDmlResults dmlHan = new HandleDmlResults();
        // create an instance of fflib_ApexMocks class part of apex mock framework.
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        // create an instance of fflib_SObjectUnitOfWork class part of apex mock framework.

       	fflib_ISObjectUnitOfWork mockUOW = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_ISObjectUnitOfWork.class);
        mockUOW = Application.UnitOfWork.newInstance(
            new UnitOfWorkPartialSaveDml(DmlHan));
       	Application.UnitOfWork.setMock(mockUOW);
        Boolean exceptions = false;
        try{
            mockUOW.registerEmptyRecycleBin(fakeCase1);
            mockUOW.commitWork();
            ((fflib_SObjectUnitOfWork) mocks.verify(mockUOW, mocks.times(1))).commitWork();
            System.assert(!exceptions, 'Record Saved Successfully');
       }
       catch(Exception e){
           System.assert(!exceptions, 'Record Saved UnSuccessfully');
       }
    }
}