/**
 * CDdRESTConnectorSvc
 *
 * @author     jnguyen
 * @date  2018-03-19
 * @decription  This class should hold all services needed to connect SFDC to any REST endpoints
 */
public class CDdRESTConnectorSvc {
    /*****************************************************************************************************************************
     *
     * Constants & Private Variables
     *
    *****************************************************************************************************************************/
    private vCS__c apiSettings;
    private Dispatch_Settings__c dispatchSettings;
    private String endpointPrefix;
    private String authToken;
    private static List<Integration_Settings__c> integrationSettings = Integration_Settings__c.getAll().values();
    private static Map<String,Integer> endpointToTimeoutMap = new Map<String,Integer>();
    /*****************************************************************************************************************************
    *
    * Public Methods
    *
    *****************************************************************************************************************************/
    public CDdRESTConnectorSvc() {
        apiSettings = vCS__c.getInstance();
        // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
        dispatchSettings = Dispatch_Settings__c.getInstance();
        //check if custom setting says to use sandbox
        if (apiSettings.UseDSJSandbox__c) {
            useSandbox();
        } else {
            useProd();
        }
        //printSettings();
        if (endpointToTimeoutMap.isEmpty()) {
              //populate map with data from custom settings
              for (Integration_Settings__c intSetVar : integrationSettings) {
                if (String.isNotBlank(intSetVar.Endpoint__c) && intSetVar.Timeout__c != null) {
                    endpointToTimeoutMap.put(intSetVar.Endpoint__c, (Integer)intSetVar.Timeout__c);
                }
            }
        }
    }
    
    public void printSettings() {
        System.debug(LoggingLevel.ERROR, 'endpointPrefix = ' + endpointPrefix);
        System.debug(LoggingLevel.ERROR, 'authToken = ' + authToken);
    }
    
    public void useProd() {
        /* 
         * This allows us to dynamically define prod to use in  our code production/future development
         * Call this function to override default in custom settings
         */
        endpointPrefix = apiSettings.DoorstepEndpointPrefix__c;
        authToken = apiSettings.DispatchTokenPrefix__c + ' ' + apiSettings.DispatchToken__c;
    }
    
    public void useSandbox() {
        /* 
         * This allows us to use a sandbox to test in production/future development
         * Call this function to override default in custom settings
         */
        endpointPrefix = apiSettings.DoorstepSandboxEndpointPrefix__c;
        authToken = apiSettings.DoorstepSandboxAuthTokenPrefix__c + ' ' + apiSettings.DoorstepSandboxAuthToken__c;
    }
    
    public CDdRestJSONObj.RestAPIResponse getDeliveryInfo(Decimal deliveryId) {
        List<String> logString = new List<String>(); 
        logString.add('getDeliveryInfo(decimal) invoked');
        CDdErrorUtilities.createApexLogs(logString, 'CDdRESTConnectorSvc', 'getDeliveryInfo', LoggingLevel.Debug);
        return getDeliveryInfo(deliveryId, null);
        
    }
    
