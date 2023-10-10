/**
 * @description       : Chatter Post Notes Template Trigger Handler
 * @author            : Jose Vega
 * @last modified on  : 05-14-2022
 * @last modified by  : Jose Vega
**/
public with sharing class CDdCPNTTriggerHandler {

    public void afterInsert(List<Chatter_Post_Notes_Template__c> newList){
        modifyChatterPostNotesTemplatesToCache(newList);
    }

    public void afterUpdate(List<Chatter_Post_Notes_Template__c> newList, Map<Id, Chatter_Post_Notes_Template__c> oldMap){
        modifyChatterPostNotesTemplatesToCache(newList);
    }

    public void afterDelete(Map<Id, Chatter_Post_Notes_Template__c> oldMap) {
        modifyChatterPostNotesTemplatesToCache(oldMap.values());
    }

    private void modifyChatterPostNotesTemplatesToCache(List<Chatter_Post_Notes_Template__c> cpntList){
        for (Chatter_Post_Notes_Template__c cpnt : cpntList){
            if (Trigger.isDelete) {
                ChatterPostNotesTemplateCache.deleteChatterPostNotesTemplateKey(cpnt.Id);
            } else {
                // If modifications have been made to an active Chatter Post Notes Tempate record
                // we need to clear out the cache containing all records.
                if(cpnt.Active__c) {
                    ChatterPostNotesTemplateCache.deleteCPNT();
                    ChatterPostNotesTemplateCache.setChatterPostNotesTemplateBody(cpnt.Id, cpnt.Body__c);
                } else {
                    ChatterPostNotesTemplateCache.deleteChatterPostNotesTemplateKey(cpnt.Id);
                }
            }
        }
    }
}