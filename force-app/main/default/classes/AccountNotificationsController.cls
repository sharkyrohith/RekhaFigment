public with sharing class AccountNotificationsController {
    /**
     * @description Gets All Active Notification for the account
     * @param Set<String> accountIds - Account to fetch
     * @param Set<String> types - types of notifications to fetch (optional, if provided - return is limited to those types, else all active notifications)
     * @return List<AccountNotificationService.AccountNotification> - Set of messages for the account.
     */
    @AuraEnabled(cacheable=true)
    public static List<AccountNotificationService.AccountNotification> getActiveNotificationsForAccount(String accountId,String objectName,String types) {
        if (String.isBlank(accountId)) {
            return new List<AccountNotificationService.AccountNotification>();
        }
        Set<String> typesToFilter = String.isBlank(types) ? new Set<String>() : new Set<String>(types.split('\\,'));
        return AccountNotificationService.getActiveNotificationsForAccount(new Set<String>{accountId}, objectName, typesToFilter).get(accountId);
    }
}