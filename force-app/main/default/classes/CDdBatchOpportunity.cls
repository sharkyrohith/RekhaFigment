/**
 * Created by Jeremy S. Johnson (Perficient, Inc)
*
 * Implements BZAP-7037: "Bulk Creation Opportunities" button and batch job
 * Implements BZAP-7046: Batch Job "Retry" Process and GridBuddy button
  */

public with sharing class CDdBatchOpportunity implements Database.Batchable<Opportunity>, Database.Stateful {
    private final String partitionPrefix = 'local.DoorDash.bo';
    private final String result = '<p>{0}. <a href="' + Url.getSalesforceBaseUrl().toExternalForm() + '/{1}">{1}</a></p>';
    private CDdBulkOpportunityController.Context ctx;

    public CDdBatchOpportunity(CDdBulkOpportunityController.Context ctx) {
        this.ctx = ctx;
    }

    public Iterable<Opportunity> start(Database.BatchableContext context) {
        return ctx.opps;
    }

    public void execute(Database.BatchableContext context, List<Opportunity> opps) {
        List<Database.SaveResult> results = Database.insert(opps, false);

        Integer i = 0;
        for(Database.SaveResult result : results) {
            ctx.oppIds.add(result.getId());

            if (result.getErrors().size() > 0) {
                for (Database.Error error : result.getErrors()) {
                    ctx.batchMessages.add(error.getMessage() + ': ' + String.join(error.fields, ', '));
                }
            }
            i++;
        }
    }

    public void finish(Database.BatchableContext context) {
        Cache.Org.put(partitionPrefix + ctx.userId, ctx);

        String body = String.format('<p>Your Bulk Opportunity request completed with {0} error(s).</p>', new List<Integer> {ctx.batchMessages.size()});

        if(ctx.batchMessages.size() > 0) {
            body += '<h3>Errors</h3>';
        }

        Integer lineNumber = 1;
        for(String error : ctx.batchMessages) {
            body += String.format('<p>{0}. {1}</p>', new List<String> {String.valueOf(lineNumber++), error});
        }

        body += '<h3>All Results</h3>';

        lineNumber = 1;
        for(String id : ctx.oppIds) {
            body += String.format(result, new List<String> {String.valueOf(lineNumber++), id});
        }

        try {
            User user = [select Email from User where Id =: ctx.userId];
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.toAddresses = new String[] { user.Email };
            email.subject = 'Your Bulk Opportunity request is complete';
            email.htmlBody = body;
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'CDdUploaderBatch.finish, Messaging.sendEmail: ' + e.getMessage());
        }
    }
}