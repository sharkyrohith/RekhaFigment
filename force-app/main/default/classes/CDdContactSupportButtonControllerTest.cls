/**
 * 
 * @author: Tia Xuan
 * @date: 2020-05
 * @description Test class for CDdCommunityWebCaseController
 * 
 */
@isTest
public class CDdContactSupportButtonControllerTest {

    @isTest
    static void testCommunityWebCase() {
        Knowledge__kav art = new Knowledge__kav();
        art.Title = 'test';
        art.urlName = 'testarticleurl';
        art.Article_Experiment__c = 'Show Web Form';
        insert art;

        Test.startTest();
        String ret = CDdContactSupportButtonController.getArticleExperiment(art.Id);
        System.assertEquals('Show Web Form', ret);
        Test.stopTest();
    }
}