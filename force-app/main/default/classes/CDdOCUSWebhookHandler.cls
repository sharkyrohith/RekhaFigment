/*
*@Description: Class to handle to webhook response from OCUS API
@Author : Veera Maddukuri
@Date : 11/23/2021
*/
@RestResource(urlMapping='/api/OCUSWebhook')
global without sharing class CDdOCUSWebhookHandler {

    //Authentication details
    public static Map<String,CDdAPICredentialData.CredentialWrapper> credentialData = CDdAPICredentialData.getCredentialWrapper(CDdAPICredentialData.OCUS_CATEGORY_WEBHOOK);
    public static final String secretKeyValue = credentialData.values()[0].accessToken;
    public static final String algorithmName = 'HmacSHA256';
    
    /*
    * @Description          : Inbound Post request from OCUS
    * @Request              : Holds Signature which is Gerenrated from SecretKeyValue
    * @Request Body         : Event data when status updated on OCUS
    * @Sample Request Body  : {"type":"event","id":"mission.status.updated","attributes":{"mission_id":"e42eb8d0-337e-11ec-a25e-a2b76bde60c3",
                                "mission_reference_id"  :"e42eb8d0-337e-11ec-a25e-a2b76bde60c3","organization_id":"d3a64e90-9dfd-11eb-affe-8a094ca0282a","public_status":"ORDERED"}}
    * @Sample Request header: {CipherSuite=ECDHE-RSA-AES256-GCM-SHA384 TLSv1.2 443, Content-Type=application/json, Host=intnl-doordash.cs215.force.com, 
                                Signature=4a946880a033096cd2fab77b5b702036366b15c991cde44adbfe10fa91e5ad14, User-Agent=GuzzleHttp/7, X-B3-Sampled=0, X-B3-SpanId=7d85f49c8ecc3579, 
                                X-B3-TraceId=7d85f49c8ecc3579, X-Salesforce-Forwarded-To=cs215.salesforce.com, X-Salesforce-SIP=35.180.15.61, ...}
    */
    @HttpPost
    global static void handleNotification(){
        try{
            RestRequest request = RestContext.request;

            String receivedHmacData = request.headers.get('Signature');

            Blob saltValue = request.requestBody;
            Blob hmacData = Crypto.generateMac(algorithmName, saltValue, Blob.valueOf(secretKeyValue));
            String generatedHmacData = EncodingUtil.convertToHex(hmacData);

            if(generatedHmacData == receivedHmacData){
                String webhookBody = request.requestBody.toString();
                CDdRestJSONObj.OCUSWebhookResponse WebhookResponse = (CDdRestJSONObj.OCUSWebhookResponse) JSON.deserialize(webhookBody, CDdRestJSONObj.OCUSWebhookResponse.class);
                handleWebhookEvents(WebhookResponse);        
            }else{
                CDdErrorUtilities.publishException('Case', 'CDdOCUSWebhookHandler', '', 'Unauthorized Server');
            }
        }catch(Exception ex){
            CDdErrorUtilities.publishException('Case', 'CDdOCUSWebhookHandler', ex);
        }
    }
    
    /*
    * Description: Method to check events from OCUS
    * @param : WebhookResponse CDdRestJSONObj.OCUSWebhookResponse
    */
    private static void handleWebhookEvents(CDdRestJSONObj.OCUSWebhookResponse WebhookResponse){
        Boolean isValidEvent = WebhookResponse?.type == 'event' && String.isNotBlank(WebhookResponse?.Id);

        if(isValidEvent){
            String event = WebhookResponse.Id;
            //Blocker Event
            if(event.equalsIgnoreCase(CDdOCUSAPIConstants.OCUS_BLOCKER_EVENT)){
                WebhookResponse.attributes.public_status = CDdOCUSAPIConstants.BLOCKED_STATUS;
                CDdOCUSAPIHandler.updateCaseBlockedStatusFromOCUS(WebhookResponse);
            }
            //Status Update event
            else if(event.equalsIgnoreCase(CDdOCUSAPIConstants.OCUS_UPDATE_EVENT)){
                handleStatusEventResponse(WebhookResponse);
            }

            //The mission address couldn't be verified using geolocation and needs to be updated.
            else if(event.equalsIgnoreCase(CDdOCUSAPIConstants.OCUS_ADDRESS_EVENT)){
                WebhookResponse.attributes.public_status = CDdOCUSAPIConstants.ADDRESS_VERIFICATION_STATUS;
                CDdOCUSAPIHandler.updateCaseStatusFromOCUS(WebhookResponse);
            }
            /*BZAP-14938: New webhook config to capture media URL */
            else if(event.equalsIgnoreCase(CDdOCUSAPIConstants.OCUS_MISSION_ARCHIVED_EVENT)) {
                CDdOCUSAPIHandler.updateCaseMediaURLFromOCUS(WebhookResponse);
            }
        }
        
    }

    /*
    * Description: Case updates based on OCUS Status
    * @param : WebhookResponse CDdRestJSONObj.OCUSWebhookResponse
    */
    private static void handleStatusEventResponse(CDdRestJSONObj.OCUSWebhookResponse WebhookResponse){
        String publicStatus = WebhookResponse?.attributes?.public_status;
            switch on publicStatus {
                when 'ARCHIVED','CANCELED','DELIVERED','WAITING_MEDIA_UPLOAD','ASSIGNED','UNASSIGNED','ORDERED','IN_POST-PRODUCTION' {
                    CDdOCUSAPIHandler.updateCaseStatusFromOCUS(WebhookResponse);
                }
                when 'APPOINTMENT_CONFIRMED' {
                    CDdOCUSAPIHandler.updateCaseAppointmentDateFromOCUS(WebhookResponse);
                }
                when 'COMPLETED' {
                    CDdOCUSAPIHandler.updateCaseMediaURLFromOCUS(WebhookResponse);
                }
                when else {
                    CDdErrorUtilities.publishException('Case', 'CDdOCUSWebhookHandler', '', 'Unknown Status from OCUS');
                }
            }
    }
}