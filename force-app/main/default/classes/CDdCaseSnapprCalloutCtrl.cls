public with sharing class CDdCaseSnapprCalloutCtrl {
    public static final vCS__c SETTINGS = vCS__c.getInstance();
    final ApexPages.StandardController controller;
    Case currCase;

    public CDdCaseSnapprCalloutCtrl(ApexPages.StandardController controller) {
        // addFields doesn't work during test execution
        if (!Test.isRunningTest()) {
            controller.addFields(new String[]{'Kodakit_Error__c'});
            controller.addFields(new String[]{'Photo_Provider__c'});
            controller.addFields(new String[]{'Kodakit_Job_Id__c'});
            // Adding below fields as per BASD-42481
            controller.addFields(new String[]{'Opportunity_Name__c', 'Menu_Preview_Links__c', 'Photoshoot_Date__c', 'Photoshoot_Time__c', 'OwnerId', 'Shipping_Address_Country__c', 'Return_Shipping_Address_State__c'});
        }

    	this.currCase = (Case) controller.getRecord();
        this.controller = controller;
    }

    public PageReference makeSnapprCallout() {
        system.debug('Error: ' + currCase.Kodakit_Error__c);
        system.debug('Settings: ' + SETTINGS.APICalloutToKodakit__c);
        system.debug('Provider: ' + currCase.Photo_Provider__c);
        system.debug('vCS: ' + SETTINGS);
        /*BZAP-12852 - Retrigger OCUS Assignment on Classic*/
        if(currCase.Photo_Provider__c == 'OCUS'){
            if(String.isBlank(currCase.Kodakit_Job_Id__c)){
                if(currCase.Opportunity_Name__c == null || currCase.Menu_Preview_Links__c == null ||
                    (currCase.Photoshoot_Date__c == null && currCase.Photoshoot_Time__c != null) ||
                    (currCase.Photoshoot_Date__c != null && currCase.Photoshoot_Time__c == null)){
                        CDdOCUSAPIHandler.validateOCUSData(new List<Case> { this.currCase }, False);
                    } else {
                        CDdOCUSAPIHandler.createOCUSPhotoshoot( new List<Id> { this.currCase.Id });
                    }
                return new PageReference('/' + String.valueOf(currCase.Id));
            }else{
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.Info, 'You do not need to schedule another photoshoot'));
            }
        }else{
            if (String.isBlank(currCase.Kodakit_Error__c) ||
                SETTINGS.APICalloutToKodakit__c == false ||
                currCase.Photo_Provider__c != 'Snappr') {
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.Info, 'You do not need to schedule another photoshoot'));
            } else {
                CDdSnapprAPIHandler.createPhotoshoot(new Set<Id> { this.currCase.Id });
                return new PageReference('/' + String.valueOf(currCase.Id));
            }
        }
        return null;
    }
}