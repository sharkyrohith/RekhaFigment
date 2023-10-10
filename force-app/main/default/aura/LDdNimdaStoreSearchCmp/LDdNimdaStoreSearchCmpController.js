({
    init: function(component, event, helper) {
        helper.init(component);
    },
    handleGetStores: function(component, event, helper) {
        component.set("v.currentStep", component.get("v.STEP_SEARCH_STORE"));
    },        
    handleStepChange: function(component, event, helper) {
        var currentStep = component.get("v.currentStep");
        switch (currentStep) {
            case component.get("v.STEP_SEARCH_STORE"): 
                helper.handleGetAllStores(component);            
                break;                          
            default:
                break;
        }
    },
    handleStoreChange: function(component, event, helper) {
        var item = event.currentTarget;
        var selectedValue = '';
        if (item && item.dataset) {
            selectedValue = item.dataset.value;
        }    
        component.set("v.selectedStore", selectedValue);
        // fire nimda sync event
        helper.fireNimdaSyncEvent(component, component.get("v.STEP_SEARCH_STORE"), component.get("v.selectedStore"));
        // handle store detail for compact layout
        helper.handleGetStoreDetail(component);
    },      
})