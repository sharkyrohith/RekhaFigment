/*******************************************************************************************
* @Name         CDdSiteEscalationConfigService
* @Author       Sahil
* @Date         2021-03-16
* @Group        Bizapps Support
* @Description  Service methods for Site Escalation Config Object
*******************************************************************************************/
/* MODIFICATION LOG
* Version          Developer          Date               Description
*-------------------------------------------------------------------------------------------
*  1.0.0             Sahil              2021-03-16         Initial Creation
*******************************************************************************************/
public with sharing class CDdSiteEscalationConfigService {
    
    
    @TestVisible private static final String SITE_CONFIGS = 'local.DoorDash.siteEscConfigs';
    private static final String SITE_CONFIG_OBJECT = 'SiteEscalationConfig';
    
    /**************************************************************************************
* @Description  get cached site escalation queues
* @Param
* @Return    List of escalation queues
* @Example
**************************************************************************************/
    public static List<Site_Escalation_Config__c> getCachedSiteEscConfigsByUserRoleId(Id userRoleId, Map<string,String> cacheKeyMap) { 
        
        // New Code
        List<Site_Escalation_Config__c> siteConfigList = new List<Site_Escalation_Config__c>(); //List<Site_Escalation_Config__c> siteEscConfigsFromDb = new List<Site_Escalation_Config__c>();
        List<String> cacheKeyList = new List<String>();
        // checking the cache if it has Site_Escalation_Config__c records
        Boolean isSiteEscConfCacheExists = (Boolean)CDdCacheService.getFromOrgCache(SITE_CONFIGS+SITE_CONFIG_OBJECT);   
        if(isSiteEscConfCacheExists != null){
            System.debug('cacheKeyMap>>'+cacheKeyMap);
            if(!( cacheKeyMap == null || cacheKeyMap.isEmpty())){
                cacheKeyList.addAll(cacheKeyMap.keySet());
            }
            if(!cacheKeyList.isEmpty()){
                Map<String,object> mapSiteConFig = CDdCacheService.getFromOrgCache(cacheKeyList);
                if(mapSiteConFig != null && !mapSiteConFig.isEmpty()){
                    for(String key : mapSiteConFig.keySet()){
                        // Boolean isList=mapSiteConFig.get(key) instanceof List<object>;
                        if(mapSiteConFig.get(key) != null && key!=SITE_CONFIGS+userRoleId){
                            siteConfigList.add((Site_Escalation_Config__c)mapSiteConFig.get(key));	
                        }else if(mapSiteConFig.get(key) != null && key ==SITE_CONFIGS+userRoleId){
                            Boolean isList=mapSiteConFig.get(SITE_CONFIGS+userRoleId) instanceof List<object>;
                            if(!isList){
                                siteConfigList.add((Site_Escalation_Config__c)mapSiteConFig.get(key));
                            }else{
                                siteConfigList.addAll((List<Site_Escalation_Config__c>)mapSiteConFig.get(key));  
                            }
                        }
                    } 
                }
            } 
            // Build the cache for Site Escalation Config object.
        }
        else{
            Map<String,String> mapUserRoleNameId = new Map<String,String>();
            for(UserRole objRole : [SELECT Id,Name FROM UserRole]){
                mapUserRoleNameId.put(objRole.Name,objRole.Id);    
            }
            Map<String,object> mapSiteRoleConFig = new Map<String,object>();
            for(Site_Escalation_Config__c objSiteConf : [SELECT Id,Queue_ID__c,Queue_Label__c,From_Queue_Id__c,Site_Role_Name__c,
                                                         IsEscalation__c,IsTransfer__c,Is_Default_Escalation__c 
                                                         FROM Site_Escalation_Config__c]){
                //Queue based check
                if(String.isEmpty(objSiteConf.Site_Role_Name__c) && String.isNotEmpty(objSiteConf.From_Queue_Id__c)){
                    CDdCacheService.putInOrgCache(
                        SITE_CONFIGS+objSiteConf.Queue_ID__c+objSiteConf.From_Queue_Id__c ,objSiteConf,Integer.valueof(System.Label.Site_Escalation_config_Cache_time_to_live) 
                    );
                    if(cacheKeyMap.containskey(SITE_CONFIGS+objSiteConf.Queue_ID__c+objSiteConf.From_Queue_Id__c)){
                        siteConfigList.add(objSiteConf)  ;
                    }
                }
                //Niether Role nor Queue based check, prevent assigning cases to Queue_ID__c queue
                else if(String.isEmpty(objSiteConf.Site_Role_Name__c) && String.isEmpty(objSiteConf.From_Queue_Id__c)){
                    CDdCacheService.putInOrgCache(
                        SITE_CONFIGS+objSiteConf.Queue_ID__c,objSiteConf,Integer.valueof(System.Label.Site_Escalation_config_Cache_time_to_live) 
                    );
                    if(cacheKeyMap.containskey(SITE_CONFIGS+objSiteConf.Queue_ID__c)){
                        siteConfigList.add(objSiteConf);
                    }
                }
                //Role based check
                else{
                    if(!mapUserRoleNameId.isEmpty() && 
                       mapUserRoleNameId.containskey(objSiteConf.Site_Role_Name__c)
                      ){
                          List<Site_Escalation_Config__c> siteRoleEscConfigs = new  List<Site_Escalation_Config__c>();
                          if(mapSiteRoleConFig.containsKey(SITE_CONFIGS+String.valueOf(mapUserRoleNameId.get(objSiteConf.Site_Role_Name__c)))){
                              Boolean isList=mapSiteRoleConFig.get(SITE_CONFIGS+String.valueOf(mapUserRoleNameId.get(objSiteConf.Site_Role_Name__c))) instanceof List<object>;
                              if(!isList){
                                  siteConfigList.add((Site_Escalation_Config__c)mapSiteRoleConFig.get(SITE_CONFIGS+String.valueOf(mapUserRoleNameId.get(objSiteConf.Site_Role_Name__c))));
                              }else{
                                  siteConfigList.addAll((List<Site_Escalation_Config__c>)mapSiteRoleConFig.get(SITE_CONFIGS+String.valueOf(mapUserRoleNameId.get(objSiteConf.Site_Role_Name__c))));  
                              }  
                          }
                          siteRoleEscConfigs.add(objSiteConf);
                          mapSiteRoleConFig.put(SITE_CONFIGS+String.valueOf(mapUserRoleNameId.get(objSiteConf.Site_Role_Name__c)),siteRoleEscConfigs);
                      }
                }
            }
            for (String roleKey : mapSiteRoleConFig.keySet()){
                CDdCacheService.putInOrgCache(roleKey, mapSiteRoleConFig.get(roleKey),Integer.valueof(System.Label.Site_Escalation_config_Cache_time_to_live));   
                if(cacheKeyMap.containsKey(roleKey)){
                    Boolean isList=mapSiteRoleConFig.get(roleKey) instanceof List<object>;
                    if(!isList){
                        siteConfigList.add((Site_Escalation_Config__c)mapSiteRoleConFig.get(roleKey));
                    }else{
                        siteConfigList.addAll((List<Site_Escalation_Config__c>)mapSiteRoleConFig.get(roleKey));  
                    } 
                } 
            }
            CDdCacheService.putInOrgCache(SITE_CONFIGS+'SiteEscalationConfig', true);
        }
        return siteConfigList;
    }      
}