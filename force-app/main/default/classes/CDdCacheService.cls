/*******************************************************************************************
 * @Name         CacheService
 * @Author       Sahil
 * @Date         2021-03-02
 * @Group        Bizapps Support
 * @Description  This class contains all service methods related to caching data in Salesforce.
 *				It is segregated as a service to make changing cache partition easy.
 *******************************************************************************************/
/* MODIFICATION LOG
 * Version          Developer          Date               Description
 *-------------------------------------------------------------------------------------------
 *  1.0              Sahil              2021-03-02          Initial Creation
 *******************************************************************************************/
public class CDdCacheService {
    /**************************************************************************************
     * @Description  This method gets checks for entries in org cache
     * @Param		 String - Key string
     * @Return       Object - Value retrieved from org cache.
     * @description  this method will return null if there is no match in the Platform cache
     * @Example
     * CacheService.getFromOrgCache('ApiToken')
    **************************************************************************************/
    public static Object getFromOrgCache(String cacheKey) {
        return Cache.Org.get(cacheKey);
    }

    /**************************************************************************************
     * @Description  This method gets checks for entries in org cache
     * @Param		 String - Key string
     * @Param		 Object - Value that needs to be stored to org cache
     * @Return       NA
     * @Example
     * CacheService.putInOrgCache('ApiToken','asodfua8sudf8ashdf8sdf')
    **************************************************************************************/
    public static void putInOrgCache(String cacheKey, Object cacheValue) {
        Cache.Org.put(cacheKey, cacheValue);
    }
   /**
     * @author     Ravali
     * @date  2021-08-18
     * @decription puts value in Org cache
     * @param   cache key, list of cache value, time to live in seconds
     * @return  N/A
    */
	public static void putInOrgCache(String cacheKey, List<Object> cacheValue, Integer ttlSecs) {
        Cache.Org.put(cacheKey, cacheValue);
    }  
    /**
     * @author     Sahil
     * @date  2021-05-20
     * @decription puts value in Org cache
     * @param   cache key, cache value, time to live in seconds
     * @return  N/A
    */
    public static void putInOrgCache(String cacheKey, Object cacheValue, Integer ttlSecs) {
        Cache.Org.put(cacheKey, cacheValue, ttlSecs);
    }

    /**
     * @author     Tia
     * @date  2022-03
     * @decription delete key from Org Cache
     * @param   cache key
     * @return  N/A
    */
    public static void deleteFromOrgCache(String cacheKey) {
        if (Cache.org.contains(cacheKey)){
            Cache.Org.remove(cacheKey);
        }
    }

    /**
     * @author     Sahil
     * @date  2021-05-18
     * @decription gets value from session cache - this method will return null if 
     *             there is no match in the Platform cache
     * @param   cache key
     * @return  Object
    */
    public static Object getFromSessionCache(String cacheKey) {
        return Cache.Session.get(cacheKey);
    }
 
    /**
     * @author     Ravali
     * @date  2021-08-11
     * @decription gets value from session cache - this method will return List of cache key values
     * @param   List of cache key
     * @return  List of Object
    */
    public static Map<String,object> getFromOrgCache(List<String> cacheKeys) {
        Map<String,object> orgCacheDataMap = new Map<String,object>();
        for(string key : cacheKeys) {
            orgCacheDataMap.put(key,Cache.Org.get(key));
        }
        return orgCacheDataMap;
    }
    
    /**
     * @author     Sahil
     * @date  2021-05-20
     * @decription puts value in session cache
     * @param   cache key, cache value, time to live in seconds
     * @return  N/A
    */
    public static void putInSessionCache(String cacheKey, Object cacheValue, Integer ttlSecs) {
        Cache.Session.put(cacheKey, cacheValue, ttlSecs);
    }

    /**
     * @author     Sahil
     * @date  2021-05-23
     * @decription puts value in session cache
     * @param   cache key, cache value
     * @return  N/A
    */
    public static void putInSessionCache(String cacheKey, Object cacheValue) {
        Cache.Session.put(cacheKey, cacheValue);
    }

    /**
     * @author     Tia
     * @date  2022-03
     * @decription get everything from a partition
     * @param   partition name
     * @return  N/A
    */
    public static Map<String, Object> getFromOrgPartition(String partName){
        Map<String, Object> retVal = new Map<String, Object>();

        cache.OrgPartition part = Cache.org.getPartition(partName);
        for (String key : part.getKeys()){
            retVal.put(key, part.get(key));
        }

        return retVal;
    }

    /**
    * @description Custom Exception 
    **/     
    public class CDdCacheServiceException extends Exception {}      
}