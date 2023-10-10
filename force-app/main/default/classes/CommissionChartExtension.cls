/*
 * 		Name:		CommissionChartExtension
 * 		Date:		2/2016
 * 		Author:		Cole Conroy - RoyCon Technologies
 * 		Desc:		Extension for CommissionChart VF Page
 * 
 */
public class CommissionChartExtension {
    
    @TestVisible private final Opportunity opp;
    
    public date clsdate;
    public decimal commish;
    public string rank;
    public string lType;
    public string oppProt;
    public boolean oppDD;
    public boolean oppInflation;
    public boolean subscription;
    public boolean subscription4;
    public double cash10 {get;set;}
    public double pnts10 {get;set;}
    public double cash11 {get;set;}
    public double pnts11 {get;set;}
    public double cash12 {get;set;}
    public double pnts12 {get;set;}
    public double cash13 {get;set;}
    public double pnts13 {get;set;}
    public double cash14 {get;set;}
    public double pnts14 {get;set;}
    public double cash15 {get;set;}
    public double pnts15 {get;set;}
    public double cash16 {get;set;}
    public double pnts16 {get;set;}
    public double cash17 {get;set;}
    public double pnts17 {get;set;}
    public double cash18 {get;set;}
    public double pnts18 {get;set;}
    public double cash19 {get;set;}
    public double pnts19 {get;set;}
    public double cash20 {get;set;}
    public double pnts20 {get;set;}
    public double cash21 {get;set;}
    public double pnts21 {get;set;}
    public double cash22 {get;set;}
    public double pnts22 {get;set;}
    public double cash23 {get;set;}
    public double pnts23 {get;set;}
    public double cash24 {get;set;}
    public double pnts24 {get;set;}
    public double cash25 {get;set;}
    public double pnts25 {get;set;}
    public double cash26 {get;set;}
    public double pnts26 {get;set;}
    public double cash27 {get;set;}
    public double pnts27 {get;set;}
    public double cash28 {get;set;}
    public double pnts28 {get;set;}
    public double cash29 {get;set;}
    public double pnts29 {get;set;}
    public double cash30 {get;set;}
    public double pnts30 {get;set;}
    
   
    
