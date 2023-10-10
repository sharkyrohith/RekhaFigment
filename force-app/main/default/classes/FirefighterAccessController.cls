/*
    Ticket      : https://doordash.atlassian.net/browse/BZAP-16407
    Author      : Sid Agarwal, 2022
    Test Class  : JiraConnectorTests.cls
*/

public class FirefighterAccessController 
{
    // variables passed from the flow
    public class flowInput 
    {
        @InvocableVariable 
        public string recordId;

        @InvocableVariable 
        public string action;
    }

    // make callout to Jira to perform certaion tasks as per incoming request status
    @InvocableMethod(label='JiraConnector' description='Check if the provided ticket number exists in the Jira and matches the defined criteria')
    public static void JiraConnector(List<flowInput> flowInput) 
    {
        switch on flowInput[0].action {
            when 'validateTicket' {
                JIRAConnector.getTicketByNameFuture(flowInput[0].recordId);
            }	
            when 'createSubTask' {
                JIRAConnector.createSubTaskFuture(flowInput[0].recordId);
            }
            when 'addCommentWithAuditLogs' {
                JIRAConnector.addCommentWithAuditLogsFuture(flowInput[0].recordId);
            }
            when 'updateTicketToComplete' {
                JIRAConnector.updateTicketToCompleteFuture(flowInput[0].recordId);
            }
        }
    }

}