({
    afterRender: function (component, helper) {
        this.superAfterRender();
        helper.initVerifyRecaptcha(component,helper);
    }
})