/**
 * @description       : 
 * @author            : Dinesh Annapareddy
 * @group             : 
 * @last modified on  : 11-16-2021
 * @last modified by  : Dinesh Annapareddy
**/
@RestResource(urlMapping='/CassieSubscriptions/*')
global with sharing class CDdGDPRSubscriptionsAPI {    
    @HttpPost
    global static void doPost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        if(req.requestBody != null ) {
            if(req.requestBody.toString() != null) {
                String requestBody = req.requestBody.toString();
                CDdGDPREmailObj.CDdGDPRSubscriptions receivedPayload =(CDdGDPREmailObj.CDdGDPRSubscriptions) 
                                        JSON.deserialize(requestBody,CDdGDPREmailObj.CDdGDPRSubscriptions.class);
                CDdGDPRSubscriptionsHelper.manageSubscriptions(new List<CDdGDPREmailObj.CDdGDPRSubscriptions>{receivedPayload});
            }
        }
    }
}