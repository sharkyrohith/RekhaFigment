({
    initTemplates : function(component,event,helper) {
        helper.spinnerOn(component);
        var action = component.get("c.getTemplateOptions");
        action.setCallback(this, function(response) {
            var state = response.getState();
            helper.spinnerOff(component);
            if (state === "SUCCESS") {
                var responseValue = response.getReturnValue();
                component.set("v.noteTemplateList" , responseValue);
                component.set("v.ntVal" , "");

            }           
        });
        $A.enqueueAction(action);
    },
    setSelectedTemplate : function(component,event,helper,selectedItem) {
        var list = component.get("v.noteTemplateList");
        list.forEach(function(elem) {
            if (elem.Id == selectedItem){
                component.set("v.noteTemplate", elem);
                component.set("v.ntVal", elem.Name);
                component.set("v.ntBody", elem.Body__c);
                component.set('v.noteTemplateFilteredList', []);
            }
        });
    },
    clearSelection : function(component,event,helper) {
        component.set("v.ntVal", "");
        component.get('v.noteTemplateFilteredList', []);
    },
    saveNotes : function(component,event,helper) {
        helper.spinnerOn(component);
        var nt = component.get("v.noteTemplate");
        var ntName = "";
        if (nt.Name){
            ntName = nt.Name;
        }
        var body = component.get("v.ntBody");
        body = body.replaceAll ("<br>", "<p>&nbsp;</p>")
                   .replaceAll("<br/>", "<p>&nbsp;</p>")
                   .replaceAll ("<br />", "<p>&nbsp;</p>")
                   .replaceAll ("<strong>", "<b>")
                   .replaceAll ("</strong>", "</b>")
                   .replaceAll ("<em>", "<i>")
                   .replaceAll ("</em>", "</i>");
        var caseId = component.get("v.recordId");
        var action = component.get("c.postFeed");
        action.setParams({ body: body, caseId: caseId, templateName: ntName });
        action.setCallback(this, function(response) {
            helper.spinnerOff(component);
            var state = response.getState();
            if (state === "SUCCESS") {
                helper.showToast(component, 'success', 'Success', "Your case notes have been submitted.");
                component.set("v.ntVal", "");
                component.set("v.ntBody", "");
                component.set("v.noteTemplate", {});
            } else {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        helper.showToast(component, 'error', 'Error', errors[0].message);
                    } else if (errors[0] && errors[0].pageErrors[0]) {
                        helper.showToast(component, 'error', 'Error', errors[0].pageErrors[0].message);
                    }
                } else {
                    helper.showToast(component, 'error', 'Error', "Unknown error");
                }
            }          
        });
        $A.enqueueAction(action);
    },
    searchTerm : function(component,event,searchTerm) {
        var list = component.get("v.noteTemplateList");
        if (searchTerm === "") {
            component.set("v.noteTemplateFilteredList", list);
        } else {
            var selectedList = list.filter(function(elem) {
                return elem.Name.toLowerCase().includes(searchTerm.toLowerCase());
            });
            component.set("v.noteTemplateFilteredList", selectedList);
        }
        component.set("v.ntVal", searchTerm);
    },
    showToast : function(component, type, title, msg) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type": type,
            "title": title,
            "message": msg
        });
        toastEvent.fire();
    },
    spinnerOn : function(component) {
        var spinner = component.find("pageSpinner");
        if (spinner){
        	$A.util.removeClass(spinner, "slds-hide");
        }
    },
    spinnerOff : function(component) {
        var spinner = component.find("pageSpinner");
        if (spinner){
        	$A.util.addClass(spinner, "slds-hide");
        }
    }
})