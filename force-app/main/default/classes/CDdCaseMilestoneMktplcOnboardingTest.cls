/**
    @author: Dan Thoreson
    @date: 07-Jun-2022
    @group: Milestone
    @description: Test class for CDdCaseMilestoneMarketplaceOnboarding.
                  Note that this class name differs slightly from the class that it tests, solely because 
                  "CDdCaseMilestoneMarketplaceOnboardingTest" is 41 characters, over the 40-character 
                  limit for Apex class identifiers. 
    2022-07-05      Nathalie Mendezona      Added testMilestoneCreationForIntlWithAlcoholConditionals() - BZAP-15925
**/
@IsTest
private class CDdCaseMilestoneMktplcOnboardingTest {    

    private static final Id CASE_MARKETPLACE_ONBOARDING_RECORD_TYPE_ID = CDdSchemaUtils.CASE_RT.marketplaceOnboardingId();
    private static final String OPPORTUNITY_NAME_NO_CONDITIONALS = 'Test Opportunity - No Conditional Milestones';
    private static final String OPPORTUNITY_NAME_POS_MILESTONES = 'Test Opportunity - POS Milestones';
    private static final String OPPORTUNITY_NAME_POS_NON_INTEGRATED_MX = 'Test Opportunity - POS Milestones - Non-Integrated Mx';
    private static final String OPPORTUNITY_NAME_POS_INTL = 'Test Opportunity - POS Milestones - International';
    private static final String OPPORTUNITY_NAME_ALCOHOL_INTL = 'Test Opportunity - Alcohol Milestones - International';

    private static List<String> defaultMarketplaceOnboardingMilestones = new List<String>{
        CDdCaseMilestoneMarketplaceOnboarding.REVIEW_TRIAGE,
        CDdCaseMilestoneMarketplaceOnboarding.SETUP_STORE,
        CDdCaseMilestoneMarketplaceOnboarding.SETUP_BANKING,
        CDdCaseMilestoneMarketplaceOnboarding.SETUP_BUSINESS,
        CDdCaseMilestoneMarketplaceOnboarding.GRANT_PORTAL_ACCESS,
        CDdCaseMilestoneMarketplaceOnboarding.ACTIVATIONS_CHECKLIST
    };

    private static Map<Id, List<String>> defaultMarketplaceOnboardingMilestonesByVersion = new Map<Id, List<String>>();

    public static final Integer NUMBER_OF_DEFAULT_MILESTONES = defaultMarketplaceOnboardingMilestones.size();

    @TestSetup
    static void setupTest() {
        System.runAs(CDdCaseMilestoneTest.getTestRunUser()) {
            CDdCaseMilestoneTest.initializeTestSettings();

            initializeTestData();
        }
    }

    @IsTest
    static void testMilestoneCreationFromCaseWithNoConditionals() {
        Test.startTest();
            Case testCase = insertMarketPlaceOnboardingCaseForOpportunity([SELECT Id, AccountId FROM Opportunity WHERE Name = :OPPORTUNITY_NAME_NO_CONDITIONALS LIMIT 1], true);
        Test.stopTest(); 

        List<Milestone__c> actualMilestones = getMilestonesForCase(testCase.Id);

        verifyMilestones(actualMilestones, new Set<String>{}, OPPORTUNITY_NAME_NO_CONDITIONALS, null);
    }

    @IsTest
    static void testMilestoneCreationFromCaseWithPosMilestones() {
        Test.startTest();
            Case testCase = insertMarketPlaceOnboardingCaseForOpportunity([SELECT Id, AccountId FROM Opportunity WHERE Name = :OPPORTUNITY_NAME_POS_MILESTONES LIMIT 1], true);
        Test.stopTest();

        List<Milestone__c> actualMilestones = getMilestonesForCase(testCase.Id);
        
        Set<String> expectedConditionals = new Set<String>{
            CDdCaseMilestoneMarketplaceOnboarding.SETUP_POS_INTEGRATION
        };

        verifyMilestones(actualMilestones, expectedConditionals, OPPORTUNITY_NAME_POS_MILESTONES, null);
    }

