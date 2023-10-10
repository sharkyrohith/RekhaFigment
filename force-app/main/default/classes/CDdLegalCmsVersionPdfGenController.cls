/**
 * @author      Raju
 * @date        June 2022
 * @decription  BIZS-1390 - Controller of PDdLegalCmsVersionPdfGenerator - Generate PDF version Legal CMS Version code.
 */
 public with sharing class CDdLegalCmsVersionPdfGenController {
    public String displayText {get; set;}
    public String recordId {get;set;}

    public CDdLegalCmsVersionPdfGenController() {
        Map<String, String> params = ApexPages.currentPage().getParameters();
        recordId = params.get('recordId');
        Legal_CMS_Content_Version__c rec  = [SELECT Id,Name,Body_1__c,Body_2__c,Body_3__c,Body_4__c,Status__c
                                                    FROM Legal_CMS_Content_Version__c
                                                WHERE Id = :recordId];
        displayText = rec.Body_1__c +
            (String.isBlank(rec.Body_2__c) ? CDdCoreConstants.BLANK_STRING : rec.Body_2__c) +
            (String.isBlank(rec.Body_3__c) ? CDdCoreConstants.BLANK_STRING : rec.Body_3__c) +
            (String.isBlank(rec.Body_4__c) ? CDdCoreConstants.BLANK_STRING : rec.Body_4__c);
    }
}