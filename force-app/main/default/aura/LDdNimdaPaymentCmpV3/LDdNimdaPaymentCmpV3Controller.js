({
    init: function(component, event, helper) {
		helper.init(component
            , function(result) {
				component.set("v.currentStep", helper.getNextStep(component));
				component.set("v.isLoading", false);				
			}
            , function(error) {
				component.set("v.isLoading", false);				
            }						
		);		
	},
    handleStepChange: function(component, event, helper) {
    	helper.clearErrors(component);
    	var currentStep = component.get("v.currentStep");
    	switch (currentStep) {
    		case component.get("v.STEP_PAYMENT_ACCOUNT"): 
				helper.createPaymentAccount(component
	        		, function(result) {
	        			try {
	        				// Parse data and retrieve relevant attributes
		        			let data = JSON.parse(result);
		        			let response = JSON.parse(data.calloutResponse);
                            component.set("v.paymentAcctId", String(response.id));
		        			component.set("v.stripeAcctId", String(response.stripe_account_id));
		        			// Move to next step
		        			component.set("v.currentStep", helper.getNextStepInOrder(component));		        			
						} catch(e) {
			                component.set("v.errorType", component.get("v.ERROR_TYPE_FATAL"));
			                component.set("v.errorMessage", component.get("v.ERROR_INVALID_DATA"));
						}		        		
		        	}
		        	, function(error) {
						helper.setComparisonResults(component);
		        		helper.handleException(component, error, true);
		        	}
		        );    		 
    			break;
    		case component.get("v.STEP_STRIPE_BANK_TOKEN"):
				helper.createStripeBankToken(component
	        		, function(result) {
	        			try {
	        				// Parse data and retrieve relevant attributes
		        			let data = JSON.parse(result);
		        			let response = JSON.parse(data.calloutResponse);
		        			component.set("v.bankTokenId", String(response.id));
		        			// Move to next step
		        			component.set("v.currentStep", helper.getNextStepInOrder(component));		        			
						} catch(e) {
			                component.set("v.errorType", component.get("v.ERROR_TYPE_FATAL"));
			                component.set("v.errorMessage", component.get("v.ERROR_INVALID_DATA"));
						}	        		
		        	}
		        	, function(error) {
						helper.setComparisonResults(component);
		        		helper.handleException(component, error, true);
		        	}
		        );    		 
    			break;
    		case component.get("v.STEP_STRIPE_BANK_ACCOUNT"): 
				helper.createDSJBankAccount(component
	        		, function(result) {
	        			try {
	        				// Parse data and retrieve relevant attributes
		        			let data = JSON.parse(result);
							let response = JSON.parse(data.calloutResponse);
							helper.setExternalAccountData(component, response);
		        			// Move to next step
		        			component.set("v.currentStep", helper.getNextStepInOrder(component));		        			
						} catch(e) {
			                component.set("v.errorType", component.get("v.ERROR_TYPE_FATAL"));
			                component.set("v.errorMessage", component.get("v.ERROR_INVALID_DATA"));
						}		        		
		        	}
		        	, function(error) {
						helper.setComparisonResults(component);
		        		helper.handleException(component, error, true);
		        	}
		        );    		 
    			break;
    		case component.get("v.STEP_COMPLETE"):
				helper.setComparisonResults(component);
		        helper.applyUpdates(component
		            , function(result) {
		                console.log('Applied updates successfully');                     
		            }
		            , function(error) {
		                console.log('Failure in applying updates ' + error.message); 
		            }                
		        );
    			break;
    		default:
    			break;
    	}
    },
})