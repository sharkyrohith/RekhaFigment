({
	showToast: function(component, event, helper) {
		var params = event.getParam('arguments');
		component.set("v.messageType", params.messageType);
		component.set("v.message", params.message);
		component.set("v.callback", params.success);
		helper.showToast(component);
	},
	closeModel: function(component, event, helper) {
		helper.closeModel(component);
	}
})