/*
 * 		Name:		Account_Methods
 * 		Date:		3/2016
 * 		Author:		Cole Conroy - RoyCon Technologies
 * 		Desc:		Update Open Opportunities when Deck Rank Changes on Account
 * 
 */

public class Account_Methods {
    /*
    public static void updateOpps(Map<Id,String> deckMap){
        //Commented out, action is being handled in Opportunity Methods now. 7/2016
        
        List<Opportunity> oppList = new List<Opportunity>();
        for(Opportunity o : [SELECT Id, AccountId FROM Opportunity WHERE AccountId IN :deckMap.keySet() AND isClosed = False]){
            o.Deck_Rank__c = deckMap.get(o.AccountId);
            oppList.add(o);
        }
        if(oppList.size() > 0){
            update oppList;
        }
    }
*/
}