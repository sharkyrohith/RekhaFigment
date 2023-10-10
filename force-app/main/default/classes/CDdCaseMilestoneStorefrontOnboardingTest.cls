/**
 * @description       : Test class for CDdCaseMilestoneStorefrontOnboarding class
 * @author            : @ebby
 * @group             : Milestone
 * @last modified on  : 11-08-2021
**/
@isTest
public class CDdCaseMilestoneStorefrontOnboardingTest {
    
    public static final Id CASE_STOREFRONT_ONBOARDING_RECORD_TYPE_ID = CDdSchemaUtils.CASE_RT.storefrontOnboardingId();

    private static final Set<String> ALL_MILESTONES {get {
        if(ALL_MILESTONES == null) {
            ALL_MILESTONES = new Set<String>{
                CDdCaseMilestoneStorefrontOnboarding.REVIEW_TRIAGE,
                CDdCaseMilestoneStorefrontOnboarding.SETUP_STORE_PRICING,
                CDdCaseMilestoneStorefrontOnboarding.SETUP_STOREFRONT_PAGE,
                CDdCaseMilestoneStorefrontOnboarding.IMPLEMENTATION_CALL,
                CDdCaseMilestoneStorefrontOnboarding.LINK_IMPLEMENTATION,
                CDdCaseMilestoneStorefrontOnboarding.LINK_OPTIMIZATION
            };
        }

        return ALL_MILESTONES;
    } set;}

    @testSetup
    static void testSetup() {
        System.runAs(CDdCaseMilestoneTest.getTestRunUser()) {
            Test.startTest();
            CDdCaseMilestoneTest.initializeTestSettings();

            TDdOpportunityLineItemFactory.createProducts();

            List<Account> accs = TDdAccountFactory.createAccounts('StoreFrontCaseParentAcc0', 1, 'Marketplace');
            accs[0].Restaurant_Id__c = '98765';

            insert new List<Account>{accs[0]};

            List<Account> childAccs = TDdAccountFactory.createAccounts('StoreFrontCaseChildAcc0', 1, 'Marketplace');
            childAccs[0].Restaurant_Id__c = '56789';  
            childAccs[0].ParentId = accs[0].Id;  
            insert childAccs;
            
            List<Contact> cons = new List<Contact>{
                TDdAccountFactory.createContacts(1, childAccs[0].Id)[0]
            };  
            cons[0].firstName = 'StoreFrontCaseF';
            cons[0].LastName = 'SFCaselname'; 
            cons[0].Email = 'storefrontcase.SFCaselname@dd.com';

            insert cons;            
            
            List<Opportunity> opps = new List<Opportunity>{
                TDdOpportunityFactory.createOpportunityByDevRT('StoreFrontCaseOpp0', childAccs[0].Id, cons[0].Id, 'New', 'ML_Inside_Sales')
            };

            opps[0].Menu_to_be_completed_by__c = 'Account Owner';
            opps[0].Order_Protocol__c = 'Email';
            opps[0].Mx_Requested_Custom_Radius_Demand_Gen__c = 'No';
            opps[0].Activate_Centrally_2__c = 'No';
            opps[0].StageName = 'Closed Won';
            insert opps;

            Product_Detail__c storefrontDetails = new Product_Detail__c();
            storefrontDetails.RecordTypeId = CDdCaseMilestoneStorefrontOnboarding.PRODUCT_DETAILS_STOREFRONT_RT;
            storefrontDetails.Opportunity__c = opps[0].Id;
            storefrontDetails.Implementation_Type__c = CDdCaseMilestoneStorefrontOnboarding.GOOGLE_FOOD;
            insert storefrontDetails;

            //Insert Milestone Templates
            CDdMilestoneTemplate.insertMilestoneTemplates();

            Case c = new Case(AccountId = childAccs[0].Id, 
                          Opportunity_name__c = opps[0].Id,
                          Origin = 'Closed Won Opportunity - SSMO',
                          Stage__c = 'Not Started',
                          recordTypeId = CASE_STOREFRONT_ONBOARDING_RECORD_TYPE_ID);
            insert c ;             
            Test.stopTest();
        }
    }

    @IsTest
    static void testMilestonesGoogleFood() {
        Test.startTest();
            Case testCase = insertStorefrontOnboardingCaseForOpportunity([SELECT Id, AccountId FROM Opportunity LIMIT 1], true);
        Test.stopTest();

        Set<String> EXPECTED_MILESTONES = new Set<String>{
            CDdCaseMilestoneStorefrontOnboarding.REVIEW_TRIAGE,
            CDdCaseMilestoneStorefrontOnboarding.SETUP_STORE_PRICING,
            CDdCaseMilestoneStorefrontOnboarding.SETUP_STOREFRONT_PAGE
        };

        List<Milestone__c> actualMilestones = getMilestonesForCase(testCase.Id);
        System.assertEquals(EXPECTED_MILESTONES.size(), actualMilestones.size(), 'Google Food Implementation Type should produce only ' + EXPECTED_MILESTONES.size() + 'Milestones.');

        verifyMilestonesForCase(EXPECTED_MILESTONES, actualMilestones);
    }

