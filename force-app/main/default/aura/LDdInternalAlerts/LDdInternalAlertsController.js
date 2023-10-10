({
    doInit : function(component, event, helper) {
        helper.getInternalAlertRefreshInternal(component, event);
        helper.autoRefresh(component, event, helper);
    }
})