    public CDdRestJSONObj.RestAPIResponse getDeliveryInfo(Decimal deliveryId, String deliveryUUID) {
        HttpRequest req = null; 
        // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
        List<String> logString = new List<String>(); 
        logString.add('getDeliveryInfo(decimal,String) invoked');
        Boolean useUUID = (dispatchSettings.Use_UUID__c != null 
                            && dispatchSettings.Use_UUID__c == true) 
                            ? true : false; 
        CDdErrorUtilities.createApexLogs(logString, 'CDdRESTConnectorSvc', 'getDeliveryInfo', LoggingLevel.Debug);
        System.debug('><> I am inside getDeliveryInfo(), this is being used'); 
        System.debug('><> I am inside getDeliveryInfo(), this is being used'); 
        if (String.isNotBlank(deliveryUUID) && useUUID){
            req = makeRequest(  'GET', 
                                (!String.isBlank(dispatchSettings.Dispatch_Token_Prefix__c) 
                                    ? dispatchSettings.Dispatch_Token_Prefix__c : 'Token ') 
                                    + ' ' + dispatchSettings.Dispatch_Token__c, 
                                dispatchSettings.Dispatch_UUID_Endpoint_Prefix__c, 
                                deliveryUUID + dispatchSettings.Dispatch_UUID_Endpoint_Suffix__c);
        } else {
            req = makeRequest(  'GET', 
                                (!String.isBlank(dispatchSettings.Dispatch_Token_Prefix__c) 
                                    ? dispatchSettings.Dispatch_Token_Prefix__c : 'Token ') 
                                    + ' ' + dispatchSettings.Dispatch_Token__c, 
                                    dispatchSettings.Dispatch_ID_Endpoint_Prefix__c, 
                                deliveryId + dispatchSettings.Dispatch_ID_Endpoint_Suffix__c);
        } 
        
        //HttpRequest req = makeRequest('GET', authToken, apiSettings.DispatchEndpointPrefix__c , deliveryId + apiSettings.DispatchEndpointSuffix__c + '/');
        HttpResponse resp = sendRequest(req);

        CDdRestJSONObj.RestAPIResponse res = new CDdRestJSONObj.RestAPIResponse();
        res.body = resp.getBody();

        res.statusCode = resp.getStatusCode();

        return res;
    }

     // Tia Xuan 07/2021 BIZS-43 Repoint API for Dispatch callout
     public CDdRestJSONObj.RestAPIResponse getDeliveryInfo(List<String> deliveryUUIDList) {
        String body = CDdSupportConstants.DELIVERY_MAIN_BODY.replace(CDdSupportConstants.DELIVERY_UUIDS_REPLACEMENT_STRING, JSON.serialize(deliveryUUIDList));
        CDdRESTConnectorSvc connector = new CDdRESTConnectorSvc();

        return connector.invokeRESTAPI( CDdSupportConstants.POST_METHOD, 
                                        body, 
                                        null, 
                                        dispatchSettings.Dispatch_ERS_Endpoint__c, 
                                        null, 
                                        CDdSupportConstants.CONTENT_TYPE_JSON, 
                                        CDdSupportConstants.DD_API_TOKEN, 
                                        dispatchSettings.Dispatch_ERS_Token__c, 
                                        null);
    }
    public CDdRestJSONObj.RestAPIResponse getDeliveryInfo(CDdRestJSONObj.dispatchRequest customerAudience) {
        String body = JSON.serialize(customerAudience, true);
        CDdRESTConnectorSvc connector = new CDdRESTConnectorSvc();
        return connector.invokeRESTAPI( CDdSupportConstants.POST_METHOD, 
                                        body, 
                                        null, 
                                        dispatchSettings.Dispatch_ERS_Endpoint__c, 
                                        null, 
                                        CDdSupportConstants.CONTENT_TYPE_JSON, 
                                        CDdSupportConstants.DD_API_TOKEN, 
                                        dispatchSettings.Dispatch_ERS_Token__c, 
                                        null);
    }
    public CDdRestJSONObj.RestAPIResponse getDoorstep(String endpoint) {
        return getDoorstep(endpoint, '/', true);
    }

    public CDdRestJSONObj.RestAPIResponse getDoorstep(String endpoint, String postfix) {
        return getDoorstep(endpoint, postfix, true);
    }
    
    public CDdRestJSONObj.RestAPIResponse getDoorstep(String endpoint, String postfix, Boolean requiresAuth) {
        return invokeDoorstepAPI('GET', null, requiresAuth ? authToken : null, endpoint, postfix);
    }

    public CDdRestJSONObj.RestAPIResponse postDoorstep(String postData, String endpoint) {
        return invokeDoorstepAPI('POST', postData, authToken, endpoint, '/');
    }

    public CDdRestJSONObj.RestAPIResponse updateDoorstep(String postData, String endpoint) {
        return invokeDoorstepAPI('PUT', postData, authToken, endpoint, '/');
    }    

    public CDdRestJSONObj.RestAPIResponse updateDoorstep(String postData, String endpoint, String recordId) {
        return invokeDoorstepAPI('PUT', postData, authToken, endpoint, '/' + recordId + '/');
    }
    
