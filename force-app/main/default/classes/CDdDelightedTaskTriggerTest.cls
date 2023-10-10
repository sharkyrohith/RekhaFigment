/**
 *
 * @author: Tia Xuan
 * @date: 2020-04
 * @description test class for CDdDelightedTaskTriggerHandler
 *
 */
@isTest
public class CDdDelightedTaskTriggerTest {
    @TestSetup
    static void setup(){
        TDdCaseFactory.getSupportFeatureFlag(true);
        vCS__c s = VTestUtil.createVeltigSettings();
        insert s;

        GDPR_Setting__c setting = new GDPR_Setting__c();
        setting.Enable_Delighted_Task_Trigger__c = true;
        insert setting;

        Account acct = VTestUtil.createAccount('Test Account', true);
        acct.Deck_Rank__c = 'Queen';
        insert acct;

        Contact ctc = VTestUtil.createContact('Test', 'tst', acct);
        ctc.FirstName = 'Door';
        ctc.LastName = 'Dash';
        ctc.Email = 'test@doordash.com';
        insert ctc;

        List<Case> css = TDdCaseFactory.createCaseRecords(1, 'Support');
        css[0].AccountId = acct.Id;
        css[0].ContactId = ctc.Id;
        insert css;
    }

    public static testMethod void updateCaseOnSent() {
        Case surveyCase = [SELECT  Id, Survey_Date_Sent__c
                            FROM Case][0];

        Test.startTest();

        Delighted_Tasks__c dt = new Delighted_Tasks__c();
        dt.Case__c = surveyCase.Id;
        dt.Survey__c = 'Menu Update';
        insert dt;

        Test.stopTest();

        Delighted_Tasks__c dtExpected = [SELECT  Id, Sent__c
                                         FROM Delighted_Tasks__c
                                         WHERE Id =: dt.Id];
        System.assertEquals(false, dtExpected.Sent__c, 'Sent field on Delighted Task is true.');
    }

    @isTest
    static void processDelightedSurveysNegative() {
        Case cse = TDdCaseFactory.createCaseRecords(1, 'Support')[0];
        cse.SuppliedEmail = null;
        insert cse;

        Test.startTest();

        Delighted_Tasks__c dt = new Delighted_Tasks__c();
        dt.Case__c = cse.Id;
        dt.Survey__c = 'Menu Update';
        insert dt;

        Test.stopTest();

        Delighted_Tasks__c dtExpected = [SELECT  Id, Sent__c, Error_Message__c
                                         FROM Delighted_Tasks__c
                                         WHERE Id =: dt.Id];
        System.assertEquals(false, dtExpected.Sent__c, 'Sent field on Delighted Task is true.');
        System.assertEquals('Request not sent due to missing email', dtExpected.Error_Message__c, 'Error Message on Delighted Task is not same as expected.');
    }

    public class MockHttpResponseGenerator implements HttpCalloutMock{
        public HttpResponse respond(HTTPRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(204);
            res.setBody('<PublishResponse xmlns="http://sns.amazonaws.com/doc/2010-03-31/"><PublishResult><SequenceNumber>10000000000103487000</SequenceNumber><MessageId>c029e41f-db4e-562c-896a-bfbc6f6dcde6</MessageId></PublishResult></PublishResponse>');
            return res;
        }
    }

    @isTest
    static void processQualtricSurveys() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Case cse = TDdCaseFactory.createCaseRecords(1, 'Support')[0];
        cse.SuppliedEmail = 'jose.vega@ext.doordash.com';
        cse.Language__c = 'German';
        insert cse;

        Test.startTest();

        Delighted_Tasks__c dt = new Delighted_Tasks__c();
        dt.Case__c = cse.Id;
        dt.Survey_Provider__c = CDdSupportConstants.SURVEY_PROVIDER_QUALTRICS;
        dt.Survey__c = 'Menu Update';
        dt.Language__c = 'German';

        insert dt;

        Test.stopTest();

        Delighted_Tasks__c dtExpected = [SELECT  Id, Sent__c, Error_Message__c
                                         FROM Delighted_Tasks__c
                                         WHERE Id =: dt.Id];
        System.assertEquals(true, dtExpected.Sent__c, 'Sent field on Delighted Task is false.');
    }
}