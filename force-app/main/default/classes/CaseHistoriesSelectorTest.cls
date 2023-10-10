/**
 * @description Test Class for CaseHistoriesSelector class
 * @author Mahesh Chouhan
 * @date May 2023
 */
@isTest
public class CaseHistoriesSelectorTest {

    /**
     * @description test method for selectById method
     */
    @isTest
    static void testSelectById(){
        List<Case> caseRecord = TDdCaseFactory.createCaseRecords(1, CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER);
        insert caseRecord;
        CaseHistory cHist = new CaseHistory();
        cHist.caseId = caseRecord[0].Id;
        cHist.field ='Owner';
        insert cHist;

        Test.startTest();
        List<CaseHistory> expectedCaseHistory = CaseHistoriesSelector.newInstance().selectById(new Set<Id>{cHist.Id});
        Test.stopTest();

        System.assertEquals(expectedCaseHistory[0].Id, cHist.Id, 'Case History record is not same as expected.');
        System.assertEquals(expectedCaseHistory[0].field, cHist.field, 'Field on Case History record is not same as expected.');
    }
    
    /**
     * @description test method for selectByCaseIdAndFields method
     */
    @isTest
    static void testSelectByCaseIdAndFields(){
        List<Case> caseRecord = TDdCaseFactory.createCaseRecords(1, CDdSupportConstants.RECORDTYPE_LABEL_CUSTOMER);
        insert caseRecord;
        CaseHistory cHist = new CaseHistory();
        cHist.caseId = caseRecord[0].Id;
        cHist.field ='Owner';
        insert cHist;

        Test.startTest();
        List<CaseHistory> expectedCaseHistory = CaseHistoriesSelector.newInstance().selectByCaseIdAndFields(new Set<Id>{caseRecord[0].Id}, new Set<String>{'Owner'});
        Test.stopTest();

        System.assertEquals(expectedCaseHistory[0].Id, cHist.Id, 'Case History record is not same as expected.');
        System.assertEquals(expectedCaseHistory[0].field, cHist.field, 'Field on Case History record is not same as expected.');
    }
}