/**
 * @author: Raju Lakshman
 * @date: June 2021
 * @description Update the parent Max Version JSON, which will allow the code to know which is the current max minor version for any major version / next available major version.
 */
public without sharing class CTrLegalCmsVersionUpdateMaxVersion extends CDdTriggerHandler {
    private List<Legal_CMS_Content_Version__c> triggerList;
    private Map<Id, Legal_CMS_Content_Version__c> triggerMapOld;

    /**
     * @description Constructor that sets class variables based on Trigger context vars
     */
    public CTrLegalCmsVersionUpdateMaxVersion() {
        Boolean isDelete = getTriggerContext() == CDdTriggerHandler.TriggerContext.BEFORE_DELETE ||
                           getTriggerContext() == CDdTriggerHandler.TriggerContext.AFTER_DELETE;
        this.triggerList = isDelete ? (List<Legal_CMS_Content_Version__c>)trigger.old : (List<Legal_CMS_Content_Version__c>)trigger.new;
        this.triggerMapOld = (Map<Id, Legal_CMS_Content_Version__c>) Trigger.oldMap;
    }

    /**
     * @description Overriden event handlers.
     */

    public override void afterInsert() {
        updateParentMaxVersion();
    }

    /**
     * @description Setting the Max_Version_JSON__c field on the parent records - so that LwcDdLegalCmsVersionNewOverride can use that to know which should be the new version
     */
    private void updateParentMaxVersion() {
        Map<String,Map<String,String>> currentTriggerMaxVersion = new Map<String,Map<String,String>>();
        Set<String> parentCmsIds = new Set<String>();
        for (Legal_CMS_Content_Version__c rec : triggerList) {
            String majorVersion = String.valueOf((Integer)rec.Major_Version__c);
            String minorVersion = String.valueOf((Integer)rec.Minor_Version__c);

            if (!currentTriggerMaxVersion.containsKey(rec.Parent__c)) {
                currentTriggerMaxVersion.put(rec.Parent__c,new Map<String,String>());
            }

            Map<String,String> temp = currentTriggerMaxVersion.get(rec.Parent__c);
            if (!temp.containsKey(majorVersion) || rec.Minor_Version__c > Integer.valueOf(temp.get(majorVersion))) {
                temp.put(majorVersion,minorVersion);
            }
            parentCmsIds.add(rec.Parent__c);
        }

        List<Legal_CMS_Content__c> parentRecords = [SELECT Id,Max_Version_JSON__c FROM Legal_CMS_Content__c WHERE Id in :parentCmsIds];

        for (Legal_CMS_Content__c parentRec : parentRecords) {
            Map<String,Object> parentMaxVersion = String.isBlank(parentRec.Max_Version_JSON__c) ?
                new Map<String,Object>() :
                (Map<String,Object>)JSON.deserializeUntyped(parentRec.Max_Version_JSON__c);

            Map<String,String> versionFromTrigger = currentTriggerMaxVersion.get(parentRec.Id);
            for (String majorVersion : versionFromTrigger.keySet()) {
                String minorVersion = versionFromTrigger.get(majorVersion);
                if (!parentMaxVersion.containsKey(majorVersion) || Integer.valueOf(parentMaxVersion.get(majorVersion)) < Integer.valueOf(minorVersion)) {
                    parentMaxVersion.put(majorVersion,minorVersion);
                }
            }
            parentRec.Max_Version_JSON__c = JSON.serialize(parentMaxVersion);
        }

        update parentRecords;
    }
}