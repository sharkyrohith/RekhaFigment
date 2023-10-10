({
    onInit: function (component, event, helper){ 
        document.addEventListener('grecaptchaVerified', function(e) {
            component.set("v.spinner", true);
            var action = component.get("c.verifyRecaptcha");
            action.setParams({
                recaptchaResponse: e.detail.response,
                domain : component.get("v.communityDomain")
            });
            action.setCallback(this, function(response) {
                component.set("v.spinner", false);
                if (response.getReturnValue()){
                    
                    component.set("v.verified", true);
                    document.dispatchEvent(new CustomEvent("grecaptchaServerVerified"));
                }
            });
            
            $A.enqueueAction(action);
        });
    },
    onRender: function (component, event, helper){ 
        document.dispatchEvent(new CustomEvent("grecaptchaRender", { "detail" : { element: 'recaptchaCheckbox'} }));
    }
})