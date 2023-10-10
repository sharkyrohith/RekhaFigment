/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 08/03/2020
*
* @group Nimda
*
* @description This class is responsible to make API requests to MuleSoft which in turn will
* interact with external interfaces namely DSJ, Nimda and Stripe
*
**************************************************************************************************************************************/
public class CDdNimdaSyncMSService {
    public static final Map<String, String> HEADERS;
    public static final Map<String, String> URL_PATHS;
    public static final String URL_PREFIX;
    public static final Boolean IS_SANDBOX;
    public Enum TYPE {Named_Credential, Header, URL_Path}
    public static final String HEADER_NAME_DD_USER = 'dduser';
    static {
        HEADERS = new Map<String, String>();
        URL_PATHS = new Map<String, String>();
        for (Organization o : [SELECT Id, IsSandbox FROM Organization WHERE Id = :UserInfo.getOrganizationId()]){
            IS_SANDBOX = o.IsSandbox;
        }
        for (Nimda_MuleSoft_API__mdt api : [SELECT Id, Label, DeveloperName, Is_Sandbox__c,
                                                Name__c, Type__c, Value__c, Active__c
                                                FROM Nimda_MuleSoft_API__mdt
                                                Where Active__c = true
                                                AND Is_Sandbox__c = :IS_SANDBOX
                                                ORDER BY Type__c ASC]){
            switch on getType(api.Type__c) {
                when Named_Credential {
                    URL_PREFIX = 'callout:' + api.Value__c;
                }
                when Header {
                    if (CDdNimdaSyncConstants.ENABLE_S2N_DD_USER && HEADER_NAME_DD_USER.equals(api.Name__c)){
                        HEADERS.put(api.Name__c, UserInfo.getUserEmail());
                    } else {
                        HEADERS.put(api.Name__c, api.Value__c);
                    }
                }
                when URL_Path {
                    URL_PATHS.put(api.Name__c, api.Value__c);
                }
            }
        }
    }
    public static String getDDUser(){
        return HEADERS.get(HEADER_NAME_DD_USER);
    }
    /**
    * @description Return the Enum Type for the input type String value
    **/
    private static TYPE getType(String typeName){
        for (TYPE typeEnum : TYPE.values()){
            if (typeName.equals(typeEnum.name())){
                return typeEnum;
            }
        }
        return null;
    }
    /**
    * @description Set the HttpRequest headers
    **/
    private static void setRequestHeaders(HttpRequest req){
        for (String name : HEADERS.keySet()){
            req.setHeader(name, HEADERS.get(name));
        }
    }
    /**
    * @description Set the HttpRequest endpoint
    **/
    private static void setEndPoint(HttpRequest req, String name, List<String> params){
        req.setEndpoint(URL_PREFIX + String.format(URL_PATHS.get(name), params));
    }
    /**
    * @description An operation that interacts with MuleSoft to GET a store
    * @param String input Store Id
    * @return Return the Store detail information
    **/
    public String getStore(String storeId) {
        if (String.isBlank(storeId)){
            throw new CDdNimdaSyncMSServiceException(
                                        CDdNimdaSyncConstants.STEP_GET_STORE
                                        , CDdNimdaSyncConstants.ERROR_TYPE_VALIDATION
                                        , CDdNimdaSyncConstants.ERROR_MSG_INVALID_STORE_ID
                                    );
        }
        HttpRequest req = new HttpRequest();
        setRequestHeaders(req);
        setEndpoint(req, CDdNimdaSyncConstants.STEP_GET_STORE, new List<String>{storeid});
        req.setMethod('GET');
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        if (res.getStatusCode() != 200){
            throw new CDdNimdaSyncMSServiceException(
            								CDdNimdaSyncConstants.STEP_GET_STORE
            								, CDdNimdaSyncConstants.ERROR_TYPE_RESPONSE
            								, 'Response status code - ' + res.getStatusCode() + ';' + res.getBody()
            								, req.getEndpoint()
            								, res.getBody()
            							);
        }
        return res.getBody();
    }

