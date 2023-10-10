/**
 * Created by Jeremy S. Johnson, Perficient Inc., 1/27/2020.
 */
public with sharing class CDdBatchLeadConvert implements Database.Batchable<String>, Database.Stateful {
    private final String status = 'Meeting Ran / Negotiated';
    private final String partitionPrefix = 'local.DoorDash.bulkLeadConvert';
    private final String hrefPre = '<a href="' + Url.getSalesforceBaseUrl().toExternalForm();
    private final String hrefPost = '">';
    private final String hrefClose = '</a>';
    private CDdBulkLeadConvertController.Context ctx;

    public CDdBatchLeadConvert(CDdBulkLeadConvertController.Context ctx) {
        this.ctx = ctx;
    }

    public Iterable<String> start(Database.BatchableContext context) {
        return this.ctx.ids;
    }

    public void execute(Database.BatchableContext context, List<String> ids) {
        List<Database.LeadConvert> lcs = new List<Database.LeadConvert>();

        for(String id : ids) {
            Lead lead = ctx.leadMap.get(id);
            Database.LeadConvert leadConvert = new Database.LeadConvert();
            leadConvert.setLeadId(id);
            leadConvert.setConvertedStatus(this.status);
            leadConvert.setOwnerId(ctx.userId);
            leadConvert.setBypassAccountDedupeCheck(true);
            leadConvert.setBypassContactDedupeCheck(true);
            if(lead.Account__c != null) {
                leadConvert.setAccountId(lead.Account__c);
            }

            lcs.add(leadConvert);
        }

        List<Database.LeadConvertResult> lcrs = Database.convertLead(lcs, false);

        for(Database.LeadConvertResult lcr : lcrs) {
            Id leadId = lcr.getLeadId();
            ctx.accountMap.put(leadId, lcr.getAccountId());
            ctx.contactMap.put(leadId, lcr.getContactId());
            ctx.opportunityMap.put(leadId, lcr.getOpportunityId());
            for(Database.Error error : lcr.getErrors()) {
                ctx.batchMessages.add('Lead: ' + leadId + ', ' + error.getMessage());
            }
        }

        List<Account> accountsToUpdate = new List<Account>();
        for(String id : ids) {
            Lead lead = ctx.leadMap.get(id);
            if(lead.Account__c == null && lead.Parent_Account_ID__c != null) {
                Id accountId = ctx.accountMap.get(lead.Id);
                Id parentId = ctx.leadMap.get(lead.Id).Parent_Account_ID__c;
                if(accountId != null && parentId != null) {
                    accountsToUpdate.add(new Account(Id=accountId, ParentId=parentId));
                } else {
                    System.debug(LoggingLevel.ERROR, 'CDdBatchLeadConvert.execute, leadId: ' + lead.Id + ', accountId: ' + accountId + ', parentId: ' + parentId);
                }
            }
        }
        update accountsToUpdate;
    }

    public void finish(Database.BatchableContext context) {
        Cache.Org.put(partitionPrefix + ctx.userId, ctx);

        String body = '<p>You Bulk Lead Conversion request completed with ' + ctx.batchMessages.size() + ' error(s).</p>';

        if(ctx.batchMessages.size() > 0) {
            body += '<h3>Errors</h3>';
        }

        Integer lineNumber = 1;
        for(String error : ctx.batchMessages) {
            body += '<p>' + String.valueOf(lineNumber++) + '. ' + error + '</p>';
        }

        body += '<h3>All Results</h3>';

        lineNumber = 1;
        for(String leadId : ctx.ids) {
            String accountId = ctx.accountMap.get(leadId);
            String contactId = ctx.contactMap.get(leadId);
            String opportunityId = ctx.opportunityMap.get(leadId);
            body += '<p>' + String.valueOf(lineNumber++) + '. Lead: ' + createHref(leadId)
                + ', Account: ' + createHref(accountId)
                + ', Opportunity: ' + createHref(opportunityId)
                + ', Contact: ' + createHref(contactId)
                +'</p>';
        }

        try {
            User user = [select Email from User where Id =: ctx.userId];
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.toAddresses = new String[] { user.Email };
            email.subject = 'Your Bulk Lead Convert request is complete';
            email.htmlBody = body;
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'CDdUploaderBatch.finish, Messaging.sendEmail: ' + e.getMessage());
        }
    }

    private String createHref(String id) {
        if(id == null) {
            return '[null]';
        } else {
            return hrefPre + '/' + id + hrefPost + id + hrefClose;
        }
    }
}