@IsTest
public without sharing class SessionTimeServiceImplTest {

    @IsTest
    static void testCheckAccess(){
        Boolean canViewCaseTimer = FeatureManagement.checkPermission('View_Case_Timer');
        if (!canViewCaseTimer) {
            insert new PermissionSetAssignment(
                PermissionSetId = [SELECT Id FROM PermissionSet WHERE Label = 'View Case Timer User' LIMIT 1].ID,
                AssigneeId = UserInfo.getUserId()
            );
        }

        Test.startTest();
        String accessMsg = SessionTimeService.checkAccess();
        Assert.areEqual(null,accessMsg,'Access Message is not null');
        Test.stopTest();
    }

    @IsTest
    static void testInsertNewSession(){

        // create an instance of fflib_ApexMocks class part of apex mock framework.
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        // create an instance of fflib_SObjectUnitOfWork class part of apex mock framework.
		fflib_ISObjectUnitOfWork mockUOW = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_ISObjectUnitOfWork.class);

        Application.UnitOfWork.setMock(mockUOW);

        Id caseId = Fake.generateId(Case.SObjectType);
        try {
            SessionTimeService.insertNewSession(caseId,100000,'Open','Available',CDdCoreConstants.BLANK_STRING,CDdCoreConstants.BLANK_STRING);
        } catch(Exception e) {
            System.assert(false,'Unexpected Exception: ' + e.getMessage());
        }

        ((fflib_ISObjectUnitOfWork) mocks.verify(mockUOW, mocks.times(1)))
        .registerNew(
            fflib_Match.sObjectWith(
                new Map<SObjectField, Object>{
                    Session_Time__c.Case__c => caseId,
                    Session_Time__c.Date__c => System.today(),
                    Session_Time__c.Duration__c => 100,
                    Session_Time__c.Agent__c => UserINFO.getUserId(),
                    Session_Time__c.Manual_Entry__c  => false,
                    Session_Time__c.Comments__c => null,
                    Session_Time__c.Name => UserINFO.getName() + ' time of 100s on ' + String.valueOf(System.today()),
                    Session_Time__c.Case_Status__c => 'Open',
                    Session_Time__c.Omni_Status__c => 'Available',
                    Session_Time__c.New_Case_Status__c => CDdCoreConstants.BLANK_STRING,
                    Session_Time__c.New_Omni_Status__c => CDdCoreConstants.BLANK_STRING
                }
            )
        );
    }

    @IsTest
    static void testInsertNewSessionManual(){

        // create an instance of fflib_ApexMocks class part of apex mock framework.
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        // create an instance of fflib_SObjectUnitOfWork class part of apex mock framework.
		fflib_ISObjectUnitOfWork mockUOW = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_ISObjectUnitOfWork.class);

        Application.UnitOfWork.setMock(mockUOW);
        String dt = '2023-08-10T00:00:00.000Z';
        Id caseId = Fake.generateId(Case.SObjectType);
        try {
            //(Id caseId, String timeVal, String theDate, String comments, String status, String omniStatus) {
            SessionTimeService.insertNewSessionManual(caseId,'00:01:40',dt,'Comments','Open','Available');
        } catch(Exception e) {
            System.assert(false,'Unexpected Exception: ' + e.getMessage());
        }
        Date d = Date.valueOf(dt);
        ((fflib_ISObjectUnitOfWork) mocks.verify(mockUOW, mocks.times(1)))
        .registerNew(
            fflib_Match.sObjectWith(
                new Map<SObjectField, Object>{
                    Session_Time__c.Case__c => caseId,
                    Session_Time__c.Date__c => d,
                    Session_Time__c.Duration__c => 100,
                    Session_Time__c.Agent__c => UserINFO.getUserId(),
                    Session_Time__c.Manual_Entry__c  => true,
                    Session_Time__c.Comments__c => 'Comments',
                    Session_Time__c.Name => UserINFO.getName() + ' time of 100s on ' + String.valueOf(d),
                    Session_Time__c.Case_Status__c => 'Open',
                    Session_Time__c.Omni_Status__c => 'Available',
                    Session_Time__c.New_Case_Status__c => CDdCoreConstants.BLANK_STRING,
                    Session_Time__c.New_Omni_Status__c => CDdCoreConstants.BLANK_STRING
                }
            )
        );
    }
}