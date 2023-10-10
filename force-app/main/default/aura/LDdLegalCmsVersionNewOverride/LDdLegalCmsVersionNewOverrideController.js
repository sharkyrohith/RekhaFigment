({
    doInit : function(component, event, helper) {
        // Extracting Parent Id from URL args.
        const pageRef = component.get("v.pageReference");
        const state = pageRef.state; // state holds any query params
        let base64Context = state.inContextOfRef;
		/*For some reason, the string starts with "1.", removing this.*/
        if (base64Context.startsWith("1\.")) {
            base64Context = base64Context.substring(2);
        }
        const addressableContext = JSON.parse(window.atob(base64Context));
        component.set("v.parentId", addressableContext.attributes.recordId);

        // Setting enclosing Tab Id and parent Tab Id for console apps.
        const workspaceAPI = component.find("workspace");
        if (!workspaceAPI) {
            return;
        }

        workspaceAPI.isConsoleNavigation().then(isConsole => {
            if (isConsole) {
                workspaceAPI.getFocusedTabInfo().then(function(response) {
                    if (response.subtabs && response.subtabs.length) {
                        let subTabId = response.tabId;
                        for (const subtab of response.subtabs) {
                            if (!subtab.pageReference) {
                                continue;
                            }
                            let subtabAttrib = subtab.pageReference.attributes;
                            if (subtabAttrib.objectApiName == "Legal_CMS_Content_Version__c" && subtabAttrib.actionName == "new") {
                                subTabId = subtab.tabId;
                                break;
                            }
                        }
                        component.set("v.enclosingTabId", subTabId);
                        component.set("v.parentTabId", response.tabId);
                    } else {
                        component.set("v.enclosingTabId", response.tabId);
                        component.set("v.parentTabId", response.parentTabId);
                    }
                })
                .catch(function(error) {
                    console.log('error getting focussed tab id',error);
                });
            }
        });
    },
    // @description - When New Override window Cancel button is clicked, close that subtab.
    handleCloseEnclosingTab: function(component, event, helper) {
        const workspaceAPI = component.find("workspace");
        if (!workspaceAPI) {
            return;
        }

        const tabId = event.getParam('tabId');

        workspaceAPI.isConsoleNavigation().then(isConsole => {
            if (isConsole) {
                workspaceAPI.closeTab({tabId: tabId});
            }
        });
    },
    // @description - When New Override window Save button is clicked, close that intermediate subtab and open the new record in another subtab.
    handleOpenNewVersionInSubtab: function(component, event, helper) {
        const workspaceAPI = component.find("workspace");
        if (!workspaceAPI) {
            return;
        }

        const tabIdToClose = event.getParam('tabIdToClose');
        const recordId = event.getParam('recordId');
        const parentTabId = event.getParam('parentTabId');

        workspaceAPI.isConsoleNavigation().then(isConsole => {
            if (isConsole) {
                workspaceAPI.openSubtab({
                    parentTabId: parentTabId,
                    recordId,
                    focus: true
                }).then(tabId => {
                    workspaceAPI.closeTab({tabId: tabIdToClose});
                    workspaceAPI.refreshTab({
                        tabId: parentTabId,
                        includeAllSubtabs: false
                    });
                });
            }
        });
    }
})