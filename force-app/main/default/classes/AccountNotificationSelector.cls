public inherited sharing class AccountNotificationSelector extends fflib_SObjectSelector implements IAccountNotificationSelector {
    /**
    * @description default constructor for the Api Logger Gate selector
    * @return  - interface of ApiLoggerGateSelector
    */
    public static IAccountNotificationSelector newInstance() {
        return (IAccountNotificationSelector) Application.Selector.newInstance(Account_Notification__c.SObjectType);
    }

    /**
    * @description This method is for getting the fields on this object
    * @return List of Schema.SObjectField
    */
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Account_Notification__c.Id,
            Account_Notification__c.Account__c,
            Account_Notification__c.Name,
            Account_Notification__c.Type__c,
            Account_Notification__c.Notifications_Starts_On__c,
            Account_Notification__c.Notification_Expires_On__c,
            Account_Notification__c.Active__c,
            Account_Notification__c.Status__c,
            Account_Notification__c.Severity__c,
            Account_Notification__c.Is_Notification_Dismissable__c
        };
    }

    /**
    * @description This method is used for getting Object type
    * @return Schema.SObjectType
    */
    public Schema.SObjectType getSObjectType() {
        return Account_Notification__c.SObjectType;
    }

    /**
     * @description This method gets all active notifications for an account
     * @param Set<String> accountIds - Account to fetch
     * @return List<Account_Notification__c>
     */
    public List<Account_Notification__c> getActiveAccountNotificationsForAccount(Set<String> accountIds) {
        String query = String.format(
            'select {0} from {1} ' +
            'where Account__c IN :accountIds AND Status__c = \'Active\' ' +
            'order by CreatedDate DESC',
            new List<String> {
                getFieldListString(),
                getSObjectName()
            }
        );
        return (List<Account_Notification__c>) Database.query(query);
    }

    /**
     * @description This method gets all active notifications of a type for an account
     * @param Set<String> accountIds - Accounts to fetch
     * @param Set<String> types - Types of notification to fetch
     * @return List<Account_Notification__c>
     */
    public List<Account_Notification__c> getActiveAccountNotificationsForAccountByType(Set<String> accountIds,Set<String> types) {
        String query = String.format(
            'select {0} from {1} ' +
            'where Account__c IN :accountIds AND Type__c IN :types AND Status__c = \'Active\' ' +
            'order by CreatedDate DESC',
            new List<String> {
                getFieldListString(),
                getSObjectName()
            }
        );
        return (List<Account_Notification__c>) Database.query(query);
    }

    /**
     * @description This method gets notifications messages from custom metadata type
     * @param Boolean useGetAll - If false, we use query as message is long text field
     * @return Map<String,Account_Notification_Message__mdt> where Key is MasterLabel of cmt which matches to Type__c picklist field value.
     */
    public Map<String,Account_Notification_Message__mdt> getAccountNotificationMessagesByType(Boolean useGetAll) {
        return useGetAll ?
            convertAccountNotificationListToTypeMap(Account_Notification_Message__mdt.getAll().values()) :
            convertAccountNotificationListToTypeMap(getAccountNotificationMessagesByQuery());
    }

    /**
     * @description This method gets notifications messages from custom metadata type
     * @param Boolean useGetAll - If false, we use query as message is long text field
     * @return Map<String,Map<String,Account_Notification_Message__mdt>> where Key is Object Name and inner map has the key MasterLabel of cmt which matches to Type__c picklist field value.
    */
    public Map<String,Map<String,Account_Notification_Message__mdt>> getAccountNotificationMessagesByObject(Boolean useGetAll) {
        return useGetAll ?
            convertAccountNotificationListToObjectMap(Account_Notification_Message__mdt.getAll().values()) :
            convertAccountNotificationListToObjectMap(getAccountNotificationMessagesByQuery());
    }

    /**
     * @description This gets the account Notifications messages by query - use if you need message which is long text
     * @return Map<String,Account_Notification_Message__mdt> where Key is MasterLabel of cmt which matches to Type__c picklist field value.
     */
    public List<Account_Notification_Message__mdt> getAccountNotificationMessagesByQuery() {
        return [SELECT MasterLabel,
                       Title__c,
                       Message__c,
                       Is_Notification_Dismissable__c,
                       Notification_Ends_After_Days__c,
                       Notification_Ends_On__c, Object_Names__c
                  FROM Account_Notification_Message__mdt];
    }

    /**
     * @description Convert list of account messages to map where key
     * @param List<Account_Notification_Message__mdt> accountNotificationMessages - list to convert to map
     * @return  Map<String,Map<String,Account_Notification_Message__mdt>> where Key is Object Name and inner map has the key MasterLabel of cmt which matches to Type__c picklist field value.
    */
    private Map<String,Map<String,Account_Notification_Message__mdt>> convertAccountNotificationListToObjectMap(List<Account_Notification_Message__mdt> accountNotificationMessages) {
        Map<String,Map<String,Account_Notification_Message__mdt>> retVal = new Map<String,Map<String,Account_Notification_Message__mdt>>();
        for (Account_Notification_Message__mdt notification : accountNotificationMessages) {
            for (String objectName : notification.Object_Names__c.split('\\,')) {
                if (!retVal.containsKey(objectName)) {
                    retVal.put(objectName, new Map<String,Account_Notification_Message__mdt>());
                }
                retVal.get(objectName).put(notification.MasterLabel,notification);
            }
        }
        return retVal;
    }

    /**
     * @description Convert list of account messages to map where key
     * @param List<Account_Notification_Message__mdt> accountNotificationMessages - list to convert to map
     * @return  Map<String,Account_Notification_Message__mdt> where Key is MasterLabel of cmt which matches to Type__c picklist field value.
    */
    private Map<String,Account_Notification_Message__mdt> convertAccountNotificationListToTypeMap(List<Account_Notification_Message__mdt> accountNotificationMessages) {
        Map<String,Account_Notification_Message__mdt> retVal = new Map<String,Account_Notification_Message__mdt>();
        for (Account_Notification_Message__mdt notification : accountNotificationMessages) {
            retVal.put(notification.MasterLabel,notification);
        }
        return retVal;
    }
}