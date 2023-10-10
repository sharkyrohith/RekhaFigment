({
	openModel: function(component, event, helper) {
    	// Set isModalOpen attribute to true
      	component.set("v.isModalOpen", true);
      	var modal = component.find("myModal");


        // Now add and remove class
        $A.util.addClass(modal, 'slds-fade-in-open');

   	},
   
    
    showToast : function(component, event, helper) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Success!",
            "message": "Mx EIN Verified successfully",
            "type":"success"
        });
        toastEvent.fire();
	},
    
    showError : function(component, event, helper) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Error!",
            "message": "Mx EIN does not match",
            "type":"error"
        });
        toastEvent.fire();
	}
})