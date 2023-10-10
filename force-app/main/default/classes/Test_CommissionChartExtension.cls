/*
 *		Name: 		Test_CommissionChartExtension
 * 		Date:		2/2016
 * 		Author:		Cole Conroy - RoyCon Technologies
 * 		Desc:		Test Class for CommissionChartExtension
 */

@isTest
public class Test_CommissionChartExtension {
    
    public static testmethod void chart(){
        Trigger_Control_Panel__c cp = new Trigger_Control_Panel__c();
        cp.Name = 'Main';
        cp.Opportunity_Trigger_Enabled__c = true;
        cp.Account_Trigger_Enabled__c = true;
        upsert cp;
        
    	Account a = new Account();
    	a.Name = 'Test Account';
    	a.BillingState = 'TX';
        a.Lead_Type__c = 'Outside';
    	insert a;
    
    	Opportunity o = new Opportunity();
        o.Name = 'Test Opp';
    	o.AccountId = a.id;
    	o.CloseDate = system.date.today().addDays(20);
    	o.StageName = 'Prospecting';
    	o.Amount = 100;
        o.Commission__c = 0.20;
        o.Deck_Rank__c = 'Ace';
        o.Permission_to_Inflate__c = true;
        o.Tablet_Subscription__c = 'Yes';
        o.Menu_to_be_completed_by__c = null;
        o.Menu_Setup_Method__c =  null;
        o.Tablet_Kit_Type__c = null;
    
    	Multiplier__c m = new Multiplier__c();
    	m.Ace_Multiplier__c = 4;
    	m.King_Multiplier__c = 3.9;
    	m.Queen_Multiplier__c = 3.8;
    	m.Jack_Multiplier__c = 3.7;
    	m.X10_Multiplier__c = 3.6;
    	m.X8_Multiplier__c = 3.4;
    	m.X6_Multiplier__c = 3.2;
    	m.X4_Multiplier__c = 3;
    	m.X2_Multiplier__c = 2;
    	m.Joker_Multiplier__c = 1;
        m.Base_Rate__c = 1.27;
        m.Effective_Date__c = system.date.today().addDays(-2);
        m.Expiration_Date__c = system.date.today().addDays(30);
        m.Commission_Pay_Point__c = 25;
        m.Name = 'Master';
        m.Include_Protocol__c = True;
        m.Exponent__c = 0.2;
        m.Include_Direct_Deposit__c = True;
        m.Include_Tablet_Subscription_2_pts__c = True;
        m.Include_Inflation_1pt__c = True;
        m.Ace_of_Spades_Multiplier__c = 4;
        m.Inside_Commission_Pay_Point__c = 5;
    	insert m;
        
       insert o;
        
        test.startTest();
        
        ApexPages.StandardController std = new ApexPages.StandardController(o);
        CommissionChartExtension ext = new CommissionChartExtension(std);
        
        test.stopTest();
        
    }
    
    public static testmethod void chart2(){
        Trigger_Control_Panel__c cp = new Trigger_Control_Panel__c();
        cp.Name = 'Main';
        cp.Opportunity_Trigger_Enabled__c = true;
        cp.Account_Trigger_Enabled__c = true;
        upsert cp;
        
    	Account a = new Account();
    	a.Name = 'Test Account';
    	a.BillingState = 'TX';
    	insert a;
    
    	Opportunity o = new Opportunity();
        o.Name = 'Test Opp';
    	o.AccountId = a.id;
    	o.CloseDate = system.date.today().addDays(20);
    	o.StageName = 'Prospecting';
    	o.Amount = 100;
        o.Commission__c = 20;
        o.Deck_Rank__c = 'King';
        o.Permission_to_Inflate__c = False;
        o.Tablet_Subscription__c = 'No';
        o.Menu_to_be_completed_by__c = null;
        o.Menu_Setup_Method__c =  null;
        o.Tablet_Kit_Type__c = null;
    
    	Multiplier__c m = new Multiplier__c();
    	m.Ace_Multiplier__c = 4;
    	m.King_Multiplier__c = 3.9;
    	m.Queen_Multiplier__c = 3.8;
    	m.Jack_Multiplier__c = 3.7;
    	m.X10_Multiplier__c = 3.6;
    	m.X8_Multiplier__c = 3.4;
    	m.X6_Multiplier__c = 3.2;
    	m.X4_Multiplier__c = 3;
    	m.X2_Multiplier__c = 2;
    	m.Joker_Multiplier__c = 1;
        m.Base_Rate__c = 1.27;
        m.Effective_Date__c = system.date.today().addDays(-2);
        m.Expiration_Date__c = system.date.today().addDays(30);
        m.Commission_Pay_Point__c = 25;
        m.Name = 'Master';
        m.Include_Protocol__c = True;
        m.Exponent__c = 0.2;
        m.Include_Direct_Deposit__c = True;
        m.Include_Tablet_Subscription_2_pts__c = True;
        m.Include_Inflation_1pt__c = True;
        m.Ace_of_Spades_Multiplier__c = 4;
        m.Inside_Commission_Pay_Point__c = 5;
    	insert m;
        
        insert o;
        
        test.startTest();
        
        ApexPages.StandardController std = new ApexPages.StandardController(o);
        CommissionChartExtension ext = new CommissionChartExtension(std);
        
        test.stopTest();
        
    }
    