    public CommissionChartExtension(ApexPages.StandardController stdController){
        this.opp = (Opportunity)stdController.getRecord();
        opp.id = ApexPages.currentPage().getParameters().get('Id');
        for(Opportunity o : [SELECT Id, Account.Lead_Type__c, CloseDate, Name, Commission__c, Deck_Rank__c, Permission_to_Inflate__c, Tablet_Subscription__c, Order_Protocol__c, Direct_Deposit__c FROM Opportunity WHERE Id = :opp.id]){
            subscription = False;
            subscription4 = False;
            clsdate = o.closeDate;
            if(o.Commission__c != null){
            	commish = o.Commission__c;   
            }
            else{
                commish = 15;
            }
            rank 	= o.Deck_Rank__c;
            lType 	= o.Account.Lead_Type__c;
            oppProt = o.Order_Protocol__c;
            oppDD   = o.Direct_Deposit__c;
            if(o.Permission_to_Inflate__c == True){
                oppInflation = True;
            }
            else oppInflation = False;
            if(o.Tablet_Subscription__c == 'Yes' || o.Tablet_Subscription__c == '$15 Monthly Subscription' || o.Tablet_Subscription__c == '$300 Upfront Fee'){
                subscription = True;
            }
            else if(o.Tablet_Subscription__c == '$15 Monthly Subscription + $300 Upfront Fee'){
                subscription4 = True;
            }
        }
        system.debug('-----lType-----'+lType);
        double aceSpades = null;
        Double ace = null;
        double king = null;
        double queen = null;
        double jack = null;
        double ten = null;
        double eight = null;
        double six = null;
        double four = null;
        double two = null;
        double joker = null;
        decimal base = null;
        double amt = null;
        date strtdt = null;
        double exponent = null;
        boolean dd = false;
        boolean prot = false;
        boolean inflation = false;
        boolean tabletSub = false;
        //sub used for subtracting from % in the factorial
        integer sub = 15;
        decimal ddvalue = 0;
        integer protvalue = 0;
        decimal inflateValue = 0;
        decimal tabletSubValue = 0;
        decimal mult = 1;
        Integer fact = 0;
        
        //Get Multiplier Values from Custom Setting and assign to variables
        List<Multiplier__c > mults = Multiplier__c.getall().values();
        date expiration = system.date.today().addDays(1);
        if(mults.size() > 1){
        	for(Multiplier__c m : mults){
                if(m.Expiration_Date__c != null){
                    expiration = m.Expiration_Date__c;
                }
            	if(clsdate >= m.Effective_Date__c && clsdate < expiration){
                    aceSpades = m.Ace_of_Spades_Multiplier__c;
                	ace 	= m.Ace_Multiplier__c;
            		king 	= m.King_Multiplier__c;
            		queen 	= m.Queen_Multiplier__c;
            		jack 	= m.Jack_Multiplier__c;
            		ten 	= m.X10_Multiplier__c;
            		eight 	= m.X8_Multiplier__c;
            		six 	= m.X6_Multiplier__c;
            		four 	= m.X4_Multiplier__c;
            		two 	= m.X2_Multiplier__c;
            		joker 	= m.Joker_Multiplier__c;
                    if(lType == 'Inside'){
            			amt = m.Inside_Commission_Pay_Point__c;
            		}
            		else{
                		amt = m.Commission_Pay_Point__c;
            		}
            		base 	= m.Base_Rate__c;
            		exponent 	= m.exponent__c;
            		dd 		= m.Include_Direct_Deposit__c;
            		prot 	= m.Include_Protocol__c;
                    inflation = m.Include_Inflation_1pt__c;
                    tabletSub = m.Include_Tablet_Subscription_2_pts__c;
            	}
        	}
        }
        else{
            aceSpades = mults[0].Ace_of_Spades_Multiplier__c;
            ace = mults[0].Ace_Multiplier__c;
            king = mults[0].King_Multiplier__c;
            queen = mults[0].Queen_Multiplier__c;
            jack = mults[0].Jack_Multiplier__c;
            ten = mults[0].X10_Multiplier__c;
            eight = mults[0].X8_Multiplier__c;
            six = mults[0].X6_Multiplier__c;
            four = mults[0].X4_Multiplier__c;
            two = mults[0].X2_Multiplier__c;
            joker = mults[0].Joker_Multiplier__c;
            if(lType == 'Inside'){
            	amt = mults[0].Inside_Commission_Pay_Point__c;
            }
            else{
                amt = mults[0].Commission_Pay_Point__c;
            }
            base = mults[0].Base_Rate__c;
            exponent = mults[0].exponent__c;
            dd = mults[0].Include_Direct_Deposit__c;
            prot = mults[0].Include_Protocol__c;
            inflation = mults[0].Include_Inflation_1pt__c;
            tabletSub = mults[0].Include_Tablet_Subscription_2_pts__c;
        }
        if(!test.isRunningTest()){
        	fact = Integer.valueOf(commish) - sub;
        }
        else{
            fact = 2;
        }
        if(dd == True && OppDD == True){
            ddvalue = 0.5;
        }
        if(oppProt != 'Other' && oppProt != null && prot == True){
            protvalue = 1;
        }
        if(inflation == True && oppInflation == True){
            inflateValue = 1;
        }
        if(tabletSub == True && subscription == True){
            tabletSubValue = 2;
        }
        else if(tabletSub == True && subscription4 == True){
            tabletSubValue = 4;
        }
        //Set multiple value based on Opp Deck Rank
        if(opp.Deck_Rank__c == 'Ace of Spades'){
            mult = aceSpades;
        }
        else if(opp.Deck_Rank__c == 'Ace'){
            mult = ace;
        }
        else if(opp.Deck_Rank__c == 'King'){
            mult = king;
        }
        else if(opp.Deck_Rank__c == 'Queen'){
            mult = queen;
        }
        else if(opp.Deck_Rank__c == 'Jack'){
            mult = jack;
        }
        else if(opp.Deck_Rank__c == '10'){
            mult = ten;
        }
        else if(opp.Deck_Rank__c == '8'){
            mult = eight;
        }
        else if(opp.Deck_Rank__c == '6'){
            mult = six;
        }
        else if(opp.Deck_Rank__c == '4'){
            mult = four;
        }
        else if(opp.Deck_Rank__c == '2'){
            mult = two;
        }
        else if(opp.Deck_Rank__c == 'Joker'){
            mult = joker;
        }
        else{
            mult = 1;
        }
        //Set Page Variables
        system.debug('---------Exponent------'+exponent);
        system.debug('---------DD------'+ddvalue);
        system.debug('---------protvalue------'+protvalue);
        system.debug('---------InflateValue------'+inflateValue);
        system.debug('---------Mult---------'+mult);
        system.debug('---------TabletSubValue-----'+tabletSubValue);
        system.debug('---------Amt--------'+amt);
        cash15 = ((((1 + base.pow(15-sub)*exponent+ddvalue+protvalue+inflateValue) * mult) + tabletSubValue) * amt).setScale(2);
        cash16 = ((((1 + base.pow(16-sub)*exponent+ddvalue+protvalue+inflateValue) * mult) + tabletSubValue) * amt).setScale(2);
        cash17 = ((((1 + base.pow(17-sub)*exponent+ddvalue+protvalue+inflateValue) * mult) + tabletSubValue) * amt).setScale(2);
        cash18 = ((((1 + base.pow(18-sub)*exponent+ddvalue+protvalue+inflateValue) * mult) + tabletSubValue) * amt).setScale(2);
        cash19 = ((((1 + base.pow(19-sub)*exponent+ddvalue+protvalue+inflateValue) * mult) + tabletSubValue) * amt).setScale(2);
        cash20 = ((((1 + base.pow(20-sub)*exponent+ddvalue+protvalue+inflateValue) * mult) + tabletSubValue) * amt).setScale(2);
        cash21 = ((((1 + base.pow(21-sub)*exponent+ddvalue+protvalue+inflateValue) * mult) + tabletSubValue) * amt).setScale(2);
        cash22 = ((((1 + base.pow(22-sub)*exponent+ddvalue+protvalue+inflateValue) * mult) + tabletSubValue) * amt).setScale(2);
        cash23 = ((((1 + base.pow(23-sub)*exponent+ddvalue+protvalue+inflateValue) * mult) + tabletSubValue) * amt).setScale(2);
        cash24 = ((((1 + base.pow(24-sub)*exponent+ddvalue+protvalue+inflateValue) * mult) + tabletSubValue) * amt).setScale(2);
        cash25 = ((((1 + base.pow(25-sub)*exponent+ddvalue+protvalue+inflateValue) * mult) + tabletSubValue) * amt).setScale(2);
        cash26 = ((((1 + base.pow(26-sub)*exponent+ddvalue+protvalue+inflateValue) * mult) + tabletSubValue) * amt).setScale(2);
        cash27 = ((((1 + base.pow(27-sub)*exponent+ddvalue+protvalue+inflateValue) * mult) + tabletSubValue) * amt).setScale(2);
        cash28 = ((((1 + base.pow(28-sub)*exponent+ddvalue+protvalue+inflateValue) * mult) + tabletSubValue) * amt).setScale(2);
        cash29 = ((((1 + base.pow(29-sub)*exponent+ddvalue+protvalue+inflateValue) * mult) + tabletSubValue) * amt).setScale(2);
        cash30 = ((((1 + base.pow(30-sub)*exponent+ddvalue+protvalue+inflateValue) * mult) + tabletSubValue) * amt).setScale(2);
        
        if(mult == acespades || mult == ace){
        	pnts10 = ((0.25 + ddvalue+protvalue+inflateValue) * mult).setScale(2) + tabletSubValue;
        	pnts11 = ((0.55 + ddvalue+protvalue+inflateValue) * mult).setScale(2) + tabletSubValue;
        	pnts12 = ((0.8 + ddvalue+protvalue+inflateValue) * mult).setScale(2) + tabletSubValue;
        	pnts13 = ((1 + ddvalue+protvalue+inflateValue) * mult).setScale(2) + tabletSubValue;
        	pnts14 = ((1.13 + ddvalue+protvalue+inflateValue) * mult).setScale(2) + tabletSubValue;
            cash10 = ((((0.25 + ddvalue+protvalue+inflateValue) * mult).setScale(2) + tabletSubValue) * amt).setScale(2);
            cash11 = ((((0.55 + ddvalue+protvalue+inflateValue) * mult).setScale(2) + tabletSubValue) * amt).setScale(2);
            cash12 = ((((0.8 + ddvalue+protvalue+inflateValue) * mult).setScale(2) + tabletSubValue) * amt).setScale(2);
            cash13 = ((((1 + ddvalue+protvalue+inflateValue) * mult).setScale(2) + tabletSubValue) * amt).setScale(2);
            cash14 = ((((1.13 + ddvalue+protvalue+inflateValue) * mult).setScale(2) + tabletSubValue) * amt).setScale(2);
        }
        else{
            pnts10 = (((ddvalue+protvalue+inflatevalue)*mult)+tabletSubValue).setScale(2);
            pnts11 = (((ddvalue+protvalue+inflatevalue)*mult)+tabletSubValue).setScale(2);
            pnts12 = (((ddvalue+protvalue+inflatevalue)*mult)+tabletSubValue).setScale(2);
            pnts13 = (((ddvalue+protvalue+inflatevalue)*mult)+tabletSubValue).setScale(2);
            pnts14 = (((ddvalue+protvalue+inflatevalue)*mult)+tabletSubValue).setScale(2);
            cash10 = null;
            cash11 = null;
            cash12 = null;
            cash13 = null;
            cash14 = null;
            
        }
        pnts15 = ((1 + base.pow(15-sub)*exponent+ddvalue+protvalue+inflateValue) * mult).setScale(2) + tabletSubValue;
        pnts16 = ((1 + base.pow(16-sub)*exponent+ddvalue+protvalue+inflateValue) * mult).setScale(2) + tabletSubValue;
        pnts17 = ((1 + base.pow(17-sub)*exponent+ddvalue+protvalue+inflateValue) * mult).setScale(2) + tabletSubValue;
        pnts18 = ((1 + base.pow(18-sub)*exponent+ddvalue+protvalue+inflateValue) * mult).setScale(2) + tabletSubValue;
        pnts19 = ((1 + base.pow(19-sub)*exponent+ddvalue+protvalue+inflateValue) * mult).setScale(2) + tabletSubValue;
        pnts20 = ((1 + base.pow(20-sub)*exponent+ddvalue+protvalue+inflateValue) * mult).setScale(2) + tabletSubValue;
        pnts21 = ((1 + base.pow(21-sub)*exponent+ddvalue+protvalue+inflateValue) * mult).setScale(2) + tabletSubValue;
        pnts22 = ((1 + base.pow(22-sub)*exponent+ddvalue+protvalue+inflateValue) * mult).setScale(2) + tabletSubValue;
        pnts23 = ((1 + base.pow(23-sub)*exponent+ddvalue+protvalue+inflateValue) * mult).setScale(2) + tabletSubValue;
        pnts24 = ((1 + base.pow(24-sub)*exponent+ddvalue+protvalue+inflateValue) * mult).setScale(2) + tabletSubValue;
        pnts25 = ((1 + base.pow(25-sub)*exponent+ddvalue+protvalue+inflateValue) * mult).setScale(2) + tabletSubValue;
        pnts26 = ((1 + base.pow(26-sub)*exponent+ddvalue+protvalue+inflateValue) * mult).setScale(2) + tabletSubValue;
        pnts27 = ((1 + base.pow(27-sub)*exponent+ddvalue+protvalue+inflateValue) * mult).setScale(2) + tabletSubValue;
        pnts28 = ((1 + base.pow(28-sub)*exponent+ddvalue+protvalue+inflateValue) * mult).setScale(2) + tabletSubValue;
        pnts29 = ((1 + base.pow(29-sub)*exponent+ddvalue+protvalue+inflateValue) * mult).setScale(2) + tabletSubValue;
        pnts30 = ((1 + base.pow(30-sub)*exponent+ddvalue+protvalue+inflateValue) * mult).setScale(2) + tabletSubValue;
   
    }
    
}