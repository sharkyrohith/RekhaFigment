public with sharing class VDispatchAPI {
	private Dispatch_Settings__c apiSettings = Dispatch_Settings__c.getInstance();

	public VDispatchAPI() {}

	public DispatchAPIResponse getDeliveryInfo(Decimal deliveryId, String deliveryUUID) {
        HttpRequest req = null; 
        // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
        Boolean useUUID = (apiSettings.Use_UUID__c != null 
                            && apiSettings.Use_UUID__c == true) 
                            ? true : false; 
        if (String.isNotBlank(deliveryUUID) && useUUID){
            req = makeRequest(  'GET', 
                                (!String.isBlank(apiSettings.Dispatch_Token_Prefix__c) 
                                    ? apiSettings.Dispatch_Token_Prefix__c : 'Token ') 
                                    + ' ' + apiSettings.Dispatch_Token__c, 
                                apiSettings.Dispatch_UUID_Endpoint_Prefix__c, 
                                deliveryUUID + apiSettings.Dispatch_UUID_Endpoint_Suffix__c);
        } else {
            req = makeRequest(  'GET', 
                                (!String.isBlank(apiSettings.Dispatch_Token_Prefix__c) 
                                    ? apiSettings.Dispatch_Token_Prefix__c : 'Token ') 
                                    + ' ' + apiSettings.Dispatch_Token__c, 
                                    apiSettings.Dispatch_ID_Endpoint_Prefix__c, 
                                deliveryId + apiSettings.Dispatch_ID_Endpoint_Suffix__c);
        } 
		HttpResponse resp = sendRequest(req);

		DispatchAPIResponse res = new DispatchAPIResponse();
        res.body = resp.getBody();
        System.debug('ret:' + resp.getBody());

		res.statusCode = resp.getStatusCode();

		return res;
	}

	public DispatchAPIResponse postCase(String postData) {
		return invokeCaseAPI('POST', postData, '/');
	}

	public DispatchAPIResponse updateCase(String postData, String caseNumber) {
		return invokeCaseAPI('PUT', postData, '/' + caseNumber + '/');
	}

	private DispatchAPIResponse invokeCaseAPI(String method, String postData, String postfix) {
        HttpRequest req = makeRequest(  method, 
                                        (!String.isBlank(apiSettings.Dispatch_Token_Prefix__c) 
                                            ? apiSettings.Dispatch_Token_Prefix__c : 'Token ') 
                                            + ' ' + apiSettings.Dispatch_Token__c, 
                                            apiSettings.Dispatch_Case_Update_Endpoint__c, 
                                        postfix);
		req.setBody(postData);
		req.setHeader('Content-Type', 'application/json');

		HttpResponse resp = sendRequest(req);

		DispatchAPIResponse res = new DispatchAPIResponse();
		res.body = resp.getBody();
		res.statusCode = resp.getStatusCode();
		return res;
	}

	private HttpResponse sendRequest(HttpRequest req) {
		Http h = new Http();
		return h.send(req);
	}

	private HttpRequest makeRequest(String method, String auth, String endpointPrefix, String endpointSuffix) {
		HttpRequest req = new HttpRequest();
		req.setMethod(method);
        req.setHeader('Authorization', auth);
        System.debug('auth:' + auth);

        req.setEndpoint(endpointPrefix + (String.isNotBlank(endpointSuffix) ? endpointSuffix : ''));
        System.debug('endpoint:' + req.getEndpoint());

		return req;
	}

	public class DispatchAPIResponse {
		public String body;
		public Integer statusCode;
	}
}