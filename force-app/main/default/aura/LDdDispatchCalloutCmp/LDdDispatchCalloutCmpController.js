({
	doInit : function(component, event, helper) {
        helper.spinnerOn(component, event, helper);
        var isLightning = window.location.href.includes("lightning");
        component.set("v.isLightning", isLightning);
		var action = component.get("c.makeDeliveryCallout"); 
        action.setParams({"caseId": component.get("v.recordId")});                 
        action.setCallback(this, function(a){
            var showError = false;
            var errorMessage = '';
            if (a.getState() === "ERROR") {
                showError = true;
                errorMessage = a.getError()[0].message;
            } else { 
                if (isLightning){
                    component.set("v.isSuccess", true);
                } else {
                    helper.back(component);
                }
            }
            helper.spinnerOff(component, event, helper);
            component.set("v.showError", showError);
            component.set("v.errorMessage", errorMessage);
        });
    	$A.enqueueAction(action); 
    },
    cancel : function(component,event,helper) {
        helper.back(component);
    },
    handleOK : function(component,event,helper) {
        var recId = component.get("v.recordId");
        var tabId = "";
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getAllTabInfo().then(function(allTabs) {
            allTabs.forEach(function(tab){
                if (tab.recordId === recId){
                    tabId = tab.tabId;
                };
                tab.subtabs.forEach(function(subtab){
                    if (subtab.recordId === recId){
                        tabId = tab.tabId;
                    }
                });
            });
            if (tabId){
                workspaceAPI.refreshTab({   tabId: tabId,
                                            includeAllSubtabs: true
                                        });
            }
            $A.get("e.force:closeQuickAction").fire();
        })
        .catch(function(error) {
            component.set("v.isSuccess", false);
            component.set("v.showError", true);
            component.set("v.errorMessage", error);
        });
    }
})