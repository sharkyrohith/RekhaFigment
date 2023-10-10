@isTest
public class MxpBobUpdateRequestSelectorTest {

    @testSetup static void testSetup() {
        Account parentAccount = TDdAccountFactory.createAccounts('parentAccountName', 1, 'Parent Account')[0];
        parentAccount.Name = 'test parent';
        parentAccount.Business_Id__c = 12345;
        insert parentAccount;

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
    }

     /**
     * @author      Nayana
     * @date        Mar 2022
     * @description Data will be quried once and can be used in test methods
     */
    public class TestContext
    {
        public Id mxpBobId;
        public TestContext(){
            mxpBobId = [SELECT Id FROM MXP_BoB_Update_Request__c WHERE CreatedDate =Today].Id;
        }
    }
   
    @isTest
    static void testSelectById() {
        TestContext context = new TestContext();
        Set<Id> setBobIds = new Set<Id>{context.mxpBobId};
        List<MXP_BoB_Update_Request__c> lstReturnedBob = MxpBobUpdateRequestSelector.newInstance().selectById(setBobIds);
        System.assertEquals( 1, lstReturnedBob.size(),'Query should return 1 record' );
    } 

    @isTest
    static void testSelectByIdString() {
        TestContext context = new TestContext();
        Set<String> setBobIds = new Set<String>{context.mxpBobId};
        List<MXP_BoB_Update_Request__c> lstReturnedBob = MxpBobUpdateRequestSelector.newInstance().selectById(setBobIds);
        System.assertEquals( 1, lstReturnedBob.size(),'Query should return 1 record' );
    } 

    @isTest
    static void testSelectByIdExtraFields() {
        TestContext context = new TestContext();
        Set<Id> setBobIds = new Set<Id>{context.mxpBobId};
        List<MXP_BoB_Update_Request__c> lstReturnedBob = MxpBobUpdateRequestSelector.newInstance().selectByIdExtraFields(setBobIds);
        System.assertEquals( 1, lstReturnedBob.size(),'Query should return 1 record' );
    } 
}