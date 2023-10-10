public inherited sharing class SessionTimes extends fflib_SObjects implements ISessionTimes {
    public static ISessionTimes newInstance(List<Session_Time__c> recordList) {
        return (ISessionTimes) Application.Domain.newInstance(recordList);
    }

    public static ISessionTimes newInstance(Set<Id> recordIdSet) {
        return (ISessionTimes) Application.Domain.newInstance(recordIdSet);
    }

    public SessionTimes(List<Session_Time__c> sObjectList) {
        super(sObjectList, Schema.Session_Time__c.SObjectType);
    }

    public List<Session_Time__c> getSessionTimes() {
        return (List<Session_Time__c>) getRecords();
    }

    public class Constructor implements fflib_IDomainConstructor {
        public fflib_SObjects construct(List<Object> objectList) {
            return new SessionTimes((List<SObject>) objectList);
        }
    }
}