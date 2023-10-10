/**
 * 
 * @author: Tia Xuan
 * @date: 2019-09
 * @description class for CDdLiveAgentHelper
 * 				helper class for Live Agent wait time
 *
 */
public without sharing class CDdLiveAgentHelper {

    /**
    * @description get Live agent wait time
    **/
    public static Service_Statistics__c getLiveAgentWaitTime(Service_Statistics__c statSetting){

        try {
            String url ='';
            String orgId = statSetting.Live_Agent_Org_ID__c.substring(0,15);
            String depId = statSetting.Live_Agent_Deployment_ID__c;
            String buttonId = statSetting.Live_Agent_Button_ID__c;
            
            // Create a chat session
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(Label.Live_Agent_REST_URL + 'System/SessionId');
            req.setMethod('GET');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('X-LIVEAGENT-API-VERSION', '47');
            req.setHeader('X-LIVEAGENT-AFFINITY', 'null');
            HttpResponse resp = http.send(req);
            
            System.debug('response Session:' + resp.getBody());
            ChatResponse sessionResp =  new ChatResponse();
            if (resp.getStatusCode() == 200) {
                sessionResp =  (ChatResponse) JSON.deserialize(resp.getBody(), ChatResponse.class);
            }

            statSetting.Live_Agent_Session_ID__c = sessionResp.id;

            // get visitor settings
            req = new HttpRequest();
            url = Label.Live_Agent_REST_URL + 'Visitor/Settings';
            url += '?org_id=' + orgId;
            url += '&deployment_id=' + depId;
            url += '&Settings.buttonIds=[\'' + buttonId + '\']';
            url += '&Settings.needEstimatedWaitTime=1';
            req.setEndpoint(url);
            req.setMethod('GET');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('X-LIVEAGENT-API-VERSION', '47');
            resp = http.send(req);
            
            // get visitor availability
            req = new HttpRequest();
            url = Label.Live_Agent_REST_URL + 'Visitor/Availability';
            url += '?org_id=' + orgId;
            url += '&deployment_id=' + depId;
            url += '&Availability.ids=[\'' + buttonId + '\']';
            url += '&Availability.needEstimatedWaitTime=1';
            req.setEndpoint(url);
            req.setMethod('GET');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('X-LIVEAGENT-API-VERSION', '47');
            resp = http.send(req);

            // initialize chat session
            req = new HttpRequest();
            req.setEndpoint(Label.Live_Agent_REST_URL + 'Chasitor/ChasitorInit');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('X-LIVEAGENT-API-VERSION', '47');
            req.setHeader('X-LIVEAGENT-AFFINITY', sessionResp.affinityToken);
            req.setHeader('X-LIVEAGENT-SESSION-KEY', sessionResp.key);

            String body = '{';
            body += '"organizationId": "' + orgId + '",';
            body += '"deploymentId": "' + depId + '",';
            body += '"buttonId": "' + buttonId + '",';
            body += '"sessionId": "' + sessionResp.id + '",'; 
            body += '"userAgent": "",';
            body += '"language": "en-US",';
            body += '"screenResolution": "1900x1080",';
            body += '"visitorName": "Test Tia",';
            body += '"prechatDetails": [],';
            body += '"prechatEntities": [],';
            body += '"receiveQueueUpdates": true,';
            body += '"isPost": true';
            body += '}';
            req.setBody(body);
            resp = http.send(req);

            // Get chat message to get the estimated wait time
            req = new HttpRequest();
            req.setEndpoint(Label.Live_Agent_REST_URL + 'System/Messages');
            req.setMethod('GET');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('X-LIVEAGENT-API-VERSION', '47');
            req.setHeader('X-LIVEAGENT-AFFINITY', sessionResp.affinityToken);
            req.setHeader('X-LIVEAGENT-SESSION-KEY', sessionResp.key);
            Boolean chatWaitTimeLongTimeout = CDdExperimentSvc.getFeatureFlag('Chat_Wait_Time_Long_Timeout__c');
            if (chatWaitTimeLongTimeout){
                req.setTimeout(120000);
            }
            resp = http.send(req);
            
            System.debug('response messages:' + resp.getBody());
            ChatResponse msgResp = null;
            if (resp.getStatusCode() == 200) {
                msgResp =  (ChatResponse) JSON.deserialize(resp.getBody(), ChatResponse.class);
                statSetting.Live_Agent_Estimated_Wait_Time__c = msgResp.messages[0].message.estimatedWaitTime;
                System.debug('estimatedWaitTime:' + msgResp.messages[0].message.estimatedWaitTime);
            }

            // end chat
            req = new HttpRequest();
            req.setEndpoint(Label.Live_Agent_REST_URL + 'Chasitor/ChatEnd');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('X-LIVEAGENT-API-VERSION', '47');
            req.setHeader('X-LIVEAGENT-AFFINITY', sessionResp.affinityToken);
            req.setHeader('X-LIVEAGENT-SESSION-KEY', sessionResp.key);
            req.setBody('{reason: "client"}');
            resp = http.send(req);

            return statSetting;
        } catch (Exception e){
            CDdErrorUtilities.createApexLogs(new List<String>{e.getMessage()}, 'CDdLiveAgentHelper');
            throw e;
        }
    }

    // response to chat
    public class ChatResponse{
        public String key {get;set;}
        public String id {get;set;}
        public Integer clientPollTimeout {get;set;}
        public String affinityToken {get;set;}
        public List<ChatResponseMessage> messages {get; set;}
    }

    // response to chat message
    public class ChatResponseMessage{
        public ChatResponseMessageInfo message {get;set;}
        public String type {get;set;}
    }

     // response to chat message info
    public class ChatResponseMessageInfo{
        public Integer connectionTimeout {get;set;}
        public Integer estimatedWaitTime {get;set;}
    }
}