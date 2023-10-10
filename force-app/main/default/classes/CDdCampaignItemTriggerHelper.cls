/********************************************************************************************************************
* @author Ganesh
* @date 01/09/2023
*
* @group Trigger Helper
*
* @description Trigger helper for Campaign Item object
**************************************************************************************************************************************/
public class CDdCampaignItemTriggerHelper {
        
    public static final Map<string,string> CI_LAUNCH_AD_OPS_QUEUES = new Map<String,string>{
                                                                            'Standard (Mx Services)' => 'Campaign_Items_Launch_Ops',
                                                                            'Custom (Ad Ops)' => 'Campaign_Items_Ad_Ops'
                                                                            };
    public static final Set<string> SPONSORED_PRODUCTS = CDdCampaignBriefController.Campaign_Items_Products_QueueMap.keySet();
        
    public static void updateOwnerOnCBChange(Map<Id, Campaign_Item__c> newMap, Map<Id, Campaign_Item__c> oldMap) {
        
        Set<Id> campaignBriefIds = new Set<Id>();
        for(Campaign_Item__c item:newMap.Values()){
            if(item.Campaign_Brief__c != null 
                && !SPONSORED_PRODUCTS.contains(item.Product__c)
                && item.Campaign_Brief__c != oldMap.get(item.Id).Campaign_Brief__c){
            
                campaignBriefIds.add(item.Campaign_Brief__c);        
            }
        }
        
        if(campaignBriefIds.isEmpty()){
            return ;
        }
        
        Map<Id, Campaign_Brief__c> campaignBriefMap = new Map<Id, Campaign_Brief__c>([SELECT Id, Configuration__c 
                                                                                            FROM Campaign_Brief__c
                                                                                            WHERE Id IN:campaignBriefIds]);
        if(campaignBriefMap.isEmpty()){
            return ;
        } 
        
        Map<string,Id> queueIdMap = new Map<string,Id>();
        for(Group gr:[SELECT id, Name,DeveloperName FROM Group 
                        WHERE Type='Queue' AND DeveloperName IN: CI_LAUNCH_AD_OPS_QUEUES.Values()]){
            
            queueIdMap.put(gr.DeveloperName, gr.Id);                
        }
                                                                                           
        for(Campaign_Item__c item:newMap.Values()){
            if(campaignBriefMap.containsKey(item.Campaign_Brief__c)
                && CI_LAUNCH_AD_OPS_QUEUES.containsKey(campaignBriefMap.get(item.Campaign_Brief__c).Configuration__c)
                && queueIdMap.containsKey(CI_LAUNCH_AD_OPS_QUEUES.get(campaignBriefMap.get(item.Campaign_Brief__c).Configuration__c))){
                
                item.OwnerId = queueIdMap.get(CI_LAUNCH_AD_OPS_QUEUES.get(campaignBriefMap.get(item.Campaign_Brief__c).Configuration__c));    
            }
        }
    }
    
}