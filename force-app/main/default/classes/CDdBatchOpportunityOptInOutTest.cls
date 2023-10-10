/**
 * Created by Jeremy S. Johnson (Perficient, Inc)
 *
 * Implements BZAP-7091: Scheduled Batch job for opted-in franchise opps (Closed Won)
 * Implements BZAP-7214: Scheduled Batch job for opted-out franchise opps (Closed Lost)
 */
@IsTest
public with sharing class CDdBatchOpportunityOptInOutTest {

    @IsTest
    public static void testBatchable() {
        Id franchiseRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Franchise_Opportunity').getRecordTypeId();

        Account account = TDdAccountFactory.createAccounts('Test', 1, 'Enterprise Marketplace')[0];
        insert account;

        List<Opportunity> opps = new List<Opportunity>();

        Opportunity optInHit = new Opportunity(Name='OptInHit', AccountId=account.Id);
        optInHit.StageName = 'Out for Signature';
        optInHit.CloseDate = System.today();
        optInHit.RecordTypeId = franchiseRecTypeId;
        optInHit.Docusign_Sent__c = Date.today().addDays(-(Integer.valueOf(Label.DdOpportunityOptInDays) + 1));
        optInHit.PactSafe_Contract_Type__c = 'Franchisee Opt-Out Addendum';
        optInHit.Menu_to_be_completed_by__c = null;
        optInHit.Menu_Setup_Method__c =  null;
        optInHit.Tablet_Kit_Type__c = null;
        opps.add(optInHit);

        Opportunity optInMiss = new Opportunity(Name='OptInMiss', AccountId=account.Id);
        optInMiss.StageName = 'Out for Signature';
        optInMiss.CloseDate = System.today();
        optInMiss.RecordTypeId = franchiseRecTypeId;
        optInMiss.Docusign_Sent__c = Date.today().addDays(-(Integer.valueOf(Label.DdOpportunityOptInDays)));
        optInMiss.PactSafe_Contract_Type__c = 'Franchisee Opt-Out Addendum';
        optInMiss.Menu_to_be_completed_by__c = null;
        optInMiss.Menu_Setup_Method__c =  null;
        optInMiss.Tablet_Kit_Type__c = null;
        opps.add(optInMiss);

        Opportunity optOutHit = new Opportunity(Name='OptOutHit', AccountId=account.Id);
        optOutHit.StageName = 'Opt-Out Review';
        optOutHit.CloseDate = System.today();
        optOutHit.RecordTypeId = franchiseRecTypeId;
        optOutHit.Docusign_Sent__c = Date.today().addDays(-(Integer.valueOf(Label.DdOpportunityOptOutDays) + 1));
        optOutHit.PactSafe_Contract_Type__c = 'Franchisee Opt-Out Addendum';
        optOutHit.Menu_to_be_completed_by__c = null;
        optOutHit.Menu_Setup_Method__c =  null;
        optOutHit.Tablet_Kit_Type__c = null;
        opps.add(optOutHit);

        Opportunity optOutMiss = new Opportunity(Name='OptOutMiss', AccountId=account.Id);
        optOutMiss.StageName = 'Opt-Out Review';
        optOutMiss.CloseDate = System.today();
        optOutMiss.RecordTypeId = franchiseRecTypeId;
        optOutMiss.Docusign_Sent__c = Date.today().addDays(-(Integer.valueOf(Label.DdOpportunityOptOutDays)));
        optOutMiss.PactSafe_Contract_Type__c = 'Franchisee Opt-Out Addendum';
        optOutMiss.Menu_to_be_completed_by__c = null;
        optOutMiss.Menu_Setup_Method__c =  null;
        optOutMiss.Tablet_Kit_Type__c = null;
        opps.add(optOutMiss);

        insert opps;

        //For some reason, setting Docusign_Sent__c reverts 'Opt-Out Review' to 'Out for Signature' after insert.
        List<Opportunity> oppsUpdate = [select Id, StageName, Docusign_Sent__c, Name from Opportunity where Name = 'OptOutHit' or Name = 'OptOutMiss'];
        for(Opportunity opp : oppsUpdate) {
            opp.StageName = 'Opt-Out Review';
        }
        update oppsUpdate;


        Test.startTest();
        CDdBatchOpportunityOptInOut oio = new CDdBatchOpportunityOptInOut();
        oio.execute(null);
        Test.stopTest();

        List<Opportunity> actuals = [select Id, Name, StageName, Lost_Reason__c from Opportunity];

        for(Opportunity opp : actuals) {
            switch on opp.Name {
                when 'OptInHit' {
                    System.assertEquals('Closed Won', opp.StageName, 'Unexpected stage');
                }
                when  'OptInMiss' {
                    System.assertEquals('Out for Signature', opp.StageName, 'Unexpected stage');
                }
                when 'OptOutHit' {
                    System.assertEquals('Closed Lost', opp.StageName, 'Unexpected stage');
                    System.assertEquals('Franchisee Opt-Out', opp.Lost_Reason__c, 'Unexpected lost reason');
                }
                when  'OptOutMiss' {
                    System.assertEquals('Opt-Out Review', opp.StageName, 'Unexpected stage');
                }
            }
        }
    }
}