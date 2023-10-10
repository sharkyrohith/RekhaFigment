({
	showToast: function(component) {
		var self = this;
		$A.util.removeClass(component.find('toastModel'), 'slds-hide');
		$A.util.addClass(component.find('toastModel'), 'slds-show');
		var closeTime = component.get("v.autoCloseTime");
		var autoClose = component.get("v.autoClose");
		var autoCloseErrorWarning = component.get("v.autoCloseErrorWarning");
		if (autoClose){
			setTimeout(function() {
				self.closeModel(component);
			}, closeTime);
		}
	},
	closeModel: function(component) {
		$A.util.addClass(component.find('toastModel'), 'slds-hide');
		component.set("v.messageType", "");
		component.set("v.messageType", "");
		this.fireCallback(component);
	},	
	fireCallback: function(component) {
		var callback = component.get("v.callback");
		if (callback) {
			callback.call(this);
		}		
	}
})