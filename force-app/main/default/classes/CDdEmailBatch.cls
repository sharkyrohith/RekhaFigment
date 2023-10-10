/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 01/11/2021
*
* @group Email
*
* @description A batch job to process and send e-mails
* Use this batch job to send e-mails, if you have
* - Input sObject type for which the emails are to be processed
* - A collection of SObject record identifiers (Required - whatIds)
* - A stored e-mail template with merged fields (Required - templateDeveloperName [must be valid/available])
* - An organization wide email address Id (Required)
* - A collection of To Address API fields to lookup on the corresponding sObject records (Optional)
* 
**************************************************************************************************************************************/
public class CDdEmailBatch implements Database.Batchable<sObject>, Database.Stateful {
    private EmailTemplate emailTemplate;
    private String orgWideEmailAddressId;
    private String sObjectType;
    private Set<Id> whatIds;
    private String whoIdApiField;
    private Set<String> toAddressApiFields;
    private String query; 
    /**
    * @description Constructor for the Batch Class
    * @param String templateDeveloperName - email template developer name
    * @param String orgWideEmailAddressId - organization wide email address Id
    * @param String sObjectType - sObject type  
    * @param Set<Id> whatIds - sObject record identifiers 
    * @param String whoIdApiField - represents the api field to retrieve the whoId from the 'what' SObject  
    * @param Set<String> toAddressApiFields - an optional collection of To Address API fields on the 'what' SObject    
    * @return 
    **/    
    public CDdEmailBatch(String templateDeveloperName, String orgWideEmailAddressId, String sObjectType, Set<Id> whatIds, String whoIdApiField, Set<String> toAddressApiFields) {
        this.emailTemplate = CDdEmailHelper.getEmailTemplate(templateDeveloperName);
        this.orgWideEmailAddressId = orgWideEmailAddressId;
        this.sObjectType = sObjectType;
        this.whatIds = whatIds;
        this.whoIdApiField = whoIdApiField;
        this.toAddressApiFields = toAddressApiFields;
        this.query = CDdEmailHelper.getQuery(sObjectType, whoIdApiField, toAddressApiFields);
    }
    /**
    * @description Execute the query and return the Database.QueryLocator
    **/	 
    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator(this.query);
    }
    /**
    * @description Prepare the email messages and send the emails for the input scoped sObjects
    **/	    
    public void execute(Database.BatchableContext bc, List<sObject> scope){
        List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
        for(SObject whatSObject : scope){
            emailMessages.add(CDdEmailHelper.getSingleEmailMessage(
                this.emailTemplate, this.orgWideEmailAddressId, whatSObject, this.whoIdApiField, this.toAddressApiFields));
        }
        CDdEmailHelper.sendEmail(emailMessages, false);
    }
    /**
    * @description Finish method
    **/	    
    public void finish(Database.BatchableContext BC){
    }
}