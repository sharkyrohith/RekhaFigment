@isTest
public class ApiLoggerGateSelectorTest {

    @testSetup static void testSetup() {
        insert new API_Logger_Gate__c(
            SetupOwnerId = Userinfo.getOrganizationId(),
            Enable_Sendbird_Logging__c = true,
            Sendbird_Record_Id__c = null,
            Sendbird_Record_Owner_Id__c = null
        );
    }

    @isTest
    static void testGetOrgDefaults() {
        API_Logger_Gate__c gate = ApiLoggerGateSelector.newInstance().getOrgDefaults();
        System.assertNotEquals( null, gate);
    }

    @isTest
    static void testGetInstance() {
        API_Logger_Gate__c gate = ApiLoggerGateSelector.newInstance().getInstance();
        System.assertNotEquals( null, gate);
    }

    @isTest
    static void increaseCodeCoverage() {
        System.assertNotEquals( null, new ApiLoggerGateSelector().getSObjectFieldList());
        System.assertNotEquals( null, new ApiLoggerGateSelector().getSObjectType());
    }
}