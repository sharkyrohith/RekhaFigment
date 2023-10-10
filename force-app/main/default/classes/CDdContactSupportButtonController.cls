/**
 * 
 * @author: Tia Xuan
 * @date: 2020-05
 * @description Class for the contact support button 
 * 
 */
public class CDdContactSupportButtonController {
   
    @AuraEnabled
    public static string getArticleExperiment(String artId){
        List<Knowledge__kav> ka =   [select Id, 
                                            Article_Experiment__c 
                                    from Knowledge__kav 
                                    where Id =: artId];
        if (ka.size() > 0){
            return ka[0].Article_Experiment__c;
        }
        return '';
        
    }
}