    @IsTest
    static void testMilestonesSocialMedia() {
        updateProductDetailImplementationType(CDdCaseMilestoneStorefrontOnboarding.SOCIAL_MEDIA);

        Test.startTest();
            Case testCase = insertStorefrontOnboardingCaseForOpportunity([SELECT Id, AccountId FROM Opportunity LIMIT 1], true);
        Test.stopTest();

        Set<String> EXPECTED_MILESTONES = new Set<String>{
            CDdCaseMilestoneStorefrontOnboarding.REVIEW_TRIAGE,
            CDdCaseMilestoneStorefrontOnboarding.SETUP_STORE_PRICING,
            CDdCaseMilestoneStorefrontOnboarding.SETUP_STOREFRONT_PAGE,
            CDdCaseMilestoneStorefrontOnboarding.IMPLEMENTATION_CALL,
            CDdCaseMilestoneStorefrontOnboarding.LINK_IMPLEMENTATION
        };

        List<Milestone__c> actualMilestones = getMilestonesForCase(testCase.Id);
        System.assertEquals(EXPECTED_MILESTONES.size(), actualMilestones.size(), 'Social Media Implementation Type should produce ' + EXPECTED_MILESTONES.size() + 'Milestones');

        verifyMilestonesForCase(EXPECTED_MILESTONES, actualMilestones);        
    }

    @IsTest
    static void testMilestonesSmartButton() {
        updateProductDetailImplementationType(CDdCaseMilestoneStorefrontOnboarding.SMART_BTN);

        Test.startTest();
            Case testCase = insertStorefrontOnboardingCaseForOpportunity([SELECT Id, AccountId FROM Opportunity LIMIT 1], true);
        Test.stopTest();        
        
        List<Milestone__c> actualMilestones = getMilestonesForCase(testCase.Id);
        System.assertEquals(ALL_MILESTONES.size(), actualMilestones.size(), 'All ' + ALL_MILESTONES.size() + 'Storefront Milestones should have been created.');

        verifyMilestonesForCase(ALL_MILESTONES, actualMilestones);        
    }
    
    @IsTest
    static void testMilestonesWebsite() {
        updateProductDetailImplementationType(CDdCaseMilestoneStorefrontOnboarding.WEBSITE);

        Test.startTest();
            Case testCase = insertStorefrontOnboardingCaseForOpportunity([SELECT Id, AccountId FROM Opportunity LIMIT 1], true);
        Test.stopTest();        

        List<Milestone__c> actualMilestones = getMilestonesForCase(testCase.Id);
        System.assertEquals(ALL_MILESTONES.size(), actualMilestones.size(), 'All ' + ALL_MILESTONES.size() + 'Storefront Milestones should have been created.');

        verifyMilestonesForCase(ALL_MILESTONES, actualMilestones);        
    }

    @IsTest
    static void testMilestoneWithNoImplementationType() {
        // Remove the Product Details created in @TestSetup
        delete [SELECT Id, Implementation_Type__c FROM Product_Detail__c LIMIT 1];

        Test.startTest();
            Case testCase = insertStorefrontOnboardingCaseForOpportunity([SELECT Id, AccountId FROM Opportunity LIMIT 1], true);
        Test.stopTest();        

        List<Milestone__c> actualMilestones = getMilestonesForCase(testCase.Id);
        System.assertEquals(ALL_MILESTONES.size(), actualMilestones.size(), 'All ' + ALL_MILESTONES.size() + 'Storefront Milestones should have been created.');

        verifyMilestonesForCase(ALL_MILESTONES, actualMilestones);  
    }
    
    private static void updateProductDetailImplementationType(String implementationType) {
        Product_Detail__c storefrontDetails = [SELECT Id, Implementation_Type__c FROM Product_Detail__c LIMIT 1];
        storefrontDetails.Implementation_Type__c = implementationType;
        update storefrontDetails;

    }

    private static Case insertStorefrontOnboardingCaseForOpportunity(Opportunity testOpportunity, Boolean performDml) {
        Case testCase = new Case();
        testCase.RecordTypeId = CASE_STOREFRONT_ONBOARDING_RECORD_TYPE_ID;
        testCase.AccountId = testOpportunity.AccountId;
        testCase.Opportunity_Name__c = testOpportunity.Id;
        testCase.Origin = 'Closed Won Opportunity - SSMO';
        testCase.Stage__c = 'Not Started';

        if(performDml) {
            insert testCase; 
        }

        return testCase;
    }

    // Verifies that the Milestones actually created are in the set of expected Milestones.
    private static void verifyMilestonesForCase(Set<String> expectedMilestoneNames, List<Milestone__c> actualMilestones) {
        for(Milestone__c thisMilestone : actualMilestones) {
            System.assert(expectedMilestoneNames.contains(thisMilestone.Milestone_Type__c));
        }
    }

    private static List<Milestone__c> getMilestonesForCase(Id caseId) {
        return new List<Milestone__c>([SELECT Id, Name, Milestone_Type__c, Case__c FROM Milestone__c WHERE Case__c = :caseId]);
    }
}