({
    init: function(component, event, helper) {
        var scale = component.get("v.scale");
        var step = null;
        if (!$A.util.isEmpty(scale)){
            switch (scale){
                case 0:
                    step = '1';
                    break;
                case 1:
                    step = '0.1';
                    break;
                case 2:
                    step = '0.01';
                    break; 
                case 3:
                    step = '0.001';
                    break;                                                             
                default:
                    step = '1';
                    break;                    
            }
        }
        if (step != null){
            component.set("v.step", step);
        }
    },    
	handleInlineEdit : function(component, event, helper) {
        // fire form item event type - Change Mode
        helper.fireFormItemEvent(component, component.get("v.FORM_ITEM_EVENT_TYPE_CHANGE_MODE"), null, component.get("v.FORM_ITEM_EDIT"));		
	},
    handleBlur : function(component, event, helper) {
        var validity  = component.find("input1").get("v.validity");
        // fire form item event type - Value Validity
        helper.fireFormItemEvent(component, component.get("v.FORM_ITEM_EVENT_TYPE_VALUE_VALIDITY"), component.get("v.property"), validity.valid);
    },    
    handleInputValueChange : function(component, event, helper) {
        // fire form item event type - Change Value
        helper.fireFormItemEvent(component, component.get("v.FORM_ITEM_EVENT_TYPE_CHANGE_VALUE"), component.get("v.property"), component.find("input1").get("v.value"), component.get("v.type"), component.get("v.scale"));      
    },
    handleSelectValueChange : function(component, event, helper) {
        // fire form item event type - Change Value
        helper.fireFormItemEvent(component, component.get("v.FORM_ITEM_EVENT_TYPE_CHANGE_VALUE"), component.get("v.property"), component.find("inputSelect1").get("v.value"), component.get("v.type"), component.get("v.scale"));      
    }
})