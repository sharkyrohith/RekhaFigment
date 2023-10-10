/**
 * Created by Jeremy S. Johnson, Perficient, Inc.
 */

({
    handleInit: function(cmp, event) {
        this.defineColumns(cmp);
        this.handleError(cmp, null);
        let action = cmp.get("c.getChecklist");
        this.enqueueAction(cmp, event, action);
    },

    handleChecks: function(cmp, event) {
        event.getSource().set("v.disabled", true);
        this.handleError(cmp, null);
        let action = cmp.get("c.validate");
        this.enqueueAction(cmp, event, action);
    },

    enqueueAction: function(cmp, event, action) {
        this.toggleSpinner(cmp);
        action.setParams({caseId : cmp.get("v.recordId")});
        action.setCallback(this, function(response) {
            event.getSource().set("v.disabled", false);
            this.toggleSpinner(cmp);
            if(response.getState() === "SUCCESS") {
                this.handleGridUpdate(cmp, event, response.getReturnValue());
            } else {
                this.handleError(cmp, response.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },

    handleSave: function(cmp, event) {
        console.log('handleSave');
        this.toggleSpinner(cmp);
        let updates = event.getParam("draftValues");
        let action = cmp.get("c.resolveItems");
        action.setParams({caseId : cmp.get("v.recordId"), items : updates});
        action.setCallback(this, function(response) {
            this.toggleSpinner(cmp);
            if(response.getState() === "SUCCESS") {
                $A.get("e.force:refreshView").fire();
                this.handleGridUpdate(cmp, event, response.getReturnValue());
            } else {
                this.handleError(cmp, response.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
        cmp.find("dataTable").set("v.draftValues", null);
    },

    defineColumns: function(cmp) {
        cmp.set("v.columns", [
            {label: "Target",       fieldName: "Target__c",        type: "text",     initialWidth: 130, editable: false, wrapText: true},
            {label: "Validation",   fieldName: "Name",             type: "text",     initialWidth: 275, editable: false, wrapText: true},
            {label: "Status",       fieldName: "Status__c",        type: "text",     initialWidth: 80,  editable: false, wrapText: true, cellAttributes: { class: {"fieldName": "showClass"}}},
            {label: "Result",       fieldName: "Result__c",        type: "text",     initialWidth: 400, editable: false, wrapText: true, cellAttributes: { class: {"fieldName": "showClass"}}},
            {label: "Resolved",     fieldName: "Resolved__c",      type: "boolean",  initialWidth: 80,  editable: true, wrapText: true},
            {label: "Last Ran",     fieldName: "Date_Time_Ran__c", type: "date",     initialWidth: 300, editable: false, wrapText: true,
                typeAttributes:{
                    year: "numeric",
                    month: "long",
                    day: "2-digit",
                    hour: "2-digit",
                    minute: "2-digit"
                }
            }
        ]);
    },

    handleGridUpdate: function(cmp, event, records) {
        console.log('handleGridUpdate');
        let passing = 0;
        let warning = 0;
        let failing = 0;
        let ignoring = 0;
        records.forEach(function(record) {
            if(record.Status__c === "Pass" || record.Resolved__c === true) {
                record.showClass = "pass";
                if(record.Resolved__c === true) {
                    ignoring += 1;
                } else {
                    passing += 1;
                }
            } else if(record.Status__c === "Warn") {
                record.showClass = "warn";
                warning += 1;
            } else if(record.Status__c === "Fail") {
                record.showClass = "fail";
                failing += 1;
            }
        });
        cmp.set("v.data", records);
        cmp.set("v.passing", passing);
        cmp.set("v.warning", warning);
        cmp.set("v.failing", failing);
        cmp.set("v.ignoring", ignoring);
    },

    handleError: function(cmp, message) {
        console.log('handleError');
        let elem = cmp.find("errorMessageCnt");
        cmp.set("v.errorMsg", message);

        if(message === null) {
            $A.util.addClass(elem, "slds-is-collapsed");
        } else {
            $A.util.removeClass(elem, "slds-is-collapsed");
        }
    },

    toggleSpinner: function(cmp) {
        console.log('toggleSpinner');
        let spinner = cmp.find("aSpinner");
        $A.util.toggleClass(spinner, "slds-hidden");
    },
});