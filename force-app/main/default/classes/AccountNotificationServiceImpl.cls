/**
 * @author  Raju L
 * @date    August 2023
 * @description This is the service implementation class for Account notifications Framework
 */
public inherited sharing class AccountNotificationServiceImpl implements IAccountNotificationService {
    /**
     * @description Gets All Active Notification for the account
     * @param Set<String> accountIds - Account to fetch
     * @param String objectName - object to limit records (optional, if provided - return is limited to those types, else all active notifications)
     * @param Set<String> types - types of notifications to fetch (optional, if provided - return is limited to those types, else all active notifications)
     * @return Map<String,List<AccountNotificationService.AccountNotification>> - Key: Acccount Id, Value: Set of messages for that account.
     */
    public Map<String,List<AccountNotificationService.AccountNotification>> getActiveNotificationsForAccount(Set<String> accountIds,String objectName,Set<String> types) {
        Map<String,List<AccountNotificationService.AccountNotification>> retVal = new Map<String,List<AccountNotificationService.AccountNotification>>();
        if (accountIds.isEmpty()) {
            return retVal;
        }
        List<Account_Notification__c> notifications = types.isEmpty() ?
            AccountNotificationSelector.newInstance().getActiveAccountNotificationsForAccount(
                accountIds
            ) :
            AccountNotificationSelector.newInstance().getActiveAccountNotificationsForAccountByType(
                accountIds,types
            );

        Map<String,Account_Notification_Message__mdt> notificationMessagesMap = null;
        if (String.isBlank(objectName)) {
            notificationMessagesMap =  AccountNotificationSelector.newInstance().getAccountNotificationMessagesByType(false);
        } else {
            Map<String,Map<String,Account_Notification_Message__mdt>> notificationMessageByObjectMap =
                AccountNotificationSelector.newInstance().getAccountNotificationMessagesByObject(false);
            notificationMessagesMap = notificationMessageByObjectMap.containsKey(objectName) ?
                notificationMessageByObjectMap.get(objectName) : new Map<String,Account_Notification_Message__mdt>();
        }

        for (Account_Notification__c notification : notifications) {
            Boolean noteMessageExists = notificationMessagesMap.containsKey(notification.Type__c);
            if (noteMessageExists && (types.isEmpty() || types.contains(notification.Type__c))) {
                if (!retVal.containsKey(notification.Account__c)) {
                    retVal.put(notification.Account__c,new List<AccountNotificationService.AccountNotification>());
                }
                retVal.get(notification.Account__c).add(
                    new AccountNotificationService.AccountNotification(notification,notificationMessagesMap.get(notification.Type__c))
                );
            }
        }
        addEmptyMessageForAccountsWhichDontHaveNotifications(retVal,accountIds);
        return retVal;
    }

    private void addEmptyMessageForAccountsWhichDontHaveNotifications(Map<String,List<AccountNotificationService.AccountNotification>> notifMap,Set<String> accountIds) {
        accountIds.removeAll(notifMap.keySet());
        for (String accountId : accountIds) {
            notifMap.put(accountId,new List<AccountNotificationService.AccountNotification>());
        }
    }
}