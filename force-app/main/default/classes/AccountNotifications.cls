public inherited sharing class AccountNotifications extends fflib_SObjects implements IAccountNotifications {
    public static IAccountNotifications newInstance(List<Account_Notification__c> recordList) {
        return (IAccountNotifications) Application.Domain.newInstance(recordList);
    }

    public static IAccountNotifications newInstance(Set<Id> recordIdSet) {
        return (IAccountNotifications) Application.Domain.newInstance(recordIdSet);
    }

    public AccountNotifications(List<Account_Notification__c> sObjectList) {
        super(sObjectList, Schema.Account_Notification__c.SObjectType);
    }

    public List<Account_Notification__c> getAccountNotifications() {
        return (List<Account_Notification__c>) getRecords();
    }

    public class Constructor implements fflib_IDomainConstructor {
        public fflib_SObjects construct(List<Object> objectList) {
            return new AccountNotifications((List<SObject>) objectList);
        }
    }
}