public interface IAccountNotificationService {
    /**
     * @description Gets All Active Notification for the account
     * @param Set<String> accountIds - Account to fetch
     * @param String objectName - object to limit records (optional, if provided - return is limited to those types, else all active notifications)
     * @param Set<String> types - types of notifications to fetch (optional, if provided - return is limited to those types, else all active notifications)
     * @return Map<String,List<AccountNotificationService.AccountNotification>> - Key: Acccount Id, Value: Set of messages for that account.
     */
    Map<String,List<AccountNotificationService.AccountNotification>> getActiveNotificationsForAccount(Set<String> accountIds,String objectName,Set<String> types);

}