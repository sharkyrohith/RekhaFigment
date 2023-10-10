@istest
private class ViewSurveyController_Test{
    //------------------------------------------------------------------------------//
    //------------------------------------------------------------------------------//
    private static Testmethod void testViewSurveyController() {
        
        Trigger_Control_Panel__c testTCP = new Trigger_Control_Panel__c(
			Name = 'Control Panel',
			Account_Trigger_Enabled__c = false,
			Opportunity_Trigger_Enabled__c = false
		);
        insert testTCP;
        
        Id prospectRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Marketplace').getRecordTypeId();
        Account testAccount = new Account(RecordTypeId=prospectRecordTypeId,
            							 Name='TestAccount (');
                                         
        insert testAccount;
        
        Id supportRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support').getRecordTypeId();
        Case testCase = new Case(RecordTypeId=supportRecordTypeId,
                                Status='New',
                               	Origin='Web');
        insert testCase;
        
        SurveyTestingUtil tu = new SurveyTestingUtil();
        Apexpages.currentPage().getParameters().put('id',tu.surveyId);
        Apexpages.currentPage().getParameters().put('caId',testCase.Id);
        Apexpages.Standardcontroller stc;
        ViewSurveyController vsc = new ViewSurveyController(stc); 
        vsc.init();
        System.assert(vsc.allQuestionsSize == 4);
        System.assert(tu.surveyId != null);


        vsc.submitResults();
        for (SFQuestion q : vsc.allQuestions)
        {
            q.selectedOption = String.valueof(2);
            q.choices = String.valueof(2);
            q.selectedOptions = new List<String>();
            q.selectedOptions.add(String.valueof(2));
            vsc.submitResults();
        }
        System.assertEquals(true, vsc.thankYouRendered);
	
		List<String> testResponses = vsc.getResponses();
        //test something
    }


    private static Testmethod void testUpdateSurveyName() {
        SurveyTestingUtil tu = new SurveyTestingUtil();
        Apexpages.currentPage().getParameters().put('id',tu.surveyId);
        Apexpages.Standardcontroller stc;
        ViewSurveyController vsc = new ViewSurveyController(stc);
        vsc.surveyName = 'new name';
        system.assert(vsc.updateSurveyName() == null);

    }


    private static Testmethod void testupdateSurveyThankYouAndLink() {
        SurveyTestingUtil tu = new SurveyTestingUtil();
        Apexpages.currentPage().getParameters().put('id',tu.surveyId);
        Apexpages.Standardcontroller stc;
        ViewSurveyController vsc = new ViewSurveyController(stc);
        vsc.surveyThankYouText = 'new stuff';
        vsc.surveyThankYouURL = 'more new stff';
        system.assert(vsc.updateSurveyThankYouAndLink()==null);
    }


}