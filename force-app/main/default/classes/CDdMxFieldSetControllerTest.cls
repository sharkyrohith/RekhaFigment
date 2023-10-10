/********************************************************************************************************************
* @author Praveen
* @date 29/06/2022
*
* @group Merchant Services
*
* @description test class for CDdMxFieldSetController.
* 
**************************************************************************************************************************************/


@isTest
public with sharing class CDdMxFieldSetControllerTest {
    
    public static final Id TEST_ROLE_ID;
    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    
    static {
        TEST_ROLE_ID = [SELECT Id FROM UserRole WHERE DeveloperName = 'COO'].Id;
    }
    /**
    * @description Prepare test run user data.
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
    * @description test method for fieldset Validation.
    */    
    static testmethod void testValidFieldSet(){
        System.runAs(getTestRunUser()){
            CDdMxFieldSetController.MetadataResponse metData = CDdMxFieldSetController.getFields('Equipment_Request', 'contact');
            System.assertEquals(true, metData != null, 'Expecting metadata but actual value is null' );
        }
    }
    /**
    * @description test method for fieldset Validation for nonvalid data.
    */    
    static testmethod void testInvalidFieldSet(){
        System.runAs(getTestRunUser()){
            CDdMxFieldSetController.MetadataResponse metData = CDdMxFieldSetController.getFields('Equipment_Reque', 'contact');
            System.assertEquals(metData, null, 'Expecting null but received some other value' );
        }
    }
}