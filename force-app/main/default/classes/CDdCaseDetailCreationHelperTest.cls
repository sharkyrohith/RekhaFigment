/**
 * CDdCaseDetailCreationHelperTest
 *
 * @author     Nayana
 * @date       03/09/2022
 * @decription Test class for CDdCaseDetailCreationHelperTest
 */
@isTest(seeAllData=false)
public with sharing class CDdCaseDetailCreationHelperTest {
    static {
        CDdCaseDetailCreationHelper.configsForTest = 
        [SELECT  Id, DeveloperName, Is_Active__c,Filter_Logic__c,Is_Test_Record__c,Sort_Order__c,
        (SELECT Id, DeveloperName, Compare_Type__c, Field_API_Name__c,
        Field_Value__c, Is_Active__c, Object_API_Name__c,
        Case_Shadow_Creation_Config__c,Rule_Number__c
        FROM Case_Shadow_Creation_Criteria__r WHERE Is_Active__c = TRUE)
        FROM Case_Shadow_Creation_Config__mdt 
        WHERE Is_Active__c = TRUE AND Is_Test_Record__c = TRUE
        ORDER BY Sort_Order__c ASC];
    }


    /**
     * @author     Nayana
     * @date       03/09/2022
     * @decription test positive scenario where record matches CMT criteria
     * @param   None
     * @return  None
    */
    @isTest
    static void testPositiveScenario() {
        //create Case record
        Case testCase = TDdCaseFactory.createCaseRecords(1, 'Support')[0];
        testCase.Origin	= CDdSupportConstants.CASE_ORIGIN_CHAT;
        Boolean isAutoCreation = CDdCaseDetailCreationHelper.isAutoCreateShadowRecord(testCase);
        System.assertEquals(true, isAutoCreation, 'This should be true as satisfying CMT criteria');
    }

   /**
     * @author     Nayana
     * @date       03/09/2022
     * @decription test negative scenario where record doest not match CMT criteria
     * @param   None
     * @return  None
    */
    @isTest
    static void testNegativeScenario() {
        //create Case record
        Case testCase = TDdCaseFactory.createCaseRecords(1, 'Support')[0];
        testCase.Origin	= CDdSupportConstants.CASE_ORIGIN_PHONE;
        Boolean isAutoCreation = CDdCaseDetailCreationHelper.isAutoCreateShadowRecord(testCase);
        System.assertEquals(false, isAutoCreation, 'This should be false as not satisfying CMT criteria');
    }


    /**
     * @author     Nayana
     * @date       03/09/2022
     * @decription test positive scenario where record does match CMT criteria with filter logic
     * @param   None
     * @return  None
    */
    @isTest
    static void testPositiveScenarioFilterLogic() {
        //create Case record
        Case testCase = TDdCaseFactory.createCaseRecords(1, 'Support')[0];
        testCase.Origin	= CDdSupportConstants.CASE_ORIGIN_CHAT;
        testCase.Status	= CDdSupportConstants.PENDING_STATUS;
        Boolean isAutoCreation = CDdCaseDetailCreationHelper.isAutoCreateShadowRecord(testCase);
        System.assertEquals(true, isAutoCreation, 'This should be true as it is satisfying CMT criteria with Filter logic');
    }

}