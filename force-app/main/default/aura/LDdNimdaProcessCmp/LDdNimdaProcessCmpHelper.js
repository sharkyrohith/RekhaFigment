({
	init : function(component) {
	},
    isOrderProtocolPOS : function(component) {
        var opportunity = component.get("v.opportunity");
        var orderProtocol = opportunity.Order_Protocol__c;
        var isPOS = false;
        var ORDER_PROTOCOL_POINT_OF_SALE = component.get("v.ORDER_PROTOCOL_POINT_OF_SALE");
        var data = component.get("v.ORDER_PROTOCOL_MAP");
        for (var i=0; i<data.length; i++){
            var label = data[i].label;
            var value = data[i].value;
            if ((orderProtocol == label) && (ORDER_PROTOCOL_POINT_OF_SALE == value)){
                isPOS = true;
            }
        }
        return isPOS;        
    },
    getStoreOrderProtocolPosRequest : function(component) {
        return {
            "order_protocol": "POINT_OF_SALE",
            "confirm_protocol": "NO_CONFIRMATION",
            "special_instructions_max_length":  "0"
        };
    },
    getStorePosDetailsRequest : function(component) {
        var opportunity = component.get("v.opportunity");
        return {
            "location_id": opportunity.POS_Integration_ID__c,
            "provider_type":  opportunity.POS_Integration_Type__c
        };
    },    
	handleException : function(component, error, applyUpdates){
        var self = this;
		if (error.message){
			try {
				let errorData = JSON.parse(error.message);
                component.set("v.errorType", errorData.errorType);
                component.set("v.errorMessage", errorData.errorMessage);
                component.set("v.calloutRequest", errorData.calloutRequest);
                component.set("v.calloutResponse", errorData.calloutResponse);
			} catch(e) {
                component.set("v.errorType", component.get("v.ERROR_TYPE_FATAL"));
                component.set("v.errorMessage", error.message);
			}
		}
        if (applyUpdates){
            self.applyUpdates(component
                , function(result) {
                    console.log('Applied updates successfully');                     
                }
                , function(error) {
                    console.log('Failure in applying updates ' + error.message); 
                }                
            );
        }
        // fire nimda sync event
        self.fireNimdaSyncEvent(component, component.get("v.currentStep"), null);        
	},
    clearErrors : function(component) {
        component.set("v.errorType", "");
        component.set("v.errorMessage", "");
        component.set("v.calloutRequest", "");
        component.set("v.calloutResponse", "");
    },
    getNextStep : function(component) {
        var account = component.get("v.account");
        var opportunity = component.get("v.opportunity");
        var paymentAcctId = component.get("v.paymentAcctId");
        var stripeAcctId = component.get("v.stripeAcctId");
        var stripeBankAcctId = component.get("v.stripeBankAcctId");
        // if store id is empty return STEP_CREATE_STORE
        if ($A.util.isEmpty(opportunity.Store_ID__c) && $A.util.isEmpty(component.get("v.storeId"))){
            return component.get("v.STEP_CREATE_STORE");
        }
        // if Portal User Id is empty return STEP_CREATE_USER
        // Note - Create User and Create Merchant need to execute if the Portal User Name is empty
        if ($A.util.isEmpty(account.Portal_User_Id__c)){
            // if current step is STEP_CREATE_USER then return the next step STEP_CREATE_MERCHANT
            return (component.get("v.currentStep") === component.get("v.STEP_CREATE_USER"))
                    ?   component.get("v.STEP_CREATE_MERCHANT")
                    :   component.get("v.STEP_CREATE_USER");
        }
        // if Stripe Account is empty return STEP_PAYMENT_ACCOUNT
        if ($A.util.isEmpty(opportunity.Stripe_Account__c) && $A.util.isEmpty(stripeAcctId)){
            return component.get("v.STEP_PAYMENT_ACCOUNT");
        }
        // if Stripe Bank Account is empty return STEP_STRIPE_BANK_TOKEN
        // Note - Stripe Bank Token and Stripe Bank Account need to execute if the Stripe Bank Account is empty
        if ($A.util.isEmpty(opportunity.Stripe_Bank_Account__c) && $A.util.isEmpty(stripeBankAcctId)){
            // if current step is STEP_STRIPE_BANK_TOKEN then return the next step STEP_STRIPE_BANK_ACCOUNT
            return (component.get("v.currentStep") === component.get("v.STEP_STRIPE_BANK_TOKEN"))
                    ?   component.get("v.STEP_STRIPE_BANK_ACCOUNT")
                    :   component.get("v.STEP_STRIPE_BANK_TOKEN");            
        }
        // if store update request data is available, post updates to the store prior to completion
        if (!$A.util.isEmpty(component.get("v.storeUpdateRequest"))){
            return component.get("v.STEP_UPDATE_STORE");
        }                         
        return component.get("v.STEP_COMPLETE");
    },
    getNextStepInOrder : function(component) {
        var steps = component.get("v.steps");
        var currentStepIndex = -1;
        for (var i = 0; i < steps.length; i++){
            if (steps[i].value === component.get("v.currentStep")){
                currentStepIndex = i;
            }
        }
        return ( (currentStepIndex > -1)
                    ?  (    (currentStepIndex < (steps.length - 1))
                            ?   steps[currentStepIndex + 1].value
                            :   steps[steps.length - 1].value
                        )
                    :  steps[steps.length - 1].value 
                );
    },
    fireNimdaSyncEvent: function(component, step, value) {
        var nimdaSyncEvent = component.getEvent("LDdNimdaSyncEvent");
        nimdaSyncEvent.setParams({
            step: step
            , value: value
        });
        nimdaSyncEvent.fire();
    },      
	createStore : function(component, success, failure) {
		var self = this;
        var calloutCmp = component.find("calloutCmp");
        if (calloutCmp){
            calloutCmp.callout( 
                    component
                    , 'createStore'
                    , { businessId : component.get("v.businessId")
                    	, account : component.get("v.account")
                    	, opportunity : component.get("v.opportunity")
                    }
            		, function(result) {
            			if (success) {
        					success.call(self, result);
        				}
        			}
        			, function(error){
            			if (failure) {
        					failure.call(self, error);
        				}        				
       				}
                );
        } 		
	},
	createUser : function(component, success, failure) {
		var self = this;
        var calloutCmp = component.find("calloutCmp");
        if (calloutCmp){
            calloutCmp.callout( 
                    component
                    , 'createUser'
                    , { businessId : component.get("v.businessId")
                    	, storeId : component.get("v.storeId")
                    	, account : component.get("v.account")
                    	, opportunity : component.get("v.opportunity")
                    }
            		, function(result) {
            			if (success) {
        					success.call(self, result);
        				}
        			}
        			, function(error){
            			if (failure) {
        					failure.call(self, error);
        				}        				
       				}
                );
        } 		
	},
	createMerchant : function(component, success, failure) {
		var self = this;
        var calloutCmp = component.find("calloutCmp");
        if (calloutCmp){
            calloutCmp.callout( 
                    component
                    , 'createMerchant'
                    , { businessId : component.get("v.businessId")
                    	, storeId : component.get("v.storeId")
                    	, userId : component.get("v.userId")
                    	, account : component.get("v.account")
                    	, opportunity : component.get("v.opportunity")
                    }
            		, function(result) {
            			if (success) {
        					success.call(self, result);
        				}
        			}
        			, function(error){
            			if (failure) {
        					failure.call(self, error);
        				}        				
       				}
                );
        } 		
	},
	createPaymentAccount : function(component, success, failure) {
		var self = this;
        var calloutCmp = component.find("calloutCmp");
        if (calloutCmp){
            calloutCmp.callout( 
                    component
                    , 'createPaymentAccount'
                    , { businessId : component.get("v.businessId")
                    	, storeId : component.get("v.storeId")
                    	, account : component.get("v.account")
                    	, opportunity : component.get("v.opportunity")
                    }
            		, function(result) {
            			if (success) {
        					success.call(self, result);
        				}
        			}
        			, function(error){
            			if (failure) {
        					failure.call(self, error);
        				}        				
       				}
                );
        } 		
	},
	createStripeBankToken : function(component, success, failure) {
		var self = this;
        var calloutCmp = component.find("calloutCmp");
        if (calloutCmp){
            calloutCmp.callout( 
                    component
                    , 'createStripeBankToken'
                    , { businessId : component.get("v.businessId")
                    	, account : component.get("v.account")
                    	, opportunity : component.get("v.opportunity")
                    }
            		, function(result) {
            			if (success) {
        					success.call(self, result);
        				}
        			}
        			, function(error){
            			if (failure) {
        					failure.call(self, error);
        				}        				
       				}
                );
        } 		
	},
	createDSJBankAccount : function(component, success, failure) {
		var self = this;
        var calloutCmp = component.find("calloutCmp");
        if (calloutCmp){
            calloutCmp.callout( 
                    component
                    , 'createDSJBankAccount'
                    , { businessId : component.get("v.businessId")
                    	, paymentAcctId : component.get("v.paymentAcctId")
                    	, bankTokenId : component.get("v.bankTokenId")
                    	, account : component.get("v.account")
                    	, opportunity : component.get("v.opportunity")
                    }
            		, function(result) {
            			if (success) {
        					success.call(self, result);
        				}
        			}
        			, function(error){
            			if (failure) {
        					failure.call(self, error);
        				}        				
       				}
                );
        } 		
	},
    applyUpdates : function(component, success, failure) {
        var self = this;
        var exceptionData = {};
        exceptionData.step = component.get("v.currentStep");
        if (!$A.util.isEmpty(component.get("v.errorType"))){
            exceptionData.errorType = component.get("v.errorType");
        }
        if (!$A.util.isEmpty(component.get("v.errorMessage"))){
            exceptionData.errorMessage = component.get("v.errorMessage");
        }
        if (!$A.util.isEmpty(component.get("v.calloutRequest"))){
            exceptionData.calloutRequest = component.get("v.calloutRequest");
        }
        if (!$A.util.isEmpty(component.get("v.calloutResponse"))){
            exceptionData.calloutResponse = component.get("v.calloutResponse");
        }
        var calloutCmp = component.find("calloutCmp");
        if (calloutCmp){
            calloutCmp.callout( 
                    component
                    , 'applyUpdates'
                    , { businessId : component.get("v.businessId")
                        , storeId : component.get("v.storeId")
                        , userId : component.get("v.userId")
                        , paymentAcctId : component.get("v.paymentAcctId")
                        , stripeAcctId : component.get("v.stripeAcctId")
                        , stripeBankAcctId : component.get("v.stripeBankAcctId")
                        , account : component.get("v.account")
                        , opportunity : component.get("v.opportunity")
                        , exceptionDataStr : JSON.stringify(exceptionData)
                    }
                    , function(result) {
                        if (success) {
                            success.call(self, result);
                        }
                    }
                    , function(error){
                        if (failure) {
                            failure.call(self, error);
                        }                       
                    }
                );
        }       
    },
    updateStore : function(component, storeRequest, success, failure) {
        var self = this;
        var calloutCmp = component.find("calloutCmp");
        if (calloutCmp){
            calloutCmp.callout( 
                component
                , 'updateStore'
                , { storeId : component.get("v.storeId")
                    , storeRequest : storeRequest
                }
                , function(result) {
                    if (success) {
                        success.call(self, result);
                    }                    
                }
                , function(error){
                    if (failure) {
                        failure.call(self, error);
                    }                       
                }
            );
        }       
    },
    updateStorePOS : function(component, storeRequest, success, failure) {
        var self = this;
        var calloutCmp = component.find("calloutCmp");
        if (calloutCmp){
            calloutCmp.callout( 
                component
                , 'updateStorePOS'
                , { storeId : component.get("v.storeId")
                    , storeRequest : storeRequest
                }
                , function(result) {
                    if (success) {
                        success.call(self, result);
                    }                    
                }
                , function(error){
                    if (failure) {
                        failure.call(self, error);
                    }                       
                }
            );
        }       
    },    
    insertNimdaHistoryRecords : function(component, nimdaHistoryData, success, failure) {
        var self = this;
        var calloutCmp = component.find("calloutCmp");
        if (calloutCmp){
            calloutCmp.callout( 
                component
                , 'insertNimdaHistoryRecords'
                , { nimdaHistoryRecordsJsonStr : JSON.stringify(nimdaHistoryData) }
                , function(result) {
                    if (success) {
                        success.call(self, result);
                    }                    
                }
                , function(error){
                    if (failure) {
                        failure.call(self, error);
                    }                       
                }
            );
        }       
    },         				
})