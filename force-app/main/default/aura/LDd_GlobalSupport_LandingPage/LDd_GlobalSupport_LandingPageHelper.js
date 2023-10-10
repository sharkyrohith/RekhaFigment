({
	getStat : function(component, helper) {
        var lang = helper.findGetParameter("language");
        lang = lang.substring(0, 2);
        var comm = component.get("v.community");
        var action = component.get("c.getWaitTimes");
        action.setParams({ "lang" : lang, "comm": comm });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var res = JSON.parse(response.getReturnValue());
                component.set("v.currentWaitTime", res.Five9WaitTime);
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        helper.showToast('Error', errors[0].message);
                    }
                } else {
                    helper.showToast('Error', "Unknown error");
                }
            }

      	});
        $A.enqueueAction(action);
		
	},
    showToast : function(component, title, msg) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": msg
        });
        toastEvent.fire();
    },
    findGetParameter : function (parameterName) {
        var result = null,
            tmp = [];
        location.search
            .substr(1)
            .split("&")
            .forEach(function (item) {
              tmp = item.split("=");
              if (tmp[0] === parameterName) result = decodeURIComponent(tmp[1]);
            });
        return result;
    }
})