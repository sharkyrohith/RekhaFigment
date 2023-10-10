public class VDispatchDeliveryCalloutQueueable implements Queueable, Database.AllowsCallouts {
	public static final Integer RESPONSE_FIELD_LENGTH =  Schema.SObjectType.Case.fields.DispatchRQResponse__c.getLength();
	public List<Case> casesToSend { get; private set; }
	public Boolean trapExceptions { get; private set; }
	public Boolean throwTestException { get; set; } // provided for coverage
	public Boolean makeCaseCallout { get; set; }
	public Boolean runCaseAlways { get; set; }
	public static final Dispatch_Settings__c apiSettings = Dispatch_Settings__c.getInstance();
	
	public VDispatchDeliveryCalloutQueueable(List<Case> casesToSend) {
		this(casesToSend, true, true, false);
		
	}

	public VDispatchDeliveryCalloutQueueable(List<Case> casesToSend, Boolean trapExceptions, Boolean makeCaseCallout, Boolean runCaseAlways) {
		this.casesToSend = casesToSend;
		this.trapExceptions = trapExceptions;
		this.makeCaseCallout = makeCaseCallout;
		this.runCaseAlways = runCaseAlways;
		this.throwTestException = false;
	}

	public void execute(QueueableContext context) {
		List<Case> casesToUpdate = new List<Case>();
		List<Case> noDeliveryNumberList = new List<Case>();

		List<VDeliveryInformation> deliveryInfoList = new List<VDeliveryInformation>();
        for(Case c : casesToSend) {
            // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
			if(((c.Customer_Type__c == CDdSupportConstants.CUSTOMER_TYPE_CONSUMER
					||c.Customer_Type__c == CDdSupportConstants.CUSTOMER_TYPE_DASHER)
					&& String.isBlank(c.DeliveryUUID__c)
					&& String.isBlank(c.ContactEmail) 
					&& String.isBlank(c.ContactPhone))
					||(!((c.Customer_Type__c == CDdSupportConstants.CUSTOMER_TYPE_CONSUMER 
						|| c.Customer_Type__c == CDdSupportConstants.CUSTOMER_TYPE_DASHER))
						&& String.isBlank(c.DeliveryUUID__c))){
        		noDeliveryNumberList.add(c);
        		continue;
        	}

        	VDispatchDeliveryCallout dispatchCallout = new VDispatchDeliveryCallout(c.DeliveryUUID__c, c.ContactEmail, c.ContactPhone, c.Customer_Type__c, c.Platform__c);
        	
        	try {
        		VDeliveryInformation info = dispatchCallout.makeDeliveryCallout();

				if(info != null) {
					c.DispatchRQAttempts__c = dispatchCallout.retryAttempts;
					c.DispatchRQStatus__c = 'Success';
					c.DispatchCalloutException__c = null;
					c = VDeliveryInformation.populateCustomerSegment(info, c);

					if(String.isNotBlank(dispatchCallout.responseData)) {
						c.DispatchRQResponse__c = dispatchCallout.responseData.left(RESPONSE_FIELD_LENGTH);
					}
	
					info.salesforceCase = c;
	
					if(c.Customer_Type__c == 'Consumer') {
						info.liveAgentCustomerId =  info.customerId;
					} else if(c.Customer_Type__c == 'Dasher') {
						info.liveAgentDasherId = info.dasherId;
					} else if(c.Customer_Type__c == 'Merchant') {
						info.liveAgentMerchantId = info.merchantId;
					}
	
					deliveryInfoList.add(info);
				}
				else {
					throw new CDdException(Label.DispatchBlankSalesforceAudienceInfo);
				}
    		} catch(Exception e) {
    			c.DispatchRQAttempts__c = dispatchCallout.retryAttempts;
        		c.DispatchRQStatus__c = 'Failure';
        		c.DispatchCalloutException__c = e.getMessage();

        		if(String.isNotBlank(dispatchCallout.responseData)) {
        			c.DispatchRQResponse__c = dispatchCallout.responseData.left(RESPONSE_FIELD_LENGTH);
        		}

        		VDispatchRecordService.clearFieldsOnError(c);

        		casesToUpdate.add(c);
    		}
    	}


		if(deliveryInfoList.size() > 0) {
			try {
    			VDispatchRecordService svc = new VDispatchRecordService();
    			svc.upsertDeliveryInfo(deliveryInfoList);


    			// NOTE: Provided for coverage.
    			if(Test.isRunningTest() && throwTestException) {
    				throw new VTestUtil.TestException('test');
    			}
			} catch(Exception e) {
				List<Case> tmp = new List<Case>();
				for(VDeliveryInformation info : deliveryInfoList) {
					info.salesforceCase.DispatchRQStatus__c = 'Failure';
					info.salesforceCase.DispatchCalloutException__c = e.getMessage();

					tmp.add(info.salesforceCase);
				}
				
				update tmp;
			}
		}

		if(casesToUpdate.size() > 0) {
			try {
    			update casesToUpdate;
			} catch(Exception e) {
				if(!trapExceptions) throw e;
			}
		}

		if(noDeliveryNumberList.size() > 0) {
			Set<String> chatKeys = new Set<String>();

			for(Case c : noDeliveryNumberList) {
				if(c.ChatKey__c != null) {
					chatKeys.add(c.ChatKey__c);
				}
			}

			VDispatchRecordService svc = new VDispatchRecordService();
			svc.upsertCasesWithoutDeliveryIds(chatKeys, noDeliveryNumberList);
		}

        Set<ID> caseIds = VObjectUtil.extractIds(casesToSend);
        // BZAP-7609 Update Dispatch Callout about Status Updates
        /*Set<String> validStatuses = new Set<String>{'Solved', 'Open', 'New'};
        //VObjectUtil.extractIds(casesToSend);
        Set<ID> caseIds = new Set<ID>();
        for (Case c : casesToSend){
            // BZAP-7609 Update Dispatch Callout about Status Updates
            if (validStatuses.contains(c.Status)){
                caseIds.add(c.Id);
            }
        }*/
		
        // adding a flag to execute future method ONLY IF makeCaseCallout = true AND 
        // Case_Object_Send_To_Dispatch__c custom setting is enabled. 
        
        if(makeCaseCallout && apiSettings.Case_Object_Send_To_Dispatch__c) {
            VDispatchDeliveryCalloutQueueable.sendCasesToDispatch(caseIds, runCaseAlways);
        }
	}

	@future(callout=true)
	public static void sendCasesToDispatch(Set<ID> caseIds, Boolean runCaseAlways) {
		VDispatchCaseCalloutQueueable q = new VDispatchCaseCalloutQueueable(caseIds, false, runCaseAlways);
		System.enqueueJob(q);
	}
}