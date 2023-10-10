({
    attachCall : function(component, event, helper) {
        helper.saveAttachCall(component, event, helper);
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