/**
* @author Tia Xuan  
* @date 2022-01
*
* @description Test class for CDdACSurvey Batch claases
*/

@isTest
public class CDdACSurveyTest {

    @TestSetup
    static void setup(){
        Support_Settings__c setting = Support_Settings__c.getInstance();
        setting.AC_Survey_Batch_Size__c = 50;
        setting.AC_Survey_Batch_Days__c = 90;
        insert setting;

        List<Case> cases = TDdCaseFactory.createCaseRecords(1, 'Support');
        insert cases;
        List<Account> accounts = TDdAccountFactory.createAccounts('TestAcct', 1);
        insert accounts; 
        List<Contact> contacts = TDdAccountFactory.createContacts(1, accounts[0].id);
        Survey__c s = new Survey__c();
        s.Name = 'test';
        insert s;

        Survey_Question__c quest = new Survey_Question__c();
        quest.Name = 'test';
        quest.Survey__c = s.Id;
        quest.Question__c = 'test';
        quest.OrderNumber__c = 1;
        insert quest;


        CDdACSurveyHelper.ACSurveyResponse resp = new CDdACSurveyHelper.ACSurveyResponse();
        resp.response =  'test';
        resp.surveyQuestion = quest.Id;
        resp.ofTimeQuestionWasRespondedTo = 1;
        
        List<CDdACSurveyHelper.ACSurveyResponse> respList = new List<CDdACSurveyHelper.ACSurveyResponse> {resp};

        CDdACSurveyHelper.ACSurvey survey = new CDdACSurveyHelper.ACSurvey();
        survey.contactId = 'test';
        survey.StreamDeliveryName = 'test'; 
        survey.caseId = cases[0].Id; 
        survey.surveyAssignedTo = 'test@test.com'; 
        survey.ownerId = UserInfo.GetUserId();
        survey.survey = s.Id; 
        survey.taken = 'true'; 
        survey.responses = respList; 
        survey.SFContactId = String.valueOf(contacts[0].Id);
        survey.SFAccountId = String.valueOf(accounts[0].Id);
        survey.WorkflowId = '171';

        AC_Survey_Task__c tsk = new AC_Survey_Task__c();
        tsk.Contact_ID__c = 'test';
        tsk.Body__c = JSON.serialize(survey);
        insert tsk;
    }

    /**
    * @description test batch for AC Survey
    */
    @isTest static void testBatch() {
        Test.startTest();
        CDdACSurveyBatch batch = new CDdACSurveyBatch();
        Database.executeBatch(batch, 50);
        Test.stopTest();

        List<SurveyTaker__c> st = [select Id from SurveyTaker__c];
        System.assert(st.size() == 1, 'No survey recorded');
    }

    /**
    * @description test scheduler for AC Survey
    */
    @isTest static void testSchedule() {
        Test.startTest();
        CDdACSurveySched sch = new CDdACSurveySched();
        sch.execute(null);
        Test.stopTest();

        List<SurveyTaker__c> st = [select Id from SurveyTaker__c];
        System.assert(st.size() == 1, 'No survey recorded');
    }
}