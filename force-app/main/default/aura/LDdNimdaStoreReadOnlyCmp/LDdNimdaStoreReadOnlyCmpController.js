({
    init: function(component, event, helper) {
        helper.init(component);
    },    
	previous: function(component, event, helper) {
		helper.getPreviousStep(component);
	},
    cancel: function(component, event, helper) {
        helper.navigateToPreviousPage(component); 
    },    
    handleStoreFormItemEvent: function(component, event, helper) {
        var formItemEventName = event.getParam("name");
        var formItemEventProperty = event.getParam("property");
        var formItemEventValue = event.getParam("value");
        switch (formItemEventName) {
            case component.get("v.FORM_ITEM_EVENT_TYPE_CHANGE_MODE"):
                component.set("v.isEditing", formItemEventValue == component.get("v.FORM_ITEM_EDIT"));                            
                break;
            case component.get("v.FORM_ITEM_EVENT_TYPE_VALUE_VALIDITY"):
                helper.handleFieldErrors(component, formItemEventProperty, $A.util.getBooleanValue(formItemEventValue));                          
                break;                
            case component.get("v.FORM_ITEM_EVENT_TYPE_CHANGE_VALUE"):
                var formItemEventType = event.getParam("type");
                var formItemEventScale = event.getParam("scale");            
                helper.handleValueChange(component, formItemEventProperty, formItemEventValue, formItemEventType, formItemEventScale);
                break;                
            default:
                break;
        }
    },
    toggleReviewChangesSection : function(component, event, helper) {
        var reviewChangesSection = component.find('reviewChangesSection');
        $A.util.toggleClass(reviewChangesSection,'slds-is-open');
    },    
    toggleStoreSection : function(component, event, helper) {
        var storeSection = component.find('storeSection');
        $A.util.toggleClass(storeSection,'slds-is-open');
    },
    toggleStorePartnershipSection : function(component, event, helper) {
        var storePartnershipSection = component.find('storePartnershipSection');
        $A.util.toggleClass(storePartnershipSection,'slds-is-open');
    },
    toggleMxAffiliatePrgmSection : function(component, event, helper) {
        var storePartnershipSection = component.find('mxAffiliatePrgmSection');
        $A.util.toggleClass(storePartnershipSection,'slds-is-open');
    },
    finish : function(component, event, helper) {
        helper.finish(component);
    },
})