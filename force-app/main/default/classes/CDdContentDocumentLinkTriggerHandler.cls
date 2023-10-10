/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 03/08/2021
*
* @group Trigger Handler
*
* @description Trigger handler method implementation for Content Link Document
**************************************************************************************************************************************/
public class CDdContentDocumentLinkTriggerHandler{

    public void beforeInsert(List<ContentDocumentLink> newList) {
        List<ContentDocumentLink> contentDocumentLinks = CDdContentDocumentLinkHelper.excludeWorkspaceContents(newList);
        if (!contentDocumentLinks.isEmpty()){
            CDdContentDocumentLinkHelper.validateContentDocumentExists(contentDocumentLinks, CDdContentDocumentLinkHelper.SOBJECT_TYPE_MERCHANT_DOCUMENT, CDdContentDocumentLinkHelper.ERROR_MESSAGE_CONTENT_DOCUMENT_EXISTS);
        }
    }

    public void afterInsert(List<ContentDocumentLink> newList) {
        List<ContentDocumentLink> contentDocumentLinks = CDdContentDocumentLinkHelper.excludeWorkspaceContents(newList);
        if (!contentDocumentLinks.isEmpty()){
            CDdContentDocumentLinkHelper.updateLinkedEntityRecord(contentDocumentLinks, CDdContentDocumentLinkHelper.SOBJECT_TYPE_MERCHANT_DOCUMENT);
        }
    }

    public void afterDelete(Map<Id, ContentDocumentLink> oldMap) {
        List<ContentDocumentLink> contentDocumentLinks = CDdContentDocumentLinkHelper.excludeWorkspaceContents(oldMap.values());
        if (!contentDocumentLinks.isEmpty()){
            CDdContentDocumentLinkHelper.removeReferenceOnLinkedEntityRecord(contentDocumentLinks, CDdContentDocumentLinkHelper.SOBJECT_TYPE_MERCHANT_DOCUMENT);
        }
    }

}