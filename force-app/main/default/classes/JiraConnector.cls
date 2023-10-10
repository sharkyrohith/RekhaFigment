/*
    Ticket      : https://doordash.atlassian.net/browse/BZAP-16407
    Author      : Sid Agarwal, 2022
    Test Class  : JiraConnectorTests.cls
*/

public with sharing class JiraConnector
{
    public static String errorMessage = null;                                       // stores any error message may encounter in the apex code
    public static Admin_Access_Request__c request = null;                           // stores reference to parent request record
    public static String namedCredentialName = 'Firefighter_Jira';                  // stores name of the Named Credential to use to make Jira callouts
    public static FINAL Integer jiraBodyMaxSize = 70000;
	public static List<SetupAuditTrail> setupAuditTrails;							// stores the SetupAuditTrail records of changes made by user
    // --- JIRA Callouts --- //

    /*
        Examples:
            BZAP-17392 Story
            BIZS-2000  Task
            BIZS-1700  Enhancement
    */
    @future(callout=true)
    public static void getTicketByNameFuture(String requestId)
    {
        if(!test.isRunningTest())   getTicketByName(requestId, true, true);
    }
    public static HttpResponse getTicketByName(String requestId, Boolean updateRequestRecord, Boolean checkTicketCompliance)
    {
        HttpResponse response = null;
        errorMessage =  '';

        try {
            // get record
            request = [Select id, CreatedDate, CreatedBy.Name, Jira_Ticket_Number__c, Status__c,
                            Reason_for_Access__c, Duration_of_Access__c
                            from Admin_Access_Request__c where id =: requestId];

            // prepare callout endpoint (its dynamic so have to customize it)
            String endpoint = 'callout:' + namedCredentialName + '/' + request.Jira_Ticket_Number__c;

            // make callout
            response = makeCalloutToJira(namedCredentialName, endpoint, 'GET', null);

            // check callout response
            if(!String.valueOf(response.getStatusCode()).startsWith('20')) {
                // handle error
                errorMessage = calloutException(response.getBody());
            } else {
                if(checkTicketCompliance) {
                    if(response != null) {
                        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                        Map<String, Object> fieldsMap = (Map<String, Object>)responseMap.get('fields');
                        Map<String, Object> issuetypeMap = (Map<String, Object>)fieldsMap.get('issuetype');
                        Map<String, Object> statusMap = (Map<String, Object>)fieldsMap.get('status');

                        // check if ticket is compliant
                        String isTicketCompliant = checkTicketCompliance(request.Reason_for_Access__c, String.valueOf(issuetypeMap.get('name')), String.valueOf(statusMap.get('name')));
                        if(String.isNotBlank(isTicketCompliant)) {
                            errorMessage = isTicketCompliant;
                        }
                    }
                }
            }
        }
        catch(exception e) {
            // print exception
            printException(e);

            // update errorMessage
            errorMessage = e.getMessage() + e.getStackTraceString();

            return null;
        }
        finally {
            if(updateRequestRecord) {
                // update the request
                if(String.isBlank(errorMessage)) {
                    request.Error_Message__c = '';
                    request.Status__c = 'Validated';
                }
                else {
                    request.Error_Message__c = errorMessage;
                    request.Status__c = 'Failed';
                }
                update request;
            }
        }

        return response;
    }

    @future(callout=true)
    public static void createSubTaskFuture(String requestId)
    {
        if(!test.isRunningTest())   createSubTask(requestId);
    }
    public static void createSubTask(Id requestId)
    {
        errorMessage =  '';                                             // record any error message
        createTicketResponse createSubTaskResponse;                     // jira callout response

        try {
            // get record
            request = [Select id, CreatedDate, CreatedBy.Name, Jira_Ticket_Number__c, Status__c,
                            Reason_for_Access__c, Duration_of_Access__c
                            from Admin_Access_Request__c where id =: requestId];

            // get parent ticket details
            HttpResponse getTicketByNameResponse = getTicketByName(requestId, false, false);

            // if parent ticket found, then create a new subtask under it
            if(getTicketByNameResponse != null)
            {
                // parse "getTicketByNameResponse" to get prject id and other custom field details etc.
                Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(getTicketByNameResponse.getBody());
                Map<String, Object> fieldsMap = (Map<String, Object>)responseMap.get('fields');
                Map<String, Object> projectMap = (Map<String, Object>)fieldsMap.get('project');

                // prepare callout body
                ticketProject project       = new ticketProject();                  // project
                project.id                  = String.valueOf(projectMap.get('id'));
                ticketIssueType issuetype   = new ticketIssueType();                // issue type (default to 5 "Sub-task")
                issuetype.id                = '5';
                subTaskParent parent        = new subTaskParent();                  // parent
                parent.key                  = request.Jira_Ticket_Number__c;
                subTaskFields fields        = new subTaskFields();                  // sub-task subject/description
                fields.project              = project;
                fields.summary              = formatTicketTitle(request.CreatedBy.Name);
                fields.description          = formatTicketDesc(request);
                fields.issuetype            = issuetype;
                fields.parent               = parent;
                fields.customfield_15564    = fieldsMap.get('customfield_15564');   // this may differ as per instance configs
                createSubTaskRequest ticket = new createSubTaskRequest();
                ticket.fields               = fields;

                // prepare callout endpoint (its dynamic so have to customize it)
                String endpoint = 'callout:' + namedCredentialName;

                // make callout
                HttpResponse res = makeCalloutToJira(namedCredentialName, endpoint, 'POST', JSON.serializePretty(ticket));

                // check callout response
                if(!String.valueOf(res.getStatusCode()).startsWith('20')) {
                    // handle error
                    errorMessage = calloutException(res.getBody());
                }
                else {
                    // handle success - get new ticket id/name
                    createSubTaskResponse = (createTicketResponse) JSON.deserialize(res.getBody(), createTicketResponse.class);
                }
            }
            else
            {
                errorMessage = 'We cound not locate the ticket. Creating new ticket instead.';
            }
        }
        catch(exception e)
        {
            // print exception
            printException(e);

            // update errorMessage
            errorMessage = e.getMessage() + e.getStackTraceString();
        }
        finally
        {
            // if success, update the request with new sub-task id
            if(String.isBlank(errorMessage) && createSubTaskResponse != null) {
                request.Jira_Sub_Ticket_Number__c = createSubTaskResponse.key;
                request.Status__c = 'Active';
                request.Error_Message__c = '';
            }
            else {
                request.Error_Message__c = errorMessage;
                request.Status__c = 'Failed';
            }
            update request;
        }
    }

    @future(callout=true)
    public static void addCommentWithAuditLogsFuture(String requestId)
    {
        if(!test.isRunningTest())   addCommentWithAuditLogs(requestId);
    }
    public static void addCommentWithAuditLogs(Id requestId)
    {
        errorMessage =  '';

        try {
            // get record
            request = [Select id, CreatedDate, CreatedBy.Name, Jira_Ticket_Number__c, Status__c,
                            Reason_for_Access__c, Duration_of_Access__c, Jira_Sub_Ticket_Number__c
                            from Admin_Access_Request__c where id =: requestId];
            // get audit logs
            String auditLogs = getAuditLogs(); // for Jira Ticket comment
			List<String> auditLogList = getAuditLogList(); // for AAR's File related list (CSV file)

            // prepare callout body
            addCommentRequest comment   = new addCommentRequest();
            comment.body                = auditLogs;

            // prepare callout endpoint (its dynamic so have to customize it)
            String endpoint = 'callout:' + namedCredentialName + '/' + request.Jira_Sub_Ticket_Number__c + '/comment';

            // make callout
            HttpResponse res = makeCalloutToJira(namedCredentialName, endpoint, 'POST', JSON.serializePretty(comment));

            // check callout response
            if(!String.valueOf(res.getStatusCode()).startsWith('20')) {
                // handle error
                errorMessage = calloutException(res.getBody());
            }

            // create new file with audit logs
            if(String.isNotBlank(auditLogs)) {
                createFile(requestId, auditLogList);
            }
        }
        catch(exception e)
        {
            // print exception
            printException(e);

            // update errorMessage
            errorMessage = e.getMessage() + e.getStackTraceString();
        }
        finally
        {
            // if success, update the request status
            if(String.isBlank(errorMessage)) {
                request.Error_Message__c = '';
                request.Status__c = 'Closed';
            }
            else {
                request.Error_Message__c = errorMessage;
                request.Status__c = 'Failed';
            }
            update request;
        }
    }

    @future(callout=true)
    public static void updateTicketToCompleteFuture(String requestId)
    {
        if(!test.isRunningTest())   updateTicketToComplete(requestId);
    }
    public static void updateTicketToComplete(Id requestId)
    {
        errorMessage =  '';

        try {
            // get record
            request = [Select id, CreatedDate, CreatedBy.Name, Jira_Ticket_Number__c, Status__c,
                            Reason_for_Access__c, Duration_of_Access__c, Jira_Sub_Ticket_Number__c
                            from Admin_Access_Request__c where id =: requestId];

            // prepare callout body
            transitionRequest transition    = new transitionRequest();
            transition tr                   = new transition();
            tr.id                           = '31';             // id for "Complete" status
            transition.transition           = tr;

            // prepare callout endpoint (its dynamic so have to customize it)
            String endpoint = 'callout:' + namedCredentialName + '/' + request.Jira_Sub_Ticket_Number__c + '/transitions';

            // make callout
            HttpResponse res = makeCalloutToJira(namedCredentialName, endpoint, 'POST', JSON.serializePretty(transition));

            // check callout response
            if(!String.valueOf(res.getStatusCode()).startsWith('20')) {
                // handle error
                errorMessage = res.getBody();
            }
        }
        catch(exception e)
        {
            // print exception
            printException(e);

            // update errorMessage
            errorMessage = e.getMessage() + e.getStackTraceString();
        }
        finally
        {
            // if success, update the request status
            if(String.isBlank(errorMessage)) {
                request.Error_Message__c = '';
                request.Status__c = 'Closed';
            }
            else {
                request.Error_Message__c = errorMessage;
                request.Status__c = 'Failed';
            }
            update request;
        }
    }

    // --- JIRA "Create Ticket" Request/Response Wrapper --- //

    public class ticketProject
    {
        string id                   {get; set;}
    }

    public class ticketIssueType
    {
        string id                   {get; set;}
        string name                 {get; set;}
    }
    public class createSubTaskRequest
    {
        subTaskFields fields         {get; set;}
    }
    public class subTaskFields
    {
        string summary              {get; set;}
        string description          {get; set;}
        ticketProject project       {get; set;}
        ticketIssueType issuetype   {get; set;}
        list<string> labels         {get; set;}
        subTaskParent parent        {get; set;}
        object customfield_15564    {get; set;} // required field "pod name"
    }
    public class subTaskParent
    {
        string key                  {get; set;}
    }

    public class createTicketResponse
    {
        string id                   {get; set;}
        string key                  {get; set;}
    }

    public class addCommentRequest
    {
        string body                 {get; set;}
    }

    public class transitionRequest
    {
        transition transition       {get; set;}
    }
    public class transition
    {
        String id                   {get; set;}
    }

    // --- Helper methods --- //

    // Helper to validate request and related ticket status/type
    private static String checkTicketCompliance(String requestType, String ticketType, String ticketStatus)
    {
        if (requestType == 'Pre/post deployment manual change') {
            if(ticketType != 'Bug' && ticketType != 'Story' && ticketType != 'Enhancement' && ticketType != 'Task') {
                return System.Label.Firefighter_Access_Error_Message;

            }
            else if((ticketType != 'Bug' || ticketType != 'Story' || ticketType != 'Enhancement' || ticketType != 'Task') &&
                    (ticketStatus != 'Ready for Release' && ticketStatus != 'Merged to Staging'))
            {
                return System.Label.Firefighter_Access_Error_Message;
            }
        }
        return null;
    }

    // Helper to henerate ticket description
    private static String formatTicketDesc(Admin_Access_Request__c request)
    {
        string result = '';
        result += 'Environment - ' + System.URL.getSalesforceBaseUrl().getHost() + '\n';
        result += 'Start Time - ' + Datetime.Now().format() + '\n';
        result += 'Requested By - ' + UserInfo.getName() + '\n';
        result += 'Jira Ticket Number - ' + request.Jira_Ticket_Number__c + '\n';
        result += 'Duration of Access - ' + request.Duration_of_Access__c + ' hrs' +  '\n';
        result += 'Reason for Access - ' + request.Reason_for_Access__c + '\n';
        return result;
    }

    // Helper to henerate ticket title
    private static String formatTicketTitle(String userName)
    {
        return (getSfInstanceType() == 'Sandbox' ? ('Sandbox: ') : '') + 'Firefighter access for "' + userName + '" ' + Datetime.Now().format();
    }

    // Get Audit Logs for the user
    // Using "HTML Text Formatting Notation" for formatting
    private static String getAuditLogs()
    {
        String userName = request.CreatedBy.Name;
        String auditLogs = '+SetupAuditTrail logs for ' + userName + ' between ' + request.CreatedDate.format() + ' and ' + Datetime.now().format() + '+\n\n';

        for(SetupAuditTrail log : queryLogs())
        {
            auditLogs += '*' + log.Id + ' ' + log.Action + ' ' + log.Section + ' ' + log.CreatedDate.format().substringAfter(' ') + '* (' + log.Display + ')\n';
        }

        auditLogs = stringTruncate(auditLogs, jiraBodyMaxSize);
        return auditLogs;
    }

    /*
     * @author      Nathalie Mendezona
     * @date        February 2023
     * @decription  BZAP-18815 - Get Audit Logs for the user in List for preparation for csv file.
     *              Note difference in columns between csv and JIRA comment generated
     * @param       None
     * @return      List<SetupAuditTrail>
     **/
    private static List<String> getAuditLogList()
    {
        List<String> auditLogList = new List<String>();

        for(SetupAuditTrail log : queryLogs())
        {
            auditLogList.add(log.Id + ',' + log.Action + ',' + log.Section + ',' + log.CreatedBy.Name + ',' + log.CreatedDate.format().substringAfter(' ')
                                    + ',' + log.Display + ',' + request.Jira_Ticket_Number__c);
        }

        return auditLogList;
    }

    /*
     * @author      Nathalie Mendezona
     * @date        February 2023
     * @decription  BZAP-18815 - Performs the SOQL query after checking if it hasn't been queried yet
     * @param       None
     * @return      List<SetupAuditTrail>
     **/
    private static List<SetupAuditTrail> queryLogs() {
        if (setupAuditTrails == null) {
            DateTime startTime = request.CreatedDate;
            String userName = request.CreatedBy.Name;
            String soql = 'SELECT Id, Action, DelegateUser, Display, Section, CreatedDate, CreatedById, CreatedBy.Name, CreatedBy.Email, CreatedBy.IsActive ' +
                          'FROM SetupAuditTrail ' +
                          'WHERE CreatedDate >= :startTime and CreatedBy.Name =: userName ' +
                          'ORDER BY CreatedDate';
            return Database.query(soql);
        }
        return setupAuditTrails;
    }

    /*
     * @author      Nathalie Mendezona
     * @date        February 2023
     * @decription  BZAP-18815 - Stores audit logs in a csv file
     *              Takes a list of strings and create a csv document that will be
     *              attached to the AAR record
     * @param       Id
     *              List<String>
     * @return      None
     **/
    private static void createFile(Id requestId, List<String> auditLogList)
    {
        String userName = request.CreatedBy.Name;
        List<String> csvHeaders = new List<String>{'Id', 'Action', 'Section', 'Created By', 'CreatedDate', 'Display', 'Jira Ticket Number'};
        String headerRow = String.join(csvHeaders,',') + '\n';
        String concatenatedStr = headerRow + String.join(auditLogList,'\n');

        ContentVersion conVer = new ContentVersion();
        conVer.ContentLocation = 'S';
        conVer.PathOnClient = 'AdminAccessRequest_AuditLogs.csv';
        conVer.Title = 'SetupAuditTrail logs for ' + userName + ' between ' + request.CreatedDate.format() + ' and ' + Datetime.now().format() + ' (' + request.Jira_Ticket_Number__c  + ')';
        conVer.VersionData = Blob.valueOf(concatenatedStr);
        conVer.IsMajorVersion = true;
        insert conVer;

        Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id].ContentDocumentId;
        list<ContentDocumentLink> cdl = [SELECT ContentDocument.title FROM ContentDocumentLink WHERE ContentDocumentId =: conDoc AND LinkedEntityId =: requestId];

        if(cdl.size() == 0)
        {
            ContentDocumentLink cDe = new ContentDocumentLink();
            cDe.ContentDocumentId = conDoc;
            cDe.LinkedEntityId = requestId;
            cDe.ShareType = 'V';
            cDe.Visibility = 'AllUsers';
            insert cDe;
        }
    }

    // Helper to get current SF instance type
    private static String getSfInstanceType()
    {
        boolean isSandbox = [Select Name, InstanceName, IsSandbox, NamespacePrefix, OrganizationType FROM Organization].IsSandbox;
        return (isSandbox ? 'Sandbox' : 'Production');
    }

    // Helper to print exception for debugging
    private static void printException(exception e)
    {
        // disabling to be comply with codescan
        // system.debug('Exception: ' + e);
        // system.debug('Exception GetMessage: ' + e.getMessage());
        // system.debug('Exception StackTrace: ' + e.getStackTraceString());
        // system.debug('Exception TypeName: ' + e.getTypeName());
    }

    // Helper to truncate string
    private static String stringTruncate(String str, Integer length){
        if(str == null || str == '')    {return str;}
        return (str.length() > length ? str.substring(0, length) : str);
    }

    // Helper to make callout to Jira
    private static HttpResponse makeCalloutToJira(String namedCredentialName, String endpoint, String method, String body)
    {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod(method);
        request.setHeader('Content-Type', 'application/json');
        if(String.isNotBlank(body)) request.setbody(body);

        Http http = new Http();
        HTTPResponse response = http.send(request);

        return response;
    }

    // Helper to parse callout exception message
    public static String calloutException(String calloutResponseBody)
    {
        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(calloutResponseBody);
        List<Object> errorMessages = (List<Object>)responseMap.get('errorMessages');
        return (errorMessages == null || errorMessages.isEmpty()) ? calloutResponseBody : String.valueOf(errorMessages[0]);
    }

}