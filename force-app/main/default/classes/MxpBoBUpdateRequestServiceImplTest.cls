/**
 * @author  Nayana K
 * @date    October 2022
 * @description This is the unit test class for MxpBoBUpdateRequestServiceImpl
 */
@IsTest
public with sharing class MxpBoBUpdateRequestServiceImplTest {

    @isTest
    static void testTransferBoBRequest() {
        Id mockAccountId = Fake.generateId( Account.class );
        Fake fakeAccount = new Fake(Account.class)
        .setField(Account.Business_Id__c, 123455);
        //.setField(Account.Case_Routing_Override__c, CDdSupportConstants.MXP_ROUTING_OVERRIDE_VALUE);

        Id userId1 = Fake.generateId(User.SObjectType);
        Id userId2 = Fake.generateId(User.SObjectType);
        Set<Id> userIdSet = new Set<Id>{userId1};
        Map<Id,Id> mapOldNewMxp = new Map<Id,Id>();
        mapOldNewMxp.put(userId1,userId2);

        Id accTeamId = Fake.generateId(AccountTeamMember.SObjectType);
        List<AccountTeamMember> lstFakeAccTeam = new List<AccountTeamMember>{(AccountTeamMember) new Fake(AccountTeamMember.class)
        .setField(AccountTeamMember.Id , accTeamId)
        .setParent('Account' , fakeAccount)
        .setField(AccountTeamMember.AccountId,mockAccountId)
        .setField(AccountTeamMember.TeamMemberRole , CDdSupportConstants.MXP_ROLE_NAME)
        .setField(AccountTeamMember.UserId , userId1)
        .toSObject()};


        // create an instance of fflib_ApexMocks class part of apex mock framework.
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        // create an instance of fflib_SObjectUnitOfWork class part of apex mock framework.
		fflib_ISObjectUnitOfWork mockUOW = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_ISObjectUnitOfWork.class);
        IAccountTeamMembersSelector mockAccTeamMemberelector = (IAccountTeamMembersSelector) mocks.mock(IAccountTeamMembersSelector.class);

        mocks.startStubbing();
		  mocks.when(mockAccTeamMemberelector.sObjectType()).thenReturn(AccountTeamMember.SObjectType);
		  mocks.when(mockAccTeamMemberelector.selectByUserIdAndRoles(userIdSet,
          new Set<String>{CDdSupportConstants.MXP_ROLE_NAME})).thenReturn(lstFakeAccTeam);
		mocks.stopStubbing();
        Application.UnitOfWork.setMock(mockUOW);
		Application.selector.setMock(mockAccTeamMemberelector);
        try{
			Test.startTest();
            String errorMsg = MxpBobUpdateRequestService.transferBoBRequest(mapOldNewMxp,lstFakeAccTeam);
            System.assertEquals('', errorMsg,'No error should occur');
			Test.stopTest();
		}
		catch(Exception e){
			System.assert(e instanceof DmlException);
		}
    }

    @isTest
    static void testTransferBusinessIdRequestNew() {
        Id mockAccountId = Fake.generateId( Account.class );
        Account fakeAccount = (Account) new Fake(Account.class)
        .setField(Account.Business_Id__c, 123455)
        .toSObject();
        List<Account> lstFakeAcc = new List<Account> {fakeAccount};
        Map<Decimal,Id>mapBusinessIdNewMxpId = new Map<Decimal,Id>();
        mapBusinessIdNewMxpId.put(123455,mockAccountId);

        // create an instance of fflib_ApexMocks class part of apex mock framework.
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        // create an instance of fflib_SObjectUnitOfWork class part of apex mock framework.
		fflib_ISObjectUnitOfWork mockUOW = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_ISObjectUnitOfWork.class);
        IAccountTeamMembersSelector mockAccTeamMemberelector = (IAccountTeamMembersSelector) mocks.mock(IAccountTeamMembersSelector.class);
        IAccountsSelector mockAccountSelector = (IAccountsSelector) mocks.mock(IAccountsSelector.class);

        mocks.startStubbing();
            mocks.when(mockAccTeamMemberelector.sObjectType()).thenReturn(AccountTeamMember.SObjectType);
            mocks.when(mockAccTeamMemberelector.selectByUserIdOrBusinessIdAndRoles(new Set<Id>(),new Set<Decimal>{123455},
            new Set<String>{CDdSupportConstants.MXP_ROLE_NAME})).thenReturn(new Set<AccountTeamMember>());
            mocks.when(mockAccountSelector.sObjectType()).thenReturn(Account.SObjectType);
            mocks.when(mockAccountSelector.selectAccountsByBusinessId(new Set<Decimal>{123455})).thenReturn(lstFakeAcc);
		mocks.stopStubbing();
        Application.UnitOfWork.setMock(mockUOW);
        Application.selector.setMock(mockAccTeamMemberelector);
        Application.selector.setMock(mockAccountSelector);
        try{
			Test.startTest();
            String errorMsg = MxpBobUpdateRequestService.processBusinessIdBobRequests(mapBusinessIdNewMxpId,lstFakeAcc);
            System.assertEquals('', errorMsg,'No error should occur');
			Test.stopTest();
		}
		catch(Exception e){
			System.assert(e instanceof DmlException);
		}
    }

    @isTest
    public static void testGetAdditionalInformationSingleMerchantTransfer() {
        Id mockAccountId = Fake.generateId(Account.SObjectType);
        Set<Id> accountIdSet = new Set<Id>{mockAccountId};

        Id userId1 = Fake.generateId(User.SObjectType);
        Id userId2 = Fake.generateId(User.SObjectType);
        Set<Id> userIdSet = new Set<Id>{userId1,userId2};

        Id mockBoBId = Fake.generateId(MXP_BoB_Update_Request__c.SObjectType);

        List<MXP_BoB_Update_Request__c> bobRequest = new List<MXP_BoB_Update_Request__c>{
            (MXP_BoB_Update_Request__c) new Fake(MXP_BoB_Update_Request__c.class)
                .setField(MXP_BoB_Update_Request__c.Id, mockBoBId)
                .setField(MXP_BoB_Update_Request__c.Merchant__c, mockAccountId)
                .setField(MXP_BoB_Update_Request__c.New_MXP__c, userId1)
                .setField(MXP_BoB_Update_Request__c.Status__c,'Approved')
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
        IMxpBoBUpdateRequestSelector mockMxpBoBUpdateReqSelector = (IMxpBoBUpdateRequestSelector) mocks.mock(
            IMxpBoBUpdateRequestSelector.class
        );

        Set<String> mxpRole = new Set<String>{CDdSupportConstants.MXP_ROLE_NAME};

        List<Aggregate> aggResultList = new List<Aggregate>{
            new Aggregate(new Map<String,Object> {
                'userName' => 'User 1',
                'userId' => userId1,
                'cnt' => 100
            }),
            new Aggregate(new Map<String,Object> {
                'userName' => 'User 2',
                'userId' => userId2,
                'cnt' => 400
            })
        };

        mocks.startStubbing();
        mocks.when(mockAccTeamMemberSelector.sObjectType()).thenReturn(AccountTeamMember.SObjectType);
        mocks.when(mockMxpBoBUpdateReqSelector.sObjectType()).thenReturn(MXP_BoB_Update_Request__c.SObjectType);
        mocks.when(mockMxpBoBUpdateReqSelector.selectByIdExtraFields(new Set<Id>{mockBoBId})).thenReturn(bobRequest);
        mocks.when(mockAccTeamMemberSelector.selectByAccountIdAndRoles(accountIdSet,mxpRole)).thenReturn(accTeamMember);
        mocks.when(mockAccTeamMemberSelector.selectCountOfAccountsSupportedGroupedByUserIdAndRoles(userIdSet,mxpRole)).thenReturn(aggResultList);
		mocks.stopStubbing();

        Application.SELECTOR.setMock(mockAccTeamMemberSelector);
        Application.SELECTOR.setMock(mockMxpBoBUpdateReqSelector);

        List<String> infoList = MxpBobUpdateRequestService.getAdditionalInformationAboutMxpBobUpdateRequest(mockBoBId);

        system.assert(!infoList.isEmpty(),'Info list was empty');
    }
}