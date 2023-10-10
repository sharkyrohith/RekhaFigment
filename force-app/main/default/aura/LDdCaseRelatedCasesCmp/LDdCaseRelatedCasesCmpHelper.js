({
    handleInit: function(component, event, helper) {
        var recPage = component.get("v.RecordPerPage");
        helper.getRecords(component, event, helper, recPage);
    },
    defineColumns: function(component, cols) {
        var columns = [];
        cols.forEach(function(col){
            var colDef = {  label: col.label,
                            fieldName: col.name,
                            type: col.type,
                            cellAttributes:{
                                class: {
                                    fieldName: 'highlightstyle'
                                }
                            }
                        };
            if (col.name === "CaseNumber"){
                colDef = {  label: col.label,
                            fieldName: "caseLink",
                            type: "url",
                            typeAttributes: {
                                target: '_self',
                                label: {
                                    fieldName : col.name
                                }},
                            cellAttributes: {
                                class: {
                                    fieldName: 'highlightstyle'
                                }
                            }
                        };
            }
            if (col.type === "DATETIME"){
                colDef = {  label: col.label,
                            fieldName: col.name,
                            type: 'date',
                            typeAttributes: {
                                day: 'numeric',
                                month: 'short',
                                year: 'numeric',
                                hour: '2-digit',
                                minute: '2-digit',
                                second: '2-digit',
                                hour12: true
                            },
                            cellAttributes: {
                                class: {
                                    fieldName: 'highlightstyle'
                                }
                            }
                        }
            }
            columns.push(colDef);
        });

        var mergeButton = component.get("v.MergeButton");
        if (mergeButton){
            columns.push({  type: "button",
                            label:"Actions",
                            typeAttributes: {
                                label: 'Merge',
                                name: 'merge',
                                title: 'Merge',
                                disabled: false,
                                value: 'merge',
                                iconPosition: 'left'
                            },
                            cellAttributes:{
                                class: {
                                    fieldName: 'highlightstyle'
                                }
                            }
                        });
        }
        component.set("v.columns", columns);
    },
    loadMoreRecords: function(component, event, helper) {
        var numRec = component.get("v.NoOfRecords");
        var recPage = component.get("v.RecordPerPage");
        helper.getRecords(component, event, helper, numRec + recPage);
    },
    getRecords : function(component, event, helper, numRec) {
        let action = component.get("c.getRelatedCases");
        action.setParams({ relatedField: component.get("v.relatedField"), caseId : component.get("v.recordId"), fields: component.get("v.fields"), numRec : numRec, addFilter : component.get("v.additionalFilter")});
        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                var res = response.getReturnValue();
                component.set("v.currentCase", res.currentCase);
                this.defineColumns(component, res.fieldList);
                for (var i = 0; i < res.caseList.length; i++) {
                    res.caseList[i].caseLink = "/" + res.caseList[i].Id;
                    var currentDate = new Date();
                    var createdDate = new Date(res.caseList[i].CreatedDate);
                    //Highlighted cases created in last 24 hours
                    if((currentDate.getTime() - createdDate.getTime())/3600000 <= 24){
                        res.caseList[i].highlightstyle = 'slds-theme_warning';
                    }
                }
                component.set("v.data", res.caseList);
                component.set("v.NoOfRecords", res.caseList.length);
                if (res.caseList.length < numRec){
                    var btn = component.find("loadMoreBtn");
                    if (btn){
                        $A.util.addClass(btn, "slds-hide");
                    }

                }
            } else {
                console.error(response.getState());
            }
        });

        $A.enqueueAction(action);
    },
    treatRecordAction : function(component, event, helper, row, actionName) {
        if (actionName == "merge"){
            component.set("v.selectedRow", row);
            component.set("v.isModalOpen", true);
        }
    },
    performMergeCases : function(component, event, helper){
        var action = component.get("c.mergeCases");
        action.setParams({ caseId : component.get("v.recordId"), parentCaseId: component.get("v.selectedRow").Id});
        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                var res = response.getReturnValue();
                helper.showToast(component, 'success', 'Success', "Your cases were merged");
            } else {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        helper.showToast(component, 'error', 'Error', errors[0].message);
                    }
                } else {
                    helper.showToast(component, 'error', 'Error', "Unknown error");
                }
            }
        });

        $A.enqueueAction(action);
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
})