@isTest
public class AttributeBasedRoutingSettingSelectorTest {
    @testSetup static void testSetup() {
        insert new Attribute_Based_Routing_Setting__c(
            SetupOwnerId = Userinfo.getOrganizationId(),
            Capacity_Weight__c = 5,
            PushTimeout__c = 20,
            Routing_Model__c = 'LeastActive',
            Routing_Priority__c = 1
        );
    }

    @isTest
    static void testGetOrgDefaults() {
        Attribute_Based_Routing_Setting__c routingSetting = AttributeBasedRoutingSettingsSelector.newInstance().getOrgDefaults();
        System.assertNotEquals( null, routingSetting);
    }

    @isTest
    static void testGetInstance() {
        Attribute_Based_Routing_Setting__c routingSetting = AttributeBasedRoutingSettingsSelector.newInstance().getInstance();
        System.assertNotEquals( null, routingSetting);
    }

    @isTest
    static void increaseCodeCoverage() {
        System.assertNotEquals( null, new AttributeBasedRoutingSettingsSelector().getSObjectFieldList());
        System.assertNotEquals( null, new AttributeBasedRoutingSettingsSelector().getSObjectType());
    }

}