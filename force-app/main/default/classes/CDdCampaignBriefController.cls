public class CDdCampaignBriefController{

    public static final string CAMPAIGN_BRIEF_OBJECT = 'Campaign Brief';
    public static final string CAMPAIGN_ITEM_OBJECT = 'Campaign Item';
    public static final string PRODUCT_OBJECT = 'Product';
    public static final string BANNER_PRODUCT = 'Banner';
    public static final string defaultQueue = 'Campaign_Items_General_Unassigned';
    public static final Set<string> promoFeeProducts = new Set<String>{'Sponsored Listing','Sponsored Products'};
    public static final Set<string> Campaign_Items_Queues = new Set<String>{'Campaign_Items_General_Unassigned',
                                                                            'Campaign_Items_Sampling_Branded',
                                                                            'Campaign_Items_Sponsored_Listings',
                                                                            'Campaign_Items_Sponsored_Products'};

    public static final Map<string,string> Campaign_Items_Products_QueueMap = new Map<String,string>{
                                                                            'Sponsored Listing' => 'Campaign_Items_Sponsored_Listings',
                                                                            'Sponsored Products' => 'Campaign_Items_Sponsored_Products',
                                                                            'Sampling' => 'Campaign_Items_Sampling_Branded',
                                                                            'Branded Collection' => 'Campaign_Items_Sampling_Branded'
                                                                            };

    @AuraEnabled
    public static string createCampaignBrief(String recId){
        try{

            Set<String> oppFieldSet = new Set<String>{'Addendum_Link__c','Marketplace_Contract_Link__c', 'Id', 'OwnerId'};
            Set<String> oppLineItemFieldsSet = new Set<String>{'Id','DayTime_of_Week__c','Maximum_Promo_Fee__c'};
            Map<string, string> campaignBriefMapping = new Map<string,string>();
            Map<string, string> campaignItemMapping = new Map<string,string>();
            Set<String> productNames = new Set<String>();

            for(Campaign_Brief_Item_Mapping_Fields__mdt mappingField:[SELECT Object__c, Value__c, Source_Field__c, Target_Field__c
                                                                       FROM Campaign_Brief_Item_Mapping_Fields__mdt]){


                if(mappingField.Object__c == CAMPAIGN_ITEM_OBJECT){
                    campaignItemMapping.put(mappingField.Target_Field__c, mappingField.Source_Field__c);
                    oppLineItemFieldsSet.add(mappingField.Source_Field__c);
                }

                if(mappingField.Object__c == PRODUCT_OBJECT){
                    productNames.add(mappingField.Value__c);
                }
            }

            List<String> oppFieldList = new List<String>();
            oppFieldList.addAll(oppFieldSet);

            List<String> oppLineItemFieldsList = new List<String>();
            oppLineItemFieldsList.addAll(oppLineItemFieldsSet);

            String oppFields = String.join(oppFieldList,', ');
            String oppLineItemFields = String.join(oppLineItemFieldsList, ', ');

            String tempQuery = 'SELECT {0}, (SELECT {1} FROM OpportunityLineItems '
                            +' WHERE Product2.Name IN:productNames)'
                            +' FROM Opportunity WHERE Id=:recId LIMIT 1';

            List<Object> parameters = new List<Object> {oppFields, oppLineItemFields};
            String query = String.format(tempQuery, parameters);

            Opportunity currOpp = Database.Query(query);

            if(currOpp.OpportunityLineItems.isEmpty() || currOpp.OpportunityLineItems.size() == 0){
                return Label.Campaign_Brief_Error_Message;
            }

            List<Campaign_Item__c> existingCampaignItems = [SELECT Id, External_Id__c FROM Campaign_Item__c
                                                            WHERE Salesforce_Opportunity__c =:recId];

            Map<Id,Id> existingCampaignItemsMap = new Map<Id,Id>();
            for(Campaign_Item__c ci:existingCampaignItems){
                existingCampaignItemsMap.put(ci.External_Id__c, ci.Id);
            }
            Map<string,Id> queueIdMap = new Map<string,Id>();
            for(Group gr:[SELECT id, Name,DeveloperName FROM Group
                            WHERE Type='Queue' AND DeveloperName IN:Campaign_Items_Queues]){

                queueIdMap.put(gr.DeveloperName, gr.Id);
            }

            List<Campaign_Item__c> campaignInsertList = new List<Campaign_Item__c>();
            for(OpportunityLineItem oli:currOpp.OpportunityLineItems){
                Campaign_Item__c campItem = new Campaign_Item__c();

                for(string targetOliField:campaignItemMapping.keySet()){
                    string sourceOliField = campaignItemMapping.get(targetOliField);
                    campItem.put(targetOliField, oli.get(sourceOliField));
                }

                if(campItem.Product__c != BANNER_PRODUCT){
                    campItem.Dayparting__c = oli.DayTime_of_Week__c;
                }

                if(!promoFeeProducts.contains(campItem.Product__c)){
                    campItem.Budget__c = oli.Maximum_Promo_Fee__c;
                }

                campItem.Sales_DRI__c = currOpp.OwnerId;
                campItem.Salesforce_Opportunity__c = currOpp.Id;


                if(existingCampaignItemsMap.containsKey(campItem.External_Id__c)){
                    campItem.Id = existingCampaignItemsMap.get(campItem.External_Id__c);
                }else{
                    if(Campaign_Items_Products_QueueMap.containsKey(campItem.Product__c)
                        && queueIdMap.containsKey(Campaign_Items_Products_QueueMap.get(campItem.Product__c))){

                        campItem.OwnerId = queueIdMap.get(Campaign_Items_Products_QueueMap.get(campItem.Product__c));

                    }else if(queueIdMap.containsKey(defaultQueue)){

                        campItem.OwnerId = queueIdMap.get(defaultQueue);
                    }
                }
                campaignInsertList.add(campItem);
            }

            upsert campaignInsertList;

            return Label.Campaign_Brief_Success_Message;

        }catch(Exception e){
            return e.getMessage();
        }
    }

}