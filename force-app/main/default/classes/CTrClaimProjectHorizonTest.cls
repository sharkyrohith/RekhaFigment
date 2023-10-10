@isTest
public class CTrClaimProjectHorizonTest {

    @IsTest
    static void testProjectHorizonWorkflowUpdate(){
        List<Account> acct = TDdAccountFactory.createAccounts('Test Dahser', 1, 'Consumer or Dasher');
        acct[0].PersonEmail = 'test.dasher@test.com';
        insert acct;

        List<Case> cases = TDdCaseFactory.createCaseRecords(1, 'Support');
        cases[0].AccountId = acct[0].Id;
        insert cases;

        CDdClaimFactory.createAutoClaims(1, cases[0].Id, acct[0].Id, true);

        List<Claim__c> expectedClaim = [SELECT Id, Claim_Number__c FROM Claim__c];
        System.assertEquals('11111111', expectedClaim[0].Claim_Number__c, 'Claim Number on Claim is not same as expected.');
    }
}