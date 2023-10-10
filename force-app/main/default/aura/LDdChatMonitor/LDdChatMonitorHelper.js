({
	openSubTab : function(component, helper, primaryObjectId, caseId) {
        var workspaceAPI = component.find("workspace");
        var caseViewURL = $A.get("$Label.c.Lightning_Case_View_URL");
        caseViewURL = helper.formatString(caseViewURL, caseId);

        workspaceAPI.getAllTabInfo().then(function(allTabInfo) {
            allTabInfo.forEach(function (tabInfo){
                if (!tabInfo.isSubTab 
                    && tabInfo.recordId
                    && tabInfo.recordId.startsWith(primaryObjectId)){
                    workspaceAPI.openSubtab({
                        parentTabId: tabInfo.tabId,
                        url: caseViewURL,
                        focus: true
                    }).catch(function(error) {
                        helper.showToast('Error', error);
                    });
                }
            });
        }).catch(function(error) {
            helper.showToast('Error', error);
        });
    },
    showToast : function(component, title, msg) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": msg
        });
        toastEvent.fire();
    },
    formatString : function(inputString) {
        var retVal = inputString;
        for (var idx = 0; idx < arguments.length; idx++) {
            if (idx != 0){
                retVal = retVal.replace("{" + (idx-1) + "}", arguments[idx]);
            }
        }
        return retVal
    }
})