    @IsTest
    static void testMilestoneCreationWithPosNonIntegratedMerchantAndActivateStoreConditionals() {
        Test.startTest();
            Case testCase = insertMarketPlaceOnboardingCaseForOpportunity([SELECT Id, AccountId FROM Opportunity WHERE Name = :OPPORTUNITY_NAME_POS_NON_INTEGRATED_MX LIMIT 1], true);
        Test.stopTest();

        List<Milestone__c> actualMilestones = getMilestonesForCase(testCase.Id);

        Set<String> expectedConditionals = new Set<String>{ CDdCaseMilestoneMarketplaceOnboarding.SETUP_MENU, CDdCaseMilestoneMarketplaceOnboarding.ACTIVATE_STORE };

        verifyMilestones(actualMilestones, expectedConditionals, OPPORTUNITY_NAME_POS_NON_INTEGRATED_MX, null);
    }

    @IsTest
    static void testMilestoneCreationPosNonIntegratedMerchantWithPosTestMethodConditionals() {
        Test.startTest();
            Case testCase = insertMarketPlaceOnboardingCaseForOpportunity([SELECT Id, AccountId FROM Opportunity WHERE Name = :OPPORTUNITY_NAME_POS_INTL LIMIT 1], true);
        Test.stopTest();

        List<Milestone__c> actualMilestones = getMilestonesForCase(testCase.Id);

        Set<String> expectedConditionals = new Set<String>{
            CDdCaseMilestoneMarketplaceOnboarding.SETUP_POS_INTEGRATION,
            CDdCaseMilestoneMarketplaceOnboarding.ALCOHOL_LICENSE,
            CDdCaseMilestoneMarketplaceOnboarding.POS_TEST_METHOD
        };

        verifyMilestones(actualMilestones, expectedConditionals, OPPORTUNITY_NAME_POS_INTL, null);
    }

    @IsTest
    static void testMilestoneCreationForIntlWithAlcoholConditionals() {
        Test.startTest();
            Case testCase = insertMarketPlaceOnboardingCaseForOpportunity([SELECT Id, AccountId FROM Opportunity WHERE Name = :OPPORTUNITY_NAME_ALCOHOL_INTL LIMIT 1], true);
        Test.stopTest();

        List<Milestone__c> actualMilestones = getMilestonesForCase(testCase.Id);

        Set<String> expectedConditionals = new Set<String>{ CDdCaseMilestoneMarketplaceOnboarding.ALCOHOL_LICENSE};

        verifyMilestones(actualMilestones, expectedConditionals, OPPORTUNITY_NAME_ALCOHOL_INTL, null);
    }

    @IsTest
    static void testMilestoneCreationFromVersionsNoConditionals() {
        initializeMilestoneVersions(false);
        
        Test.startTest();
            Case testCase = insertMarketPlaceOnboardingCaseForOpportunity([SELECT Id, AccountId FROM Opportunity WHERE Name = :OPPORTUNITY_NAME_NO_CONDITIONALS LIMIT 1], true);
        Test.stopTest(); 

        List<Milestone__c> actualMilestones = getMilestonesForCase(testCase.Id);

        verifyMilestones(actualMilestones, new Set<String>{}, OPPORTUNITY_NAME_NO_CONDITIONALS, null);
    }

    @IsTest
    static void testMilestoneCreationFromCaseWithPosMilestonesFromVersions() {
        initializeMilestoneVersions(false);
        testMilestoneCreationFromCaseWithPosMilestones();    
    }

    @IsTest
    static void testMilestoneCreationPosNonIntegratedMerchantWithPosTestMethodConditionalsFromVersions() {
        initializeMilestoneVersions(false);
        testMilestoneCreationPosNonIntegratedMerchantWithPosTestMethodConditionals();    
    }

