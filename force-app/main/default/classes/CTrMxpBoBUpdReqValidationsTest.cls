@isTest
public without sharing class CTrMxpBoBUpdReqValidationsTest {
    @IsTest
    static void testValidateRecordPriorToApproval(){
        Id mockAccountId = Fake.generateId(Account.SObjectType);
        Id mockBoBId = Fake.generateId(MXP_BoB_Update_Request__c.SObjectType);

        List<MXP_BoB_Update_Request__c> recList = new List<MXP_BoB_Update_Request__c>{
            (MXP_BoB_Update_Request__c) new Fake(MXP_BoB_Update_Request__c.class)
                .setField(MXP_BoB_Update_Request__c.Id, mockBoBId)
                .setField(MXP_BoB_Update_Request__c.Merchant__c, mockAccountId)
                .setField(MXP_BoB_Update_Request__c.Any_MXP__c, true)
                .setField(MXP_BoB_Update_Request__c.Status__c,'Approved')
                .toSObject()
        };

        Map<Id,MXP_BoB_Update_Request__c> recOldMap = new Map<Id,MXP_BoB_Update_Request__c>{
            mockBoBId => (MXP_BoB_Update_Request__c) new Fake(MXP_BoB_Update_Request__c.class)
                .setField(MXP_BoB_Update_Request__c.Id, mockBoBId)
                .setField(MXP_BoB_Update_Request__c.Merchant__c, mockAccountId)
                .setField(MXP_BoB_Update_Request__c.Any_MXP__c, true)
                .setField(MXP_BoB_Update_Request__c.Status__c,'Pending Approval')
                .toSObject()
        };

        CTrMxpBoBUpdReqValidations cls = new CTrMxpBoBUpdReqValidations();
        cls.setTriggerContext('before update',true);
        cls.setMockTriggerList(recList);
        cls.setMockTriggerOldMap(recOldMap);

        cls.validateRecordPriorToApproval();

        System.assert(recList[0].hasErrors() == true,'Error found');
    }

    @IsTest
    static void testValidateRecordTypeSelectionWhenRecordTypeIsMerchantNewMxp() {
        Id recordTypeId = MxpBoBUpdateRequest.getRecordTypeIdByDevName(MxpBoBUpdateRequest.RECORDTYPE_DEV_NAME_NEW_MERCHANT_BOB);

        Id mockAccountId = Fake.generateId(Account.SObjectType);
        Set<Id> accountIdSet = new Set<Id>{mockAccountId};

        Id userId1 = Fake.generateId(User.SObjectType);
        Id userId2 = Fake.generateId(User.SObjectType);

        List<MXP_BoB_Update_Request__c> recList = new List<MXP_BoB_Update_Request__c>{
            (MXP_BoB_Update_Request__c) new Fake(MXP_BoB_Update_Request__c.class)
                .setField(MXP_BoB_Update_Request__c.RecordTypeId, recordTypeId)
                .setField(MXP_BoB_Update_Request__c.Merchant__c, mockAccountId)
                .setField(MXP_BoB_Update_Request__c.New_MXP__c, userId1)
                .setField(MXP_BoB_Update_Request__c.Status__c,'New')
                .setField(MXP_BoB_Update_Request__c.Batch_Job_Status__c,'Not Started')
                .toSObject()
        };

        Id accTeamId = fflib_IDGenerator.generate(AccountTeamMember.SObjectType);
        List<AccountTeamMember> accTeamMember = new List<AccountTeamMember>{
            (AccountTeamMember) new Fake(AccountTeamMember.class)
                .setField(AccountTeamMember.Id, accTeamId)
                .setField(AccountTeamMember.AccountId, mockAccountId)
                .setField(AccountTeamMember.TeamMemberRole, CDdSupportConstants.MXP_ROLE_NAME)
                .setField(AccountTeamMember.UserId,userId2)
                .toSObject()
        };

        // create an instance of fflib_ApexMocks class part of apex mock framework.
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        // create an instance of fflib_SObjectUnitOfWork class part of apex mock framework.
        IAccountTeamMembersSelector mockAccTeamMemberSelector = (IAccountTeamMembersSelector) mocks.mock(
            IAccountTeamMembersSelector.class
        );

        Set<String> mxpRole = new Set<String>{CDdSupportConstants.MXP_ROLE_NAME};

        mocks.startStubbing();
        mocks.when(mockAccTeamMemberSelector.sObjectType()).thenReturn(AccountTeamMember.SObjectType);
        mocks.when(mockAccTeamMemberSelector.selectByAccountIdAndRoles(accountIdSet,mxpRole)).thenReturn(accTeamMember);
		mocks.stopStubbing();

        Application.SELECTOR.setMock(mockAccTeamMemberSelector);

        CTrMxpBoBUpdReqValidations cls = new CTrMxpBoBUpdReqValidations();
        cls.setTriggerContext('before insert',true);
        cls.setMockTriggerList(recList);

        cls.validateRecordTypeSelection();

        System.assert(recList[0].hasErrors() == true,'Error found');
    }

    @IsTest
    static void testValidateRecordTypeSelectionWhenRecordTypeIsMerchantTransferMxp() {
        Id recordTypeId = MxpBoBUpdateRequest.getRecordTypeIdByDevName(MxpBoBUpdateRequest.RECORDTYPE_DEV_NAME_TRANSFER_SINGLE_BUSINESSID);

        Id mockAccountId = Fake.generateId(Account.SObjectType);
        Set<Id> accountIdSet = new Set<Id>{mockAccountId};

        Id userId1 = Fake.generateId(User.SObjectType);

        List<MXP_BoB_Update_Request__c> recList = new List<MXP_BoB_Update_Request__c>{
            (MXP_BoB_Update_Request__c) new Fake(MXP_BoB_Update_Request__c.class)
                .setField(MXP_BoB_Update_Request__c.RecordTypeId, recordTypeId)
                .setField(MXP_BoB_Update_Request__c.Merchant__c, mockAccountId)
                .setField(MXP_BoB_Update_Request__c.New_MXP__c, userId1)
                .setField(MXP_BoB_Update_Request__c.Status__c,'New')
                .setField(MXP_BoB_Update_Request__c.Batch_Job_Status__c,'Not Started')
                .toSObject()
        };

        // create an instance of fflib_ApexMocks class part of apex mock framework.
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        // create an instance of fflib_SObjectUnitOfWork class part of apex mock framework.
        IAccountTeamMembersSelector mockAccTeamMemberSelector = (IAccountTeamMembersSelector) mocks.mock(
            IAccountTeamMembersSelector.class
        );

        Set<String> mxpRole = new Set<String>{CDdSupportConstants.MXP_ROLE_NAME};

        mocks.startStubbing();
        mocks.when(mockAccTeamMemberSelector.sObjectType()).thenReturn(AccountTeamMember.SObjectType);
        mocks.when(mockAccTeamMemberSelector.selectByAccountIdAndRoles(accountIdSet,mxpRole)).thenReturn(new List<AccountTeamMember>());
		mocks.stopStubbing();

        Application.SELECTOR.setMock(mockAccTeamMemberSelector);

        CTrMxpBoBUpdReqValidations cls = new CTrMxpBoBUpdReqValidations();
        cls.setTriggerContext('before insert',true);
        cls.setMockTriggerList(recList);

        cls.validateRecordTypeSelection();

        System.assert(recList[0].hasErrors() == true,'Error found');
    }

    @IsTest
    static void testBeforeInsert() {
        Id recordTypeId = MxpBoBUpdateRequest.getRecordTypeIdByDevName(MxpBoBUpdateRequest.RECORDTYPE_DEV_NAME_INCREASE_MXP_BOB);

        Id userId1 = Fake.generateId(User.SObjectType);

        List<MXP_BoB_Update_Request__c> recList = new List<MXP_BoB_Update_Request__c>{
            (MXP_BoB_Update_Request__c) new Fake(MXP_BoB_Update_Request__c.class)
                .setField(MXP_BoB_Update_Request__c.RecordTypeId, recordTypeId)
                .setField(MXP_BoB_Update_Request__c.MXP__c, userId1)
                .setField(MXP_BoB_Update_Request__c.Status__c,'New')
                .toSObject()
        };

        CTrMxpBoBUpdReqValidations cls = new CTrMxpBoBUpdReqValidations();
        cls.setTriggerContext('before insert',true);
        cls.setMockTriggerList(recList);

        cls.beforeInsert();
        system.assert(recList[0].hasErrors() == false, 'Record has errors');
    }

    @IsTest
    static void testBeforeUpdate() {
        Id recordTypeId = MxpBoBUpdateRequest.getRecordTypeIdByDevName(MxpBoBUpdateRequest.RECORDTYPE_DEV_NAME_INCREASE_MXP_BOB);
        Id userId1 = Fake.generateId(User.SObjectType);
        Id mockBoBId = Fake.generateId(MXP_BoB_Update_Request__c.SObjectType);

        List<MXP_BoB_Update_Request__c> recList = new List<MXP_BoB_Update_Request__c>{
            (MXP_BoB_Update_Request__c) new Fake(MXP_BoB_Update_Request__c.class)
                .setField(MXP_BoB_Update_Request__c.Id, mockBoBId)
                .setField(MXP_BoB_Update_Request__c.RecordTypeId, recordTypeId)
                .setField(MXP_BoB_Update_Request__c.MXP__c, userId1)
                .setField(MXP_BoB_Update_Request__c.Status__c,'Pending Approval')
                .toSObject()
        };

        Map<Id,MXP_BoB_Update_Request__c> recOldMap = new Map<Id,MXP_BoB_Update_Request__c>{
            mockBoBId => (MXP_BoB_Update_Request__c) new Fake(MXP_BoB_Update_Request__c.class)
                .setField(MXP_BoB_Update_Request__c.Id, mockBoBId)
                .setField(MXP_BoB_Update_Request__c.RecordTypeId, recordTypeId)
                .setField(MXP_BoB_Update_Request__c.MXP__c, userId1)
                .setField(MXP_BoB_Update_Request__c.Status__c,'New')
                .toSObject()
        };

        CTrMxpBoBUpdReqValidations cls = new CTrMxpBoBUpdReqValidations();
        cls.setTriggerContext('before update',true);
        cls.setMockTriggerList(recList);
        cls.setMockTriggerOldMap(recOldMap);

        cls.beforeUpdate();
        system.assert(recList[0].hasErrors() == false, 'Record has errors');
    }
}