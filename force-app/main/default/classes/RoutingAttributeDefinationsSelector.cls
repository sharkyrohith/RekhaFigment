public inherited sharing class RoutingAttributeDefinationsSelector extends fflib_SObjectSelector implements IRoutingAttributeDefinationSelector {
     /**
     * @description default constructor for the Routing_Attribute_Defination__mdt Selector class
     * @return  - interface of IRoutingAttributeDefinationSelector
     */
    public static IRoutingAttributeDefinationSelector newInstance() {
        return (IRoutingAttributeDefinationSelector) Application.Selector.newInstance(Routing_Attribute_Defination__mdt.SObjectType);
    }

    /**
     * @description This method is for getting the fields Attribute Based Routing
     * @return List of Schema.SObjectField
     */
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Routing_Attribute_Defination__mdt.Id,
            Routing_Attribute_Defination__mdt.Skill__c,
            Routing_Attribute_Defination__mdt.Skill_Level__c,
            Routing_Attribute_Defination__mdt.Skill_Priority__c,
            Routing_Attribute_Defination__mdt.Routing_Configuration__c,
            Routing_Attribute_Defination__mdt.Additional_Skill__c
        };
    }

     /**
     * @description This method is used for getting Object type
     * @return Schema.SObjectType
     */
    public Schema.SObjectType getSObjectType() {
        return Routing_Attribute_Defination__mdt.SObjectType;
    }

    /**
    * @description This method is used for getting Sobject type Id
    * @param setConfigIds
    * @return List<Routing_Attribute_Defination__mdt>
    */
    public List<Routing_Attribute_Defination__mdt> selectActiveDefinationById(Set<String> setConfigIds) {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('Is_Active__c = true AND Routing_Configuration__c IN :setConfigIds');
        return (List<Routing_Attribute_Defination__mdt>) Database.query(query.toSOQL());
    }

}