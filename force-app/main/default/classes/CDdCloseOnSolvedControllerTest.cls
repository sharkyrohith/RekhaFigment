/**
 *
 * @author: Tia Xuan
 * @date: 2020-07
 * @description Test class for CDdCloseOnSolvedController
 *
 */
@isTest
public class CDdCloseOnSolvedControllerTest {
    /**
     * Begin - Test class to execute if one of these classes is updated
     */
    private static List<System.Type> CLASS_REFERENCE = new List<System.Type>{
        CDdSupportHelper.class
    };

    @isTest
    static void testPositive() {
        DateTime dCreated = DateTime.now().addDays(-4);
        List<Case> caseList = TDdCaseFactory.createCaseRecords(1, 'Support');
        caseList[0].Origin = 'Chat';
        caseList[0].CreatedDate = dCreated;
        caseList[0].Solved_At__c = dCreated;
        caseList[0].Subject = 'test';
        caseList[0].Customer_Type__c = 'Merchant';
        caseList[0].Issue__c = 'Update Account Details';
        caseList[0].Issue_Type__c = 'Account Settings - MX';
        caseList[0].Resolution__c = 'Printer issue resolved - MX';
        caseList[0].Resolution_Type__c = 'Merchant Equipment';
        caseList[0].Validation_Bypass__c = true;
        insert caseList;

        LiveChatVisitor visitor = new LiveChatVisitor();
        insert visitor;

        LiveChatTranscript tx = new LiveChatTranscript(
            chatKey = '123', liveChatVisitorId = visitor.id, Status='Completed',
            CaseId = caseList[0].Id);
        insert tx;

        Test.startTest();

        CDdCloseOnSolvedController.setCaseToSolved(caseList[0].Id);

        Case cse = [select Id, Status from Case where Id =: caseList[0].Id];
        System.assert(cse.Status == 'Solved');

        Test.stopTest();
    }

    @isTest
    static void testPositiveMobile() {
        DateTime dCreated = DateTime.now().addDays(-4);
        List<Case> caseList = TDdCaseFactory.createCaseRecords(1, 'Support');
        caseList[0].Origin = 'Chat';
        caseList[0].CreatedDate = dCreated;
        caseList[0].Solved_At__c = dCreated;
        caseList[0].Subject = 'test';
        caseList[0].Customer_Type__c = 'Merchant';
        caseList[0].Issue__c = 'Update Account Details';
        caseList[0].Issue_Type__c = 'Account Settings - MX';
        caseList[0].Resolution__c = 'Printer issue resolved - MX';
        caseList[0].Resolution_Type__c = 'Merchant Equipment';
        caseList[0].Validation_Bypass__c = true;
        caseList[0].ChatKey__c = '123';
        insert caseList;

        LiveChatVisitor visitor = new LiveChatVisitor();
        insert visitor;

        LiveChatTranscript tx = new LiveChatTranscript(
            chatKey = '123', liveChatVisitorId = visitor.id, Status='Completed',
            CaseId = caseList[0].Id);
        insert tx;

        Test.startTest();

        CDdCloseOnSolvedController.setCaseToSolved(caseList[0].Id);

        Case cse = [select Id, Status from Case where Id =: caseList[0].Id];
        System.assert(cse.Status == 'Solved');

        Test.stopTest();
    }

    @isTest
    static void testLiveOrderNoUUIDException() {
        List<Case> caseList = TDdCaseFactory.createCaseRecords(1, 'Support');
        caseList[0].Origin = 'Chat';
        caseList[0].Subject = 'test';
        caseList[0].Customer_Type__c = 'Dasher';
        caseList[0].Issue_Type__c = 'Issue With Dropoff - Dx';
        caseList[0].Issue__c = 'Unable to Dropoff - Dx	';
        insert caseList;

        Test.startTest();
        try{
            CDdCloseOnSolvedController.setCaseToSolved(caseList[0].Id);
        }catch(Exception e){
            System.assertEquals(System.Label.Case_Notes_Require_Delv_for_LiveOrder, e.getMessage(),'Delivery UUID validation is not working as expected');
        }
        Test.stopTest();
    }

}