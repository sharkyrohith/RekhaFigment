/********************************************************************************************************************
* @author Sriram
* @date 11/08/2021
*
* @group Merchant Services
*
* @description Apex test class for Merchant Services configuration
*
**************************************************************************************************************************************/
@isTest
public class CDdMxSxConfigHelperTest {
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
     * @description Test the configuration setup and values returned by the helper class
     */
    @isTest
    public static void testConfiguration() {
        System.runAs (getTestRunUser()) {
            Test.startTest();
            System.assertEquals(true, CDdMxSxConfigHelper.OPPORTUNITY_CLOSE_DATE_CUTOVER != null);
            System.assertEquals(true, CDdMxSxConfigHelper.PLATFORM_EVENT_RETRY_LIMIT != null);
             System.assertEquals(true, CDdMxSxConfigHelper.MX_EQUIPMENTREQUEST_ACCOUNTRECORDTYPES != null);
             System.assertEquals(true, CDdMxSxConfigHelper.MX_EQUIPMENTREQUEST_ORDERPROTOCOL != null);
             System.assertEquals(true, CDdMxSxConfigHelper.MX_EQUIPMENTREQUEST_PROTOCOL_UPGRADE_MAP != null);
             System.assertEquals(true, CDdMxSxConfigHelper.MX_EQUIPMENTREQUEST_RETURNPRODUCT_MAP != null);
             System.assertEquals(true, CDdMxSxConfigHelper.Mx_CASE_ORIGIN_REQUEST_TYPE_MAP != null);
			 System.assertEquals(true, CDdMxSxConfigHelper.MX_DISABLED_SETTING != null);

            Test.stopTest();
        }
    }
    /**
     * @description Test the configuration values for the Opportunity Closed won cutover date logic
     */
    @isTest
    private static void testOpportunityCutoverDateToCreateCases() {
        Test.startTest();
        MxSx_Config__mdt config = [SELECT Id, Opportunity_Close_Date_Cutover__c, Do_Not_Process_Opp_Closed_X_Years_Ago__c
        FROM MxSx_Config__mdt WHERE developerName = :CDdMxSxConfigHelper.DEFAULT_DEVELOPER_NAME LIMIT 1];
        if(config.Do_Not_Process_Opp_Closed_X_Years_Ago__c == null){
            return;
        }
        Date cutOverDateFromOppClosedYears = System.today().addYears(-Integer.valueOf(config.Do_Not_Process_Opp_Closed_X_Years_Ago__c));
        Date cutOverDateFromConfig =  config.Opportunity_Close_Date_Cutover__c != null ? config.Opportunity_Close_Date_Cutover__c : System.today();

        Test.stopTest();
        if(cutOverDateFromOppClosedYears > cutOverDateFromConfig){
            System.assertEquals(
                cutOverDateFromOppClosedYears,
                CDdMxSxConfigHelper.OPPORTUNITY_CLOSE_DATE_CUTOVER,
                'Cutover Date to create cases for Opp Closed won should be from Do_Not_Process_Opp_Closed_X_Years_Ago__c field value');
        }else{
            System.assertEquals(
                cutOverDateFromConfig,
                CDdMxSxConfigHelper.OPPORTUNITY_CLOSE_DATE_CUTOVER,
                'Cutover Date to create cases for Opp Closed won should be from Opportunity_Close_Date_Cutover__c field value');
        }
    }
}