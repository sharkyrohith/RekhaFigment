/**
 * @author      Raju
 * @date        June 2022
 * @decription  BIZS-1390 - Controller for Legal CMS Version code
 */
public with sharing class CDdLegalCmsVersionController {
    /**
     * @author      Raju
     * @date        June 2022
     * @decription  Gets the Published Version for any Parent Legal CMS Content record
     * @param   parentId {String} - Legal CMS Content record Id
     * @return  Legal_CMS_Content_Version__c record - currently published one
     */
    @AuraEnabled(cacheable=true)
    public static Legal_CMS_Content_Version__c getPublishedVersion(String parentId){
        if (parentId == null) {
            return null;
        }
        List<Legal_CMS_Content_Version__c> versions = [
            SELECT Id,Major_Version__c,Minor_Version__c,Published_Date__c,Body_1__c,Body_2__c,Body_3__c,Body_4__c
              FROM Legal_CMS_Content_Version__c
             WHERE Parent__c = :parentId
               AND Status__c = 'Published'
          ORDER BY Published_Date__c desc
             LIMIT 1
        ];
        return versions.isEmpty() ? null : versions[0];
    }

    /**
     * @author      Raju
     * @date        June 2022
     * @decription  Gets the Parent Legal CMS Content record and its child Published Version.
     *              Note - this is not set as cacheable as the cache is messing up with correct record fetch.
     * @param   contentId {String} - Legal CMS Content record Id
     * @return  Legal_CMS_Content__c record - CMS Record
     */
    @AuraEnabled
    public static Legal_CMS_Content__c getLegalCmsContentWithPublishedVersion(String contentId){
        List<Legal_CMS_Content__c> contents = [
            SELECT Id,Name,Max_Version_JSON__c,
                   (SELECT Id,Major_Version__c,Minor_Version__c,Published_Date__c,Body_1__c,Body_2__c,Body_3__c,Body_4__c
                      FROM Legal_CMS_Content_Versions__r
                     WHERE Status__c = 'Published'
                  ORDER BY Published_Date__c desc)
              FROM Legal_CMS_Content__c
             WHERE Id = :contentId
        ];
        return contents.isEmpty() ? null : contents[0];
    }

    /**
     * @author      Raju
     * @date        June 2022
     * @decription  Called from LwcDdLegalCmsVersionPublishQuickAction. Publishes a version, and sets previous published version to archived.
     * @param   versionIdToPublish {String} - Record id to publish
     * @param   parentId {String} - Parent Content CMS id - used to fetch version to archive.
     */
    @AuraEnabled
    public static void publishContentVersion(String versionIdToPublish,String parentId){
        try {
            List<Legal_CMS_Content_Version__c> toUpdate = new List<Legal_CMS_Content_Version__c>();

            Legal_CMS_Content_Version__c currentPublished = getPublishedVersion(parentId);
            if (currentPublished != null) {
                currentPublished.Status__c = CDdSupportConstants.STATUS_ARCHIVED;
                toUpdate.add(currentPublished);
            }
            toUpdate.add(new Legal_CMS_Content_Version__c(
                    Id = versionIdToPublish,
                    Status__c = CDdSupportConstants.STATUS_PUBLISHED,
                    Published_Date__c = System.today(),
                    Previous_Published__c = currentPublished != null ? currentPublished.Id : null
                )
            );
            update toUpdate;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @author      Raju
     * @date        June 2022
     * @decription  Check if user has access to publish content
     */
    @AuraEnabled(cacheable = true)
    public static Boolean canPublish() {
        return FeatureManagement.checkPermission(CDdCustomPermissionConstants.LEGAL_CMS_CONTENT_PUBLISH);
    }


    /**
     * @author      Raju
     * @date        June 2022
     * @decription  Check if user has access to edit content version body
     */
    @AuraEnabled(cacheable = true)
    public static Boolean canEditContentVersion() {
        return Schema.sObjectType.Legal_CMS_Content_Version__c.isUpdateable() && Schema.sObjectType.Legal_CMS_Content_Version__c.fields.Body_1__c.isUpdateable();
    }
}