({
	doInit : function(component, event, helper) {
        var pageRef = component.get("v.pageReference");
        var id = pageRef.state.c__id;
        component.set("v.id",id);
		console.log('myValue++'+id);     
	}
})