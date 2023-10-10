({ 
    handleSelection: function(component, event, helper) {
        var value = component.get("v.value");
        switch (value) {
            case component.get("v.CHANGE_OF_OWNERSHIP_CREATE"):
                helper.fireNimdaSyncEvent(component, component.get("v.STEP_CHANGE_OF_OWNERSHIP_CONFIRMATION"), component.get("v.version"));           
                break;                
            case component.get("v.CHANGE_OF_OWNERSHIP_UPDATE"):
                helper.fireNimdaSyncEvent(component, component.get("v.STEP_UPDATE_STORE"), component.get("v.version"));                                      
                break;
            default: 
                helper.fireNimdaSyncEvent(component, value, component.get("v.version")); 
                break;  
        }
    },    
})