    // public CDdRestJSONObj.RestAPIResponse patchDoorstep(String postData, String endpoint, String recordId) {
    //     List<String> logString = new List<String>(); 
    //     logString.add('patchDoorstep invoked');
    //     CDdErrorUtilities.createApexLogs(logString, 'CDdRESTConnectorSvc', 'getDeliveryInfo', LoggingLevel.Debug);
    //     return invokeDoorstepAPI('PATCH', postData, authToken, endpoint, '/' + recordId + '/');
    // }
    
    public CDdRestJSONObj.RestAPIResponse invokeDoorstepAPI(String method, String postData, String auth, String endpoint, String postfix) {
        return invokeRESTAPI(method, postData, auth, endpointPrefix + endpoint, postfix);
    }
    
    // public CDdRestJSONObj.RestAPIResponse getRESTAPI(String auth, String endpoint) {
    //     List<String> logString = new List<String>(); 
    //     logString.add('getRESTAPI(String,String) invoked');
    //     CDdErrorUtilities.createApexLogs(logString, 'CDdRESTConnectorSvc', 'getDeliveryInfo', LoggingLevel.Debug);
    //     return getRESTAPI(auth, endpoint, '/');
    // }
    
    // public CDdRestJSONObj.RestAPIResponse getRESTAPI(String auth, String endpoint, String postfix) {
    //     List<String> logString = new List<String>(); 
    //     logString.add('getRESTAPI(String,String,String) invoked');
    //     CDdErrorUtilities.createApexLogs(logString, 'CDdRESTConnectorSvc', 'getDeliveryInfo', LoggingLevel.Debug);
    //     return invokeRESTAPI('GET', null, auth, endpoint, postfix);
    // }

    public CDdRestJSONObj.RestAPIResponse postRESTAPI(String postData, String auth, String endpoint) {
        return invokeRESTAPI('POST', postData, auth, endpoint, '/');
    }
    
    // public CDdRestJSONObj.RestAPIResponse putRESTAPI(String postData, String auth, String endpoint, String recordId) {
    //     List<String> logString = new List<String>(); 
    //     logString.add('putRESTAPI invoked');
    //     CDdErrorUtilities.createApexLogs(logString, 'CDdRESTConnectorSvc', 'getDeliveryInfo', LoggingLevel.Debug);
    //     return invokeRESTAPI('PUT', postData, auth, endpoint, '/' + recordId + '/');
    // }
    
    public CDdRestJSONObj.RestAPIResponse patchRESTAPI(String postData, String auth, String endpoint, String recordId) {
        return invokeRESTAPI('PATCH', postData, auth, endpoint, '/' + recordId + '/');
    }
    
    public CDdRestJSONObj.RestAPIResponse invokeRESTAPI(String method, String postData, String auth, String endpoint, String postfix) {
        return invokeRESTAPI(method, postData, auth, endpoint, postfix, 'application/json');
    }
    
    public CDdRestJSONObj.RestAPIResponse invokeRESTAPI(String method, String postData, String auth, String endpoint, String postfix, String contentType) {
        return invokeRESTAPI(method, postData, auth, endpoint, postfix, contentType, null);
    }
    
    public CDdRestJSONObj.RestAPIResponse invokeRESTAPI(String method, String postData, String auth, String endpoint, 
            String postfix, String contentType, String namedCredential) {
        return invokeRESTAPI(method, postData, auth, endpoint, postfix, contentType, null, namedCredential);
    }
    
    public CDdRestJSONObj.RestAPIResponse invokeRESTAPI(String method, String postData, String auth, String endpoint, 
            String postfix, String contentType, String queryParams, String namedCredential) {

        HttpRequest req =  String.isBlank(queryParams) ? makeRequest(method, auth, endpoint, postfix, namedCredential)
                            : makeRequest(method, auth, endpoint, postfix, queryParams, namedCredential);
        if (postData != null) {
            req.setBody(postData);
            req.setHeader('Content-Type', ((!String.isBlank(contentType) || contentType != null) ? contentType : 'application/json'));    
        }

        HttpResponse resp = sendRequest(req);

        CDdRestJSONObj.RestAPIResponse res = new CDdRestJSONObj.RestAPIResponse();
        res.body = resp.getBody();
        res.statusCode = resp.getStatusCode();
        res.status = resp.getStatus();
        return res;
    }
    
