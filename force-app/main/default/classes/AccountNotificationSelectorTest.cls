@isTest
public without sharing class AccountNotificationSelectorTest {

    @testSetup static void testSetup() {
        Account parentAccount = TDdAccountFactory.createAccounts('parentAccountName', 1, 'Parent Account')[0];
        parentAccount.Name = 'test parent';
        parentAccount.Business_Id__c = 12345;
        insert parentAccount;

        Account_Notification__c notification = new Account_Notification__c();
        notification.Account__c = parentAccount.Id;
        notification.Active__c = true;
        notification.Type__c = AccountNotificationsConstants.TYPE_HIGH_RISK_OF_ATO;
        insert notification;
    }

    /**
     * @description Data will be quried once and can be used in test methods
     */
    public class TestContext
    {
        public Id accountId;
        public Id notificationId;
        public TestContext(){
            Account_Notification__c notification = [SELECT Id,Account__c FROM Account_Notification__c WHERE CreatedDate = Today];
            notificationId = notification.Id;
            accountId = notification.Account__c;
        }
    }

    @isTest
    static void testGetActiveAccountNotificationsForAccount() {
        TestContext context = new TestContext();
        Set<String> accountIds = new Set<String>{context.accountId};
        List<Account_Notification__c> returnedNotifications = AccountNotificationSelector.newInstance().getActiveAccountNotificationsForAccount(accountIds);
        System.assertEquals( 1, returnedNotifications.size(),'Query should return 1 record' );
    }

    @isTest
    static void testGetActiveAccountNotificationsForAccountByType() {
        TestContext context = new TestContext();
        Set<String> accountIds = new Set<String>{context.accountId};
        Set<String> types = new Set<String>{ AccountNotificationsConstants.TYPE_HIGH_RISK_OF_ATO};
        List<Account_Notification__c> returnedNotifications = AccountNotificationSelector.newInstance().getActiveAccountNotificationsForAccountByType(accountIds,types);
        System.assertEquals( 1, returnedNotifications.size(),'Query should return 1 record' );
    }

    @isTest
    static void testGetAccountNotificationMessages() {
        Map<String,Account_Notification_Message__mdt> messageMdtMap1 = AccountNotificationSelector.newInstance().getAccountNotificationMessagesByType(true);
        System.assert(!messageMdtMap1.isEmpty(),'Query should return at least 1 cmt record' );

        Map<String,Account_Notification_Message__mdt> messageMdtMap2 = AccountNotificationSelector.newInstance().getAccountNotificationMessagesByType(false);
        System.assert(!messageMdtMap2.isEmpty(),'Query should return at least 1 cmt record' );

        Map<String,Map<String,Account_Notification_Message__mdt>> messageMdtMap3 = AccountNotificationSelector.newInstance().getAccountNotificationMessagesByObject(true);
        System.assert(!messageMdtMap3.isEmpty(),'Query should return at least 1 cmt record' );

        Map<String,Map<String,Account_Notification_Message__mdt>> messageMdtMap4 = AccountNotificationSelector.newInstance().getAccountNotificationMessagesByObject(false);
        System.assert(!messageMdtMap4.isEmpty(),'Query should return at least 1 cmt record' );
    }
}