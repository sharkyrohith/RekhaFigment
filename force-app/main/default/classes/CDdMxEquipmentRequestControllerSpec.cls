/********************************************************************************************************************
* @author Praveen Pandem
* @date 11/07/2022
*
* @group fflib
*
* @description Apex test class for CDdMxEquipmentRequestController
* 
**************************************************************************************************************************************/

@isTest
public class CDdMxEquipmentRequestControllerSpec {

    private static fflib_ApexMocks mocks {get {
        if(mocks == null) {
            mocks = new fflib_ApexMocks();
        }
        return mocks;
    } set;}
    /**
    *@description Initializes the common class MxSxApexMockTestDataFactory to mock mx related object records.
    */
    private static MxSxApexMockTestDataFactory mockTestDataFactory {get {
        if(mockTestDataFactory == null) {
            mockTestDataFactory = new MxSxApexMockTestDataFactory();
        }
        return mockTestDataFactory;
    } set;} 
    /**
    *@description mock opportunity using common class MxSxApexMockTestDataFactory.
    */
    private static Opportunity marketplaceOpportunity {get {
        if(marketplaceOpportunity == null) {
            marketplaceOpportunity = mockTestDataFactory.marketplaceOpportunity;
        }
        return marketplaceOpportunity;
    } set;}
    /**
    *@description mock marketplaceAccount using common class MxSxApexMockTestDataFactory.
    */
    private static Account marketPlaceAccount {get {
        if(marketPlaceAccount == null) {
            marketPlaceAccount = mockTestDataFactory.marketplaceAccount;
        }
        return marketPlaceAccount;
    } set;}   
    /**
    *@description test method for CDdMxEquipmentRequestController.getOpportunities.
    *tesing for getOpportunities by accountIds.
    */   
    @isTest
    private static void testWhenInputAccountIdsToGetOpportunties() {
        // Given mock Selector
        IOpportunitiesSelector mockOpportunitiesSelector = (IOpportunitiesSelector) mocks.mock(OpportunitiesSelector.class);
        // Given mocks response
        List<Opportunity> mockOpportunities =  new List<Opportunity>{ marketplaceOpportunity};
        mocks.startStubbing();
        mocks.when(mockOpportunitiesSelector.sObjectType()).thenReturn(Opportunity.SObjectType);
        mocks.when(mockOpportunitiesSelector.getOpportunitiesByAccountIds(new Set<Id>{marketPlaceAccount.Id})).thenReturn(mockOpportunities);
        mocks.stopStubbing();
        Application.Selector.setMock(mockOpportunitiesSelector);
        List<CDdMxEquipmentLookupSearchModel> searchResult = CDdMxEquipmentRequestController.getOpportunities('',String.valueof(marketPlaceAccount.Id));       
        System.assert(searchResult.size()==1, 'Expecting search result size as 1 ');
        System.assert(mockOpportunities[0].Id == searchResult[0].Id, 'Opportunity Id should match with the result ');
    }
    /**
    *@description test method for CDdMxEquipmentRequestController.getOpportunities.
    *tesing for getOpportunities by accountid and search by name and accountds.
    */   
    @isTest
    private static void testWhenInputSearchTermAndAccountIdsToSearchForOpportunities() {
        // Given mock Selector
        IOpportunitiesSelector mockOpportunitiesSelector = (IOpportunitiesSelector) mocks.mock(OpportunitiesSelector.class);
        // Given mocks response
        List<Opportunity> mockOpportunities =  new List<Opportunity>{ marketplaceOpportunity};
        List<SObject> castRecords = (List<SObject>)mockOpportunities;
        List<List<sObject>> searchResultOpps = new List<List<sObject>>{castRecords};

        mocks.startStubbing();
        mocks.when(mockOpportunitiesSelector.sObjectType()).thenReturn(Opportunity.SObjectType);
        mocks.when(mockOpportunitiesSelector.searchOpportunitiesBysearchTermAndAccountIds('Test', new Set<Id>{marketPlaceAccount.Id})).thenReturn(searchResultOpps);
        mocks.stopStubbing();
        Application.Selector.setMock(mockOpportunitiesSelector);
        List<CDdMxEquipmentLookupSearchModel> searchResult = CDdMxEquipmentRequestController.getOpportunities('Test', String.valueof(marketPlaceAccount.Id));       
        System.assert(searchResult.size()==1, 'Expecting search result size as 1 ');
        System.assert(mockOpportunities[0].Id == searchResult[0].Id, 'Opportunity Id should match with the result ');
    }
    /**
    *@description mock marketplaceAccount using common class MxSxApexMockTestDataFactory.
    */
    @isTest
    private static void testgetOpportunitiesMethodWhenExceptionThrown() {
        IOpportunitiesSelector mockOpportunitiesSelector = (IOpportunitiesSelector) mocks.mock(OpportunitiesSelector.class);
        Account marketPlaceAccount = mockTestDataFactory.marketplaceAccount;
        // Given mocks response
        fflib_ISObjectUnitOfWork mockUOW = (fflib_ISObjectUnitOfWork) mocks.mock(
            fflib_ISObjectUnitOfWork.class
        );
        mocks.startStubbing();
        mocks.when(mockOpportunitiesSelector.sObjectType()).thenReturn(Opportunity.SObjectType);
        ((IOpportunitiesSelector) mocks.doThrowWhen(
            new applicationException('Exception occurred while querying opportunities'),
            mockOpportunitiesSelector
            )).searchOpportunitiesBysearchTermAndAccountIds('Test Exception', new Set<Id>{marketPlaceAccount.Id});
        mocks.stopStubbing();
        Application.Selector.setMock(mockOpportunitiesSelector);
        Application.UNITOFWORK.setMock(mockUOW);
        Boolean exceptionsThrown = false;
        try{
            CDdMxEquipmentRequestController.getOpportunities('Test Exception',string.valueof(marketPlaceAccount.Id));
        }catch(Exception ex){
            exceptionsThrown =true;
        }
        system.assert(exceptionsThrown, 'Exception should be thrown while querying opportunities');
    }
    /**
    *@description inner class defined to throw the application exception. 
    */
    private class ApplicationException extends Exception {}
}