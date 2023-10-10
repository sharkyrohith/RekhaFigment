({
    init : function(component) {
        var self = this;
        self.updateNimdaSyncStatus(component
            , function(result){
                self.showInfoDialog(component, true, component.get("v.INFO_MESSAGE_PROCESSING"));
                self.fullOnboard(component
                    , function(result){
                        let pollingTimeout = component.get("v.NIMDA_SYNC_POLLING_TIMEOUT");
                        console.log('LDdNimdaProcessCmpv45: Polling timeout = ' + pollingTimeout);
                        window.setTimeout(
                            $A.getCallback(function() {
                                if ($A.util.getBooleanValue(component.get("v.isLoading"))){
                                    self.handlePolledResult(component
                                        , function(result) {
                                            if ($A.util.getBooleanValue(self.showPayment(component, component.get("v.polledStep")))){
                                                component.set("v.showPaymentV3", true);
                                            }
                                        }
                                    );
                                }                                
                            }), pollingTimeout
                        );                        
                    }
                    , function(error) {
                        self.handleException(component, error);
                        self.showInfoDialog(component, false, null);
                    }                    
                );
            }
            , function(error) {
                self.handleException(component, error);
                self.showInfoDialog(component, false, null); 
            }            
        );        
    },
    toggleSTNv4Section : function(component) {
        var stnV4Section = component.find('stnV4Section');
        $A.util.toggleClass(stnV4Section,'slds-is-open');
    },
    toggleSTNv3Section : function(component) {
        var stnV3Section = component.find('stnV3Section');
        $A.util.toggleClass(stnV3Section,'slds-is-open');
    },
    showPayment : function(component, polledStep){
        let showPaymentSteps = [component.get("v.FULL_ONBOARDING_CREATE"),component.get("v.FULL_ONBOARDING_UPDATE"),component.get("v.STEP_PAYMENT_ACCOUNT"),component.get("v.STEP_STRIPE_BANK_TOKEN"),component.get("v.STEP_STRIPE_BANK_ACCOUNT"),component.get("v.STEP_FINISHED")];
        return showPaymentSteps.indexOf(polledStep) > -1;
    },
    showInfoDialog : function(component, show, infoMessage){
        component.set("v.infoMessage", (!$A.util.isEmpty(infoMessage) ? infoMessage : ''));
        component.set("v.isLoading", show);       
    },    
	handleException : function(component, error){
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
	},    
    handlePolledResult : function(component, success, failure){
        var self = this;
        self.getNimdaSyncStatus(component
            , function(result) {
                let opportunity = result;
                let fullOnboardingSteps = [component.get("v.FULL_ONBOARDING_CREATE"),component.get("v.FULL_ONBOARDING_UPDATE")];
                if (fullOnboardingSteps.indexOf(opportunity.Nimda_Sync_Step__c) > -1){
                    component.set("v.errorType", null);
                    component.set("v.errorMessage", component.get("v.ERROR_POLLING_TIMEOUT_MESSAGE_V3_RETRY"));
                    component.set("v.polledStep", opportunity.Nimda_Sync_Step__c);
                } else {
                    component.set("v.errorType", null);
                    component.set("v.errorMessage", null);                
                    component.set("v.polledStep", opportunity.Nimda_Sync_Step__c);
                    component.set("v.polledErrorType", opportunity.Nimda_Sync_Error_Type__c);
                    component.set("v.polledErrorMessage", opportunity.Nimda_Sync_Error_Message__c);
                    component.set("v.polledCalloutRequest", opportunity.Nimda_Sync_Callout_Request__c);
                    component.set("v.polledCalloutResponse", opportunity.Nimda_Sync_Callout_Response__c);            
                }
                component.set("v.isLoading", false);                 
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
    },
    fullOnboard : function(component, success, failure) {
        var self = this;
        var calloutCmp = component.find("calloutCmp");
        if (calloutCmp){
            calloutCmp.callout( 
                component
                , 'fullOnboard'
                , { opportunityId : component.get("v.recordId")
                    , originatingOnboardingStep : component.get("v.originatingOnboardingStep")
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
    getNimdaSyncStatus : function(component, success, failure) {
        var self = this;
        var calloutCmp = component.find("calloutCmp");
        if (calloutCmp){
            calloutCmp.callout( 
                component
                , 'getNimdaSyncStatus'
                , { opportunityId : component.get("v.recordId") }
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
    updateNimdaSyncStatus : function(component, success, failure) {
        var self = this;
        var calloutCmp = component.find("calloutCmp");
        if (calloutCmp){
            calloutCmp.callout( 
                component
                , 'updateNimdaSyncStatus'
                , { step : component.get("v.fullOnboardingAction"), opportunityId : component.get("v.recordId") }
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