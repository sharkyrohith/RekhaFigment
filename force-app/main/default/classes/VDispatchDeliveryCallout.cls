public with sharing class VDispatchDeliveryCallout {
    // BZAP-7341 Kill Switch for Dispatch API calls from Salesforce
    // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
    private Dispatch_Settings__c apiSettings = Dispatch_Settings__c.getInstance();

    public Decimal deliveryId { get; private set; }
    public String deliveryUUID { get; private set; }
	public Decimal retryAttempts { get; private set; }
	public String responseData { get; private set; }
    public String email { get; private set; }
    public String phoneNumber { get; private set; }
    public String customerType { get; private set; }
    public Decimal experience { get; private set; }

	public VDispatchDeliveryCallout(Decimal deliveryId, String deliveryUUID) {
        this.deliveryId = 0;
        this.deliveryUUID = deliveryUUID;
	}
    public VDispatchDeliveryCallout(String deliveryUUID, String email, String phoneNumber, String customerType, String platform) {
        
        this.deliveryId = 0;
        this.deliveryUUID = deliveryUUID;
        this.email = email;
        this.phoneNumber = phoneNumber;
        this.customerType = customerType;
        if(platform == 'Cavair')
            this.experience=1;
        else
            this.experience=0;
    }
	public VDeliveryInformation makeDeliveryCallout() {      
        VDeliveryInformation res;
        
        // BZAP-7341 Kill Switch for Dispatch API calls from Salesforce
        if (apiSettings.Disabled__c) return res;

        // BZAP-4002 delivery ID is 0, check feauture flag to see if prevent delivery 0
        // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit    
        if (CDdExperimentSvc.getFeatureFlag('Exclude_Delivery_No_0__c')){
            if (((customerType == CDdSupportConstants.CUSTOMER_TYPE_CONSUMER 
                || customerType == CDdSupportConstants.CUSTOMER_TYPE_DASHER) 
                && String.isBlank(deliveryUUID) 
                && String.isBlank(email) 
                && String.isBlank(phoneNumber))
                || (!((customerType == CDdSupportConstants.CUSTOMER_TYPE_CONSUMER 
                    || customerType == CDdSupportConstants.CUSTOMER_TYPE_DASHER))
                    && String.isBlank(deliveryUUID))){ 
                throw new DispatchCalloutException(Label.LDdDispatchDelivery0);
            }
        }
		Integer retryCount = 0;
        Integer maxRetries = apiSettings.Get_From_Dispatch_Retries__c.intValue();

		VDispatchAPI api = new VDispatchAPI();

		for(Integer i = 0; i < maxRetries; i++) {
			try {
                if (apiSettings.Use_ERS_API__c){
                    CDdRESTConnectorSvc connector = new CDdRESTConnectorSvc();
                    CDdRestJSONObj.RestAPIResponse apiResult;
                    List<CDdRestJSONObj.CustomerAudience> customerAudience = new List<CDdRestJSONObj.CustomerAudience>();
                    List<CDdRestJSONObj.Customer> customers = new List<CDdRestJSONObj.Customer>();
                    If(string.isNotBlank(deliveryUUID)){
                        apiResult = connector.getDeliveryInfo(new List<String>{deliveryUUID});
                    }else {
                        if(string.isNotBlank(customerType)
                            && (string.isNotBlank(email)
                            || string.isNotBlank(phoneNumber))){
                            CDdRestJSONObj.Customer custReq=new CDdRestJSONObj.Customer();
                            custReq.experience=experience;
                            if(string.isNotBlank(email))
                                custReq.email=email;
                            else if(string.isNotBlank(phoneNumber))
                                    custReq.phoneNumber=phoneNumber; 
                            switch on customerType {
                                when 'Consumer'{
                                    custReq.customerType=integer.valueOf(CDdNameValuePairHelper.getValue(CDdNameValuePairConstants.CONSUMER_CUSTOMER_TYPE_VALUE_2));
                                }
                                when 'Dasher'{
                                    custReq.customerType=integer.valueOf(CDdNameValuePairHelper.getValue(CDdNameValuePairConstants.DASHER_CUSTOMER_TYPE_VALUE_3));
                                }
                                when else{
                                }
                            }
                            customers.add(custReq);
                        }
                        if(!customers.isEmpty() && customers != null){
                            List<CDdRestJSONObj.RestAPIResponse> responses = new List<CDdRestJSONObj.RestAPIResponse>(); 
                            CDdRestJSONObj.CustomerAudience custAudience = new CDdRestJSONObj.CustomerAudience();
                            CDdRestJSONObj.dispatchRequest dispatchRequest= new CDdRestJSONObj.dispatchRequest();
                            custAudience.customers = customers; 
                            dispatchRequest.customerAudience = custAudience ; 
                            apiResult = connector.getDeliveryInfo(dispatchRequest);
                        }
                    }
                    retryAttempts = i + 1;

                    if(apiResult.statusCode < 200 || apiResult.statusCode > 299) {
                        responseData = apiResult.body;

                        throw new DispatchCalloutException(Label.vDispatchServerError.replace('{0}', ''+apiResult.statusCode));
                    }

                    List<VDeliveryInformation> deserializedResponse = CDdDispatchDeliveryInformation.deserialize(apiResult.body);
                    if(deserializedResponse.size() > 0){
                        res = CDdDispatchDeliveryInformation.deserialize(apiResult.body)[0];
                    }
                    responseData = apiResult.body;
                } else {
                    VDispatchAPI.DispatchAPIResponse apiResult = api.getDeliveryInfo(deliveryId, deliveryUUID);

                    retryAttempts = i + 1;

                    if(apiResult.statusCode < 200 || apiResult.statusCode > 299) {
                        responseData = apiResult.body;

                        throw new DispatchCalloutException(Label.vDispatchServerError.replace('{0}', ''+apiResult.statusCode));
                    }

                    res = VDeliveryInformation.deserialize(apiResult.body);
                    responseData = apiResult.body;
                }

				break;
			} catch(Exception e) {
				if(i == maxRetries-1) {
					retryAttempts = maxRetries;
					throw new DispatchCalloutException(Label.vMaxRetriesAttempted + ' ' + e.getMessage() + ' ' + e.getStackTraceString());
				}
			}
		}

		return res;
	}


	public class DispatchCalloutException extends Exception {

	}
}