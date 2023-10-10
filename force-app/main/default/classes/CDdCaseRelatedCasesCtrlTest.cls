/**
 *
 * @author: Tia Xuan
 * @date: 2021-02
 * @description Test class for CDdCaseRelatedCasesCtrl
 *
 */
@isTest
public class CDdCaseRelatedCasesCtrlTest {

    @isTest
    static void testGetRelatedCases() {
        Account testAcc = VTestUtil.createAccount('Test Acc', true);
        testAcc.Phone = '7868799484';
        testAcc.BillingCountryCode = 'US';
        testAcc.Market_Area__c = 'Northern California - East Bay';
        testAcc.Business_ID__c = 123456;
        insert testAcc;

        List<Case> caseList = TDdCaseFactory.createCaseRecords(2, 'Support');
        caseList[0].AccountId = testAcc.Id;
        caseList[1].AccountId = testAcc.Id;
        insert caseList;

        Test.startTest();

        CDdCaseRelatedCasesCtrl.DeliveryCasesWrapper res = CDdCaseRelatedCasesCtrl.getRelatedCases('AccountId', caseList[0].Id, 'AccountId,CaseNumber', 10, null);
        System.assert(res != null);

        Test.stopTest();
    }

    @isTest
    static void testMergeCases() {

        List<Case> caseList = TDdCaseFactory.createCaseRecords(2, 'Support');
        caseList[0].Customer_Type__c = 'Dasher';
        caseList[0].Issue_Type__c = 'Account Issue - Dx';
        caseList[0].Issue__c = 'Account Updates - Dx';
        caseList[0].Resolution_Type__c = 'Account Management - DX';
        caseList[0].Resolution__c = 'Account Info Reset';
        insert caseList;

        Test.startTest();

        CDdCaseRelatedCasesCtrl.mergeCases(caseList[0].Id, caseList[1].Id);

        Case c = [select Id, ParentId from Case where Id=: caseList[0].Id];
        System.assert(c.ParentId == caseList[1].Id);

        Test.stopTest();
    }

}