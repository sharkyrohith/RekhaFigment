public inherited sharing class MxpBobUpdateRequestSelector extends fflib_SObjectSelector implements IMxpBoBUpdateRequestSelector {
     /**
     * @description default constructor for the MXP BoB Update Request Selector class
     * @return  - interface of IMxpBoBUpdateRequestSelector
     */
    public static IMxpBoBUpdateRequestSelector newInstance() {
        return (IMxpBoBUpdateRequestSelector) Application.Selector.newInstance(MXP_BoB_Update_Request__c.SObjectType);
    }

    /**
     * @description This method is for getting the fields on account object
     * @return List of Schema.SObjectField
     */
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            MXP_BoB_Update_Request__c.Id,
            MXP_BoB_Update_Request__c.Name,
            MXP_BoB_Update_Request__c.RecordTypeId,
            MXP_BoB_Update_Request__c.MXP__c,
            MXP_BoB_Update_Request__c.Previous_MXP__c,
            MXP_BoB_Update_Request__c.New_MXP__c,
            MXP_BoB_Update_Request__c.Merchant__c,
            MXP_BoB_Update_Request__c.Status__c,
            MXP_BoB_Update_Request__c.Business_Id__c
        };
    }

    /**
     * @description This method is used for getting Object type
     * @return Schema.SObjectType
     */
    public Schema.SObjectType getSObjectType() {
        return MXP_BoB_Update_Request__c.SObjectType;
    }

    /**
     * @description This method is used for getting Sobject type Id
     * @param idSet
     * @return List<MXP_BoB_Update_Request__c>
     */
    public List<MXP_BoB_Update_Request__c> selectById(Set<Id> idSet) {
        return (List<MXP_BoB_Update_Request__c>) selectSObjectsById(idSet);
    }

    /**
     * @description This method is used for getting Sobject type Id
     * @param recordIds
     * @return List<MXP_BoB_Update_Request__c>
     */
    public List<MXP_BoB_Update_Request__c> selectById(Set<String> recordIds) {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('Id IN :recordIds');
        return (List<MXP_BoB_Update_Request__c>) Database.query(query.toSOQL());
    }

     /**
     * @description This method is used for getting Sobject type Id
     * @param recordIds
     * @return List<MXP_BoB_Update_Request__c>
     */
    public List<MXP_BoB_Update_Request__c> selectByIdExtraFields(Set<Id> recordIds) {
        fflib_QueryFactory query = newQueryFactory()
            .selectFields(new Set<String> {
                'RecordType.DeveloperName',
                'CreatedBy.Email',
                'Previous_MXP__r.Name','Previous_MXP__r.Email',
                'New_MXP__r.Email','New_MXP__r.Name',
                'MXP__r.Email','MXP__r.Name'
            })
            .setCondition('Id IN :recordIds');
        return (List<MXP_BoB_Update_Request__c>) Database.query(query.toSOQL());
    }
}