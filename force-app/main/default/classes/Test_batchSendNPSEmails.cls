/*
 * 		Name:		Test_batchSendNPSEmails
 * 		Date:		3/2016
 * 		Author:		Cole Conroy - RoyCon Technologies
 * 		Desc:		Test class for batch_SendNPSEmails
 * 
 * 
 */

@isTest
public class Test_batchSendNPSEmails {
    
    @testSetup static void testSetup() {
        CDdContactTriggerHelper.insertCampaign();
    }
    
    public static testmethod void tests(){
        Trigger_Control_Panel__c cp = new Trigger_Control_Panel__c();
        cp.Name = 'Main';
        cp.Opportunity_Trigger_Enabled__c = true;
        cp.Account_Trigger_Enabled__c = true;
        upsert cp;
        
        NPS_Emails__c nps = new NPS_Emails__c();
        nps.Name = 'Master';
        nps.Send_NPS_Emails__c = true;
        nps.Email_Frequency__c = 90;
        upsert nps;
        
        Account a = new Account();
        a.Name = 'Test Company 2';
        a.BillingPostalCode = '12345';
        a.BillingState = 'TX';
        a.BillingStateCode = 'TX';
        a.Account_Status__c = 'Active';
        a.Deck_Rank__c = 'Ace';
        a.Receive_NPS_Email__c = true;
        a.Last_NPS_Email_Sent__c = system.date.today().addDays(-90);
        insert a;
        
        Account a2 = new Account();
        a2.Name = 'Test Company';
        a2.BillingPostalCode = '12345';
        a2.BillingState = 'TX';
        a2.BillingStateCode = 'TX';
        a2.Account_Status__c = 'Active (non-preferred)';
        a2.Deck_Rank__c = 'Ace';
        a2.Receive_NPS_Email__c = true;
        a2.Last_NPS_Email_Sent__c = system.date.today().addDays(-90);
        insert a2;
        
        Contact c = new Contact();
        c.FirstName = 'Test';
        c.LastName = 'Contact';
        c.Email = 'test@testemail.com';
        c.AccountId = a2.id;
        insert c;
        
        Contact c2 = new Contact();
        c2.FirstName = 'Test';
        c2.LastName = 'Contact2';
        c2.Email = 'test2@testemail.com';
        c2.AccountId = a2.id;
        insert c2;
        
        a.Decision_Maker__c = c.id;
        update a;
        
        a2.General_Manager__c = c.id;
        a2.Decision_Maker__c = c2.id;
        update a2;
        
        test.startTest();
        
        batch_SendNPSEmails batch = new batch_SendNPSEmails();
        database.executeBatch(batch);
        
        test.stopTest();
        
    }

}