/**
 * @author Mahesh Chouhan
 * @date April 2023
 * @description Test class for the methods in CDdArticlesWithTopicController
 */

@isTest
public class CDdArticlesWithTopicControllerTest {
    private static final String LANGUAGE_EN = 'en_US';
    private static final String TOPIC_NAME = 'Test Customer Support';

    /**
     * @description Prepare test data
     */
    @TestSetup
    static void setup() {
        List<Knowledge__kav> articles = new List<Knowledge__kav>();
        List<TopicAssignment> topicAssignments = new List<TopicAssignment>();
        List<String> articleTitles = new List<String>();

        Topic kbArticleTopic = new Topic(Name = TOPIC_NAME);
        insert kbArticleTopic;

        for(Integer index = 0; index < 3; index++){
            Knowledge__kav knowledgeArticle = new Knowledge__kav();
            knowledgeArticle.Title = 'Knowledge Article ' + index;
            knowledgeArticle.UrlName = 'knowledge-article-' + index;
            knowledgeArticle.Language = LANGUAGE_EN;
            articleTitles.add(knowledgeArticle.Title);
            articles.add(knowledgeArticle);
        }
        insert articles;

        List<Knowledge__kav> queryArticles = [SELECT Id, KnowledgeArticleId FROM Knowledge__kav WHERE Title IN :articleTitles];
        for(Knowledge__kav article : queryArticles){
            KbManagement.PublishingService.publishArticle(article.KnowledgeArticleId, true);
            topicAssignments.add(new TopicAssignment(EntityId = article.Id, TopicId = kbArticleTopic.Id));
        }

        insert topicAssignments;
    }

    /**
     * @description Test method for getArticles method for Grouped Articles
     */
    @isTest
    static void testGetGroupedArticles(){
        String topicId = 'TestTopicId';
        CDdArticlesWithTopicController.KBArticleResponse response = CDdArticlesWithTopicController.getArticles(LANGUAGE_EN, topicId, 10, 'consumers');

        System.assert(response.groupedArticles.size() > 0, 'No Grouping exists for Topic : ' + topicId);
        System.assertEquals('Test Category', response.groupedArticles[0].category, 'Category label is not same as expected');
        System.assertEquals('Test Subcategory', response.groupedArticles[0].subcategory[0].category, 'Subcategory label is not same as expected');
    }

    /**
     * @description Test method for getArticles method for Ungrouped Articles
     */
    @isTest
    static void testGetListArticles(){
        Topic testTopic = [SELECT ID FROM Topic WHERE Name = :TOPIC_NAME];
        CDdArticlesWithTopicController.KBArticleResponse response = CDdArticlesWithTopicController.getArticles(LANGUAGE_EN, testTopic.Id, 10, 'consumers');

        System.assertEquals(3, response.ungroupedArticles.size(),
            String.format('Number of articles found for Topic {0} is not same as expected.', new List<String>{TOPIC_NAME}));
    }
}