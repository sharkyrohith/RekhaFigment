public inherited sharing class MxpBoBUpdateRequest extends fflib_SObjects implements IMxpBoBUpdateRequest {

    //Record type Dev Name
    public static final String RECORDTYPE_DEV_NAME_TRANSFER_SINGLE_BUSINESSID = 'Transfer_Single_Business_ID';
    public static final String RECORDTYPE_DEV_NAME_BOOK_OF_BUSINESS = 'Book_of_Business_Transfer_request';
    public static final String RECORDTYPE_DEV_NAME_NEW_MERCHANT_BOB = 'New_Business_Store_Needs_MXP_Assigned';
    public static final String RECORDTYPE_DEV_NAME_REDUCE_MXP_BOB = 'Reduce_MXP_BoB';
    public static final String RECORDTYPE_DEV_NAME_INCREASE_MXP_BOB = 'Increase_MXP_BoB';

    public static final String ACCOUNT_TEAM_MEMBER_SOURCE = 'Salesforce';

    public static IMxpBoBUpdateRequest newInstance(List<MXP_BoB_Update_Request__c> recordList) {
        return (IMxpBoBUpdateRequest) Application.Domain.newInstance(recordList);
    }

    public static IMxpBoBUpdateRequest newInstance(Set<Id> recordIdSet) {
        return (IMxpBoBUpdateRequest) Application.Domain.newInstance(recordIdSet);
    }

    public MxpBoBUpdateRequest(List<MXP_BoB_Update_Request__c> sObjectList) {
        super(sObjectList, Schema.MXP_BoB_Update_Request__c.SObjectType);
    }

    public List<MXP_BoB_Update_Request__c> getMxpBobUpdateRequests() {
        return (List<MXP_BoB_Update_Request__c>) getRecords();
    }


    public class Constructor implements fflib_IDomainConstructor {
        public fflib_SObjects construct(List<Object> objectList) {
            return new MxpBoBUpdateRequest
            ((List<SObject>) objectList);
        }
    }

    private static Map<String, RecordTypeInfo> RECORDTYPEINFO;
    public static Id getRecordTypeIdByDevName(String name) {
        if (RECORDTYPEINFO == null) {
            RECORDTYPEINFO = Schema.SObjectType.MXP_BoB_Update_Request__c.getRecordTypeInfosByDeveloperName();
        }
        return RECORDTYPEINFO.get(name).getRecordTypeId();
    }
}