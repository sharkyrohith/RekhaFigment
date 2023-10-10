@IsTest
public with sharing class CDdBulkUploadFileRetentionTest {

    @IsTest
    static void testCreateLibrary() {
        String libraryName = 'Test Library Name';
        String libraryDevName = 'Test_Library_Name';
        
        Test.startTest();
        
        CDdBulkUploadFileRetention bufr = new CDdBulkUploadFileRetention();
        Id libaryId = bufr.createLibrary(libraryName, libraryDevName);
        Id contentLibraryId = bufr.getLibraryIdByDeveloperName(libraryDevName);
        
        Test.stopTest();
        
        System.assertEquals(libaryId, contentLibraryId, 'Get Content Library Id failed');
    }
    
    @IsTest
    static void testRetainFile(){
        String filename = 'test_filename.csv';
        String title = 'Test Filename';
        String tag = 'csv';
        String content = 'test content';

        Test.startTest();
        CDdBulkUploadFileRetention bufr = new CDdBulkUploadFileRetention();

        Id contentDocumentId = bufr.retainFile(filename, title, tag, content);
        
        Test.stopTest();

        System.assert(contentDocumentId != null, 'Content was not uploaded');
    }
    
    @IsTest
    static void testInvalidLinkFile(){
        CDdBulkUploadFileRetention.CDdBulkUploadFileRetentionException frException;
        String filename = 'test_filename.csv';
        String title = 'Test Filename';
        String tag = 'csv';
        String content = 'test content';

        Test.startTest();
        CDdBulkUploadFileRetention bufr = new CDdBulkUploadFileRetention();

        Id contentDocumentId = bufr.retainFile(filename, title, tag, content);
        try {
        	Id contentDocumentLinkId = bufr.linkFileToLibrary(contentDocumentId, null);
        } catch(CDdBulkUploadFileRetention.CDdBulkUploadFileRetentionException e) {
            frException = e;
        }

        Test.stopTest();

        System.assert(frException != null, 'Exception handled');
    }
}