    public static testmethod void chart3(){
        Trigger_Control_Panel__c cp = new Trigger_Control_Panel__c();
        cp.Name = 'Main';
        cp.Opportunity_Trigger_Enabled__c = true;
        cp.Account_Trigger_Enabled__c = true;
        upsert cp;
        
    	Account a = new Account();
    	a.Name = 'Test Account';
    	a.BillingState = 'TX';
    	insert a;
    
    	Opportunity o = new Opportunity();
        o.Name = 'Test Opp';
    	o.AccountId = a.id;
    	o.CloseDate = system.date.today().addDays(20);
    	o.StageName = 'Prospecting';
    	o.Amount = 100;
        o.Commission__c = 20;
        o.Deck_Rank__c = 'Queen';
        o.Permission_to_Inflate__c = true;
        o.Tablet_Subscription__c = 'Yes';
        o.Menu_to_be_completed_by__c = null;
        o.Menu_Setup_Method__c =  null;
        o.Tablet_Kit_Type__c = null;
    
    	Multiplier__c m = new Multiplier__c();
    	m.Ace_Multiplier__c = 4;
    	m.King_Multiplier__c = 3.9;
    	m.Queen_Multiplier__c = 3.8;
    	m.Jack_Multiplier__c = 3.7;
    	m.X10_Multiplier__c = 3.6;
    	m.X8_Multiplier__c = 3.4;
    	m.X6_Multiplier__c = 3.2;
    	m.X4_Multiplier__c = 3;
    	m.X2_Multiplier__c = 2;
    	m.Joker_Multiplier__c = 1;
        m.Base_Rate__c = 1.27;
        m.Effective_Date__c = system.date.today().addDays(-2);
        m.Expiration_Date__c = system.date.today().addDays(30);
        m.Commission_Pay_Point__c = 25;
        m.Name = 'Master';
        m.Include_Protocol__c = True;
        m.Exponent__c = 0.2;
        m.Include_Direct_Deposit__c = True;
        m.Include_Tablet_Subscription_2_pts__c = True;
        m.Include_Inflation_1pt__c = True;
        m.Ace_of_Spades_Multiplier__c = 4;
        m.Inside_Commission_Pay_Point__c = 5;
    	insert m;
        
   	 	insert o;
        test.startTest();
        
        ApexPages.StandardController std = new ApexPages.StandardController(o);
        CommissionChartExtension ext = new CommissionChartExtension(std);
        
        test.stopTest();
        
    }
    
