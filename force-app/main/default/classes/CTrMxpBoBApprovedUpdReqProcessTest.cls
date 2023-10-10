@isTest
public class CTrMxpBoBApprovedUpdReqProcessTest {
	@IsTest
    static void testRecordProcessingPostApprovalSynch(){
        Id mockAccountId = Fake.generateId(Account.SObjectType);

        User fakeUser = (User) new Fake(User.class)
        .setFakeId()
        .toSObject();

        Id tferSingleBusinessId = MxpBoBUpdateRequest.getRecordTypeIdByDevName(MxpBoBUpdateRequest.RECORDTYPE_DEV_NAME_NEW_MERCHANT_BOB);
        Id mockBoBId = Fake.generateId(MXP_BoB_Update_Request__c.SObjectType);
        List<MXP_BoB_Update_Request__c> recList = new List<MXP_BoB_Update_Request__c>{
            (MXP_BoB_Update_Request__c) new Fake(MXP_BoB_Update_Request__c.class)
                .setField(MXP_BoB_Update_Request__c.Id, mockBoBId)
                .setField(MXP_BoB_Update_Request__c.RecordTypeId, tferSingleBusinessId)
                .setField(MXP_BoB_Update_Request__c.Merchant__c, mockAccountId)
                .setField(MXP_BoB_Update_Request__c.Business_Id__c, 1234)
                .setField(MXP_BoB_Update_Request__c.Store_Id__c, 4567)
                .setField(MXP_BoB_Update_Request__c.New_MXP__c, fakeUser.Id)
                .setField(MXP_BoB_Update_Request__c.Status__c,'Approved')
                .toSObject()
        };

        Map<Id,MXP_BoB_Update_Request__c> recOldMap = new Map<Id,MXP_BoB_Update_Request__c>{
            mockBoBId => (MXP_BoB_Update_Request__c) new Fake(MXP_BoB_Update_Request__c.class)
                .setField(MXP_BoB_Update_Request__c.Id, mockBoBId)
                .setField(MXP_BoB_Update_Request__c.RecordTypeId, tferSingleBusinessId)
                .setField(MXP_BoB_Update_Request__c.Merchant__c, mockAccountId)
                .setField(MXP_BoB_Update_Request__c.Business_Id__c, 1234)
                .setField(MXP_BoB_Update_Request__c.Store_Id__c, 4567)
                .setField(MXP_BoB_Update_Request__c.New_MXP__c, fakeUser.Id)
                .setField(MXP_BoB_Update_Request__c.Status__c,'Pending Approval')
                .toSObject()
        };

        // create an instance of fflib_ApexMocks class part of apex mock framework.
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IUsersSelector usersSelector = (IUsersSelector) mocks.mock( IUsersSelector.class );

        mocks.startStubbing();
        mocks.when( usersSelector.sObjectType() ).thenReturn( Schema.User.SObjectType );
        mocks.when( usersSelector.selectById( new Set<Id>{ fakeUser.Id } ) ).thenReturn( new List<User>{ fakeUser } );
		mocks.stopStubbing();

        Application.Selector.setMock( usersSelector );

        CTrMxpBoBApprovedUpdReqProcess cls = new CTrMxpBoBApprovedUpdReqProcess();
        cls.setTriggerContext('after update',true);
        cls.setMockTriggerList(recList);
        cls.setMockTriggerOldMap(recOldMap);

        cls.processApprovedTransferRecords();

        System.assert(recList[0].hasErrors() == false,'No Error found');
    }
    
    @IsTest
    static void testRecordProcessingPostApprovalAsynch(){
        Id mockAccountId = Fake.generateId(Account.SObjectType);
        
        Id tferSingleBusinessId = MxpBoBUpdateRequest.getRecordTypeIdByDevName(MxpBoBUpdateRequest.RECORDTYPE_DEV_NAME_NEW_MERCHANT_BOB);
        
        Id mockBoBId = Fake.generateId(MXP_BoB_Update_Request__c.SObjectType);
        Id userId1 = Fake.generateId(User.SObjectType);
        List<MXP_BoB_Update_Request__c> recList = new List<MXP_BoB_Update_Request__c>{
            (MXP_BoB_Update_Request__c) new Fake(MXP_BoB_Update_Request__c.class)
                .setField(MXP_BoB_Update_Request__c.Id, mockBoBId)
                .setField(MXP_BoB_Update_Request__c.RecordTypeId, tferSingleBusinessId)
                .setField(MXP_BoB_Update_Request__c.Merchant__c, mockAccountId)
                .setField(MXP_BoB_Update_Request__c.Business_Id__c, 1234)
                .setField(MXP_BoB_Update_Request__c.New_MXP__c, userId1)
                .setField(MXP_BoB_Update_Request__c.Status__c,'Approved')
                .toSObject()
        };

        Map<Id,MXP_BoB_Update_Request__c> recOldMap = new Map<Id,MXP_BoB_Update_Request__c>{
            mockBoBId => (MXP_BoB_Update_Request__c) new Fake(MXP_BoB_Update_Request__c.class)
                .setField(MXP_BoB_Update_Request__c.Id, mockBoBId)
                .setField(MXP_BoB_Update_Request__c.RecordTypeId, tferSingleBusinessId)
                .setField(MXP_BoB_Update_Request__c.Merchant__c, mockAccountId)
                .setField(MXP_BoB_Update_Request__c.Business_Id__c, 1234)
                .setField(MXP_BoB_Update_Request__c.New_MXP__c, userId1)
                .setField(MXP_BoB_Update_Request__c.Status__c,'Pending Approval')
                .toSObject()
        };

        CTrMxpBoBApprovedUpdReqProcess cls = new CTrMxpBoBApprovedUpdReqProcess();
        cls.setTriggerContext('after update',true);
        cls.setMockTriggerList(recList);
        cls.setMockTriggerOldMap(recOldMap);

        cls.processApprovedTransferRecords();

        System.assert(recList[0].hasErrors() == false,'No Error found');
    }
}