({
    doInit : function(component, event, helper) {
        helper.initTimer(component, event, helper);
    },
    onTabClosed : function(component, event, helper) {
        var intId = component.get("v.intId");
        var closedTabId = event.getParam('tabId');

        var workspaceAPI = component.find("workspace");
        workspaceAPI.getEnclosingTabId().then(function(enclosingTabId) {
            if (enclosingTabId == closedTabId){
                window.clearInterval(intId);
            }
        })
        .catch(function(error) {
            console.log(error);
        });
    }
})