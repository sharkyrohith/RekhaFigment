public with sharing class VDeliveryCalloutExt {
	public ApexPages.StandardController controller;
	public Boolean throwTestException { get; set; } // provided for coverage
	public VDeliveryCalloutExt(ApexPages.StandardController controller) {
		this.controller = controller;
		this.throwTestException = false;
	}

	public PageReference doCallout() {
		Dispatch_Settings__c settings = Dispatch_Settings__c.getInstance();

		PageReference res = null;

        // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
		Case[] pCse = [select Id, DeliveryNo__c, ContactPhone, ContactEmail, Platform__c, DeliveryUUID__c, Customer_Type__c, ChatKey__c, RecordTypeId, AccountId, Origin
			from Case
			where Id = :controller.getRecord().Id];

		Integer responseFieldLength = Schema.SObjectType.Case.fields.DispatchRQResponse__c.getLength();

		if(pCse.size() == 1) {
			Case c = pCse[0];

            // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
            Boolean useUUID = (settings.Use_UUID__c != null 
                                && settings.Use_UUID__c == true) 
                                ? true : false; 
            if(c.DeliveryNo__c != null || (String.isNotBlank(c.DeliveryUUID__c) && useUUID)) {
                // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
				VDispatchDeliveryCalloutQueueable q = new VDispatchDeliveryCalloutQueueable(new List<Case> { c }, false, 
                                                                                            (c.RecordTypeId == settings.Case_API_Record_Type_ID__c
                                                                                                || (c.Origin != 'Chat' && c.Origin != 'Web' && c.Origin != 'Email')), 
                                                                                            (c.RecordTypeId == settings.Case_API_Record_Type_ID__c
                                                                                                || (c.Origin != 'Chat' && c.Origin != 'Web'  && c.Origin != 'Email')));
				try {
					q.execute(null);

					c = [select Id, DispatchCalloutException__c, DispatchRQResponse__c from Case where Id = :c.Id];

					if(c.DispatchCalloutException__c != null) {
						if(c.DispatchRQResponse__c != null && c.DispatchRQResponse__c.contains('Not found')) {
							ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.vDispatch404));
						} else {
							ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, c.DispatchCalloutException__c));
						}
					} else {
						res = new PageReference('/' + c.Id);
		    			res.setRedirect(true);
					}

					if(Test.isRunningTest() && throwTestException) {
						res = null;
						throw new VTestUtil.TestException('Test');
					}
				} catch(Exception e) {
	        		c.DispatchRQStatus__c = 'Failure';
	        		c.DispatchCalloutException__c = e.getMessage();

	        		VDispatchRecordService.clearFieldsOnError(c);
	        		update c;

	        		ApexPages.addMessages(e);
				}
			} else {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.vMissingDeliveryNo));
			}
		} else {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.vMissingCaseID));
		}

		return res;
	}
}