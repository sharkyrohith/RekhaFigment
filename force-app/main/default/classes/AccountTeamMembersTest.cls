/**
 * @author  Nayana K
 * @date    November 2022
 * @description This is the test class for AccountTeamMembers
 */
@isTest
public class AccountTeamMembersTest {
    @isTest
    private static void testWhenClassInstantiatesThenRun() {
         List<AccountTeamMember> lstAccTeamMembers = new List<AccountTeamMember>();
        //IAccounts Instance Creation Call
        AccountTeamMembers.newInstance(lstAccTeamMembers);
        //Default Constructor Call
        AccountTeamMembers atmObject = new AccountTeamMembers(lstAccTeamMembers);
        //fflib_IDomainConstructor call
        AccountTeamMembers.Constructor constructorObject = new AccountTeamMembers.Constructor();
        constructorObject.construct(lstAccTeamMembers);
        System.assertNotEquals(
            AccountTeamMembers.newInstance(lstAccTeamMembers),
            atmObject,
            'These objects should not be similar'
        );
    }
    
    @isTest
    private static void testCoverage() {
        Set<Id> lstAtmIds = new Set<Id>();
        lstAtmIds.add(Fake.generateId(AccountTeamMember.SObjectType));
        //IAccounts Instance Creation Call
        AccountTeamMembers.newInstance(lstAtmIds);
        List<AccountTeamMember> lstATM = AccountTeamMembers.newInstance(lstAtmIds).getAccountTeamMembers();
        System.assertEquals(0, lstATM.size(), 'Should return empty list');
    }
}