    public static testmethod void chart4(){
        Trigger_Control_Panel__c cp = new Trigger_Control_Panel__c();
        cp.Name = 'Main';
        cp.Opportunity_Trigger_Enabled__c = true;
        cp.Account_Trigger_Enabled__c = true;
        upsert cp;
        
    	Account a = new Account();
    	a.Name = 'Test Account';
    	a.BillingState = 'TX';
    	insert a;
    
    	Opportunity o = new Opportunity();
        o.Name = 'Test Opp';
    	o.AccountId = a.id;
    	o.CloseDate = system.date.today().addDays(20);
    	o.StageName = 'Prospecting';
    	o.Amount = 100;
        o.Commission__c = 20;
        o.Deck_Rank__c = 'Jack';
        o.Permission_to_Inflate__c = true;
        o.Tablet_Subscription__c = 'Yes';
        o.Menu_to_be_completed_by__c = null;
        o.Menu_Setup_Method__c =  null;
        o.Tablet_Kit_Type__c = null;
    
    	Multiplier__c m = new Multiplier__c();
    	m.Ace_Multiplier__c = 4;
    	m.King_Multiplier__c = 3.9;
    	m.Queen_Multiplier__c = 3.8;
    	m.Jack_Multiplier__c = 3.7;
    	m.X10_Multiplier__c = 3.6;
    	m.X8_Multiplier__c = 3.4;
    	m.X6_Multiplier__c = 3.2;
    	m.X4_Multiplier__c = 3;
    	m.X2_Multiplier__c = 2;
    	m.Joker_Multiplier__c = 1;
        m.Base_Rate__c = 1.27;
        m.Effective_Date__c = system.date.today().addDays(-2);
        m.Expiration_Date__c = system.date.today().addDays(30);
        m.Commission_Pay_Point__c = 25;
        m.Name = 'Master';
        m.Include_Protocol__c = True;
        m.Exponent__c = 0.2;
        m.Include_Direct_Deposit__c = True;
        m.Include_Tablet_Subscription_2_pts__c = True;
        m.Include_Inflation_1pt__c = True;
        m.Ace_of_Spades_Multiplier__c = 4;
        m.Inside_Commission_Pay_Point__c = 5;
    	insert m;
       
        insert o;
        test.startTest();
        
        ApexPages.StandardController std = new ApexPages.StandardController(o);
        CommissionChartExtension ext = new CommissionChartExtension(std);
        
        test.stopTest();
        
    }
    
    public static testmethod void chart5(){
        Trigger_Control_Panel__c cp = new Trigger_Control_Panel__c();
        cp.Name = 'Main';
        cp.Opportunity_Trigger_Enabled__c = true;
        cp.Account_Trigger_Enabled__c = true;
        upsert cp;
        
    	Account a = new Account();
    	a.Name = 'Test Account';
    	a.BillingState = 'TX';
    	insert a;
    
    	Opportunity o = new Opportunity();
        o.Name = 'Test Opp';
    	o.AccountId = a.id;
    	o.CloseDate = system.date.today().addDays(20);
    	o.StageName = 'Prospecting';
    	o.Amount = 100;
        o.Commission__c = 20;
        o.Deck_Rank__c = '10';
        o.Permission_to_Inflate__c = true;
        o.Tablet_Subscription__c = 'Yes';
        o.Menu_to_be_completed_by__c = null;
        o.Menu_Setup_Method__c =  null;
        o.Tablet_Kit_Type__c = null;
    
    	Multiplier__c m = new Multiplier__c();
    	m.Ace_Multiplier__c = 4;
    	m.King_Multiplier__c = 3.9;
    	m.Queen_Multiplier__c = 3.8;
    	m.Jack_Multiplier__c = 3.7;
    	m.X10_Multiplier__c = 3.6;
    	m.X8_Multiplier__c = 3.4;
    	m.X6_Multiplier__c = 3.2;
    	m.X4_Multiplier__c = 3;
    	m.X2_Multiplier__c = 2;
    	m.Joker_Multiplier__c = 1;
        m.Base_Rate__c = 1.27;
        m.Effective_Date__c = system.date.today().addDays(-2);
        m.Expiration_Date__c = system.date.today().addDays(30);
        m.Commission_Pay_Point__c = 25;
        m.Name = 'Master';
        m.Include_Protocol__c = True;
        m.Exponent__c = 0.2;
        m.Include_Direct_Deposit__c = True;
        m.Include_Tablet_Subscription_2_pts__c = True;
        m.Include_Inflation_1pt__c = True;
        m.Ace_of_Spades_Multiplier__c = 4;
        m.Inside_Commission_Pay_Point__c = 5;
    	insert m;
        
        insert o;
        test.startTest();
        
        ApexPages.StandardController std = new ApexPages.StandardController(o);
        CommissionChartExtension ext = new CommissionChartExtension(std);
        
        test.stopTest();
    }
    
