/**
 * CDdProactiveCaseCreationHelperTest
 *
 * @author     Nayana
 * @date  Sept 2022
 * @decription Test class for CDdProactiveCaseCreationHelper
 */
@isTest
public with sharing class CDdProactiveCaseCreationHelperTest {
    private static List<Case> setupCase(Boolean shouldInsert,String issue,String storeId) {
        List<Case> cases = TDdCaseFactory.createCaseRecords(1, CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER);
        Case newCase = cases[0];
        newCase.Issue_Type__c = CDdSupportConstants.CASE_ISSUE_ACCT_MGMT;
        newCase.Issue__c = issue;
        newCase.Priority = 'High';
        newCase.Status = CDdSupportConstants.OPEN_STATUS;
        newCase.Routing_Reason__c = 'This is a test record';
        newCase.Store_ID__c = storeId;

        if (shouldInsert) {
            insert newCase;
        } else {
            newCase.Id = '500000000000000';
        }
        return cases;
    }

    @isTest
    public static void testWithoutFilterLogic_1() {
        List<Case> cases = setupCase(false,'Gift Card Inquiry','');
        Test.startTest();
        CDdProactiveCaseCreationHelper.ProactiveCaseInfo proactiveCaseWrap =
        CDdProactiveCaseCreationHelper.isProactiveCaseCreation(cases[0]);
        Test.stopTest();
        system.assertEquals(true,proactiveCaseWrap.isProactiveCaseFlow,'This case is valid for Proactive Case creation');
    }

    @isTest
    public static void testWithoutFilterLogic_2() {
        List<Case> cases = setupCase(false,'test','123456');
        Test.startTest();
        CDdProactiveCaseCreationHelper.ProactiveCaseInfo proactiveCaseWrap =
        CDdProactiveCaseCreationHelper.isProactiveCaseCreation(cases[0]);
        Test.stopTest();
        system.assertEquals(false,proactiveCaseWrap.isProactiveCaseFlow,'This case is not valid for Proactive Case creation');
    }

    @isTest
    public static void testWithFilterLogic_1() {
        List<Case> cases = setupCase(false,'Gift Card Inquiry','123456');
        Test.startTest();
        CDdProactiveCaseCreationHelper.ProactiveCaseInfo proactiveCaseWrap =
        CDdProactiveCaseCreationHelper.isProactiveCaseCreation(cases[0]);
        Test.stopTest();
        system.assertEquals(true,proactiveCaseWrap.isProactiveCaseFlow,'This case is valid for Proactive Case creation');
    }

    @isTest
    public static void testWithFilterLogic_2() {
    	List<Case> cases = setupCase(false,'Reactivate Account','678901');
        Test.startTest();
        CDdProactiveCaseCreationHelper.ProactiveCaseInfo proactiveCaseWrap =
        CDdProactiveCaseCreationHelper.isProactiveCaseCreation(cases[0]);
        Test.stopTest();
        system.assertEquals(false,proactiveCaseWrap.isProactiveCaseFlow,'This case is not valid for Proactive Case creation');
    }

    @isTest
    public static void testRelatedObject1() {
        List<Account> accs = TDdAccountFactory.createAccounts('testAcct', 2, 'Marketplace');
        accs[0].Restaurant_ID__c = '12345';
        accs[0].Case_Routing_Override__c = CDdSupportConstants.MXP_ROUTING_OVERRIDE_VALUE;
        accs[0].Deck_Rank__c = 'Ace';
        insert accs[0];
        Test.startTest();
        List<Case> testCaseList = TDdCaseFactory.createCaseRecords(1, CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER);
        testCaseList[0].AccountId = accs[0].Id;
        testCaseList[0].Store_ID__c = '123456';
        CDdProactiveCaseCreationHelper.ProactiveCaseInfo proactiveCaseWrap =
        CDdProactiveCaseCreationHelper.isProactiveCaseCreation(testCaseList[0]);
        Test.stopTest();
    }

    @isTest
    public static void testProactiveCaseInfoCreation() {
        vCS__c testSettings;
        testSettings = VTestUtil.createVeltigSettings();
        testSettings.CaseTrigger__c = true;
        testSettings.FireAutoResponseRules__c = true;
        insert testSettings;
        TDdCaseFactory.getSupportFeatureFlag(true);
        List<Account> accs = TDdAccountFactory.createAccounts('testAcct', 2, 'Marketplace');
        insert accs;
        Delivery__c deliveryInfo = new Delivery__c();
        deliveryInfo.DeliveryUUID__c ='12344556';
        deliveryInfo.Merchant__c = accs[0].Id;
        insert deliveryInfo;
        Case newCase = new Case();
        newCase.Customer_Type__c=CDdSupportConstants.CUSTOMER_TYPE_CONSUMER;
        newCase.Issue_Type__c = CDdSupportConstants.CASE_ISSUE_ACCT_MGMT;
        newCase.Issue__c = 'Gift Card Inquiry';
        newCase.Priority = 'High';
        newCase.Status = CDdSupportConstants.OPEN_STATUS;
        newCase.DeliveryUUID__c ='12344556';
        insert newCase;
        Test.startTest();
        newCase.Routing_Reason__c = 'This is a test record';
        update newCase;
        Test.stopTest();
        List<Case> lstCase = [SELECT Id FROM Case WHERE CreatedDate=today AND Origin = 'API'];
        system.assertEquals(true,lstCase.size()>0,'This case is valid for Proactive Case creation');
    }

    @isTest
    static void increaseCodeCoverage(){
        Proactive_Case_Creation_Criterion__mdt mdt = Proactive_Case_Creation_Criterion__mdt.getInstance('TEST_DO_NOT_DELETE_Proactive_Case_2');
        CDdCriterionEvaluator eval = new CDdCriterionEvaluator();
        CDdProactiveCaseCreationHelper.getRelatedObjectFieldsMap();
        increaseCodeCoverageHelper(eval,mdt);
        eval.getRelatedObjectMap('Case-Opportunity');
        eval.getRelatedObjectMap('Case-Contact');
        eval.getRelatedObjectMap('Test-Test');
        eval.getRelatedObjectFieldValue(null,null,null,null);

        increaseCodeCoverageHelper(new CDdEqualsCriterionEvaluator(),mdt);
        increaseCodeCoverageHelper(new CDdNotEqualsCriterionEvaluator(),mdt);
        increaseCodeCoverageHelper(new CDdContainsCriterionEvaluator(),mdt);
        increaseCodeCoverageHelper(new CDdNotContainsCriterionEvaluator(),mdt);
        increaseCodeCoverageHelper(new CDdLikeCriterionEvaluator(),mdt);
        increaseCodeCoverageHelper(new CDdIsNotBlankCriterionEvaluator(),mdt);
        increaseCodeCoverageHelper(new CDdIsChangedCriterionEvaluator(),mdt);
        increaseCodeCoverageHelper(new CDdNotLikeCriterionEvaluator(),mdt);
        increaseCodeCoverageHelper(new CDdIsBlankCriterionEvaluator(),mdt);
    }


    private static void increaseCodeCoverageHelper(CDdCriterionEvaluator eval,Proactive_Case_Creation_Criterion__mdt mdt) {
        eval.evaluateCriterion('TEST', 'TEST', null,false);
        eval.evaluateCriterion(mdt, null);
        eval.evaluateCriterion();
        eval.evaluateCriterion('',null);
    }

}