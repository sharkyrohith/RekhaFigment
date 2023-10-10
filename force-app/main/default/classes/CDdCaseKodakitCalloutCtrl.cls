public with sharing class CDdCaseKodakitCalloutCtrl {
    public static final vCS__c SETTINGS = vCS__c.getInstance();
    final ApexPages.StandardController controller;
    Case currCase;
    
    public CDdCaseKodakitCalloutCtrl(ApexPages.StandardController controller) {
        // addFields doesn't work during test execution
        if (!Test.isRunningTest()) {
            controller.addFields(new String[]{'Kodakit_Error__c'});
            controller.addFields(new String[]{'Photo_Provider__c'});
        } 

    	this.currCase = (Case) controller.getRecord();    
        this.controller = controller;
    }
    
    public PageReference makeKodakitCallout() {
        if (String.isBlank(currCase.Kodakit_Error__c) || 
            SETTINGS.APICalloutToKodakit__c == false || 
            currCase.Photo_Provider__c != 'Kodakit') {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.Info, 'You do not need to schedule another photoshoot'));            
        } else {
            CDdKodakitSvc.createPhotoshoot(new List<Id> { this.currCase.Id });
            return new PageReference('/' + String.valueOf(currCase.Id));
        }
        return null;
    }
}