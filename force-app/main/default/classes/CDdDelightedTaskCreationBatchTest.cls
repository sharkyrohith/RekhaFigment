@isTest
public with sharing class CDdDelightedTaskCreationBatchTest {
    @isTest static void testSurveyWebCaseQualtrics() {

        Support_Feature_Flag__c featureFlag = Support_Feature_Flag__c.getOrgDefaults();
        featureFlag.Enable_Qualtrics_Surveys__c = true;
        upsert featureFlag;
        Account webAcct = TDdAccountFactory.createAccounts('webAcct', 1, 'Marketplace')[0];
        webAcct.Is_Partner__c = 'Yes';
        insert webAcct;
        Contact webContact = TDdAccountFactory.createContacts(1, webAcct.Id)[0];
        insert webContact;
        Case webCase = TDdCaseFactory.createSolveableSupportCase(1, 'Support', webAcct.Id, webContact.id)[0];
        webCase.Origin = 'Facebook';
        webCase.Status = 'Open';
        webCase.Language__c = 'English';
        CDdCaseTriggerHelperV2.ranSurveySend = true;
        insert webCase;
        webCase.Status = 'Solved';
        update webcase;
        Test.startTest();
        CDdCaseTriggerHelperV2.ranSurveySend = false;
        CDdDelightedTaskCreationBatch batch = new CDdDelightedTaskCreationBatch();
        SchedulableContext sc = null;
        batch.execute(sc);
        Test.stopTest();
        webCase = [Select id, Delighted_Task_Created__c, Status  from Case where id =: webCase.Id];
        System.assertNotEquals(null, webCase.Delighted_Task_Created__c);
        Delighted_Tasks__c task = [Select id, Survey_Provider__c from Delighted_Tasks__c where case__c =: webCase.id][0];
        System.assertEquals(CDdSupportConstants.SURVEY_PROVIDER_QUALTRICS, task.Survey_Provider__c);
    }

}