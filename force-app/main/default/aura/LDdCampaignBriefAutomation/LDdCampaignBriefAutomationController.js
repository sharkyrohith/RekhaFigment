({
    doInit : function(component, event, helper) {
        helper.showSpinner(component);
        var action = component.get("c.createCampaignBrief");
        action.setParams({
            recId: component.get("v.recordId")
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS") {
                component.set("v.message",response.getReturnValue());
                helper.hideSpinner(component);
            }
        });
        $A.enqueueAction(action);
    }
})