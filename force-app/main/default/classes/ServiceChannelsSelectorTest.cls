@isTest
public class ServiceChannelsSelectorTest {

    @isTest
    static void testSelectByRelatedEntity() {
        ServiceChannel sChannel = ServiceChannelsSelector.newInstance().selectByRelatedEntity(CDdSupportConstants.CASE_OBJECT_LABEL);
        System.assertNotEquals( null, sChannel);
    }

    @isTest
    static void increaseCodeCoverage() {
        System.assertNotEquals( null, new ServiceChannelsSelector().getSObjectFieldList());
        System.assertNotEquals( null, new ServiceChannelsSelector().getSObjectType());
    }
}