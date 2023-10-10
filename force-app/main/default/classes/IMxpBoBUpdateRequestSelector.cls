public interface IMxpBoBUpdateRequestSelector extends fflib_ISObjectSelector {
    /**
     * @description This method id for getting object type
     * @param idSet
     * @return ListMap<MXP_BoB_Update_Request__c> - List MXP_BoB_Update_Request__c
     */
    List<MXP_BoB_Update_Request__c> selectById(Set<Id> idSet);

    /**
     * @description This method is used for getting Sobject type Id
     * @param recordIds
     * @return List<MXP_BoB_Update_Request__c>
     */
    List<MXP_BoB_Update_Request__c> selectById(Set<String> recordIds);

    /**
     * @description This method is used for getting Sobject type Id
     * @param recordIds
     * @return List<MXP_BoB_Update_Request__c>
     */
    List<MXP_BoB_Update_Request__c> selectByIdExtraFields(Set<Id> recordIds);
    
}