    public static testmethod void chart6(){
        Trigger_Control_Panel__c cp = new Trigger_Control_Panel__c();
        cp.Name = 'Main';
        cp.Opportunity_Trigger_Enabled__c = true;
        cp.Account_Trigger_Enabled__c = true;
        upsert cp;
        
    	Account a = new Account();
    	a.Name = 'Test Account';
    	a.BillingState = 'TX';
    	insert a;
    
    	Opportunity o = new Opportunity();
        o.Name = 'Test Opp';
    	o.AccountId = a.id;
    	o.CloseDate = system.date.today().addDays(20);
    	o.StageName = 'Prospecting';
    	o.Amount = 100;
        o.Commission__c = 20;
        o.Deck_Rank__c = '8';
        o.Permission_to_Inflate__c = true;
        o.Tablet_Subscription__c = 'Yes';
        o.Menu_to_be_completed_by__c = null;
        o.Menu_Setup_Method__c =  null;
        o.Tablet_Kit_Type__c = null;
    
    	Multiplier__c m = new Multiplier__c();
    	m.Ace_Multiplier__c = 4;
    	m.King_Multiplier__c = 3.9;
    	m.Queen_Multiplier__c = 3.8;
    	m.Jack_Multiplier__c = 3.7;
    	m.X10_Multiplier__c = 3.6;
    	m.X8_Multiplier__c = 3.4;
    	m.X6_Multiplier__c = 3.2;
    	m.X4_Multiplier__c = 3;
    	m.X2_Multiplier__c = 2;
    	m.Joker_Multiplier__c = 1;
        m.Base_Rate__c = 1.27;
        m.Effective_Date__c = system.date.today().addDays(-2);
        m.Expiration_Date__c = system.date.today().addDays(30);
        m.Commission_Pay_Point__c = 25;
        m.Name = 'Master';
        m.Include_Protocol__c = True;
        m.Exponent__c = 0.2;
        m.Include_Direct_Deposit__c = True;
        m.Include_Tablet_Subscription_2_pts__c = True;
        m.Include_Inflation_1pt__c = True;
        m.Ace_of_Spades_Multiplier__c = 4;
        m.Inside_Commission_Pay_Point__c = 5;
    	insert m;
        
        insert o;
        test.startTest();
        
        ApexPages.StandardController std = new ApexPages.StandardController(o);
        CommissionChartExtension ext = new CommissionChartExtension(std);
        
        test.stopTest();
    }
    
    public static testmethod void chart7(){
        Trigger_Control_Panel__c cp = new Trigger_Control_Panel__c();
        cp.Name = 'Main';
        cp.Opportunity_Trigger_Enabled__c = true;
        cp.Account_Trigger_Enabled__c = true;
        upsert cp;
        
    	Account a = new Account();
    	a.Name = 'Test Account';
    	a.BillingState = 'TX';
    	insert a;
    
    	Opportunity o = new Opportunity();
        o.Name = 'Test Opp';
    	o.AccountId = a.id;
    	o.CloseDate = system.date.today().addDays(20);
    	o.StageName = 'Prospecting';
    	o.Amount = 100;
        o.Commission__c = 20;
        o.Deck_Rank__c = '6';
        o.Permission_to_Inflate__c = true;
        o.Tablet_Subscription__c = 'Yes';
        o.Menu_to_be_completed_by__c = null;
        o.Menu_Setup_Method__c =  null;
        o.Tablet_Kit_Type__c = null;
    
    	Multiplier__c m = new Multiplier__c();
    	m.Ace_Multiplier__c = 4;
    	m.King_Multiplier__c = 3.9;
    	m.Queen_Multiplier__c = 3.8;
    	m.Jack_Multiplier__c = 3.7;
    	m.X10_Multiplier__c = 3.6;
    	m.X8_Multiplier__c = 3.4;
    	m.X6_Multiplier__c = 3.2;
    	m.X4_Multiplier__c = 3;
    	m.X2_Multiplier__c = 2;
    	m.Joker_Multiplier__c = 1;
        m.Base_Rate__c = 1.27;
        m.Effective_Date__c = system.date.today().addDays(-2);
        m.Expiration_Date__c = system.date.today().addDays(30);
        m.Commission_Pay_Point__c = 25;
        m.Name = 'Master';
        m.Include_Protocol__c = True;
        m.Exponent__c = 0.2;
        m.Include_Direct_Deposit__c = True;
        m.Include_Tablet_Subscription_2_pts__c = True;
        m.Include_Inflation_1pt__c = True;
        m.Ace_of_Spades_Multiplier__c = 4;
        m.Inside_Commission_Pay_Point__c = 5;
    	insert m;
        
        insert o;
        test.startTest();
        
        ApexPages.StandardController std = new ApexPages.StandardController(o);
        CommissionChartExtension ext = new CommissionChartExtension(std);
        
        test.stopTest();
    }
    
