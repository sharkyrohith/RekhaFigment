({
    doInit : function(component, event, helper) {
	    var action = component.get("c.createPersonAccount"); 
        action.setParams({"caseId": component.get("v.recordId")});                 
        action.setCallback(this, function(a){
            var showError = false;
            var errorMessage = '';
            if (a.getState() === "ERROR") {
                showError = true;
                if (a.getError()[0].message){
                    errorMessage = a.getError()[0].message;
                } else {
                    errorMessage = a.getError()[0].pageErrors[0].message;
                }
                
            } else { 
                helper.back(component);
            }
            
            component.set("v.showError", showError);
            component.set("v.errorMessage", errorMessage);
        });
    	$A.enqueueAction(action); 
    },
    cancel : function(component,event,helper) {
        helper.back(component);
    },
    spinnerOn : function(component) {
        var spinner = component.find("pageSpinner");
        if (spinner){
        	$A.util.removeClass(spinner, "slds-hide");
        }
    },
    spinnerOff : function(component) {
        var spinner = component.find("pageSpinner");
        if (spinner){
        	$A.util.addClass(spinner, "slds-hide");
        }
    }
})