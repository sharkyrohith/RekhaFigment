public interface IAccountNotificationSelector extends fflib_ISObjectSelector {
    /**
     * @description This method gets all active notifications for an account
     * @param Set<String> accountIds - Account to fetch
     * @return List<Account_Notification__c>
     */
    List<Account_Notification__c> getActiveAccountNotificationsForAccount(Set<String> accountIds);

    /**
     * @description This method gets all active notifications of a type for an account
     * @param Set<String> accountIds - Account to fetch
     * @param Set<String> types - Type of notification to fetch
     * @return List<Account_Notification__c>
     */
    List<Account_Notification__c> getActiveAccountNotificationsForAccountByType(Set<String> accountIds,Set<String> types);

    /**
     * @description This method gets notifications messages from custom metadata type.
     * @param Boolean useGetAll - If false, we use query as message is long text field
     * @return Map<String,Account_Notification_Message__mdt> where Key is MasterLabel of cmt which matches to Type__c picklist field value.
     */
    Map<String,Account_Notification_Message__mdt> getAccountNotificationMessagesByType(Boolean useGetAll);

    /**
     * @description This method gets notifications messages from custom metadata type.
     * @param Boolean useGetAll - If false, we use query as message is long text field
     * @return Map<String,Map<String,Account_Notification_Message__mdt>> where Key is Object Name and inner map has the key MasterLabel of cmt which matches to Type__c picklist field value.
    */
    Map<String,Map<String,Account_Notification_Message__mdt>> getAccountNotificationMessagesByObject(Boolean useGetAll);
}