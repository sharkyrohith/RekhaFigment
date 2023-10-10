/**
* @author Nayana Kapse
* @date  2021-09-07
* @decription Test class for MxP functionalities
*/
@isTest
public class CDdMxPHelperTest {
    private static Id mxpQueueId = [SELECT ID FROM Group WHERE Name = :CDdSupportConstants.MX_SUCCESS_ASSOCIATE].Id;

    /**
     * @author      Nayana
     * @date        Sept 2021
     * @description Data setup method
     */
	@testSetup
    static void testSetup() {
        vCS__c testSettings = new VCS__c();
        testSettings.SetupOwnerId = UserInfo.getOrganizationId();
        testSettings.CaseTrigger__c = true;
        insert testSettings;

        Support_Feature_Flag__c featureFlag = Support_Feature_Flag__c.getOrgDefaults();
        featureFlag.Enable_Qualtrics_Surveys__c = false;
        featureFlag.EnableReopen__c = true;
        featureFlag.EnableMXPAgentReopens__c = true;
        featureFlag.Enable_Tasks_on_Case_Feed__c = true;
        featureFlag.MXP_Support_E2C_Linking__c = true;
        featureFlag.Enable_Sendbird_API_Callouts__c = true;
        upsert featureFlag;

        insert new Sendbird_Settings__c(Callout_Retries__c = 1);

        Support_Assignment_Mapping__c mxSxSuccessAssociate = new Support_Assignment_Mapping__c();
        mxSxSuccessAssociate.Name = CDdSupportConstants.MX_SUCCESS_ASSOCIATE;
        mxSxSuccessAssociate.Queue_Id__c = mxpQueueId;
        mxSxSuccessAssociate.Support_Assignment_Name__c = CDdSupportConstants.MX_SUCCESS_ASSOCIATE;
        mxSxSuccessAssociate.Object__c = CDdSupportConstants.CASE_OBJECT_LABEL;

        insert mxSxSuccessAssociate;

        Feature_Flags__c ftrFlag = Feature_Flags__c.getOrgDefaults();
        ftrFlag.Enable_CPU_Time_Check__c = true;
        ftrFlag.Enable_Debug_Logs__c = true;
        insert ftrFlag;

        //Insert MXP Account
        Account testAcct = TDdAccountFactory.createAccounts(CDdSupportConstants.NAME_TEST_ACCOUNT,1)[0];
        testAcct.Case_Routing_Override__c = CDdSupportConstants.QUEUE_MX_SUCCESSASSOCIATE;
        insert testAcct;

        //Insert the cases for MXP Account
        String PARTNER_INTEGRATION_KWIKTRIP = 'kwiktrip';
        List<Case> testCaseList = TDdCaseFactory.createCaseRecords(1, CDdSupportConstants.RECORDTYPE_NAME_SUPPORT);
        testCaseList[0].AccountId = testAcct.Id;
        testCaseList[0].Customer_Type__c = CDdSupportConstants.CUSTOMER_TYPE_MERCHANT;
        testCaseList[0].Issue_Type__c = CDdSupportConstants.ISSUE_POS;
        testCaseList[0].POS_Integration_Type__c = PARTNER_INTEGRATION_KWIKTRIP;
        insert testCaseList;
        System.runAs(new User(Id=UserInfo.getUserId())){
            //Create Parent Group
            Group testGroup = new Group(Name='CDdMxPHelperTest Group1', Type='Queue');
            insert testGroup;

            //Associating queue with group AND to the Case object
            QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = 'Case');
            insert testQueue;
        }
    }

    /**
     * @author      Nayana
     * @date        Sept 2021
     * @description Data will be quried once and can be used in test methods
     */
    public class TestContext
    {
        public List<Case> lstCase;
        public List<Account> lstAccount;
        public Group testGroup;
        public TestContext(){
            lstCase = [SELECT Id,AccountId,OwnerId,Case_Routing_Override__c FROM Case];
            lstAccount = [SELECT Id,Case_Routing_Override__c FROM Account];
            testGroup = [SELECT Id FROM Group WHERE Name='CDdMxPHelperTest Group1'];
        }
    }

    /**
     * @author      Nayana
     * @date        August 2021
     * @jira        https://doordash.atlassian.net/browse/BZAPSUP-1866
     * @description tests processing of MxP cases escalation to MxP Queue
     */
    @isTest
    static void testMxPCasesEscalation() {
        Test.setMock(HttpCalloutMock.class, TDdCaseFactory.getSendbirdMockResponse());
		TestContext context = new TestContext();
        Id firstOwnerChange = context.testGroup.Id;
        Case testCase = context.lstCase[0];

        //This was added as directly changing owner to MxSx queue was throwing Case merge error,so updating the case to some other queue first and then to MxSx queue
        testCase.OwnerId = firstOwnerChange;
        testCase.Issue_Type__c =  'Activations - Mx';
        testCase.Issue__c =   CDdSupportConstants.ISSUE_POS;
        update testCase;
        //Escalate the case
        Test.startTest();
        testCase.OwnerId = Id.valueof(Id_Metadata__mdt.getInstance('Queue_MxSx_National').Id__c);
        update testCase;
		Test.stopTest();

        //assert that the case owner is mxp agent
        Case caseFromDB = [SELECT OwnerId FROM Case WHERE Id =:testCase.Id LIMIT 1];
        System.assertEquals(mxpQueueId, caseFromDB.OwnerId, 'Case Owner should be Mx Assosciate Queue');
    }

     /**
     * @author      Nayana
     * @date        Jan 2022
     * @jira        https://doordash.atlassian.net/browse/BIZS-676
     * @description tests reopening of MxpCases
     */
    @isTest
    static void testMxPReopen() {
        Test.setMock(HttpCalloutMock.class, TDdCaseFactory.getSendbirdMockResponse());

        TestContext context = new TestContext();
        Case testCase = context.lstCase[0];
        testCase.Status = CDdSupportConstants.REOPEN_STATUS;
        Test.startTest();
        update testCase;
        Test.stopTest();
        Case caseFromDB = [SELECT OwnerId FROM Case WHERE Id =:testCase.Id LIMIT 1];
        System.assertEquals(mxpQueueId, caseFromDB.OwnerId, 'Case Owner should be Mx Assosciate Queue');
    }

     /**
     * @author      Nayana
     * @date        Jan 2022
     * @jira        https://doordash.atlassian.net/browse/BZAPSUP-1866
     * @description tests processing of MxP cases escalation to MxP Queue
     */
    @isTest
    static void testMxPCasesEscalationV2() {
        Test.setMock(HttpCalloutMock.class, TDdCaseFactory.getSendbirdMockResponse());

		TestContext context = new TestContext();
        Id firstOwnerChange = context.testGroup.Id;
        Case testCase = context.lstCase[0];

        //This was added as directly changing owner to MxSx queue was throwing Case merge error,so updating the case to some other queue first and then to MxSx queue
        testCase.OwnerId = firstOwnerChange;
        testCase.Issue_Type__c =  'Activations - Mx';
        testCase.Issue__c =   CDdSupportConstants.ISSUE_POS;
        update testCase;
        //Escalate the case
        Test.startTest();
        testCase.OwnerId = Id.valueof(Id_Metadata__mdt.getInstance('Queue_MxSx_National').Id__c);
        update testCase;
		Test.stopTest();

        //assert that the case owner is mxp agent
        Case caseFromDB = [SELECT OwnerId FROM Case WHERE Id =:testCase.Id LIMIT 1];
        System.assertEquals(mxpQueueId, caseFromDB.OwnerId, 'Case Owner should be Mx Assosciate Queue');
    }

     /**
     * @author      Nayana
     * @date        Jan 2022
     * @jira        https://doordash.atlassian.net/browse/BIZS-676
     * @description tests reopening of MxpCases
     */
    @isTest
    static void testMxPReopenV2() {
        Test.setMock(HttpCalloutMock.class, TDdCaseFactory.getSendbirdMockResponse());
        TestContext context = new TestContext();
        Case testCase = context.lstCase[0];
        testCase.Status = CDdSupportConstants.REOPEN_STATUS;
        Test.startTest();
        update testCase;
        Test.stopTest();
        Case caseFromDB = [SELECT OwnerId FROM Case WHERE Id =:testCase.Id LIMIT 1];
        System.assertEquals(mxpQueueId, caseFromDB.OwnerId, 'Case Owner should be Mx Assosciate Queue');
    }

}