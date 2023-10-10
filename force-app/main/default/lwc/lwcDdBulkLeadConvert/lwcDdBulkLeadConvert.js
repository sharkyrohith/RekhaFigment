/**
 * Created by Jeremy S. Johnson, Perficient, Inc. on 3/14/2020.
 * A window overlay for performing bulk lead conversions from GridBuddy
 */
import {LightningElement, track} from 'lwc';
import bulkConvertLeads from "@salesforce/apex/CDdBulkLeadConvertController.bulkConvertLeads";
import getProgress from "@salesforce/apex/CDdBulkLeadConvertController.getProgress";
import getImportMessages from "@salesforce/apex/CDdBulkLeadConvertController.getImportMessages";

export default class LwcDdBulkLeadConvert extends LightningElement {
    @track importStatus = "";
    @track batchId = "";
    @track activeSections = [];
    @track currentStep = "submitted";
    @track hasError = false;
    @track progressValue = 0;

    connectedCallback() {
        console.log("connectedCallback");
        let ids = new URL(window.location.href).searchParams.get("id");
        let that = this;
        bulkConvertLeads({ ids : ids, batchSize : 1 })
            .then(batchId => {
                that.batchId = batchId;
                that.importStatus = "Your request has been submitted for batch processing. Batch Id: " + batchId + '. Results will be sent via email when the job completes.';
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
                    messages = "One or more errors occurred during batch processing. Leads that encountered errors must be resolved and resubmitted.\n\n";
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