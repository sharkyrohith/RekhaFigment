/**
* @author: Tia Xuan
* @date: 2021-03
* @description Chatbot VIP callout 
*/
public class CDdChatbotVIPCallout {

    public class DRSCalloutInput {
        @InvocableVariable(required=true)
        public String email;
        @InvocableVariable(required=true)
        public String VIPButtonId;
    }
    
    public class DRSCalloutOutput {
        @InvocableVariable(required=true)
        public Boolean isVIP;
        @InvocableVariable(required=true)
        public Integer chatWaitTime;
    }
    
    @InvocableMethod(label='Call DRS')
    public static List<DRSCalloutOutput> DRSCallout(List<DRSCalloutInput> inputs) {

        List<Service_Statistics__c> stats = [select     Id, 
                                                        Live_Agent_Estimated_Wait_Time__c 
                                                from    Service_Statistics__c 
                                                where   Live_Agent_Button_ID__c =: inputs[0].VIPButtonId];
        Integer chatWaitTime = 0;
        if (stats.size() > 0
            && stats[0].Live_Agent_Estimated_Wait_Time__c != null){
            chatWaitTime = Integer.valueOf(stats[0].Live_Agent_Estimated_Wait_Time__c);
        }
        List<DRSCalloutOutput> outs = new List<DRSCalloutOutput>();
        for (DRSCalloutInput input : inputs){
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            String callURL = 'callout:Doordash_Audience_API';
            callURL += '?customer_type=consumer';
            callURL += '&experience=doordash';
            callURL += '&email=' + input.email;

            request.setEndpoint(callURL);
            request.setHeader('Authorization', '{!$Credential.Password}');
            request.setHeader('content-type', 'application/json');
            request.setHeader('DD-API-TOKEN', CDdSupportConstants.DRS_DD_API_TOKEN);
            request.setMethod('GET');

            HttpResponse response = http.send(request);
            DRSCalloutOutput out =  new DRSCalloutOutput();
            out.isVIP = false;
            out.chatWaitTime = chatWaitTime;
            if (response.getStatusCode() < 300){
                Map<String, Object> jsonResult = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                Map<String, Object> audience = (Map<String, Object>)jsonResult.get('audience');
                Map<String, Object> consumerAudience = (Map<String, Object>)audience.get('consumer_audience');

                Integer vipValue = (Integer) consumerAudience.get('cx_unavail_last_3_orders_flag');
                if (vipValue != null 
                    && CDdSupportConstants.CHATBOT_VIP_VALUES.contains(vipValue)){
                        out.isVIP = true;
                }
            }
            outs.add(out);
        }
        return outs;
    }
}