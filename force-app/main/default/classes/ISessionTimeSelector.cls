public interface ISessionTimeSelector extends fflib_ISObjectSelector {
    /**
    * @description This method is used for getting session times
    * @param idSet
    * @return List<Session_Time__c>
    */
    List<Session_Time__c> selectById(Set<Id> idSet);

    /**
     * @description Get Sessions By Parent Case Id
     * @param recordId <Id> - Parent Case Id
     * @return List<Session_Time__c> - List of sessions related to this case
     */
    List<Session_Time__c> selectByCaseId(Id recordId);

    /**
     * @description Gets the total time spent on this case
     * @param recordIds Set<Id> - Parent Case Ids
     * @return List<Aggregate>
     */
    List<Aggregate> getTotalTimeForCaseId(Set<Id> recordIds);
}