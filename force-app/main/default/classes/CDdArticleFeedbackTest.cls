/**
* @author Tia Xuan	
* @date 2019-04
*
* @description Test class for CDdBatchCaseToClose
*/
@isTest
public class CDdArticleFeedbackTest {

    /**
	* @description test CDdArticleFeedbackController
	*/
	@isTest static void testArticleFeedback() {
        Knowledge__kav art = new Knowledge__kav();
        art.Title = 'test';
        art.urlName = 'testarticleurl';
        insert art;

        Test.startTest();

        CDdArticleFeedbackController.handleYesClickServer(art.Id, 'Dasher', 'en_US');
        CDdArticleFeedbackController.handleNoClickServer(art.Id, 'Other', 'testarticleurl', 'Dasher', 'en_US');

        List<Article_Feedback__c> af = [select Id from Article_Feedback__c];
        System.assert(af.size() == 2);

        Test.stopTest();

    }

}