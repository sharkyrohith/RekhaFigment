/**
 * @author: Tia Xuan
 * @date: 05-2020
 * @description:  Recaptcha verify
 */ 

public class CDdRecaptchaContactSupportController {

    @AuraEnabled
    public static Boolean verifyRecaptcha(String recaptchaResponse, String domain){
        Recaptcha_Setting__mdt setting =[select Secret_Key__c,
                                                Verify_URL__c
                                        from Recaptcha_Setting__mdt
                                        where MasterLabel =: domain];
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(setting.Verify_URL__c);
        request.setMethod('POST');
        request.setBody('secret=' + setting.Secret_Key__c + '&response=' + recaptchaResponse);
        HttpResponse response = http.send(request);

        if (response.getStatusCode() == 200) {
            System.debug(response.getBody());
            Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

            if (result.containsKey('success') && result.get('success') == true) {
                return true;
            } else {
                return false;
            }
        }
        return false;
    }
}