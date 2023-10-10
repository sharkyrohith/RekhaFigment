/**
 * @author  Nayana K
 * @date    October 2022
 * @description This is the test class for AccountTeamMembersSelector
 */
@isTest
public with sharing class AccountTeamMembersSelectorTest {

    @testSetup static void testSetup() {
        Account parentAccount = TDdAccountFactory.createAccounts('parentAccountName', 1, 'Parent Account')[0];
        parentAccount.Name = 'test parent';
        parentAccount.Business_Id__c = 12345;
        insert parentAccount;

        List<User> lstUser = [Select Id,Email From User Where IsActive=true And Profile.Name = 'System Administrator' Limit 2];

        List<AccountTeamMember> atmList = new List<AccountTeamMember>();
        atmList.add(new AccountTeamMember(AccountId =parentAccount.Id,UserId= lstUser[0].Id,TeamMemberRole= CDdSupportConstants.MXP_ROLE_NAME));
        insert atmList;
    }

     /**
     * @author      Nayana
     * @date        Mar 2022
     * @description Data will be quried once and can be used in test methods
     */
    public class TestContext
    {
        public Id atmId;
        public Id accId;
        public Id userId;
        public TestContext(){
            List<AccountTeamMember> lstAccTeamMember = [SELECT Id,AccountId,UserId FROM AccountTeammember WHERE CreatedDate =Today];
            atmId = lstAccTeamMember[0].Id;
            accId = lstAccTeamMember[0].AccountId;
            userId = lstAccTeamMember[0].UserId;
        }
    }

    @isTest
    static void testSelectById() {
        TestContext context = new TestContext();
        Set<Id> setAtmIds = new Set<Id>{context.atmId};
        List<AccountTeamMember> lstReturnAtm = AccountTeamMembersSelector.newInstance().selectById(setAtmIds);
        System.assertEquals( 1, lstReturnAtm.size(),'Query should return 1 record' );
    } 

    @isTest
    static void testSelectByIdString() {
        TestContext context = new TestContext();
        Set<String> setAtmIds = new Set<String>{context.atmId};
        List<AccountTeamMember> lstReturnAtm = AccountTeamMembersSelector.newInstance().selectById(setAtmIds);
        System.assertEquals( 1, lstReturnAtm.size(),'Query should return 1 record' );
    } 

    @isTest
    static void testSelectByAccountId() {
        TestContext context = new TestContext();
        Set<Id> setAccIds = new Set<Id>{context.accId};
        List<AccountTeamMember> lstReturnAtm = AccountTeamMembersSelector.newInstance().selectByAccountId(setAccIds);
        System.assertEquals( 1, lstReturnAtm.size(),'Query should return 1 record' );
    } 
    
    @isTest
    static void testSelectByAccountIdAndRoles() {
        TestContext context = new TestContext();
        Set<Id> setAccIds = new Set<Id>{context.accId};
        List<AccountTeamMember> lstReturnAtm = AccountTeamMembersSelector.newInstance().selectByAccountIdAndRoles(setAccIds,new Set<String>{CDdSupportConstants.MXP_ROLE_NAME});
        System.assertEquals( context.accId, lstReturnAtm[0].AccountId,'Query should return 1 record' );
    }

    @isTest
    static void testSelectByUserIdAndRoles() {
        TestContext context = new TestContext();
        Set<Id> setUserIds = new Set<Id>{context.userId};
        List<AccountTeamMember> lstReturnAtm = AccountTeamMembersSelector.newInstance().selectByUserIdAndRoles(setUserIds,new Set<String>{CDdSupportConstants.MXP_ROLE_NAME});
        System.assertEquals(context.userId, lstReturnAtm[0].UserId,'Query should return 1 record' );
        System.assertEquals(CDdSupportConstants.MXP_ROLE_NAME, lstReturnAtm[0].TeamMemberRole,'Query should return MXP role' );
    }

    @isTest
    static void testSelectByUserIdOrBusinessIdAndRoles() {
        TestContext context = new TestContext();
        Set<Id> setUserIds = new Set<Id>{context.userId};
        List<AccountTeamMember> lstReturnAtm = AccountTeamMembersSelector.newInstance().selectByUserIdOrBusinessIdAndRoles(setUserIds,new Set<Decimal> {12345},new Set<String>{CDdSupportConstants.MXP_ROLE_NAME});
        System.assertEquals(context.userId, lstReturnAtm[0].UserId,'Query should return 1 record' );
    }

    @isTest
    static void testSelectCountOfAccountsSupportedGroupedByUserIdAndRoles() {
        TestContext context = new TestContext();
        Set<Id> setUserIds = new Set<Id>{context.userId};
        List<Aggregate> lstAggregateResult = AccountTeamMembersSelector.newInstance().selectCountOfAccountsSupportedGroupedByUserIdAndRoles(setUserIds,new Set<String>{CDdSupportConstants.MXP_ROLE_NAME});
        System.assertEquals(1, (Integer) lstAggregateResult[0].get('cnt'),'Query should return 1 record' );
    }


    @isTest
    static void testQueryLocatorSelectByUserIdAndRoles() {
        TestContext context = new TestContext();
        Set<Id> setUserIds = new Set<Id>{context.userId};
        Database.QueryLocator datbaseQueryLocator = AccountTeamMembersSelector.newInstance().queryLocatorSelectByUserIdAndRoles(setUserIds,new Set<String>{CDdSupportConstants.MXP_ROLE_NAME});
        System.assertEquals(true, datbaseQueryLocator!=null,'Query locatory should be returned' );
    }
}