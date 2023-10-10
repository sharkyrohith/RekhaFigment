/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 03/08/2021
*
* @group ContentDocumentLink
*
* @description ContentDocumentLink related functions are defined here
* 
**************************************************************************************************************************************/
public class CDdContentDocumentLinkHelper {

    public static final String SOBJECT_TYPE_MERCHANT_DOCUMENT = 'Merchant_Document__c';
    public static final String ERROR_MESSAGE_CONTENT_DOCUMENT_EXISTS = 'You are only able to add a single file to this Document. Please remove the previous file before adding this one';    
    public static final String CONTENT_DOCUMENT_URL = URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/r/ContentDocument/{0}/view';
    public static final Set<String> WORKSPACE_IDS = new Set<String>(System.Label.FILE_LIBRARY_IDS.split(','));
    public static final Id USER_ID = UserInfo.getUserId();
    /**
     * Process the Collection to exclude Workspace Contents
     */ 
    public static List<ContentDocumentLink> excludeWorkspaceContents(List<ContentDocumentLink> contentDocumentLinks){
        List<ContentDocumentLink> retVal = new List<ContentDocumentLink>();
        for (ContentDocumentLink cdl : contentDocumentLinks){
            if (String.isNotBlank(cdl.LinkedEntityId) 
                && !WORKSPACE_IDS.contains(cdl.LinkedEntityId)
                && !USER_ID.equals(cdl.LinkedEntityId)){
                retVal.add(cdl);
            }
        }
        return retVal;
    }
    /**
     * Construct and return the content document URL
     */
    public static String getContentDocumentURL(Id contentDocumentId){
        return String.format(CONTENT_DOCUMENT_URL, new List<String>{contentDocumentId});
    }
    /**
     * Extract and return a Collection of LinkedEntity Ids for the input Content Document Links
     */    
    public static Set<Id> getLinkedEntityIds(List<ContentDocumentLink> contentDocumentLinks, String linkedEntitySObjectType){
        Set<Id> linkedEntityIds = new Set<Id>();
        for (ContentDocumentLink cdl : contentDocumentLinks){
            if (String.isNotBlank(cdl.LinkedEntityId) && cdl.LinkedEntityId.getSObjectType().getDescribe().getName().equals(linkedEntitySObjectType)){
                linkedEntityIds.add(cdl.LinkedEntityId);
            }
        }
        return linkedEntityIds;
    }
    /**
     * Perform a check if the input record Ids are already associated with a Content Document
     */
    public static Map<Id, Boolean> isRecordLinkedToContentDocument(Set<Id> recordIds){
        Map<Id, Boolean> isLinkedToDocument = new Map<Id, Boolean>();
        if (!recordIds.isEmpty()){
            // Initialize the Collection and default the linked to Document as false
            for (Id recordId : recordIds){
                isLinkedToDocument.put(recordId, false);
            }
            // Perform a check and update the Boolean 'linked to Document' to true, 
            //     if found to be already linked to a Content Document
            for (ContentDocumentLink cdl : [SELECT Id, LinkedEntityId
                                            FROM ContentDocumentLink
                                            WHERE LinkedEntityId IN :recordIds]){
                isLinkedToDocument.put(cdl.LinkedEntityId, true);                                           
            }
        }
        return isLinkedToDocument;
    }
    /**
     * Return the following collection for the input ContentDocumentLink objects and the linked entity sObjectType
     * Key - LinkedEntityId
     * Value - ContentDocumentId
     */    
    public static Map<Id, Id> getContentDocumentIdForLinkedEntityId(List<ContentDocumentLink> contentDocumentLinks, String linkedEntitySObjectType){
        Map<Id, Id> contentDocumentIdForLinkedEntityId = new Map<Id, Id>();
        Set<Id> linkedEntityIds = getLinkedEntityIds(contentDocumentLinks, linkedEntitySObjectType);
        for (ContentDocumentLink cdl : contentDocumentLinks){
            if (String.isNotBlank(cdl.LinkedEntityId) && linkedEntityIds.contains(cdl.LinkedEntityId)){
                contentDocumentIdForLinkedEntityId.put(cdl.LinkedEntityId, cdl.ContentDocumentId);
            }
        }
        return contentDocumentIdForLinkedEntityId;
    }
    /**
     * Return the following collection for the input ContentDocumentLink objects and the linked entity sObjectType
     * Key - LinkedEntityId
     * Value - ContentVersion Object
     */       
    public static Map<Id, ContentVersion> getContentVersionForLinkedEntityId(List<ContentDocumentLink> contentDocumentLinks, String linkedEntitySObjectType){
        Map<Id, ContentVersion> contentVersionForLinkedEntityId = new Map<Id, ContentVersion>();
        Map<Id, Id> contentDocumentIdForLinkedEntityId = getContentDocumentIdForLinkedEntityId(contentDocumentLinks, linkedEntitySObjectType);
        for (ContentVersion cv : [  SELECT Id, ContentDocumentId
                                    FROM ContentVersion 
                                    WHERE ContentDocumentId IN :contentDocumentIdForLinkedEntityId.values() 
                                    AND IsLatest=true
                                ] ){
            for (Id linkedEntityId : contentDocumentIdForLinkedEntityId.keySet()){
                Id contentDocumentId = contentDocumentIdForLinkedEntityId.get(linkedEntityId);
                if (String.isNotBlank(cv.ContentDocumentId) && cv.ContentDocumentId.equals(contentDocumentId)){
                    contentVersionForLinkedEntityId.put(linkedEntityId, cv);
                    continue;
                }
            }
        }
        return contentVersionForLinkedEntityId;
    }
    /**
     * Validate if the input record Id (or Linked Entity Id) is already associated with a Content Document
     * The validation is performed for a specific Linked Entity SObject Type
     */      
    public static void validateContentDocumentExists(List<ContentDocumentLink> contentDocumentLinks, String linkedEntitySObjectType, String errorMessage){
        Set<Id> linkedEntityIds = getLinkedEntityIds(contentDocumentLinks, linkedEntitySObjectType);
        Map<Id, Boolean> contentDocumentExists = isRecordLinkedToContentDocument(linkedEntityIds);
        for (ContentDocumentLink cdl : contentDocumentLinks){
            if (contentDocumentExists.containsKey(cdl.LinkedEntityId) && contentDocumentExists.get(cdl.LinkedEntityId) == true){
                cdl.addError(errorMessage);
            }
        }
    }
    /**
     * Update the corresponding Linked Entity record
     */ 
    public static void updateLinkedEntityRecord(List<ContentDocumentLink> contentDocumentLinks, String linkedEntitySObjectType){
        List<String> errorMessages = new List<String>();
        try {  
            Set<Id> linkedEntityIds = getLinkedEntityIds(contentDocumentLinks, linkedEntitySObjectType);
            Map<Id, ContentVersion> contentVersionForLinkedEntityId = getContentVersionForLinkedEntityId(contentDocumentLinks, linkedEntitySObjectType);
            switch on linkedEntitySObjectType {
                when 'Merchant_Document__c' {
                    List<Merchant_Document__c> merchantDocumentsToUpdate = new List<Merchant_Document__c>();
                    for (Id linkedEntityId : linkedEntityIds){
                        ContentVersion contentVersion = contentVersionForLinkedEntityId.get(linkedEntityId);
                        Id contentVersionId = contentVersion.Id;
                        Id contentDocumentId = contentVersion.ContentDocumentId;
                        merchantDocumentsToUpdate.add(
                            new Merchant_Document__c(
                                Id = linkedEntityId,
                                File_URL__c = getContentDocumentURL(contentDocumentId),
                                Content_Version_Id__c = contentVersionId
                            )
                        );
                    }
                    if(!merchantDocumentsToUpdate.isEmpty()) {
                        List<Database.SaveResult> sResults = Database.update(merchantDocumentsToUpdate, false);
                        errorMessages = CDdErrorUtilities.processSaveResults(sResults, errorMessages);
                    }
                }
                when else {}
            }
        } catch (Exception e) {
            errorMessages.add(e.getStackTraceString());
            throw e;
        } finally {
            CDdErrorUtilities.createApexLogs(errorMessages, 'CDdContentDocumentLinkHelper', 'updateLinkedEntityRecord', LoggingLevel.ERROR);
        }                 
    }
    /**
     * Remove the reference on the corresponding Linked Entity record
     */ 
    public static void removeReferenceOnLinkedEntityRecord(List<ContentDocumentLink> contentDocumentLinks, String linkedEntitySObjectType){
        List<String> errorMessages = new List<String>();
        try {  
            Set<Id> linkedEntityIds = getLinkedEntityIds(contentDocumentLinks, linkedEntitySObjectType);
            switch on linkedEntitySObjectType {
                when 'Merchant_Document__c' {
                    List<Merchant_Document__c> merchantDocumentsToUpdate = new List<Merchant_Document__c>();
                    for (Id linkedEntityId : linkedEntityIds){
                        merchantDocumentsToUpdate.add(
                            new Merchant_Document__c(
                                Id = linkedEntityId,
                                File_URL__c = null,
                                Content_Version_Id__c = null
                            )
                        );
                    }
                    if(!merchantDocumentsToUpdate.isEmpty()) {
                        List<Database.SaveResult> sResults = Database.update(merchantDocumentsToUpdate, false);
                        errorMessages = CDdErrorUtilities.processSaveResults(sResults, errorMessages);
                    }
                }
                when else {}
            }
        } catch (Exception e) {
            errorMessages.add(e.getStackTraceString());
            throw e;
        } finally {
            CDdErrorUtilities.createApexLogs(errorMessages, 'CDdContentDocumentLinkHelper', 'removeReferenceOnLinkedEntityRecord', LoggingLevel.ERROR);
        }                 
    }    
}