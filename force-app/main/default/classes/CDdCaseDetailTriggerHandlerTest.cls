/**
 * CDdCaseDetailTriggerHandlerTest
 *
 * @author     Nayana
 * @date       03/09/2022
 * @decription Test class for CDdCaseDetailTriggerHandlerTest
 */
@isTest(seeAllData=false)
public with sharing class CDdCaseDetailTriggerHandlerTest {
    /**
     * @author      Nayana
     * @date        Mar 2022
     * @description Data setup method
     */
	@testSetup
    static void testSetup() {
        vCS__c testSettings = new VCS__c();
        testSettings.SetupOwnerId = UserInfo.getOrganizationId();
        testSettings.CaseTrigger__c = true;
        insert testSettings;

        Disable_Trigger_Code__c rec = new Disable_Trigger_Code__c();
        rec.SetupOwnerId = UserInfo.getUserId();
        upsert rec;

        //Insert MXP Account
        Account testAcct = TDdAccountFactory.createAccounts(CDdSupportConstants.NAME_TEST_ACCOUNT,1)[0];
        insert testAcct;

        //Insert the cases for MXP Account
        List<Case> testCaseList = TDdCaseFactory.createCaseRecords(1, CDdSupportConstants.RECORDTYPE_NAME_SUPPORT);
        testCaseList[0].AccountId = testAcct.Id;
        insert testCaseList;
        TDdCaseFactory.getSupportFeatureFlag(true);
    }

     /**
     * @author      Nayana
     * @date        Mar 2022
     * @description Data will be quried once and can be used in test methods
     */
    public class TestContext
    {
        public List<Account> lstAccount;
        public List<Case> lstCase;
        public TestContext(){
            lstCase = [SELECT Id,AccountId,Opportunity_Name__c,Origin,Customer_Type__c,RecordTypeId FROM Case];
            lstAccount = [SELECT Id FROM Account];
        }
    }

     /**
     * @author      Nayana
     * @date        Mar 2022
     * @jira        https://doordash.atlassian.net/browse/BIZS-1051
     * @description tests HandlePrePostSaleCaseEvent
     */
    @isTest
    static void testInsertCaseDetailRec() {
        TestContext context = new TestContext();
        Case_Detail__c cDetail = new Case_Detail__c();
        cDetail.Case__c = context.lstCase[0].Id;
        cDetail.Case_Origin__c = context.lstCase[0].Origin;
        cDetail.Case_Customer_Type__c = context.lstCase[0].Customer_Type__c;
        CDetail.Case_RecordType__c = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeDevNameById(context.lstCase[0].RecordTypeId);
        Test.startTest();
        insert cDetail;
        Test.stopTest();
        cDetail = [SELECT Id,Case_Unique_Id__c FROM Case_Detail__c];
        System.assertEquals(cDetail.Case_Unique_Id__c,context.lstCase[0].Id,'Case Unique Id must be updated');
    }


     /**
     * @author      Nayana
     * @date        Mar 2022
     * @jira        https://doordash.atlassian.net/browse/BIZS-1051
     * @description tests HandlePrePostSaleCaseEvent
     */
    @isTest
    static void testUpdateCaseDetailRec() {
        TestContext context = new TestContext();
        Case_Detail__c cDetail = new Case_Detail__c();
        cDetail.Case__c = context.lstCase[0].Id;
        cDetail.Case_Origin__c = context.lstCase[0].Origin;
        cDetail.Case_Customer_Type__c = context.lstCase[0].Customer_Type__c;
        CDetail.Case_RecordType__c = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeDevNameById(context.lstCase[0].RecordTypeId);
        insert cDetail;
        //Insert new Case for update Scenario
        List<Case> testCaseList = TDdCaseFactory.createCaseRecords(1, CDdSupportConstants.RECORDTYPE_NAME_SUPPORT);
        testCaseList[0].AccountId = context.lstAccount[0].Id;
        insert testCaseList;
        Test.startTest();
        cDetail.Case__c = testCaseList[0].Id;
        update cDetail;
        Test.stopTest();
        cDetail = [SELECT Id,Case_Unique_Id__c FROM Case_Detail__c];
        System.assertEquals(cDetail.Case_Unique_Id__c,testCaseList[0].Id,'Case Unique Id must be updated to new case');
    }
}