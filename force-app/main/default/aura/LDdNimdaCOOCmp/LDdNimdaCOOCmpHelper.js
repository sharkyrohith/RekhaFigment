({
    fireNimdaSyncEvent: function(component, step, version) {
        var nimdaSyncEvent = component.getEvent("LDdNimdaSyncEvent");
        nimdaSyncEvent.setParams({
            step: step
            , version: parseInt(version)
        });
        nimdaSyncEvent.fire();
    },
    saveBusinessConfigurationOnOpportunity : function(component, success, failure) {  
        var calloutCmp = component.find("calloutCmp");
        if (calloutCmp){
            calloutCmp.callout( 
                    component
                    , 'saveBusinessConfigurationOnOpportunity'
                    , {opportunityId: component.get("v.opportunity.Id"),                                                
					   businessId : component.get("v.businessIDInput"),
				       businessOption: component.get("v.businessOptionSelected")}
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
    handleException : function(component, error, applyUpdates){
        if (error.message){
            try {
                let errorData = JSON.parse(error.message);
                component.set("v.errorType", errorData.errorType);
                component.set("v.errorMessage", errorData.errorMessage);           
            } catch(e) {
                component.set("v.errorType", component.get("v.ERROR_TYPE_FATAL"));
                component.set("v.errorMessage", error.message);
            }
        }
	},
    clearErrors : function(component) {
        component.set("v.errorType", "");
        component.set("v.errorMessage", "");
    }, 
    navigateToPreviousPage: function(component) {
        if (window.sforce && window.sforce.one){
            var navEvent = $A.get("e.force:navigateToSObject");
            navEvent.setParams({
                "recordId": component.get("v.opportunity.Id")
            });
            navEvent.fire();
        } else {         
            window.open("/" + component.get("v.opportunity.Id"), "_self");
        }
    },        
})