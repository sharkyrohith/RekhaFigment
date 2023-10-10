public class CDdBatchPromotionValidation implements Database.Batchable<sObject>, Database.Stateful {
    public static final vCS__c SETTINGS = vCS__c.getInstance();
    public Map<Id, List<Id>> userToPromoMap;
    public Map<Id, String> userToEmailMap;

    public CDdBatchPromotionValidation() {
        this.userToEmailMap = new Map<Id, String>();
        this.userToPromoMap = new Map<Id, List<Id>>();
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        // putting negative so that we only get records that are modified more than TIME_TO_WAIT minutes ago
        final Integer TIME_TO_WAIT = -10;
        String dateTimeCheck = Datetime.now().addMinutes(TIME_TO_WAIT).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        String query = 	'SELECT ' + 
            		   	'Id, Bff_Status__c, Bff_Error_Message__c, Bff_Promotion_Id__c, EmailRecipient__c, ' + 
                        'CreatedById ' +
            		   	'FROM Campaign ' +
            		   	'WHERE LastModifiedDate <= ' + dateTimeCheck + ' ' +
            		   	'AND Bff_Status__c = \'IN_PROGRESS\' ' +
                        'AND RecordTypeId = \'' + SETTINGS.CampaignPromotionRecordType__c + '\' ' +
            		   	'ORDER BY LastModifiedDate ASC';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<Campaign> scope) {
        List<Campaign> promotionsToUpdate = new List<Campaign>();
        // set all records matching criteria to Failure
        for (Campaign promo : scope) {
            if (userToPromoMap.get(promo.CreatedById) == null) {
                userToPromoMap.put(promo.CreatedById, new List<Id> { promo.Id });
                userToEmailMap.put(promo.CreatedById, promo.EmailRecipient__c);
            } else {
                userToPromoMap.get(promo.CreatedById).add(promo.Id);
            }
            promo.Bff_Status__c = 'FAILURE';
            promo.Bff_Error_Message__c = 'There was an unexpected error. Could not communicate with the server. Please try again or contact an administrator.';
        }    
        update scope;
    }
    
    public void finish(Database.BatchableContext BC) {
        if (SETTINGS.PromoValidationOutboundEmail__c) {
            //Send out email per user
            Messaging.SingleEmailMessage[] emails =   new List<Messaging.SingleEmailMessage>();
            
            for (Id user : userToPromoMap.keyset()) {
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.toAddresses = new String[] { userToEmailMap.get(user) };
                email.optOutPolicy = 'FILTER';
                email.subject = 'Your Merchant Promotion(s) Failed to Sync';
                String failedRecordLinks = '';
                for (Id currId : userToPromoMap.get(user)) {
                    failedRecordLinks += 'https://figment.lightning.force.com/' + currId + '\n\n';
                }
                // Ed - No email template, because we need to send in a list of Ids into the template. No time to figure that out
                // TODO - Email Template
                email.plainTextBody = 'Hello,\n\n' +
                                      'Your merchant promotion record(s) failed to sync. Please open the record(s) below and click ' + 
                                      'the "Re-Sync with Server" button. If the issue persists, please submit a support case ' + 
                                      'by emailing tools@doordash.com\n\n' + 
                                      failedRecordLinks + 
                                      '\n- Salesforce Team';
                emails.add(email);
            }
            Messaging.SendEmailResult[] results = Messaging.sendEmail(emails);
        }
    }
}