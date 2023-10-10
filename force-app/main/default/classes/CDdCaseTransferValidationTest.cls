@isTest
public without sharing class CDdCaseTransferValidationTest {

    private static List<Case> setupCase(Boolean shouldInsert,String queueId,String issue,String storeId) {
        List<Case> cases = TDdCaseFactory.createCaseRecords(1, CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER);
        Case newCase = cases[0];

        if (String.isNotBlank(queueId)) {
            newCase.OwnerId = queueId;
        }
        newCase.Issue_Type__c = 'Account Management - CX';
        newCase.Issue__c = issue;
        newCase.Priority = 'High';
        newCase.Status = 'Open';
        newCase.Routing_Reason__c = 'This is a test record';
        newCase.Store_ID__c = storeId;
        newCase.Previous_Queue_ID__c = '00G2L000001WlbqUAC';

        if (shouldInsert) {
            insert newCase;
        } else {
            newCase.Id = '500000000000000';
        }
        return cases;
    }

    private static Map<Id,Case> createCaseOldmap(List<Case> cases) {
        Map<Id,Case> caseOldMap = new Map<Id,Case>();
        for (Case c : cases) {
            Case oldCase = c.clone(true,false,false,false);
            oldCase.OwnerId = UserInfo.getUserId();
            caseOldMap.put(oldCase.Id,oldCase);
        }
        return caseOldMap;
    }

    @isTest
    public static void testWithoutFilterLogic_1() {
        List<Case> cases = setupCase(false,'00G000000000000000','Gift Card Inquiry','');
        Map<Id,Case> caseOldMap = createCaseOldmap(cases);

        Test.startTest();
        CDdCaseTransferValidationHelper.executeTransferValidation(cases, caseOldMap);
        Test.stopTest();
        system.assertEquals(true, cases[0].hasErrors(), 'The test case did not have the expected error');
        Case_Transfer_Validation_Config__mdt validation = Case_Transfer_Validation_Config__mdt.getInstance('TEST_DO_NOT_DELETE_Case_Test');
        system.assert(cases[0].getErrors()[0].getMessage().contains(validation.Id), 'Expected validation was not fired');
    }

    @isTest
    public static void testWithoutFilterLogic_2() {
        List<Case> cases = setupCase(false,'00G000000000000000','Gift Card Inquiry','123456');
        Map<Id,Case> caseOldMap = createCaseOldmap(cases);

        Test.startTest();
        CDdCaseTransferValidationHelper.executeTransferValidation(cases, caseOldMap);
        Test.stopTest();
        system.assertEquals(false, cases[0].hasErrors(), 'The test case had an unexpected error.');
    }

    @isTest
    public static void testWithFilterLogic_1() {
        List<Case> cases = setupCase(false,'00G000000000000001','Reactivate Account','678901');
        Map<Id,Case> caseOldMap = createCaseOldmap(cases);

        Test.startTest();
        CDdCaseTransferValidationHelper.executeTransferValidation(cases, caseOldMap);
        Test.stopTest();
        system.assertEquals(true, cases[0].hasErrors(), 'The test case did not have the expected error');
        Case_Transfer_Validation_Config__mdt validation = Case_Transfer_Validation_Config__mdt.getInstance('TEST_DO_NOT_DELETE_Case_Test_Filters');
        system.assert(cases[0].getErrors()[0].getMessage().contains(validation.Id), 'Expected validation was not fired');
    }

    @isTest
    public static void testWithFilterLogic_2() {
        List<Case> cases = setupCase(false,'00G000000000000001','Gift Card Inquiry','123456');
        Map<Id,Case> caseOldMap = createCaseOldmap(cases);

        Test.startTest();
        CDdCaseTransferValidationHelper.executeTransferValidation(cases, caseOldMap);
        Test.stopTest();
        system.assertEquals(false, cases[0].hasErrors(), 'The test case had an unexpected error.');
    }

    @isTest
    public static void testRelatedObject() {
        TDdCaseFactory.getSupportFeatureFlag(true);
        vCS__c testSettings;
        testSettings = VTestUtil.createVeltigSettings();
        testSettings.CaseTrigger__c = true;
        insert testSettings;
        Group testQueue = [SELECT Id FROM Group WHERE Name='Test' AND Type = 'Queue'];
        insert new Queue_Mapping__c(
            Queue_Id__c = testQueue.Id,
            Queue_Name__c = 'Test',
            Queue_Developer_Name__c = 'Test',
            Language__c = 'English',
            Is_VIP__c = true,
            Chat_Bot_Vendor__c = ''
        );
        List<Case> testCaseList = TDdCaseFactory.createCaseRecords(1, CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER);
        testCaseList[0].Previous_Queue_ID__c = '00G2L000001WlbqUAC';
        insert testCaseList;
        insert new FeedItem(
            Type = CDdSupportConstants.CASEFEED_TYPE_TEXTPOST,
            Body = 'Test Record',
            ParentId = testCaseList[0].Id
        );
        insert new amazonconnect__AC_ContactTraceRecord__c(
            Case__c = testCaseList[0].Id,
            amazonconnect__Initiation_Method__c = 'TRANSFER',
            amazonconnect__QueueName__c = 'AC Queue',
            amazonconnect__Channel__c = 'VOICE',
            amazonconnect__ContactId__c = '000aaa0a-0a00-0a0a-00aa-00a000000a00'
        );
        Test.startTest();
        try {
            testCaseList[0].OwnerId = testQueue.Id;
            testCaseList[0].Issue_Type__c = 'Account Management - CX';
            testCaseList[0].Issue__c = 'Gift Card Inquiry';
            testCaseList[0].DispatchRQResponse__c = '{"salesforceAudienceInfoBulkResponse":[{"customerType":0,"audience":{"consumerAudience":{"id":"1337489918","firstName":"Nansy","lastName":"Soto"},"dasherAudience":{"id":"13846954","firstName":"Alicia","lastName":"Heredia"},"store":{"id":"1084436","name":"Walgreens (7375)","isPartner":false,"tenure":1234}}}],"salesforceAudienceInfoBulkResponseErrors":[]}';
            update testCaseList;
            system.assert(false,'Should not come here');
        } catch(Exception e) {
            system.assert(true,'Should come here');
            Case_Transfer_Validation_Config__mdt validation = Case_Transfer_Validation_Config__mdt.getInstance('TEST_DO_NOT_DELETE_Related_Objects');
            system.assert(e.getMessage().contains(validation.Id), 'Expected validation was not fired: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void increaseCodeCoverage(){
        Case_Transfer_Validation_Criterion__mdt mdt = Case_Transfer_Validation_Criterion__mdt.getInstance('TEST_DO_NOT_DELETE_Case_Test_2');
        CDdCriterionEvaluator eval = new CDdCriterionEvaluator();

        increaseCodeCoverageHelper(eval,mdt);
        eval.getRelatedObjectMap('Case-Opportunity');
        eval.getRelatedObjectMap('Case-Contact');
        eval.getRelatedObjectMap('LiveChatTranscript-Case');
        eval.getRelatedObjectMap('Test-Test');
        eval.getRelatedObjectFieldValue(null,null,null,null);

        increaseCodeCoverageHelper(new CDdEqualsCriterionEvaluator(),mdt);
        increaseCodeCoverageHelper(new CDdNotEqualsCriterionEvaluator(),mdt);
        increaseCodeCoverageHelper(new CDdContainsCriterionEvaluator(),mdt);
        increaseCodeCoverageHelper(new CDdNotContainsCriterionEvaluator(),mdt);
        increaseCodeCoverageHelper(new CDdLikeCriterionEvaluator(),mdt);
        increaseCodeCoverageHelper(new CDdIsNotBlankCriterionEvaluator(),mdt);
        increaseCodeCoverageHelper(new CDdIsNewCriterionEvaluator(),mdt);
        increaseCodeCoverageHelper(new CDdIsChangedCriterionEvaluator(),mdt);
        increaseCodeCoverageHelper(new CDdNotLikeCriterionEvaluator(),mdt);
        increaseCodeCoverageHelper(new CDdIsBlankCriterionEvaluator(),mdt);
    }

    private static void increaseCodeCoverageHelper(CDdCriterionEvaluator eval,Case_Transfer_Validation_Criterion__mdt mdt) {
        eval.evaluateCriterion('TEST', 'TEST', null,false);
        eval.evaluateCriterion(mdt, null);
        eval.evaluateCriterion();
        eval.evaluateCriterion('',null);
    }
}