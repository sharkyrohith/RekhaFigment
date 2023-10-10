({
    onRender : function(component, event, helper) {
        component.set('v.agentUserId', $A.get('$SObjectType.CurrentUser.Id'));
        helper.shouldConnectToChat(component);
    }
})