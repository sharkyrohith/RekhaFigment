({
    init: function(component, event, helper) {
        helper.init(component);
    },
    handleCancel : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();      
    }    
})