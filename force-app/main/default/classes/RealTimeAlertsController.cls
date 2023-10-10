/**
 * @description Gets All Active Notification for the account
 * @param Set<String> accountId - Account to fetch
 * @return List<AccountNotificationService.AccountNotification> - Set of messages for the account.
 */
public with sharing class RealTimeAlertsController {
    @AuraEnabled(cacheable=true)
    public static List<RealTimeAlertService.RealTimeAlert> getRealTimeAlertsForCase(String accountId){
        return RealTimeAlertService.getRealTimeAlertsForCase(accountId);
    }
}