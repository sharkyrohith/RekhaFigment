// Service Facade for AccountNotification
public inherited sharing class AccountNotificationService {
    /**
     * @description Gets All Active Notification for the account
     * @param Set<String> accountIds - Account to fetch
     * @param String objectName - object to limit records (optional, if provided - return is limited to those types, else all active notifications)
     * @param Set<String> types - types of notifications to fetch (optional, if provided - return is limited to those types, else all active notifications)
     * @return Map<String,List<AccountNotificationService.AccountNotification>> - Key: Acccount Id, Value: Set of messages for that account.
     */
    public static Map<String,List<AccountNotificationService.AccountNotification>> getActiveNotificationsForAccount(Set<String> accountIds,String objectName,Set<String> types) {
        return service().getActiveNotificationsForAccount(accountIds,objectName,types);
    }

    /**
     * @description It creates instance of AccountNotificationServiceImpl class.
     * @return  - return instance of IAccountNotificationService
     */
    private static IAccountNotificationService service() {
        return (IAccountNotificationService) Application.Service.newInstance(
            IAccountNotificationService.class
        );
    }

    public class AccountNotification {
        @AuraEnabled public String severity {get;set;}
        @AuraEnabled public String title {get;set;}
        @AuraEnabled public String message {get;set;}
        @AuraEnabled public Boolean isDismissable {get;set;}

        public AccountNotification(Account_Notification__c rec,Account_Notification_Message__mdt message) {
            this.severity = rec.Severity__c;
            this.title = message.Title__c;
            this.isDismissable = rec.Is_Notification_Dismissable__c;
            this.message = message.Message__c;
        }
    }
}