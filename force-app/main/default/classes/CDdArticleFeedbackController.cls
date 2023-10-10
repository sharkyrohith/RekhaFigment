/* 
 * @author: Tia Xuan (Perficient)
 * @date : 2019-10
 * @description: public article feedback component
 */
global class CDdArticleFeedbackController {

    /** 
    * @description handle the click yes event and save the result to Community Article Feedback
    * @param articleId article ID 
    */
    @AuraEnabled
    public static void handleYesClickServer(Id articleId, String comm, String lang){
        Article_Feedback__c articleFeedback = getArticleFeedback(articleId);
        articleFeedback.Was_this_article_helpful__c = 'Yes';
        articleFeedback.Community__c = comm;
        articleFeedback.Language__c = lang;
        insert articleFeedback;
    }

    /** 
    * @description handle the click no event and save the result to Community Article Feedback
    * @param articleId article ID 
    */
    @AuraEnabled
    public static void handleNoClickServer(Id articleId, String option, String mInfo, String comm, String lang){
        Article_Feedback__c articleFeedback = getArticleFeedback(articleId);
        articleFeedback.Was_this_article_helpful__c = 'No';
        articleFeedback.How_can_we_improve_this_article__c = option;
        articleFeedback.Let_us_know_how_this_article_helped__c = mInfo;
        articleFeedback.Community__c = comm;
        articleFeedback.Language__c = lang;
        insert articleFeedback;

    }

    /** 
    * @description get the article feedback
    * @param articleId article ID 
    */
    @AuraEnabled
    public static Article_Feedback__c getArticleFeedback(Id articleId) {
        KnowledgeArticleVersion article = [ SELECT Id, ArticleNumber, Title
        FROM KnowledgeArticleVersion 
        WHERE Id =: articleId];
        Article_Feedback__c articleFeedback = new Article_Feedback__c(Article_Id__c = articleId, 
                Title__c = article.Title,
                Article_Number__c = article.ArticleNumber);

        return articleFeedback;
    }

}