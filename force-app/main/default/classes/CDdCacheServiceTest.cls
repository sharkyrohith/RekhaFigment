/*******************************************************************************************
 * @Name         CacheServiceTest
 * @Author       Sahil
 * @Date         2021-03-02
 * @Group        Bizapps Support
 * @Description  Test class for Cache Service
 *******************************************************************************************/
/* MODIFICATION LOG
 * Version          Developer          Date               Description
 *-------------------------------------------------------------------------------------------
 *  1.0              Sahil              2021-03-02      Initial Creation
 *******************************************************************************************/
@isTest
public class CDdCacheServiceTest {
    public static final String KEY_ORGCACHE = 'testKeyOrgCache';
    public static final String KEY_SESSIONCACHE = 'testKeySessionCache';
    public static final String KEY_ORGCACHE_TTL = 'keyWithTTLOrg';
    public static final String KEY_SESSIONCACHE_TTL = 'keyWithTTLSession';
    public static final List<String> KEY_ORGCACHE_list = new List<String>{'testKeyOrgCache1','testKeyOrgCache2'};
    public static final List<Object> VALUE_ORGCACHE_list2 = new List<Object>{'orgCacheValue1','orgCacheValue2'};
    /**************************************************************************************
     * @Description  Method for testing org cache operations
     * @Return       NA
     **************************************************************************************/
  @isTest
    static void testCacheServiceOperations() {
        Test.startTest();
        //Asserting that initial value in cache is null
        Object initialCachedValue = CDdCacheService.getFromOrgCache(KEY_ORGCACHE);
        System.assertEquals(initialCachedValue, null, 'Org Cache should be Empty');
        
        Object initialCachedValueOrgTTL = CDdCacheService.getFromOrgCache(KEY_ORGCACHE_TTL);
        System.assertEquals(initialCachedValueOrgTTL, null, 'Org Cache should be Empty');

        Object initialCachedValueSessTTL = CDdCacheService.getFromSessionCache(KEY_SESSIONCACHE_TTL);
        System.assertEquals(initialCachedValueSessTTL, null, 'Session Cache should be Empty');

        Object initialCachedValueSession = CDdCacheService.getFromSessionCache(KEY_SESSIONCACHE);
        System.assertEquals(initialCachedValueSession, null, 'Session Cache should be Empty');

        //Putting value to cache
        //Org cache without TTL
        CDdCacheService.putInOrgCache(KEY_ORGCACHE, 'myCacheEntry');
        String cachedValue = (String) CDdCacheService.getFromOrgCache(KEY_ORGCACHE);

        //Org cache with TTL
        CDdCacheService.putInOrgCache(KEY_ORGCACHE_TTL, 'cacheEntrywithTTL', 300);
        String orgWithTTL = (String) CDdCacheService.getFromOrgCache(KEY_ORGCACHE_TTL);

        //Session Cache with TTL
        CDdCacheService.putInSessionCache(KEY_SESSIONCACHE_TTL, 'cacheValueSessionTTL', 500);
        String sessWithTTL = (String) CDdCacheService.getFromSessionCache(KEY_SESSIONCACHE_TTL);

        //Session Cache without TTL
        CDdCacheService.putInSessionCache(KEY_SESSIONCACHE, 'cacheValueSession');
        String sessWithoutTTL = (String) CDdCacheService.getFromSessionCache(KEY_SESSIONCACHE);
        
        //putInOrgCache(String cacheKey, List<Object> cacheValue, Integer ttlSecs)
        
        CDdCacheService.putInOrgCache(KEY_ORGCACHE_TTL,VALUE_ORGCACHE_list2 ,300);
        Map<String,object> mapInitialCachedValueOrgTTL=(Map<String,object>)CDdCacheService.getFromOrgCache(KEY_ORGCACHE_list);
        
        
        //force exception
        Boolean exceptionRaised = false;
        try {
            CDdCacheService.putInSessionCache(KEY_SESSIONCACHE, 'cacheValueSession', 10);
        } catch (Exception e) {
            exceptionRaised = true;
        }

        Test.stopTest();
        //Asserting that value is retrieved from cache correctly
        System.assertEquals(cachedValue, 'myCacheEntry','Expecting value to be myCacheEntry');
        System.assertEquals(orgWithTTL, 'cacheEntrywithTTL','Expecting value to be cacheEntrywithTTL');
        System.assertEquals(sessWithTTL, 'cacheValueSessionTTL','Expecting value to be cacheValueSessionTTL');
        System.assertEquals(sessWithoutTTL, 'cacheValueSession','Expecting value to be cacheValueSession');
        System.assertEquals(exceptionRaised, true,'Expecting exception to be raised');
    }
}