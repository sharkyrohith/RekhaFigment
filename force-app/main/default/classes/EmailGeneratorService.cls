public inherited sharing class EmailGeneratorService {
    public static Messaging.SingleEmailMessage getEmailToSend(String templateIdVal, String whatId, String[] toAddresses,Map<String,String> mergeValuesForTemplate, Boolean isSupport){
        return service().getEmailToSend(templateIdVal, whatId,toAddresses, mergeValuesForTemplate, isSupport);
    }
    public static void sendWFEmailAlert(String recordId, String sObjectType, String emailAlertName){
        service().sendWFEmailAlert(recordId, sObjectType, emailAlertName);
    }
    private static IEmailGeneratorService service() {
        return (IEmailGeneratorService) Application.Service.newInstance(IEmailGeneratorService.class);
    }
}