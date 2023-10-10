/**
    @author: Dan Thoreson
    @date: 08-Aug-2022
    @group: Merchant Services
    @description: Test class for helper methods in CDdMxSxCaseHelper
**/
@IsTest
private class CDdMxSxCaseHelperTest {
    static final String TEST_PARENT_ACCOUNT_NAME = 'Test Parent Account';
    static final String TEST_OPPORTUNITY_NAME = 'Test_Opportunity';
    static final String PARENT_ACCOUNT_RT_NAME = 'Parent Account';

    @TestSetup static void initData() {

        Test.startTest();
        vCS__c testSettings;
        testSettings = VTestUtil.createVeltigSettings();
        testSettings.CaseTrigger__c = true;
        testSettings.FireAutoResponseRules__c = true;
        insert testSettings;

        RealZip__RealZips__c realZip = TDdCPQTestDataFactory.createRealZip(TDdCPQTestDataFactory.createSubmarket('New York', 'NEW YORK', 10, null, true), false);
        insert realZip;

        Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = UserInfo.getUserId());
        validation.Bypass_Opportunity_Validations__c = true;
        insert validation;

        // insert parent account
        Account parentAccount = TDdAccountFactory.createAccounts(TEST_PARENT_ACCOUNT_NAME, 1, PARENT_ACCOUNT_RT_NAME)[0];
        parentAccount.BillingCountry = 'United States';
        parentAccount.Business_Id__c = 1224444;
        parentAccount.Deck_Rank__c = 'Jack';
        parentAccount.RealZip__RealZip__c = realZip.Id;
        insert parentAccount;

        // Insert Storefront Onboarding Case
        List<Case> storefrontCases = TDdCaseFactory.createCases(1, parentAccount.Id, null, CDdMxSxConstants.RECORD_TYPE_ID_CASE_STOREFRONT_ONBOARDING);
        storefrontCases[0].OwnerId = CDdMxSxConstants.QUEUE_ID_STOREFRONT_CASE_HOLDING_QUEUE;
        storefrontCases[0].ClosedDate = System.today().addDays(5);
        insert storefrontCases;

        List<Account> stores = new List<Account>();

        // Store #1 - Active
        Account store1 = TDdAccountFactory.createAccount(CDdMxSxConstants.RECORD_TYPE_ID_ACCOUNT_MARKETPLACE);
        store1.ParentId = parentAccount.Id;
        store1.Currently_Active__c = 'Yes';
        store1.Is_Partner__c = 'Yes';
        stores.add(store1);

        // Store #2 - Inactive
        Account store2 = TDdAccountFactory.createAccount(CDdMxSxConstants.RECORD_TYPE_ID_ACCOUNT_MARKETPLACE);
        store2.ParentId = parentAccount.Id;
        stores.add(store2);

        insert stores;

        //Marketplace Opportunity
        List<Opportunity> opps = new List<Opportunity>{
            TDdOpportunityFactory.createOpportunityByDevRT('POSIntegrationsCaseOpp0', store1.Id, null, 'New', 'ML_Inside_Sales')
        };

