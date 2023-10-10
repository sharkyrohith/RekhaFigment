({
    init: function(component, event, helper) {
        // Prefetch dependencies in a separate out of band action request
        setTimeout($A.getCallback(function() {
            $A.createComponent("c:LDdNimdaSyncDependencies", {}, function() {
                console.log("c:LDdNimdaSyncDependencies loaded");
            });
        }), 300);        
        helper.init(component);
    },
    handleNimdaSyncEvent: function(component, event, helper) {
        /** 1. Set current step */
        var eventStep = event.getParam("step");
        component.set("v.currentStep", eventStep);
        /** 2. Set version */        
        var version = event.getParam("version");
        if (!$A.util.isEmpty(version)){
            component.set("v.version", version);
        }
        /** 3. Set isChangeOfOwnership */
        var isChangeOfOwnership = event.getParam("isChangeOfOwnership");
        component.set("v.isChangeOfOwnership", $A.util.getBooleanValue(isChangeOfOwnership));
        /** 4. Set originating onboarding step */ 
        helper.setOriginatingOnboardingStep(component, eventStep);
        /** 5. Perform the appropriate action */ 
        switch (eventStep) {
            case component.get("v.FULL_ONBOARDING_CREATE"):
                component.set("v.fullOnboardingAction", component.get("v.FULL_ONBOARDING_CREATE"));
                helper.processStep(component);                             
                break;                
            case component.get("v.FULL_ONBOARDING_UPDATE"):
                component.set("v.fullOnboardingAction", component.get("v.FULL_ONBOARDING_UPDATE"));
                helper.processStep(component, event.getParam("value"));                             
                break;
            case component.get("v.CHANGE_OF_OWNERSHIP_CREATE"):
                component.set("v.fullOnboardingAction", component.get("v.CHANGE_OF_OWNERSHIP_CREATE"));
                helper.processStep(component);                             
                break;                
            case component.get("v.CHANGE_OF_OWNERSHIP_UPDATE"):
                component.set("v.fullOnboardingAction", component.get("v.CHANGE_OF_OWNERSHIP_UPDATE"));
                helper.processStep(component, event.getParam("value"));                             
                break;                
            case component.get("v.STEP_PAYMENT_ACCOUNT"):
                helper.renderPaymentCmpV3(component, function(processCmp){});                 
                break;                
            case component.get("v.STEP_SEARCH_STORE"):
                component.set("v.storeId", event.getParam("value"));                     
                break;
            case component.get("v.STEP_UPDATE_STORE"):
            case component.get("v.STEP_PRODUCT_AND_PRICING_ONBOARDING"):
            case component.get("v.STEP_FEE_ONBOARDING"):
            case component.get("v.STEP_CHANGE_OF_OWNERSHIP_CONFIRMATION"):
            default:
                break;
        }

    },        
    next: function(component, event, helper) {
        let nextStep = helper.getNextStep(component);
        if (component.get("v.currentStep") !== nextStep){
            component.set("v.currentStep", nextStep);
        }
    },
    previous: function(component, event, helper) {
        let previousStep = helper.getPreviousStep(component);
        if (component.get("v.currentStep") !== previousStep){
            component.set("v.currentStep", previousStep);
        }
    },    
    navigateToPreviousPage: function(component, event, helper) {
        if (window.sforce && window.sforce.one){
            var navEvent = $A.get("e.force:navigateToSObject");
            navEvent.setParams({
                "recordId": component.get("v.recordId")
            });
            navEvent.fire();
        } else {         
            window.open("/" + component.get("v.recordId"), "_self");
        }
    },
})