    // Scenario for the following bug - https://doordash.atlassian.net/browse/BZAP-17274
    // Two sets of Milestone Templates are getting linked to the same Case because of how the Versions were set.
    // The existingMilestoneTemplates map in CDdMilestoneGeneratorImpl was looking at the wrong Template IDs, which
    // was causing both sets (the existing "new" Version and the recently created "old" Version) to the Case.     
    @IsTest
    static void testMilestoneCreationWithMultipleVersionsWithOldCase() {
        // Initialize some Milestones for a previous Version
        initializeMilestoneVersions(true);

        List<Milestone_Template_Version__c> versions = [SELECT Id, Record_Type_Id__c, End_Time__c 
                                                            FROM Milestone_Template_Version__c 
                                                            WHERE Record_Type_Id__c = :CDdSchemaUtils.CASE_RT.marketplaceOnboardingId()
                                                            ORDER BY Version_Number__c];

        Milestone_Template_Version__c oldVersion = versions[0];
        Milestone_Template_Version__c newVersion = versions[1];

        createNewMarketplaceMilestoneTemplatesForVersion(newVersion.Id); // Templates do not yet exist for new Version; make them. 

        Test.startTest();
            // CDdMilestoneGeneratorImpl.dateOverrideTesting = System.today().addDays(-10);
			CDdMilestoneGeneratorImpl.dateOverrideTesting = System.today();
            
            Case testCase = insertMarketPlaceOnboardingCaseForOpportunity([SELECT Id, AccountId FROM Opportunity WHERE Name = :OPPORTUNITY_NAME_ALCOHOL_INTL LIMIT 1], true);
        
        	// Add Milestones to the testCase with from the different Template Version; this will simulate bug BZAP-17274
        	List<Milestone__c> milestones = new List<Milestone__c>();
        
            CDdMilestoneGenerator milestoneGenerator = (CDdMilestoneGenerator) Type.forName('CDdCaseMilestoneMarketplaceOnboarding').newInstance();
            String parentSObjectReferenceField = 'Case__c';
        
            milestoneGenerator.setParentAttributes('Case', CDdSchemaUtils.CASE_RT.marketplaceOnboardingId(), parentSObjectReferenceField);
	        milestoneGenerator.setParentSObjectRecords(new Map<Id, SObject>{ testCase.Id => testCase });
            milestoneGenerator.execute();
        
        	CDdMilestoneGeneratorImpl.dateOverrideTesting = System.today().addDays(-10);
        Test.stopTest();

        // Verify the Milestones do not get added multiple times
        Set<String> createdMilestones = new Set<String>();
        
        for(Milestone__c thisMilestone : getMilestonesForCase(testCase.Id)) {
            System.assert(!createdMilestones.contains(thisMilestone.Name), 'The ' + thisMilestone.Name + ' Milestone already exists on this Case.');
            createdMilestones.add(thisMilestone.Name);
        }
    }
	
    private static void createNewMarketplaceMilestoneTemplatesForVersion(Id versionId) {
        // It doesn't really matter what Milestones are in here - we just need a new set. 
        List<Milestone_Template__c> templates = new List<Milestone_Template__c>{
            CDdMilestoneTemplate.reviewAndTriage(),
            CDdMilestoneTemplate.setupStore(),
            CDdMilestoneTemplate.setupBanking(),
            CDdMilestoneTemplate.setupCustomDeliveryRadius(),
            CDdMilestoneTemplate.setupBusiness(),
            CDdMilestoneTemplate.setupMenu(),
            CDdMilestoneTemplate.setupCatalog(),
            CDdMilestoneTemplate.grantPortalAccess()
        };

        for(Milestone_Template__c thisTemplate : templates) {
            thisTemplate.Milestone_Template_Version__c = versionId;
        }

        insert templates;

        setVersionsMap();
    }

