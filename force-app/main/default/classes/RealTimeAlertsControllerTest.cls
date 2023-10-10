@isTest
public without sharing class RealTimeAlertsControllerTest {
    private static Id caseRecordTypeId = CDdRecordTypeCase.customer();
    @IsTest
    static void testGetRealTimeNotifications_NoAccount() {
        Id mockAccountId = Fake.generateId(Account.class);
        List<RealTimeAlertService.RealTimeAlert> returnValue = new List<RealTimeAlertService.RealTimeAlert>();

        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRealTimeAlertService serviceMock = (IRealTimeAlertService) mocks.mock(IRealTimeAlertService.class);

        mocks.startStubbing();
            mocks.when(serviceMock.getRealTimeAlertsForCase(String.valueOf(mockAccountId))).thenReturn(returnValue);
        mocks.stopStubbing();
        Application.Service.setmock(IRealTimeAlertService.class, serviceMock);

        Test.startTest();
        List<RealTimeAlertService.RealTimeAlert> realTimeAlerts =
            RealTimeAlertsController.getRealTimeAlertsForCase(String.valueOf(mockAccountId));
        Test.stopTest();
        System.assertEquals(realTimeAlerts.size(),0, 'No alerts expected');
    }

    @IsTest
    static void testGetRealTimeNotificationsForAccount_No_Warning(){
        Id mockAccountId = Fake.generateId(Account.class);
        List<RealTimeAlertService.RealTimeAlert> returnValue = new List<RealTimeAlertService.RealTimeAlert>();
        RealTimeAlertService.RealTimeAlert mockValue = new RealTimeAlertService.RealTimeAlert('Warning', 'this is a test title', 'this is a test message', false);
        returnValue.add(mockValue);

        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRealTimeAlertService serviceMock = (IRealTimeAlertService) mocks.mock(IRealTimeAlertService.class);
        mocks.startStubbing();
            mocks.when(serviceMock.getRealTimeAlertsForCase(String.valueOf(mockAccountId))).thenReturn(returnValue);
        mocks.stopStubbing();
        Application.Service.setmock(IRealTimeAlertService.class, serviceMock);

        Test.startTest();
        List<RealTimeAlertService.RealTimeAlert> realTimeAlerts =
            RealTimeAlertsController.getRealTimeAlertsForCase(String.valueOf(mockAccountId));
        Test.stopTest();
        System.assertEquals(1, realTimeAlerts.size(), '1 Alert Expected');

    }
}