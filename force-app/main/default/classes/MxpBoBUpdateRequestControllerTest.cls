@isTest
public with sharing class MxpBoBUpdateRequestControllerTest {

    @isTest
    static void testWhenGetAdditionalInformationIscAlledThenCallTheMxpBobUpdateRequestService() {
        // Arrange
        Id mockBoBId = Fake.generateId(MXP_BoB_Update_Request__c.SObjectType);

        fflib_ApexMocks mocks = new fflib_ApexMocks();
        // create an instance of fflib_SObjectUnitOfWork class part of apex mock framework.
        IMxpBoBUpdateRequestSelector mockMxpBoBUpdateReqSelector = (IMxpBoBUpdateRequestSelector) mocks.mock(
            IMxpBoBUpdateRequestSelector.class
        );
        IMxpBobUpdateRequestService serviceMock = (IMxpBobUpdateRequestService) mocks.mock(
            IMxpBobUpdateRequestService.class
        );
        mocks.startStubbing();
        mocks.when(mockMxpBoBUpdateReqSelector.sObjectType()).thenReturn(MXP_BoB_Update_Request__c.SObjectType);
        mocks.when(mockMxpBoBUpdateReqSelector.selectByIdExtraFields(new Set<Id>{mockBoBId})).thenReturn(new List<MXP_BoB_Update_Request__c>());
        mocks.when(serviceMock.getAdditionalInformationAboutMxpBobUpdateRequest(mockBoBId)).thenReturn(new List<String>());
		mocks.stopStubbing();

        Application.SELECTOR.setMock(mockMxpBoBUpdateReqSelector);
        Application.SERVICE.setMock(IMxpBobUpdateRequestService.class, serviceMock);

        Test.startTest();
        List<String> retVal = MxpBoBUpdateRequestController.getAdditionalInformation(
            mockBoBId
        );
        Test.stopTest();
        System.assertEquals(
            retVal.size(),
            0,
            'Retval size is not expected'
        );
    }
}