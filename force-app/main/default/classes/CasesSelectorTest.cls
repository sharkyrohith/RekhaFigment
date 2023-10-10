/**
    @author: Dan Thoreson
    @date: 09-Nov-2022
    @description: Tests for the CasesSelector. Includes full tests with DML to determine the accuracy
                  of the data returned. Basic unit tests for the CasesSelector are in CasesSelectorSpec.
**/
@IsTest
private class CasesSelectorTest {

    @TestSetup
    static void initData() {
        System.runAs(getTestRunUser()) {
            TDdCaseFactory.getSupportFeatureFlag(true);
            CDdCaseMilestoneTest.initializeTestSettings();

            TDdOpportunityLineItemFactory.createProducts();

            List<Account> parentAccounts = TDdAccountFactory.createAccounts('Parent_Account_1', 1, 'Parent Account');
            insert parentAccounts;

            List<Account> childAccounts = TDdAccountFactory.createAccounts('Child_Account_1', 1, 'Marketplace');
            childAccounts[0].Restaurant_Id__c = '56789';
            childAccounts[0].ParentId = parentAccounts[0].Id;
            insert childAccounts;

            List<Contact> contacts = TDdAccountFactory.createContacts(1, childAccounts[0].Id);
            contacts[0].FirstName = 'Storefront';
            contacts[0].LastName = 'Contact';
            contacts[0].Email = 'storefrontcase@dd-testing.com';
            insert contacts;

            Opportunity mktplcOpportunity = TDdOpportunityFactory.createOpportunityByDevRT('Marketplace_Opportunity_1', parentAccounts[0].Id, contacts[0].Id, 'New', 'ML_Inside_Sales');
            mktplcOpportunity.Menu_to_be_completed_by__c = 'Account Owner';
            mktplcOpportunity.Order_Protocol__c = 'Email';
            mktplcOpportunity.Mx_Requested_Custom_Radius_Demand_Gen__c = 'No';
            mktplcOpportunity.Activate_Centrally_2__c = 'No';
            mktplcOpportunity.StageName = 'Closed Won';
            insert mktplcOpportunity;

            insert new Case(AccountId = parentAccounts[0].Id,
                            Opportunity_Name__c = mktplcOpportunity.Id,
                            Origin = 'Closed Won Opportunity - SSMO',
                            Stage__c = 'Not Started',
                            RecordTypeId = CDdSchemaUtils.CASE_RT.storefrontOnboardingId());
        }
    }

    @IsTest
    static void testSelectCasesByIdsWithParentAccountInfo() {
        Set<Id> caseIds = new Map<Id, Case>([SELECT Id FROM Case LIMIT 10]).keySet();

        Test.startTest();
            List<Case> results = CasesSelector.newInstance().selectCasesByIdsWithParentAccountInfo(caseIds);
        Test.stopTest();

        System.assertEquals(caseIds.size(), results.size(), 'An incorrect number of Case records were retrieved by the selector.');
        System.assertNotEquals(null, results[0].RecordType.Name, 'RecordType.Name should have been queried as a related field.');
    }

    @IsTest
    static void testSelectCasesWithMilestonesByRecordTypeAndAccount() {
        Set<Id> accountIds = new Map<Id, Account>([SELECT Id FROM Account WHERE ParentId = null]).keySet();

        Test.startTest();
            Map<Id, Case> results = new Map<Id, Case>(CasesSelector.newInstance().selectCasesWithMilestonesByRecordTypeAndAccount(CDdSchemaUtils.CASE_RT.storefrontOnboardingId(), accountIds));
        Test.stopTest();

        Map<Id, Case> expected = new Map<Id, Case>([SELECT Id FROM Case WHERE AccountId IN :accountIds AND RecordTypeId = :CDdSchemaUtils.CASE_RT.storefrontOnboardingId()]);

        System.assertEquals(expected.size(), results.size());

        for(Id thisCaseId : results.keySet()) {
            System.assert(expected.containsKey(thisCaseId));
        }
    }

