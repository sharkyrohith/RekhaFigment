public interface IAttributeBasedRoutingSettingSelector extends fflib_ISObjectSelector {
    /**
     * @description This method is to get the Org Default of the custom setting
     * @param None
     * @return Attribute_Based_Routing_Setting__c - the Org Default
     */
    Attribute_Based_Routing_Setting__c getOrgDefaults();

    /**
     * @description This method is to get the Instance record of the custom setting
     * @param Non
     * @return Attribute_Based_Routing_Setting__c - the Instance record
     */
    Attribute_Based_Routing_Setting__c getInstance();
}