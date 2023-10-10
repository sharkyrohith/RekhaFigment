/**
 * @author Mahesh Chouhan
 * @date Nov 2022
 * @description Test class for controller of lwcDdAudienceInfo Lightning Web Component
 */

@isTest
public class CDdAudienceInfoControllerTest {
    private static final String MOCK_EXCEPTION_MESSAGE = 'Exception occurred while querying records';

    /**
     * @description Test method for getAudienceInfo method
     */
    static testMethod void testGetAudienceInfo(){
        Id caseId = Fake.generateId(Case.SObjectType);

        Case caseRecord = (Case) new Fake(Case.class)
            .setField(Case.Id, caseId)
            .setField(Case.DispatchRQResponse__c, VTestUtil.ERS_DISPATCH_DELIVERY_MESSAGE)
            .toSObject();
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        ICasesSelector caseSelectorMock = (ICasesSelector) mocks.mock(
            ICasesSelector.class
        );

        mocks.startStubbing();
        mocks.when(caseSelectorMock.sObjectType()).thenReturn(Case.SObjectType);
        mocks.when(caseSelectorMock.selectById(new Set<Id>{caseId}, new Set<String>{'DispatchRQResponse__c'}))
            .thenReturn(new List<Case>{caseRecord});
        mocks.stopStubbing();

        Application.Selector.setMock(caseSelectorMock);

        List<CDdAudienceInfoController.AudienceInfo> audienceInfoList = CDdAudienceInfoController.getAudienceInfo(caseId);
        System.assert(audienceInfoList.size() > 0, 'No Audience Info returned');
    }

    /**
     * @description Test method for getAudienceInfo method with Exception
     */
    static testMethod void testGetAudienceInfoWithException(){
        Id caseId = Fake.generateId(Case.SObjectType);

        Case caseRecord = (Case) new Fake(Case.class)
            .setField(Case.Id, caseId)
            .setField(Case.DispatchRQResponse__c, VTestUtil.ERS_DISPATCH_DELIVERY_MESSAGE)
            .toSObject();
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        ICasesSelector caseSelectorMock = (ICasesSelector) mocks.mock(
            ICasesSelector.class
        );

        mocks.startStubbing();
        mocks.when(caseSelectorMock.sObjectType()).thenReturn(Case.SObjectType);
        mocks.when(caseSelectorMock.selectById(new Set<Id>{caseId}, new Set<String>{'DispatchRQResponse__c'}))
            .thenThrow(new TestException(MOCK_EXCEPTION_MESSAGE));
        mocks.stopStubbing();

        Application.Selector.setMock(caseSelectorMock);

        Boolean isExceptionFound;
        try{
            CDdAudienceInfoController.getAudienceInfo(caseId);
        }
        catch(Exception ex){
            isExceptionFound = true;
        }
        System.assert(isExceptionFound, 'Exception must be fired.');
    }

    /**
     * @author Mahesh Chouhan
     * @date Nov 2022
     * @description Exception class for customizing exception for Tests.
     */
    class TestException extends Exception {
    }
}