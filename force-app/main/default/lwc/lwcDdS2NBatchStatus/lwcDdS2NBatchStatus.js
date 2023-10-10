import { api, LightningElement } from 'lwc';
import getProgress from "@salesforce/apex/CDdS2NBypassToolUploaderController.getProgress";
import getImportMessages from "@salesforce/apex/CDdS2NBypassToolUploaderController.getImportMessages";


// Import Custom Label
import importStatus from '@salesforce/label/c.DDS2N_BatchStatus_ImportStatus';
import importProgress from '@salesforce/label/c.DDS2N_BatchStatus_ImportProgress';
import progressSubmitted from '@salesforce/label/c.DDS2N_BatchStatus_ProgressIndicator_Submitted';
import progressHolding from '@salesforce/label/c.DDS2N_BatchStatus_ProgressIndicator_Holding';
import progressQueued from '@salesforce/label/c.DDS2N_BatchStatus_ProgressIndicator_Queued';
import progressPreparing from '@salesforce/label/c.DDS2N_BatchStatus_ProgressIndicator_Preparing';
import progressProcessing from '@salesforce/label/c.DDS2N_BatchStatus_ProgressIndicator_Processing';
import progressCompleted from '@salesforce/label/c.DDS2N_BatchStatus_ProgressIndicator_Completed';
import batchProgress from '@salesforce/label/c.DDS2N_BatchStatus_BatchProgress';
import importResults from '@salesforce/label/c.DDS2N_BatchStatus_ImportResults';
import muleError from '@salesforce/label/c.DDS2N_BatchStatus_MulesoftErrors';
import batchStatusCompleted from '@salesforce/label/c.DDS2N_BatchStatus_CompletedSuccessfully';

export default class LwcDdS2NBatchStatus extends LightningElement {

    batchId;
    get showBatchStatus() {
        console.log('this.batchId: ', this.batchId);
        return this.batchId != null;
    }

    importStatus;
    currentStep = 'submitted';
    progressValue = 0;
    importMessages = '';
    progress;
    hasError = false;

    label = {
        importStatus, importProgress, progressSubmitted, progressHolding,
        progressQueued, progressPreparing, progressProcessing, progressCompleted,
        batchProgress, importResults, muleError, batchStatusCompleted
    }

    @api
    reset() {
        this.batchId = null;
        this.currentStep = 'submitted';
        this.progressValue = 0;
        this.importMessages = '';
        clearInterval(this.progress);
    }

    @api
    startPolling(batchId) {
        let that = this;
        this.batchId = batchId;
        console.log('startPolling');
        
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.progress = setInterval(() => {
            getProgress({batchId: that.batchId})
                .then(asyncApexJob => {
                    that.importMessages = new Date().toISOString() + ": " + JSON.stringify(asyncApexJob);

                    if(["Aborted", "Failed", "Completed"].includes(asyncApexJob.Status)) {
                        clearInterval(that.progress);
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
                    clearInterval(that.progress);
                    that.processApiErrors(e);
                })
        }, 3000)
    }

    processApiErrors(e) {
        console.log(e);
        console.error("processApiErrors: " + JSON.stringify(e, null, 2));
    }

    handleImportMessages(asyncApexJob) {
        getImportMessages()
            .then(errors => {
                let elem = this.template.querySelector('[data-id="importMessages"]');
                let importMessage = '';
                console.log('errors', errors);
                if(errors.length > 0 || 
                    asyncApexJob.NumberOfErrors > 0 ||
                    ["Aborted", "Failed"].includes(asyncApexJob.Status)) {
                    this.hasError = true;
                    importMessage = this.label.muleError + "\n\n\r\r";

                }

                if(errors.length > 0) {
                    let i = 1;
                    for(let id in errors) {
                        importMessage += i++ + ". " + errors[id] + "\n\n";
                    }
                } else if(asyncApexJob.NumberOfErrors > 0 || ["Aborted", "Failed"].includes(asyncApexJob.Status)) {
                    importMessage += JSON.stringify(asyncApexJob);
                }else {
                    importMessage = this.label.batchStatusCompleted;
                }
                elem.innerText = importMessage;
            })
            .catch(e => {
                console.error("handleBatchErrors, e: ", e);
            });
    }

    disconnectedCallback() {
        this.reset();
    }
}