    /**
   * @author     Sahil
   * @date  2020-03-30
   * @decription invoke REST API
   * @param   method,payload,endpoint,endpointsuffix,content type,header key,header value,named credential
   * @return  instance of CDdRestJSONObj.RestAPIResponse. it will have response and status code
   */
    public CDdRestJSONObj.RestAPIResponse invokeRESTAPI(String method, String postData, String auth, String endpoint, 
            String postfix, String contentType, String headerKey, String headerValue, String namedCredential) {
        CDdRestJSONObj.RestAPIResponse res = new CDdRestJSONObj.RestAPIResponse();
        try {
            HttpRequest req = makeRequest(method, auth, endpoint, postfix, namedCredential);
            if (postData != null) {
                req.setBody(postData);
                req.setHeader('Content-Type', ((!String.isBlank(contentType) || contentType != null) ? contentType : 'application/json'));
                if (String.isNotBlank(headerKey) && String.isNotBlank(headerValue)) {
                    req.setHeader(headerKey, headerValue);
                }
            }
            HttpResponse resp = sendRequest(req);
            res.body = resp.getBody();
            res.statusCode = resp.getStatusCode();
            res.status = resp.getStatus();
            return res;
        } catch (Exception e) {
            throw new CDdRESTConnectorSvcException(e.getMessage());
        }
    }

    private HttpResponse sendRequest(HttpRequest req) {
        Http h = new Http();
        return h.send(req);
    }

    private HttpRequest makeRequest(String method, String auth, String endpointPrefix, String endpointSuffix ) {
        return makeRequest(method, auth, endpointPrefix, endpointSuffix, null);
        
    }
    
    private HttpRequest makeRequest(String method, String auth, String endpointPrefix, String endpointSuffix, String namedCredential) {
        return makeRequest(method, auth, endpointPrefix, endpointSuffix, null, namedCredential);
    }

    private HttpRequest makeRequest(String method, String auth, String endpointPrefix, String endpointSuffix, String queryParams, String namedCredential) {
        HttpRequest req = new HttpRequest();
        req.setMethod(method);
        queryParams = String.isNotBlank(queryParams) ? CDdCoreConstants.DELIMITER_QUESTION_MARK + queryParams : CDdCoreConstants.BLANK_STRING;

        if(namedCredential != null) {
            req.setEndpoint('callout:'+ namedCredential + endpointSuffix + queryParams);
            //BZAP-13546 False positive for Hardcoded Authentication Credentail
            req.setHeader('Authorization','{!$Credential.Password}');
        } else if (auth != null) {
            //BZAP-13546 False positive for HardCoded Authentication Credentail
            req.setHeader('Authorization', auth);
        }
        // set the endpoint url if NamedCredential is Null. 
        // this is done to set the endpoint regardless if an authorization required or not.
        if(namedCredential == null) {
            req.setEndpoint(endpointPrefix + (String.isNotBlank(endpointSuffix) ? endpointSuffix + queryParams : CDdCoreConstants.BLANK_STRING));
        }
        //set timeout based on endpoint (configured in custom settings)
        if (!endpointToTimeoutMap.isEmpty() && String.isNotBlank(endpointSuffix) 
            && endpointToTimeoutMap.containsKey(endpointSuffix)) {
            Integer timeout = endpointToTimeoutMap.get(endpointSuffix);
            req.setTimeout(timeout);
        } else {
            req.setTimeout(20000); //timeout in ms
        }
        System.debug('||||');
        System.debug(req);
        return req;
    }
    
    /**** Processing REST Calls ****/
    
    /*
    public SObject sendAndRetrieveRESTCall(CDdRestJSONObj.RequestParams params, SObject response) {
        return null;
    }
    */
    public class CDdRESTConnectorSvcException extends Exception{}
}