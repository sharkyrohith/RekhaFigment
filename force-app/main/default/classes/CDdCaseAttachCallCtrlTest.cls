/**
 * 
 * @author: Tia Xuan
 * @date: 2021-02
 * @description Test class for CDdCaseAttachCallCtrl
 * 
 */
@isTest
public class CDdCaseAttachCallCtrlTest {

    @isTest
    static void testPostFeed() {
        List<Case> caseList = TDdCaseFactory.createCaseRecords(1, 'Support');
        insert caseList;

        Test.startTest();

        CDdCaseAttachCallCtrl.postFeed(caseList[0].Id, 'INBOUND');


        List<AC_Outbound_Call__c> ocList = [select Id from AC_Outbound_Call__c where Case__c  =: caseList[0].Id];
        System.assert(ocList.size() == 1);
        
        Test.stopTest();
    }

}