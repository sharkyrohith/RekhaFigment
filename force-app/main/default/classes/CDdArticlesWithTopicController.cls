/**
 * CDdArticlesWithTopicController
 * @jira https://doordash.atlassian.net/browse/BASD-45965
 * @author Mahesh Chouhan
 * @date  April 2023
 * @decription Controller for lwcDdArticlesWithTopic lwc component
 */
public class CDdArticlesWithTopicController {

    public static final String ARTICLE_PREFIX = '/{0}/s/article/';

   /**
    * @author Mahesh Chouhan
    * @date  April 2023
    * @decription Returns list of wrapper containing grouped articles
    * @param String lang - Language of KB Article
    * @param String topicId - Id of the topic associated with KB Article
    * @return List<GroupArticleWrapper> Wrapper containing grouped Articles by Category and Subcategory
    */
    public static List<GroupArticleWrapper> getGroupedArticles(String lang, String topicId){
        try {
            List<KB_Article_Item__mdt> kbArticles = [SELECT ID, Article_Label__c, Article_URL__c, Order__c, KB_Article_Category__c, KB_Article_Category__r.Category_Label__c,
                                                     KB_Article_Category__r.Active__c, KB_Article_Subcategory__c, KB_Article_Subcategory__r.Subcategory_Label__c,
                                                     KB_Article_Category__r.Order__c, KB_Article_Subcategory__r.Active__c,
                                                     KB_Article_Subcategory__r.KB_Article_Category__r.Category_Label__c,
                                                     KB_Article_Subcategory__r.KB_Article_Category__r.Order__c,
                                                     KB_Article_Subcategory__r.KB_Article_Category__r.Active__c
                                                     FROM KB_Article_Item__mdt
                                                     WHERE Active__c = true AND Language__c = :lang AND Topic_Id__c = :topicId ORDER BY Order__c];
            //Key is Category Label and Value is Grouped Articles by Category
            Map<String, GroupArticleWrapper> categoryGrouped = new Map<String, GroupArticleWrapper>();
            //Key is Subcategory Label and Value is Grouped Articles by Subcategory
            Map<String, GroupArticleWrapper> subcategoryGrouped = new Map<String, GroupArticleWrapper>();

            for(KB_Article_Item__mdt kbArticle : kbArticles){
                if(kbArticle.KB_Article_Category__c != null){
                    //Create GroupArticleWrapper instance with category Label and Links
                    String categoryLabel = kbArticle.KB_Article_Category__r.Category_Label__c;
                    Boolean isCategoryActive = kbArticle.KB_Article_Category__r.Active__c;
                    Integer order = Integer.valueOf(kbArticle.KB_Article_Category__r.Order__c);
                    if(!categoryGrouped.containsKey(categoryLabel) && isCategoryActive){
                        GroupArticleWrapper gaWInstance = new GroupArticleWrapper();
                        gaWInstance.category = categoryLabel;
                        gaWInstance.order = order;
                        gaWInstance.links = new List<ArticleWrapper>();
                        categoryGrouped.put(categoryLabel, gaWInstance);
                    }

                    if(categoryGrouped.containsKey(categoryLabel)){
                        ArticleWrapper articleWrapper = new ArticleWrapper();
                        articleWrapper.url = kbArticle.Article_URL__c;
                        articleWrapper.label = kbArticle.Article_Label__c;
                        categoryGrouped.get(categoryLabel).links.add(articleWrapper);
                    }
                }
                else if(kbArticle.KB_Article_Subcategory__c != null){
                    //Create GroupArticleWrapper instance with subcategory Label and Links
                    String categoryLabel = kbArticle.KB_Article_Subcategory__r.KB_Article_Category__r.Category_Label__c;
                    Integer order = Integer.valueOf(kbArticle.KB_Article_Subcategory__r.KB_Article_Category__r.Order__c);
                    Boolean isCategoryActive = kbArticle.KB_Article_Subcategory__r.KB_Article_Category__r.Active__c;
                    String subcategoryLabel = kbArticle.KB_Article_Subcategory__r.Subcategory_Label__c;
                    Boolean isSubcategoryActive = kbArticle.KB_Article_Subcategory__r.Active__c;
                    if(!subcategoryGrouped.containsKey(subcategoryLabel) && isSubcategoryActive){
                        GroupArticleWrapper gaWInstance = new GroupArticleWrapper();
                        gaWInstance.category = subcategoryLabel;
                        gaWInstance.links = new List<ArticleWrapper>();
                        subcategoryGrouped.put(subcategoryLabel, gaWInstance);
                    }

                    if(subcategoryGrouped.containsKey(subcategoryLabel)){
                        ArticleWrapper articleWrapper = new ArticleWrapper();
                        articleWrapper.url = kbArticle.Article_URL__c;
                        articleWrapper.label = kbArticle.Article_Label__c;

                        subcategoryGrouped.get(subcategoryLabel).links.add(articleWrapper);
                    }

                    if(!categoryGrouped.containsKey(categoryLabel) && isCategoryActive){
                        GroupArticleWrapper gaWInstance = new GroupArticleWrapper();
                        gaWInstance.category = categoryLabel;
                        gaWInstance.order = order;
                        gaWInstance.links = new List<ArticleWrapper>();
                        gaWInstance.subcategory = new List<GroupArticleWrapper>();
                        categoryGrouped.put(categoryLabel, gaWInstance);
                    }
                }
            }

            Set<String> processedSubcategories = new Set<String>();
            //Populate subcategory list for GroupArticleWrapper instance
            for(KB_Article_Item__mdt kbArticle : kbArticles){
                String categoryLabel = kbArticle.KB_Article_Subcategory__r.KB_Article_Category__r.Category_Label__c;
                String subcategoryLabel = kbArticle.KB_Article_Subcategory__r.Subcategory_Label__c;
                if(kbArticle.KB_Article_Subcategory__c != null && !processedSubcategories.contains(subcategoryLabel) && categoryGrouped.containsKey(categoryLabel)){
                    if(categoryGrouped.get(categoryLabel).subcategory == null){
                        categoryGrouped.get(categoryLabel).subcategory = new List<GroupArticleWrapper>();
                    }
                    categoryGrouped.get(categoryLabel).subcategory.add(subcategoryGrouped.get(subcategoryLabel));
                    processedSubcategories.add(subcategoryLabel);
                }
            }

            return categoryGrouped.values();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
    * @author Mahesh Chouhan
    * @date  April 2023
    * @decription Returns wrapper containing grouped and ungrouped articles
    * @param String lang - Language of KB Article
    * @param String topicId - Id of the topic associated with KB Article
    * @param Integer limitSize - No of articles to be displayed for ungrouped articles
    * @return KBArticleResponse Wrapper containing grouped and ungrouped articles
    */
    @AuraEnabled(cacheable=true)
    public static KBArticleResponse getArticles(String lang, String topicId, Integer limitSize, String community){
        List<GroupArticleWrapper> groupedArticles = getGroupedArticles(lang, topicId);
        KBArticleResponse kbArticleResponse = new KBArticleResponse();

        if(groupedArticles.size() > 0){
            groupedArticles.sort();
            kbArticleResponse.groupedArticles = groupedArticles;
        }
        else {
            List<ArticleWrapper> articleWrapperList = new List<ArticleWrapper>();
            /* Added LIMIT to overcome error
             Implementation restriction: TopicAssignment only allows security evaluation for non-admin users when either (1) LIMIT is specified */
            List<TopicAssignment> assignmentList = [SELECT EntityId FROM TopicAssignment WHERE TopicId = :topicId LIMIT 1000];
            Set<Id> entityIds = new Set<Id>();
            for(TopicAssignment assignment : assignmentList){
                entityIds.add(assignment.EntityId);
            }
            List<KnowledgeArticleVersion> kavList = [SELECT Id, UrlName, Title
                                                 FROM KnowledgeArticleVersion
                                                 WHERE Language = :lang AND PublishStatus = 'Online' AND Id in :entityIds
                                                 ORDER BY LastPublishedDate DESC];
            for(KnowledgeArticleVersion kav : kavList){
                ArticleWrapper articleWrapper = new ArticleWrapper();
                articleWrapper.label = kav.Title;
                articleWrapper.url = String.format(ARTICLE_PREFIX, new List<String>{community}) + kav.UrlName;
                articleWrapperList.add(articleWrapper);
            }
            kbArticleResponse.ungroupedArticles = articleWrapperList;
        }
        return kbArticleResponse;
    }

    /**
     * @decription Wrapper for grouping KB article
     * JSON representation of GroupArticleWrapper
        [
            {
                category : 'Category 1',
                links :
                    [
                        {
                            label: 'Link 1',
                            url: 'Link URL 1'
                        }
                    ]
            },
            {
                category : 'Category 2',
                subcategory:
                    [
                        {
                            category : 'Subcategory 1',
                            links :
                                [
                                    {
                                        label: 'Link 2',
                                        url: 'Link URL 2'
                                    }
                                ]
                        }
                    ]
            }
        ]
     */
    public class GroupArticleWrapper implements Comparable{
        @AuraEnabled
        public Integer order;
        @AuraEnabled
        public String category;
        @AuraEnabled
        public List<GroupArticleWrapper> subcategory;
        @AuraEnabled
        public List<ArticleWrapper> links;

        public Integer compareTo(Object compareTo) {
            GroupArticleWrapper compareToEmp = (GroupArticleWrapper)compareTo;
            return order > compareToEmp.order ? 1 : (order == compareToEmp.order ? 0 : -1);
        }
    }

    /**
     * @decription Wrapper for single KB article
     */
    public class ArticleWrapper {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String url;
    }

    public class KBArticleResponse{
        @AuraEnabled
        public List<GroupArticleWrapper> groupedArticles;
        @AuraEnabled
        public List<ArticleWrapper> ungroupedArticles;
    }
}