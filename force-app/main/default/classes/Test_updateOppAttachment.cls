@isTest
public class Test_updateOppAttachment {
	@testSetup static void testSetup() {
        CDdContactTriggerHelper.insertCampaign();
    }
    public static testMethod void Test_updateOppAttachment(){
        Trigger_Control_Panel__c cp = new Trigger_Control_Panel__c();
        cp.Name = 'MAin';
        cp.Opportunity_Trigger_Enabled__c = true;
        cp.Account_Trigger_Enabled__c = true;
        upsert cp;
        
        Territory__c t = new Territory__c();
        	t.name = 'Austin';
        	t.zip_codes__c = '78741, 78704';
       	insert t;
        
        Account a = new Account();
        	a.Name ='Test Accounta';
        	a.BillingCity = 'Austin';
        	a.BillingState = 'TX';
        	a.BillingStateCode = 'TX';
        	a.BillingPostalCode = '78741';
        insert a;
        
        Contact c = new Contact();
        	c.FirstName = 'test';
        	c.LastName = 'user1';
        	c.AccountId = a.id;
        	c.Email = 'testemail@doordash.com';
        insert c;
        
        Opportunity o = new Opportunity();
        	o.Name = 'Test Opp';
        	o.AccountId = a.id;
        	o.CloseDate = system.date.today();
        	o.StageName = 'Pitched';
        	o.Decision_Maker__c = c.id;
        	o.Lead_Source_Detail__c = 'Formstack';
					o.Menu_to_be_completed_by__c = null;
					o.Menu_Setup_Method__c =  null;
					o.Tablet_Kit_Type__c = null;
        insert o;
        
        test.startTest();
        
        Attachment att = new Attachment();
        	att.Name = 'Menu';
        	att.ParentId = o.id;
        	att.Body = blob.valueOf('b');
        insert att;
        
        test.stopTest();
    }
}