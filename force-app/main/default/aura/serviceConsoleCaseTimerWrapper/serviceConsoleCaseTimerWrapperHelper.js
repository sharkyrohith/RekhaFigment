({
    // Update the variables for visibility that will trigger updates in the LWC component
    updateVisibility : function(component,focusedTabId) {
        const currentTabId = component.get("v.consoleTabId");
        const stopTimerWhenSubtabFocused = component.get("v.stopTimerWhenSubtabFocused");

        const focussedTabIsCurrentTab = focusedTabId === currentTabId;
        const focussedTabIsPrimary = focusedTabId && focusedTabId.indexOf('_') === -1;
        const focussedTabIsSubTabOfCurrentTab = !stopTimerWhenSubtabFocused && !focussedTabIsPrimary && focusedTabId && focusedTabId.startsWith(currentTabId);

        this.logToConsole(component,'helper updateVisbility',
            'currentTabId: ' + currentTabId + ' ; ' +
            'focusedTabId: ' + focusedTabId + ' ; ' +
            'focussedTabIsPrimary: ' + focussedTabIsPrimary + ' ; ' +
            'focussedTabIsCurrentTab: ' + focussedTabIsCurrentTab + ' ; ' +
            'focussedTabIsSubTabOfCurrentTab: ' + focussedTabIsSubTabOfCurrentTab);

        component.set('v.pausedVar', !focussedTabIsCurrentTab && !focussedTabIsSubTabOfCurrentTab);
    },
    // Update the variable for the tab being closed to trigger updates in the LWC component
    tabClosed : function(component,tabId) {
        const currentTabId = component.get("v.consoleTabId");
        component.set('v.maintabClosed', tabId === currentTabId);
    },
    setOmniStatus: function(component) {
        if (component.get("v.useOmniForAvailabilityTracking") && !component.get("v.omniStatus")) {
            let omniAPI = component.find("omniToolkit");
            if (omniAPI) {
                let helper = this;
                omniAPI.getServicePresenceStatusId().then(function(result) {
                    helper.logToConsole(component, "Setting Omni Current Status", result.statusName);
                    component.set("v.omniStatus",result.statusName);
                }).catch(function(error) {
                    if (error && typeof error === 'string' && error.indexOf('Omni-Channel is not available.') !== -1) {
                        component.set("v.omniStatus","Offline");
                    } else {
                        component.set("v.omniStatus","Unknown-Error");
                        helper.logToConsole(component, 'setOmniStatus Error', JSON.parse(JSON.stringify(error)));
                    }
                });
            }
        }
    },
    logToConsole : function(component, source, toLog) {
        if (component.get('v.loggingEnabled')) {
            console.log("Case Timer AURA: " + source, toLog);
        }
    }
})