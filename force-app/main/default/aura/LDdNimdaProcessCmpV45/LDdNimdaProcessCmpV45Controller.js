({
    init: function(component, event, helper) {
        helper.showInfoDialog(component, true, component.get("v.INFO_MESSAGE_INITIALIZING"));
        var fullOnboardingAction = component.get("v.fullOnboardingAction");
        switch (fullOnboardingAction) {
            case component.get("v.FULL_ONBOARDING_CREATE"):
                component.set("v.pollingSteps", component.get("v.STEPS_FULL_ONBOARDING_CREATE_V4"));
                break;
            case component.get("v.FULL_ONBOARDING_UPDATE"):
                component.set("v.pollingSteps", component.get("v.STEPS_FULL_ONBOARDING_UPDATE_V4"));
                break;                                               
            default:
                break;
        }        
    },
    handleNimdaSyncPollingEvent: function(component, event, helper) {
        console.log('LDdNimdaProcessCmpV4: Entering handleNimdaSyncPollingEvent');
        var data = event.getParam("message");
        console.log('LDdNimdaProcessCmpV4: ' + JSON.stringify(data));
        if (data.type && data.type == 'INITIALIZED'){
            helper.init(component);
        } else {
            if (data.message && data.message.data && data.message.data.sobject){
                if (!$A.util.isEmpty(data.message.data.sobject.Nimda_Sync_Step__c)){
                    helper.handlePolledResult(component
                        , function(result) {
                            if ($A.util.getBooleanValue(helper.showPayment(component, component.get("v.polledStep")))){
                                component.set("v.showPaymentV3", true);
                            }
                        }
                    );
                }
            }
        }
    },
    toggleSTNv4Section : function(component, event, helper) {
        helper.toggleSTNv4Section(component);
    },
    toggleSTNv3Section : function(component, event, helper) {
        helper.toggleSTNv3Section(component);
    },            
})