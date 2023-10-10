({
    handleClick : function(component, success, failure) {
        var calloutCmp = component.find("calloutCmp");
        if (calloutCmp){
            calloutCmp.callout( 
                    component
                    , 'createNetSuiteAccount'
                    , { recordId : component.get("v.recordId") }
                    , function(result) {
                        if (success) {
                            var successToast = $A.get("e.force:showToast");
                            successToast.setParams({
                                "duration": 2000,
                                "title": "Success",
                                "message": result,
                                "type":'success'
                            });
                            successToast.fire();
                            $A.get("e.force:closeQuickAction").fire();
                        }
                    },
                    function(error){
                        if (failure) {
                            var failureToast = $A.get("e.force:showToast");
                            failureToast.setParams({
                                "duration": 7000,
                                "title": "Error",
                                "message": error.message,
                                "type":'info'
                            });
                            failureToast.fire();
                            $A.get("e.force:closeQuickAction").fire();
                        }                       
                    }
                );
        }       
    }
})