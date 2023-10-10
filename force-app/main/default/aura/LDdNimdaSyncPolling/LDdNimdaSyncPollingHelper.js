({
	init: function(component) {
        component.set("v.isLoading", true);
        var self = this;
        self.addEventListener(component);
		self.getNimdaSyncPollingPageURL(component
    		, function(result) {
    			let pageURL = String(result) + '?' + 'id=' + component.get("v.recordId");
    			console.log('Page URL = ' + pageURL);
        		component.set("v.nimdaSyncPollingPageURL", pageURL);
        		component.set("v.isLoading", false);
        	}
        	, function(error) {
        		self.handleException(component, error);
        		component.set("v.isLoading", false);
        	}
        );
    },
    addEventListener: function(component){
        var self = this;
        window.addEventListener('message', $A.getCallback(function(postMessageEvent) {
            if (postMessageEvent && postMessageEvent.data.randomKey && component.isValid() && (postMessageEvent.data.randomKey == component.get("v.RANDOM_KEY"))){
                component.set("v.origin", postMessageEvent.origin);
            }
            if (postMessageEvent && postMessageEvent.data && component.isValid() && (postMessageEvent.origin == component.get("v.origin"))) {
                var data = postMessageEvent.data;
                self.fireEvent(component, data);
            }
        }), false);
    },
    fireEvent: function(component, message) {
        console.log('Firing nimda sync polling event with message ' + JSON.stringify(message));
        // Get the event 
        var evt = component.getEvent("LDdNimdaSyncPollingEvent");
        // Populate the event 
        evt.setParams({"message" : message});
        // Fire the event
        evt.fire();
    },
	handleException : function(component, error){
		console.log(error);
	},   
    getNimdaSyncPollingPageURL : function(component, success, failure) {
        var self = this;
        var calloutCmp = component.find("calloutCmp");
        if (calloutCmp){
            calloutCmp.callout( 
                component
                , 'getNimdaSyncPollingPageURL'
                , { }
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