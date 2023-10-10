/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 01/11/2021
*
* @group Email
*
* @description A Service class to process and send e-mails
* 
**************************************************************************************************************************************/
public class CDdEmailService {
    public static Integer THRESHOLD_SIZE = 50;
    public static Integer BATCH_SIZE = 50;
    /**
    * @description Prepare email messages and send emails
    * @param String templateDeveloperName - email template developer name
    * @param String orgWideEmailAddressId - organization wide email address Id
    * @param String sObjectType - sObject type  
    * @param Set<Id> whatIds - sObject record identifiers 
    * @param String whoIdApiField - represents the api field to retrieve the whoId from the 'what' SObject  
    * @param Set<String> toAddressApiFields - an optional collection of To Address API fields on the 'what' SObject    
    * @return 
    **/ 
    public static void sendEmails(String templateDeveloperName, String orgWideEmailAddressId, String sObjectType, Set<Id> whatIds, String whoIdApiField, Set<String> toAddressApiFields){
        if (whatIds!=null && !whatIds.isEmpty()){
            if (whatIds.size() > THRESHOLD_SIZE){
                Database.executeBatch(new CDdEmailBatch(templateDeveloperName, orgWideEmailAddressId, sObjectType, whatIds, whoIdApiField, toAddressApiFields), BATCH_SIZE);
            } else {
                EmailTemplate emailTemplate = CDdEmailHelper.getEmailTemplate(templateDeveloperName);
                List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
                for (SObject whatSObject: Database.query(CDdEmailHelper.getQuery(sObjectType, whoIdApiField, toAddressApiFields))){
                    emailMessages.add(CDdEmailHelper.getSingleEmailMessage(
                        emailTemplate, orgWideEmailAddressId, whatSObject, whoIdApiField, toAddressApiFields));
                }
                CDdEmailHelper.sendEmail(emailMessages, false);
            }
        }
    }
}