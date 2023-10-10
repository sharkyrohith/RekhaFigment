/*
* @author sarah.beccari@atginfo.com
* Controller class for ApprovalEmailTemplateComponent
*/

public class ApprovalEmailController {

    public Id quoteId {get; set;}

    public List<SBQQ__QuoteLine__c> emailTemplateQuoteLines {get{
        if(emailTemplateQuoteLines == null) {
            emailTemplateQuoteLines = [
                SELECT Id, SBQQ__Number__c, SBQQ__ProductName__c, Trial_Period__c, Trial_Commission__c, Final_Commission__c,
                    Original_Commission__c, SBQQ__NetPrice__c, SBQQ__ListPrice__c, Final_Fee__c
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Quote__c = :quoteId
                ORDER BY SBQQ__Number__c
            ];
        }        
        return emailTemplateQuoteLines;
    } set;}

    public ApprovalEmailController(){
        // this constructor is called from the ApprovalEmailTemplateComponent
    }

}