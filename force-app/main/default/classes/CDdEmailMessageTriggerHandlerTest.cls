/**
 * @description       : Email Message Trigger Handler
 * @last modified on  : 02-13-2023
 * @last modified by  : Jose Vega
**/
@isTest
public class CDdEmailMessageTriggerHandlerTest {

    public static final Id TEST_ROLE_ID;
    public static final Id SYSTEM_ADMIN_PROFILE_ID;
        public static final Id CASE_DRIVEMENU_RECORDTYPEID = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Drive Menu Team').getRecordTypeId();
        public static final Id SUPPORT_RECORDTYPEID = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support').getRecordTypeId();
        public static final Id SUPPORT_TOOL_RECORDTYPEID = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support Tool Requests').getRecordTypeId();

    public static final String TEST_DD_RUN_USERNAME = 'test.runninguser@doordash.com';
    static {
        TEST_ROLE_ID = [SELECT Id FROM UserRole WHERE DeveloperName = 'COO'].Id;
        SYSTEM_ADMIN_PROFILE_ID = [SELECT Id FROM Profile WHERE Name =: CDdSupportConstants.PROFILE_SYS_ADM].Id;
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

    @testSetup
    static void testSetup() {
        Group testCaseQueue = new Group(Name='Test Case Queue', Type = CDdSupportConstants.GROUP_QUEUE);
        insert testCaseQueue;
        System.runAs(getTestRunUser()){
            QueuesObject testQueue = new QueueSObject(QueueID = testCaseQueue.id, SObjectType = CDdSupportConstants.CASE_OBJECT_LABEL);
            insert testQueue;
            vCS__c testSettings;
            testSettings = VTestUtil.createVeltigSettings();
            testSettings.CaseTrigger__c = true;
            insert testSettings;

            Support_Feature_Flag__c featureFlag = Support_Feature_Flag__c.getOrgDefaults();
            featureFlag.Enable_updateEmailCountonCases__c = true;
            featureFlag.Enable_reopenCaseFromEmailMessage__c  = true;
            featureFlag.Enable_createEscalationcases__c = true;
            featureFlag.Redirect_Closed_Cases_to_Web__c = true;
            featureFlag.Auto_Create_Closed_Case_Response__c = true;
            featureFlag.Disable_THQ_Callouts__c = true;
            upsert featureFlag;

            List<Case> casesToInsert = new List<Case>();
            List<EmailMessage> emailToInsert = new List<EmailMessage>();
            List<Group> mEscalationBGCQueue = [SELECT ID FROM Group WHERE Name = :CDdEmailMessageHelper.M_ESCALATIONS_BGC_QUEUE_NAME];

           List<Case> cslist1 = CDdTestDataFactory.createSObjectList('Case', 5, false);
           for(Case c:cslist1){

               c.BusinessHours=null;
               c.Subject='testcasesubject';
               c.Case_Claimed__c=date.today();
           }
            for(Integer i = 0; i < cslist1.size(); i++){

                if(i==0){
                    cslist1[i].recordtypeid=SUPPORT_RECORDTYPEID;
                    cslist1[i].status='Closed';
                }
                if(i==1){
                    cslist1[i].recordtypeid=SUPPORT_RECORDTYPEID;
                    cslist1[i].status='Pending';
                }
                if(i==2){
                    cslist1[i].RecordTypeId = SUPPORT_RECORDTYPEID;
                    cslist1[i].status='Pending';
                }
                if(i==3){
                    cslist1[i].RecordTypeId = SUPPORT_TOOL_RECORDTYPEID;
                    cslist1[i].status='Pending';
                }
                if(i==4){
                    cslist1[i].RecordTypeId = SUPPORT_RECORDTYPEID;
                    cslist1[i].status='Solved';
                    cslist1[i].Initial_Queue__c=mEscalationBGCQueue[0].Id;
                    cslist1[i].Initial_Queue_Name__c=CDdEmailMessageHelper.M_ESCALATIONS_BGC_QUEUE_NAME;
                }
                casesToInsert.add(cslist1[i]);
            }

            insert casesToInsert;

            List<EmailMessage> emlist = CDdTestDataFactory.createSObjectList('EmailMessage', 5, false);
            for(EmailMessage e:emlist){

                e.Subject='settestemailmessage';
                e.status='3';
                e.fromAddress='test.case@doordash.com';
                e.HtmlBody='test case';
                e.fromName='test case';
            }
            for(Integer i = 0; i < emlist.size(); i++){
                if(i==0){
                    emlist[i].relatedToId =casesToInsert[i].id;
                    emlist[i].toAddress = 'test.case@m-escalations.com';
                    emlist[i].incoming = true;
                }
                if(i==1){
                    emlist[i].relatedToId =casesToInsert[i].id;
                    emlist[i].toAddress = 'test.case@doordash.com';
                    emlist[i].incoming = true;
                }
                if(i==2){
                    emlist[i].relatedToId =casesToInsert[i].id;
                    emlist[i].toAddress = 'test.case@doordash.com';
                    emlist[i].incoming = false;
                }
                if(i==3){
                    emlist[i].relatedToId =casesToInsert[i].id;
                    emlist[i].toAddress = 'test.case@doordash.com';
                    emlist[i].incoming = true;
                }
                if(i==4){
                    emlist[i].relatedToId =casesToInsert[i].id;
                    emlist[i].toAddress = 'test.case@m-escalations.com';
                    emlist[i].incoming = true;
                }
                emailToInsert.add(emlist[i]);
            }

            Test.startTest();

            insert emailToInsert;

            List<emailMessage> createdEmailMessages = [SELECT Id,
                                                              RelatedToId,
                                                              Incoming
                                                            FROM EMAILMESSAGE];

            System.assert(!createdEmailMessages.isEmpty(),'List should not be empty');
            //Ensure 5 records were created
            System.assert(createdEmailMessages .size() == 5,'5 emailmessage records should be returned');
            List<Case> udpatedCase = [SELECT ID, OwnerId FROM Case WHERE Initial_Queue_Name__c=:CDdEmailMessageHelper.M_ESCALATIONS_BGC_QUEUE_NAME];
            System.assertEquals(mEscalationBGCQueue[0].Id, udpatedCase[0].OwnerId, 'Reopened Cases are assigned again to M-Escalations Dx BGC Compliance Queue');

            Test.stopTest();

        }
    }
    public static testMethod void testDeletionsAllowed() {
        Record_Type_Values__mdt caseRecordType = [SELECT QualifiedApiName, Record_Type_Id__c
                                                        FROM Record_Type_Values__mdt
                                                        WHERE QualifiedApiName  = 'Case_Tablet_Requests'];

        List<Case> caseList = TDdCaseFactory.createCaseRecords(1, 'Account Management');
        Insert caseList;
        EmailMessage testEM1 = new EmailMessage(ParentId=caseList[0].Id,
                                              Incoming=true,ToAddress = 'test.case@notrealemailaddress.com',
                                                FromAddress='support@doordash.com');

        insert testEM1;
        Allow_Email_Deletion__c emailDeleteSetting = Allow_Email_Deletion__c.getOrgDefaults();
        emailDeleteSetting.Allow_All_Email_Deletions__c = true;
        upsert emailDeleteSetting;

        Test.startTest();
        delete testEM1;
        Test.stopTest();

        List<EmailMessage> messages = [Select id from EmailMessage where parentId =: caseList[0].id ];
        System.assertEquals(0, messages.size());

    }

    public static testMethod void testDeletionsNotAllowed() {
        Boolean correctExceptionThrown = false;
        Record_Type_Values__mdt caseRecordType = [SELECT QualifiedApiName, Record_Type_Id__c
                                                        FROM Record_Type_Values__mdt
                                                        WHERE QualifiedApiName  = 'Case_Tablet_Requests'];

        List<Case> caseList = TDdCaseFactory.createCaseRecords(1, 'Account Management');
        Insert caseList;
        EmailMessage testEM1 = new EmailMessage(ParentId=caseList[0].Id,
                                              Incoming=true,ToAddress = 'test.case@notrealemailaddress.com',
                                               FromAddress='support@doordash.com');
        insert testEM1;
        Allow_Email_Deletion__c emailDeleteSetting = Allow_Email_Deletion__c.getOrgDefaults();
        emailDeleteSetting.Allow_All_Email_Deletions__c = false;
        upsert emailDeleteSetting;

        Test.startTest();
        try {
            delete testEM1;
        } catch (Exception ex) {
            correctExceptionThrown = ex.getMessage().contains(Label.Email_Delete_Not_Allowed) ? true : false;
        }

        Test.stopTest();

        List<EmailMessage> messages = [Select id from EmailMessage where parentId =: caseList[0].id ];
        System.assert(correctExceptionThrown);
    }

    public static testMethod void populatePlatformCaviarMxCasesTest(){
        List<Case> cslist = CDdTestDataFactory.createSObjectList('Case', 1, false);
        cslist[0].BusinessHours=null;
        cslist[0].Subject='testcasesubject';
        cslist[0].Case_Claimed__c=date.today();

        insert cslist;

        List<EmailMessage> emlist = CDdTestDataFactory.createSObjectList('EmailMessage', 5, false);
        emlist[0].Subject='Caivar Test Case';
        emlist[0].status='3';
        emlist[0].fromAddress='test.case@doordash.com';
        emlist[0].toAddress= CDdEmailMessageHelper.CAVIAR_RESTAURANTS_ROUTING_EMAIL;
        emlist[0].HtmlBody='Caviar Test Case';
        emlist[0].fromName='Test Name';
        emlist[0].ParentId=cslist[0].Id;

        Test.startTest();
        insert emlist;
        Test.stopTest();

        List<Case> updatedCase = [SELECT ID, Platform__c FROM Case WHERE Id = :cslist[0].Id];
        System.assertEquals(CDdEmailMessageHelper.CASE_PLATFORM_CAVIAR, updatedCase[0].Platform__c, 'Platform field on case should be Caivar');
    }

    @isTest
    private static void shouldUpdateLastEmailFromCustomer(){
        Map<Id,Case> caseMap = new Map<Id, Case>();
        List<Case> returnedCases = new List<Case>();

        List<Case> csList = CDdTestDataFactory.createSObjectList('Case', 1, false);
        csList[0].BusinessHours=null;
        csList[0].Subject = 'testcasesubject';
        // csList[0].Status = 'Open';
        csList[0].Case_Claimed__c = Date.today();
        csList[0].Last_Email_from_Customer__c = null;
        insert csList;

        caseMap.putAll(csList);


        List<EmailMessage> emlist = CDdTestDataFactory.createSObjectList('EmailMessage', 1, false);
        emlist[0].Subject = 'Test email';
        emList[0].Incoming = true;
        emlist[0].fromAddress = 'test.case@notrealemailaddress.com';
        emlist[0].toAddress = 'testcase@doordash.com';
        emlist[0].HtmlBody ='Test Case';
        emlist[0].fromName ='Test Name';
        emlist[0].ParentId = cslist[0].Id;

        insert emList;

        // CDdEmailMessageHelper emHelper = new CDdEmailMessageHelper();
        // returnedCases = emHelper.updateLastEmailFrom(emlist, caseMap);
        List<Case> updatedCase = [SELECT Id, Last_Email_from_Customer__c FROM Case WHERE Id = :cslist[0].Id];
        System.debug('updated case in test ' + updatedCase[0].Last_Email_from_Customer__c);
        System.assert(!updatedCase.isEmpty(), 'Returned Cases should not be empty');
        System.assertNotEquals(updatedCase[0].Last_Email_from_Customer__c, null, 'Last email from customer should not be blank');



    }
    @isTest
    private static void shouldUpdateLastEmailToCustomer(){
        CDdEmailMessageHelper emailMessageHelper = new  CDdEmailMessageHelper();
        List<EmailMessage> emlist =[SELECT ID,ParentId,FromAddress,toAddress,incoming FROM EmailMessage WHERE incoming = false AND ParentId!=null LIMIT 1];
        Map<Id,Case> mapEmailMsgToCase = new Map<Id,Case>();
        mapEmailMsgToCase.putAll(emailMessageHelper.queryCases(emlist));
        List<Case> updatedCase = emailMessageHelper.updateLastEmail(emlist,mapEmailMsgToCase);
        System.assert(!updatedCase.isEmpty(), 'Returned Cases should not be empty');
        System.assertNotEquals(updatedCase[0].Last_Email_to_Customer__c, null, 'Last email to customer should not be blank');
    }

    @isTest
    private static void testProactiveOutreachRecordType(){
        List<Case> caseList = TDdCaseFactory.createCaseRecords(1, CDdSupportConstants.RECORDTYPE_NAME_PROACTIVE_OUTREACH);
        insert caseList;
        caseList[0].Status = CDdSupportConstants.PENDING_STATUS;
        update caseList;

        List<EmailMessage> emlist = CDdTestDataFactory.createSObjectList('EmailMessage', 1, false);
        emlist[0].Subject = 'Test email';
        emList[0].Incoming = true;
        emlist[0].fromAddress = 'test.case@notrealemailaddress.com';
        emlist[0].toAddress = 'testcase@doordash.com';
        emlist[0].HtmlBody ='Test Case';
        emlist[0].fromName ='Test Name';
        emlist[0].ParentId = caseList[0].Id;
        Test.startTest();
        insert emList;
        Test.stoptest();
        List<Case> updatedCase = [SELECT Id, Status FROM Case WHERE Id = :caseList[0].Id];
        System.assertEquals(CDdSupportConstants.REOPEN_STATUS, updatedCase[0].Status, 'Case should be reopend');

    }

    public static testMethod void reOpenMOTest(){

        Id Market_Onboarding = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Marketplace Onboarding').getRecordTypeId();
        Id MarketPlace = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Marketplace').getRecordTypeId();

        List<Account> testAccounts = TDdAccountFactory.createAccounts('TestDDAccount', 1);
        testAccounts[0].recordtypeId = MarketPlace;
        testAccounts[0].Deck_Rank__c = 'Queen';
        insert testAccounts;

        List<Case> cslist = CDdTestDataFactory.createSObjectList('Case', 1, false);
        cslist[0].BusinessHours=null;
        cslist[0].Subject='testcasesubject';
        cslist[0].Case_Claimed__c=date.today();
        cslist[0].recordtypeid = Market_Onboarding;
        cslist[0].status = 'Closed';
        cslist[0].AccountId = testAccounts[0].id;
        insert cslist;

        List<EmailMessage> emlist = CDdTestDataFactory.createSObjectList('EmailMessage', 5, false);
        emlist[0].Subject='Incomplete Activation details';
        emlist[0].status='3';
        emlist[0].fromAddress='test.case@doordash.com';
        emlist[0].toAddress= CDdEmailMessageHelper.CAVIAR_RESTAURANTS_ROUTING_EMAIL;
        emlist[0].HtmlBody='Caviar Test Case';
        emlist[0].fromName='Test Name';
        emlist[0].ParentId=cslist[0].Id;

        Test.startTest();
        insert emlist;
        Test.stopTest();

        List<Case> updatedCase = [SELECT ID, Status FROM Case WHERE Id = :cslist[0].Id];
        System.assertEquals('Closed', updatedCase[0].Status, 'Should be Closed');
    }

    @isTest
    private static void reOpenCaviarOnboardingTest(){

        List<Case> caseList = TDdCaseFactory.createCaseRecords(1, CDdSupportConstants.RECORDTYPE_NAME_CAVIAR_ONBOADING);
        insert caseList;
        caseList[0].Status = CDdSupportConstants.CLOSED_STATUS;
        update caseList;

        List<EmailMessage> emlist = CDdTestDataFactory.createSObjectList('EmailMessage', 5, false);
        emlist[0].Subject='Test Caviar Status update';
        emlist[0].status='0';
        emList[0].Incoming = true;
        emlist[0].fromAddress='test.case@doordash.com';
        emlist[0].toAddress= CDdEmailMessageHelper.CAVIAR_RESTAURANTS_ROUTING_EMAIL;
        emlist[0].HtmlBody='Caviar Test Case';
        emlist[0].fromName='Test Name';
        emlist[0].ParentId=caseList[0].Id;

        Test.startTest();
        insert emlist;
        Test.stopTest();

        List<Case> updatedCase = [SELECT ID, Status FROM Case WHERE Id = :caseList[0].Id];
        System.assertEquals('Under Review', updatedCase[0].Status, 'Should be Updated to Under Review');
    }

    /**
     * @author      Mahesh Chouhan
     * @date        May 2023
     * @jira        https://doordash.atlassian.net/browse/BASD-47588
     * @description tests autoCreateClosedCaseResponse
     */
    @isTest
    static void testAutoCreateClosedCaseResponse(){
        List<Group> testQueueCase = [SELECT ID FROM Group WHERE Name = 'Test Case Queue'];
        List<Case> caseList = TDdCaseFactory.createSolveableSupportCase(1, CDdRecordTypeCase.customer());
        insert caseList;
        caseList[0].Status = CDdSupportConstants.CLOSED_STATUS;
        caseList[0].Previous_Queue_Id__c = testQueueCase[0].Id;
        caseList[0].To_Email_Address__c = 'support@doordash.com';
        update caseList;

        List<EmailMessage> emlist = CDdTestDataFactory.createSObjectList('EmailMessage', 1, false);
        emlist[0].Subject='Test Closed Case Reopen';
        emList[0].Incoming = true;
        emlist[0].fromAddress='test.case@test.com';
        emlist[0].toAddress= 'support@doordash.com';
        emlist[0].HtmlBody='Test Closed Case Reopen';
        emlist[0].fromName='Test Name';
        emlist[0].ParentId=caseList[0].Id;

        Test.startTest();
        insert emlist;
        Test.stopTest();

        List<Case> updatedCase = [SELECT ID, Origin FROM Case WHERE ParentId = :caseList[0].Id];
        System.assertEquals(CDdSupportConstants.ORIGIN_EMAIL_CLOSED_CASE_RESPONSE, updatedCase[0].Origin, 'Case Origin is not same as expected.');
    }
}