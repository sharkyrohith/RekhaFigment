({
	onWorkAccepted : function(component, event, helper) {
        var workItemId = event.getParam('workItemId');
        var workId = event.getParam('workId');

        var action = component.get("c.CreateCase");
        action.setParams({ workItemId : workItemId });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var cCase = response.getReturnValue();
                if (cCase != null){
                    helper.openSubTab(component, helper, workItemId, cCase.Id);
                }
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
    onWorkAssigned : function(component, event, helper) {
        var workItemId = event.getParam('workItemId');
        var workId = event.getParam('workId');
       
        if (workItemId.startsWith("500")){
            var action = component.get("c.stampPreviousQueue");
            action.setParams({ caseId : workItemId });

            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "ERROR") {
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
        }
    },
    onTabCreated : function(component, event, helper) {
        var newTabId = event.getParam('tabId');
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getTabInfo({
            tabId: newTabId
        }).then(function(response) {
            if (response.recordId.startsWith("500")){
                var action = component.get("c.takeOwnership");
                action.setParams({ caseId : response.recordId });
    
                action.setCallback(this, function(response) {
                    var state = response.getState();
                    if (state === "ERROR") {
                        var errors = response.getError();
                        if (errors) {
                            if (errors[0] && errors[0].message) {
                                helper.showToast('Error', errors[0].message);
                            }
                        } else {
                            helper.showToast('Error', "Unknown error");
                        }
                    } else {
                        workspaceAPI.refreshTab({
                            tabId: newTabId,
                            includeAllSubtabs: true
                        });
                            
                    }
                });
    
                $A.enqueueAction(action);
            }
        });
            
    }, 
})