     /**
    * @description An operation that interacts with MuleSoft to GET a Business details
    * @param String input Business Id
    * @return Return the Business detail information
    **/
    public String getBusiness(String businessId) {
        if (String.isBlank(businessId)){
            throw new CDdNimdaSyncMSServiceException(CDdNimdaSyncConstants.STEP_GET_BUSINESS,CDdNimdaSyncConstants.ERROR_TYPE_VALIDATION,CDdNimdaSyncConstants.ERROR_MSG_INVALID_BUSINESS_ID);
        }
        HttpRequest req = new HttpRequest();
        setRequestHeaders(req);
        setEndpoint(req, CDdNimdaSyncConstants.STEP_GET_BUSINESS, new List<String>{businessId});
        req.setMethod('GET');
        Http http = new Http();
        HTTPResponse res = http.send(req);
        if (res.getStatusCode() != 200){
            throw new CDdNimdaSyncMSServiceException(CDdNimdaSyncConstants.STEP_GET_BUSINESS, CDdNimdaSyncConstants.ERROR_TYPE_RESPONSE, 'Response status code - ' + res.getStatusCode() + ';' + res.getBody()
            								, req.getEndpoint(), res.getBody());
        }
        return res.getBody();
    }

    /**
    * @description An operation that interacts with MuleSoft to GET a store menu links
    * @param String input Store Id
    * @return Return the Store menu information if its active
    **/
    public String getStoreMenuLinks(String storeId) {
        if (String.isBlank(storeId)){
            throw new CDdNimdaSyncMSServiceException(
                                        CDdNimdaSyncConstants.STEP_GET_STORE_MENU
                                        , CDdNimdaSyncConstants.ERROR_TYPE_VALIDATION
                                        , CDdNimdaSyncConstants.ERROR_MSG_INVALID_STORE_ID
                                    );
        }
        HttpRequest req = new HttpRequest();
        setRequestHeaders(req);
        setEndpoint(req, CDdNimdaSyncConstants.STEP_GET_STORE_MENU, new List<String>{storeid});
        req.setMethod('GET');
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        if (res.getStatusCode() != 200){
            throw new CDdNimdaSyncMSServiceException(
            								CDdNimdaSyncConstants.STEP_GET_STORE_MENU
            								, CDdNimdaSyncConstants.ERROR_TYPE_RESPONSE
            								, 'Response status code - ' + res.getStatusCode() + ';' + res.getBody()
            								, req.getEndpoint()
            								, res.getBody()
            							);
        }
        return res.getBody();
    }
    /**
    * @description An operation that interacts with MuleSoft to GET a PaymentAccount details
    * @param String paymentAccountId
    * @return Return the Payment Account information
    **/
    public String getPaymentAccount(String accountId) {
        if (String.isBlank(accountId)){
            throw new CDdNimdaSyncMSServiceException(CDdNimdaSyncConstants.STEP_GET_PAYMENT_ACCOUNT,CDdNimdaSyncConstants.ERROR_TYPE_VALIDATION,CDdNimdaSyncConstants.ERROR_MSG_INVALID_PAYMENT_ACCOUNT_ID);
        }
        HttpRequest req = new HttpRequest();
        setRequestHeaders(req);
        setEndpoint(req, CDdNimdaSyncConstants.STEP_GET_PAYMENT_ACCOUNT, new List<String>{accountId});
        req.setMethod('GET');
        Http http = new Http();
        HTTPResponse res = http.send(req);
        if (res.getStatusCode() != 200){
            throw new CDdNimdaSyncMSServiceException(CDdNimdaSyncConstants.STEP_GET_PAYMENT_ACCOUNT, CDdNimdaSyncConstants.ERROR_TYPE_RESPONSE, 'Response status code - ' + res.getStatusCode() + ';' + res.getBody()
            								, req.getEndpoint(), res.getBody());
        }
        return res.getBody();
    }

