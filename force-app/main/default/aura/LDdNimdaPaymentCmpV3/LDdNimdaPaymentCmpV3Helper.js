({
	init : function(component, success, failure) {
        var self = this;
        // Get Opportunity
        self.getOpportunity(component
            , function(result) {
                component.set("v.opportunity", result);
                component.set("v.accountId", result.AccountId);
                if (!$A.util.isEmpty(result.Store_ID__c)){
                    component.set("v.storeId", String(result.Store_ID__c));
                    // Get Account
                    self.getAccount(component
                        , function(result) {
                            component.set("v.account", result);
                            // Get store from Nimda
                            self.getStore(component
                                , function(result) {
                                    try {
                                        // Parse data and retrieve relevant attributes
                                        let data = JSON.parse(result);
                                        // Extract Business Id
                                        if (!$A.util.isEmpty(data['business'])){
                                            let businessId = data['business'].id;
                                            component.set("v.businessId", businessId);
                                        }
                                        // Extract Payment Account Id
                                        if (!$A.util.isEmpty(data['payment_account_id'])){
                                            let paymentAcctId = data['payment_account_id'];
                                            component.set("v.paymentAcctId", paymentAcctId);
                                            // Get payment account from Nimda
                                            self.getPaymentAccount(component
                                                , paymentAcctId
                                                , function(result) {
                                                    try {
                                                        // Parse data and retrieve relevant attributes
                                                        let data = JSON.parse(result);
                                                        if (!$A.util.isEmpty(data.stripe_account_id)){
                                                            component.set("v.stripeAcctId", String(data.stripe_account_id));
                                                        }
                                                        self.setExternalAccountData(component, data);
                                                        if (success) {
                                                            success.call(self, result);
                                                        }                                    
                                                    } catch(e) {
                                                        component.set("v.errorType", component.get("v.ERROR_TYPE_FATAL"));
                                                        component.set("v.errorMessage", component.get("v.ERROR_INVALID_DATA"));
                                                        if (failure) {
                                                            failure.call(self, e);
                                                        }                                                
                                                    }
                                                }
                                                , function(error) {
                                                    self.handleException(component, error);
                                                    if (failure) {
                                                        failure.call(self, error);
                                                    }                                
                                                }
                                            );
                                        } else { // if payment_account_id is null on the store
                                            if (success) {
                                                success.call(self, result);
                                            }                                         
                                        }
                                    } catch(e) {
                                        component.set("v.errorType", component.get("v.ERROR_TYPE_FATAL"));
                                        component.set("v.errorMessage", component.get("v.ERROR_INVALID_DATA"));
                                        if (failure) {
                                            failure.call(self, e);
                                        }                    
                                    }
                                }                 
                                , function(error) {
                                    self.handleException(component, error);
                                    if (failure) {
                                        failure.call(self, error);
                                    }                
                                }
                            );                                
                        }
                        , function(error) {
                            self.handleException(component, error);
                            if (failure) {
                                failure.call(self, error);
                            }
                        }
                    );
                } else {
                    component.set("v.errorType", component.get("v.ERROR_TYPE_VALIDATION"));
                    component.set("v.errorMessage", component.get("v.ERROR_STORE_ID_NOT_FOUND"));
                    if (failure) {
                        failure.call(self, null);
                    }                    
                }
            }
            , function(error) {
                self.handleException(component, error);
                if (failure) {
                    failure.call(self, error);
                }
            }
        );        
    },
    setExternalAccountData : function(component, data){
        if (data.stripe_account && data.stripe_account.external_account){
            if (!$A.util.isEmpty(data.stripe_account.external_account.fingerprint)){
                component.set("v.stripeBankAcctId", String(data.stripe_account.external_account.fingerprint));
            }
            if (!$A.util.isEmpty(data.stripe_account.external_account.routing_number)){
                component.set("v.routingNumber", String(data.stripe_account.external_account.routing_number));
            }
            if (!$A.util.isEmpty(data.stripe_account.external_account.bank_name)){
                component.set("v.bankName", String(data.stripe_account.external_account.bank_name));
            }                                                                                                                
        }
    },
    setComparisonResults : function(component){
        var self = this;
        let account = component.get("v.account");
        let opportunity = component.get("v.opportunity");
        let mxPortalLink = component.get("v.MX_PORTAL_LINK").replace("%storeId%", component.get("v.storeId"));
        let storeMsg = component.get("v.S2N_V3_PAYMENT_MSG_SUCCESS_STORE").replace("{0}", component.get("v.storeId"));
        let results = [];
        // success Store message
        results.push({message: storeMsg, status: 'success'});
        if (component.get("v.STEP_FINISHED") !== component.get("v.v4NimdaStep")){
            // warning User message
            results.push({message: component.get("v.S2N_V3_PAYMENT_MSG_CHECK_USER") + mxPortalLink, status: 'warning'});
            // warning tablet message
            results.push({message: component.get("v.S2N_V3_PAYMENT_MSG_CHECK_TABLET_CREDENTIAL") + mxPortalLink, status: 'warning'});
        }
        // check for payment account
        results.push(self.getComparisonResult(component
            ,   'Payment Account'
            ,   'Account'
            ,   account.Payment_Account_ID__c
            ,   component.get("v.paymentAcctId")      
        ));
        // check for stripe account
        results.push(self.getComparisonResult(component
            ,   'Stripe Account'
            ,   'Opportunity'
            ,   opportunity.Stripe_Account__c
            ,   component.get("v.stripeAcctId")      
        ));
        // check for stripe bank account                
        results.push(self.getComparisonResult(component
            ,   'Stripe Bank Account'
            ,   'Opportunity'
            ,   opportunity.Stripe_Bank_Account__c
            ,   component.get("v.stripeBankAcctId")      
        ));
        // Compare routing number only if the external bank account is already setup
        if (!$A.util.isEmpty(component.get("v.stripeBankAcctId"))){
            results.push(self.getComparisonResult(component
                ,   'External Account Routing Number'
                ,   'Account'
                ,   account.Bank_Routing_Number_Encrypted__c
                ,   component.get("v.routingNumber")
                ,   true      
            ));
        }        
        component.set("v.comparisonResults", results);        
    },
    getComparisonResult : function(component, label, sObjectType, salesforceValue, nimdaValue, encrypt){
        let result = {label: label, salesforceValue: salesforceValue, nimdaValue: nimdaValue};
        let message = '';
        let status = 'error';
        if (!$A.util.isEmpty(nimdaValue)){
            let nValue = encrypt ? nimdaValue.replace(/\w/g, 'X') : nimdaValue;
            if ($A.util.isEmpty(salesforceValue)){
                message = label + ' ' + nValue + ' not found on the ' + sObjectType;
            } else {
                let sValue = encrypt ? salesforceValue.replace(/\w/g, 'X') : salesforceValue;
                if (nimdaValue == salesforceValue){
                    message = label + ' ' + nValue + ' matches with value on ' + sObjectType;
                    status = 'success';
                } else {
                    message = label + ' ' + nValue  + ' in Nimda does not match with ' + label + ' ' + sValue + ' on ' +  sObjectType;
                }
            }
        } else {
            message = label + ' is currently not setup';
        }
        result.message = message;
        result.status = status;
        return result;        
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
	},
    clearErrors : function(component) {
        component.set("v.errorType", "");
        component.set("v.errorMessage", "");
        component.set("v.calloutRequest", "");
        component.set("v.calloutResponse", "");
    },
    getNextStep : function(component) {
        var stripeAcctId = component.get("v.stripeAcctId");
        var stripeBankAcctId = component.get("v.stripeBankAcctId");
        // if Stripe Account is empty return STEP_PAYMENT_ACCOUNT
        if ($A.util.isEmpty(stripeAcctId)){
            return component.get("v.STEP_PAYMENT_ACCOUNT");
        }
        // if Stripe Bank Account is empty return STEP_STRIPE_BANK_TOKEN
        // Note - Stripe Bank Token and Stripe Bank Account need to execute if the Stripe Bank Account is empty
        if ($A.util.isEmpty(stripeBankAcctId)){
            // if current step is STEP_STRIPE_BANK_TOKEN then return the next step STEP_STRIPE_BANK_ACCOUNT
            return (component.get("v.currentStep") === component.get("v.STEP_STRIPE_BANK_TOKEN"))
                    ?   component.get("v.STEP_STRIPE_BANK_ACCOUNT")
                    :   component.get("v.STEP_STRIPE_BANK_TOKEN");            
        }
        return component.get("v.STEP_COMPLETE");
    },
    getNextStepInOrder : function(component) {
        var steps = component.get("v.paymentSteps");
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
    getOpportunity : function(component, success, failure) {
        var self = this;
        var calloutCmp = component.find("calloutCmp");
        if (calloutCmp){
            calloutCmp.callout( 
                    component
                    , 'getOpportunity'
                    , {opportunityId : component.get("v.recordId")}
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
    getAccount : function(component, success, failure) {
        var self = this;
        var calloutCmp = component.find("calloutCmp");
        if (calloutCmp){
            calloutCmp.callout( 
                    component
                    , 'getAccount'
                    , {accountId : component.get("v.accountId")}
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
    getStore : function(component, success, failure) {
        var self = this;
        var calloutCmp = component.find("calloutCmp");
        if (calloutCmp){
            calloutCmp.callout( 
                component
                , 'getStore'
                , { storeId : component.get("v.storeId") }
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
    getPaymentAccount : function(component, paymentAccountId, success, failure) {
        var self = this;
        var calloutCmp = component.find("calloutCmp");
        if (calloutCmp){
            calloutCmp.callout( 
                component
                , 'getPaymentAccount'
                , { paymentAccountId : paymentAccountId }
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
                    , 'applyPaymentV3Updates'
                    , { paymentAcctId : component.get("v.paymentAcctId")
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
})