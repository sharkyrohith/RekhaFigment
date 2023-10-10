/***
 * Author : Sugan
 * Date : Feb 11th 2023
 * Description : Test class for the tools admin api framework - includes test code for
 * CDdChargeBackSubmissionCallout, CDdToolsAdminCallout
 */
@isTest
public with sharing class CDdToolsAdminFrameworkTest {
    @isTest
    static void testCaseShouldBeClosedIfChargeBackAutomationIsSuccess(){
        // Given an instance of ApexMocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        // Given an instance of a mock UnitOfWork class
        fflib_SObjectUnitOfWork mockUow = (fflib_SObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);
        // Given mock instance injected into the fflib factories
        Application.UnitOfWork.setMock(mockUow);

        //set test context boolea
        EmailGeneratorServiceImpl.isTestContext = true;

        // Given mock data
        List<Case> newList = new List<Case>();
        Id caseId = Fake.generateId(Case.SObjectType);
        Id QUEUE_MX_PARKING_Id = CDdGenericTriggerOptimizationHelper.getQueueIdByName(CDdCaseTriggerHelperV2.QUEUE_MX_PARKING);
        Id supportRecordTypeId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeIdByDevName(CDdSupportConstants.RECORDTYPE_NAME_CUSTOMER);
        Case mockCase = new Case(Id = caseId);
        mockCase.OwnerId = QUEUE_MX_PARKING_Id;
        mockCase.Origin = 'Web';
        mockCase.Customer_type__c = 'Merchant';
        mockCase.Formstack_Source__c = 'Support Request - Mx Portal';
        mockCase.Formstack_Subcategory__c = 'Error Charge Disputes';
        mockCase.Description = 'Payments - Error Charge Disputes \n  2134324 \n test \n Contact Name:  SUGAN KARTHIK KANNAKUMAR \n Contact Email:  test@test.com \n Contact Phone:  9706914073 \n Error Charge Amount: 12321 \n';
        mockCase.Delivery_UUID_8_Digit__c = '12345678';
        mockCase.RecordTypeID = supportRecordTypeId;
        mockCase.status = 'Open';
        newList.add(mockCase);

        Test.setMock(HttpCalloutMock.class, new CddToolsAdminCalloutMockImpl('chargebacksubmission','SUCCESS_RESPONSE'));

        List<CDdRestJSONObj.ChargeBackSubmission> chbReq = CddcaseTriggerHelperV2.prepareChargeBackSubmissionRecords(newList);
        //since we are mocking the callouts - we can do a synchronous test instead of any asynchronous one
        String actionName = 'ChargeBackSubmission_EC_Dispute';
        Tools_Admin_API__mdt actionApiDetails = [Select Id,Child_Class_name__c, DeveloperName, Label, Path__c, Method__c,(Select Id, Response_Status_Code__c, Response_Message_key__c, Fields_To_Update__c, Email_Template_Name__c, MasterLabel from Tools_Admin_API_actions__r)  from Tools_Admin_API__mdt where DeveloperName = :actionName];
        CDdToolsAdminCallout toolAdminCallout = (CDdToolsAdminCallout)Type.forName(actionApiDetails.Child_Class_name__c).newInstance();

        //replicating the method callout from trigger / queueable job
        try{
            /*we set the success id in advance as there is no actual DML performed and
            some of the functionality depends on the DML to succeed */
            CDdToolsAdminCallout.toolsAdminDMLHandler.successIds.add(caseId);
            toolAdminCallout.makeCall(actionApiDetails,chbReq);
        }catch(Exception err){
            system.assert(false,'The chargeback automation mock failed');
        }


        ((fflib_ISObjectUnitOfWork) mocks.verify(mockUow, 1)).commitWork();

        //verifying that the case status was set to be closed via uow mock
        ((fflib_ISObjectUnitOfWork) mocks.verify(mockUow))
            .registerDirty(
            fflib_Match.sObjectWith(
                new Map<SObjectField, Object>{
                    Case.Id => caseId,
                    Case.Status => 'Closed'
                }
        ));
    }

    @isTest
    static void testToIncreaseCoverage(){
        List<Case> dummyList = new list<Case>();
        EmailGeneratorServiceImpl.isTestContext = true;
        CDdCaseTriggerHelperV2.mxChargebackProcessing(dummyList);

        List<CDdRestJSONObj.ChargeBackSubmission> dummyChbReq = new List<CDdRestJSONObj.ChargeBackSubmission>();
        Test.startTest();
            System.enqueueJob(new CDdToolsAdminCalloutQueuable('ChargeBackSubmission_EC_Dispute',dummyChbReq));
        Test.stopTest();

        String testErrorMessage = 'Test Error Message';
        List<String> errMsgs = new List<String>{'Tools admin automation error: '+testErrorMessage};
        Database.SaveResult sr = (Database.SaveResult)JSON.deserialize('{"success":false,"errors":[{"message":"'+testErrorMessage+'","statusCode":"FIELD_CUSTOM_VALIDATION_EXCEPTION"}]}', Database.SaveResult.class);
        Database.SaveResult[] results = new Database.SaveResult[]{sr};
        CDdToolsAdminCallout.toolsAdminDMLHandler.handle(results);

        System.assertEquals(errMsgs, CDdToolsAdminCallout.toolsAdminDMLHandler.errorMessages, 'Error message not geenrated as expected');
    }

    @isTest
    static void testCDdChargeBackSubmissionCalloutDirectly(){
        // Given an instance of ApexMocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        // Given an instance of a mock UnitOfWork class
        fflib_SObjectUnitOfWork mockUow = (fflib_SObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);
        // Given mock instance injected into the fflib factories
        Application.UnitOfWork.setMock(mockUow);

        //set test context boolea
        EmailGeneratorServiceImpl.isTestContext = true;

        // Given mock data
        List<Case> newList = new List<Case>();
        Id caseId = Fake.generateId(Case.SObjectType);
        Id QUEUE_MX_PARKING_Id = CDdGenericTriggerOptimizationHelper.getQueueIdByName(CDdCaseTriggerHelperV2.QUEUE_MX_PARKING);
        Id supportRecordTypeId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeIdByDevName(CDdSupportConstants.RECORDTYPE_NAME_CUSTOMER);
        Case mockCase = new Case(Id = caseId);
        mockCase.OwnerId = QUEUE_MX_PARKING_Id;
        mockCase.Origin = 'Web';
        mockCase.Customer_type__c = 'Merchant';
        mockCase.Formstack_Source__c = 'Support Request - Mx Portal';
        mockCase.Formstack_Subcategory__c = 'Error Charge Disputes';
        mockCase.Description = 'Payments - Error Charge Disputes \n  2134324 \n test \n Contact Name:  SUGAN KARTHIK KANNAKUMAR \n Contact Email:  test@test.com \n Contact Phone:  9706914073 \n Error Charge Amount: 12321 \n';
        mockCase.Delivery_UUID_8_Digit__c = '12345678';
        mockCase.RecordTypeID = supportRecordTypeId;
        mockCase.status = 'Open';
        newList.add(mockCase);

        Test.setMock(HttpCalloutMock.class, new CddToolsAdminCalloutMockImpl('chargebacksubmission','SUCCESS_RESPONSE'));

        List<CDdRestJSONObj.ChargeBackSubmission> chbReq = CddcaseTriggerHelperV2.prepareChargeBackSubmissionRecords(newList);
        //since we are mocking the callouts - we can do a synchronous test instead of any asynchronous one
        String actionName = 'ChargeBackSubmission_EC_Dispute';
        Tools_Admin_API__mdt actionApiDetails = [Select Id,Child_Class_name__c, DeveloperName, Label, Path__c, Method__c,(Select Id, Response_Status_Code__c, Response_Message_key__c, Fields_To_Update__c, Email_Template_Name__c, MasterLabel from Tools_Admin_API_actions__r)  from Tools_Admin_API__mdt where DeveloperName = :actionName];

        //replicating the method callout from trigger / queueable job
        try{
            /*we set the success id in advance as there is no actual DML performed and
            some of the functionality depends on the DML to succeed */
            CDdToolsAdminCallout.toolsAdminDMLHandler.successIds.add(caseId);
            new CDdChargeBackSubmissionCallout().makeCall(actionApiDetails,chbReq);
        }catch(Exception err){
            system.assert(false,'The chargeback automation mock failed');
        }


        ((fflib_ISObjectUnitOfWork) mocks.verify(mockUow, 1)).commitWork();

        //verifying that the case status was set to be closed via uow mock
        ((fflib_ISObjectUnitOfWork) mocks.verify(mockUow))
            .registerDirty(
            fflib_Match.sObjectWith(
                new Map<SObjectField, Object>{
                    Case.Id => caseId,
                    Case.Status => 'Closed'
                }
        ));
    }

}