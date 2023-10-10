public inherited sharing class ApiLogs extends fflib_SObjects implements IApiLogs {
    public static IApiLogs newInstance(List<API_Log__c> recordList) {
        return (IApiLogs) Application.Domain.newInstance(recordList);
    }

    public static IApiLogs newInstance(Set<Id> recordIdSet) {
        return (IApiLogs) Application.Domain.newInstance(recordIdSet);
    }

    public ApiLogs  (List<API_Log__c> sObjectList) {
        super(sObjectList, Schema.API_Log__c.SObjectType);
    }

    public List<API_Log__c> getApiLogs() {
        return (List<API_Log__c>) getRecords();
    }

    public class Constructor implements fflib_IDomainConstructor {
        public fflib_SObjects construct(List<Object> objectList) {
            return new ApiLogs((List<SObject>) objectList);
        }
    }
}