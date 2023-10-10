/**
 * @author: Raju Lakshman
 * @date: June 2021
 * @description Update the Name field from the Type, Country and Language fields / force unique across these three fields.
 */
public without sharing class CTrLegalCmsUpdateNameAndUniqueKey extends CDdTriggerHandler {
    private List<Legal_CMS_Content__c> triggerList;
    private Map<Id, Legal_CMS_Content__c> triggerMapOld;

    /**
     * @description Constructor that sets class variables based on Trigger context vars
     */
    public CTrLegalCmsUpdateNameAndUniqueKey() {
        Boolean isDelete = getTriggerContext() == CDdTriggerHandler.TriggerContext.BEFORE_DELETE ||
                           getTriggerContext() == CDdTriggerHandler.TriggerContext.AFTER_DELETE;
        this.triggerList = isDelete ? (List<Legal_CMS_Content__c>)trigger.old : (List<Legal_CMS_Content__c>)trigger.new;
        this.triggerMapOld = (Map<Id, Legal_CMS_Content__c>) Trigger.oldMap;
    }

    /**
     * @description Overriden event handlers.
     */

    public override void beforeInsert() {
        updateNameAndUniqueKey();
    }

    public override void beforeUpdate() {
        updateNameAndUniqueKey();
    }

    /**
     * @description Updating the Name
     */
    private void updateNameAndUniqueKey() {
        for (Legal_CMS_Content__c rec : triggerList) {
            if (isNewOrFieldUpdated(rec, 'Type__c') || isNewOrFieldUpdated(rec, 'Country__c') || isNewOrFieldUpdated(rec, 'Language__c') ||
            isNewOrFieldUpdated(rec, 'Country_Code__c') || isNewOrFieldUpdated(rec, 'Salesforce_Language_Code__c')) {
                rec.Name = getKey(rec,CDdCoreConstants.DELIMITER_HYPHEN_WITH_SPACE,true);
                rec.Unique_Key__c = getKey(rec,CDdCoreConstants.DELIMITER_HYPHEN,false);
            }
        }
    }

    /**
     * @description Combine fields to get the key
     * @param rec {Legal_CMS_Content__c} - record to be processed
     * @param delimiter {String} - Delimiter
     * @return String
     */
    private String getKey(Legal_CMS_Content__c rec, String delimiter, Boolean shouldTruncate) {
        String key = rec.Type__c + delimiter + rec.Country__c + delimiter + rec.Language__c;
        key = shouldTruncate && key.length() > 80 ? rec.Type__c + delimiter + rec.Country_Code__c + delimiter + rec.Language__c : key;
        key = shouldTruncate && key.length() > 80 ? rec.Type__c + delimiter + rec.Country_Code__c + delimiter + rec.Salesforce_Language_Code__c : key;
        key = shouldTruncate && key.length() > 80 ? key.left(80) : key;
        return key;
    }
}