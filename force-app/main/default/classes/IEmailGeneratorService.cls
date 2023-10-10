/**
     * @author Sugan
     * @date  Feb 2023
     * @decription service to generate email based on input
    */
public interface IEmailGeneratorService {
    Messaging.SingleEmailMessage getEmailToSend(String templateIdVal, String whatId, String[] toAddresses,Map<String,String> mergeValuesForTemplate,Boolean isSupport);
    void sendWFEmailAlert(String recordId, String sObjectType, String emailAlertName);
}