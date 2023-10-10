/**
 * @description       : Test class for CDdCaseMilestonePOSIntegrations class
 * @author            : @lathika
 * @group             : Milestone
 * @last modified on  : 12-12-2021
**/
@isTest
public class CDdCaseMilestonePOSIntegrationsTest { 
    public static final Id CASE_POS_INTEGRATIONS_RECORD_TYPE_ID = CDdSchemaUtils.CASE_RT.posIntegrationsId();
    public static final Integer NUMBER_OF_POS_MILESTONES = 5;

    @testSetup
    static void testSetup() {
        System.runAs(CDdCaseMilestoneTest.getTestRunUser()) {
            Test.startTest();
            CDdCaseMilestoneTest.initializeTestSettings();

            TDdOpportunityLineItemFactory.createProducts();

            List<Account> accs = TDdAccountFactory.createAccounts('POSIntegrationsParentAcc0', 1, 'Marketplace');
            accs[0].Restaurant_Id__c = '98765';

            insert new List<Account>{accs[0]};

            List<Account> childAccs = TDdAccountFactory.createAccounts('POSIntegrationsChildAcc0', 1, 'Marketplace');
            childAccs[0].Restaurant_Id__c = '56789';  
            childAccs[0].ParentId = accs[0].Id;  
            insert childAccs;

            List<Contact> cons = new List<Contact>{
                TDdAccountFactory.createContacts(1, childAccs[0].Id)[0]
            };  
            cons[0].firstName = 'POSIntegrationsCase';
            cons[0].LastName = 'POSIntegrationsCaselname'; 
            cons[0].Email = 'posintegrations.POSCaselname@dd.com';

            insert cons;            

            List<Opportunity> opps = new List<Opportunity>{
                TDdOpportunityFactory.createOpportunityByDevRT('POSIntegrationsCaseOpp0', childAccs[0].Id, cons[0].Id, 'New', 'ML_Inside_Sales')
            };

            opps[0].Menu_to_be_completed_by__c = 'Account Owner';
            opps[0].Order_Protocol__c = 'Email';
            opps[0].Mx_Requested_Custom_Radius_Demand_Gen__c = 'No';
            opps[0].Activate_Centrally_2__c = 'No';
            opps[0].StageName = 'Closed Won';
            insert opps;
            CDdMilestoneTemplate.insertMilestoneTemplates();   
            Test.stopTest();
        }
    }

    @isTest 
    static void testPOSIntegrationCase(){
        CDdCaseMilestonePOSIntegrations cdDCaseMilestonePOS = new CDdCaseMilestonePOSIntegrations();
        cdDCaseMilestonePOS.getClassName();
        list<Account> listAccounts = [Select Id from Account];
        list<Opportunity> listOpportunity = [Select Id from Opportunity];
        Test.startTest();
        Case c = new Case(AccountId = listAccounts[0].Id, 
                          Opportunity_name__c = listOpportunity[0].Id,
                          Origin = 'Closed Won Opportunity',
                          Stage__c = 'Not Started',Activation_Method__c = 'Test order',POS_Integration_Type__c ='square',
                          recordTypeId = CASE_POS_INTEGRATIONS_RECORD_TYPE_ID);
        insert c ; 
        Test.stopTest();  
        List<Milestone__c> milestones = [Select Id from Milestone__c where Case__c = :c.Id];
        System.assertEquals(NUMBER_OF_POS_MILESTONES, milestones.size());
    }

    @isTest 
    static void testPOSIntegrationCaseBulkAndPOSIntegrationTypeSquare(){
        list<Account> listAccounts = [Select Id from Account];
        list<Opportunity> listOpportunity = [Select Id from Opportunity];
        Test.startTest();
        Case c = new Case(AccountId = listAccounts[0].Id, 
                          Opportunity_name__c = listOpportunity[0].Id,
                          Origin = 'Provider Requested - Data Loader',
                          Stage__c = 'Not Started',Activation_Method__c = 'Light Up',POS_Integration_Type__c ='square',
                          recordTypeId = CASE_POS_INTEGRATIONS_RECORD_TYPE_ID);
        insert c ; 
        Test.stopTest();  
        List<Milestone__c> milestones = [Select Id from Milestone__c where Case__c = :c.Id];
        System.assertEquals(NUMBER_OF_POS_MILESTONES, milestones.size());
    }

    @isTest 
    static void testPOSIntegrationCaseBulkAndPOSIntegrationTypeNOTSquare(){
        list<Account> listAccounts = [Select Id from Account];
        list<Opportunity> listOpportunity = [Select Id from Opportunity];
        Test.startTest();
        Case c = new Case(AccountId = listAccounts[0].Id, 
                          Opportunity_name__c = listOpportunity[0].Id,
                          Origin = 'Provider Requested - Data Loader',
                          Stage__c = 'Not Started',Activation_Method__c = 'Light Up',POS_Integration_Type__c ='square',
                          recordTypeId = CASE_POS_INTEGRATIONS_RECORD_TYPE_ID);
        insert c ; 
        Test.stopTest();  
        List<Milestone__c> milestones = [Select Id from Milestone__c where Case__c = :c.Id];
        System.assertEquals(NUMBER_OF_POS_MILESTONES, milestones.size());
    }
}