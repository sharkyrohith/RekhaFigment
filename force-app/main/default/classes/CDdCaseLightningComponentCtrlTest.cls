@IsTest
private class CDdCaseLightningComponentCtrlTest {

    private static fflib_ApexMocks mocks {get {
        if(mocks == null) {
            mocks = new fflib_ApexMocks();
        }

        return mocks;
    } set;}

    private static MxSxApexMockTestDataFactory mockDataFactory {get {
        if(mockDataFactory == null) {
            mockDataFactory = new MxSxApexMockTestDataFactory();
        }

        return mockDataFactory;
    } set;}

    private static IAccountsSelector accountsSelectorMock {get {
        if(accountsSelectorMock == null) {
            accountsSelectorMock = (IAccountsSelector) mocks.mock(IAccountsSelector.class);
        }

        return accountsSelectorMock;
    } set;}

    private static ICasesSelector casesSelectorMock {get {
        if(casesSelectorMock == null) {
            casesSelectorMock = (ICasesSelector) mocks.mock(ICasesSelector.class);
        }

        return casesSelectorMock;
    } set;}

    private static Account parentAccount {get {
        if(parentAccount == null) {
            parentAccount = mockDataFactory.parentAccount;
        }

        return parentAccount;
    } set;}

    private static Account childAccount {get {
        if(childAccount == null) {
            childAccount = mockDataFactory.marketplaceAccount;
        }

        return childAccount;
    } set;}

    private static Opportunity marketplaceOpp {get {
        if(marketplaceOpp == null) {
            marketplaceOpp = mockDataFactory.marketplaceOpportunity;
        }

        return marketplaceOpp;
    } set;}

    private static Case storefrontCase {get {
        if(storefrontCase == null) {
            storefrontCase = (Case) new Fake(Case.class)
                                            .setFakeId()
                                            .setField(Case.Opportunity_Name__c, marketplaceOpp.Id)
                                            .setField(Case.RecordTypeId, CDdSchemaUtils.CASE_RT.storefrontOnboardingId())
                                            .setField(Case.AccountId, parentAccount.Id)
                                            .setField(Case.Origin, 'Closed Won Opportunity - SSMO')
                                            .setField(Case.Stage__c, 'Not Started')
                                            .toSObject();
        }

        return storefrontCase;
    } set;}

    private static Case marketplaceCase {get {
        if(marketplaceCase == null) {
            marketplaceCase = (Case) new Fake(Case.class)
                                            .setFakeId()
                                            .setField(Case.Opportunity_Name__c, marketplaceOpp.Id)
                                            .setField(Case.RecordTypeId, CDdSchemaUtils.CASE_RT.marketplaceOnboardingId())
                                            .setField(Case.AccountId, childAccount.Id)
                                            .toSObject();               
        }

        return marketplaceCase;
    } set;}

    @IsTest
    static void testGetSiblingCase() {
        // Mocks
        setupMocksForSiblingCaseRetrieval(parentAccount, childAccount, storefrontCase, marketplaceCase);

        // Call getSiblingCase method
        Test.startTest();
            CDdCaseLightningComponentCtrl.CaseDetailsWrapper marketplaceCaseObj = CDdCaseLightningComponentCtrl.getSiblingCase(storefrontCase.Id);
        Test.stopTest();

        // Marketplace validations
        System.assertNotEquals(null, marketplaceCaseObj.caseToDisplay);
        System.assertEquals(CDdSchemaUtils.CASE_RT.marketplaceOnboardingId(), marketplaceCaseObj.caseToDisplay.RecordTypeId);
        System.assertEquals(0, marketplaceCaseObj.completedMilestones);
        System.assertEquals('Marketplace', marketplaceCaseObj.caseTypeToShow);
    }

    @IsTest
    static void testGetSiblingCaseNullInput() {    
        // Scenario - there's no related AccountId on the Case (bad data)
        storefrontCase.AccountId = null; // Remove the related Account - which is another validation

        setupMocksForSiblingCaseRetrieval(parentAccount, childAccount, storefrontCase, marketplaceCase);

        // Verify a null return value
        CDdCaseLightningComponentCtrl.CaseDetailsWrapper marketplaceCaseObj = CDdCaseLightningComponentCtrl.getSiblingCase(storefrontCase.Id);
        System.assertEquals(null, marketplaceCaseObj);

        // Scenario - we don't have a matching Case. Modify the mock to return an empty list.
        mocks.startStubbing();
            mocks.when(casesSelectorMock.selectCasesByIdsWithParentAccountInfo(new Set<Id>{storefrontCase.Id})).thenReturn(new List<Case>());
        mocks.stopStubbing();

        // Verify another null return value
        marketplaceCaseObj = CDdCaseLightningComponentCtrl.getSiblingCase(storefrontCase.Id);
        System.assertEquals(null, marketplaceCaseObj);

        // Scenario - null object returned for matchingCases - exception thrown
        // Reset data
        storefrontCase.AccountId = parentAccount.Id;
        mocks.startStubbing();
            mocks.when(casesSelectorMock.selectCasesByIdsWithParentAccountInfo(new Set<Id>{storefrontCase.Id})).thenReturn(new List<Case>{storefrontCase});
            mocks.when(casesSelectorMock.selectCasesWithMilestonesByRecordTypeAndAccount(CDdSchemaUtils.CASE_RT.marketplaceOnboardingId(), new Set<Id>{childAccount.Id})).thenReturn(null);
        mocks.stopStubbing();

        Boolean exceptionThrown = false;

        try {
            marketplaceCaseObj = CDdCaseLightningComponentCtrl.getSiblingCase(storefrontCase.Id);
        } catch(AuraHandledException ex) {
            exceptionThrown = true;
        }

        System.assertEquals(null, marketplaceCaseObj);
        System.assert(exceptionThrown, 'An exception should have been thrown due to the null matchingCases object returned in getSiblingCase()');
    }

    /**
        @author: Dan Thoreson
        @date: 07-Nov-2022
        @description: Helper method to set up the Mocks and Selectors
    **/
    private static void setupMocksForSiblingCaseRetrieval(Account parent, Account child, Case storefront, Case marketplace) {
        mocks.startStubbing();
            mocks.when(casesSelectorMock.sObjectType()).thenReturn(Case.SObjectType);
            mocks.when(casesSelectorMock.selectCasesByIdsWithParentAccountInfo(new Set<Id>{storefront.Id})).thenReturn(new List<Case>{storefront});
            mocks.when(casesSelectorMock.selectCasesWithMilestonesByRecordTypeAndAccount(CDdSchemaUtils.CASE_RT.marketplaceOnboardingId(), new Set<Id>{child.Id})).thenReturn(new List<Case>{marketplace});
            
            mocks.when(accountsSelectorMock.sObjectType()).thenReturn(Account.SObjectType);
            mocks.when(accountsSelectorMock.selectAccountsForParent(parent.Id)).thenReturn(new List<Account>{child});
        mocks.stopStubbing();

        Application.Selector.setMock(casesSelectorMock);
        Application.Selector.setMock(accountsSelectorMock);
    }
}