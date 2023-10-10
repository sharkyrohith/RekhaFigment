/**
* @author Tia Xuan
* @date 2019-11
* @description BZAP-5425 -- Migrate Legal docs from community page to knowledge articles
*/
public without sharing class CDdLegalArticleController {

    /**
    * @description BZAP-5425 get article with article url and language
    */
    @auraEnabled
    public static String getArticle(String url, string lang){
        List<KnowledgeArticleVersion> kaMainArt = [    SELECT Id, KnowledgeArticleId
                                                        FROM KnowledgeArticleVersion 
                                                        WHERE PublishStatus = 'Online'
                                                            and UrlName =: url]; 
        
        if (kaMainArt.size() > 0){                            
            List<KnowledgeArticleVersion> kaArts = [    SELECT Id, KnowledgeArticleId, Language
                                                        FROM KnowledgeArticleVersion 
                                                        WHERE PublishStatus = 'Online'
                                                            and KnowledgeArticleId =: kaMainArt[0].KnowledgeArticleId]; 

            if (kaArts.size() > 0){
                KnowledgeArticleVersion kav = null;
                for (KnowledgeArticleVersion ka : kaArts){
                    if (ka.Language == lang){
                        kav = ka;
                    }
                }

                if (kav != null){
                    String qry = 'SELECT Id, Title, Communities_Article_Details__c ';
                    qry += ' from Knowledge__kav ' ;
                    qry += ' where Id = \'' + kav.Id + '\'';
                    System.debug('qry:' + qry);

                    SObject obj = Database.query(qry);
                    return JSON.serialize(obj);
                }
            }  
        }                                             
        return '{}';
    }
}