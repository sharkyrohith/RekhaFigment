({
    initComponent : function(component, event, helper) {
        var action = component.get("c.initQM");               
        action.setCallback(this, function(a){
            if (a.getState() === "SUCCESS") {
                var res = a.getReturnValue();
                component.set("v.isLiveAgentUser", res.isLiveAgentUser);
                component.set("v.currentQueues", res.queueMemberships);
                component.set("v.currentUserId", res.currentUserId);
                var membershipInterval = res.qmIntervalTime;
                var membershipIntervalCache = res.qmIntervalCacheTime;

                if (res.isLiveAgentUser){
                    component.set( "v.membershipIntervalId", 
                        window.setInterval(
                            $A.getCallback(function() {
                                if (!document.hidden){
                                    helper.getCurrentMembership(component, event, helper);
                                }
                            }),
                            membershipInterval)); 
                    component.set( "v.membershipCacheIntervalId", 
                        window.setInterval(
                            $A.getCallback(function() {
                                if (!document.hidden){
                                    helper.checkCurrentMembership(component, event, helper);
                                }
                            }),
                            membershipIntervalCache)); 
            }
            }
        });
        $A.enqueueAction(action);
    },
    checkCurrentMembership : function(component, event, helper) {
        var oldQueues =  component.get("v.currentQueues");
        var action = component.get("c.checkCurrentQueueMembership");   
        action.setParams({
            currentMemberships: oldQueues
        });            
        action.setCallback(this, function(a){
            if (a.getState() === "SUCCESS") {
                var queueList = a.getReturnValue();
                component.set("v.currentQueues", queueList);
                if (oldQueues !== queueList){
                    helper.resetAgentQueues(component, event, helper);
                }
            }
        });
        $A.enqueueAction(action);
    },
    getCurrentMembership : function(component, event, helper) {
        var action = component.get("c.getCurrentQueueMembership");               
        action.setCallback(this, function(a){
            if (a.getState() === "SUCCESS") {
                var queueList = a.getReturnValue();
                var oldQueues =  component.get("v.currentQueues");
                component.set("v.currentQueues", queueList);
                if (oldQueues !== queueList){
                    helper.resetAgentQueues(component, event, helper);
                }
            }
        });
        $A.enqueueAction(action);
    },
    resetAgentQueues : function(component, event, helper) {
        if (!window.location.href.includes("lightning")){
            var myEvent = $A.get("e.c:LDdQueueMonitorEvt");
            myEvent.fire();
        } else {
            var availableStatusId = $A.get("$Label.c.Omni_Available_Status");
            var omniAPI = component.find("omniToolkit");
            omniAPI.getAgentWorks()
                .then(function(result) {
                    omniAPI.logout()
                        .then(function(logoutRes){
                            if (logoutRes){
                                omniAPI.login({statusId: availableStatusId})
                                    .then(function(resLogin) {
                                        if (resLogin) {
                                            console.log("Login successful");
                                        } else {
                                            console.log("Login failed");
                                        }
                                    }).catch(function(error) {
                                        console.log(error);
                                    });
                            }
                        })
                }).catch(function(error) {
                    console.log(error);
                });
        }
    }

})