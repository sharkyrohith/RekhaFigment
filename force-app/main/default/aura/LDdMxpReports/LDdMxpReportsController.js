({
    // Update the tab title and logo
    handleReportActivation: function(component, event, helper) {
        const reportName = event.getParam("reportName");
        helper.updateConsoleTabTitle(component,reportName);
    },
    // Navigate to an SObject
    handleNavigateToRecord: function(component, event, helper) {
        if (event === null || !event.getParam("recordId"))
            return;

        const recordId = event.getParam("recordId");
        const openMode = event.getParam("openMode") ? event.getParam("openMode") : 'tab';
        const quickViewFieldSetName = event.getParam("quickViewFieldSetName") ? event.getParam("quickViewFieldSetName") : '';
        const quickViewHeaderValue = event.getParam("quickViewHeaderValue") ? event.getParam("quickViewHeaderValue") : '';
        helper.navigateToRecord(component,helper,recordId,openMode,quickViewFieldSetName,quickViewHeaderValue);
    }
})