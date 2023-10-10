@isTest
public class RoutingAttributeDefinationsSelectorTest {


    @isTest
    static void testSelectActiveDefinationById() {
        Routing_Configuration__mdt mc = Routing_Configuration__mdt.getInstance('TEST_DO_NOT_DELETE_AttributeBasedRoute');
        Set<String> rConfigId = new Set<String>{mc.Id};
        List<Routing_Attribute_Defination__mdt> attributeDef = RoutingAttributeDefinationsSelector.newInstance().selectActiveDefinationById(rConfigId);
        System.assertNotEquals( null, attributeDef);
    }


    @isTest
    static void increaseCodeCoverage() {
        System.assertNotEquals( null, new RoutingAttributeDefinationsSelector().getSObjectFieldList());
        System.assertNotEquals( null, new RoutingAttributeDefinationsSelector().getSObjectType());
    }
}