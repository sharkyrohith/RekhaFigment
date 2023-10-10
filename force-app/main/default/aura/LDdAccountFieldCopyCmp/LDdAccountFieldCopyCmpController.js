({
    init: function(component, event, helper) {
    	helper.init(component);
        if (!($A.util.isEmpty(component.get("v.selectedIds")))){
			helper.copyFields(component
        		, function(result) {
        			helper.showToast(component, 'success', component.get("v.INFO_MSG_BATCH_JOB_SUBMITTED").replace('{0}', result));
        		}
	        	, function(error) {
	        		if (error.message){
	        			helper.showToast(component, 'error', error.message); 
	        		}
	        	}
	        );	
        } else {
        	helper.showToast(component, 'warning', component.get("v.INFO_MSG_NO_RECORD_SELECTED")); 
        }    	
    },
})