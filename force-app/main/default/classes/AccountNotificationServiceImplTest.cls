@isTest
public without sharing class AccountNotificationServiceImplTest {
    @isTest
    static void testGetActiveNotificationsForAccountWhenAccountIsBlank() {
        Map<String,List<AccountNotificationService.AccountNotification>> notificationsMap = AccountNotificationService.getActiveNotificationsForAccount(new Set<String>(),CDdCoreConstants.BLANK_STRING,new Set<String>());
        system.assert(notificationsMap.isEmpty(),'Notification map was not empty');
    }

    @isTest
    static void testGetActiveNotificationsForAccountWhenTypesAndObjectNameIsProvided() {
        Id mockAccountId = Fake.generateId( Account.class );
        Id mockAccountId2 = Fake.generateId( Account.class );

        Set<String> accountIds = new Set<String>{mockAccountId,mockAccountId2};
        Set<String> types = new Set<String>{AccountNotificationsConstants.TYPE_KNOWN_VICTIM_OF_ATO};

        List<Account_Notification__c> notifications = new List<Account_Notification__c>{(Account_Notification__c) new Fake(Account_Notification__c.class)
        .setField(Account_Notification__c.Id , Fake.generateId(Account_Notification__c.SObjectType))
        .setField(Account_Notification__c.Account__c,mockAccountId)
        .setField(Account_Notification__c.Active__c , true)
        .setField(Account_Notification__c.Type__c , AccountNotificationsConstants.TYPE_KNOWN_VICTIM_OF_ATO)
        .setField(Account_Notification__c.Notification_Expires_On__c,System.today().addDays(365))
        .setField(Account_Notification__c.Severity__c,'Warning')
        .toSObject()};

        Map<String,Account_Notification_Message__mdt> notificationMessagesMap = new Map<String,Account_Notification_Message__mdt>{
            AccountNotificationsConstants.TYPE_KNOWN_VICTIM_OF_ATO => (Account_Notification_Message__mdt) new Fake(Account_Notification_Message__mdt.class)
            .setField(Account_Notification_Message__mdt.MasterLabel , AccountNotificationsConstants.TYPE_KNOWN_VICTIM_OF_ATO)
            .setField(Account_Notification_Message__mdt.Title__c,'Title')
            .setField(Account_Notification_Message__mdt.Message__c,'Message')
            .toSObject()
        };

        Map<String,Map<String,Account_Notification_Message__mdt>>  notificationMessagesByObjectMap = new Map<String,Map<String,Account_Notification_Message__mdt>> {
            'Case' => notificationMessagesMap
        };

         // create an instance of fflib_ApexMocks class part of apex mock framework.
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        // create an instance of fflib_SObjectUnitOfWork class part of apex mock framework.
        IAccountNotificationSelector notificationSelector = (IAccountNotificationSelector) mocks.mock(
            IAccountNotificationSelector.class
        );

        mocks.startStubbing();
        mocks.when(notificationSelector.sObjectType()).thenReturn(Account_Notification__c.SObjectType);
        mocks.when(notificationSelector.getActiveAccountNotificationsForAccount(accountIds)).thenReturn(notifications);
        mocks.when(notificationSelector.getActiveAccountNotificationsForAccountByType(accountIds,types)).thenReturn(notifications);
        mocks.when(notificationSelector.getAccountNotificationMessagesByType(false)).thenReturn(notificationMessagesMap);
        mocks.when(notificationSelector.getAccountNotificationMessagesByObject(false)).thenReturn(notificationMessagesByObjectMap);
		mocks.stopStubbing();

        Application.SELECTOR.setMock(notificationSelector);

        Map<String,List<AccountNotificationService.AccountNotification>> notificationsMap = AccountNotificationService.getActiveNotificationsForAccount(accountIds,'Case',types);
        system.assert(!notificationsMap.isEmpty(),'Notification map was empty');
        system.assert(!notificationsMap.get(mockAccountId).isEmpty(),'Expected notification was not found');
        system.assert(notificationsMap.get(mockAccountId2).isEmpty(),'Extra notification was found');
    }

    @isTest
    static void testGetActiveNotificationsForAccountWhenTypesAreNotProvidedButObjectNameIsProvided() {
        Id mockAccountId = Fake.generateId( Account.class );
        Id mockAccountId2 = Fake.generateId( Account.class );

        Set<String> accountIds = new Set<String>{mockAccountId,mockAccountId2};
        Set<String> types = new Set<String>{AccountNotificationsConstants.TYPE_KNOWN_VICTIM_OF_ATO};

        List<Account_Notification__c> notifications = new List<Account_Notification__c>{(Account_Notification__c) new Fake(Account_Notification__c.class)
        .setField(Account_Notification__c.Id , Fake.generateId(Account_Notification__c.SObjectType))
        .setField(Account_Notification__c.Account__c,mockAccountId)
        .setField(Account_Notification__c.Active__c , true)
        .setField(Account_Notification__c.Type__c , AccountNotificationsConstants.TYPE_KNOWN_VICTIM_OF_ATO)
        .setField(Account_Notification__c.Notification_Expires_On__c,System.today().addDays(365))
        .setField(Account_Notification__c.Severity__c,'Warning')
        .toSObject()};

        Map<String,Account_Notification_Message__mdt> notificationMessagesMap = new Map<String,Account_Notification_Message__mdt>{
            AccountNotificationsConstants.TYPE_KNOWN_VICTIM_OF_ATO => (Account_Notification_Message__mdt) new Fake(Account_Notification_Message__mdt.class)
                .setField(Account_Notification_Message__mdt.MasterLabel , AccountNotificationsConstants.TYPE_KNOWN_VICTIM_OF_ATO)
                .setField(Account_Notification_Message__mdt.Title__c,'Title')
                .setField(Account_Notification_Message__mdt.Message__c,'Message')
                .toSObject()
        };

        Map<String,Map<String,Account_Notification_Message__mdt>> notificationMessagesByObjectMap = new Map<String,Map<String,Account_Notification_Message__mdt>> {
            'Case' => notificationMessagesMap
        };

         // create an instance of fflib_ApexMocks class part of apex mock framework.
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        // create an instance of fflib_SObjectUnitOfWork class part of apex mock framework.
        IAccountNotificationSelector notificationSelector = (IAccountNotificationSelector) mocks.mock(
            IAccountNotificationSelector.class
        );

        mocks.startStubbing();
        mocks.when(notificationSelector.sObjectType()).thenReturn(Account_Notification__c.SObjectType);
        mocks.when(notificationSelector.getActiveAccountNotificationsForAccount(accountIds)).thenReturn(notifications);
        mocks.when(notificationSelector.getActiveAccountNotificationsForAccountByType(accountIds,types)).thenReturn(notifications);
        mocks.when(notificationSelector.getAccountNotificationMessagesByType(false)).thenReturn(notificationMessagesMap);
        mocks.when(notificationSelector.getAccountNotificationMessagesByObject(false)).thenReturn(notificationMessagesByObjectMap);
		mocks.stopStubbing();

        Application.SELECTOR.setMock(notificationSelector);

        Map<String,List<AccountNotificationService.AccountNotification>> notificationsMap = AccountNotificationService.getActiveNotificationsForAccount(accountIds,'Case',new Set<String>());
        system.assert(!notificationsMap.isEmpty(),'Notification map was empty');
        system.assert(!notificationsMap.get(mockAccountId).isEmpty(),'Expected notification was not found');
        system.assert(notificationsMap.get(mockAccountId2).isEmpty(),'Extra notification was found');
    }

    @isTest
    static void testGetActiveNotificationsForAccountWhenTypesAreProvidedButObjectNameIsNotProvided() {
        Id mockAccountId = Fake.generateId( Account.class );
        Id mockAccountId2 = Fake.generateId( Account.class );

        Set<String> accountIds = new Set<String>{mockAccountId,mockAccountId2};
        Set<String> types = new Set<String>{AccountNotificationsConstants.TYPE_KNOWN_VICTIM_OF_ATO};

        List<Account_Notification__c> notifications = new List<Account_Notification__c>{(Account_Notification__c) new Fake(Account_Notification__c.class)
        .setField(Account_Notification__c.Id , Fake.generateId(Account_Notification__c.SObjectType))
        .setField(Account_Notification__c.Account__c,mockAccountId)
        .setField(Account_Notification__c.Active__c , true)
        .setField(Account_Notification__c.Type__c , AccountNotificationsConstants.TYPE_KNOWN_VICTIM_OF_ATO)
        .setField(Account_Notification__c.Notification_Expires_On__c,System.today().addDays(365))
        .setField(Account_Notification__c.Severity__c,'Warning')
        .toSObject()};

        Map<String,Account_Notification_Message__mdt> notificationMessagesMap = new Map<String,Account_Notification_Message__mdt>{
            AccountNotificationsConstants.TYPE_KNOWN_VICTIM_OF_ATO => (Account_Notification_Message__mdt) new Fake(Account_Notification_Message__mdt.class)
            .setField(Account_Notification_Message__mdt.MasterLabel , AccountNotificationsConstants.TYPE_KNOWN_VICTIM_OF_ATO)
            .setField(Account_Notification_Message__mdt.Title__c,'Title')
            .setField(Account_Notification_Message__mdt.Message__c,'Message')
            .toSObject()
        };

        Map<String,Map<String,Account_Notification_Message__mdt>>  notificationMessagesByObjectMap = new Map<String,Map<String,Account_Notification_Message__mdt>> {
            'Case' => notificationMessagesMap
        };

         // create an instance of fflib_ApexMocks class part of apex mock framework.
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        // create an instance of fflib_SObjectUnitOfWork class part of apex mock framework.
        IAccountNotificationSelector notificationSelector = (IAccountNotificationSelector) mocks.mock(
            IAccountNotificationSelector.class
        );

        mocks.startStubbing();
        mocks.when(notificationSelector.sObjectType()).thenReturn(Account_Notification__c.SObjectType);
        mocks.when(notificationSelector.getActiveAccountNotificationsForAccount(accountIds)).thenReturn(notifications);
        mocks.when(notificationSelector.getActiveAccountNotificationsForAccountByType(accountIds,types)).thenReturn(notifications);
        mocks.when(notificationSelector.getAccountNotificationMessagesByType(false)).thenReturn(notificationMessagesMap);
        mocks.when(notificationSelector.getAccountNotificationMessagesByObject(false)).thenReturn(notificationMessagesByObjectMap);
		mocks.stopStubbing();

        Application.SELECTOR.setMock(notificationSelector);

        Map<String,List<AccountNotificationService.AccountNotification>> notificationsMap = AccountNotificationService.getActiveNotificationsForAccount(accountIds,null,types);
        system.assert(!notificationsMap.isEmpty(),'Notification map was empty');
        system.assert(!notificationsMap.get(mockAccountId).isEmpty(),'Expected notification was not found');
        system.assert(notificationsMap.get(mockAccountId2).isEmpty(),'Extra notification was found');
    }

    @isTest
    static void testGetActiveNotificationsForAccountWhenTypesAndObjectNameAreNotProvided() {
        Id mockAccountId = Fake.generateId( Account.class );
        Id mockAccountId2 = Fake.generateId( Account.class );

        Set<String> accountIds = new Set<String>{mockAccountId,mockAccountId2};
        Set<String> types = new Set<String>{AccountNotificationsConstants.TYPE_KNOWN_VICTIM_OF_ATO};

        List<Account_Notification__c> notifications = new List<Account_Notification__c>{(Account_Notification__c) new Fake(Account_Notification__c.class)
        .setField(Account_Notification__c.Id , Fake.generateId(Account_Notification__c.SObjectType))
        .setField(Account_Notification__c.Account__c,mockAccountId)
        .setField(Account_Notification__c.Active__c , true)
        .setField(Account_Notification__c.Type__c , AccountNotificationsConstants.TYPE_KNOWN_VICTIM_OF_ATO)
        .setField(Account_Notification__c.Notification_Expires_On__c,System.today().addDays(365))
        .setField(Account_Notification__c.Severity__c,'Warning')
        .toSObject()};

        Map<String,Account_Notification_Message__mdt> notificationMessagesMap = new Map<String,Account_Notification_Message__mdt>{
            AccountNotificationsConstants.TYPE_KNOWN_VICTIM_OF_ATO => (Account_Notification_Message__mdt) new Fake(Account_Notification_Message__mdt.class)
                .setField(Account_Notification_Message__mdt.MasterLabel , AccountNotificationsConstants.TYPE_KNOWN_VICTIM_OF_ATO)
                .setField(Account_Notification_Message__mdt.Title__c,'Title')
                .setField(Account_Notification_Message__mdt.Message__c,'Message')
                .toSObject()
        };

        Map<String,Map<String,Account_Notification_Message__mdt>> notificationMessagesByObjectMap = new Map<String,Map<String,Account_Notification_Message__mdt>> {
            'Case' => notificationMessagesMap
        };

         // create an instance of fflib_ApexMocks class part of apex mock framework.
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        // create an instance of fflib_SObjectUnitOfWork class part of apex mock framework.
        IAccountNotificationSelector notificationSelector = (IAccountNotificationSelector) mocks.mock(
            IAccountNotificationSelector.class
        );

        mocks.startStubbing();
        mocks.when(notificationSelector.sObjectType()).thenReturn(Account_Notification__c.SObjectType);
        mocks.when(notificationSelector.getActiveAccountNotificationsForAccount(accountIds)).thenReturn(notifications);
        mocks.when(notificationSelector.getActiveAccountNotificationsForAccountByType(accountIds,types)).thenReturn(notifications);
        mocks.when(notificationSelector.getAccountNotificationMessagesByType(false)).thenReturn(notificationMessagesMap);
        mocks.when(notificationSelector.getAccountNotificationMessagesByObject(false)).thenReturn(notificationMessagesByObjectMap);
		mocks.stopStubbing();

        Application.SELECTOR.setMock(notificationSelector);

        Map<String,List<AccountNotificationService.AccountNotification>> notificationsMap = AccountNotificationService.getActiveNotificationsForAccount(accountIds,null,new Set<String>());
        system.assert(!notificationsMap.isEmpty(),'Notification map was empty');
        system.assert(!notificationsMap.get(mockAccountId).isEmpty(),'Expected notification was not found');
        system.assert(notificationsMap.get(mockAccountId2).isEmpty(),'Extra notification was found');
    }
}