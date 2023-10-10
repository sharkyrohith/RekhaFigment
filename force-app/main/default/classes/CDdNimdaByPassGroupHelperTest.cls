/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 12/15/2020
*
* @group Nimda ByPass Tool
*
* @description Test class for CDdNimdaByPassGroupHelper          
* 
**************************************************************************************************************************************/
@isTest
public class CDdNimdaByPassGroupHelperTest {
    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    public static final Id SYSTEM_ADMIN_PROFILE_ID;
    static {
        TEST_ROLE_ID = [SELECT Id FROM UserRole WHERE DeveloperName = 'COO'].Id;
        SYSTEM_ADMIN_PROFILE_ID = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;        
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
    @isTest
    static void testGetNimdaFields(){
        System.runAs(getTestRunUser()){
            Test.startTest();
            List<Map<String, String>> nimdaFields = CDdNimdaByPassGroupHelper.getNimdaFields();
            System.assertEquals(true, nimdaFields!=null, 'Expecting nimda fields');
            Test.stopTest();     
        }        
    }            
}