    private static void setVersionsMap() {
        for(Milestone_Template_Version__c mtv : [SELECT Id,
                                                    (SELECT Active__c, Completed_by_Stage__c, Default_Milestone_Status_on_Creation__c,
                                                                        Default_Owner_on_Creation_18__c, Default_Sort_Order__c, Id,
                                                                        Milestone_Creation_Type__c, Milestone_Record_Type_ID_18__c, Milestone_Type__c,
                                                                        Parent_Object_API_Name__c, Parent_Object_Record_Type_ID_18__c, Reviewed_by_Stage__c,
                                                                        Stage_Completed_Sort_Order__c, Stage_Reviewed_Sort_Order__c
                                                                FROM Milestone_Templates__r 
                                                                WHERE Active__c = true 
                                                                ORDER BY Default_Sort_Order__c) 
                                                    FROM Milestone_Template_Version__c WHERE Record_Type_Id__c = :CDdSchemaUtils.CASE_RT.marketplaceOnboardingId()]) 
        {
            defaultMarketplaceOnboardingMilestonesByVersion.put(mtv.Id, new List<String>());
            for(Milestone_Template__c template : mtv.Milestone_Templates__r) {
                if(template.Milestone_Creation_Type__c == 'Default') {
                    defaultMarketplaceOnboardingMilestonesByVersion.get(mtv.Id).add(template.Milestone_Type__c);
                }
            }
        }
    }

    /**
        @author: Dan Thoreson
        @date: 09-Jun-2022
        @description: Assert the creation of Milestones for an inputted Case's list of Milestones
        @param: List<Milestone__c> actualMilestones - the Milestones created for a given Case
        @param: List<Milestone__c> expectedConditionals - the Conditional Milestones that should have been created for the Case
        @param: String oppName - Name of the Opportunity or test case, used in assertion messages
        @param: Id versionId - Indicates specific version ID to use; if null, then use latest
        @return: void
    **/
    private static void verifyMilestones(List<Milestone__c> actualMilestones, Set<String> expectedConditionals, String oppName, Id versionId) {
        Integer numberOfDefaultMilestones;

        // Figure out the number of expected Default Milestones based on Version
        if(versionId == null) { // Use latest version
            numberOfDefaultMilestones = defaultMarketplaceOnboardingMilestones.size();
        } else {
            numberOfDefaultMilestones = defaultMarketplaceOnboardingMilestonesByVersion.get(versionId).size();
        }
    
        Integer totalExpectedMilestones = numberOfDefaultMilestones + expectedConditionals.size();

        System.assertEquals(totalExpectedMilestones, actualMilestones.size(), totalExpectedMilestones + ' Milestones should have been created for test case: ' + oppName);

        Map<String, Milestone__c> milestonesByNames = new Map<String, Milestone__c>();

        for(Milestone__c thisMilestone : actualMilestones) {
            milestonesByNames.put(thisMilestone.Milestone_Type__c, thisMilestone);
        }

        verifyDefaultMilestones(milestonesByNames.keySet());
        verifyConditionalMilestones(milestonesByNames.keySet(), expectedConditionals);
    }

    /**
        @author: Dan Thoreson
        @date: 09-Jun-2022
        @description: From an inputted list of Case Milestones, verify that all the default Marketplace 
                      Onboarding Milestones are present.
        @param: Set<String> actualMilestoneNames - the Milestone records that were actually created for a Case
        @return: void
    **/
    private static void verifyDefaultMilestones(Set<String> actualMilestoneNames) {
        for(String milestoneName : defaultMarketplaceOnboardingMilestones) {
            System.assert(actualMilestoneNames.contains(milestoneName), 'Marketplace Onboarding Case is missing the ' + milestoneName + ' Milestone.');
        }
    }

