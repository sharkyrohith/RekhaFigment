/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 04/29/2021
*
* @group Nimda S2N
*
* @description  Test class for Apex Helper Class CDdS2NProductPropertyHelper
* 
**************************************************************************************************************************************/
@isTest
public class CDdS2NProductPropertyHelperTest {
    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    static {
        TEST_ROLE_ID = [SELECT Id FROM UserRole WHERE DeveloperName = 'COO'].Id;
    }
    /**
     * @description Prepare and return the test running user
     */
    private static User getTestRunUser() {
        User testRunUser = null;
        for (User u : [SELECT Id FROM User WHERE UserName = :TEST_DD_RUN_USERNAME]){
            testRunUser = u;
        }
        if (testRunUser == null){
            testRunUser = TDdAccountFactory.createUsers(1, null, TEST_ROLE_ID)[0];
            testRunUser.Username = TEST_DD_RUN_USERNAME;
        }
        return testRunUser;
    }
   /** 
    * @description Test method convertToAPIType
    */
    @isTest
    public static void testConvertToAPIType() {
        System.runAs (getTestRunUser()) {
            Test.startTest();
            System.assertEquals(null, CDdS2NProductPropertyHelper.convertToAPIType('is_consumer_subscription_eligible', null,'USD'));
            System.assertEquals(315, CDdS2NProductPropertyHelper.convertToAPIType('custom_delivery_fee', 3.15,'USD'));
            System.assertEquals('true', CDdS2NProductPropertyHelper.convertToAPIType('offers_pickup', true,'USD'));
            System.assertEquals('false', CDdS2NProductPropertyHelper.convertToAPIType('offers_delivery', false,'USD'));
            System.assertEquals(315, CDdS2NProductPropertyHelper.convertToAPIType('weekly_tablet_subscription_fee', 315,'JPY'));
            Test.stopTest();
        }
    }  
}