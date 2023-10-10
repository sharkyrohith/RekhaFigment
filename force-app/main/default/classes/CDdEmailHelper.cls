/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 01/11/2021
*
* @group Email
*
* @description A helper class to process and send e-mails
* 
**************************************************************************************************************************************/
public class CDdEmailHelper {
    /**
    * @description Prepare and return an instance of Messaging.SingleEmailMessage
    * @param EmailTemplate emailTemplate  
    * @param Id orgWideEmailAddressId - organization wide email address Id  
    * @param SObject whatSObject - the record for that object is read and used in merge field processing.
    * @param String whoIdApiField - represents the api field to retrieve the whoId from the 'what' SObject  
    * @param Set<String> toAddressApiFields - an optional collection of To Address API fields on the 'what' SObject    
    * @return the Email Message object <Messaging.SingleEmailMessage>
    **/     
    public static Messaging.SingleEmailMessage getSingleEmailMessage(EmailTemplate emailTemplate, Id orgWideEmailAddressId, SObject whatSObject, String whoIdApiField, Set<String> toAddressApiFields) {
        String whoId = getValue(whatSObject, whoIdApiField);
        Messaging.SingleEmailMessage emailMessage = Messaging.renderStoredEmailTemplate(emailTemplate.Id, whoId, whatSObject.Id);
        emailMessage.setOrgWideEmailAddressId(orgWideEmailAddressId);
        if (emailMessage.getToAddresses()==null || emailMessage.getToAddresses().isEmpty()){
            Set<String> toAddresses = new Set<String>();
            for (String toAddressApiField : toAddressApiFields){
                String toAddress = getValue(whatSObject, toAddressApiField);
                if (String.isNotBlank(toAddress)){
                    toAddresses.add(toAddress);
                }
            }
            emailMessage.setToAddresses(new List<String>(toAddresses));
        }
        return emailMessage;
    }
    /**
    * @description Sends the list of emails instantiated with either SingleEmailMessage or MassEmailMessage 
    *   and returns a list of SendEmailResult objects.
    * @param Messaging.Email[] emails - a Collection of Email Messages
    * @param Boolean allOrNothing - The optional opt_allOrNone parameter specifies whether sendEmail prevents 
            delivery of all other messages when any of the messages fail due to an error (true), 
            or whether it allows delivery of the messages that don't have errors (false).
    * @return Messaging.SendEmailResult[] a Collection of SendEmailResult objects
    **/ 
    public static Messaging.SendEmailResult[] sendEmail(Messaging.Email[] emails, Boolean allOrNothing){
        return Messaging.sendEmail(emails, allOrNothing);
    }
    /**
    * @description Return the Email Template for the input template developer name
    **/	
    public static EmailTemplate getEmailTemplate(String templateDeveloperName){
        EmailTemplate retVal = null;
        for (EmailTemplate emailTemplate : [SELECT Id, Subject, Body
                                            FROM EmailTemplate 
                                            WHERE DeveloperName = :templateDeveloperName]){
            retVal = emailTemplate;                                  
        }
        return retVal;
    }    
    /**
    * @description Prepare and return the dynamic SOQL query to execute.
    **/		
    public static String getQuery(String sObjectType, String whoIdApiField, Set<String> toAddressApiFields) {
        List<String> apiFields = new List<String>();
        if (String.isNotBlank(whoIdApiField)){
            apiFields.add(whoIdApiField);
        }
        for (String toAddressApiField : toAddressApiFields){
            if (String.isNotBlank(toAddressApiField)){
                apiFields.add(toAddressApiField);
            }            
        }
        return  'SELECT Id '
                + (!apiFields.isEmpty() ? ',' + String.join(apiFields, ',') : '')
                + ' FROM ' + sObjectType
                + ' WHERE ' + 'Id' + ' IN ' + ':' + 'whatIds';
    }    
    private static String getValue(SObject whatSObject, String apiField){
        return (whatSObject.isSet(apiField) && whatSObject.get(apiField)!=null)
                ?   (String)whatSObject.get(apiField)
                :   null;         
    }
}