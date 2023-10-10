({
    init : function(component) {
        var self = this;
        // Get Opportunity
        self.getOpportunity(component
            , function(result) {
                component.set("v.opportunity", result);
                component.set("v.accountId", result.AccountId);
                if (!$A.util.isEmpty(result.Store_ID__c)){
                    component.set("v.storeId", String(result.Store_ID__c));
                }              
                // Get Account
                self.getAccount(component
                    , function(result) {
                        component.set("v.account", result);
                        self.setBusinessId(component);
                        component.set("v.currentStep", self.getNextStep(component));
                        component.set("v.isLoading", false);
                    }
                    , function(error) {
                        self.handleException(component, error, false);
                        component.set("v.isLoading", false);
                    }
                );
            }
            , function(error) {
                self.handleException(component, error, false);
                component.set("v.isLoading", false);
            }
        );      
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
    },
    clearErrors : function(component) {
        component.set("v.errorType", "");
        component.set("v.errorMessage", "");
        component.set("v.calloutRequest", "");
        component.set("v.calloutResponse", "");
    },
    setBusinessId : function(component) {
        var account = component.get("v.account");
        if (!$A.util.isEmpty(account.Business_ID__c)) {
            component.set("v.businessId", account.Business_ID__c);
        } else if (!$A.util.isEmpty(account.Parent) && !$A.util.isEmpty(account.Parent.Business_ID__c)){
            component.set("v.businessId", account.Parent.Business_ID__c);
        }
    },
    setOriginatingOnboardingStep : function(component, step) {
        switch (step) {
            case component.get("v.FULL_ONBOARDING_CREATE"):
            case component.get("v.CHANGE_OF_OWNERSHIP_CREATE"):
                component.set("v.originatingOnboardingStep", component.get("v.STEP_CREATE_STORE"));
                break;
            case component.get("v.FULL_ONBOARDING_UPDATE"):
            case component.get("v.CHANGE_OF_OWNERSHIP_UPDATE"):
                break;                                 
            case component.get("v.STEP_UPDATE_STORE"):
                component.set("v.originatingOnboardingStep", component.get("v.STEP_UPDATE_STORE"));
                break;
            case component.get("v.STEP_PRODUCT_AND_PRICING_ONBOARDING"):
                component.set("v.originatingOnboardingStep", component.get("v.STEP_PRODUCT_AND_PRICING_ONBOARDING"));
                break;
            case component.get("v.STEP_FEE_ONBOARDING"):
                component.set("v.originatingOnboardingStep", component.get("v.STEP_FEE_ONBOARDING"));
                break;                                                
            default:
                component.set("v.originatingOnboardingStep", null);
                break;
        }
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
    hasPermission : function(component, customPermissionApiName, success, failure) {
        var self = this;
        var calloutCmp = component.find("calloutCmp");
        if (calloutCmp){
            calloutCmp.callout( 
                    component
                    , 'hasPermission'
                    , {customPermission : customPermissionApiName}
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
    getNextStep : function(component) {
        component.set("v.previousStep", component.get("v.currentStep"));
        if ($A.util.isEmpty(component.get("v.currentStep"))){
            return component.get("v.STEP_INITIALIZE"); 
        } else {
            if (component.get("v.currentStep") === component.get("v.STEP_SEARCH_STORE")){
                return component.get("v.STEP_UPDATE_STORE");
            }
        }        
        return component.get("v.STEP_COMPLETE");        
    },
    getPreviousStep : function(component) {
        if (component.get("v.currentStep") === component.get("v.STEP_SEARCH_STORE")){
            return component.get("v.STEP_INITIALIZE");
        }
        if (component.get("v.currentStep") === component.get("v.STEP_UPDATE_STORE")){
            return component.get("v.STEP_SEARCH_STORE");
        }
        if (component.get("v.currentStep") === component.get("v.STEP_FEE_ONBOARDING")){
            return component.get("v.STEP_INITIALIZE");
        }                
        return component.get("v.STEP_COMPLETE");        
    },    
    processStep : function(component, params) {
        var self = this;
        var version = component.get("v.version");
        switch (version) {
            case 3:
                this.renderProcessCmp(component, function(processCmp){
                    processCmp.processNextStepJS(params);
                });            
                break;
            case 4:
            case 5:
                self.renderProcessCmpV4(component, function(processCmp){});
                break;                                          
            default:
                break;
        }
    },
    renderProcessCmp: function(component, success){
        var targetCmp = component.find("processCmpPlaceHolder");
        if ( ($A.util.isEmpty(targetCmp.get("v.body"))) ) {
            $A.createComponent(
                "c:LDdNimdaProcessCmp",
                {
                    "aura:id" : "processCmp",
                    "recordId" : component.getReference("v.recordId"),
                    "businessId" : component.getReference("v.businessId"),
                    "storeId" : component.getReference("v.storeId"),
                    "accountId" : component.getReference("v.accountId"),
                    "opportunity" : component.getReference("v.opportunity"),
                    "account" : component.getReference("v.account")                                        
                },
                function(newProcessCmp, status, errorMessage){
                    if (status === "SUCCESS") {
                        targetCmp.set("v.body", newProcessCmp);
                        if (success) {
                            success.call(this, newProcessCmp);
                        }
                    }
                }
            );
        }
    },
    renderProcessCmpV4: function(component, success){
        var targetCmp = component.find("processCmpPlaceHolder");
        if ( ($A.util.isEmpty(targetCmp.get("v.body"))) ) {
            $A.createComponent(
                "c:LDdNimdaProcessCmpV4",
                {
                    "aura:id" : "processCmpV4",
                    "recordId" : component.getReference("v.recordId"),
                    "fullOnboardingAction" : component.getReference("v.fullOnboardingAction"),
                    "originatingOnboardingStep" : component.getReference("v.originatingOnboardingStep")                                 
                },
                function(newProcessCmp, status, errorMessage){
                    if (status === "SUCCESS") {
                        targetCmp.set("v.body", newProcessCmp);
                        if (success) {
                            success.call(this, newProcessCmp);
                        }
                    }
                }
            );
        }
    },
    renderProcessCmpV45: function(component, success){
        var targetCmp = component.find("processCmpPlaceHolder");
        if ( ($A.util.isEmpty(targetCmp.get("v.body"))) ) {
            $A.createComponent(
                "c:LDdNimdaProcessCmpV45",
                {
                    "aura:id" : "processCmpV45",
                    "recordId" : component.getReference("v.recordId"),
                    "fullOnboardingAction" : component.getReference("v.fullOnboardingAction"),
                    "originatingOnboardingStep" : component.getReference("v.originatingOnboardingStep")                                 
                },
                function(newProcessCmp, status, errorMessage){
                    if (status === "SUCCESS") {
                        targetCmp.set("v.body", newProcessCmp);
                        if (success) {
                            success.call(this, newProcessCmp);
                        }
                    }
                }
            );
        }
    },    
    renderPaymentCmpV3: function(component, success){
        var targetCmp = component.find("processCmpPlaceHolder");
        if ( ($A.util.isEmpty(targetCmp.get("v.body"))) ) {
            $A.createComponent(
                "c:LDdNimdaPaymentCmpV3",
                {
                    "aura:id" : "paymentCmpV3",
                    "recordId" : component.getReference("v.recordId")                               
                },
                function(newProcessCmp, status, errorMessage){
                    if (status === "SUCCESS") {
                        targetCmp.set("v.body", newProcessCmp);
                        if (success) {
                            success.call(this, newProcessCmp);
                        }
                    }
                }
            );
        }
    },        
})