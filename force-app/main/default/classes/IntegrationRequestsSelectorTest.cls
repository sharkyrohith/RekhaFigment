/********************************************************************************************************************
* @author Praveen
* @date 1/17/2023
*
* @group Merchant Services
*
* @description test class for IntegrationRequestsSelector.
* 
**************************************************************************************************************************************/


@IsTest
public with sharing class IntegrationRequestsSelectorTest {
    public static fflib_ApexMocks mocks {get {
        if(mocks == null) {
            mocks = new fflib_ApexMocks();
        }
        return mocks;
    } set;}
    /**
    *@description Initializes the common class MxSxApexMockTestDataFactory to mock mx related object records.
    */
    public static MxSxApexMockTestDataFactory mockTestDataFactory {get {
        if(mockTestDataFactory == null) {
            mockTestDataFactory = new MxSxApexMockTestDataFactory();
        }
        return mockTestDataFactory;
    } set;}
     /**
    *@description mock IntegrationRequests using common class MxSxApexMockTestDataFactory.
    */
    public static List<Integration_Request__x> integrationRequest{get {
        if(integrationRequest == null) {
            integrationRequest = mockTestDataFactory.posIntegrationRequests;
        }
        return integrationRequest;
    } set;}
     /**
     * @description To test Contructor instantiation.
     */
    @isTest
    private static void testWhenClassInstantiatesThenCheckSObjectTypeAndFieldList() {
        SObjectField[] expectedTokens = new SObjectField[]{
            Integration_Request__x.Id,
            Integration_Request__x.Store_Id__c,
            Integration_Request__x.Sfdc_status__c,
            Integration_Request__x.Sfdc_Org__c,
            Integration_Request__x.Onboarding_Id__c,
            Integration_Request__x.Integration_Provider__c,
            Integration_Request__x.Integration_Id__c,
            Integration_Request__x.Business_Id__c,
            Integration_Request__x.Previous_Integration_ID__c,
            Integration_Request__x.Previous_Integration_Provider__c,
            Integration_Request__x.Notes__c,
            Integration_Request__x.Activation_Date__c,
            Integration_Request__x.Onboarding_Type__c,   
            Integration_Request__x.Decision_Maker_Email__c,
            Integration_Request__x.Provider_Account_Owner_Email__c, 
            Integration_Request__x.Request_Owner_Email__c,
            Integration_Request__x.Action__c,
            Integration_Request__x.Exclusion_Code__c,
            Integration_Request__x.Target_Status__c,
            Integration_Request__x.Error_Message__c,
            Integration_Request__x.Integration_Type__c
        };

        SObjectField[] actualTokens = new IntegrationRequestsSelector().getSObjectFieldList();
        System.assertEquals(
            expectedTokens,
            actualTokens,
            'Received an unexpected list of SObjectField tokens.  Expected: ' + expectedTokens + ' Received: ' + actualTokens
        );
    }
    /**
    *@description test method for getIntegrationRequestsByStatusAndOrg and selectById. 
    */
    @IsTest
    public static void testSelectWhenGetIntgrationRequestsByStatusAndOrg() {
        IIntegrationRequestsSelector mockIntegrationSelector = (IIntegrationRequestsSelector) mocks.mock(IntegrationRequestsSelector.class);
        // Given mocks response
        Set<String> status = new Set<String>{CDdMxSxConstants.POS_INTEGRATION_REQUESTS_STATUS_PENDING};
        Set<String> sfdcOrg = new Set<String>{CDdMxSxConstants.POS_INTEGRATION_REQUESTS_ORG_FIGMENT};
        CDdMxIntegrationObject Requests = new CDdMxIntegrationObject(IntegrationRequest);
        Set<Id> RequstsId = new Set<Id>{IntegrationRequest[0].Id};
        IntegrationRequestsSelector.newInstance().selectIntegrationRequestsByStatusAndOrg(status, sfdcOrg, 5);      
        mocks.startStubbing();
        mocks.when(mockIntegrationSelector.sObjectType()).thenReturn(Integration_Request__x.SObjectType);
        mocks.when(mockIntegrationSelector.selectIntegrationRequestsByStatusAndOrg(status, sfdcOrg, 5)).thenReturn(Requests);
        mocks.when(mockIntegrationSelector.selectById(RequstsId)).thenReturn(Requests);
        mocks.stopStubbing();
        Application.Selector.setMock(mockIntegrationSelector);
        CDdMxIntegrationObject IntegrationRequest = IntegrationRequestsSelector.newInstance().selectIntegrationRequestsByStatusAndOrg(status, sfdcOrg, 5);      
        System.assert(IntegrationRequest.IntegrationRequests.size()==1, 'Expecting integration requests result size as 1 ');
        CDdMxIntegrationObject IntegrationRequestbyId = IntegrationRequestsSelector.newInstance().selectById(RequstsId);   
        System.assert(IntegrationRequestbyId.IntegrationRequests.size()==1, 'Expecting integration requests result size as 1 for selectById method');
    }
    /**
    *@description test method for getIntegrationRequestsByonboardingIds.
    */
    @IsTest
    public static void testSelectWhenGetIntgrationRequestsByonboardingIds() {
        IIntegrationRequestsSelector mockIntegrationSelector = (IIntegrationRequestsSelector) mocks.mock(IntegrationRequestsSelector.class);
        // Given mocks response
        CDdMxIntegrationObject Requests = new CDdMxIntegrationObject(IntegrationRequest);
        Set<String> onboardingIds = new Set<String>{IntegrationRequest[0].onboarding_Id__c};
        IntegrationRequestsSelector.newInstance().selectIntegrationRequestsByOnboardingIds(onboardingIds);
        mocks.startStubbing();
        mocks.when(mockIntegrationSelector.sObjectType()).thenReturn(Integration_Request__x.SObjectType);
        mocks.when(mockIntegrationSelector.selectIntegrationRequestsByOnboardingIds(onboardingIds)).thenReturn(Requests);
        mocks.stopStubbing();
        Application.Selector.setMock(mockIntegrationSelector);
        CDdMxIntegrationObject IntegrationRequest = IntegrationRequestsSelector.newInstance().selectIntegrationRequestsByOnboardingIds(onboardingIds);
        System.assert(IntegrationRequest.IntegrationRequests.size()==1, 'Expecting integration requests result size as 1 ');
    }
}