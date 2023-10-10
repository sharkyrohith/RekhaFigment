public with sharing class CDdContentDocumentTriggerHandler {
    public CDdContentDocumentTriggerHandler() {

    }

    public void beforeDelete(List<ContentDocument> oldList){
        String libraryName = Label.Bulk_Uploader_Content_Library_Name;
        List<ContentWorkspace> cws = [SELECT Id FROM ContentWorkspace WHERE DeveloperName = :libraryName];
        if (cws.size() > 0) {
            ContentWorkspace cw = cws.get(0);
            validateContentDeletion(oldList, cw);
        }
    }

    @TestVisible
    private void validateContentDeletion(List<ContentDocument> contentList, ContentWorkspace cw) {
        List<Id> contentListIds = new List<Id>();
        for (ContentDocument cd : contentList) {
            contentListIds.add(cd.Id);
        }

        List<ContentDocumentLink> cdls = [
                SELECT ContentDocumentId 
                FROM ContentDocumentLink 
                WHERE ContentDocumentId IN :contentListIds AND LinkedEntityId = :cw.Id];
        
        if (cdls.size() > 0) {
            List<Id> impactedContentDocuments = new List<Id>();
            for (ContentDocumentLink cdl : cdls) {
                impactedContentDocuments.add(cdl.ContentDocumentId);
            }

            for (ContentDocument cd : contentList) {
                if (impactedContentDocuments.contains(cd.Id)) {
                    cd.addError('Cannot delete a file from the Bulk Uploader CSV libary');
                }
            }
        }
    }
}