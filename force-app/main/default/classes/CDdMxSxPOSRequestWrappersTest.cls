/**
    @author: Dan Thoreson
    @date: 20-Jan-2023
    @group: Mx Services
    @description: Test class for CDdMxSxPOSRequestWrappers
**/
@IsTest
private class CDdMxSxPOSRequestWrappersTest {

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

    private static ICasesSelector casesSelectorMock {get {
        if(casesSelectorMock == null) {
            casesSelectorMock = (ICasesSelector) mocks.mock(ICasesSelector.class);
        }

        return casesSelectorMock;
    } set;}

    @IsTest
    static void testMarketplaceCasesByOpportunityIds() {
        CDdMxSxPOSRequestWrappers.setMarketplaceOpportunityIdsForCaseRetrieval(new Set<Id>{ mockDataFactory.marketplaceOpportunity.Id });

        mocks.startStubbing();
            mocks.when(casesSelectorMock.sObjectType()).thenReturn(Case.SObjectType);
            mocks.when(casesSelectorMock.selectCasesWithMilestonesByRecordTypeAndGenericParent(CDdSchemaUtils.CASE_RT.marketplaceOnboardingId(), 'Opportunity_Name__c', new Set<Id>{ mockDataFactory.marketplaceOpportunity.Id })).thenReturn(new List<Case>{ mockDataFactory.marketplaceOnboardingCase });
        mocks.stopStubbing();

        Application.Selector.setMock(casesSelectorMock);

        System.assert(CDdMxSxPOSRequestWrappers.marketplaceCasesByOpportunityIds.containsKey(mockDataFactory.marketplaceOpportunity.Id));
        System.assertEquals(mockDataFactory.marketplaceOnboardingCase.Id, CDdMxSxPOSRequestWrappers.marketplaceCasesByOpportunityIds.get(mockDataFactory.marketplaceOpportunity.Id).Id);
    }

    @IsTest
    static void testPosRequestObject() {
        IOpportunitiesSelector oppsSelectorMock = (IOpportunitiesSelector) mocks.mock(IOpportunitiesSelector.class);

        Set<String> extraFields = new Set<String>{
            'Order_Protocol__c',
            'Store_ID__c',
            'POS_Integration_Type__c',
            'POS_Integration_ID__c',
            'Opportunity_Account_Name__c',
            'Notes__c',
            'Decision_Maker__c',
            'Proposed_Date_of_Activation__c',
            'POS_Fallback_Protocol__c',
            'CreatedById'
        };

        mocks.startStubbing();
            mocks.when(oppsSelectorMock.sObjectType()).thenReturn(Opportunity.SObjectType);
            mocks.when(oppsSelectorMock.selectByIdExtraFields(new Set<Id>{ mockDataFactory.marketplaceOpportunity.Id }, extraFields)).thenReturn(new List<Opportunity>{ mockDataFactory.marketplaceOpportunity });
        mocks.stopStubbing();

        Application.Selector.setMock(oppsSelectorMock);


        CDdMxSxPOSRequestWrappers.setOpportunityIdsAndMarketplaceCaseIds(new List<Case>{ mockDataFactory.marketplaceOnboardingCase });
        CDdMxSxPOSRequestWrappers.POSRequest posReqObj = new CDdMxSxPOSRequestWrappers.POSRequest(mockDataFactory.marketplaceOnboardingCase);

        System.assertEquals(mockDataFactory.marketplaceOpportunity.Id, posReqObj.sourceOpportunity.Id, 'The sourceOpportunity should be set to the input Opportunity.');
        System.assertEquals(mockDataFactory.marketplaceOnboardingCase.Id, posReqObj.marketplaceOnboardingCase.Id, 'The marketplaceOnboardingCase should be set to the input Case.');
        System.assert(posReqObj.actionDetails != null, 'actionDetails should be set for the POSRequest, indicating which action(s) to perform.');
        System.assert(posReqObj.actionDetails instanceof CDdMxSxPOSRequestWrappers.POSCaseCreationDetails, 'The actionDetails in this instance should be a `createPOSCase` type');
        System.assertEquals(CDdMxSxPOSRequestWrappers.RequestType.OPPORTUNITY_CLOSE_WON, posReqObj.reqType, 'This "Request Type" is an Opportunity C/W event.');
        System.assert(posReqObj.createPOSCase, 'createPOSCase should be set to true');
        System.assert(!posReqObj.updateExistingCaseToDead, 'Other Booleans besides createPOSCase should be false.');
        System.assert(!posReqObj.updateExistingCaseLocationId, 'Other Booleans besides createPOSCase should be false.');
        System.assert(!posReqObj.updateOpportunity, 'Other Booleans besides createPOSCase should be false.');
    }

}