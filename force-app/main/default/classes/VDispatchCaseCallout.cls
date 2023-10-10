public with sharing class VDispatchCaseCallout {
     // BZAP-7341 Kill Switch for Dispatch API calls from Salesforce
     // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
     private Dispatch_Settings__c apiSettings = Dispatch_Settings__c.getInstance();

	public Case cse { get; private set; }

	public Decimal retryAttempts { get; private set; }
	public String responseData { get; private set; }

	public VDispatchCaseCallout(Case cse) {
		this.cse = cse;
	}

	public void makeCaseCallout() {
         // BZAP-7341 Kill Switch for Dispatch API calls from Salesforce
         if (apiSettings.Disabled__c) return;

		Integer retryCount = 0;
		Integer maxRetries = apiSettings.Send_To_Dispatch_Retries__c.intValue();

		VDispatchAPI api = new VDispatchAPI();

		for(Integer i = 0; i < maxRetries; i++) {
			try {
				String jsonData = VDispatchCaseSerializer.serialize(cse);

				VDispatchAPI.DispatchAPIResponse apiResult = null;
				System.debug(jsonData);

				if(!cse.IsSentToDispatch__c) {
					apiResult = api.postCase(jsonData);
				} else {
					apiResult = api.updateCase(jsonData, cse.CaseNumber);
				}

				retryAttempts = i + 1;
				responseData = apiResult.body;

				if(apiResult.statusCode < 200 || apiResult.statusCode > 299) {
					throw new VDispatchCalloutException(Label.vDispatchServerError.replace('{0}', ''+apiResult.statusCode));
				}

				break;
			} catch(Exception e) {
				if(i == maxRetries-1) {
					retryAttempts = maxRetries;
					throw new VDispatchCalloutException(Label.vMaxRetriesAttempted + ' ' + e.getMessage());
				}
			}
		}
	}
}