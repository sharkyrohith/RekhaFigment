({
    back : function(component) {      
        var navEvt = $A.get("e.force:navigateToSObject");
    	navEvt.setParams({
      		"recordId": component.get("v.recordId")
    	});
    	navEvt.fire();
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