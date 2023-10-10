public with sharing class AQS_QuoteExtController {

    private Id quoteId;
    
    public AQS_QuoteExtController(ApexPages.StandardController stdController) {
        quoteId = stdController.getId();
        if (quoteId == null) {
            quoteId = System.currentPageReference().getParameters().get('id');
        }
    }
    
    public PageReference onSubmit() {
        
        try {
            if (quoteId != null) {
                SBAA.ApprovalAPI.submit(quoteId, SBAA__Approval__c.AQS_Quote__c);
            } 
        } 
        // Approval Enablement Package 4.0 - Catch any errors (Validation, Apex) during approval process
        catch(Exception ex) {
            ApexPages.addMessages(ex);
            return null;
        }
        
        // Approval Enablement Package 4.0 - If no error then return user to the quote page
        PageReference pr = new PageReference('/' + quoteId);
        pr.setRedirect(true);
        return pr;
    }
    
    public PageReference onRecall() {
        try {
            if (quoteId != null) {
                SBAA.ApprovalAPI.recall(quoteId, SBAA__Approval__c.AQS_Quote__c);
            }
        }
        // Approval Enablement Package 4.0 - Catch any errors (Validation, Apex) during approval process
        catch(Exception ex) {
            ApexPages.addMessages(ex);
            return null;
        }

        // Approval Enablement Package 4.0 - If not error, return to quote page
        PageReference pr = new PageReference('/' + quoteId);
        pr.setRedirect(true);
        return pr;
    }

    // Approval Enablement Package 4.0 - Show a Cancel button on the page if an error occurs
    public PageReference onCancel() {
        return new PageReference('/' + quoteId);
    }
}