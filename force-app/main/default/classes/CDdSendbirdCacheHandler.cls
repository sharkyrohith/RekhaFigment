/**
 * CDdSendbirdCacheHandler
 *
 * @author     Sahil
 * @date  2020-03-30
 * @decription caching data frequently used in sendbird transactions
 */
public with sharing class CDdSendbirdCacheHandler {
  /*****************************************************************************************************************************
   *
   * Public Methods
   *
   *****************************************************************************************************************************/
  /**
   * @author     Sahil
   * @date  2020-03-30
   * @decription Gets quick text records from platform cache
   * @param   cache key
   * @return  quick text records
   */
  public static List<QuickText> getCachedQuickText(String cacheKey, String liveagentChannel) {
    String key = cacheKey+liveagentChannel.trim();
    key = key.replace(' ', '');
    List<QuickText> quickTextListFromCache = (List<QuickText>) CDdCacheService.getFromOrgCache(key);
    if (quickTextListFromCache == null) {
      //get quick texts from database
      List<QuickText> quickTextListFromDB = [
        SELECT Id, Name, Message, Category, Channel
        FROM QuickText
        WHERE Channel = :CDdSupportConstants.LIVEAGENT_CHANNEL
      ];
      System.debug('building quicktext cache now');
      CDdCacheService.putInOrgCache(cacheKey, quickTextListFromDB);
      return quickTextListFromDB;
    } else {
      System.debug('returning quicktext from cache');
      return quickTextListFromCache;
    }
  }
}