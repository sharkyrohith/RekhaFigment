/**
 * @author: Raju Lakshman
 * @date: June 2021
 * @description Handle update to the default language flag... if a record has it checked, then uncheck from other record for the same parent, etc...
 */
public without sharing class CTrLegalCmsUpdateDefaultLanguageFlag extends CDdTriggerHandler {
    private List<Legal_CMS_Content__c> triggerList;
    private Map<Id, Legal_CMS_Content__c> triggerMapOld;

    /**
     * @description Constructor that sets class variables based on Trigger context vars
     */
    public CTrLegalCmsUpdateDefaultLanguageFlag() {
        Boolean isDelete = getTriggerContext() == CDdTriggerHandler.TriggerContext.BEFORE_DELETE ||
                           getTriggerContext() == CDdTriggerHandler.TriggerContext.AFTER_DELETE;
        this.triggerList = isDelete ? (List<Legal_CMS_Content__c>)trigger.old : (List<Legal_CMS_Content__c>)trigger.new;
        this.triggerMapOld = (Map<Id, Legal_CMS_Content__c>) Trigger.oldMap;
    }

    /**
     * @description Overriden event handlers.
     */

    public override void beforeInsert() {
        processDefaultLanguageFlag();
    }

    public override void beforeUpdate() {
        processDefaultLanguageFlag();
    }

    /**
     * @description Overriden event handlers.
     */
    private void processDefaultLanguageFlag() {
        Set<String> typeToCheck = new Set<String>();
        Set<String> countryToCheck = new Set<String>();
        List<Legal_CMS_Content__c> toProcess = new List<Legal_CMS_Content__c>();
        for (Legal_CMS_Content__c rec : triggerList) {
            if (isNewOrFieldUpdated(rec, 'Type__c') || isNewOrFieldUpdated(rec, 'Country__c') ||
                (isNewOrFieldUpdated(rec, 'Default_Language_for_Country__c') && rec.Default_Language_for_Country__c)) {
                typeToCheck.add(rec.Type__c);
                countryToCheck.add(rec.Country__c);
                toProcess.add(rec);
            }
        }

        if (toProcess.isEmpty()) {
            return;
        }

        Map<String,Map<String,Legal_CMS_Content__c>> existingRecordMap = new Map<String,Map<String,Legal_CMS_Content__c>>();
        for (Legal_CMS_Content__c rec : [SELECT Id,Type__c,Country__c FROM Legal_CMS_Content__c
                                          WHERE Type__c in :typeToCheck AND Country__c in :countryToCheck
                                            AND Default_Language_for_Country__c = true
                                            AND Id NOT IN :triggerList]) {
            if (!existingRecordMap.containsKey(rec.Type__c)) {
                existingRecordMap.put(rec.Type__c,new Map<String,Legal_CMS_Content__c>());
            }
            existingRecordMap.get(rec.Type__c).put(rec.Country__c,rec);
        }

        List<Legal_CMS_Content__c> toUpdate = new List<Legal_CMS_Content__c>();
        for (Legal_CMS_Content__c rec : toProcess) {
            Legal_CMS_Content__c existingRecord = existingRecordMap.containsKey(rec.Type__c) && existingRecordMap.get(rec.Type__c).containsKey(rec.Country__c) ?
                existingRecordMap.get(rec.Type__c).get(rec.Country__c) : null;

            if (existingRecord == null) {
                rec.Default_Language_for_Country__c = true;
            } else {
                if (rec.Default_Language_for_Country__c) {
                    existingRecord.Default_Language_for_Country__c = false;
                    toUpdate.add(existingRecord);
                }
            }
        }
        update toUpdate;
    }
}