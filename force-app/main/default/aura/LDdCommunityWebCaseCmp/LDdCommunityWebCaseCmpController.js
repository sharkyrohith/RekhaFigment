({
    onInit: function(component, event, helper) {
        helper.initCmp(component, event, helper);
        helper.checkIPaddress(component, event, helper);
    },
    handleCategoryChange: function(component, event, helper) {
        helper.onCategoryChange(component, event, helper);
    },
    submitCase: function(component, event, helper) {
        component.set("v.spinner", true);
        var btn = event.getSource();
        btn.set('v.disabled', true);
        document.dispatchEvent(new CustomEvent("grecaptchaExecute", {"detail": {action: "submitCase"}}));
    } 
})