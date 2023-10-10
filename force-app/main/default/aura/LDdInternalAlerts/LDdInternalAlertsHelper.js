({
    getAlert : function(component, event) {
        var utilityAPI = component.find("utilitybar");
        var action = component.get("c.getCommunityAlert");
        action.setParam("showInternalAlert", true);

        action.setCallback(this, function(a){
            if (a.getState() == "SUCCESS"){
                component.set("v.showAlert", true);
                var alerts = a.getReturnValue();
                component.set("v.pageError", false);

                if(alerts && alerts.length > 0){
                    utilityAPI.getAllUtilityInfo().then(function (response) {
                        if (typeof response !== 'undefined') {
                                    utilityAPI.openUtility();
                        }
                    });
                    var myEvent = $A.get("e.c:LDdRefreshInternalAlertEvt");
                    myEvent.fire();
                }
                else {
                    alerts = [{"Alert_Type__c" : "Informative", "Text_before_URL__c" : "No Internal Alerts"}];
                }
                component.set("v.alerts", alerts);
            } else {
                component.set("v.showAlert", false);
                component.set("v.pageError", true);
                var errors = a.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.error(errors[0].message);
                    }
                    if (errors[0] && errors[0].pageErrors && errors[0].pageErrors[0]) {
                        console.error(errors[0].pageErrors[0].message);
                    }
                } else {
                    console.error("Unknown error");
                }  
            } 
        });
    	$A.enqueueAction(action); 
    },

    getInternalAlertRefreshInternal: function(component, event){
        var action = component.get("c.getInternalAlertRefreshInternal");

        action.setCallback(this, function(a){
            if (a.getState() == "SUCCESS"){
                component.set("v.internalAlertRefreshInterval", a.getReturnValue());
            } else {
                var errors = a.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.error(errors[0].message);
                    }
                    if (errors[0] && errors[0].pageErrors && errors[0].pageErrors[0]) {
                        console.error(errors[0].pageErrors[0].message);
                    }
                } else {
                    console.error("Unknown error");
                }
            }
        });
        $A.enqueueAction(action); 
    },

    autoRefresh:  function(component, event, helper){
        var that = this;

        helper.getAlert(component, event);
        var refreshIntervalMilliSec = component.get("v.internalAlertRefreshInterval") * 1000;
        window.setTimeout(
            $A.getCallback(function() {
                that.autoRefresh(component, event, helper);
            }), refreshIntervalMilliSec
        );
    }
})