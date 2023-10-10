public inherited sharing class ServiceChannelsSelector extends fflib_SObjectSelector implements IServiceChannelSelector {
     /**
     * @description default constructor for the MXP BoB Update Request Selector class
     * @return  - interface of IServiceChannelSelector
     */
    public static IServiceChannelSelector newInstance() {
        return (IServiceChannelSelector) Application.Selector.newInstance(ServiceChannel.SObjectType);
    }

    /**
     * @description This method is for getting the fields on account object
     * @return List of Schema.SObjectField
     */
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            ServiceChannel.Id,
            ServiceChannel.RelatedEntity
        };
    }

     /**
     * @description This method is used for getting Object type
     * @return Schema.SObjectType
     */
    public Schema.SObjectType getSObjectType() {
        return ServiceChannel.SObjectType;
    }


    /**
     * @description This method is used for getting Service Channel for object
     * Only 1 service channel per object so returning single object
     * @param Entity Name
     * @return ServiceChannel
     */
    public ServiceChannel selectByRelatedEntity(String relatedEntity) {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('RelatedEntity =:relatedEntity');
        return Database.query(query.toSOQL());
    }

}