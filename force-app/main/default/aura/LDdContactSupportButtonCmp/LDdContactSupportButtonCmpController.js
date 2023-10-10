({
	onInit : function(component, event, helper) {
        component.set("v.spinner", true);
        var recId = component.get("v.recordId");
        var action = component.get("c.getArticleExperiment");
        action.setParams({  artId : recId });
        action.setCallback(this, function(response) {
            component.set("v.spinner", false);
            var state = response.getState();
            if (state === "SUCCESS") {
                var res = response.getReturnValue();
                if (res === 'Show Web Form'){
                    var contactLink = component.get("v.ContactLink");
                    contactLink += '?webform=true';
                    component.set("v.ContactLink", contactLink);
                }
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log('ERROR:'  + errors[0].message);
                    }
                } else {
                    console.log('ERROR:'  + "Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
	}
})