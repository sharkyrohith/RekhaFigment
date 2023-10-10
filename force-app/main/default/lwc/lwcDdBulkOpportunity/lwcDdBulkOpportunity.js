/**
 * Created by Jeremy S. Johnson (Perficient, Inc)
 *
 * Implements BZAP-7037: "Bulk Creation Opportunities" button and batch job
 * Implements BZAP-7046: Batch Job "Retry" Process and GridBuddy button
 */
import {LightningElement, track, api} from 'lwc';
import execute from "@salesforce/apex/CDdBulkOpportunityController.execute";
import getProgress from "@salesforce/apex/CDdBulkOpportunityController.getProgress";
import getImportMessages from "@salesforce/apex/CDdBulkOpportunityController.getImportMessages";

export default class LwcDdBulkOpportunity extends LightningElement {
    @api recordId;
    @track importStatus = "";
    @track batchId = "";
    @track activeSections = [];
    @track currentStep = "submitted";
    @track hasError = false;
    @track progressValue = 0;

//    connectedCallback() {
    handleExecute() {
        console.log("connectedCallback");
        this.template.querySelector('[data-id="btnExecute"]').disabled = true;
        let oppId = new URL(window.location.href).searchParams.get("oppId");
        let ids = new URL(window.location.href).searchParams.get("id");
        let that = this;
        console.log("oppId: " + oppId);
        console.log("accountIds: " + ids);
        execute({ oppId : oppId, accountIds : ids })
            .then(batchId => {
                that.batchId = batchId;
                that.importStatus = "Your request has been submitted for batch processing. Batch Id: " + batchId + '. You do not need to keep this window open. Results will be sent via email when the job completes.';
                that.handleOnLoad();
            })
            .catch(error => {
                console.error(error);
            })
    }

    handleOnLoad() {
        console.log("handleOnLoad");
        let that = this;
        let progress = setInterval(function() {
            getProgress({batchId: that.batchId})
                .then(asyncApexJob => {
                    console.log(JSON.stringify(asyncApexJob));
                    that.importMessages = new Date().toISOString() + ": " + JSON.stringify(asyncApexJob);

                    if(["Aborted", "Failed", "Completed"].includes(asyncApexJob.Status)) {
                        clearInterval(progress);
                        that.currentStep = "completed";
                        that.progressValue = 100;
                        that.handleImportMessages(asyncApexJob);

                    } else {
                        that.currentStep = asyncApexJob.Status.toLowerCase();
                        if(asyncApexJob.TotalJobItems > 0) {
                            that.progressValue = asyncApexJob.JobItemsProcessed / asyncApexJob.TotalJobItems * 100;
                        }
                    }
                })
                .catch(e => {
                    clearInterval(progress);
                    console.error('getProgress.catch(e): ' + JSON.stringify(e));
                })
        }, 1000)
    }

    handleImportMessages(asyncApexJob) {
        console.log("handleImportMessages")
        getImportMessages({})
            .then(batchMessages => {
                let messages = "";

                if(batchMessages.length > 0 || asyncApexJob.NumberOfErrors > 0 || ["Aborted", "Failed"].includes(asyncApexJob.Status)) {
                    messages = "One or more errors occurred during batch processing. Opportunities that encountered errors must be resolved and resubmitted.\n\n";
                    this.hasError = true;
                    this.toggleTheme(["importMessages"], false);
                }

                let i = 1;
                let elem = this.template.querySelector('[data-id="importMessages"]');
                if(batchMessages.length > 0) {
                    for(let id in batchMessages) {
                        messages += (i++) + ". " + batchMessages[id] + "\n\n";
                    }
                    elem.innerText = messages;

                } else if(asyncApexJob.NumberOfErrors > 0 || ["Aborted", "Failed"].includes(asyncApexJob.Status)) {
                    elem.innerText = messages + JSON.stringify(asyncApexJob);

                } else {
                    this.toggleTheme(["importMessages"], true);
                }
            })
            .catch(e => {
                console.error("handleImportMessages, e: " + e);
            });
    }

    toggleTheme(ids, success) {
        for(let id in ids) {
            let elem = this.template.querySelector('[data-id="' + ids[id] + '"]');
            if(success === null) {
                elem.classList.remove("slds-theme_error");
                elem.classList.remove("slds-theme_success");
            } else if (success) {
                elem.classList.remove("slds-theme_error");
                elem.classList.add("slds-theme_success");
            } else {
                elem.classList.remove("slds-theme_success");
                elem.classList.add("slds-theme_error");
            }
        }
    }
}