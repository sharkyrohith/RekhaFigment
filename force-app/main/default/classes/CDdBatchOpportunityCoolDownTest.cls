/* 
 * @author: Jeegar
 * @date : 2019-05
 * @description: Test Class for CDdBatchOpportunityCoolDown. Tests failure, success and CDdScheduleOpportunityCoolDown class
 */

@isTest
public with sharing class CDdBatchOpportunityCoolDownTest {

    @isTest static void testFailureBatch() {
        List<Opportunity> opptys;
        Opportunity oppty; 
        List<Account> accts;
        Account acct;
        List<Lead> leads;
        Opportunity_Inversion_Settings__c settings = TDdOpportunityFactory.setCustomSettings();

        accts = TDdAccountFactory.createAccounts('TestAccount', 1); 
        acct = accts[0];
        acct.BillingPostalCode = '95689';
        insert acct; 

        opptys = TDdAccountFactory.createOpportunities(1, accts[0].Id);
        oppty = opptys[0];
        oppty.StageName = 'Closed Lost';
        oppty.Lost_Reason__c = 'Not interested in 3rd party delivery';
        oppty.Lost_Reason_Detail__c = 'Don’t believe in delivery';
        oppty.Cool_Down_Period__c = '30 Days';
        oppty.recordtypeid = '0121a000000QpnMAAS';
        oppty.CloseDate = System.Today();
        oppty.Lead_Source_Detail__c = 'Formstack';
        oppty.Menu_to_be_completed_by__c = null;
        oppty.Menu_Setup_Method__c =  null;
        oppty.Tablet_Kit_Type__c = null;

        insert oppty; 

        oppty.Opportunity_Inversion_date__c = System.Today(); 
        update oppty; 
        
        Test.startTest(); 

        CDdBatchOpportunityCoolDown batch = new CDdBatchOpportunityCoolDown(); 
        Database.executeBatch(batch);
        
        Test.stopTest(); 
        
        leads = [Select id, firstName from Lead where account__c =: acct.id];
        System.assertEquals(0, leads.size());
        
    }
        

    @isTest static void testSuccessBatch(){
        List<Opportunity> opptys;
        Opportunity oppty; 
        Contact con; 
        List<Account> accts;
        Account acct;
        List<Lead> leads;
        Lead currLead;
        Opportunity_Inversion_Settings__c settings = TDdOpportunityFactory.setCustomSettings();
        
        accts = TDdAccountFactory.createAccounts('TestAccount', 1); 
        acct = accts[0];
        acct.BillingPostalCode = '95689';
        insert acct; 

        List<Contact> contacts = TDdAccountFactory.createContacts(1, accts[0].id);
        con = contacts[0];
        con.Phone = TDdAccountFactory.getRandom();
        insert con;
        
        Lead ltest = TDdLeadFactory.createLeads('test', 1, true)[0];
        
        opptys = TDdAccountFactory.createOpportunities(1, accts[0].Id);
        oppty = opptys[0];
        oppty.StageName = 'Closed Lost';
        oppty.Lost_Reason__c = 'Not interested in 3rd party delivery';
        oppty.Lost_Reason_Detail__c = 'Don’t believe in delivery';
        oppty.Cool_Down_Period__c = '30 Days';
        oppty.recordtypeid = '0121a000000QpnMAAS';
        oppty.Decision_Maker__c = con.id; 
        oppty.CloseDate = System.Today();
        oppty.Converted_Lead_ID__c  = ltest.Id;
        oppty.Menu_to_be_completed_by__c = null;
        oppty.Menu_Setup_Method__c =  null;
        oppty.Tablet_Kit_Type__c = null;

        insert oppty; 
        oppty.Opportunity_Inversion_date__c = System.Today(); 
        update oppty; 

        Test.startTest(); 

        CDdBatchOpportunityCoolDown batch = new CDdBatchOpportunityCoolDown(); 
        Database.executeBatch(batch);

        Test.stopTest(); 

        leads = [Select id, firstName, LastName, Email, Status, Reopened_Lead__c, Lead_Reopen_Date__c, Account__c 
                 from Lead 
                 WHERE Opportunity__c =: oppty.id];
        System.assertEquals(1, leads.size());
        currLead = leads[0];
        System.assertEquals(Oppty.Accountid, currLead.Account__c);
        System.assertEquals(true, currLead.Reopened_Lead__c);
        System.assertEquals(System.today(), currLead.Lead_Reopen_Date__c);
        
    }

    @isTest static void testScheduleBatch() {
        Test.startTest();
        Datetime dt = Datetime.now().addMinutes(1);
        String CRON_EXP = '0 '+ dt.minute() + ' * ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year();
        String jobId = System.schedule('ScheduleCoolDown', CRON_EXP, new CDdScheduleOpportunityCoolDown() );   
        Test.stopTest();
    }
}