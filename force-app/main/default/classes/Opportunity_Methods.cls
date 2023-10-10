/**
* @author: Cole Conroy - RoyCon Technologies
* @date: 3/2016
* @description Update Open Opportunities when Deck Rank Changes on Account
##############################################################################################################################
##############################################################################################################################
##############################################################################################################################
08-13-2019: Jeegar is Commenting this out to see if someone misses this code. 
If you see this after 09-13-2019 and it is still commented, NUKE IT
##############################################################################################################################
##############################################################################################################################
##############################################################################################################################
*/ 

public class Opportunity_Methods {
    // 	Set<Id> OppIds = new Set<Id>();
    // 	Map<Id,Id> opMap = new Map<Id,Id>();
    
    // public static boolean flag = true;
    
    // public static void updateAcctClosedWon(Map<Id,Id> opMap){
    //     List<Account> acctList = new List<Account>();
        
    //     List<Menu_Team_Member__c> mmbr = [SELECT Id FROM Menu_Team_Member__c WHERE Name = 'Menu- Already Exists' LIMIT 1];
        
    //     Map<String, String> statMap = new Map<String, String>{'Local Team' => 'Local Team Working','Menu Team' => 'Pending - Menu Attached by PL'};
        
    //         for(Opportunity o : [SELECT Id, AccountId, EIN__c, Decision_Maker__c, LeadSource, Menu_Has_Been_Provided__c, Account_Number__c, Routing_Number__c, Order_Protocol__c, Menu_PDF_Attached__c, commission__c, Delivery__c, Inflation__c, Order_Protocol_Fax__c, Order_Protocol_Email__c, Payment_Protocol__c, Menu_Url__c, Menu_to_be_Completed_by__c FROM Opportunity WHERE Id IN :opMap.keyset()]){
    //             Account a = new Account();
    //             a.id = o.AccountId;
    //             if(mmbr.size() > 0 && o.Menu_to_be_completed_by__c == 'Already Complete'){
    //             	a.Menu_Team_QA__c = mmbr[0].id;
    //             	a.Menu_Team_Creation__c = mmbr[0].id;
    //                 a.Menu_Team_Status__c = 'Completed';
    //             }
    //             else{
    //                 a.Menu_Team_Status__c = statMap.get(o.Menu_to_be_completed_by__c);
    //             }
    //             	a.Order_Protocol__c = o.Order_Protocol__c;
    //             	a.Commission__c = o.Commission__c;
    //             	a.inflation__c = o.Inflation__c;
    //             	a.delivery__c = o.Delivery__c;
    //             	a.order_Protocol_fax__c = o.Order_Protocol_Fax__c;
    //             	a.order_Protocol_Email__c = o.Order_Protocol_Email__c;
    //             	a.Payment_Protocol__c = o.Payment_Protocol__c;
    //             	a.menu_url__c = o.Menu_URL__c;
    //             	a.Bank_Account_Number__c = o.account_Number__c;
    //             	a.EIN_Tax_ID__c = o.EIN__c;
    //             	a.Routing_Number__c = o.routing_Number__c;
    //             	a.How_did_you_hear_about_us__c = o.leadSource;
    //             	a.Decision_Maker__c = o.Decision_Maker__c;
    //             	acctList.add(a);
    //     }
    //     if(acctList.size() > 0){
    //         update acctList;
    //     }
      		
    // }
    
    
    // public static void updateAcctFields(Map<Id,Id>acctMap){
    //     Map<Id,Set<String>> NotesMap = new Map<Id,Set<String>>();
    //     List<Account> acctList = [SELECT Id, Contract_Notes__c, (SELECT Id, AccountId, Decision_Maker__c, Region_Type__c, Submarket__c, Commission__c, Inflation__c, Contract_Notes__c, Order_Protocol__c,
    //                               Order_Protocol_Fax__c, Order_Protocol_Email__c, Direct_Deposit__c, EIN__c, Account_Number__c, Routing_Number__c, Restaurant_Website__c,
    //                               Competitors__c, Hours_of_Operation__c, Max_Order_Size__c, Tax_Override_Rate__c, Food_Is_Bike_Friendly__c, Menu_to_be_Completed_By__c
    //                              FROM Opportunities) FROM Account WHERE ID IN :acctMap.keySet()];
    //     List<Menu_Team_Member__c> mmbr = [SELECT Id FROM Menu_Team_Member__c WHERE Name = 'Menu- Already Exists' LIMIT 1];
    //     Map<String, String> statMap = new Map<String, String>{'Local Team' => 'Local Team Working','Menu Team' => 'Pending - Menu Attached by PL'};
        
