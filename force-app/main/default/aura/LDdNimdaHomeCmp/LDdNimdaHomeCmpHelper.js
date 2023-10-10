({
    init: function(component, event, helper) {	
        var self = this;
        // Get steps to display on the Home Component
        self.getSteps(component
            , function(result) {
            	console.log(result);
                component.set("v.actions", result);
            }
            , function(error) {
                self.handleException(component, error, false);
            }
        );
    },
    handleException : function(component, error, applyUpdates){
        var self = this;
        if (error.message){
            try {
                let errorData = JSON.parse(error.message);
                component.set("v.errorMessage", errorData.errorMessage);
            } catch(e) {
                component.set("v.errorMessage", error.message);
            }
        }
    },
    getSteps : function(component, success, failure) {
        var self = this;
        var calloutCmp = component.find("calloutCmp");
        if (calloutCmp){
            calloutCmp.callout( 
                    component
                    , 'getSendToNimdaSteps'
                    , {opportunity : component.get("v.opportunity")}
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