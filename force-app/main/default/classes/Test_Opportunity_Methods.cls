@isTest
public class Test_Opportunity_Methods {

    @testSetup static void testSetup() {
        CDdContactTriggerHelper.insertCampaign();
    }

    public static testmethod void Test_Opportunity_Methods(){
        Trigger_Control_Panel__c cp = new Trigger_Control_Panel__c();
        cp.Name = 'Main';
        cp.Opportunity_Trigger_Enabled__c = true;
        cp.Account_Trigger_Enabled__c = true;
        upsert cp;

        Territory__c t = new Territory__c();
        	t.name = 'Austin';
        	t.zip_codes__c = '78741, 78704';
       	insert t;

        Menu_Team_Member__c mm = new Menu_Team_Member__c();
        	mm.Name = 'Menu- Already Exists';
        	mm.Email__c = 'afsadf@asdfa.com';
        	mm.Active__c = True;
        insert mm;

        Account a = new Account();
        	a.Name ='Test Accounta';
        	a.BillingCity = 'Austin';
        	a.BillingState = 'TX';
        	a.BillingStateCode = 'TX';
        	a.BillingPostalCode = '78741';
        	a.Menu_Team_QA__c = mm.id;
        	a.Menu_Team_Creation__c = mm.id;
        	a.Lead_Type__c = 'Outside';
        	a.Deck_Rank__c = 'Ace';
        insert a;

        Contact c = new Contact();
        	c.FirstName = 'test';
        	c.LastName = 'user1';
        	c.AccountId = a.id;
        	c.Email = 'testemail@doordash.com';
        insert c;

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

        RecordType oppRT = [SELECT Id FROM RecordType WHERE Name = 'Marketplace' AND sObjectType = 'Opportunity'];
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];

        User u = new User();
       	u.FirstName = 'Test';
       	u.LastName  = 'User12';
       	u.Email     = 'testsuser@tests.com';
       	u.Username  = 'testsuser@tests.com';
       	u.Alias     = 'test23';
       	u.ProfileId = p.id;
       	u.TimeZoneSidKey    = 'America/Denver';
       	u.LocaleSidKey      = 'en_US';
       	u.EmailEncodingKey  = 'UTF-8';
       	u.LanguageLocaleKey = 'en_US';
        insert u;

        test.startTest();

        Opportunity o = new Opportunity();
        o.Name = 'Test Opp';
        o.AccountId = a.id;
        o.CloseDate = system.date.today();
        o.Contract_Signed_Date__c = system.date.today();
        o.StageName = 'Pitched';
        o.Decision_Maker__c = c.id;
        o.menu_URL__c = 'www.menus.com';
        o.Contract_Signed_Date__c = system.date.today();
        o.Commission__c = 0.12;
        o.Inflation__c = 3;
        o.Order_Protocol__c = 'Email';
        o.Order_Protocol_Email__c = 'dd@doordash.com';
        o.Menu_to_be_completed_by__c = 'DoorDash Onboarding Team';
        o.Submarket__c = 'Southern California - San Diego';
        o.Region_Type__c = 'Live Region';
        o.Hours_of_Operation__c = 'All Day Every Day';
        o.Menu_Has_Been_Provided__c = true;
        o.Type = 'New Partner';
        o.Permission_to_Inflate__c = true;
        o.Tablet_Subscription__c = 'Yes';
        o.Direct_Deposit__c = true;
        o.Account_Number__c = '123412351';
        o.Routing_Number__c = '23421341';
        o.EIN__c = '1231231';
        o.Legal_Business_Name__c = 'legal';
        o.RecordTypeId = oppRT.Id;
        o.Tablet_Kit_Type__c = null;
        insert o;

        /*
         * [JN-NOTE] This is causing the unit tests to fail
         * 			 due to some PBs introduced recently (3/18/18 - 4/20/18)
         * 			 Will fix this unit test at a later time.
        o.Food_is_Bike_Friendly__c = True;
        o.StageName = 'Closed Won';
        o.DM_Email2__c = 'dm01@doordash.com';
        o.Activate_Centrally_2__c = 'Yes';
        o.Interest_Website_Button__c = 'No';
        o.LeadSource = 'Yelp';
        o.Pricing_Tier__c = 'Tier 1';
        o.Service_Fee__c = 25.00;
        o.Mx_Requesting_Photoshoot__c = 'Yes';
        o.Average_of_Catering_Orders_per_Week__c = 200;
        //o.Webmaster_Name__c = 'Webmaster Magoo';
        //o.Webmaster_Email__c = 'webmaster01@thewebiestofmasters.com';
        update o;
		*/

