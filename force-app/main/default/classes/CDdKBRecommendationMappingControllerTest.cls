/**
 * 
 * @author: Tia Xuan
 * @date: 2020-09
 * @description Test class for CDdKBRecommendationMappingController
 * 
 */
@isTest
public class CDdKBRecommendationMappingControllerTest {
    /**
    * @description test for CDdKBRecommendationMappingController
    **/
    @isTest static void KBRecommendationTest() {

        test.startTest();

        CDdKBRecommendationMappingController.createKBRecommendation( 'test',
                                                                    'test',
                                                                    'test',
                                                                    'test',
                                                                    'test');
        List<KB_Recommendation_Mappings__c> retList = [ select Id, Name 
                                                        from KB_Recommendation_Mappings__c];
        System.assert(retList.size() == 1);

        List<KB_Recommendation_Mappings__c> kbRecList = 
            CDdKBRecommendationMappingController.getKBRecommendation();
        System.assert(kbRecList.size() == 1);

        kbRecList[0].Name = 'test 1';
        CDdKBRecommendationMappingController.updateKBRecommendation(kbRecList);
        retList = [ select Id, Name 
                    from KB_Recommendation_Mappings__c
                    where Id =: kbRecList[0].Id];
        System.assert(retList[0].Name == 'test 1');


        CDdKBRecommendationMappingController.deleteKBRecommendation(kbRecList[0].Id);
        retList = [ select Id, Name 
                    from KB_Recommendation_Mappings__c];
        System.assert(retList.size() == 0);

        test.stopTest();  
    }
 
}