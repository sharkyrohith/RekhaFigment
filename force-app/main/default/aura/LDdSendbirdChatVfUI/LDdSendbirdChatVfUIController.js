({
    doInit : function(component, event, helper) {
        const vfOrigin = "https://" + helper.getVisualforceDomain();
        const vfEnhancedDomainOrigin = "https://" + helper.getEnhancedVfDomain();
        window.addEventListener("message", function(event) {
            if (event.origin === vfOrigin || event.origin === vfEnhancedDomainOrigin) {
                helper.processMessage(component,event.data);
            } else {
                console.log("Not the expected origin: Rejecting message!",`Got:${event.origin}`,`Expected: ${vfOrigin} or ${vfEnhancedDomainOrigin}`,event.data);
            }
        }, false);
        helper.getEnclosingTabId(component,helper,event);
    },
    onTabFocused : function(component, event, helper) {
        const focusedTabId = event.getParam('currentTabId');
        const tabId = component.get("v.enclosingTabId");
        if (focusedTabId !== tabId) {
            console.log('[LDdSendbirdChatVfUI] Ignoring onTabFocussed',focusedTabId,tabId);
            return;
        }
        const workspaceAPI = component.find("workspace");
        workspaceAPI.getTabInfo({
            tabId : focusedTabId
        }).then((response) => {
            if (response.highlighted) {
                helper.setTabHighlighted(component,tabId,false);
            }
        });
    }
})