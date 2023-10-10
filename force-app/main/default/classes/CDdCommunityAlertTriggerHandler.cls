/**
* @author Tia Xuan	
* @date 2022-03
*
* @description Community Alert Trigger Handler
*/

public class CDdCommunityAlertTriggerHandler {

    public static final String COMMUNITY_ALERT_CACHE_PREFIX = 'local.CommunityAlert.';
    public static final Integer MAX_TTL = 172800;
    
    public void afterInsert(List<CommunityAlert__c> newList){
        addAlertToCache(newList);
    }

    public void afterUpdate(List<CommunityAlert__c> newList, Map<Id, CommunityAlert__c> oldMap){
        addAlertToCache(newList);
    }

    public void addAlertToCache(List<CommunityAlert__c> newList){

        for (CommunityAlert__c ca : newList){
            String cacheKey = COMMUNITY_ALERT_CACHE_PREFIX + ca.Id;
            if (ca.Active__c){
                CDdCacheService.putInOrgCache(cacheKey, JSON.serialize(ca), MAX_TTL);
            } else {
                CDdCacheService.deleteFromOrgCache(cacheKey);
            }
        }
    }
}