    /**
        @author: Dan Thoreson
        @date: 09-Jun-2022
        @description: From an inputted list of actual Case Milestone names and expected Case Milestone names, verify that all 
                      the Marketplace Onboarding Milestones are present.
        @param: Set<String> actualMilestoneNames - the names of the Milestone records that were actually created for a Case
        @param: Set<String> expectedConditionalMilestoneNames - the names of the Milestone records that are EXPECTED for a Case
        @return: void
    **/    
    private static void verifyConditionalMilestones(Set<String> actualMilestoneNames, Set<String> expectedConditionalMilestoneNames) {
        for(String milestoneName : expectedConditionalMilestoneNames) {
            System.assert(actualMilestoneNames.contains(milestoneName), 'Marketplace Onboarding Case is missing the ' + milestoneName + ' conditional Milestone.');
        } 
    }

    private static List<Milestone__c> getMilestonesForCase(Id caseId) {
        return new List<Milestone__c>([SELECT Id, Name, Milestone_Type__c, Case__c FROM Milestone__c WHERE Case__c = :caseId]);
    }

    /**
        @author: Dan Thoreson
        @date: 08-Jun-2022
        @description: Initializes Marketplace Onboarding Case records for the test methods
        @param: Opportunity testOpportunity - related Opportunity
        @param: Opportunity testOpportunity - indicates whether to insert the Case in this method (true), or return the initialized object without insertion (false)
        @return: Case - the created Case record
    **/
    private static Case insertMarketPlaceOnboardingCaseForOpportunity(Opportunity testOpportunity, Boolean performDml) {
        Case testCase = new Case();
        testCase.RecordTypeId = CASE_MARKETPLACE_ONBOARDING_RECORD_TYPE_ID;
        testCase.AccountId = testOpportunity.AccountId;
        testCase.Opportunity_Name__c = testOpportunity.Id;
        testCase.Stage__c = 'Not Started';

        if(performDml) {
            insert testCase; 
        }

        return testCase;
    }

    private static void initializeMilestoneVersions(Boolean useMultiple) {
        useMultiple = useMultiple != null ? useMultiple : false;

        delete [SELECT Id FROM Milestone_Template__c]; // Clear out the old Templates created without versions
        CDdMilestoneTemplate.insertMilestoneTemplatesWithVersions();

        if(useMultiple) {
            List<Milestone_Template_Version__c> versionsToUpdate = new List<Milestone_Template_Version__c>();

            Milestone_Template_Version__c oldVersion = [SELECT Id, Record_Type_Id__c, End_Time__c 
                                                    FROM Milestone_Template_Version__c 
                                                    WHERE Record_Type_Id__c = :CDdSchemaUtils.CASE_RT.marketplaceOnboardingId()];
            oldVersion.End_Time__c = System.today().addDays(-3);
            versionsToUpdate.add(oldVersion);
            
            Milestone_Template_Version__c newVersion = new Milestone_Template_Version__c();
            newVersion.Record_Type_Id__c = CDdSchemaUtils.CASE_RT.marketplaceOnboardingId();
            newVersion.Version_Number__c = 2;
            newVersion.Start_Time__c = System.today().addDays(-3);
            newVersion.End_Time__c = null;
            versionsToUpdate.add(newVersion);
    
            upsert versionsToUpdate;
        }
    }

