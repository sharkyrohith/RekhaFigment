({
	handleCallout : function(component, event, helper) {
        var utilComponent = component;
        var params = event.getParam('arguments');
        if (params) {
            helper.callout(params.componentCtrl, params.actionName, params.params, params.success, params.failure, params.abortable);
        } 		
	}
})