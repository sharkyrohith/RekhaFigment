/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 04/29/2019
*
* @group Nimda
*
* @description This class will search for any existing stores 
*	- It uses the following api to interact with external interfaces namely DSJ, Nimda
*	Step 1 - Send a GET request to endpoint '/v1/address' to get a list of addresses
*	Step 2 - Send a GET request to endpoint '/v1/addresses/<addressId>/stores' to get a list of stores
*	
**************************************************************************************************************************************/
public class CDdNimdaSyncSearchStoreService {
	/**
	* @description member variable to store the business identifier
	**/
	private String businessId;
	/**
	* @description member variable to store the address identifier
	**/
	private String addressId;		
	/**
	* @description member variable to store the account Id
	**/
	private Account account;
	/**
	* @description member variable to store the Nimda validator object
	**/	
	private CDdNimdaSyncValidator validator;	
	/**
	* @description member variable to store the Veltig custom settings
	**/		
	private vCS__c apiSettings = vCS__c.getInstance();
	/**
	* @description member variable to store the REST Connector Service
	**/		
	private CDdRESTConnectorSvc connector = new CDdRESTConnectorSvc();
	/**
  	* @description Constructor - inject the Account record and initialize any member variables
  	* @param Account input account record  	
  	**/
	public CDdNimdaSyncSearchStoreService(Account account) {
		this.account = account;
		this.validator = new CDdNimdaSyncValidator(this.account, null);
	}
	/**
  	* @description Constructor - inject the Account record and initialize any member variables
  	* @param String input Business Id
  	* @param String input Address Id	  		
  	* @param Account input account record  	
  	**/
	public CDdNimdaSyncSearchStoreService(String businessId, String addressId, Account account) {
		this(account);
		this.businessId = businessId;
		this.addressId = addressId;
	}
    /**
    * @description Default no argument constructor
    **/  
	public CDdNimdaSyncSearchStoreService() {
	}		
   /**
	* @description An operation that interacts with the external service to get stores
	* REST Endpoint referenced is '/v1/addresses/<addressId>/stores/?business_id=<businessId>'
	* This method will throw an exception for the following conditions
	* - Store not found
	* -	Multiple stores found
	* @return List<CDdRestJSONObj.StoreSuccesses> a Collection of Store
	**/		
	public List<CDdRestJSONObj.StoreSuccesses> getStores(){
		String storeReq = '/v1/addresses/' + this.addressId + '/stores/?business_id=' + this.businessId;
        CDdRestJSONObj.RestAPIResponse storeRes = connector.getDoorstep(storeReq, null);
        List<CDdRestJSONObj.StoreSuccesses> stores = (List<CDdRestJSONObj.StoreSuccesses>) JSON.deserialize(storeRes.body, List<CDdRestJSONObj.StoreSuccesses>.class);
		// If none or more than one store found, throw an exception        
        if (stores.size()==0) {
            throw new CDdNimdaSyncSearchStoreServiceException(
            								CDdNimdaSyncConstants.STEP_SEARCH_STORE
            								, CDdNimdaSyncConstants.ERROR_TYPE_RESPONSE
            								, (stores.size()==0 ? CDdNimdaSyncConstants.ERROR_MSG_STORE_NOT_FOUND : CDdNimdaSyncConstants.ERROR_MSG_MULTIPLE_STORES_FOUND)
            								, storeReq
            								, JSON.serialize(stores)
            							);	             
        }        		
		return stores;
	}
   /**
	* @description An operation that interacts with the external service to get addresses
	* REST Endpoint referenced is '/v1/addresses/?address_string=<formattedAddressString>&amp;extra=id
	* This method will throw an exception for the following conditions
	* - Address not found
	* -	Multiple addresses found
	* @return List<CDdRestJSONObj.Address> a Collection of Address
	**/			
	public List<CDdRestJSONObj.Address> getAddresses(){
		List<String> errorMessages = validator.fieldValidator(this.account, CDdNimdaSyncConstants.VALIDATE_ADDRESS_FIELDS_ON_ACCOUNT);
		if (!errorMessages.isEmpty()){
        	throw new CDdNimdaSyncSearchStoreServiceException(CDdNimdaSyncConstants.STEP_SEARCH_ADDRESS, CDdNimdaSyncConstants.ERROR_TYPE_VALIDATION, String.join(errorMessages, ','));				
		}
		String addressReq = '/v1/addresses/' 
							+ '?' 
							+ 'address_string=' + this.getQueryParamAddressString()
							+ '&'
							+ 'extra=id';
        CDdRestJSONObj.RestAPIResponse addressRes = connector.getDoorstep(addressReq, null);
        List<CDdRestJSONObj.Address> addresses = (List<CDdRestJSONObj.Address>) JSON.deserialize(addressRes.body, List<CDdRestJSONObj.Address>.class);
		// If none or more than one address found, throw an exception        
        if (addresses.size()==0) {
            throw new CDdNimdaSyncSearchStoreServiceException(
            								CDdNimdaSyncConstants.STEP_SEARCH_ADDRESS
            								, CDdNimdaSyncConstants.ERROR_TYPE_RESPONSE
            								, (addresses.size()==0 ? CDdNimdaSyncConstants.ERROR_MSG_ADDRESS_NOT_FOUND : CDdNimdaSyncConstants.ERROR_MSG_MULTIPLE_ADDRESSES_FOUND)
            								, addressReq
            								, JSON.serialize(addresses)
            							);	             
        }        		
		return addresses;		
	}
    /**
    * @description An operation that interacts with the external service to GET a store
    * REST Endpoint referenced is '/v1/stores/<store id>/'
    * @param String input Store Id 
    * @return Return the Store GET response information on interaction with external service
    **/             
    public String getStore(String storeId) {
        if (String.isBlank(storeId)){
            throw new CDdNimdaSyncSearchStoreServiceException(
                                        CDdNimdaSyncConstants.STEP_GET_STORE
                                        , CDdNimdaSyncConstants.ERROR_TYPE_VALIDATION
                                        , CDdNimdaSyncConstants.ERROR_MSG_INVALID_STORE_ID
                                    );                  
        }
        String storeReq = CDdNimdaSyncConstants.CREATE_STORE_ENDPOINT_SUFFIX + '/' + storeId + '/' + CDdNimdaSyncStoreHelper.getStoreExtraFieldQueryString();        
        CDdRestJSONObj.RestAPIResponse storeRes = connector.getDoorstep(storeReq, '');
        System.debug(LoggingLevel.DEBUG, storeRes);
        if (storeRes.statusCode == 500){
            handleResponseCode500(CDdNimdaSyncConstants.STEP_GET_STORE, storeReq, storeRes.body);
        }         
        if (storeRes.statusCode != 200){
            throw new CDdNimdaSyncSearchStoreServiceException(
            								CDdNimdaSyncConstants.STEP_GET_STORE
            								, CDdNimdaSyncConstants.ERROR_TYPE_RESPONSE
            								, CDdNimdaSyncConstants.ERROR_TYPE_RESPONSE
            								, storeReq
            								, JSON.serialize(storeRes)
            							);        	
        }
        return storeRes.body;
    }
    /**
    * @description An operation that interacts with the external service to GET the Store Partnership data
    * REST Endpoint referenced is '/v1/stores/<store id>/store_partnerships/'
    * @param String input Store Id 
    * @return Return the Store GET response information on interaction with external service
    **/             
    public String getStorePartnership(String storeId) {
        if (String.isBlank(storeId)){
            throw new CDdNimdaSyncSearchStoreServiceException(
                                        CDdNimdaSyncConstants.STEP_GET_STORE
                                        , CDdNimdaSyncConstants.ERROR_TYPE_VALIDATION
                                        , CDdNimdaSyncConstants.ERROR_MSG_INVALID_STORE_ID
                                    );                  
        }
        String storePartnershipReq = CDdNimdaSyncConstants.CREATE_STORE_ENDPOINT_SUFFIX + '/' + storeId + '/' + 'store_partnerships' + '/' + CDdNimdaSyncStoreHelper.getStorePartnershipExtraFieldQueryString();        
        CDdRestJSONObj.RestAPIResponse storePartnershipRes = connector.getDoorstep(storePartnershipReq, '');
        System.debug(LoggingLevel.DEBUG, storePartnershipRes);
        if (storePartnershipRes.statusCode == 500){
            handleResponseCode500(CDdNimdaSyncConstants.STEP_GET_STORE, storePartnershipReq, storePartnershipRes.body);
        }         
        if (storePartnershipRes.statusCode != 200){
            throw new CDdNimdaSyncSearchStoreServiceException(
                                            CDdNimdaSyncConstants.STEP_GET_STORE
                                            , CDdNimdaSyncConstants.ERROR_TYPE_RESPONSE
                                            , CDdNimdaSyncConstants.ERROR_TYPE_RESPONSE
                                            , storePartnershipReq
                                            , JSON.serialize(storePartnershipRes)
                                        );          
        }
        return storePartnershipRes.body;
    }
    /**
    * @description An operation that interacts with the external service to GET the Store Point of Sale information
    * REST Endpoint referenced is '/v1/stores/<store id>/point_of_sale_info/'
    * @param String input Store Id 
    * @return Return the Store POS GET response information on interaction with external service
    **/             
    public String getStorePOS(String storeId) {
        if (String.isBlank(storeId)){
            throw new CDdNimdaSyncSearchStoreServiceException(
                                        CDdNimdaSyncConstants.STEP_GET_STORE
                                        , CDdNimdaSyncConstants.ERROR_TYPE_VALIDATION
                                        , CDdNimdaSyncConstants.ERROR_MSG_INVALID_STORE_ID
                                    );                  
        }
        String storePOSReq = CDdNimdaSyncConstants.CREATE_STORE_ENDPOINT_SUFFIX + '/' + storeId + '/' + 'point_of_sale_info' + '/';        
        CDdRestJSONObj.RestAPIResponse storePOSRes = connector.getDoorstep(storePOSReq, '');
        System.debug(LoggingLevel.DEBUG, storePOSRes);
        if (storePOSRes.statusCode == 500){
            handleResponseCode500(CDdNimdaSyncConstants.STEP_GET_STORE, storePOSReq, storePOSRes.body);
        }         
        if (storePOSRes.statusCode != 200){
            throw new CDdNimdaSyncSearchStoreServiceException(
                                            CDdNimdaSyncConstants.STEP_GET_STORE
                                            , CDdNimdaSyncConstants.ERROR_TYPE_RESPONSE
                                            , CDdNimdaSyncConstants.ERROR_TYPE_RESPONSE
                                            , storePOSReq
                                            , JSON.serialize(storePOSRes)
                                        );          
        }
        return storePOSRes.body;
    }    
    /**
    * @description An operation that interacts with the external service to GET the Payment Accounts data
    * REST Endpoint referenced is '/v1/payment_accounts/<payment account id>/'
    * @param String input Payment Account Id 
    * @return Return the Payment Account GET response information on interaction with external service
    **/             
    public String getPaymentAccount(String paymentAccountId) {
        if (String.isBlank(paymentAccountId)){
            throw new CDdNimdaSyncSearchStoreServiceException(
                                        CDdNimdaSyncConstants.STEP_PAYMENT_ACCOUNT
                                        , CDdNimdaSyncConstants.ERROR_TYPE_VALIDATION
                                        , CDdNimdaSyncConstants.ERROR_MSG_INVALID_PAYMENT_ACCOUNT_ID
                                    );                  
        }
        String paymentAccountReq = CDdNimdaSyncConstants.CREATE_PAYMENT_ACCOUNT_ENDPOINT_SUFFIX + '/' + paymentAccountId + '/' + '?extra=stripe_account';        
        CDdRestJSONObj.RestAPIResponse paymentAccountRes = connector.getDoorstep(paymentAccountReq, '');
        System.debug(LoggingLevel.DEBUG, paymentAccountRes);
        if (paymentAccountRes.statusCode == 500){
            handleResponseCode500(CDdNimdaSyncConstants.STEP_PAYMENT_ACCOUNT, paymentAccountReq, paymentAccountRes.body);
        }        
        if (paymentAccountRes.statusCode != 200){
            throw new CDdNimdaSyncSearchStoreServiceException(
                                            CDdNimdaSyncConstants.STEP_PAYMENT_ACCOUNT
                                            , CDdNimdaSyncConstants.ERROR_TYPE_RESPONSE
                                            , CDdNimdaSyncConstants.ERROR_TYPE_RESPONSE
                                            , paymentAccountReq
                                            , JSON.serialize(paymentAccountRes)
                                        );          
        }
        return paymentAccountRes.body;
    }    
    /**
    * @description An operation that interacts with the external service to update (POST) a store
    * REST Endpoint referenced is '/v1/stores/<store id>/'
    * If a store partnership property needs to be updated, you must send along with the changes, the non-null values
    * of the current store partnership record, to ensure the new Store Partnership record in Nimda is stamped with
    * updated and carryover values from previous version
    * @param String The Store Id to update
    * @param String storeRequest [A JSON string with the specific store and/or store partnership properties and values]  
    * @return Return the Store POST response information on interaction with external service
    **/             
    public Object updateStore(String storeId, String storeRequest) {
        String endpoint = CDdNimdaSyncConstants.CREATE_STORE_ENDPOINT_SUFFIX + '/' + storeId;        
        CDdRestJSONObj.RestAPIResponse storeRes = connector.postDoorstep(storeRequest, endpoint);
        System.debug(LoggingLevel.DEBUG, storeRes);
        if (storeRes.statusCode == 500){
            handleResponseCode500(CDdNimdaSyncConstants.STEP_UPDATE_STORE, storeRequest, storeRes.body);
        }        
        if (storeRes.statusCode != 200){
            throw new CDdNimdaSyncSearchStoreServiceException(
                                            CDdNimdaSyncConstants.STEP_UPDATE_STORE
                                            , CDdNimdaSyncConstants.ERROR_TYPE_RESPONSE
                                            , CDdNimdaSyncConstants.ERROR_TYPE_RESPONSE
                                            , storeRequest
                                            , storeRes.body
                                        );              
        }       
        // Create CDdNimdaSyncInfo Object and return to the caller
        return new CDdNimdaSyncInfo(CDdNimdaSyncConstants.STEP_UPDATE_STORE, storeRequest, JSON.serialize(storeRes.body));
    }
    /**
    * @description An operation that interacts with the external service to update (PUT) store point of sale info
    * REST Endpoint referenced is '/v1/stores/<store id>/'
    * @param String The Store Id to update
    * @param String storeRequest [A JSON string with the specific store property and value for Provider Type, Location Id]  
    * @return Return the Store Point od Sale PUT response information on interaction with external service
    **/             
    public Object updateStorePOS(String storeId, String storeRequest) {
        String endpoint = CDdNimdaSyncConstants.CREATE_STORE_ENDPOINT_SUFFIX + '/' + storeId + '/' + 'point_of_sale_info';        
        CDdRestJSONObj.RestAPIResponse storeRes = connector.updateDoorstep(storeRequest, endpoint);
        System.debug(LoggingLevel.DEBUG, storeRes);
        if (storeRes.statusCode == 500){
            handleResponseCode500(CDdNimdaSyncConstants.STEP_UPDATE_STORE, storeRequest, storeRes.body);
        }        
        if (storeRes.statusCode != 200){
            throw new CDdNimdaSyncSearchStoreServiceException(
                                            CDdNimdaSyncConstants.STEP_UPDATE_STORE
                                            , CDdNimdaSyncConstants.ERROR_TYPE_RESPONSE
                                            , CDdNimdaSyncConstants.ERROR_TYPE_RESPONSE
                                            , storeRequest
                                            , storeRes.body
                                        );              
        }       
        // Create CDdNimdaSyncInfo Object and return to the caller
        return new CDdNimdaSyncInfo(CDdNimdaSyncConstants.STEP_UPDATE_STORE, storeRequest, JSON.serialize(storeRes.body));
    }    
    /**
    * @description Handle response code 500
    * @return 
    **/    
    public void handleResponseCode500(String step, String request, String responseBody){
        String errorMessage = '500 Internal Server Error. ';
        Integer index = responseBody.indexOf('reference id: ');
        if (index > -1){
            errorMessage += 'Reference Id: ' + responseBody.substring(index+14, index+14+32);
        }
        throw new CDdNimdaSyncSearchStoreServiceException(step, CDdNimdaSyncConstants.ERROR_TYPE_RESPONSE, errorMessage, request, errorMessage);         
    }            	
   /**
	* @description Prepare a formatted address string for the Get Address API
	**/		
	private String getQueryParamAddressString(){
		return EncodingUtil.urlEncode(
				'\''
				+ this.account.BillingStreet + ', ' 
				+ this.account.BillingCity + ', ' 
				+ this.account.BillingState + ' ' + this.account.BillingPostalCode + ', ' 
				+ this.account.BillingCountry
				+ '\''
				, 'UTF-8'
			);
	}
    /**
    * @description Inner class used for interaction with the caller of this service
    * This object includes the request and response information produced during the invocation of the external REST service
    **/ 
    public class CDdNimdaSyncInfo {
        /**
        * @description What step did the error take place in?
        * - Update Store
        **/     
        @AuraEnabled
        public String step {get; set;}
        /**
        * @description The serialized callout request
        **/                     
        @AuraEnabled
        public String calloutRequest {get; set;}
        /**
        * @description The serialized callout response
        **/                     
        @AuraEnabled
        public String calloutResponse {get; set;}
        /**
        * @description Constructor - instantiate the exception with the following parameters
        * @param String the Step in execution
        * @param String the Error Type  
        * @param String the Error Message
        * @param String the Callout Request
        * @param String the Callout Response
        **/     
        public CDdNimdaSyncInfo(String step, String calloutRequest, String calloutResponse){
            this.step = step;
            this.calloutRequest = calloutRequest;
            this.calloutResponse = calloutResponse;
        }               
    }    	
   /**
	* @description Inner class used for capturing the exception data
	**/	
	public class CDdNimdaSyncExceptionData {
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
		public CDdNimdaSyncExceptionData(String step, String errorType, String errorMessage){
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
		public CDdNimdaSyncExceptionData(String step, String errorType, String errorMessage, String calloutRequest, String calloutResponse){
			this(step, errorType, errorMessage);
			this.calloutRequest = calloutRequest;
			this.calloutResponse = calloutResponse;
		}
	}
   /**
	* @description A custom exception is thrown in the event something goes wrong during the processing in the above operations
	**/		
	public class CDdNimdaSyncSearchStoreServiceException extends Exception {
	  /**
	  	* @description Constructor - instantiate the exception with the following parameters
	  	* @param String the Step in execution
		* @param String the Error Type	
	  	* @param String the Error Message
	  	**/		
		public CDdNimdaSyncSearchStoreServiceException(String step, String errorType, String errorMessage){
			setMessage(JSON.serialize(new CDdNimdaSyncExceptionData(step, errorType, errorMessage), true));
		}		
	  /**
	  	* @description Constructor - instantiate the exception with the following parameters
	  	* @param String the Step in execution
		* @param String the Error Type	
	  	* @param String the Error Message
	  	* @param String the Callout Request
	  	* @param String the Callout Response
	  	**/		
		public CDdNimdaSyncSearchStoreServiceException(String step, String errorType, String errorMessage, String calloutRequest, String calloutResponse){
			setMessage(JSON.serialize(new CDdNimdaSyncExceptionData(step, errorType, errorMessage, calloutRequest, calloutResponse), true));
		}
	}			
}