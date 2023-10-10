/**
* @author Tia Xuan
* @date 2019-11
* @description Test class for CDdLegalArticleController
*/
@isTest
public with sharing class CDdLegalArticleTest {
    
    /**
    * @description BZAP-5425 test get Article
    */
    static testMethod void testGetArticle() {

        Knowledge__kav newArticle = new Knowledge__kav(
          Title='test article', 
          UrlName='testarticleurl', 
          Language='en_US', 
          Communities_Article_Details__c='test'
        );

        insert newArticle;

        Knowledge__kav comArt = [ select Id, KnowledgeArticleId
                                            from Knowledge__kav
                                            where Id =: newArticle.Id];


        KbManagement.PublishingService.publishArticle(comArt.KnowledgeArticleId, true);
        Test.startTest();
        String artDetail = CDdLegalArticleController.getArticle('testarticleurl', 'en_US');
        System.assert(artDetail != '{}');
        artDetail = CDdLegalArticleController.getArticle('test', 'en_US');
        System.assert(artDetail == '{}');
        Test.stopTest();

    }
}