/**
 * 
 * @author: Tia Xuan
 * @date: 2020-05
 * @description Test class for CDdCreatePersonAccountController
 * 
 */
@isTest
public class CDdCreatePersonAccountControllerTest {
    @isTest
    static void testCreatePersonAccount() {
        List<Case> caseList = TDdCaseFactory.createCaseRecords(1, 'Support');
        caseList[0].SuppliedEmail = 'test@test.com';
        caseList[0].SuppliedPhone = '1234567890';
        caseList[0].Full_Name__c = 'test@test.com';
        insert caseList;

        Test.startTest();
        String accId = CDdCreatePersonAccountController.createPersonAccount(caseList[0].Id);

        Case c = [  select  Id,
                            AccountId,
                            ContactId
                    from Case
                    where Id =: caseList[0].Id];
        System.assert(c.AccountId != null);
        System.assert(c.ContactId != null);

        Test.stopTest();
    }
}