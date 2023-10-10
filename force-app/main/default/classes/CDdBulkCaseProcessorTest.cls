/**
 * CDdBulkCaseProcessorTest
 *
 * @author     Sahil
 * @date  2022-05-31
 * @decription Test class for CDdBulkCaseProcessor
 */
@isTest
public class CDdBulkCaseProcessorTest {

    /**
    * @author     Sahil
    * @date  2022-05-31
    * @decription test calling the LWC apex controller to process CSV
    * @param   None
    * @return  None
    */
    @isTest
    static void testImportCsv() {
        String filename = 'test_filename.csv';
        String title = 'Test Filename';
        String tag = 'csv';
        String content = 'Id,Issue_Type__c,Issue__c,Resolution_Type__c,Resolution__c\n'+
                         '5001a00000LU86dAAD,Completed Order - CX,Delivered Late,Completed Order - CX,Provided Credits';
        ContentWorkspace cw = [SELECT Id FROM ContentWorkspace LIMIT 1];
        ContentVersion conVer = new ContentVersion();
        conVer.ContentLocation = 'S'; 
        conVer.PathOnClient = filename;
        conVer.Title = title;
        conVer.VersionData = Blob.valueOf(content);
        conVer.TagCsv = tag;
        conver.firstPublishLocationId = cw.Id;
        insert conVer;
        ContentVersion insertedConVer = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id];
        List<ContentDocument> cdToProcess = [SELECT Id FROM ContentDocument WHERE Id =: insertedConVer.ContentDocumentId];
        System.assertEquals(1, cdToProcess.size(), 'content document should be inserted');
        Test.startTest();
        CDdBulkCaseProcessor.processCases(cdToProcess[0].Id, true, 'Test', 'Closed');
        Test.stopTest();
        List<Load_Request_Item__c> lriList = [SELECT Id FROM Load_Request_Item__c];
        System.assertEquals(1, lriList.size(), '1 staging record should be inserted');
    }
    
    /**
    * @author     Mahesh Chouhan
    * @date  2022-09-19
    * @decription test calling the LWC apex controller to process CSV with Error records
    * @param   None
    * @return  None
    */
    @isTest
    static void testImportCsvErrorRecord() {
        Load_Request_Item__c lRI = new Load_Request_Item__c();
        lRI.UUID__c = '5001a00000LU86dAAD';
        lRI.Status__c = CDdSupportConstants.ERROR_LABEL;
        lRI.Exception_Details__c = 'Sample Error Message';
        lRI.Error__c = true;
        
        insert lRI;
        
        String filename = 'test_filename.csv';
        String title = 'Test Filename';
        String tag = 'csv';
        String content = 'Id,Issue_Type__c,Issue__c,Resolution_Type__c,Resolution__c\n'+
                         '5001a00000LU86dAAD,Completed Order - CX,Delivered Late,Completed Order - CX,Provided Credits';
        ContentWorkspace cw = [SELECT Id FROM ContentWorkspace LIMIT 1];
        ContentVersion conVer = new ContentVersion();
        conVer.ContentLocation = 'S'; 
        conVer.PathOnClient = filename;
        conVer.Title = title;
        conVer.VersionData = Blob.valueOf(content);
        conVer.TagCsv = tag;
        conver.firstPublishLocationId = cw.Id;
        insert conVer;
        ContentVersion insertedConVer = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id];
        List<ContentDocument> cdToProcess = [SELECT Id FROM ContentDocument WHERE Id =: insertedConVer.ContentDocumentId];
        System.assertEquals(1, cdToProcess.size(), 'content document should be inserted');
        Test.startTest();
        CDdBulkCaseProcessor.processCases(cdToProcess[0].Id, true, 'Test', 'Closed');
        Test.stopTest();
        List<Load_Request_Item__c> lriList = [SELECT Id, Status__c FROM Load_Request_Item__c];
        System.assertEquals(1, lriList.size(), '1 staging record should be inserted');
        System.assertEquals(CDdSupportConstants.NEW_STATUS, lriList[0].Status__c, 'Status of Load Request Item is not same as expected.');
    }
}