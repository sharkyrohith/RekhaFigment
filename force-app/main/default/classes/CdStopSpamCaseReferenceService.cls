/*******************************************************************************************
* @Name         StopSpamCaseReferenceService
* @Author       Schubert
* @Date         2023-06-12
* @Group        Bizapps Support
* @Description  Service methods for Stop Spam Case Reference Object
*******************************************************************************************/
public with sharing class CdStopSpamCaseReferenceService {

    @TestVisible private static final String STOPSPAM_CONFIGS = 'local.DoorDash.stopSpamCaseRef';
    private static final String STOPSPAM_CONFIG_OBJECT = 'StopSpamCaseReference';
    public static final Integer MAX_TTL = 172800; // 48 hours Max

    /**************************************************************************************
    * @Description  get cached Stop_Spam_Case_Reference__c
    * @Param
    * @Return    List of Stop_Spam_Case_Reference__c
    * @Example
    **************************************************************************************/
    public static List<Stop_Spam_Case_Reference__c> getCachedStopSpamCaseReference() {

        List<Stop_Spam_Case_Reference__c> returnSSCRList = new List<Stop_Spam_Case_Reference__c>();

        Object cacheResult = CDdCacheService.getFromOrgCache(STOPSPAM_CONFIGS+STOPSPAM_CONFIG_OBJECT);

        if( cacheResult == NULL ){ // Build the cache
			// Save value in cache url encoded
            for( Stop_Spam_Case_Reference__c r: [SELECT Id, Field__c, Operator__c, Value__c FROM Stop_Spam_Case_Reference__c] ){
                r.Value__c = EncodingUtil.URLENCODE( r.Value__c.trim(), 'UTF-8' );
                returnSSCRList.add(r);
            }

            CDdCacheService.putInOrgCache( STOPSPAM_CONFIGS+STOPSPAM_CONFIG_OBJECT, returnSSCRList, MAX_TTL );

        }else{

            returnSSCRList = (List<Stop_Spam_Case_Reference__c>)cacheResult;

            for( Stop_Spam_Case_Reference__c r: returnSSCRList ){
                r.Value__c = EncodingUtil.URLDECODE( r.Value__c, 'UTF-8' );
            }
        }

        return returnSSCRList;
    }
    /**************************************************************************************
    * @Description  refresh Stop_Spam_Case_Reference__c cache
    * @Param
    * @Return
    * @Example
    **************************************************************************************/
    public static void refreshStopSpamCaseReferenceCache() {
        CDdCacheService.deleteFromOrgCache(STOPSPAM_CONFIGS+STOPSPAM_CONFIG_OBJECT);
        CdStopSpamCaseReferenceService.getCachedStopSpamCaseReference();
    }

}