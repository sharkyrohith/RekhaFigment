({
    init: function (component, event, helper) {
        helper.handleInit(component, event, helper);
    },
    loadMore: function (component, event, helper) {
        helper.loadMoreRecords(component, event, helper);
    },
    recordAction: function (component, event, helper) {
        var rec = event.getParam('row');
        var actionName = event.getParam('action').name;
        helper.treatRecordAction(component, event, helper,rec, actionName);
    },
    performMerge : function(component, event, helper) {
        component.set("v.isModalOpen", false);
        helper.performMergeCases(component, event, helper);
    },
    spinnerOn : function(component) {
        var spinner = component.find("pageSpinner");
        if (spinner){
        	$A.util.removeClass(spinner, "slds-hide");
        }
    },
    spinnerOff : function(component) {
        var spinner = component.find("pageSpinner");
        if (spinner){
        	$A.util.addClass(spinner, "slds-hide");
        }
    }, 
    openModel: function(component, event, helper) {
        component.set("v.isModalOpen", true);
    },
    closeModel: function(component, event, helper) {
        component.set("v.isModalOpen", false);
    },
})