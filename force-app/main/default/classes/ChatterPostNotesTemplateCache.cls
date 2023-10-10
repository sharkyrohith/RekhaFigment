/**
 * @description       : Service to handle Chatter Post Notes Template Cache
 * @author            : Jose Vega
 * @last modified on  : 05-18-2022
 * @last modified by  : Jose Vega
**/
public with sharing class ChatterPostNotesTemplateCache {

    public static final String CHATTER_POST_NOTES_TEMPLATE_CACHE_PREFIX = 'local.Chatter.';
    public static final String CHATTER_POST_NOTES_TEMPLATE_ALL_KEY = 'loadCPNT';
    public static final Integer MAX_TTL = 172800;

    /**
    * @description Returns Chatter Post Notes Template Body for a ID
    * @author Jose Vega | 05-14-2022 
    * @param String chatterPostNotesTemplateId 
    * @return String 
    **/
    public static String getChatterPostNotesTemplateBody(String chatterPostNotesTemplateId) {
        String cacheKey = CHATTER_POST_NOTES_TEMPLATE_CACHE_PREFIX + chatterPostNotesTemplateId;
        return (String)CDdCacheService.getFromOrgCache(cacheKey);
    }

    /**
    * @description Sets the Chatter Post Notes Template Body per ID
    * @author Jose Vega | 05-14-2022 
    * @param String chatterPostNotesTemplateId 
    * @param String chatterPostNotesTemplateBody 
    **/
    public static void setChatterPostNotesTemplateBody(String chatterPostNotesTemplateId, String chatterPostNotesTemplateBody) {
        String cacheKey = CHATTER_POST_NOTES_TEMPLATE_CACHE_PREFIX + chatterPostNotesTemplateId;
        CDdCacheService.putInOrgCache(cacheKey, chatterPostNotesTemplateBody, MAX_TTL);
    }

    /**
    * @description Delete Chatter Post Notes Template Body record by Id
    * it is used when a record is deleted or becomes inactive.
    * @author Jose Vega | 05-14-2022 
    * @param String chatterPostNotesTemplateId 
    **/
    public static void deleteChatterPostNotesTemplateKey(String chatterPostNotesTemplateId) {
        String cacheKey = CHATTER_POST_NOTES_TEMPLATE_CACHE_PREFIX + chatterPostNotesTemplateId;
        CDdCacheService.deleteFromOrgCache(cacheKey);
    }

    public static List<Chatter_Post_Notes_Template__c> loadCPNT() {
        String cacheKey = CHATTER_POST_NOTES_TEMPLATE_CACHE_PREFIX + CHATTER_POST_NOTES_TEMPLATE_ALL_KEY;
        
        List<Chatter_Post_Notes_Template__c> results = new List<Chatter_Post_Notes_Template__c>();
        Object cacheResults = CDdCacheService.getFromOrgCache(cacheKey);
        
        // If Cache MISS, let's create it.
        if (cacheResults == null) {
            results = [
                SELECT Id, Name
                FROM Chatter_Post_Notes_Template__c
                WHERE Active__c = true ORDER BY Name
            ];
            CDdCacheService.putInOrgCache(cacheKey, results, MAX_TTL);
        } else {
            results = (List<Chatter_Post_Notes_Template__c>) JSON.deserialize(JSON.serialize(cacheResults), List<Chatter_Post_Notes_Template__c>.class);
        }
        return results;
    }

    /**
    * @description Resets the Chatter Post Notes Template Active
    * @author Jose Vega | 05-14-2022 
    **/
    public static void deleteCPNT() {
        String cacheKey = CHATTER_POST_NOTES_TEMPLATE_CACHE_PREFIX + CHATTER_POST_NOTES_TEMPLATE_ALL_KEY;
        CDdCacheService.deleteFromOrgCache(cacheKey);
    }
}