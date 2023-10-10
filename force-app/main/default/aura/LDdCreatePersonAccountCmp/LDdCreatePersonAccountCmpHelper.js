({
    back : function(component) {        
        var navEvt = $A.get("e.force:navigateToSObject");
    	navEvt.setParams({
      		"recordId": component.get("v.recordId")
    	});
    	navEvt.fire();
	}
})