({
    doInit : function(component, event, helper) {
        //component.set('v.loggingEnabled',true); // Determines if the logs are written to the console. Disable/remove before publishing

        var autoStarted = component.get("v.autoStartVar");
        var workspaceAPI = component.find("workspace");

        component.set('v.pausedVar', !autoStarted);

        workspaceAPI.getEnclosingTabId().then(function(response){
            var enclosingTabId = response;
            helper.logToConsole(component, "doInit TabID", enclosingTabId);
            component.set('v.consoleTabId', enclosingTabId);
        });

        workspaceAPI.isConsoleNavigation().then(function(response) {
            // Set the parameter - true if console nav, false if standard
            component.set("v.isConsoleNavigation", response);
        });

        helper.setOmniStatus(component,false);
    },

    onTabCreated : function(component, event, helper) {
        helper.logToConsole(component, "onTabCreated event", event.getParam('tabId'));
        helper.updateVisibility(component, event.getParam('tabId'));
    },

    onTabFocused : function(component, event, helper) {
        helper.logToConsole(component, "onTabFocused event", event.getParam('currentTabId'));
        helper.updateVisibility(component, event.getParam('currentTabId'));
    },

    onTabUpdated : function(component, event, helper) {
        helper.logToConsole(component, "onTabUpdated event", event.getParam('tabId'));
        helper.updateVisibility(component, event.getParam('tabId'));
    },

    onTabReplaced : function(component, event, helper) {
        helper.logToConsole(component, "onTabReplaced event", event.getParam('tabId'));
        helper.updateVisibility(component, event.getParam('tabId'));
    },

    onTabClosed : function(component, event, helper) {
        helper.logToConsole(component, "onTabClosed event",event.getParam('tabId'));
        helper.tabClosed(component, event.getParam('tabId'));
    },

    // This is called by the LWC to open the Session Time or User record when the corresponding column is clicked
    openRecord : function(component, event, helper){
        var workspaceAPI = component.find("workspace");
        var recordId = event.getParam('passedrecid');

        workspaceAPI.isConsoleNavigation().then(function(response) {
            if(response){
                workspaceAPI.openTab({
                    recordId: recordId,
                })
                .catch(function(error) {
                });
            }else{
                var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                    "recordId": recordId,
                });
                navEvt.fire();
            }
        })
    },

    onOmniConnectionError: function(component, event, helper) {
        if (component.get("v.useOmniForAvailabilityTracking")) {
            helper.logToConsole(component, "Omni Network Connection Error.");
            component.set("v.omniStatus", "Offline-Connection Error");
        }
    },

    onOmniLoginSuccess: function(component, event, helper) {
        if (component.get("v.useOmniForAvailabilityTracking")) {
            helper.logToConsole(component,"Omni Login success.");
            helper.setOmniStatus(component);
        }
    },

    onOmniStatusChanged: function(component, event, helper) {
        if (component.get("v.useOmniForAvailabilityTracking")) {
            const statusName = event.getParam('statusName');
            helper.logToConsole(component,"Omni Status changed",statusName);
            component.set("v.omniStatus",statusName);
        }
    },

    onOmniLogout: function(component, event, helper) {
        if (component.get("v.useOmniForAvailabilityTracking")) {
            helper.logToConsole(component,"Omni Logout success.");
            const reason = event.getParam("reason");
            if (reason === 'DuplicateLogin') {
                component.set("v.omniStatus","Offline-Another Browser");
            } else {
                component.set("v.omniStatus","Offline");
            }
        }
    }
})