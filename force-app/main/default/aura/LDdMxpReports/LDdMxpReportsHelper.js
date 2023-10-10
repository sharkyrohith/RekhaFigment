({
    updateConsoleTabTitle: function(component, title) {
        var workspaceAPI = component.find("workspace");
        if (!workspaceAPI)
            return;

        // If console - then set the tab label and icon
        workspaceAPI.isConsoleNavigation().then(function(isConsole) {
            if (isConsole) {
                workspaceAPI.getFocusedTabInfo().then(function(tabInfo) {
                    workspaceAPI.setTabLabel({
                        tabId: tabInfo.tabId,
                        label: title
                    });
                    workspaceAPI.setTabIcon({
                        tabId: tabInfo.tabId,
                        icon: "standard:service_report",
                        iconAlt: "Report"
                    });
                })
                .catch(function(error) {
                    console.log('****workspaceAPI getFocusedTabInfo Error',error);
                });
            }
        });
    },
    navigateToRecord: function(component, helper, recordId, openMode, quickViewFieldSetName, quickViewHeaderValue) {
        var workspaceAPI = component.find("workspace");
        if (!workspaceAPI || openMode === 'newBrowserTab') {
            helper.navigateToNewBrowserTab(recordId);
            return;
        }

        // if console, then based on openMode, call the appropriate workspace api method to open a tab.
        // else, use the simple aura navigate to sobject method to open the tab.
        workspaceAPI.isConsoleNavigation().then(function(isConsole) {
            if (isConsole) {
                switch (openMode) {
                    case 'subTab':
                        workspaceAPI.getFocusedTabInfo().then(function(tabInfo) {
                            workspaceAPI.openSubtab({
                                parentTabId: tabInfo.tabId,
                                recordId: recordId,
                                focus: true
                            }).catch(function(error) {
                                console.log('****workspaceAPI openSubTab Error',error);
                            });
                        })
                        .catch(function(error) {
                            console.log('****workspaceAPI getFocusedTabInfo Error',error);
                        });
                        break;
                    case 'quickView':
                        var lwcDdGridReport=component.find('lwcDdGridReport');
                        lwcDdGridReport.openQuickView(recordId, quickViewFieldSetName, quickViewHeaderValue);
                        break;
                    default:
                        workspaceAPI.openTab({
                            recordId: recordId,
                            focus: true
                        })
                        .catch(function(error) {
                               console.log('****workspaceAPI openTab Error',error);
                        });
                        break;
                }
            } else {
                helper.navigateToNewBrowserTab(recordId);
            }
        });
    },
    navigateToNewBrowserTab: function(recordId) {
        window.open('/' + recordId);
    }
})