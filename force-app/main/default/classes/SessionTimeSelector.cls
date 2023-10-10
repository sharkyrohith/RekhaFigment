public inherited sharing class SessionTimeSelector extends fflib_SObjectSelector implements ISessionTimeSelector {
    /**
    * @description default constructor for the Session Time Selector class
    * @return  - interface of ISessionTimeSelector
    */
    public static ISessionTimeSelector newInstance() {
        return (ISessionTimeSelector) Application.Selector.newInstance(Session_Time__c.SObjectType);
    }

   /**
    * @description This method is for getting the fields on account object
    * @return List of Schema.SObjectField
    */
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
           Session_Time__c.Id,
           Session_Time__c.Agent__c,
           Session_Time__c.Date__c,
           Session_Time__c.Duration__c,
           Session_Time__c.Case_Status__c,
           Session_Time__c.Omni_Status__c
        };
    }

   /**
    * @description This method is used for getting Object type
    * @return Schema.SObjectType
    */
    public Schema.SObjectType getSObjectType() {
        return Session_Time__c.SObjectType;
    }

   /**
    * @description This method is used for getting Sobject type Id
    * @param idSet
    * @return List<Session_Time__c>
    */
    public List<Session_Time__c> selectById(Set<Id> idSet) {
        return (List<Session_Time__c>) selectSObjectsById(idSet);
    }

    /**
     * @description Get Sessions By Parent Case Id
     * @param recordId <Id> - Parent Case Id
     * @return List<Session_Time__c> - List of sessions related to this case
     */
    public List<Session_Time__c> selectByCaseId(Id recordId) {
        String query = String.format(
            'select {0} from {1} ' +
            'where Case__c = :recordId ' +
            'order by CreatedDate DESC',
            new List<String> {
                getFieldListString() + ',Agent__r.Name',
                getSObjectName()
            }
        );
        return (List<Session_Time__c>) Database.query(query);
    }

    /**
     * @description Gets the total time spent on this case
     * @param recordIds Set<Id> - Parent Case Ids
     * @return List<Aggregate>
     */
    public List<Aggregate> getTotalTimeForCaseId(Set<Id> recordIds) {
        List<AggregateResult> queryResult = [SELECT Case__c,SUM(Duration__c) TotalDuration FROM Session_Time__c WHERE Case__c IN :recordIds GROUP BY Case__c];
        return Aggregate.convertResults(queryResult);
    }
}