/**
 * @author  Nayana K
 * @date    October 2022
 * @description This is the test class for MxpBobTransferBatch
 */
@isTest
public with sharing class MxpBobBusinessBatchTest {
   //test batchable interface
   @isTest
   static void testTransferBusinessIdRequest() {
       Id mockAccountId = Fake.generateId( Account.class );
       Account fakeAccount = (Account) new Fake(Account.class)
       .setField(Account.Business_Id__c, 123455)
       .toSObject();
       List<Account> lstFakeAcc = new List<Account> {fakeAccount};

       Id userId1 = Fake.generateId(User.SObjectType);
       
       Id tferSingleBusinessId = Schema.SObjectType.MXP_BoB_Update_Request__c.getRecordTypeInfosByDeveloperName()
           .get(MxpBoBUpdateRequest.RECORDTYPE_DEV_NAME_TRANSFER_SINGLE_BUSINESSID)
           .getRecordTypeId();

       Id mockBoBId = Fake.generateId(MXP_BoB_Update_Request__c.SObjectType);
       MXP_BoB_Update_Request__c fakeBobReq = (MXP_BoB_Update_Request__c) new Fake(MXP_BoB_Update_Request__c.class)
       .setField(MXP_BoB_Update_Request__c.RecordTypeId,tferSingleBusinessId)
       .setField(MXP_BoB_Update_Request__c.Id, mockBoBId)
       .setField(MXP_BoB_Update_Request__c.Merchant__c, mockAccountId)
       .setField(MXP_BoB_Update_Request__c.New_MXP__c, userId1)
       .setField(MXP_BoB_Update_Request__c.Business_Id__c, 123455)
       .setField(MXP_BoB_Update_Request__c.Status__c, 'Approved')
       .setField(MXP_BoB_Update_Request__c.Batch_Job_Status__c, 'Not Started')
       .toSObject();
       
       // create an instance of fflib_ApexMocks class part of apex mock framework.
       fflib_ApexMocks mocks = new fflib_ApexMocks();
       // create an instance of fflib_SObjectUnitOfWork class part of apex mock framework.
       fflib_ISObjectUnitOfWork mockUOW = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_ISObjectUnitOfWork.class);
        IAccountTeamMembersSelector mockAccTeamMemberelector = (IAccountTeamMembersSelector) mocks.mock(
            IAccountTeamMembersSelector.class
        );
        IAccountsSelector mockAccountSelector = (IAccountsSelector) mocks.mock(
            IAccountsSelector.class
        );
        IMxpBobUpdateRequestSelector mockMxpSelector = (IMxpBobUpdateRequestSelector) mocks.mock(
            IMxpBobUpdateRequestSelector.class
        );
        IMxpBobUpdateRequestService serviceMock = (IMxpBobUpdateRequestService) mocks.mock(IMxpBobUpdateRequestService.class);
        mocks.startStubbing();
           mocks.when(mockMxpSelector.sObjectType()).thenReturn(MXP_BoB_Update_Request__c.SObjectType);
           mocks.when(mockMxpSelector.selectByIdExtraFields(new Set<Id>{mockBoBId})).thenReturn(new Set<MXP_BoB_Update_Request__c>{fakeBobReq});
           mocks.when(mockAccTeamMemberelector.sObjectType()).thenReturn(AccountTeamMember.SObjectType);
           mocks.when(mockAccTeamMemberelector.selectByAccountId(new Set<Id>{mockAccountId})).thenReturn(new Set<AccountTeamMember>());
           mocks.when(mockAccountSelector.sObjectType()).thenReturn(Account.SObjectType);
           mocks.when(mockAccountSelector.queryLocatorSelectAccountsByBusinessId(new Set<Decimal>{123455})).thenReturn(lstFakeAcc);
        mocks.stopStubbing();
        Application.UnitOfWork.setMock(mockUOW);
        Application.selector.setMock(mockAccTeamMemberelector);
        Application.selector.setMock(mockAccountSelector);
        Application.SERVICE.setMock(IMxpBobUpdateRequestService.class, serviceMock);
       try{
            Test.startTest();
            MxpBobBusinessBatch batch = new MxpBobBusinessBatch();
            batch.start(null);
            batch.execute(null, lstFakeAcc);
            batch.finish(null);
            ((IAccountTeamMembersSelector) mocks.verify(mockAccTeamMemberelector, 0))
            .selectByAccountId(new Set<Id>{mockAccountId});
            Test.stopTest();
       }
       catch(Exception e){
           System.assert(e instanceof DmlException);
       } 
   }
    
    //test schedulable interface
    @isTest
    static void testCDdBatchBoBTransferScheduleClass() {
        Test.startTest();
        String jobId = System.schedule(
            'MxpBobBusinessBatch',
            '0 0 1 * * ?',
            new MxpBobBusinessBatch()
        );
        Test.stopTest();
        CronTrigger cronTriggerRecord = [
            SELECT Id, CronExpression, TimesTriggered, NextFireTime
            FROM CronTrigger
            WHERE Id = :jobId
        ];
        System.assertEquals(
            Time.newInstance(1, 0, 0, 0),
            cronTriggerRecord.NextFireTime.time(),
            'Unexpected Error: The Batch has not been triggered yet'
        );
    }
    
    //Integration testing
    @isTest
    static void testCDdBatchBoBTransferBusinessIdIntegrationTest() { 
        Account parentAccount = TDdAccountFactory.createAccounts('parentAccountName', 1, 'Parent Account')[0];
        parentAccount.Name = 'test parent';
        parentAccount.Business_Id__c = 12345;
        insert parentAccount;

        Account childAccount = TDdAccountFactory.createAccounts('childAccountName', 1, 'Marketplace')[0];
        childAccount.ParentId = parentAccount.Id;
        childAccount.Business_Id__c = 12345;
        childAccount.Restaurant_ID__c = '76899';
        insert childAccount;

        Set<Id> accIds = new Set<Id>{parentAccount.Id,childAccount.Id};
        List<User> lstUser = [Select Id,Email From User Where IsActive=true And Profile.Name = 'System Administrator' Limit 2];

        List<AccountTeamMember> atmList = new List<AccountTeamMember>();
        atmList.add(new AccountTeamMember(AccountId =parentAccount.Id,UserId= lstUser[0].Id,TeamMemberRole= CDdSupportConstants.MXP_ROLE_NAME));
        insert atmList;
        
        MXP_BoB_Update_Request__c bobReq = new MXP_BoB_Update_Request__c();
        bobReq.RecordTypeId = MxpBoBUpdateRequest.getRecordTypeIdByDevName(MxpBoBUpdateRequest.RECORDTYPE_DEV_NAME_TRANSFER_SINGLE_BUSINESSID);
        bobReq.Merchant__c = parentAccount.Id;
        bobReq.New_MXP__c = lstUser[1].Id;
        bobReq.Status__c = 'New';
        insert bobReq;
        Test.startTest();
            MxpBobBusinessBatch batch = new MxpBobBusinessBatch(new Set<Id>{bobReq.Id});
        	Database.executeBatch(batch, 150);
        Test.stopTest();
        List<AccountTeamMember> atmListRefreshed = [SELECT Id,UserId FROM AccountTeamMember WHERE AccountId IN : accIds AND TeamMemberRole=: CDdSupportConstants.MXP_ROLE_NAME];
        System.assertEquals(lstUser[1].Id, atmListRefreshed[0].UserId, 'Mxp added to account');
        System.assertEquals(lstUser[1].Id, atmListRefreshed[1].UserId, 'Mxp added to account');
    }
}