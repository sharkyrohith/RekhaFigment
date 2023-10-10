/**
* @author Tia Xuan	
* @date 2022-03
*
* @description Test class for CDdCommunityAlertTriggerHandler
*/
@isTest
public class CDdCommunityAlertTriggerTest {

    /**
	* @description test treatFormstackPhotoAttachment
	*/
	@isTest static void testCommunityAlert() {
        Test.startTest();
        List<CommunityAlert__c> caList = new List<CommunityAlert__c>();
        caList.add(new CommunityAlert__c(Community__c = 'Customer Community', All_Pages__c = true, Language__c = 'en_US'));
        caList.add(new CommunityAlert__c(Language__c = 'en_US', Internal_Alert__c = true, Alert_Type__c = 'Outage'));
        insert caList;

        for(CommunityAlert__c ca : caList){
            ca.Active__c = true;
        }
        update caList;
        Test.stopTest();

        String cacheKey = CDdCommunityAlertTriggerHandler.COMMUNITY_ALERT_CACHE_PREFIX + caList[0].Id;
        String alrt = (String) CDdCacheService.getFromOrgCache(cacheKey);
        System.assert(String.isNotBlank(alrt), 'A cache entry must be there');
    }
}