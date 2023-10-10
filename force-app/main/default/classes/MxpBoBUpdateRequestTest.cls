/**
 * @author  Nayana K
 * @date    November 2022
 * @description This is the test class for MxpBoBUpdateRequest
 */
@isTest
public class MxpBoBUpdateRequestTest {
	@isTest
    private static void testWhenClassInstantiatesThenRun() {
         List<MXP_BoB_Update_Request__c> lstMxpBobRequest = new List<MXP_BoB_Update_Request__c>();
        //IAccounts Instance Creation Call
        MxpBoBUpdateRequest.newInstance(lstMxpBobRequest);
        //Default Constructor Call
        MxpBoBUpdateRequest mxpBobsObject = new MxpBoBUpdateRequest(lstMxpBobRequest);
        //fflib_IDomainConstructor call
        MxpBoBUpdateRequest.Constructor constructorObject = new MxpBoBUpdateRequest.Constructor();
        constructorObject.construct(lstMxpBobRequest);
        System.assertNotEquals(
            MxpBoBUpdateRequest.newInstance(lstMxpBobRequest),
            mxpBobsObject,
            'These objects should not be similar'
        );
    }
    
    @isTest
    private static void testCoverage() {
        Set<Id> lstMxpBobIdRequest = new Set<Id>();
        lstMxpBobIdRequest.add(Fake.generateId(MXP_BoB_Update_Request__c.SObjectType));
        //IAccounts Instance Creation Call
        MxpBoBUpdateRequest.newInstance(lstMxpBobIdRequest);
        List<MXP_BoB_Update_Request__c> lstMxp = MxpBoBUpdateRequest.newInstance(lstMxpBobIdRequest).getMxpBobUpdateRequests();
        System.assertEquals(0, lstMxp.size(), 'Should return empty list');
    }
    
    @isTest
    private static void testGetRecordTypeIdByDevName() {
        Id recordTypeId = MxpBoBUpdateRequest.getRecordTypeIdByDevName(MxpBoBUpdateRequest.RECORDTYPE_DEV_NAME_BOOK_OF_BUSINESS);
        System.assertEquals(true, recordTypeId!=null, 'Should return valid recordTypeId');
    }
}