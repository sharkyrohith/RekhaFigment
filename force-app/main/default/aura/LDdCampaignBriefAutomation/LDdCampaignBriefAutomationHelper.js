({
    showSpinner: function (component, event, helper) {
        var spinner = component.find("campaignSpinnerId");
        $A.util.removeClass(spinner, "slds-hide");
    },
     
    hideSpinner: function (component, event, helper) {
        var spinner = component.find("campaignSpinnerId");
        $A.util.addClass(spinner, "slds-hide");
    }
})