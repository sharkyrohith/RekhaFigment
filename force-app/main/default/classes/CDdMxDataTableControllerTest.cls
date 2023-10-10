/********************************************************************************************************************
* @author Praveen
* @date 29/06/2022
*
* @group Merchant Services
*
* @description test class for CDdMxDataTableController.
* 
**************************************************************************************************************************************/

@isTest
public with sharing class CDdMxDataTableControllerTest {
    
    
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
    * @description Prepare test data
    */
    @TestSetup
    static void setup() {
        System.runAs(getTestRunUser()){
            Mx_Order__c mxOrder = new Mx_Order__c(Vendor__c = 'Denali');
            insert mxOrder;
            
        }
    }
    /**
    * @description Test check Data Table Results.
    */    
    @isTest
    public static void CheckDataTableResults() {
        System.runAs (getTestRunUser()) {
            Test.startTest();
            Mx_Order__c mxOrd =[select Id from Mx_Order__c limit 1];
            CDdMxDataTableController.DataTableResponse response = CDdMxDataTableController.GetTableColumnData('OrderHistory','Id',mxOrd.Id);
            System.assertEquals(1, response.lstDataTableData.size(), 'Expecting Order record count 1' );
            Test.stopTest();            
        }
    }
    
}