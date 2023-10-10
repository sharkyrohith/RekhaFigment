/**
 * @author     Nathalie Mendezona
 * @date       07/25/2023
 * @decription Extension class to perform combining multiple CSV documents into one
 *             This class is called by a button Admin_Access_Request__c.Combine_Audit_Logs
 *             https://doordash.atlassian.net/browse/BZAP-20763
 **/
public class VCombineAuditLogsExtension {
    ApexPages.StandardSetController setCon;
    public String error { get; set; }
    public PageReference originalUrl { get; set; }

    public VCombineAuditLogsExtension(ApexPages.StandardSetController controller) {
        setCon = controller;
    }

    public String getMySelectedSize() {
        return setCon.getSelected().size() + '';
    }

    public PageReference mergeAuditLogs(){
        originalUrl = setCon.cancel();
        Set<Id> recordIds = new Set<Id>();
        for (Admin_Access_Request__c aar: (List<Admin_Access_Request__c>) setCon.getSelected()) {
            recordIds.add(aar.Id);
        }
        List<ContentDocumentLink> contentDocs = [SELECT Id, ContentDocumentId, ContentDocument.title
                                                 FROM ContentDocumentLink
                                                 WHERE LinkedEntityId in: recordIds
                                                 	WITH SECURITY_ENFORCED];

        Set<Id> contentLinks = new Set<Id>();
        for(ContentDocumentLink contentDoc: contentDocs){
            contentLinks.add(contentDoc.ContentDocumentId);
        }

        List<ContentVersion> contentVersions = [SELECT Id, Title, VersionData
                                                FROM ContentVersion
                                                WHERE ContentDocumentId in: contentLinks
                                                	WITH SECURITY_ENFORCED
                                                	ORDER BY CreatedDate ASC];

        List<string> contDocIds = new List<String>();
        String str = '';
        String header = 'Id,Action,Section,Created By,Created Date,Display,Jira Ticket Number';
        for (ContentVersion conDoc: contentVersions) {
            String docString = conDoc.VersionData.toString()+',';
            docString = docString.remove('Id,Action,Section,Created By,CreatedDate,Display,Jira Ticket Number');
            str += docString;
        }
        str = header + str;

        Document o = new Document(
                FolderId = UserInfo.getUserId(),
                Name = 'SetupAuditTrail logs for Multiple Tickets.csv',
                Body = Blob.valueOf(str)
            );
        insert o;
        return new PageReference('/servlet/servlet.FileDownload?file=' + o.Id);
    }
}