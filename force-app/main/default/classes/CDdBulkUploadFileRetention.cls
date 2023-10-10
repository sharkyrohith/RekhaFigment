/**
 * @name			CDdBulkUploadFileRetention
 * @author			Jose Vega <jose.vega@doordash.com>
 * @created			01 / 18 / 2021
 * @description		Handles the retention of the CSV files used in
 * Bulk Uploader
**/
public with sharing class CDdBulkUploadFileRetention {
    // String filename;
    // String tag;
    // String content;

    public CDdBulkUploadFileRetention(
        // String filename, String tag, String content
        ) {
        // this.filename = filename;
        // this.tag = tag;
        // this.content = content;
    }

    /**
     * @author			Jose Vega <jose.vega@doordash.com>
     * @created			01 / 19 / 2021
     * @description		method called to save the uploaded file
    **/
    public Id retainFile(String filename, String title, String tag, String content) {
        Id contentDocumentId = createContentVersion(filename, title, tag, content);
        return contentDocumentId;
    }

    public Id createLibrary(String name, String developerName) {
        Id contentWorkspaceId = createContentWorkspace(name, developerName);
        return contentWorkspaceId;
    }

    public Id linkFileToLibrary(Id contentDocumentId, Id contentLibraryId) {
        if (contentDocumentId == null || contentLibraryId == null) {
            throw new CDdBulkUploadFileRetentionException('Required DocumentId and WorkspaceId for linking');
        }

        Id contentDocumentLinkId = createContentDocumentLink(contentDocumentId, contentLibraryId);

        return contentDocumentLinkId;
    }

    /**
     * @author			Jose Vega <jose.vega@doordash.com>
     * @created			01 / 18 / 2021
     * @description		Description of your code
    **/
    private Id createContentVersion(String filename, String title, String tag, String content) {
        ContentVersion conVer = new ContentVersion();
        // S specify this document is in Salesforce
        conVer.ContentLocation = 'S'; 
        conVer.PathOnClient = filename;
        conVer.Title = title;
        conVer.VersionData = Blob.valueOf(content);
        conVer.TagCsv = tag;
        // conver.firstPublishLocationId= libraryId;
        insert conVer;

        ContentVersion insertedConVer = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id];

        return insertedConVer.ContentDocumentId;
    }

    /**
     * @author			Jose Vega <jose.vega@doordash.com>
     * @created			01 / 21 / 2021
     * @description		Creates Workspace
     * @return			Content Workspace ID
    **/
    private Id createContentWorkspace(String name, String developerName) {
        ContentWorkspace c = new ContentWorkspace ();
        c.DeveloperName = developerName;
        c.name= name;

        Insert c;

        return c.Id;
    }

    /**
     * @author			Jose Vega <jose.vega@doordash.com>
     * @created			01 / 18 / 2021
     * @description		Create link between library and content
    **/
    private Id createContentDocumentLink(Id contentId, Id contentLibraryId) {
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = contentId;
        cdl.ShareType = 'I';
        // Visibility to InternalUsers is now allowed when linking to
        // conent library.
        // cdl.Visibility = 'InternalUsers';
        cdl.LinkedEntityId = contentLibraryId;  // content library id
        insert cdl;

        return cdl.Id;
    }

    /**
     * @author			Jose Vega <jose.vega@doordash.com>
     * @created			01 / 18 / 2021
     * @description		Get library ID
    **/
    public Id getLibraryIdByDeveloperName(String developerName) {
        Id contentWorkspaceId;
        List<ContentWorkspace> cws = [
            SELECT Id FROM ContentWorkspace WHERE 
            DeveloperName =: developerName];

        for (ContentWorkspace cw: cws) {
            contentWorkspaceId = cw.Id;
        }

        System.debug('Content Workspace');
        System.debug(cws);
        
        return contentWorkspaceId;
    }

    public class CDdBulkUploadFileRetentionException extends Exception {}
}