    @IsTest
    static void testSelectCasesWithMilestonesByRecordTypeAndGenericParent() {
        Set<Id> accountIds = new Map<Id, Account>([SELECT Id FROM Account WHERE ParentId = null]).keySet();
        Set<Id> opportunityIds = new Set<Id>{ [SELECT Opportunity_Name__c FROM Case WHERE RecordTypeId = :CDdSchemaUtils.CASE_RT.storefrontOnboardingId() LIMIT 1].Opportunity_Name__c };

        Test.startTest();
            Map<Id, Case> resultsForAccountField = new Map<Id, Case>(CasesSelector.newInstance().selectCasesWithMilestonesByRecordTypeAndGenericParent(CDdSchemaUtils.CASE_RT.storefrontOnboardingId(), 'AccountId', accountIds));
            Map<Id, Case> resultsForOpportunityField = new Map<Id, Case>(CasesSelector.newInstance().selectCasesWithMilestonesByRecordTypeAndGenericParent(CDdSchemaUtils.CASE_RT.marketplaceOnboardingId(), 'Opportunity_Name__c', opportunityIds));
        Test.stopTest();

        Map<Id, Case> expectedForAccount = new Map<Id, Case>([SELECT Id FROM Case WHERE AccountId IN :accountIds AND RecordTypeId = :CDdSchemaUtils.CASE_RT.storefrontOnboardingId()]);
        Map<Id, Case> expectedForOpportunity = new Map<Id, Case>([SELECT Id FROM Case WHERE Opportunity_Name__c IN :opportunityIds AND RecordTypeId = :CDdSchemaUtils.CASE_RT.marketplaceOnboardingId()]);

        System.assertEquals(expectedForAccount.size(), resultsForAccountField.size());
        System.assertEquals(expectedForOpportunity.size(), resultsForOpportunityField.size());

        for(Id thisCaseId : resultsForAccountField.keySet()) {
            System.assert(expectedForAccount.containsKey(thisCaseId));
        }

        for(Id thisCaseId : resultsForOpportunityField.keySet()) {
            System.assert(expectedForOpportunity.containsKey(thisCaseId));
        }
    }

    private static User getTestRunUser() {
        // References one of the methods to get test run user in Figment; most have the same requirements
        return CDdCaseMilestoneTest.getTestRunUser();
    }


    /**
     * @author  Sanidhya Jain L
     * @date    January 2023
     * @description This method will test the query & retrive the data which was not modified from last 180 Days.
     */
    @IsTest
    static void testSelectOpenCasesFromLastSixMonths() {

        System.runAs(getTestRunUser()){
            DateTime lastDate= DateTime.now().addDays(-180);
            Case case1 = new Case();
            case1.Customer_Type__c = 'Merchant';
            case1.CreatedDate = lastDate;
            case1.LastModifiedDate = lastDate;
            case1.Status = 'Open';
            case1.Subject = 'Test';
            case1.Description = 'Test 1';
            case1.RecordTypeId = CDdSchemaUtils.CASE_RT.apiId();
            insert case1;

            test.startTest();
                database.executeBatch(new CloseOpenCaseOfLastSixMonBatch());
            test.stopTest();

            List<case> caseList = new List<Case>([Select id,Status,Description From case Where Status = 'Closed']);
            System.assert(!caseList.isEmpty(), 'Case List should not be Empty');
        }
    }
    @IsTest
    static void testSelectCasesWithMilestonesByRecordTypeAndAccountsAndStatus() {
        Set<Id> accountIds = new Map<Id, Account>([SELECT Id FROM Account WHERE ParentId = null]).keySet();
        Set<Id> caseRecordTypeIds = new Set<Id>{CDdSchemaUtils.CASE_RT.storefrontOnboardingId()};
        Test.startTest();
            Map<Id, Case> results = new Map<Id, Case>(CasesSelector.newInstance().selectCasesWithMilestoneByRecordTypesAndAccountsAndStatus(caseRecordTypeIds, accountIds, CDdMxSxConstants.OB_CASE_OPEN_STATUS));
        Test.stopTest();

        Map<Id, Case> expected = new Map<Id, Case>([SELECT Id FROM Case WHERE AccountId IN :accountIds AND RecordTypeId IN: caseRecordTypeIds AND status IN: CDdMxSxConstants.OB_CASE_OPEN_STATUS]);

        System.assertEquals(expected.size(), results.size());

        for(Id thisCaseId : results.keySet()) {
            System.assert(expected.containsKey(thisCaseId));
        }
    }

