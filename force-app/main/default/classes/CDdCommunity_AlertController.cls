public without sharing class CDdCommunity_AlertController {

    @AuraEnabled
    public static List<CommunityAlert__c> getCommunityAlert(String lang, String page, Boolean showInternalAlert){
        String communityId = Network.getNetworkId();
        String netName = 'Customer Community';
        if (!Test.isRunningTest() && !showInternalAlert){
        	Network net = [select Id, Name from Network where Id =: communityId];
            netName = net.Name;
        }


        List<CommunityAlert__c> alerts = new List<CommunityAlert__c>();
        
        
        if (CDdExperimentSvc.getSupportFeatureFlag('Use_Community_Alert_Cache__c')){
            Map<String, Object> retVal = new Map<String, Object>();
            Map<String, Object> cacheList =  CDdCacheService.getFromOrgPartition('local.CommunityAlert');

            for(String key : cacheList.keySet()){
                String caJSON = (String) cacheList.get(key);
                CommunityAlert__c ca = (CommunityAlert__c) JSON.deserialize(caJSON, CommunityAlert__c.class);
                if(showInternalAlert && ca.Internal_Alert__c){
                    alerts.add(ca);
                }
                else if(!ca.Internal_Alert__c){
                    if (ca.Community__c.contains(netName) 
                        && ca.Language__c == lang
                        && ca.Internal_Alert__c == false
                        && (ca.Pages__c.contains(page)
                            || ca.All_Pages__c)){
                            alerts.add(ca);
                    }
                }
            }
        } else  {
            if(showInternalAlert){
                alerts = [SELECT Alert_Type__c, Link_Label__c, Link_URL__c, Text_after_URL__c, 
                          Text_before_URL__c, Label_URL_2__c, Link_URL_2__c, End_Text__c, Title__c
                          FROM CommunityAlert__c
                          WHERE Active__c = true
                          AND Internal_Alert__c = true
                          ORDER BY LastModifiedDate DESC];
            }
            else {
                alerts = [	select  Alert_Type__c, Link_Label__c, Link_URL__c, Text_after_URL__c, 
                                Text_before_URL__c, Label_URL_2__c, Link_URL_2__c, End_Text__c, Title__c
                        from CommunityAlert__c
                        where Community__c includes (: netName)
                            and Language__c =: lang
                            and (Pages__c includes (: page)
                                OR All_Pages__c = true)
                            and Active__c = true
                            and Internal_Alert__c = false
                        order by LastModifiedDate DESC];
            }
        }
        
        if (alerts.size() > 0){
        	return alerts;
        }
        
        return null;
        
    }

    @AuraEnabled
    public static Integer getInternalAlertRefreshInternal(){
        return CDdNameValuePairHelper.getIntegerValue(CDdNameValuePairConstants.INTERNAL_ALERT_REFRESH_INTERVAL);
    }
}