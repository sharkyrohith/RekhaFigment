/**
 * @author     Nathalie Mendezona
 * @date       07/25/2023
 * @decription Extension test class to perform combining multiple CSV documents into one
 *             This class is called by a button Admin_Access_Request__c.Combine_Audit_Logs
 *             https://doordash.atlassian.net/browse/BZAP-20763
 **/
@isTest
private class VCombineAuditLogsExtentionTest {
    static testMethod void testMergeAudits() {

        List<Admin_Access_Request__c> aars = new List<Admin_Access_Request__c>();
        aars.add(new Admin_Access_Request__c(Jira_Ticket_Number__c = 'BIZS-2000', Duration_of_Access__c = '1', Reason_For_Access__c = 'Hotfix / Incident'));
        aars.add(new Admin_Access_Request__c(Jira_Ticket_Number__c = 'BZAP-20763', Duration_of_Access__c = '1', Reason_For_Access__c = 'Hotfix / Incident'));
        insert aars;
        
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(aars);
        sc.setSelected(aars);
        VCombineAuditLogsExtension extension = new VCombineAuditLogsExtension(sc);
        
        createFile(aars.get(0));
        createFile(aars.get(1));
        
        System.assertNotEquals(null, extension.mergeAuditLogs());
    }
    
    static void createFile(Admin_Access_Request__c request) {
        List<String> csvHeaders = new List<String>{'Id', 'Action', 'Section', 'Created By', 'CreatedDate', 'Display', 'Jira Ticket Number'};
        String headerRow = String.join(csvHeaders,',') + '\n';
        String concatenatedStr = '';
        String username = 'Nathalie Mendezona';
        
        List<String> auditLogList = new List<String>();

        for(Integer i=0; i<10; i++) {
            auditLogList.add('Id'+i + ',' + 'MyAction'+i + ',' + 'MySection'+i + ',' + username + ',' + Date.today().format()
                                    + ',' + 'MyDisplay'+i + ',' + request.Jira_Ticket_Number__c);
        }
        concatenatedStr = headerRow + String.join(auditLogList,'\n');

        
        ContentVersion conVer = new ContentVersion();
        conVer.ContentLocation = 'S';
        conVer.PathOnClient = 'AdminAccessRequest_AuditLogs.csv';
        conVer.Title = 'SetupAuditTrail logs for ' + username + ' between ' + Date.today().format() + ' and ' + Datetime.now().format() + ' (' + request.Jira_Ticket_Number__c  + ')';
        conVer.VersionData = Blob.valueOf(concatenatedStr);
        conVer.IsMajorVersion = true;
        insert conVer;

        Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id].ContentDocumentId;
        ContentDocumentLink cDe = new ContentDocumentLink();
        cDe.ContentDocumentId = conDoc;
        cDe.LinkedEntityId = request.Id;
        cDe.ShareType = 'V';
        cDe.Visibility = 'AllUsers';
        insert cDe;

    }

    static testMethod void testSelectedSize() {
        List<Admin_Access_Request__c> aars = new List<Admin_Access_Request__c>();
        aars.add(new Admin_Access_Request__c());
        aars.add(new Admin_Access_Request__c());
        aars.add(new Admin_Access_Request__c());

        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(aars);
        sc.setSelected(aars);
        VCombineAuditLogsExtension extension = new VCombineAuditLogsExtension(sc);

        System.assertEquals('3', extension.getMySelectedSize());
    }
}