    public static testmethod void chart8(){
        Trigger_Control_Panel__c cp = new Trigger_Control_Panel__c();
        cp.Name = 'Main';
        cp.Opportunity_Trigger_Enabled__c = true;
        cp.Account_Trigger_Enabled__c = true;
        upsert cp;
        
    	Account a = new Account();
    	a.Name = 'Test Account';
    	a.BillingState = 'TX';
    	insert a;
    
    	Opportunity o = new Opportunity();
        o.Name = 'Test Opp';
    	o.AccountId = a.id;
    	o.CloseDate = system.date.today().addDays(20);
    	o.StageName = 'Prospecting';
    	o.Amount = 100;
        o.Commission__c = 20;
        o.Deck_Rank__c = '4';
        o.Permission_to_Inflate__c = true;
        o.Tablet_Subscription__c = 'Yes';
        o.Menu_to_be_completed_by__c = null;
        o.Menu_Setup_Method__c =  null;
        o.Tablet_Kit_Type__c = null;
    
    	Multiplier__c m = new Multiplier__c();
    	m.Ace_Multiplier__c = 4;
    	m.King_Multiplier__c = 3.9;
    	m.Queen_Multiplier__c = 3.8;
    	m.Jack_Multiplier__c = 3.7;
    	m.X10_Multiplier__c = 3.6;
    	m.X8_Multiplier__c = 3.4;
    	m.X6_Multiplier__c = 3.2;
    	m.X4_Multiplier__c = 3;
    	m.X2_Multiplier__c = 2;
    	m.Joker_Multiplier__c = 1;
        m.Base_Rate__c = 1.27;
        m.Effective_Date__c = system.date.today().addDays(-2);
        m.Expiration_Date__c = system.date.today().addDays(30);
        m.Commission_Pay_Point__c = 25;
        m.Name = 'Master';
        m.Include_Protocol__c = True;
        m.Exponent__c = 0.2;
        m.Include_Direct_Deposit__c = True;
        m.Include_Tablet_Subscription_2_pts__c = True;
        m.Include_Inflation_1pt__c = True;
        m.Ace_of_Spades_Multiplier__c = 4;
        m.Inside_Commission_Pay_Point__c = 5;
    	insert m;
        
        insert o;
        test.startTest();
        
        ApexPages.StandardController std = new ApexPages.StandardController(o);
        CommissionChartExtension ext = new CommissionChartExtension(std);
        
        test.stopTest();
    }
    
