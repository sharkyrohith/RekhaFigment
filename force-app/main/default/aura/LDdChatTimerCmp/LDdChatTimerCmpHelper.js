({

    initTimer : function(component, event, helper) {
        var transId = component.get("v.recordId");
        var action = component.get("c.getChatInfo");
        action.setParams({  tranId: transId});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var resp = response.getReturnValue();
                component.set("v.transObj", resp);
                if (resp.status == "Completed"){
                    helper.calculateTime(component, event, helper);
                } else {
                    var intId = window.setInterval(
                        $A.getCallback(function() {
                            helper.calculateTime(component, event, helper);
                        }), 1000);
                    component.set("v.intId", intId);
                }
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log('ERROR:'  + errors[0].message);
                    }
                } else {
                    console.log('ERROR:'  + "Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
        
    },
    calculateTime : function(component, event, helper) {
        var transObj = component.get("v.transObj");
        var startTime = transObj.startTime;
        var endTime = (new Date()).getTime();
        if (transObj.Status == "Completed"){
            endTime = transObj.endTime;
        }
        var timeElapsed = endTime - startTime;
        var minutes = helper.pad(parseInt(timeElapsed / 60000));
        var seconds = helper.pad(parseInt((timeElapsed % 60000) / 1000));
        var timercss = "dd-service-console-green";
        if (minutes >= 8){
            timercss = "dd-service-console-red";
        } else if (minutes >= 5){
            timercss = "dd-service-console-yellow";
        }

        component.set("v.timercss", timercss);
        component.set("v.minutes", minutes);
        component.set("v.seconds", seconds);
        
    },
    pad: function (val) {
        var valString = val + "";
        if (valString.length < 2) {
            return "0" + valString;
        } else {
            return valString;
        }
    }
})