    //     for(Account a : acctList){
    //         for(Opportunity o : a.Opportunities){
    //                 String cn1 = a.Contract_Notes__c;
    //                 String cn2 = o.Contract_Notes__c;
    //                 String region = null;
    //                 if(a.Contract_Notes__c == null){
    //                     a.Contract_Notes__c = o.Contract_Notes__c;
    //                 }
    //                 else if(!cn1.contains(cn2)){
    //                     String cn3 = o.Contract_Notes__c + ', '+a.Contract_Notes__c;
    //                     a.Contract_Notes__c = cn3;
    //                 }
    //                 if(o.Region_Type__c == 'Live Region'){
    //                     region = 'Live';
    //                 }
    //                 else if(o.Region_Type__c == 'Non-Live Region'){
    //                     region = 'Pre-Launch';
    //                 }
    //                 if(mmbr.size() > 0 && o.Menu_to_be_completed_by__c == 'Already Complete'){
    //             		a.Menu_Team_QA__c = mmbr[0].id;
    //             		a.Menu_Team_Creation__c = mmbr[0].id;
    //                 	a.Menu_Team_Status__c = 'Completed';
    //             	}
    //             	else{
    //                 	a.Menu_Team_Status__c = statMap.get(o.Menu_to_be_completed_by__c);
    //             	}
    //                 a.Food_is_Bike_Friendly__c = o.Food_is_Bike_Friendly__c;
    //                 a.Hours_of_Operation__c = o.Hours_of_Operation__c;
    //                 a.Website = o.Restaurant_Website__c;
    //                 a.Max_Order_Size__c = o.Max_Order_Size__c;
    //                 a.Tax_Override_Rate__c = o.Tax_Override_Rate__c;
    //                 a.competitors__c = o.Competitors__c;
    //                 //a.Market_Area__c = o.Submarket__c;
    //                 a.Live_or_Pre_Launch__c = region;
    //                 a.Commission__c = o.Commission__c;
    //                 a.Inflation__c = o.Inflation__c;
    //                 a.Order_Protocol__c = o.Order_Protocol__c;
    //                 a.Order_Protocol_Email__c = o.Order_Protocol_Email__c;
    //                 a.Order_Protocol_Fax__c = o.Order_Protocol_Fax__c;
    //                 a.Direct_Deposit__c = o.Direct_Deposit__c;
    //                 a.EIN_Tax_ID__c = o.EIN__c;
    //                 a.Account_Number__c = o.Account_Number__c;
    //                 a.Routing_Number__c = o.Routing_Number__c;
    //                 a.Website = o.Restaurant_Website__c;
    //                 a.Decision_Maker__c = o.Decision_Maker__c;
    //         }
    //     }
    //     if(acctList.size() > 0){
    //         update acctList;
    //     }
    // }
    
    // //Calculate Point Total And Commission Earned
    // public static void setPoints(Set<Id> pointSet){
	// 	List<Opportunity> oppList = new List<Opportunity>();
    //     double aceSpades = 0;
    //     Double ace = 0;
    //     double king = 0;
    //     double queen = 0;
    //     double jack = 0;
    //     double ten = 0;
    //     double eight = 0;
    //     double six = 0;
    //     double four = 0;
    //     double two = 0;
    //     double joker = 0;
    //     decimal base;
    //     double amt;
    //     double exponent;
    //     boolean dd;
    //     boolean prot;
    //     boolean inflation;
    //     boolean tabletSub;
    //     //sub used for subtracting from % in the factorial
    //     Integer sub;
    //     decimal ddvalue;
    //     integer protvalue;
    //     decimal inflateValue;
    //     decimal tabletSubValue;
    //     decimal mult;
    //     decimal factorial;
    //     boolean proceed;
    //     decimal variable;
        
    //     for(Opportunity opp : [SELECT Id, Account.Lead_Type__c, CloseDate, Name, Commission__c, Deck_Rank__c, Permission_to_Inflate__c, Order_Protocol__c, Direct_Deposit__c, Tablet_Subscription__c FROM Opportunity WHERE Id IN :pointSet AND Deck_Rank__c != null AND Commission__c != null]){            
    //         proceed = false;
    //         base = 0;
    //         amt = 0;
    //         exponent = 0;
    //         dd = false;
    //         prot = false;
    //         inflation = false;
    //         tabletSub = false;
    //         sub = 15;
    //         ddvalue = 0;
    //         protvalue = 0;
    //         inflateValue = 0;
    //         tabletSubValue = 0;
    //         mult = 1;
    //         factorial = 0.00;
    //         variable = 0;
            
