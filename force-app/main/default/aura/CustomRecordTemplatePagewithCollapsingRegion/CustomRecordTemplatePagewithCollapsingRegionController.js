({
    doInit: function(component, event, helper) {
        if (window.location.href.indexOf('flexipageEditor/surface.app') !== -1) {
            component.set("v.isLivePage",false);
        }
    },
    toggleLeftSidebar : function(component, event, helper) {
        component.set('v.isLeftSidebarCollapsed', !component.get('v.isLeftSidebarCollapsed'));
    },
    handleVisibility : function(component, event) {
        try{
            let visibility = event.getParam("visibility");
            let region = event.getParam("region");
            let isLeftSidebarCollapsed = component.get('v.isLeftSidebarCollapsed');
            if(visibility == "hide" && region == "sidebarLeft") {
                component.set("v.isLeftSidebarCollapsed", true);
            }
            else if(visibility == "show" && region == "sidebarLeft" && isLeftSidebarCollapsed){
                component.set("v.isLeftSidebarCollapsed", false);
            }
        }catch(err){
            console.log('Following error occured while trying to hide sections in the page: '+err.message);
        }
    },
    toggleQuickViewPanel: function(component, event, helper) {
        component.set('v.isQuickviewCollapsed', !component.get('v.isQuickviewCollapsed'));
    },
})