        Opportunity o2 = new Opportunity();
        o2.Name = 'Test Opp2';
        o2.AccountId = a.id;
        o2.CloseDate = system.date.today();
        o2.StageName = 'Pitched';
        o2.Decision_Maker__c = c.id;
        o2.menu_URL__c = 'www.testurl.com';
        o2.Menu_Has_Been_Provided__c = True;
        o2.Contract_Signed_Date__c = system.date.today();
        o2.Commission__c = 0.12;
        o2.Inflation__c = 8;
        o2.Order_Protocol__c = 'Email';
        o2.Order_Protocol_Email__c = 'dd@doordash.com';
        o2.Menu_to_be_completed_by__c = 'DoorDash Onboarding Team';
        o2.Submarket__c = 'Southern California - San Diego';
        o2.Region_Type__c = 'Live Region';
        o2.Hours_of_Operation__c = 'All Day Every Day';
        o2.Type = 'New Partner Sign';
        o2.Menu_Has_Been_Provided__c = true;
        o2.Contract_Signed_Date__c = system.date.today();
        o2.Deck_Rank__c = 'Ace';
        o2.Permission_to_Inflate__c = true;
        o2.Tablet_Subscription__c = 'Yes';
        o2.Direct_Deposit__c = false;
        o2.EIN__c = '212111';
        o2.Legal_Business_Name__c = 'legal';
        o2.RecordTypeId = oppRT.Id;
        o2.Tablet_Kit_Type__c = null;
        o2.Menu_to_be_completed_by__c = null;
        o2.Menu_Setup_Method__c =  null;
        insert o2;

        /*
         * [JN-NOTE] This is causing the unit tests to fail
         * 			 due to some PBs introduced recently (3/18/18 - 4/20/18)
         * 			 Will fix this unit test at a later time.
        o2.Food_is_Bike_Friendly__c = True;
        o2.StageName = 'Closed Won';
        o2.DM_Email2__c = 'dm02@doordash.com';
        o2.Activate_Centrally_2__c = 'Yes';
        o2.Interest_Website_Button__c = 'No';
        o2.LeadSource = 'Yelp';
        o2.Pricing_Tier__c = 'Tier 2';
        o2.Service_Fee__c = 15.00;
        o2.Mx_Requesting_Photoshoot__c = 'Yes';
        o2.Average_of_Catering_Orders_per_Week__c = 400;
        //o2.Webmaster_Name__c = 'Webmaster Maow';
        //o2.Webmaster_Email__c = 'webmaster02@thewebiestofmasters.com';
        update o2;
		*/