        opps[0].Menu_to_be_completed_by__c = 'Account Owner';
        opps[0].Order_Protocol__c = 'Email';
        opps[0].Mx_Requested_Custom_Radius_Demand_Gen__c = 'No';
        opps[0].Activate_Centrally_2__c = 'No';
        opps[0].StageName = 'Closed Won';
        insert opps;
        Test.stopTest();
    }

    @IsTest
    static void testShouldCaseGoToUnderReviewQueue() {
        CDdMxSxParentAccountHelper parentAccountHelper;
        Id parentAccountId = [SELECT Id FROM Account WHERE RecordTypeId = :Schema.SObjectType.Account.getRecordTypeInfosByName().get(PARENT_ACCOUNT_RT_NAME).getRecordTypeId() LIMIT 1].Id;

        parentAccountHelper = new CDdMxSxParentAccountHelper(new Set<Id>{ parentAccountId });

        // The result of shouldCaseGoUnderReviewWithOneStoreActive should be determined by the Assign_Storefront_Cases_One_Active_Store__c Feature Flag
        System.assertEquals(CDdExperimentSvc.getFeatureFlag('Assign_Storefront_Cases_One_Active_Store__c'), CDdMxSxCaseHelper.assignStorefrontCasesWhenSingleStoreIsActive);

        // Positive case - feature is enabled and 1 of 2 Stores are active; Case should be assigned
        CDdMxSxCaseHelper.assignStorefrontCasesWhenSingleStoreIsActive = true;
        System.assert(CDdMxSxCaseHelper.shouldCaseGoToUnderReviewQueue(parentAccountHelper, parentAccountId));

        // Negative case - feature is disabled and only 1 of 2 Stores are active; Case should NOT be assigned
        CDdMxSxCaseHelper.assignStorefrontCasesWhenSingleStoreIsActive = false;
        System.assert(!CDdMxSxCaseHelper.shouldCaseGoToUnderReviewQueue(parentAccountHelper, parentAccountId));

        // Positive case - feature is disabled but all Stores (2 of 2) are active; Case should be assigned
        List<Account> stores = new List<Account>([SELECT Id, Currently_Active__c, Is_Partner__c FROM Account WHERE ParentId = :parentAccountId]);
        for(Account thisStore : stores) {
            thisStore.Currently_Active__c = 'Yes';
            thisStore.Is_Partner__c = 'Yes';
        }

        update stores;

        System.assert(CDdMxSxCaseHelper.shouldCaseGoToUnderReviewQueue(new CDdMxSxParentAccountHelper(new Set<Id>{ parentAccountId }), parentAccountId));
    }

    /**
     * @author: Veera Maddukuri
     * @date: 26-Aug-2022
     * @description: test metod to verify the Update of POS Integration fields on Opportunity when POS Case is Closed
    **/
    /*@IsTest
    static void testupdateOpportunityCaviarPOSFieldsOnPOSIntegrationCaseClosed() {
        String testIntegrationId = '62c32bc630d02e00e0b01104';
        String testIntegrationType = 'square';

        Opportunity opp = [Select Id,AccountId from Opportunity WHERE Name = 'POSIntegrationsCaseOpp0' LIMIT 1];
        opp.Platform__c = CDdMxSxConstants.OPPORTUNITY_PLATFORM_CAVIER;
        opp.Caviar_Order_Protocol__c = CDdMxSxConstants.OPPORTUNITY_CAVIAR_POS_OWNS;
        update opp;

        Case c = new Case(AccountId =opp.AccountId,
                        Opportunity_name__c = opp.Id,
                        Origin = 'Closed Won Opportunity',
                        Stage__c = 'Not Started',Activation_Method__c = 'Test order',
                        POS_Integration_Type__c =testIntegrationType,
                        recordTypeId = CDdSchemaUtils.CASE_RT.posIntegrationsId());
        insert c ;
        Test.startTest();
        c.POS_Integration_ID__c = testIntegrationId;
        c.Status = CDdMxSxConstants.CASE_STATUS_CLOSED;
        update c;

        Test.stopTest();
        opp = [Select Id, AccountId, POS_Integration_ID__c,POS_Integration_Type__c,Caviar_POS_Integration_Type__c from Opportunity WHERE Name = 'POSIntegrationsCaseOpp0' LIMIT 1];

        System.assertEquals(testIntegrationId, opp.POS_Integration_ID__c, 'Opportunity POS_Integration_ID__c not updated on POS Case update');
        System.assert(testIntegrationType.equalsIgnoreCase(opp.Caviar_POS_Integration_Type__c), 'Opportunity Caviar_POS_Integration_Type__c not updated on POS Case update');
    }*/
    /**
     * @author: Veera Maddukuri
     * @date: 26-Aug-2022
     * @description: test metod to verify the Update of POS Integration fields on Opportunity when POS Case is Closed
    **/
    /*@IsTest
    static void testupdateOpportunityPOSFieldsOnPOSIntegrationCaseClosed() {
        String testIntegrationId = '62c32bc630d02e00e0b01104';
        String testIntegrationType = 'square';

        Opportunity opp = [Select Id,AccountId from Opportunity WHERE Name = 'POSIntegrationsCaseOpp0' LIMIT 1];
        opp.Platform__c = CDdMxSxConstants.OPPORTUNITY_PLATFORM_DOORDASH;
        opp.Order_Protocol__c = CDdMxSxConstants.OPPORTUNITY_POS;
        update opp;

        Case c = new Case(AccountId =opp.AccountId,
                        Opportunity_name__c = opp.Id,
                        Origin = 'Closed Won Opportunity',
                        Stage__c = 'Not Started',Activation_Method__c = 'Test order',
                        POS_Integration_Type__c =testIntegrationType,
                        recordTypeId = CDdSchemaUtils.CASE_RT.posIntegrationsId());
        insert c ;
        Test.startTest();
        c.POS_Integration_ID__c = testIntegrationId;
        c.Status = CDdMxSxConstants.CASE_STATUS_CLOSED;
        update c;

        Test.stopTest();
        opp = [Select Id, AccountId, POS_Integration_ID__c,POS_Integration_Type__c,Caviar_POS_Integration_Type__c from Opportunity WHERE Name = 'POSIntegrationsCaseOpp0' LIMIT 1];

        System.assertEquals(testIntegrationId, opp.POS_Integration_ID__c, 'Opportunity POS_Integration_ID__c not updated on POS Case update');
        System.assertEquals(testIntegrationType, opp.POS_Integration_Type__c, 'Opportunity POS_Integration_Type__c not updated on POS Case update');
    }*/
    /**
     * @author: Veera Maddukuri
     * @date: 26-Aug-2022
     * @description: test metod to verify the Update of POS Integration fields on Opportunity when POS Case is Closed
    **/
    @IsTest
    static void testupdateOpportunityPOSFieldsOnPOSIntegrationCaseClosedWithInvalidData() {
        String testIntegrationId = 'N/a';
        String testIntegrationType = 'square';

        Opportunity opp = [Select Id,AccountId from Opportunity WHERE Name = 'POSIntegrationsCaseOpp0' LIMIT 1];
        opp.Platform__c = CDdMxSxConstants.OPPORTUNITY_PLATFORM_DOORDASH;
        opp.Order_Protocol__c = CDdMxSxConstants.OPPORTUNITY_POS;
        update opp;

        Case c = new Case(AccountId =opp.AccountId,
                        Opportunity_name__c = opp.Id,
                        Origin = 'Closed Won Opportunity',
                        Stage__c = 'Not Started',Activation_Method__c = 'Test order',
                        POS_Integration_Type__c =testIntegrationType,
                        recordTypeId = CDdSchemaUtils.CASE_RT.posIntegrationsId());
        insert c ;
        Test.startTest();
        c.POS_Integration_ID__c = testIntegrationId;
        c.POS_Integration_Type__c =testIntegrationType;
        c.Status = CDdMxSxConstants.CASE_STATUS_CLOSED;
        update c;
        Test.stopTest();
        opp = [Select Id, AccountId, POS_Integration_ID__c,POS_Integration_Type__c,Caviar_POS_Integration_Type__c from Opportunity WHERE Name = 'POSIntegrationsCaseOpp0' LIMIT 1];
        System.assertEquals(null, opp.POS_Integration_ID__c, 'Opportunity POS_Integration_ID__c not updated on POS Case update');
        System.assertEquals(null, opp.POS_Integration_Type__c, 'Opportunity POS_Integration_Type__c not updated on POS Case update');
    }

    /**
     * @author: Veera Maddukuri
     * @date: 21-Sep-2022
     * @description: test metod to verify the Eligibility to Send Printer
    **/
    @IsTest
    static void testIsMxEligibleForPrinter() {
        Opportunity opp = [Select Id,AccountId from Opportunity WHERE Name = 'POSIntegrationsCaseOpp0' LIMIT 1];
        Account acc = new Account();
        acc.Id = opp.AccountId;
        acc.Top_Mx__c = true;
        update acc;

        String PARTNER_INTEGRATION_SQUARE = 'square';

        opp.Order_Protocol__c = CDdMxSxConstants.OPPORTUNITY_POS;
        opp.POS_Integration_Type__c = PARTNER_INTEGRATION_SQUARE;
        update opp;

        Id PARTNER_INTEGRATION_POS_RECORDTYPEID = Schema.SObjectType.Partner_Integration__c.getRecordTypeInfosByDeveloperName().get('Point_Of_Sale').getRecordTypeId();
        Partner_Integration__c partnerIntegration1 = new Partner_Integration__c(Provider_Type__c = PARTNER_INTEGRATION_SQUARE, Provider_Name__c = PARTNER_INTEGRATION_SQUARE, Integration_Function__c = 'New Verticals', Launch_Day__c = 'PDOA', Menu_Type__c = 'OPEN_API', Menu_Pull__c = 'False', Menu_Push__c = 'True', Integration_Status__c = 'Live', Integration_Type__c = 'POS System', RecordTypeId=PARTNER_INTEGRATION_POS_RECORDTYPEID);
        partnerIntegration1.Menu_Vs_Order_Integration__c = CDdMxSxConstants.PARTNER_INTEG_MENU_ONLY_INTEGRATION;
        insert partnerIntegration1;

        Test.startTest();
        Map<Id,Boolean> opportunityVsPrinterEligibleStatus = CDdMxSxCaseHelper.isMxEligibleForPrinter(new Set<Id>{opp.Id});
        Test.stopTest();
        System.assertEquals(true, opportunityVsPrinterEligibleStatus.get(opp.Id), 'Opportunity should be Eligible to send Printer');
    }

     /**
     * @author: Veera Maddukuri
     * @date: 20-Nov-2022
     * @description: test metod to verify the Eligibility to Send Printer for Cases
    **/
    @IsTest
    static void testIsMxEligibleForPrinterForCases() {

        Integer bypassPrinterBlock = [SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId = :Userinfo.getUserId() AND PermissionSet.Name IN :CDdMxSxConstants.PRINTER_BYPASS_PERMISSIONSETS];
        if(bypassPrinterBlock == 0){
            List<PermissionSet> permSet = [SELECT Id FROM PermissionSet WHERE Name IN :CDdMxSxConstants.PRINTER_BYPASS_PERMISSIONSETS];
            PermissionSetAssignment psa = new PermissionSetAssignment();
            psa.AssigneeId = Userinfo.getUserId();
            psa.PermissionSetId = permSet[0].Id;
            insert psa;
        }

        List<Case> cases = [SELECT Id, Opportunity_Name__c FROM Case LIMIT 1];

        Test.startTest();
        Map<Id,Boolean> opportunityVsPrinterEligibleStatus = CDdMxSxCaseHelper.isMxEligibleForPrinterForCases(new Set<Id>{cases[0].Id});
        Test.stopTest();
        System.assertEquals(true, opportunityVsPrinterEligibleStatus.get(cases[0].Opportunity_Name__c), 'Case should be Eligible to send Printer');
    }

    /**
     * @author: Veera Maddukuri
     * @date: 18-Nov-2022
     * @description: test metod to verify the Eligibility to Send Printer for Caviar account
    **/
    @IsTest
    static void testIsMxEligibleForPrinterForCaviarAccount() {
        Opportunity opp = [Select Id,AccountId from Opportunity WHERE Name = 'POSIntegrationsCaseOpp0' LIMIT 1];
        Account acc = new Account();
        acc.Id = opp.AccountId;
        update acc;

        String PARTNER_INTEGRATION_SQUARE = 'square';
        opp.Order_Protocol__c = 'Tablet (DoorDash Owns)';
        opp.Platform__c= 'Caviar and DoorDash';
        update opp;

        Id PARTNER_INTEGRATION_POS_RECORDTYPEID = Schema.SObjectType.Partner_Integration__c.getRecordTypeInfosByDeveloperName().get('Point_Of_Sale').getRecordTypeId();
        Partner_Integration__c partnerIntegration1 = new Partner_Integration__c(Provider_Type__c = PARTNER_INTEGRATION_SQUARE, Provider_Name__c = PARTNER_INTEGRATION_SQUARE, Integration_Function__c = 'New Verticals', Launch_Day__c = 'PDOA', Menu_Type__c = 'OPEN_API', Menu_Pull__c = 'False', Menu_Push__c = 'True', Integration_Status__c = 'Live', Integration_Type__c = 'POS System', RecordTypeId=PARTNER_INTEGRATION_POS_RECORDTYPEID);
        partnerIntegration1.Menu_Vs_Order_Integration__c = CDdMxSxConstants.PARTNER_INTEG_MENU_ONLY_INTEGRATION;
        insert partnerIntegration1;

        Test.startTest();
        Map<Id,Boolean> opportunityVsPrinterEligibleStatus = CDdMxSxCaseHelper.isMxEligibleForPrinter(new Set<Id>{opp.Id});
        Test.stopTest();
        System.assertEquals(true, opportunityVsPrinterEligibleStatus.get(opp.Id), 'Opportunity should be Eligible to send Printer');
    }

    /**
     * @author: Veera Maddukuri
     * @date: 21-Sep-2022
     * @description: test metod to verify the Eligibility to Send Printer bypassing the checks
    **/
    @IsTest
    static void testIsMxEligibleForPrinterByPassLogic() {
        Opportunity opp = [Select Id,AccountId from Opportunity WHERE Name = 'POSIntegrationsCaseOpp0' LIMIT 1];
        Integer bypassPrinterBlock = [SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId = :Userinfo.getUserId() AND PermissionSet.Name = 'Bypass_Printer_Block'];
        if(bypassPrinterBlock == 0){
            List<PermissionSet> permSet = [SELECT Id FROM PermissionSet WHERE Name IN :CDdMxSxConstants.PRINTER_BYPASS_PERMISSIONSETS];
            PermissionSetAssignment psa = new PermissionSetAssignment();
            psa.AssigneeId = Userinfo.getUserId();
            psa.PermissionSetId = permSet[0].Id;
            insert psa;
        }
        Test.startTest();
        Map<Id,Boolean> opportunityVsPrinterEligibleStatus = CDdMxSxCaseHelper.isMxEligibleForPrinter(new Set<Id>{opp.Id});
        Test.stopTest();
        System.assertEquals(true, opportunityVsPrinterEligibleStatus.get(opp.Id), 'Opportunity should be Eligible to send Printer');
    }

    /**
     * @author: Veera Maddukuri
     * @date: 31-Oct-2022
     * @description: test null pointer check for Send Printer Eligibility method
    **/
    @IsTest
    static void testIsMxEligibleForPrinterForInvalidData() {
        Opportunity opp = [Select Id,AccountId from Opportunity WHERE Name = 'POSIntegrationsCaseOpp0' LIMIT 1];
        Account acc = new Account();
        acc.Id = opp.AccountId;
        acc.Top_Mx__c = true;
        update acc;

        String PARTNER_INTEGRATION_SQUARE = 'square';

        opp.Order_Protocol__c = null;
        opp.POS_Integration_Type__c = null;
        opp.Weekly_Tablet_Subscription_Fee__c = '';
        opp.Weekly_Printer_Subscription_Fee__c = '';
        update opp;

        Id PARTNER_INTEGRATION_POS_RECORDTYPEID = Schema.SObjectType.Partner_Integration__c.getRecordTypeInfosByDeveloperName().get('Point_Of_Sale').getRecordTypeId();
        Partner_Integration__c partnerIntegration1 = new Partner_Integration__c(Provider_Type__c = PARTNER_INTEGRATION_SQUARE, Provider_Name__c = PARTNER_INTEGRATION_SQUARE, Integration_Function__c = 'New Verticals', Launch_Day__c = 'PDOA', Menu_Type__c = 'OPEN_API', Menu_Pull__c = 'False', Menu_Push__c = 'True', Integration_Status__c = 'Live', Integration_Type__c = 'POS System', RecordTypeId=PARTNER_INTEGRATION_POS_RECORDTYPEID);
        partnerIntegration1.Menu_Vs_Order_Integration__c = CDdMxSxConstants.PARTNER_INTEG_MENU_ONLY_INTEGRATION;
        insert partnerIntegration1;

        Test.startTest();
        Map<Id,Boolean> opportunityVsPrinterEligibleStatus = CDdMxSxCaseHelper.isMxEligibleForPrinter(new Set<Id>{opp.Id});
        Test.stopTest();
        System.assertEquals(true, opportunityVsPrinterEligibleStatus.get(opp.Id), 'Opportunity should be Eligible to send Printer for non POS');
    }

    @IsTest
    static void testUpdateMarketplaceOnboardingMilestoneFromPosCase() {
        Map<String, String> milestoneStatusesByCaseStatuses = new Map<String, String>{
            CDdMxSxConstants.CASE_STATUS_CLOSED => CDdMxSxConstants.MILESTONE_STATUS_COMPLETE,
            CDdMxSxConstants.CASE_STATUS_BLOCKED => CDdMxSxConstants.MILESTONE_STATUS_BLOCKED,
            CDdMxSxConstants.CASE_STATUS_IN_PROGRESS => CDdMxSxConstants.MILESTONE_STATUS_IN_PROGRESS,
            CDdMxSxConstants.CASE_STATUS_ESCALATED => CDdMxSxConstants.MILESTONE_STATUS_ESCALATED
        };

        Integer numberOfUpdates = 4; // Track the Milestones we update for fflib validations

        for(String thisCaseStatusScenario : milestoneStatusesByCaseStatuses.keySet()) {
            fflib_ApexMocks mocks = new fflib_ApexMocks();
            fflib_ISObjectUnitOfWork mockUow = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_ISObjectUnitOfWork.class);

            MxSxApexMockTestDataFactory mockDataFactory = new MxSxApexMockTestDataFactory();

            Account childAccount = mockDataFactory.marketplaceAccount;

            Case marketplaceCase = (Case) new Fake(Case.class)
                                                    .setFakeId()
                                                    .setField(Case.RecordTypeId, CDdSchemaUtils.CASE_RT.marketplaceOnboardingId())
                                                    .setField(Case.AccountId, childAccount.Id)
                                                    .toSObject();

            Milestone__c posMilestone = (Milestone__c) new Fake(Milestone__c.class)
                                                            .setFakeId()
                                                            .setField(Milestone__c.Status__c, CDdMxSxConstants.MILESTONE_STATUS_IN_PROGRESS)
                                                            .setField(Milestone__c.RecordTypeId, Schema.SObjectType.Milestone__c.getRecordTypeInfosByDeveloperName().get(CDdCaseMilestoneMarketplaceOnboarding.SETUP_POS_RT_DEV_NAME).getRecordTypeId())
                                                            .setField(Milestone__c.Case__c, marketplaceCase.Id)
                                                            .toSObject();

            Case posCase = (Case) new Fake(Case.class)
                                            .setFakeId()
                                            .setField(Case.Status, thisCaseStatusScenario)
                                            .setField(Case.RecordTypeId, CDdSchemaUtils.CASE_RT.posIntegrationsId())
                                            .setField(Case.AccountId, childAccount.Id)
                                            .setField(Case.ParentId, marketplaceCase.Id)
                                            .toSObject();

            ICasesSelector casesSelectorMock = (ICasesSelector) mocks.mock(ICasesSelector.class);
            IMilestonesSelector milestonesSelectorMock = (IMilestonesSelector) mocks.mock(IMilestonesSelector.class);

            Set<Id> posCaseIds = new Set<Id>{ posCase.Id };
            Set<Id> parentCaseIds = new Set<Id>{ posCase.ParentId };

            mocks.startStubbing();
                mocks.when(casesSelectorMock.sObjectType()).thenReturn(Case.SObjectType);
                mocks.when(casesSelectorMock.selectByIdExtraFields(posCaseIds, new Set<String>{'Status_Reason__c', 'Status_Reason_Details__c'})).thenReturn(new List<Case>{ posCase });

                mocks.when(milestonesSelectorMock.sObjectType()).thenReturn(Milestone__c.SObjectType);
                mocks.when(milestonesSelectorMock.selectByCaseIdAndRecordTypeDeveloperName(parentCaseIds, new Set<String>{CDdCaseMilestoneMarketplaceOnboarding.SETUP_POS_RT_DEV_NAME})).thenReturn(new List<Milestone__c>{ posMilestone });
            mocks.stopStubbing();

            Application.Selector.setMock(casesSelectorMock);
            Application.Selector.setMock(milestonesSelectorMock);
            Application.UnitOfWork.setMock(mockUow);

            CDdMxSxCaseHelper.updateMarketplaceOnboardingMilestoneFromPosCase(new List<Case>{ posCase });

            String expectedStatusReason = (posCase.Status == CDdMxSxConstants.CASE_STATUS_BLOCKED || posCase.Status == CDdMxSxConstants.CASE_STATUS_ESCALATED) ? 'Other' : null;

            // Verify a single Milestone was updated with the relevant Status, based on what happened to the POS Case
            ((fflib_ISObjectUnitOfWork) mocks.verify(mockUow, 1)).registerDirty(fflib_Match.sObjectWith(new Map<SObjectField, Object>{
                Milestone__c.Id => posMilestone.Id,
                Milestone__c.Status__c => milestoneStatusesByCaseStatuses.get(thisCaseStatusScenario),
                Milestone__c.Status_Reason__c => expectedStatusReason
            }));

            if(numberOfUpdates < milestoneStatusesByCaseStatuses.size()) {
                numberOfUpdates++;
            }
        }

        // fflib assertions are above, but a traditional assertion is required for CodeScan
        // Use this to verify that we made Case updates with each testable status
        System.assertEquals(milestoneStatusesByCaseStatuses.keySet().size(), numberOfUpdates, 'Each scenario in the Status map should have been tested.');
    }
}