/**
* @author: Critical River
* @date: 2023-05
* @description Trigger handler for ContentVersion.
*/
public class CDdContentVersionTriggerHandler {
    /**
     * @description handle the before insert event
     */
    public void beforeInsert(List<ContentVersion> newList){
        CDdMxDocumentService.associateContentDocument(filterMxDocuments(newList));
    }
    /**
     * @description handle the after insert event
     */
    public void afterInsert(List<ContentVersion> newList) {
        CDdMxDocumentService.addMxDocumentToLibrary(filterMxDocuments(newList));
    }

    /**
     * @description Purpose of this method is to filter out the Mx Documents for further processing within the Mx Document framework
     * Criteria for Mx Document is as follows:
     * - Mx_Store_Id__c IS NOT NULL
     * - Mx_Document_Type__c IS NOT NULL
     * @param List<ContentVersion> newList
     * @return A collection of Mx Documents
     */
    private List<ContentVersion> filterMxDocuments(List<ContentVersion> newList){
        List<ContentVersion> mxContentVersionList = new List<ContentVersion>();
        for(ContentVersion cv : newList){
            if(String.isNotBlank(cv.Mx_Document_Type__c) && String.isNotBlank(cv.Mx_Store_Id__c)){
                mxContentVersionList.add(cv);
            }
        }
        return mxContentVersionList;
    }
}