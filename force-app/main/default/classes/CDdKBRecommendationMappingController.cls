/**
 * 
 * @author: Tia Xuan
 * @date: 2020-09
 * @description Class for managing KB Recommendation mapping custom setting
 *              BZAPSUP-864 Create a management page for KB Recommendations
 * 
 */
public class CDdKBRecommendationMappingController { 
    @AuraEnabled(Cacheable = true)
    public static List<KB_Recommendation_Mappings__c> getKBRecommendation(){
        List<KB_Recommendation_Mappings__c> retVal = [  select  Id,
                                                                Name,
                                                                Case_Category__c,
                                                                Case_Sub_Category__c,
                                                                Customer_Type__c,
                                                                Recommended_KB_Article__c
                                                        from KB_Recommendation_Mappings__c];
        return retVal;
    }

    @AuraEnabled
    public static void updateKBRecommendation(List<KB_Recommendation_Mappings__c> changedRows){
        update changedRows;
    }

    @AuraEnabled
    public static void createKBRecommendation(  String name,
                                                String category,
                                                String subcategory,
                                                String customerType,
                                                String recommendedKBArticleId){
        KB_Recommendation_Mappings__c rec = new KB_Recommendation_Mappings__c();
        rec.Name = name;
        rec.Case_Category__c = category;
        rec.Case_Sub_Category__c = subcategory;
        rec.Customer_Type__c = customerType;
        rec.Recommended_KB_Article__c = recommendedKBArticleId;
        insert rec;
    }

    @AuraEnabled
    public static void deleteKBRecommendation(String mappingId){
        List<KB_Recommendation_Mappings__c> retVal = [  select  Id
                                                        from KB_Recommendation_Mappings__c
                                                        where Id =: mappingId];
        if (retVal.size() > 0){
            delete retVal;
        }
    }
}