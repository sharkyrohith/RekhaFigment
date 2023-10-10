/**
 * @author  Raju L
 * @date    May 2022
 * @description This is the test class for AccountNotification
 */
@isTest
public class AccountNotificationTest {
	@isTest
    private static void testWhenClassInstantiatesThenRun() {
         List<Account_Notification__c> notifications = new List<Account_Notification__c>();
        //IAccounts Instance Creation Call
        AccountNotifications.newInstance(notifications);
        //Default Constructor Call
        AccountNotifications notification = new AccountNotifications(notifications);
        //fflib_IDomainConstructor call
        AccountNotifications.Constructor constructorObject = new AccountNotifications.Constructor();
        constructorObject.construct(notifications);
        System.assertNotEquals(
            AccountNotifications.newInstance(notifications),
            notification,
            'These objects should not be similar'
        );
    }

    @isTest
    private static void testCoverage() {
        Set<Id> ids = new Set<Id>();
        ids.add(Fake.generateId(Account_Notification__c.SObjectType));
        //IAccounts Instance Creation Call
        AccountNotifications.newInstance(ids);
        List<Account_Notification__c> recs = AccountNotifications.newInstance(ids).getRecords();
        System.assertEquals(0, recs.size(), 'Should return empty list');
        List<Account_Notification__c> recs2 = AccountNotifications.newInstance(ids).getAccountNotifications();
        System.assertEquals(0, recs2.size(), 'Should return empty list');
    }
}