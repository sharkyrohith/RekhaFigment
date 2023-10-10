/**
 * @author: Raju Lakshman
 * @date: June 2021
 * @description Validate the Status change of the Legal CMS Content Version Record
 */
public without sharing class CTrLegalCmsVersionGeneratePDF extends CDdTriggerHandler {
    private List<Legal_CMS_Content_Version__c> triggerList;
    private Map<Id, Legal_CMS_Content_Version__c> triggerMapOld;
    private static final string TEST_BODY = 'Test Body';

    /**
     * @description Constructor that sets class variables based on Trigger context vars
     */
    public CTrLegalCmsVersionGeneratePDF() {
        Boolean isDelete = getTriggerContext() == CDdTriggerHandler.TriggerContext.BEFORE_DELETE ||
                           getTriggerContext() == CDdTriggerHandler.TriggerContext.AFTER_DELETE;
        this.triggerList = isDelete ? (List<Legal_CMS_Content_Version__c>)trigger.old : (List<Legal_CMS_Content_Version__c>)trigger.new;
        this.triggerMapOld = (Map<Id, Legal_CMS_Content_Version__c>) Trigger.oldMap;
    }

    /**
     * @description Overriden event handlers.
     */
    public override void afterUpdate() {
        generatePDF();
    }

    /**
     * @description Generate a PDF for the published version
     */
    private void generatePDF() {
        List<String> toProcess = new List<String>();

        for (Legal_CMS_Content_Version__c rec : triggerList) {
            if (rec.Status__c == CDdSupportConstants.STATUS_PUBLISHED && isFieldUpdated(rec,'Status__c')) {
                toProcess.add(rec.Id);
            }
        }
        if (!toProcess.isEmpty() ) {
            generatePdfHelper(toProcess);
        }
    }

    /**
     * @description Generate PDF Asynchronously
     * @param       legalContentVersionIds - List of records to generate PDF.
     */
    @future(callout=true)
    public static void generatePdfHelper(List<String> legalContentVersionIds) {

        List<Attachment> toAttach = new List<Attachment>();
        for (Legal_CMS_Content_Version__c rec : [SELECT Id,Name,Body_1__c,Body_2__c,Body_3__c,Body_4__c,Status__c
                                                    FROM Legal_CMS_Content_Version__c
                                                WHERE Id in :legalContentVersionIds]) {
            Pagereference pg = Page.PDdLegalCmsVersionPdfGenerator;
            pg.getParameters().put('recordId', rec.Id);
            Attachment objAttachment = new Attachment();
            objAttachment.Name = rec.Name + '.pdf';
            objAttachment.ParentId = rec.Id;
            objAttachment.Body = Test.isRunningTest() ? Blob.valueOf(TEST_BODY) : pg.getContentaspdf();
            objAttachment.IsPrivate = false;
            toAttach.add(objAttachment);
        }
        insert toAttach;
    }
}