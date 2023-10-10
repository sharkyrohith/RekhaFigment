/**
 * CDdCaseTriggerHandlerV2 supplimental tests
 * This class is to break up test class into multiple test classes so that
 * CDdCaseTriggerHandlerV2Test does not time out.
 *
 * @author Jeegar
 * @date Feb-2023
 *
 */

@isTest
public class CDdCaseTriggerHelperAdditionalTest {
    @testSetup
    static void testSetup() {
        vCS__c testSettings;
        testSettings = VTestUtil.createVeltigSettings();
        testSettings.CaseTrigger__c = true;
        testSettings.FireAutoResponseRules__c = true;
        insert testSettings;

        Support_Feature_Flag__c featureFlag = Support_Feature_Flag__c.getOrgDefaults();
        featureFlag.Enable_Qualtrics_Surveys__c = false;
        featureFlag.EnableReopen__c = true;
        featureFlag.EnableMXPAgentReopens__c = true;
        featureFlag.Enable_Tasks_on_Case_Feed__c = true;
        featureFlag.MXP_Support_E2C_Linking__c = true;
        featureFlag.Enable_Sendbird_API_Callouts__c = true;
        featureFlag.Publish_AWS_Events__c = true;
        upsert featureFlag;

        Feature_Flags__c ftrFlag = Feature_Flags__c.getOrgDefaults();
        ftrFlag.Enable_CPU_Time_Check__c = true;
        ftrFlag.Enable_Debug_Logs__c = true;
        insert ftrFlag;

        List<Account> acclist = CDdTestDataFactory.createSObjectList('Account', 1, true);
        List<Case> casesToInsert = TDdCaseFactory.createSolveableSupportCase(3,
                    CDdGenericTriggerOptimizationHelper.getCaseRecordTypeIdByDevName(CDdSupportConstants.RECORDTYPE_NAME_CUSTOMER),
                    accList[0].id, null);


        Insert casesToInsert;


    }

    /**
     * Test shouldSendTHQAlert Testing Phone Case creation logic.
     */
    @isTest
    static void testPhoneCaseCreationTHQNotification() {
        List<Case> casesToInsert = TDdCaseFactory.createSolveableSupportCase(1,
                CDdGenericTriggerOptimizationHelper.supportRecordTypeId);
        for(Case currCase : casesToInsert) {
            currCase.Origin = CDdSupportConstants.CASE_ORIGIN_PHONE;
        }

        System.assertEquals(true, CDdCaseTriggerHelperV2.shouldSendTHQAlert(casesToInsert[0], null),
            'shouldSendTHQAlert should return true' );

    }
    /**
     * Test shouldSendTHQAlert Testing Chat Case creation logic, this is a negative test.
     */
    @isTest
    static void testNegativeTHQNotification() {
        List<Case> casesToInsert = TDdCaseFactory.createSolveableSupportCase(1,
                CDdGenericTriggerOptimizationHelper.supportRecordTypeId);
        for(Case currCase : casesToInsert) {
            currCase.Origin = CDdSupportConstants.CASE_ORIGIN_CHAT;
        }

        System.assertEquals(false, CDdCaseTriggerHelperV2.shouldSendTHQAlert(casesToInsert[0], null),
        'shouldSendTHQAlert should return false' );
    }

    /**
     * Test shouldSendTHQAlert Testing Chat Case update logic.
     */
    @IsTest
    static void testPositiveCaseUpdateTHQNotification(){
        List<Case> casesToInsert = TDdCaseFactory.createSolveableSupportCase(2,
                CDdGenericTriggerOptimizationHelper.supportRecordTypeId);
        for(Case currCase : casesToInsert) {
            currCase.Origin = CDdSupportConstants.CASE_ORIGIN_CHAT;
        }
        System.assertEquals(true, CDdCaseTriggerHelperV2.shouldSendTHQAlert(
                    casesToInsert[0], casesToInsert[1]),
                    'shouldSendTHQAlert should return true' );

    }


    /**
     * @author          Jeegar
     * @date            May 2023
     * @jira            https://doordash.atlassian.net/browse/BIZS-2857
     * @description     test auto merging of case Postitive test
     */

    @isTest
    static void testCaseAutoMergePositiveTest() {
        List<Case> caseList = [SELECT id, status, accountId, issue_Type__c
                                    FROM Case
                                    WHERE recordtypeid = :CDdGenericTriggerOptimizationHelper.getCaseRecordTypeIdByDevName(
                                                                            CDdSupportConstants.RECORDTYPE_NAME_CUSTOMER)
                                        AND AccountId != '' ];

        Support_Feature_Flag__c featureFlag = Support_Feature_Flag__c.getOrgDefaults();
        featureFlag.Enable_Sendbird_API_Callouts__c = false;
        featureFlag.Publish_AWS_Events__c = false;
        featureFlag.Disable_Auto_Merge_Cases__c = false;
        upsert featureFlag;

        System.assert(caseList.size() > 1, 'Case List should return atleast 2 cases for the test to be successful');
        Case parentCase = caseList[0];
        Case duplicateCase = caseList[1];
        parentCase.ParentId = null;
        parentCase.Status = CDdSupportConstants.SOLVED_STATUS;
        parentCase.DeliveryUUID__c = 'asfescase';
        parentCase.Origin = CDdSupportConstants.CASE_ORIGIN_CHAT;
        parentCase.Customer_Type__c = CDdSupportConstants.CUSTOMER_TYPE_CONSUMER;
        parentCase.Solved_At__c = system.now();
        update parentCase;

        Test.startTest();
        duplicateCase.accountId = parentCase.AccountId;
        duplicateCase.customer_type__c = CDdSupportConstants.CUSTOMER_TYPE_CONSUMER;
        duplicateCase.Status = CDdSupportConstants.SOLVED_STATUS;
        duplicateCase.DeliveryUUID__c = 'asfescase';
        duplicateCase.Origin = CDdSupportConstants.CASE_ORIGIN_CHAT;
        update duplicateCase;
        Test.stopTest();

        Case resultCase  = [SELECT Id, Status, Resolution__c, Resolution_Type__c, parentId
                                FROM Case
                                where id = :duplicateCase.id][0];
        System.assertEquals(CDdSupportConstants.CLOSED_STATUS,resultCase.status, 'Status should be closed but is not');
        System.assertEquals(parentCase.id, resultCase.ParentId, 'Parent Id is incorrect');
        System.assertEquals(CDdSupportConstants.RESOLUTION_TYPE_OTHER_CX, resultCase.Resolution_Type__c,
                'Resolution Type should be "' + CDdSupportConstants.RESOLUTION_TYPE_OTHER_CX + '"');
        System.assertEquals(CDdSupportConstants.CASE_RESOLUTION_AUTOMATED_MERGE_DUPLICATE, resultCase.Resolution__C,
                'Resolution should be "' + CDdSupportConstants.CASE_RESOLUTION_AUTOMATED_MERGE_DUPLICATE +'"');
    }

