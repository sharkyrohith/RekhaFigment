({
    init : function(component) {
        var self = this;
        self.copyFields(component
            , function(result) {
                component.set("v.info", component.get("v.INFO_MSG_BATCH_JOB_SUBMITTED").replace('{0}', result));
                self.showToast(component, 'success', component.get("v.info"));
            }
            , function(error) {
                if (error.message){
                    component.set("v.error", error.message); 
                    self.showToast(component, 'error', component.get("v.error")); 
                }
            }
        );
    },
    copyFields : function(component, success, failure) {
        var self = this;
        var calloutCmp = component.find("calloutCmp");
        if (calloutCmp){
            calloutCmp.callout( 
                    component
                    , 'copyFields'
                    , { recordId : component.get("v.recordId") }
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
    showToast : function(component, messageType, message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Copy from Parent",
            "message": message,
            "type": messageType
        });
        toastEvent.fire();    
    },      
})