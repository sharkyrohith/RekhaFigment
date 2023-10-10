@isTest
public without sharing class CTrAccNotificationSetExpiresOnDateTest {

    @IsTest
    static void testSetExpiresOnDateOnInsertWhenTypeIsKnownVictimOfAto(){
        Id mockAccountId = Fake.generateId( Account.class );
        Id mockAccNotificationId = Fake.generateId(Account_Notification__c.SObjectType);

        List<Account_Notification__c> recList = new List<Account_Notification__c>{(Account_Notification__c) new Fake(Account_Notification__c.class)
            .setField(Account_Notification__c.Id,mockAccNotificationId)
            .setField(Account_Notification__c.Account__c,mockAccountId)
            .setField(Account_Notification__c.Active__c , true)
            .setField(Account_Notification__c.Type__c , AccountNotificationsConstants.TYPE_KNOWN_VICTIM_OF_ATO)
            .toSObject()};

        Map<Id,Account_Notification__c> recOldMap = new Map<Id,Account_Notification__c>{
            mockAccNotificationId => (Account_Notification__c) new Fake(Account_Notification__c.class)
                .setField(Account_Notification__c.Id,mockAccNotificationId)
                .setField(Account_Notification__c.Account__c,mockAccountId)
                .setField(Account_Notification__c.Active__c , false)
                .setField(Account_Notification__c.Type__c , AccountNotificationsConstants.TYPE_KNOWN_VICTIM_OF_ATO)
                .toSObject()
        };

        CTrAccountNotificationSetExpiresOnDate cls = new CTrAccountNotificationSetExpiresOnDate();
        cls.setTriggerContext('before update',true);
        cls.setMockTriggerList(recList);
        cls.setMockTriggerOldMap(recOldMap);

        cls.setDefaultValuesOnFields();

        System.assert(recList[0].Notification_Expires_On__c != null,'Expires On was not set');
    }

    @IsTest
    static void testSetExpiresOnDateOnInsertWhenTypeIsHighRiskVictimOfAto(){
        Id mockAccountId = Fake.generateId( Account.class );
        Id mockAccNotificationId = Fake.generateId(Account_Notification__c.SObjectType);

        List<Account_Notification__c> recList = new List<Account_Notification__c>{(Account_Notification__c) new Fake(Account_Notification__c.class)
            .setField(Account_Notification__c.Id,mockAccNotificationId)
            .setField(Account_Notification__c.Account__c,mockAccountId)
            .setField(Account_Notification__c.Active__c , true)
            .setField(Account_Notification__c.Type__c , AccountNotificationsConstants.TYPE_HIGH_RISK_OF_ATO)
            .toSObject()};

        Map<Id,Account_Notification__c> recOldMap = new Map<Id,Account_Notification__c>{
            mockAccNotificationId => (Account_Notification__c) new Fake(Account_Notification__c.class)
                .setField(Account_Notification__c.Id,mockAccNotificationId)
                .setField(Account_Notification__c.Account__c,mockAccountId)
                .setField(Account_Notification__c.Active__c , false)
                .setField(Account_Notification__c.Type__c , AccountNotificationsConstants.TYPE_HIGH_RISK_OF_ATO)
                .toSObject()
        };

        CTrAccountNotificationSetExpiresOnDate cls = new CTrAccountNotificationSetExpiresOnDate();
        cls.setTriggerContext('before update',true);
        cls.setMockTriggerList(recList);
        cls.setMockTriggerOldMap(recOldMap);

        cls.setDefaultValuesOnFields();

        System.assert(recList[0].Notification_Expires_On__c != null,'Expires On was not set');

    }

    @IsTest
    static void testSetExpiresOnDateOnInsertWhenTypeIsHighRiskVictimOfAtoWithHypotheticalMsgMetadata(){
        Id mockAccountId = Fake.generateId( Account.class );
        Id mockAccNotificationId = Fake.generateId(Account_Notification__c.SObjectType);

        List<Account_Notification__c> recList = new List<Account_Notification__c>{(Account_Notification__c) new Fake(Account_Notification__c.class)
            .setField(Account_Notification__c.Id,mockAccNotificationId)
            .setField(Account_Notification__c.Account__c,mockAccountId)
            .setField(Account_Notification__c.Active__c , true)
            .setField(Account_Notification__c.Type__c , AccountNotificationsConstants.TYPE_HIGH_RISK_OF_ATO)
            .toSObject()};

        Map<Id,Account_Notification__c> recOldMap = new Map<Id,Account_Notification__c>{
            mockAccNotificationId => (Account_Notification__c) new Fake(Account_Notification__c.class)
                .setField(Account_Notification__c.Id,mockAccNotificationId)
                .setField(Account_Notification__c.Account__c,mockAccountId)
                .setField(Account_Notification__c.Active__c , false)
                .setField(Account_Notification__c.Type__c , AccountNotificationsConstants.TYPE_HIGH_RISK_OF_ATO)
                .toSObject()
        };

        Date endsOn = Date.newInstance(2023, 12, 31);
        Map<String,Account_Notification_Message__mdt> notificationMessagesMap = new Map<String,Account_Notification_Message__mdt>{
            AccountNotificationsConstants.TYPE_HIGH_RISK_OF_ATO => (Account_Notification_Message__mdt) new Fake(Account_Notification_Message__mdt.class)
                .setField(Account_Notification_Message__mdt.MasterLabel , AccountNotificationsConstants.TYPE_HIGH_RISK_OF_ATO)
                .setField(Account_Notification_Message__mdt.Title__c,'Title')
                .setField(Account_Notification_Message__mdt.Message__c,'Message')
                .setField(Account_Notification_Message__mdt.Severity__c,null)
                .setField(Account_Notification_Message__mdt.Notification_Ends_On__c,endsOn)
                .toSObject()
        };

        // create an instance of fflib_ApexMocks class part of apex mock framework.
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        // create an instance of fflib_SObjectUnitOfWork class part of apex mock framework.
        IAccountNotificationSelector notificationSelector = (IAccountNotificationSelector) mocks.mock(
            IAccountNotificationSelector.class
        );

        mocks.startStubbing();
        mocks.when(notificationSelector.sObjectType()).thenReturn(Account_Notification__c.SObjectType);
        mocks.when(notificationSelector.getAccountNotificationMessagesByType(true)).thenReturn(notificationMessagesMap);
        mocks.stopStubbing();

        Application.SELECTOR.setMock(notificationSelector);

        CTrAccountNotificationSetExpiresOnDate cls = new CTrAccountNotificationSetExpiresOnDate();
        cls.setTriggerContext('before update',true);
        cls.setMockTriggerList(recList);
        cls.setMockTriggerOldMap(recOldMap);

        cls.setDefaultValuesOnFields();

        System.assertEquals('Info',recList[0].Severity__c,'Default Severity was not set');
        System.assertEquals(endsOn,recList[0].Notification_Expires_On__c,'Expires on was not correctly set');

    }
}