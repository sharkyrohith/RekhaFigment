({
    doInit : function(component, event, helper) {
       helper.initTemplates(component, event, helper);
    },
    getTemplates : function(component, event, helper) {
        //var val = component.get("v.ntVal");
        var val = "";
        if (event.target.value){
            val = event.target.value;
        }
        helper.searchTerm(component, event, val);
    },
    onBlur : function(component, event, helper) {
        window.setTimeout(
            $A.getCallback(function() {
                component.set('v.noteTemplateFilteredList', []);
            }),
            300
        );
        
    },
    clearSearch : function(component,event,helper) {
        helper.clearSelection(component, event, helper);
    },
    selectTemplate : function(component, event, helper) {
        var selectedItem = event.currentTarget.id;
        helper.setSelectedTemplate(component, event, helper, selectedItem);
    },
    postNotes : function(component, event, helper) {
        helper.saveNotes(component, event, helper);
    }
    
})