    private static void initializeTestData() {
        TDdOpportunityLineItemFactory.createProducts();

        List<Account> marketplaceAccounts = TDdAccountFactory.createAccounts('POSIntegrationsParentAcc0', 2, 'Marketplace');
        marketplaceAccounts[1].Name = 'NZ Account';
        marketplaceAccounts[1].BillingPostalCode = '1234';
        marketplaceAccounts[1].BillingCountry = 'New Zealand';
        marketplaceAccounts[1].BillingCountryCode = 'NZ';
        marketplaceAccounts[1].BillingState = 'Auckland';
        marketplaceAccounts[1].Phone = '+64 12345678';
        marketplaceAccounts[1].Alcohol_Addendum_Signed__c = true;

        insert marketplaceAccounts;  
        
        List<Opportunity> oppsToInsert = new List<Opportunity>();

        Opportunity testOpportunity = TDdOpportunityFactory.createOpportunity(OPPORTUNITY_NAME_NO_CONDITIONALS, marketplaceAccounts[0].Id, null, 'Contract Signed', 'Pipeline', UserInfo.getUserId());
        testOpportunity.StageName = 'Closed Won';
        testOpportunity.Menu_to_be_completed_by__c = 'Account Owner';
        testOpportunity.Order_Protocol__c = 'Email';
        testOpportunity.Mx_Requested_Custom_Radius_Demand_Gen__c = 'No';
        testOpportunity.Activate_Centrally_2__c = 'No';
        testOpportunity.POS_Fallback_Protocol__c = null;
        testOpportunity.POS_System__c = null;
        oppsToInsert.add(testOpportunity);

        Opportunity posOpportunity = TDdOpportunityFactory.createOpportunity(OPPORTUNITY_NAME_POS_MILESTONES, marketplaceAccounts[0].Id, null, 'Contract Signed', 'Pipeline', UserInfo.getUserId());
        posOpportunity.StageName = 'Closed Won';
        posOpportunity.Order_Protocol__c = 'POS';
        posOpportunity.Menu_to_be_completed_by__c = 'DoorDash Onboarding Team';
        posOpportunity.Activate_Centrally_2__c = 'No';
        oppsToInsert.add(posOpportunity);

        Opportunity posNonIntegratedMerchantOpportunity = TDdOpportunityFactory.createOpportunity(OPPORTUNITY_NAME_POS_NON_INTEGRATED_MX, marketplaceAccounts[0].Id, null, 'Contract Signed', 'Pipeline', UserInfo.getUserId());
        posNonIntegratedMerchantOpportunity.StageName = 'Closed Won';
        posNonIntegratedMerchantOpportunity.Order_Protocol__c = 'POS';
        posNonIntegratedMerchantOpportunity.Menu_to_be_completed_by__c = 'DoorDash Onboarding Team';
        posNonIntegratedMerchantOpportunity.Activate_Centrally_2__c = 'Yes';
        posNonIntegratedMerchantOpportunity.POS_Integration_Type__c = CDdCaseMilestoneMarketplaceOnboarding.POS_INTEGRATION_TYPE_NON_INTEGRATED_MX;
        oppsToInsert.add(posNonIntegratedMerchantOpportunity);

        Opportunity alcoholIntlOpportunity = TDdOpportunityFactory.createOpportunity(OPPORTUNITY_NAME_ALCOHOL_INTL, marketplaceAccounts[1].Id, null, 'Contract Signed', 'Pipeline', UserInfo.getUserId());
        alcoholIntlOpportunity.StageName = 'Closed Won';
        alcoholIntlOpportunity.Order_Protocol__c = 'Email';
        alcoholIntlOpportunity.Menu_to_be_completed_by__c = 'Account Owner';
        alcoholIntlOpportunity.Activate_Centrally_2__c = 'No';
        alcoholIntlOpportunity.POS_Fallback_Protocol__c = null;
        alcoholIntlOpportunity.POS_System__c = null;
        oppsToInsert.add(alcoholIntlOpportunity);

        Opportunity newZealandPosOpportunity = TDdOpportunityFactory.createOpportunity(OPPORTUNITY_NAME_POS_INTL, marketplaceAccounts[1].Id, null, 'Contract Signed', 'Pipeline', UserInfo.getUserId());
        newZealandPosOpportunity.StageName = 'Closed Won';
        newZealandPosOpportunity.Order_Protocol__c = 'POS';
        newZealandPosOpportunity.Menu_to_be_completed_by__c = 'DoorDash Onboarding Team';
        newZealandPosOpportunity.Activate_Centrally_2__c = 'No';
        newZealandPosOpportunity.POS_Fallback_Protocol__c = null;
        newZealandPosOpportunity.POS_System__c = null;
        oppsToInsert.add(newZealandPosOpportunity);

        insert oppsToInsert;

        CDdMilestoneTemplate.insertMilestoneTemplates();
    }
}