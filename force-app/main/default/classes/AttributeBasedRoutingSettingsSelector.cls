public inherited sharing class AttributeBasedRoutingSettingsSelector extends fflib_SObjectSelector implements IAttributeBasedRoutingSettingSelector {
     /**
     * @description default constructor for the Attribute Based Routing Custom Setting Selector class
     * @return  - interface of IAttributeBasedRoutingSettingSelector
     */
    public static IAttributeBasedRoutingSettingSelector newInstance() {
        return (IAttributeBasedRoutingSettingSelector) Application.Selector.newInstance(Attribute_Based_Routing_Setting__c.SObjectType);
    }

    /**
     * @description This method is for getting the fields Attribute Based Routing
     * @return List of Schema.SObjectField
     */
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Attribute_Based_Routing_Setting__c.Id
        };
    }

     /**
     * @description This method is used for getting Object type
     * @return Schema.SObjectType
     */
    public Schema.SObjectType getSObjectType() {
        return Attribute_Based_Routing_Setting__c.SObjectType;
    }

     /**
     * @description This method is to get the Org Default of the custom setting
     * @param None
     * @return Attribute_Based_Routing_Setting__c - the Org Default
     */
    public Attribute_Based_Routing_Setting__c getOrgDefaults() {
        return Attribute_Based_Routing_Setting__c.getOrgDefaults();
    }

    /**
     * @description This method is to get the Instance record of the custom setting
     * @param None
     * @return Attribute_Based_Routing_Setting__c - the Instance record
     */
    public Attribute_Based_Routing_Setting__c getInstance() {
        return Attribute_Based_Routing_Setting__c.getInstance();
    }

}