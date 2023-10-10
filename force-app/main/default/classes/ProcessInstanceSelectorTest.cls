@isTest
public class ProcessInstanceSelectorTest {

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

        Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitrequest();
        app.setObjectId(bobReq.Id);    
        Approval.process(app);
    }

     /**
     * @author      Nayana
     * @date        Oct 2022
     * @description Data will be quried once and can be used in test methods
     */
    public class TestContext
    {
        public Id targetId;
        public TestContext(){
            ProcessInstance pi = [SELECT TargetObjectId, CreatedDate FROM ProcessInstance WHERE CreatedDate =Today];
            targetId = pi.TargetObjectId;
        }
    }

    @isTest
    static void testSelectByParentId() {
        TestContext context = new TestContext();
        Set<Id> setParentIds = new Set<Id>{context.targetId};
        List<ProcessInstance> lstProcessInstance = ProcessInstanceSelector.newInstance().selectByParentId(setParentIds);
        System.assertEquals( 1, lstProcessInstance.size(),'Query should return 1 record' );
    }
    
    @isTest
    static void testGetMapParentApprovalEmail() {
        TestContext context = new TestContext();
        Set<Id> setParentIds = new Set<Id>{context.targetId};
        Map<Id,String> mapApproverIdEmail = ProcessInstanceSelector.newInstance().getMapParentApprovalEmail(setParentIds);
        System.assertEquals( 0, mapApproverIdEmail.size(),'No approved record' );
    }
}