/**
 * @author Sanidhya Jain
 * @date 2023-08
 *
 * @description Class : BIZS-3185 Test class for CDdShowCaseDetailRecord
*/
@isTest
public class CDdShowCaseDetailRecordTest {
	//testSetup to create dumy data
    @testSetup
    public static void tesSetup(){
        List<Case> caseList = TDdCaseFactory.createCaseRecords(1, 'Support');
        insert caseList;
    }
    
    //Method to check what will happen if Case Deatil is not present on Case record
    @isTest
    static void testGetCaseDetailFieldSetNonValid(){
        CDdShowCaseDetailRecord.GetRecordFieldSetName recordFieldSetWrap = new CDdShowCaseDetailRecord.GetRecordFieldSetName();
        List<Case> caseList = new List<Case>();
        caseList = [Select id From Case Where RecordType.Name = 'Support'];
        test.startTest();
        recordFieldSetWrap = CDdShowCaseDetailRecord.getCaseDetailFieldSet(caseList[0].Id);
        test.stopTest();
        System.assertEquals(null, recordFieldSetWrap, 'recordFieldSetWrap should be empty');
    }
    
    //Method to check what will happen if Case Deatil is present on Case record
    @isTest
    static void testGetCaseDetailFieldSetValid(){
        
        List<Case> caseList = new List<Case>();
        caseList = [Select id,Origin,Customer_Type__c,RecordTypeId,Case_Detail__c From Case Where RecordType.Name = 'Support'];
        //create Case Detail record
            Case_Detail__c cDetail1 = new Case_Detail__c();
            cDetail1.Case_Origin__c = caseList[0].Origin;
            cDetail1.Case_Customer_Type__c = caseList[0].Customer_Type__c;
            insert cDetail1;
        
        CDdShowCaseDetailRecord.GetRecordFieldSetName recordFieldSetWrap = new CDdShowCaseDetailRecord.GetRecordFieldSetName();
        
        test.startTest();
            caseList[0].Case_Detail__c = cDetail1.id;
            update caseList;
            recordFieldSetWrap = CDdShowCaseDetailRecord.getCaseDetailFieldSet(caseList[0].Id);
        test.stopTest();
        System.assert(recordFieldSetWrap != null, 'recordFieldSetWrap should not be empty');
    }
}