({
    saveAttachCall : function(component,event,helper) {
        var caseId = component.get("v.recordId");
        var callType = component.get("v.callType");
        var action = component.get("c.postFeed");
        action.setParams({ caseId: caseId, callType: callType });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                helper.showToast(component, 'success', 'Success', "Your call has been successfully attached to the case.");
            } else {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        helper.showToast(component, 'error', 'Error', errors[0].message);
                    }
                } else {
                    helper.showToast(component, 'error', 'Error', "Unknown error");
                }
            }          
        });
        $A.enqueueAction(action);
    },
    showToast : function(component, type, title, msg) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type": type,
            "title": title,
            "message": msg
        });
        toastEvent.fire();
    },
})