    /**
     * @author          Jeegar
     * @description     Test selectCasesByAccountIdAndIssueType
     * @date            Aug 2023
     */
    @IsTest
    static void testselectCasesByAccountIdAndIssueType() {

        Account accountManagementAcct = TDdAccountFactory.createAccount();
        accountManagementAcct.name = 'Account Management Case';
        insert accountManagementAcct;


        List<Case> casesToInsert = TDdCaseFactory.createSolveableSupportCase(3, CDdRecordTypeCase.customer(), accountManagementAcct.id, null);
        // solveable cases creates cases of type Account Management
        // insert casesToInsert;

        DateTime lookbackDateTime = Datetime.now().addHours(-24);
        Set<Id> recordTypeIds = new Set<Id>();
        Set<String> accountManagementIssueTypes = new Set<String>();

        recordTypeIds.add(CDdGenericTriggerOptimizationHelper.supportRecordTypeId);

        accountManagementIssueTypes.add(CDdSupportConstants.CASE_ISSUE_TYPE_ACCOUNT_MANAGEMENT);
        accountManagementIssueTypes.add(CDdSupportConstants.CASE_ISSUE_TYPE_ACCOUNT_MANAGEMENT_CX);
        accountManagementIssueTypes.add(CDdSupportConstants.CASE_ISSUE_TYPE_ACCOUNT_MANAGEMENT_MX);
        accountManagementIssueTypes.add(CDdSupportConstants.CASE_ISSUE_TYPE_ACCOUNT_MANAGEMENT_DX);
        insert casesToInsert;
        Test.startTest();

        List<Case> queriedCases = CasesSelector.newInstance().
        selectCasesByAccountIdAndIssueTypeLastnHours(accountManagementAcct.id, RealTimeAlertsConstants.LAST_N_HOURS, recordTypeIds, accountManagementIssueTypes);

        Test.stopTest();

        List<Case> casesExpected = [SELECT id, accountId, issue_type__c, status
                                        FROM Case
                                        WHERE AccountId = :accountManagementAcct.id
                                            AND createddate > :lookbackDateTime
                                            AND recordTypeId in :recordTypeIds
                                            AND issue_type__c in :accountManagementIssueTypes];

        System.assertEquals(casesExpected.size() , queriedCases.size(), 'Expected ' + casesExpected.size() + ' cases to be returned');
    }

    /**
     * @author  Mahesh Chouhan
     * @date    May 2023
     * @description This method will test the query & retrive cases owned by inactive users
     */
    @IsTest
    static void testSelectOpenCasesWithInactiveOwner() {
        System.runAs(getTestRunUser()){
            Case case1 = new Case();
            case1.Customer_Type__c = 'Merchant';
            case1.Status = 'Open';
            case1.Subject = 'Test';
            case1.Description = 'Test 1';
            case1.Origin = 'Web';
            case1.RecordTypeId = CDdSchemaUtils.CASE_RT.customerId();
            case1.OwnerId = getTestRunUser().Id;
            insert case1;

            test.startTest();
            Database.QueryLocator queryLocator = CasesSelector.newInstance().selectOpenCasesWithInactiveOwner(ProcessInactiveCaseBatch.CASE_ORIGINS);
            test.stopTest();

            String qyery = queryLocator.getQuery();
            Database.QueryLocatorIterator it =  queryLocator.iterator();

            //Iterate over the records
            while (it.hasNext())
            {
                Case cs = (Case)it.next();
                System.assertEquals('Test 1', cs.Subject, 'Case Subject is not same as expected.');
                System.assertEquals('Web', cs.Origin, 'Case Origin is not same as expected.');
                System.assertEquals('Merchant', cs.Customer_Type__c, 'Customer Type is not same as expected.');
            }
        }
    }
    @IsTest
    static void testSelectCasesWithOnboardingIdsAndrecordTypeAndStatus() {
        Set<Id> accountIds = new Map<Id, Account>([SELECT Id FROM Account WHERE ParentId != null]).keySet();
        Set<Id> caseRecordTypeIds = new Set<Id>{CDdMxSxConstants.RECORD_TYPE_ID_CASE_POS_INTEGRATIONS};
        String onboardingId = 'onboardingId001';
        Set<String> onboardingIds = new Set<String>{onboardingId};
        /*Case case1 = new Case();
        case1.Customer_Type__c = 'Merchant';
        case1.Status = 'Open';
        case1.Subject = 'Test';
        case1.Description = 'Test 1';
        case1.Origin = 'Web';
        case1.onboarding_Id__c = onboardingId;
        case1.AccountId = new List<Id>(accountIds)[0];
        case1.RecordTypeId = CDdMxSxConstants.RECORD_TYPE_ID_CASE_POS_INTEGRATIONS;
        case1.POS_Integration_Type__c = 'toast';
        case1.OwnerId = getTestRunUser().Id;
        insert case1;
        Test.startTest();*/

        Map<Id, Case> results = new Map<Id, Case>(CasesSelector.newInstance().selectByOnboardingIdAndrecorTypeAndStatus(onboardingIds, caseRecordTypeIds, CDdMxSxConstants.OB_CASE_OPEN_STATUS));
        /*Test.stopTest();

        Map<Id, Case> expected = new Map<Id, Case>([SELECT Id FROM Case WHERE AccountId IN :accountIds AND RecordTypeId IN: caseRecordTypeIds AND status IN: CDdMxSxConstants.OB_CASE_OPEN_STATUS]);*/

        System.assertEquals(results.size(), 0, 'case count not matching');

        /*for(Id thisCaseId : results.keySet()) {
            System.assert(expected.containsKey(thisCaseId));
        }*/
    }
}