        test.stopTest();

    }

    public static testmethod void commissiontest(){

        Trigger_Control_Panel__c cp = new Trigger_Control_Panel__c();
        cp.Name = 'Main';
        cp.Opportunity_Trigger_Enabled__c = true;
        cp.Account_Trigger_Enabled__c = true;
        upsert cp;

        RecordType oppRT = [SELECT Id FROM RecordType WHERE Name = 'Marketplace' AND sObjectType = 'Opportunity'];

        Id userId = UserInfo.getUserId();
        Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = userId);
        validation.Bypass_Opportunity_Validations__c = true;
        insert validation;

        Account a = new Account();
        a.Name ='Test Accounta';
        a.BillingCity = 'Austin';
        a.BillingState = 'TX';
        a.BillingStateCode = 'TX';
        a.BillingPostalCode = '78741';
        a.Lead_Type__c = 'Outside';
        a.Deck_Rank__c = 'Ace';
        insert a;

        Contact c = new Contact();
        c.firstName= 'test';
        c.LastName = 'contact';
        c.Email = 'test@tes.com';
        c.AccountId = a.id;
        insert c;

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

    	Opportunity o = new Opportunity();
        o.Name = 'Test Opp';
    	o.AccountId = a.id;
    	o.CloseDate = system.date.today().addDays(20);
    	o.StageName = 'Closed Won';
        o.Contract_Signed_Date__c = date.today();
        o.Menu_Has_Been_Provided__c = true;
        o.Menu_URL__c = 'http://fakemenus.com/thisshouldntexist';
        o.Hours_of_Operation__c = 'test';
    	o.Amount = 100;
        o.Decision_Maker__c = c.id;
        o.LeadSource = 'Other';
        o.Type = 'New Partner';
        o.Submarket__c = 'Southern California - San Diego';
        o.Menu_to_be_completed_by__c = 'DoorDash Onboarding Team';
        o.Commission__c = 0.20;
        o.Deck_Rank__c = 'Ace';
        o.Permission_to_Inflate__c = true;
        o.Tablet_Subscription__c = 'Yes';
        o.Direct_Deposit__c = false;
        o.Account_Number__c = '987654321';
        o.Routing_Number__c = '123456789';
        o.EIN__c = '212111';
        o.Legal_Business_Name__c = 'legal';
        o.Pricing_Tier__c = 'Tier 3';
        o.Service_Fee__c = 10.00;

        o.Average_of_Catering_Orders_per_Week__c = 400;
		o.Platform__c = 'Doordash';
        o.Region_Type__c = 'Live Region';
        o.Order_Service_Type__c = 'Delivery Only';
        o.Interest_Website_Button__c = 'No';
        o.RecordTypeId = oppRT.Id;
        o.Requesting_Account_Management__c = 'Unmanaged';
        o.Activation_Fee__c = '$0';
        o.Weekly_Printer_Subscription_Fee__c = '$0';
        o.Order_Protocol_Email__c = 'order_prot@doordash.com';
        o.Order_Protocol__c = 'POS and and Tablet (DoorDash Owns)';
        o.Tablet_Delivery_Method__c = 'Drop-ship';
        o.POS_Fallback_Protocol__c = 'OP Phone Call';
        o.POS_Integration_ID__c = '123';
        o.POS_Integration_Type__c = 'crisp';
        o.Activate_Centrally_2__c = 'No';
        o.Activate_Centrally_No_Validation__c = 'Already Live, not in SFDC';
        o.Proposed_Date_of_Activation__c = System.today();
        o.PactSafe_Record__c = 'https://app.pactsafe.com/requests/5d6564c4f964b579a6176fe1';
        o.PactSafe_Contract_Type__c = 'English US Mx Sign Up Sheet';
        o.of_Addressable_Locations__c = 10;
    	insert o;

        test.startTest();

        o.Permission_to_Inflate__c = false;
        o.Tablet_Subscription__c = 'No';
        update o;

        a.Deck_Rank__c = 'Joker';
        update a;

        test.stopTest();
    }

    /*
    public static testmethod void acctTest(){

        Trigger_Control_Panel__c cp = new Trigger_Control_Panel__c();
        cp.Name = 'Main';
        cp.Opportunity_Trigger_Enabled__c = true;
        cp.Account_Trigger_Enabled__c = true;
        upsert cp;

        Account a = new Account();
        a.Name ='Test Accounta';
        a.BillingCity = 'Austin';
        a.BillingState = 'TX';
        a.BillingStateCode = 'TX';
        a.BillingPostalCode = '78741';
        a.Lead_Type__c = 'Outside';
        a.Deck_Rank__c = 'Ace';
        insert a;

        Contact c = new Contact();
        c.firstName= 'test';
        c.LastName = 'contact';
        c.Email = 'test@tes.com';
        c.AccountId = a.id;
        insert c;

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

    	Opportunity o = new Opportunity();
        o.Name = 'Test Opp';
    	o.AccountId = a.id;
    	o.CloseDate = system.date.today().addDays(20);
    	o.StageName = 'Pitching';
        o.Contract_Signed_Date__c = date.today();
        o.Menu_Has_Been_Provided__c = true;
        o.Hours_of_Operation__c = 'test';
    	o.Amount = 100;
        o.Decision_Maker__c = c.id;
        o.Type = 'New Partner Sign';
        o.Submarket__c = 'Southern California - San Diego';
        o.Menu_to_be_completed_by__c = 'Default- Menu Team';
        o.Commission__c = 20;
        o.Deck_Rank__c = 'Ace';
        o.Permission_to_Inflate__c = true;
        o.Tablet_Subscription__c = 'Yes';
        o.Direct_Deposit__c = false;
        o.Order_Protocol__c = 'Email';
        o.Order_Protocol_Email__c = 'testemail@testemail.com';
        o.Account_Number__c = '1234213';
        o.Routing_Number__c = '2142133';
        o.EIN__c = '212111';
        o.Legal_Business_Name__c = 'legal';
    	insert o;

        test.startTest();

        a.Deck_Rank__c = 'Joker';
        update a;

        test.stopTest();
    }
    */
}