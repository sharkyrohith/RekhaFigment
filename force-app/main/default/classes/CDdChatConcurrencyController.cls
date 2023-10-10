/**
 * 
 * @author: Tia Xuan
 * @date: 2020-04
 * @description class for CDdChatConcurrencyController - BZAP-7383 controller for chat concurrency
 * 
 */
public class CDdChatConcurrencyController {

     /**
     * @description Initialize chat concurrency 
     */
    @AuraEnabled
    public static List<QueueRoutingConfig> initChatConcurrency(){
        List<String> routingConfigLabels = new List<String>();
        for(Chat_Concurrency_Setting__c chatConcurrencySetting : Chat_Concurrency_Setting__c.getAll().values()) {
            routingConfigLabels.add(chatConcurrencySetting.Routing_Config_Label__c);
        }
        List<QueueRoutingConfig> config = [ SELECT  Id,
                                                    MasterLabel,
                                                    CapacityWeight
                                            FROM QueueRoutingConfig
                                            WHERE MasterLabel IN :routingConfigLabels
                                          ];
        return config;
    }

    /**
     * @description Save chat concurrency 
     */
    @AuraEnabled
    public static void updateChatConcurrency(List<QueueRoutingConfig> changedRows){
        //Make sure your Salesforce instance URL is added in remote site settings
        String sfdcURL = URL.getSalesforceBaseUrl().toExternalForm(); 
        String restURLTemplate = 'callout:SalesforceNamedCred/services/data/v48.0/sobjects/QueueRoutingConfig/{1}?_HttpMethod=PATCH';

        Http http = new Http();   
        HttpRequest req = new HttpRequest();  
        req.setMethod('POST');   
        req.setHeader('Content-Type', 'application/json');   

        for (QueueRoutingConfig qrc : changedRows){
            String[] urlParams = new String[]{sfdcURL, qrc.Id};
            String restAPIURL = String.format(restURLTemplate, urlParams);
            req.setEndpoint(restAPIURL); 
            String body = '{ \"CapacityWeight\" : ' + qrc.CapacityWeight + ' }';
            req.setBody(body); 
            HttpResponse resp = http.send(req);  
            if (resp.getStatusCode() != 204 ) {  
                throw new CalloutException( resp.getBody() );  
            }   
        }
    }
}