    /**
     * @author          Jeegar
     * @date            May 2023
     * @jira            https://doordash.atlassian.net/browse/BIZS-2857
     * @description     test auto merging of case Negative test
     */

    @isTest
    static void testCaseAutoMergeNegativeTest() {
        List<Case> caseList = [SELECT id, status, accountId, issue_Type__c
                                    FROM Case
                                    WHERE recordtypeid = :CDdGenericTriggerOptimizationHelper.getCaseRecordTypeIdByDevName(
                                                                            CDdSupportConstants.RECORDTYPE_NAME_CUSTOMER)
                                        AND AccountId != '' ];

        Support_Feature_Flag__c featureFlag = Support_Feature_Flag__c.getOrgDefaults();
        featureFlag.Enable_Sendbird_API_Callouts__c = false;
        featureFlag.Publish_AWS_Events__c = false;
        featureFlag.Disable_Auto_Merge_Cases__c = false;
        upsert featureFlag;

        System.assert(caseList.size() > 1, 'Case List should return atleast 2 cases for the test to be successful');
        Case parentCase = caseList[0];
        Case duplicateCase = caseList[1];
        parentCase.ParentId = null;
        parentCase.Status = 'Solved';
        parentCase.Customer_Type__c = CDdSupportConstants.CUSTOMER_TYPE_CONSUMER;
        update parentCase;

        Test.startTest();
        duplicateCase.accountId = parentCase.AccountId;
        duplicateCase.customer_type__c = CDdSupportConstants.CUSTOMER_TYPE_DASHER;
        duplicateCase.Status = 'Solved';
        update duplicateCase;

        Test.stopTest();

        Case resultCase  = [SELECT Id, Status, Resolution__c, Resolution_Type__c, parentId
                                FROM Case
                                where id = :duplicateCase.id][0];

        System.assertNotEquals(CDdSupportConstants.CLOSED_STATUS, resultCase.status, 'Status should NOT be closed');
        System.assertNotEquals(parentCase.id, resultCase.ParentId, 'Parent Id should be null');
        System.assertNotEquals(CDdSupportConstants.CASE_RESOLUTION_AUTOMATED_MERGE_DUPLICATE, resultCase.Resolution__C,
                'Resolution NOT should be "' + CDdSupportConstants.CASE_RESOLUTION_AUTOMATED_MERGE_DUPLICATE +'"');
    }

    /**
     * @author        Srikanth Matety
     * @date          07/26/2023
     * @jira          https://doordash.atlassian.net/browse/BASD-51546
     * @description   test to delete a case , negative test (case will be deleted)
     */
    @isTest
    static void testprocessDeleteCaseAllow() {
        Boolean isError = false;

        List<Case> caseToDelete = [SELECT id FROM Case limit 1];

        Support_Feature_Flag__c featureFlag = Support_Feature_Flag__c.getOrgDefaults();
        featureFlag.Allow_Case_Deletion__c = true;
        upsert featureFlag;

        Test.startTest();
        try{
            delete caseToDelete;
        }
        catch(Exception ex){
            isError = true;
        }
        Test.stopTest();
        System.assertEquals(false,isError,'no exception in deleting the case');
    }

    /**
     * @author        Srikanth Matety
     * @date          07/26/2023
     * @jira          https://doordash.atlassian.net/browse/BASD-51546
     * @description   test to delete a case , positive test (case cannot be deleted)
     */
    @isTest
    static void testprocessDeleteCaseDoNotAllow() {

        Boolean isError = false;
        String casedeleteerrormessage = 'The Delete Option for Cases has been Disabled. Please Close the Case instead.';

        List<Case> caseToDelete = [SELECT id FROM Case limit 1];

        Support_Feature_Flag__c featureFlag = Support_Feature_Flag__c.getOrgDefaults();
        featureFlag.Allow_Case_Deletion__c = false;
        upsert featureFlag;


        Test.startTest();
        try{
            Delete caseToDelete;
        }
        catch(Exception ex){
            system.assert(ex.getMessage().contains(casedeleteerrormessage),'Exception thrown is different from expected - ' + ex.getMessage());
            isError = true;
        }
        Test.stopTest();
        System.assertEquals(true,isError,'an exception in deleting the case');

    }

}