    public static testmethod void chart9(){
        Trigger_Control_Panel__c cp = new Trigger_Control_Panel__c();
        cp.Name = 'Main';
        cp.Opportunity_Trigger_Enabled__c = true;
        cp.Account_Trigger_Enabled__c = true;
        upsert cp;
        
    	Account a = new Account();
    	a.Name = 'Test Account';
    	a.BillingState = 'TX';
    	insert a;
    
    	Opportunity o = new Opportunity();
        o.Name = 'Test Opp';
    	o.AccountId = a.id;
    	o.CloseDate = system.date.today().addDays(20);
    	o.StageName = 'Prospecting';
    	o.Amount = 100;
        o.Commission__c = 20;
        o.Deck_Rank__c = '2';
        o.Permission_to_Inflate__c = true;
        o.Tablet_Subscription__c = 'Yes';
        o.Menu_to_be_completed_by__c = null;
        o.Menu_Setup_Method__c =  null;
        o.Tablet_Kit_Type__c = null;
    
    	Multiplier__c m = new Multiplier__c();
    	m.Ace_Multiplier__c = 4;
    	m.King_Multiplier__c = 3.9;
    	m.Queen_Multiplier__c = 3.8;
    	m.Jack_Multiplier__c = 3.7;
    	m.X10_Multiplier__c = 3.6;
    	m.X8_Multiplier__c = 3.4;
    	m.X6_Multiplier__c = 3.2;
    	m.X4_Multiplier__c = 3;
    	m.X2_Multiplier__c = 2;
    	m.Joker_Multiplier__c = 1;
        m.Base_Rate__c = 1.27;
        m.Effective_Date__c = system.date.today().addDays(-2);
        m.Expiration_Date__c = system.date.today().addDays(30);
        m.Commission_Pay_Point__c = 25;
        m.Name = 'Master';
        m.Include_Protocol__c = True;
        m.Exponent__c = 0.2;
        m.Include_Direct_Deposit__c = True;
        m.Include_Tablet_Subscription_2_pts__c = True;
        m.Include_Inflation_1pt__c = True;
        m.Ace_of_Spades_Multiplier__c = 4;
        m.Inside_Commission_Pay_Point__c = 5;
    	insert m;
        
        insert o;
        test.startTest();
        
        ApexPages.StandardController std = new ApexPages.StandardController(o);
        CommissionChartExtension ext = new CommissionChartExtension(std);
        
        test.stopTest();
    }
    
    public static testmethod void chart10(){
        Trigger_Control_Panel__c cp = new Trigger_Control_Panel__c();
        cp.Name = 'Main';
        cp.Opportunity_Trigger_Enabled__c = true;
        cp.Account_Trigger_Enabled__c = true;
        upsert cp;
        
    	Account a = new Account();
    	a.Name = 'Test Account';
    	a.BillingState = 'TX';
    	insert a;
    
    	Opportunity o = new Opportunity();
        o.Name = 'Test Opp';
    	o.AccountId = a.id;
    	o.CloseDate = system.date.today().addDays(20);
    	o.StageName = 'Prospecting';
    	o.Amount = 100;
        o.Commission__c = 20;
        o.Deck_Rank__c = 'Joker';
        o.Permission_to_Inflate__c = true;
        o.Tablet_Subscription__c = 'Yes';
        o.Menu_to_be_completed_by__c = null;
        o.Menu_Setup_Method__c =  null;
        o.Tablet_Kit_Type__c = null;
    
    	Multiplier__c m = new Multiplier__c();
    	m.Ace_Multiplier__c = 4;
    	m.King_Multiplier__c = 3.9;
    	m.Queen_Multiplier__c = 3.8;
    	m.Jack_Multiplier__c = 3.7;
    	m.X10_Multiplier__c = 3.6;
    	m.X8_Multiplier__c = 3.4;
    	m.X6_Multiplier__c = 3.2;
    	m.X4_Multiplier__c = 3;
    	m.X2_Multiplier__c = 2;
    	m.Joker_Multiplier__c = 1;
        m.Base_Rate__c = 1.27;
        m.Effective_Date__c = system.date.today().addDays(-2);
        m.Expiration_Date__c = system.date.today().addDays(30);
        m.Commission_Pay_Point__c = 25;
        m.Name = 'Master';
        m.Include_Protocol__c = True;
        m.Exponent__c = 0.2;
        m.Include_Direct_Deposit__c = True;
        m.Include_Tablet_Subscription_2_pts__c = True;
        m.Include_Inflation_1pt__c = True;
        m.Ace_of_Spades_Multiplier__c = 4;
        m.Inside_Commission_Pay_Point__c = 5;
    	insert m;
        
        insert o;
        test.startTest();
        
        ApexPages.StandardController std = new ApexPages.StandardController(o);
        CommissionChartExtension ext = new CommissionChartExtension(std);
        
        test.stopTest();
    }
}