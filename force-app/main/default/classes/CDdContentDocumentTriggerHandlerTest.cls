@IsTest
public with sharing class CDdContentDocumentTriggerHandlerTest {
    
    @IsTest
    static void testPreventDeletion(){
        String filename = 'test_filename.csv';
        String title = 'Test Filename';
        String tag = 'csv';
        String content = 'test content';

        ContentWorkspace cw = [SELECT Id FROM ContentWorkspace LIMIT 1];
        ContentVersion conVer = new ContentVersion();

        // S specify this document is in Salesforce
        conVer.ContentLocation = 'S'; 
        conVer.PathOnClient = filename;
        conVer.Title = title;
        conVer.VersionData = Blob.valueOf(content);
        conVer.TagCsv = tag;
        conver.firstPublishLocationId = cw.Id;
        insert conVer;

        ContentVersion insertedConVer = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id];

        List<ContentDocumentLink> cdl = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE ContentDocumentId =: insertedConVer.ContentDocumentId];
        List<ContentDocument> cdToDelete = [SELECT Id FROM ContentDocument WHERE Id =: insertedConVer.ContentDocumentId];
        System.debug(cdl);

        Test.startTest();
        
        CDdContentDocumentTriggerHandler contentDocumentTriggerHandler = new CDdContentDocumentTriggerHandler();
        contentDocumentTriggerHandler.validateContentDeletion(cdToDelete, cw);

        Test.stopTest();
    }
    
    @IsTest
    static void testBeforeDelete() {
        String filename = 'test_filename.csv';
        String title = 'Test Filename';
        String tag = 'csv';
        String content = 'test content';

        ContentVersion conVer = new ContentVersion();
        conVer.ContentLocation = 'S'; 
        conVer.PathOnClient = filename;
        conVer.Title = title;
        conVer.VersionData = Blob.valueOf(content);
        conVer.TagCsv = tag;

        insert conVer;
        ContentVersion insertedConVer = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id];
        ContentDocument cd = [SELECT Id FROM ContentDocument WHERE Id =: insertedConVer.ContentDocumentId];
        
        Test.startTest();
        delete cd;
        Test.stopTest();
    }
}