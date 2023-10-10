/**
 * 
 * @author: Tia Xuan
 * @date: 2021-02
 * @description Test class for CDdCaseNotesCtrl
 * 
 */
@isTest
public class CDdCaseNotesCtrlTest {

    @isTest
    static void CaseNotesCtrlTest() {
        Account testAcc = VTestUtil.createAccount('Test Acc', true);
        testAcc.Phone = '7868799484';
        testAcc.BillingCountryCode = 'US';
        testAcc.Market_Area__c = 'Northern California - East Bay';
        testAcc.Business_ID__c = 123456;
        insert testAcc;

        List<Case> caseList = TDdCaseFactory.createCaseRecords(1, 'Support');
        caseList[0].AccountId = testAcc.Id;
        insert caseList;

        Chatter_Post_Notes_Template__c temp = new Chatter_Post_Notes_Template__c();
        temp.Name = 'test'; 
        temp.Body__c = 'test';
        insert temp;

        Test.startTest();

        List<Chatter_Post_Notes_Template__c> tempList = CDdCaseNotesCtrl.getTemplateOptions();
        System.assert(tempList.size() == 1);

        CDdCaseNotesCtrl.postFeed('test', caseList[0].Id, 'test');
        List<FeedItem> fiList = [select Id from FeedItem where ParentId =: caseList[0].Id];
        System.assert(fiList.size() == 1);

        Case cse = [select Id, CaseNoteTemplate__c from Case where Id=: caseList[0].Id];
        System.assert(cse.CaseNoteTemplate__c == 'test');

        CDdCaseNotesCtrl.postFeed('test', caseList[0].Id, 'test');
        fiList = [select Id from FeedItem where ParentId =: caseList[0].Id];
        System.assert(fiList.size() == 2);
        
        Test.stopTest();
    }

}