    /**
    * @description An operation that interacts with MuleSoft to GET the Mx Affiliate Program Details
    * @param String input Store Id, Experience and Active at Attribute (Default to current date)
    * For Response - We need to parse through each experience and extact the relevant fee attributes.
    * @return Return the Mx Affiliate Program Details information
    **/
    public String getMxAffiliaetProgramDetails(String storeId) {
        Map <String, String> feeRateValue = new Map <String, String>();
        String experience = 'ANY_EXPERIENCE';
        String activeTimeStamp = String.valueof(datetime.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\''));
        if (String.isBlank(storeId)){
            throw new CDdNimdaSyncMSServiceException(
                                        CDdNimdaSyncConstants.STEP_GET_STORE
                                        , CDdNimdaSyncConstants.ERROR_TYPE_VALIDATION
                                        , CDdNimdaSyncConstants.ERROR_MSG_INVALID_STORE_ID
                                    );
        }
        HttpRequest req = new HttpRequest();
        setRequestHeaders(req);
        setEndpoint(req, CDdNimdaSyncConstants.STEP_MX_API, new List<String>{storeId,experience,activeTimeStamp});
        req.setMethod('GET');
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        if (res.getStatusCode() != 200){
            throw new CDdNimdaSyncMSServiceException(
            								CDdNimdaSyncConstants.STEP_GET_STORE
            								, CDdNimdaSyncConstants.ERROR_TYPE_RESPONSE
            								, 'Response status code - ' + res.getStatusCode() + ';' + res.getBody()
            								, req.getEndpoint()
            								, res.getBody()
            							);
        }
        return res.getBody();
    }
    /**
    * @description An operation that interacts with MuleSoft to UPDATE a store
    * @param String input Store Id
    * @param String input Opportunity Id
    * @return Return the Store detail information
    **/
    public String updateStore(String storeId, String opportunityId) {
        if (String.isBlank(storeId)){
            throw new CDdNimdaSyncMSServiceException(
                                        CDdNimdaSyncConstants.STEP_UPDATE_STORE
                                        , CDdNimdaSyncConstants.ERROR_TYPE_VALIDATION
                                        , CDdNimdaSyncConstants.ERROR_MSG_INVALID_STORE_ID
                                    );
        }
        Opportunity opportunity = getOpportunity(CDdNimdaSyncConstants.STEP_UPDATE_STORE, opportunityId);
        HttpRequest req = new HttpRequest();
        setRequestHeaders(req);
        setEndpoint(req, CDdNimdaSyncConstants.STEP_UPDATE_STORE, new List<String>{storeId});
        req.setMethod('POST');
        req.setHeader('Content-Type','application/json');
        req.setBody(JSON.serialize(getOnboardingAPIPostBody(opportunity, CDdNimdaSyncConstants.STEP_UPDATE_STORE), true));
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        if (res.getStatusCode() != 200){
            throw new CDdNimdaSyncMSServiceException(
                                            CDdNimdaSyncConstants.STEP_UPDATE_STORE
                                            , CDdNimdaSyncConstants.ERROR_TYPE_RESPONSE
                                            , 'Response status code - ' + res.getStatusCode() + ';' + res.getBody()
                                            , req.getEndpoint()
                                            , res.getBody()
                                        );
        }
        return res.getBody();
    }
    /**
    * @description An operation that interacts with MuleSoft to Full Onboard a store
    * @param String input Opportunity Id
    * @param String originatingOnboardingStep Full Onboarding Originating Step
    * @return Return the response from MuleSoft Data Service API
    **/
    public String fullOnboard(String opportunityId, String originatingOnboardingStep) {
        Opportunity opportunity = getOpportunity(CDdNimdaSyncConstants.STEP_INITIALIZATION, opportunityId);
        String step = getFullOnboardingStep(opportunity);
        HttpRequest req = new HttpRequest();
        setRequestHeaders(req);
        setEndpoint(req, step, new List<String>{opportunity.Store_Id__c});
        req.setMethod('POST');
        req.setHeader('Content-Type','application/json');
        req.setBody(JSON.serialize(getOnboardingAPIPostBody(opportunity, originatingOnboardingStep), true));
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        if (res.getStatusCode() != 200){
            throw new CDdNimdaSyncMSServiceException(
                                            step
                                            , CDdNimdaSyncConstants.ERROR_TYPE_RESPONSE
                                            , CDdNimdaSyncConstants.ERROR_TYPE_RESPONSE
                                            , req.getBody()
                                            , res.getBody()
                                        );
        }
        return res.getBody();
    }
    /**
    * @description An operation that interacts with MuleSoft to CREATE a Business
    * @param String input Business Name
    * @return Return the Business Identifier
    **/
    public Integer createBusiness(String businessName) {
        if (String.isBlank(businessName)){
            throw new CDdNimdaSyncMSServiceException(
                                        CDdNimdaSyncConstants.STEP_CREATE_BUSINESS
                                        , CDdNimdaSyncConstants.ERROR_TYPE_VALIDATION
                                        , CDdNimdaSyncConstants.ERROR_MSG_INVALID_BUSINESS_NAME
                                    );
        }
        String KEY_BUSINESS_ID = 'id';
        HttpRequest req = new HttpRequest();
        setRequestHeaders(req);
        setEndpoint(req, CDdNimdaSyncConstants.STEP_CREATE_BUSINESS, new List<String>{});
        req.setMethod('POST');
        req.setHeader('Content-Type','application/json');
        req.setBody(JSON.serialize(new Map<String, Object>{'name' => businessName, 'description' => ' ', 'active' => true}, true));
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        if (res.getStatusCode() != 200){
            throw new CDdNimdaSyncMSServiceException(
                                            CDdNimdaSyncConstants.STEP_CREATE_BUSINESS
                                            , CDdNimdaSyncConstants.ERROR_TYPE_RESPONSE
                                            , 'Response status code - ' + res.getStatusCode() + ';' + res.getBody()
                                            , req.getEndpoint()
                                            , res.getBody()
                                        );
        }
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
        return response.containsKey(KEY_BUSINESS_ID) ? Integer.valueOf(response.get(KEY_BUSINESS_ID)) : null;
    }
    private Opportunity getOpportunity(String step, String opportunityId){
        if (String.isBlank(opportunityId)){
            throw new CDdNimdaSyncMSServiceException(
                                        step
                                        , CDdNimdaSyncConstants.ERROR_TYPE_VALIDATION
                                        , CDdNimdaSyncConstants.ERROR_MSG_INVALID_OPPORTUNITY_ID
                                    );
        }
        Opportunity opportunity = null;
        for (Opportunity opp : [SELECT Id, Type, AccountId, Store_Id__c, Original_Store_ID__c, SBQQ__PrimaryQuote__c
                                FROM Opportunity
                                WHERE Id = :opportunityId]){
            opportunity = opp;
        }
        if (opportunity==null){
            throw new CDdNimdaSyncMSServiceException(
                                        step
                                        , CDdNimdaSyncConstants.ERROR_TYPE_VALIDATION
                                        , CDdNimdaSyncConstants.ERROR_MSG_INVALID_OPPORTUNITY_ID
                                    );
        }
        return opportunity;
    }
    /**
    * @description This method can return one of the following steps based on whether the Opportunity is a 'Change of Onwership' or a regular one
    * 1. Full Onboarding Create
    * 2. Full Onboardinbg Update
    * 3. Change of Ownership Create
    * 4. Change of Ownership Update
    * @param Opportunity input opportunity record
    * @return Return the Boolean
    **/
    private String getFullOnboardingStep(Opportunity opportunity){
        Boolean isChangeOfOwnership = CDdNimdaSyncStoreHelper.isChangeOfOwnership(opportunity);
        return isChangeOfOwnership
                        ? (String.isBlank(opportunity.Original_Store_ID__c) ? CDdNimdaSyncConstants.STEP_CHANGE_OF_OWNERSHIP_CREATE : CDdNimdaSyncConstants.STEP_CHANGE_OF_OWNERSHIP_UPDATE)
                        : (String.isBlank(opportunity.Store_Id__c) ? CDdNimdaSyncConstants.FULL_ONBOARDING_CREATE : CDdNimdaSyncConstants.FULL_ONBOARDING_UPDATE);
    }
    /**
    * @description An operation that interacts with MuleSoft for Bulk Update of Store
    * Expected sample input
    [{
        "id" : "<storeId_required>",
        "accountId" : <accountId_required>",
        "ownerId" : "<current user id>",
        "origin" : "<System.Label.Nimda_Origin_Bulk_Uploader>",
        "reason" : "<required as captured in bulk bypass tool UI>",
        "<property> : "<optional>",
        ---
        --
        --
    }]
    * @param List<Map<String, Object>> bulkUpdateStoreList, a Collection of Store properties
    * @return Return the response from MuleSoft Data Service API
    **/
    public String bulkUpdateStore(List<Map<String, Object>> bulkUpdateStoreList) {
        String step = CDdBypassBulkStoreUpdateConstants.MS_SYNC_STAGE_BYPASS_BULK_STORE_UPDATE;
        HttpRequest req = new HttpRequest();
        setRequestHeaders(req);
        setEndpoint(req, step, new List<String>());
        req.setMethod('PUT');
        req.setHeader('Content-Type','application/json');
        req.setBody(JSON.serialize(bulkUpdateStoreList, true));
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        if (res.getStatusCode() != 200){
            throw new CDdNimdaSyncMSServiceException(
                                            step
                                            , CDdNimdaSyncConstants.ERROR_TYPE_RESPONSE
                                            , CDdNimdaSyncConstants.ERROR_TYPE_RESPONSE
                                            , req.getBody()
                                            , res.getBody()
                                        );
        }
        return res.getBody();
    }
    /**
    * @description Return the Onboarding Post Body for the MuleSoft API to consume
    * @param Opportunity input opportunity record
    * @param String originatingOnboardingStep Full Onboarding Originating Step
    * @return Return the Full Onboard POST Body
    **/
    @TestVisible
    private Map<String, Object> getOnboardingAPIPostBody(Opportunity opportunity, String originatingOnboardingStep) {
        MSSyncStage originatingOnboardingStepEnum = CDdS2NUtil.msSyncStageFromString(originatingOnboardingStep);
        switch on originatingOnboardingStepEnum {
            when CreateStore {
                if (String.isNotBlank(opportunity.Store_Id__c) && !CDdNimdaSyncStoreHelper.isChangeOfOwnership(opportunity)){
                    throw new CDdNimdaSyncMSServiceException(originatingOnboardingStep, CDdNimdaSyncConstants.ERROR_TYPE_VALIDATION, 'Store Id ' + opportunity.Store_Id__c + ' found on the Opportunity.');
                }
                return new Map<String, Object>{'accountId__c' => opportunity.AccountId,
                                                'opportunityId__c' => opportunity.Id,
                                                'PrimaryQuote__c' => opportunity.SBQQ__PrimaryQuote__c,
                                                'Origin__c' => System.Label.Nimda_Origin_Send_To_Nimda,
                                                'User_Id__c' => UserInfo.getUserId()
                                            };
            }
            when UpdateStore {
                if (String.isBlank(opportunity.Store_Id__c)){
                    throw new CDdNimdaSyncMSServiceException(originatingOnboardingStep, CDdNimdaSyncConstants.ERROR_TYPE_VALIDATION, 'Store Id not found on the Opportunity.');
                }
                return new Map<String, Object>{'accountId__c' => opportunity.AccountId,
                                                'opportunityId__c' => opportunity.Id,
                                                'PrimaryQuote__c' => opportunity.SBQQ__PrimaryQuote__c,
                                                'Origin__c' => System.Label.Nimda_Origin_Send_To_Nimda,
                                                'User_Id__c' => UserInfo.getUserId()
                                            };
            }
            when ProductAndPricingOnboarding {
                if (String.isBlank(opportunity.Store_Id__c)){
                    throw new CDdNimdaSyncMSServiceException(CDdNimdaSyncConstants.STEP_UPDATE_STORE, CDdNimdaSyncConstants.ERROR_TYPE_VALIDATION, 'Store Id not found on the Opportunity.');
                }
                return new Map<String, Object>{'accountId__c' => opportunity.AccountId,
                                                'opportunityId__c' => opportunity.Id,
                                                'PrimaryQuote__c' => opportunity.SBQQ__PrimaryQuote__c,
                                                'MS_Changed_Fields__c' => String.join(CDdNimdaSyncOnboardingConfigHelper.getAllFieldProperties(originatingOnboardingStep),','),
                                                'Do_Change_Fields_Incl_Store_Partnership__c' => true,
                                                'Origin__c' => System.Label.Nimda_Origin_Send_To_Nimda,
                                                'User_Id__c' => UserInfo.getUserId()
                                            };
            }
            when else {
                throw new CDdNimdaSyncMSServiceException(CDdNimdaSyncConstants.STEP_INITIALIZATION, CDdNimdaSyncConstants.ERROR_TYPE_VALIDATION, 'Invalid originating onboarding step - ' + originatingOnboardingStep);
            }
        }
    }
    /**
     * @description Send request for the supported operation within MuleSoft
     * Note : There should corresponding definition for the operation in custom metada Nimda_MuleSoft_API__mdt
     * @param String Serialized payload request
     * @return Return the Rest API Response
     **/
    public CDdRestJSONObj.RestAPIResponse sendRequest(String operation, String request) {
        HttpRequest req = new HttpRequest();
        setRequestHeaders(req);
        setEndpoint(req, operation, new List<String>{});
        req.setMethod('POST');
        req.setHeader('Content-Type','application/json');
        req.setBody(request);
        Http http = new Http();
        HTTPResponse res = http.send(req);
        CDdRestJSONObj.RestAPIResponse restApiResponse = new CDdRestJSONObj.RestAPIResponse();
        restApiResponse.body = res.getBody();
        restApiResponse.statusCode = res.getStatusCode();
        return restApiResponse;
    }
   /**
    * @description Inner class used for capturing the exception data
    **/
    public class CDdNimdaSyncMSExceptionData {
      /**
        * @description What step did the error take place in?
        * - Create Store
        * - Create User
        * - Create Merchant
        * - Payment Account
        * - Stripe Bank Token
        * - Stripe Bank Account
        **/
        public String step;
      /**
        * @description The serialized callout request
        **/
        public String calloutRequest;
      /**
        * @description The serialized callout response
        **/
        public String calloutResponse;
      /**
        * @description What is the error type? Error types are 'Validation Error', 'Response Error', 'Runtime Exception'
        **/
        public String errorType;
      /**
        * @description The actual error message
        **/
        public String errorMessage;
      /**
        * @description Constructor - instantiate the exception with the following parameters
        * @param String the Step in execution
        * @param String the Error Type
        * @param String the Error Message
        **/
        public CDdNimdaSyncMSExceptionData(String step, String errorType, String errorMessage){
            this.step = step;
            this.errorType = errorType;
            this.errorMessage = errorMessage;
            this.calloutRequest = null;
            this.calloutResponse = null;
        }
      /**
        * @description Constructor - instantiate the exception with the following parameters
        * @param String the Step in execution
        * @param String the Error Type
        * @param String the Error Message
        * @param String the Callout Request
        * @param String the Callout Response
        **/
        public CDdNimdaSyncMSExceptionData(String step, String errorType, String errorMessage, String calloutRequest, String calloutResponse){
            this(step, errorType, errorMessage);
            this.calloutRequest = calloutRequest;
            this.calloutResponse = calloutResponse;
        }
    }
   /**
    * @description A custom exception is thrown in the event something goes wrong during the processing in the above operations
    **/
    public class CDdNimdaSyncMSServiceException extends Exception {
      /**
        * @description Constructor - instantiate the exception with the following parameters
        * @param String the Step in execution
        * @param String the Error Type
        * @param String the Error Message
        **/
        public CDdNimdaSyncMSServiceException(String step, String errorType, String errorMessage){
            setMessage(JSON.serialize(new CDdNimdaSyncMSExceptionData(step, errorType, errorMessage), true));
        }
      /**
        * @description Constructor - instantiate the exception with the following parameters
        * @param String the Step in execution
        * @param String the Error Type
        * @param String the Error Message
        * @param String the Callout Request
        * @param String the Callout Response
        **/
        public CDdNimdaSyncMSServiceException(String step, String errorType, String errorMessage, String calloutRequest, String calloutResponse){
            setMessage(JSON.serialize(new CDdNimdaSyncMSExceptionData(step, errorType, errorMessage, calloutRequest, calloutResponse), true));
        }
    }
}