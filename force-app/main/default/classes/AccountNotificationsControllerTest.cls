@isTest
public without sharing class AccountNotificationsControllerTest {

    @IsTest
    static void testGetActiveNotificationsForAccount_NoAccountProvided(){
        Test.startTest();
        List<AccountNotificationService.AccountNotification> retVal = AccountNotificationsController.getActiveNotificationsForAccount(
            null,null,null
        );
        Test.stopTest();
        System.assertEquals(
            retVal.size(),0,'Retval size is not expected'
        );
    }

    @IsTest
    static void testGetActiveNotificationsForAccount(){

        Id mockAccountId = Fake.generateId( Account.class );

        Account_Notification__c notification = (Account_Notification__c) new Fake(Account_Notification__c.class)
            .setField(Account_Notification__c.Id , Fake.generateId(Account_Notification__c.SObjectType))
            .setField(Account_Notification__c.Account__c,mockAccountId)
            .setField(Account_Notification__c.Active__c , true)
            .setField(Account_Notification__c.Type__c , AccountNotificationsConstants.TYPE_KNOWN_VICTIM_OF_ATO)
            .setField(Account_Notification__c.Notification_Expires_On__c,System.today().addDays(365))
            .setField(Account_Notification__c.Severity__c,'Warning')
            .toSObject();

        Account_Notification_Message__mdt notificationMessage = (Account_Notification_Message__mdt) new Fake(Account_Notification_Message__mdt.class)
            .setField(Account_Notification_Message__mdt.MasterLabel , AccountNotificationsConstants.TYPE_KNOWN_VICTIM_OF_ATO)
            .setField(Account_Notification_Message__mdt.Title__c,'Title')
            .setField(Account_Notification_Message__mdt.Message__c,'Message')
            .toSObject();

        AccountNotificationService.AccountNotification wrapper = new AccountNotificationService.AccountNotification(notification,notificationMessage);

        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IAccountNotificationService serviceMock = (IAccountNotificationService) mocks.mock(
            IAccountNotificationService.class
        );

        Set<String> accountIds = new Set<String>{mockAccountId};
        Set<String> types = new Set<String>{AccountNotificationsConstants.TYPE_KNOWN_VICTIM_OF_ATO};
        Map<String,List<AccountNotificationService.AccountNotification>> serviceReturn = new Map<String,List<AccountNotificationService.AccountNotification>> {
            mockAccountId => new List<AccountNotificationService.AccountNotification>{wrapper}
        };

        mocks.startStubbing();
        mocks.when(serviceMock.getActiveNotificationsForAccount(accountIds,'Case',types)).thenReturn(serviceReturn);
		mocks.stopStubbing();

        Application.SERVICE.setMock(IAccountNotificationService.class, serviceMock);

        Test.startTest();
        List<AccountNotificationService.AccountNotification> retVal = AccountNotificationsController.getActiveNotificationsForAccount(
            mockAccountId,'Case',AccountNotificationsConstants.TYPE_KNOWN_VICTIM_OF_ATO
        );
        Test.stopTest();
        System.assertEquals(
            retVal.size(),1,'Retval size is not expected'
        );
    }
}