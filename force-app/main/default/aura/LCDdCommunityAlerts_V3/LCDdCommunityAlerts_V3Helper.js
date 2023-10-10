({
	getAlert : function(component, event) {
        var url = new URL(window.location.href);
        var urlString = url.pathname;
        var lang = url.searchParams.get("language");
        if (!lang) {
            lang = 'en_US';
		}

        var pageStart = 0;
        var pageEnd = urlString.length;
        var page = 'Home';


        var pageStart = urlString.indexOf('/s');
        if (pageEnd > (pageStart +3)){
            pageEnd = urlString.indexOf('/', pageStart+3);
            if (pageEnd !== -1){
            	page = urlString.substring(pageStart+3, pageEnd);
            } else {
                page = urlString.substring(pageStart+3, urlString.length);
            }
        }

		var action = component.get("c.getCommunityAlert");
        action.setParam("lang", lang);
        action.setParam("page", page);
        action.setParam("showInternalAlert", false);
        action.setCallback(this, function(a){
            if (a.getState() == "SUCCESS"){
                component.set("v.showAlert", true);
				component.set("v.alerts", a.getReturnValue());
                component.set("v.pageError", false);
            } else {
                component.set("v.showAlert", false);
                component.set("v.pageError", true);
                var errors = a.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.error(errors[0].message);
                    }
                    if (errors[0] && errors[0].pageErrors && errors[0].pageErrors[0]) {
                        console.error(errors[0].pageErrors[0].message);
                    }
                } else {
                    console.error("Unknown error");
                }
            }
        });
    	$A.enqueueAction(action);
	}
})