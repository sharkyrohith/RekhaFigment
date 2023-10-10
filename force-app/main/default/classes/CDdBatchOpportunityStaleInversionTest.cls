/* 
 * @author: Jeegar
 * @date : 2019-05
 * @description: Test Class for CDdBatchOpportunityCoolDown. Tests failure, success and CDdScheduleOpportunityCoolDown class
 */

@isTest
public with sharing class  CDdBatchOpportunityStaleInversionTest {
    
    @isTest static void testNoLeadCreation(){
        List<Opportunity> opptys;
        Opportunity oppty; 
        Contact con; 
        List<Account> accts;
        Account acct;
        List<Lead> leads;
        Opportunity_Inversion_Settings__c settings = TDdOpportunityFactory.setCustomSettings(); 
        
        accts = TDdAccountFactory.createAccounts('TestAccount', 1); 
        acct = accts[0];
        acct.BillingPostalCode = '95689';
        insert acct; 
        
        Lead ltest = TDdLeadFactory.createLeads('test', 1, true)[0];
        
        opptys = TDdAccountFactory.createOpportunities(1, accts[0].Id);
        oppty = opptys[0];
        oppty.StageName = 'Seeking Meeting';
        oppty.recordtypeid = CDdBatchOpportunityStaleInversion.OPP_MARKETPLACE_RT_ID;
        oppty.CloseDate = System.Today();
        oppty.Converted_Lead_ID__c  = ltest.Id;
        oppty.Menu_to_be_completed_by__c = null;
        oppty.Menu_Setup_Method__c =  null;
        oppty.Tablet_Kit_Type__c = null;
        insert oppty; 

        
        Test.startTest(); 

        CDdBatchOpportunityStaleInversion batch = new CDdBatchOpportunityStaleInversion(); 
        Database.executeBatch(batch);
        
        Test.stopTest(); 
        
        leads = [Select id, firstName from Lead where account__c =: acct.id];
        opptys = [Select id, StageName, Lost_Reason__c, Lost_Reason_Detail__c from Opportunity where id =: oppty.id];

        System.assertEquals(0, leads.size());
        System.assertEquals('Closed Lost', opptys[0].StageName);
        System.assertEquals('Lack of Activity', opptys[0].Lost_Reason__c);
        System.assertEquals('Auto Closed', opptys[0].Lost_Reason_Detail__c);

    }

    @isTest static void testExcludedStaleOpportunityRemainsOpen(){
        List<Opportunity> opps;
        Account acct;
        
        acct = TDdAccountFactory.createAccounts('TestAccount', 1)[0];
        acct.BillingPostalCode = '95689';
        insert acct; 
        
        opps = new List<Opportunity>{
            new Opportunity(
                Name = 'Stale Opp - Out for Sig', 
                AccountId = acct.Id,
                StageName = 'Out for Signature',
                CloseDate = System.Today().addDays(1),
                RecordTypeId = CDdBatchOpportunityStaleInversion.OPP_MARKETPLACE_RT_ID,
                Menu_to_be_completed_by__c = null,
                Menu_Setup_Method__c =  null,
                Tablet_Kit_Type__c = null
            ),
            new Opportunity(
                Name = 'Stale Opp - Contract Signed', 
                AccountId = acct.Id,
                StageName = 'Contract Signed',
                CloseDate = System.Today().addDays(1),
                RecordTypeId = CDdBatchOpportunityStaleInversion.OPP_MARKETPLACE_RT_ID,
                Menu_to_be_completed_by__c = null,
                Menu_Setup_Method__c =  null,
                Tablet_Kit_Type__c = null
            )
        };
        insert opps; 
        
        Test.startTest(); 
        Database.executeBatch(new CDdBatchOpportunityStaleInversion());
        Test.stopTest(); 

        Map<Id, Opportunity> queriedOpps = new Map<Id, Opportunity>(
                [SELECT Id, StageName, Lost_Reason__c FROM Opportunity WHERE Id IN :opps]);
        System.assertEquals(true, [Select id, firstName from Lead where account__c =: acct.id].isEmpty());
        System.assertNotEquals('Closed Lost', queriedOpps.get(opps[0].Id).StageName);
        System.assertNotEquals('Closed Lost', queriedOpps.get(opps[1].Id).StageName);                               
    }
    
    @isTest static void testLeadCreation(){
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
        oppty.StageName = 'Seeking Meeting';
        oppty.recordtypeid = CDdBatchOpportunityStaleInversion.OPP_MARKETPLACE_RT_ID;
        oppty.Decision_Maker__c = con.id; 
        oppty.CloseDate = System.Today();
        oppty.Converted_Lead_ID__c  = ltest.Id;
        oppty.Menu_to_be_completed_by__c = null;
        oppty.Menu_Setup_Method__c =  null;
        oppty.Tablet_Kit_Type__c = null;

        insert oppty; 
        
        Test.startTest(); 

        CDdBatchOpportunityStaleInversion batch = new CDdBatchOpportunityStaleInversion(); 
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
        opptys = [SELECT id, StageName, Lost_Reason__c, Lost_Reason_Detail__c, Reopened_Lead_Created__c, Reopened_Lead_Created_ID_18__c 
                    FROM Opportunity 
                    WHERE id =: oppty.id];

        System.assertEquals(1, leads.size());
        System.assertEquals('Closed Lost', opptys[0].StageName);
        System.assertEquals('Lack of Activity', opptys[0].Lost_Reason__c);
        System.assertEquals('Auto Closed', opptys[0].Lost_Reason_Detail__c);
        System.assertEquals(True, opptys[0].Reopened_Lead_Created__c);
        System.assertEquals(String.valueOf(currLead.id), opptys[0].Reopened_Lead_Created_ID_18__c);

    }
    @isTest static void testLeadCreationWithoutDM(){
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
        oppty.StageName = 'Seeking Meeting';
        oppty.recordtypeid = CDdBatchOpportunityStaleInversion.OPP_MARKETPLACE_RT_ID;
        oppty.CloseDate = System.Today();
        oppty.Converted_Lead_ID__c  = ltest.Id;
        oppty.Menu_to_be_completed_by__c = null;
        oppty.Menu_Setup_Method__c =  null;
        oppty.Tablet_Kit_Type__c = null;

        insert oppty; 
        
        Test.startTest(); 

        CDdBatchOpportunityStaleInversion batch = new CDdBatchOpportunityStaleInversion(); 
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
        opptys = [Select id, StageName, Lost_Reason__c, Lost_Reason_Detail__c from Opportunity where id =: oppty.id];

        System.assertEquals(1, leads.size());
        System.assertEquals('Closed Lost', opptys[0].StageName);
        System.assertEquals('Lack of Activity', opptys[0].Lost_Reason__c);
        System.assertEquals('Auto Closed', opptys[0].Lost_Reason_Detail__c);

    }
    @isTest static void testScheduleBatch() {
        Test.startTest();
        Datetime dt = Datetime.now().addMinutes(1);
        String CRON_EXP = '0 '+ dt.minute() + ' * ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year();
        String jobId = System.schedule('ScheduleStaleInversion', CRON_EXP, new CDdScheduleOpportunityStaleInversion() );   
        Test.stopTest();
    }
}