({
	init : function(component) {
		let selectedIds = JSON.parse(component.get("v.selectedIdsSerializedString"));
		component.set("v.selectedIds", selectedIds);
	},
	showToast : function(component, messageType, message) {
        this.renderToastCmp(component, function(toastCmp){
            toastCmp.showToastModel(messageType, message, function(){
	            var navEvent = $A.get("e.force:navigateToObjectHome");
				navEvent.setParams({
					"scope": "Account"
				});
				navEvent.fire();	            
            });
        });		
	},
    renderToastCmp: function(component, success){
        var targetCmp = component.find("toastCmpPlaceHolder");
        if ( ($A.util.isEmpty(targetCmp.get("v.body"))) ) {
            $A.createComponent(
                "c:LDdToastCmp",
                {
                    "aura:id" : "toastCmp",
                },
                function(newToastCmp, status, errorMessage){
                    if (status === "SUCCESS") {
                        targetCmp.set("v.body", newToastCmp);
                        if (success) {
                            success.call(this, newToastCmp);
                        }
                    }
                }
            );
        }
    },
    coverageCheck : function(component, success, failure) {
        var self = this;
        var calloutCmp = component.find("calloutCmp");
        if (calloutCmp){
            calloutCmp.callout( 
                    component
                    , 'coverageCheck'
                    , { recordIds : component.get("v.selectedIds") }
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