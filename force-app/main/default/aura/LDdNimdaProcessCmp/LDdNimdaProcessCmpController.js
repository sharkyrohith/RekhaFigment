({
    init: function(component, event, helper) {
        var account = component.get("v.account");
        var opportunity = component.get("v.opportunity");
        if (!$A.util.isEmpty(account.Payment_Account_ID__c)){
            component.set("v.paymentAcctId", account.Payment_Account_ID__c);
        }        
        if (!$A.util.isEmpty(opportunity.Stripe_Account__c)){
            component.set("v.stripeAcctId", opportunity.Stripe_Account__c);
        }
        if (!$A.util.isEmpty(opportunity.Stripe_Bank_Account__c)){
            component.set("v.stripeBankAcctId", opportunity.Stripe_Bank_Account__c);
        }                
    },
    handleProcessNextStep: function(component, event, helper) {
        var input = event.getParam('arguments');
        if (input && input.params) {
            if (!$A.util.isEmpty(input.params.paymentAcctId)){
                component.set("v.paymentAcctId", input.params.paymentAcctId);
            }
            if (!$A.util.isEmpty(input.params.stripeAcctId)){
                component.set("v.stripeAcctId", input.params.stripeAcctId);
            }
            if (!$A.util.isEmpty(input.params.stripeBankAcctId)){
                component.set("v.stripeBankAcctId", input.params.stripeBankAcctId);
            }            
            component.set("v.storeUpdateRequest", input.params.storeUpdateRequest);
            component.set("v.nimdaHistoryData", input.params.nimdaHistoryData);
            if (!$A.util.isEmpty(component.get("v.storeUpdateRequest"))){ 
                var steps = component.get("v.steps");
                var addStep = component.get("v.STEP_UPDATE_STORE");
                steps.splice(steps.length - 1, 0, { label: addStep, value: addStep });
                component.set("v.steps", steps);
            }            
        }
    	component.set("v.currentStep", helper.getNextStep(component));
    },       
    handleStepChange: function(component, event, helper) {
    	helper.clearErrors(component);
    	var currentStep = component.get("v.currentStep");
    	switch (currentStep) {
    		case component.get("v.STEP_CREATE_STORE"): 
				helper.createStore(component
	        		, function(result) {
	        			try {
	        				// Parse data and retrieve relevant attributes
		        			let data = JSON.parse(result);
		        			let response = JSON.parse(data.calloutResponse);
		        			component.set("v.storeId", String(response.successes.id));
                            if (helper.isOrderProtocolPOS(component)){
                                // PUT Store Point of Sale Info 
                                helper.updateStorePOS(component
                                    , JSON.stringify(helper.getStorePosDetailsRequest(component))
                                    , function(result) {
                                        // Update Store Order Protocol to POS
                                        helper.updateStore(component
                                            , JSON.stringify(helper.getStoreOrderProtocolPosRequest(component))
                                            , function(result) {
                                                // Move to next step
                                                component.set("v.currentStep", helper.getNextStepInOrder(component));                                                
                                            }
                                            , function(error) {
                                                helper.handleException(component, error, true);
                                            }
                                        );
                                    }
                                    , function(error) {
                                        helper.handleException(component, error, true);
                                    }
                                );
                            } else {
		        			   // Move to next step
		        			   component.set("v.currentStep", helper.getNextStepInOrder(component));
                            }
						} catch(e) {
			                component.set("v.errorType", component.get("v.ERROR_TYPE_FATAL"));
			                component.set("v.errorMessage", component.get("v.ERROR_INVALID_DATA"));
						}
	        		}
		        	, function(error) {
		        		helper.handleException(component, error, true);
		        	}
		        );    		 
    			break;
    		case component.get("v.STEP_CREATE_USER"): 
				helper.createUser(component
	        		, function(result) {
	        			try {
	        				// Parse data and retrieve relevant attributes
		        			let data = JSON.parse(result);
		        			let response = JSON.parse(data.calloutResponse);
		        			component.set("v.userId", String(response.user.id));
		        			// Move to next step
		        			component.set("v.currentStep", helper.getNextStepInOrder(component));		        			
						} catch(e) {
			                component.set("v.errorType", component.get("v.ERROR_TYPE_FATAL"));
			                component.set("v.errorMessage", component.get("v.ERROR_INVALID_DATA"));
						}		        		
		        	}
		        	, function(error) {
		        		helper.handleException(component, error, true);
		        	}
		        );    		 
    			break;
    		case component.get("v.STEP_CREATE_MERCHANT"): 
				helper.createMerchant(component
	        		, function(result) {
	        			try {
	        				// Parse data and retrieve relevant attributes
		        			// Move to next step
		        			component.set("v.currentStep", helper.getNextStepInOrder(component));		        			
						} catch(e) {
			                component.set("v.errorType", component.get("v.ERROR_TYPE_FATAL"));
			                component.set("v.errorMessage", component.get("v.ERROR_INVALID_DATA"));
						}		        		
		        	}
		        	, function(error) {
		        		helper.handleException(component, error, true);
		        	}
		        );    		 
    			break;
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
		        			component.set("v.stripeBankAcctId", String(response.stripe_account.external_account.fingerprint));
		        			// Move to next step
		        			component.set("v.currentStep", helper.getNextStepInOrder(component));		        			
						} catch(e) {
			                component.set("v.errorType", component.get("v.ERROR_TYPE_FATAL"));
			                component.set("v.errorMessage", component.get("v.ERROR_INVALID_DATA"));
						}		        		
		        	}
		        	, function(error) {
		        		helper.handleException(component, error, true);
		        	}
		        );    		 
    			break;
            case component.get("v.STEP_UPDATE_STORE"):
                if (!$A.util.isEmpty(component.get("v.storeUpdateRequest"))){ 
                    helper.updateStore(component
                        , JSON.stringify(component.get("v.storeUpdateRequest"))
                        , function(result) {
                            helper.insertNimdaHistoryRecords(component
                                , component.get("v.nimdaHistoryData")
                                , function(result) {
                                    // Move to next step
                                    component.set("v.currentStep", helper.getNextStepInOrder(component));                                
                                }
                                , function(error) {
                                    helper.handleException(component, error, true);
                                }                            
                            );
                        }
                        , function(error) {
                            helper.handleException(component, error, true);
                        }
                    );
                } else {
                    // Move to next step
                    component.set("v.currentStep", helper.getNextStepInOrder(component));                    
                }
                break;                
    		case component.get("v.STEP_COMPLETE"):
		        helper.applyUpdates(component
		            , function(result) {
		                console.log('Applied updates successfully');                     
		            }
		            , function(error) {
		                console.log('Failure in applying updates ' + error.message); 
		            }                
		        );
		        // fire nimda sync event
		        helper.fireNimdaSyncEvent(component, component.get("v.STEP_COMPLETE"), null);		            		 
    			break;
    		default:
    			break;
    	}
    },
})