    //         for(Multiplier__c m : Multiplier__c.getall().values()){
    //             if(opp.CloseDate >= m.Effective_Date__c && opp.CloseDate <= m.Expiration_Date__c && opp.Commission__c > 9){
    //                 aceSpades = m.Ace_of_Spades_Multiplier__c;
    //             	ace 	= m.Ace_Multiplier__c;
    //         		king 	= m.King_Multiplier__c;
    //         		queen 	= m.Queen_Multiplier__c;
    //         		jack 	= m.Jack_Multiplier__c;
    //         		ten 	= m.X10_Multiplier__c;
    //         		eight 	= m.X8_Multiplier__c;
    //         		six 	= m.X6_Multiplier__c;
    //         		four 	= m.X4_Multiplier__c;
    //         		two 	= m.X2_Multiplier__c;
    //         		joker 	= m.Joker_Multiplier__c;
    //                 if(opp.Account.Lead_Type__c == 'Inside'){
    //         			amt = m.Inside_Commission_Pay_Point__c;
    //         		}
    //         		else{
    //             		amt = m.Commission_Pay_Point__c;
    //         		}
    //         		base 		= m.Base_Rate__c;
    //         		exponent 	= m.exponent__c;
    //         		dd 			= m.Include_Direct_Deposit__c;
    //         		prot 		= m.Include_Protocol__c;
    //                 inflation 	= m.Include_Inflation_1pt__c;
    //                 tabletSub 	= m.Include_Tablet_Subscription_2_pts__c;
    //                 proceed 	= True;
    //             }
    //         }
            
    //         if(proceed == True || test.isRunningTest()){
            
    //         if(opp.Commission__c >= 15){
    //             factorial = base.pow(Integer.valueOf(opp.Commission__c) - sub);
    //         }
    //         else if(opp.Commission__c < 15 && opp.Commission__c > 9){
    //             if(opp.Commission__c == 14){
    //                 variable = 1.13;
    //             }
    //             if(opp.Commission__c == 13){
    //                 variable = 1;
    //             }
    //             if(opp.Commission__c == 12){
    //                 variable = 0.8;
    //             }
    //             if(opp.Commission__c == 11){
    //                 variable = 0.55;
    //             }
    //             if(opp.Commission__c == 10){
    //                 variable = 0.25;
    //             }
    //         }
    //         else{
    //             factorial = 1;
    //         }
            
    //         if(opp.Permission_to_Inflate__c == True && inflation == True){
    //             inflateValue = 1;
    //         }
    //         if(opp.Direct_Deposit__c == True && dd == True){
    //             ddvalue = 0.5;
    //         }
    //         if(opp.Order_Protocol__c != 'Other' && opp.Order_Protocol__c != null && prot == True){
    //             protvalue = 1;
    //         }
    //         if((opp.Tablet_Subscription__c == 'Yes' || opp.Tablet_Subscription__c == '$15 Monthly Subscription' || opp.Tablet_Subscription__c =='$300 Upfront Fee') && tabletSub == True){
    //             tabletSubValue = 2;
    //         }
    //         else if(opp.Tablet_Subscription__c == '$15 Monthly Subscription + $300 Upfront Fee' && tabletSub == True){
    //             tabletSubValue = 4;
    //         }
    //         Map<String,Double> rankMap = new Map<String,Double>{'Ace of Spades' => aceSpades, 'Ace' => ace, 'King' => king, 'Queen' => queen, 'Jack' => jack, '10' => ten, '8' => eight, '6' => six, '4' => four, '2' => two, 'Joker' => joker};
    //         //Set multiple value based on Opp Deck Rank
    //         if(rankMap.get(opp.Deck_Rank__c) != null){
    //         	mult = rankMap.get(opp.Deck_Rank__c);
    //         }
    //     	else{
    //         	mult = 1;
    //     	}
    //             if(opp.Commission__c > 14){
    //         		opp.Point_Total__c = (((1 + factorial*exponent+ddvalue+protvalue+inflateValue) * mult) + tabletSubValue).setScale(2);
    //         		opp.Earned_Commission__c = ((((1 + factorial*exponent+ddvalue+protvalue+inflateValue) * mult) + tabletSubValue) * amt).setScale(2);
    //             }
    //             else if(opp.Commission__c < 15 && opp.Commission__c > 9 && (mult == Ace || mult == aceSpades)){
    //                 opp.Point_Total__c = (((variable+ddvalue+protvalue+inflatevalue) * mult) + tabletSubValue).setScale(2);
    //                 opp.Earned_Commission__c = ((((variable+ddvalue+protvalue+inflatevalue) * mult) + tabletSubValue) * amt).setScale(2);
    //             }
    //             else if((opp.Commission__c < 15 && opp.Commission__c > 9 && mult != Ace && mult != aceSpades) || opp.Commission__c < 10 ){
    //                 opp.Point_Total__c = (((ddvalue+protvalue+inflatevalue) * mult) + tabletsubValue).setscale(2);
    //                 opp.Earned_Commission__c = null;
    //             }
    //             oppList.add(opp);
    //     	}
    //     }
    //     if(oppList.size() > 0){
    //     	update oppList;
    //     }
    // }
}