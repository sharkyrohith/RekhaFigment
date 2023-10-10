/**
 * @author  Nayana K
 * @date    October 2022
 * @description This is the test class for MxpBobTransferBatch
 */
@IsTest
public class MxpBobTransferBatchTest {
    //test batchable interface
	@isTest
    static void testCDdBatchBoBTransferBatchClass() {
        Id mockAccountId = Fake.generateId( Account.class );

        Id userId1 = Fake.generateId(User.SObjectType);
        Id userId2 = Fake.generateId(User.SObjectType);

        Map<Id,Id> mapOldNewMxp = new Map<Id,Id>();
        mapOldNewMxp.put(userId1,userId2);

        Id mockBoBId1 = Fake.generateId(MXP_BoB_Update_Request__c.SObjectType);
		MXP_BoB_Update_Request__c fakeBobReq1 = (MXP_BoB_Update_Request__c) new Fake(MXP_BoB_Update_Request__c.class)
        .setField(MXP_BoB_Update_Request__c.Id, mockBoBId1)
        .setField(MXP_BoB_Update_Request__c.Previous_MXP__c, userId1)
        .setField(MXP_BoB_Update_Request__c.New_MXP__c, userId2)
        .setField(MXP_BoB_Update_Request__c.Status__c, 'Approved')
        .setField(MXP_BoB_Update_Request__c.Batch_Job_Status__c, 'Not Started')
        .toSObject();

        Id accTeamId = Fake.generateId(AccountTeamMember.SObjectType);
        List<AccountTeamMember> lstFakeAccTeam = new List<AccountTeamMember>{(AccountTeamMember) new Fake(AccountTeamMember.class)
        .setField(AccountTeamMember.Id , accTeamId)
        .setField(AccountTeamMember.AccountId,mockAccountId)
        .setField(AccountTeamMember.TeamMemberRole , CDdSupportConstants.MXP_ROLE_NAME)
        .setField(AccountTeamMember.UserId , userId1)
        .toSObject()};

        // create an instance of fflib_ApexMocks class part of apex mock framework.
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        // create an instance of fflib_SObjectUnitOfWork class part of apex mock framework.
		fflib_ISObjectUnitOfWork mockUOW = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_ISObjectUnitOfWork.class);
        IAccountTeamMembersSelector mockAccTeamMemberelector = (IAccountTeamMembersSelector) mocks.mock(
            IAccountTeamMembersSelector.class
        ); 
        IMxpBoBUpdateRequestSelector mockMxpBoBUpdateReqSelector = (IMxpBoBUpdateRequestSelector) mocks.mock(
            IMxpBoBUpdateRequestSelector.class
        );
        IMxpBobUpdateRequestService serviceMock = (IMxpBobUpdateRequestService) mocks.mock(IMxpBobUpdateRequestService.class);
        mocks.startStubbing();
            mocks.when(mockMxpBoBUpdateReqSelector.sObjectType()).thenReturn(MXP_BoB_Update_Request__c.SObjectType);
            mocks.when(mockMxpBoBUpdateReqSelector.selectById(new Set<Id>{mockBoBId1})).thenReturn(fakeBobReq1);
		    mocks.when(mockAccTeamMemberelector.sObjectType()).thenReturn(AccountTeamMember.SObjectType);
		    mocks.when(mockAccTeamMemberelector.queryLocatorSelectByUserIdAndRoles(mapOldNewMxp.keySet(), new Set<String>{CDdSupportConstants.MXP_ROLE_NAME})).thenReturn(null);
		mocks.stopStubbing();
        Application.UnitOfWork.setMock(mockUOW);
        Application.selector.setMock(mockMxpBoBUpdateReqSelector);
		Application.selector.setMock(mockAccTeamMemberelector);
        Application.SERVICE.setMock(IMxpBobUpdateRequestService.class, serviceMock);
        try{
            Test.startTest();
            MxpBobTransferBatch batch = new MxpBobTransferBatch();
            batch.start(null);
            batch.execute(null, lstFakeAccTeam);
            batch.finish(null);
            ((IAccountTeamMembersSelector) mocks.verify(mockAccTeamMemberelector, 0))
            .queryLocatorSelectByUserIdAndRoles(mapOldNewMxp.keySet(), new Set<String>{CDdSupportConstants.MXP_ROLE_NAME});
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
            'MxpBobTransferBatch',
            '0 0 1 * * ?',
            new MxpBobTransferBatch()
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
    static void testCDdBatchBoBTransferIntegrationTest() {        
        List<Account> accts = TDdAccountFactory.createAccounts('test acct', 1);
        insert accts;
        
        List<User> insUser = [Select Id From User Where IsActive=true And Profile.Name = 'System Administrator' Limit 2];
        
        List<AccountTeamMember> atmList = new List<AccountTeamMember>();
        atmList.add(new AccountTeamMember(AccountId =accts[0].Id,UserId= insUser[0].Id,TeamMemberRole= CDdSupportConstants.MXP_ROLE_NAME));
        insert atmList;
        
        MXP_BoB_Update_Request__c bobReq = new MXP_BoB_Update_Request__c();
        bobReq.RecordTypeId = MxpBoBUpdateRequest.getRecordTypeIdByDevName(MxpBoBUpdateRequest.RECORDTYPE_DEV_NAME_BOOK_OF_BUSINESS);
        bobReq.Previous_MXP__c = insUser[0].Id;
        bobReq.New_MXP__c = insUser[1].Id;
        bobReq.Status__c = 'New';
        bobReq.Batch_Job_Status__c = 'Not Started';
        insert bobReq;
        bobReq.Status__c = 'Approved';
        update bobReq;
        Test.startTest();
        	MxpBobTransferBatch batch = new MxpBobTransferBatch(new Set<Id>{bobReq.Id});
        	Database.executeBatch(batch, 150);
        Test.stopTest();
        List<AccountTeamMember> atmListRefreshed = [SELECT Id,UserId FROM AccountTeamMember WHERE AccountId=:accts[0].Id AND TeamMemberRole=: CDdSupportConstants.MXP_ROLE_NAME];
        System.assertEquals(insUser[1].Id, atmListRefreshed[0].UserId, 'New Mxp should replace old Mxp');
    }
}