/**
 * Happy path scenario:
 *     1) Display MS Sync Stages option group
 *     2) Display file selector
 *     3) Call server-side controller to parse the CSV file
 *     4) Display parsing results as a data-table along with warnings and errors, if any
 *     5) Display import button if no errors
 *     6) Call server-side controller to import
 *     7) Display batch start notification
 */

/* eslint-disable @lwc/lwc/no-async-operation */
/* eslint-disable vars-on-top */
import { api, LightningElement, track } from "lwc";
import Id from "@salesforce/user/Id";
import uploadCsv from "@salesforce/apex/CDdUploaderController.uploadCsv";
import importCsv from "@salesforce/apex/CDdUploaderController.importCsv";
import getProgress from "@salesforce/apex/CDdUploaderController.getProgress";
import getImportMessages from "@salesforce/apex/CDdUploaderController.getImportMessages";

// Import custom label
import fileInfo from '@salesforce/label/c.DDS2N_Uploader_SelectedFile';
import tablePreview from '@salesforce/label/c.DDS2N_Uploader_Preview';
import tableUploadResults from '@salesforce/label/c.DDS2N_Uploader_UploadResults';
import importButton from '@salesforce/label/c.DDS2N_Uploader_Import';
import resetButton from '@salesforce/label/c.DDS2N_Uploader_Reset';
import importStatus from '@salesforce/label/c.DDS2N_Uploader_ImportStatus';
import importProgress from '@salesforce/label/c.DDS2N_Uploader_ImportProgress';
import progressSubmitted from '@salesforce/label/c.DDS2N_Uploader_ProgressIndicator_Submitted';
import progressHolding from '@salesforce/label/c.DDS2N_Uploader_ProgressIndicator_Holding';
import progressQueued from '@salesforce/label/c.DDS2N_Uploader_ProgressIndicator_Queued';
import progressPreparing from '@salesforce/label/c.DDS2N_Uploader_ProgressIndicator_Preparing';
import progressProcessing from '@salesforce/label/c.DDS2N_Uploader_ProgressIndicator_Processing';
import progressCompleted from '@salesforce/label/c.DDS2N_Uploader_ProgressIndicator_Completed';
import batchProgress from '@salesforce/label/c.DDS2N_Uploader_BatchProgress';
import importResult from '@salesforce/label/c.DDS2N_Uploader_ImportResults';
import rowErr from '@salesforce/label/c.DDS2N_Uploader_Row';
import colErr  from '@salesforce/label/c.DDS2N_Uploader_Column';
import errorErr from '@salesforce/label/c.DDS2N_Uploader_Error';
import importReady from '@salesforce/label/c.DDS2N_Uploader_FileImportReady';
import fileContainsError from '@salesforce/label/c.DDS2N_Uploader_FileContainsError';
import batchSubmitted from '@salesforce/label/c.DDS2N_Uploader_BatchSubmitted';
import muleError from '@salesforce/label/c.DDS2N_Uploader_MulesoftError';
import rowError from '@salesforce/label/c.DDS2N_Uploader_RowError';
import fileError from '@salesforce/label/c.DDS2N_Uploader_FileError';
import unexpectedError from '@salesforce/label/c.DDS2N_Uploader_UnexpectedError';
import batchSize from '@salesforce/label/c.DDS2N_Uploader_BatchSize';
import fileInstructions from '@salesforce/label/c.DDS2N_Uploader_FileInstructions';
import uploadButton from '@salesforce/label/c.DDS2N_Uploader_UploadButton';

export default class LwcDdUploader extends LightningElement {
    csvStr;

    @api
    msSyncStage;

    @track userId = Id.toString();
    @track filename = "";
    @track uploadMessages = "";
    @track importStatus = "";
    @track importMessages = "";
    @track batchId = "";
    @track columns = [{}];
    @track data = [{}];
    @track errors = [{}];
    @track currentStep = "submitted";
    @track hasError = false;
    @track progressValue = 0;
    @track batchSize = 25;

    label = {
        fileInfo, tablePreview, tableUploadResults, importButton, resetButton,
        uploadButton, importStatus, importProgress, progressSubmitted, progressHolding,
        progressQueued, progressPreparing, progressProcessing, progressCompleted,
        batchProgress, importResult, rowErr, colErr, errorErr, importReady, fileContainsError,
        batchSubmitted, muleError, rowError, fileError, unexpectedError, batchSize,
        fileInstructions
    };

    /**
     * Take the uploaded CSV string and submit it to the server for parsing and validation.
     *
     * @param event
     */
    handleUpload(event) {
        console.log('handleUpload');
        this.toggleSpinner();

        let that = this;
        let file = event.target.files[0];

        if (file) {
            this.filename = file.name;
            let reader = new FileReader();

            reader.onload = function(event) {
                let csv = event.target.result;
                that.csvStr = csv;
                that.uploadCsv();
            };

            reader.onerror = function(evt) {
                console.log('handleUpload, evt: ' + evt);
                that.processApiErrors(evt);
            };

            reader.readAsText(file);
        }
    }

    /**
     * Clear previous values so onchange will fire if selecting the same file again
     * @param event
     */
    handleUploadClick(event) {
        event.target.value = null;
        let elems = ["dataTable", "uploadMessages", "importResetDiv", "importButton", "resetButton"];
        this.toggleExpanded(elems, false);
        this.toggleDisabled(elems, false);
    }

    /**
     * Push the CSV to the server for parsing and validation. Return a CDdUploaderContext object.
     */
    uploadCsv() {
        console.log("uploadCsv");
        uploadCsv({ csv : this.csvStr, userId : this.userId, msSyncStage : this.msSyncStage, filename : this.filename })
            .then(ctx => {
                console.log("uploadCsv, ctx: " + ctx);
                let json = JSON.parse(JSON.stringify(ctx));
                this.setUploadMessages(json);

                let columns = [];
                for (let key in json.columns) {
                    let column = json.columns[key];
                    columns.push({label: column, fieldName: column, type: 'text', editable: true})
                }

                this.columns = columns;
                this.data = JSON.parse(JSON.stringify(ctx.dataTable));   //dataTable is already JSON
                this.errors = this.generateErrorsObj(ctx);

                this.toggleExpanded([ "dataTable", "importResetDiv" ], true);

                if(ctx.csv.isImportable) { //Keep importButton disabled if the file is not importable.
                    this.toggleDisabled([ "importButton", "resetButton" ], false);
                } else {
                    this.toggleDisabled([ "importButton" ], true);
                    this.toggleDisabled([ "resetButton" ], false);
                }

                this.toggleSpinner();
            })
            .catch(e => {
                console.log("uploadCsv, e: " + e);
                this.processApiErrors(e);
            })
    }

    /**
     * Format validation messages and display them in the uploadMessages text area.
     * @param ctx
     */
    setUploadMessages(ctx) {
        console.log(ctx.csv);
        let messages = ctx.csv.numRows + " " + this.label.rowErr + ", "
            + ctx.csv.numCols + " " + this.label.colErr + ", "
            + ctx.csv.numErrors + " " + this.label.errorErr + ".\n";

        if(ctx.csv.isImportable) {
            messages = this.label.importReady + " " + messages;

            this.toggleTheme(["uploadMessagesDiv"], true);

        } else {
            messages = this.label.fileContainsError + " " + messages;

            let i = 1;
            for(let key in ctx.csv.csvErrors) {
                messages += (i++) + ". " + ctx.csv.csvErrors[key] + "\n";
            }

            for(let key in ctx.csv.rowErrors) {
                let row = ctx.csv.rowErrors[key];
                for(let msg in row.messages) {
                    messages += (i++) + ". " + row.messages[msg] + "\n";
                }
            }

            this.toggleTheme(["uploadMessagesDiv"], false);
        }

        if(messages !== "") {
            this.template.querySelector('[data-id="uploadMessagesDiv"]').innerText = messages;
            this.toggleExpanded([ "uploadMessages" ], true);
        }
    }

    handleSliderChange(event) {
        this.batchSize = event.target.value;
    }

    /**
     * Submit the import for batch processing. Controller returns a batchId and reports results to Chatter.
     */
    handleImport(event) {
        event.target.disabled = true;
        this.toggleDisabled([
            "dataTable",
            "fileSelectorInput",
            "uploadMessages"
        ], true);
        this.toggleSpinner();

        importCsv({ userId : this.userId, batchSize : this.batchSize })
            .then(batchId => {
                this.batchId = batchId;
                this.importStatus = this.label.batchSubmitted + ": " + batchId;
                this.template.querySelector('[data-id="importMessages"]').innerHTML = "";
                this.toggleExpanded([ "importStatus" ], true);
                this.toggleSpinner();

                let that = this;
                let progress = setInterval(function() {
                    getProgress({batchId: batchId})
                        .then(asyncApexJob => {
                            that.template.querySelector('[data-id="importMessages"]').innerText = new Date().toISOString() + ": " + JSON.stringify(asyncApexJob);;

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
                            this.processApiErrors(e);
                        })
                }, 3000)

            })
            .catch(e => {
                this.processApiErrors(e);
            })
    }

    handleImportMessages(asyncApexJob) {
        getImportMessages({userId : this.userId})
            .then(errors => {
                let messages = "";
                let elem = this.template.querySelector('[data-id="importMessages"]');

                if(errors.length > 0 || asyncApexJob.NumberOfErrors > 0 || ["Aborted", "Failed"].includes(asyncApexJob.Status)) {
                    messages = this.label.muleError + "\n\n";
                    this.hasError = true;
                    this.toggleTheme(["importMessages"], false);
                }

                if(errors.length > 0) {
                    let i = 1;
                    for(let id in errors) {
                        messages += i++ + ". " + errors[id] + "\n\n";
                    }
                    elem.innerText = messages;

                } else if(asyncApexJob.NumberOfErrors > 0 || ["Aborted", "Failed"].includes(asyncApexJob.Status)) {
                    elem.innerText = messages + JSON.stringify(asyncApexJob);

                } else {
                    this.toggleTheme(["importMessages"], true);
                }
            })
            .catch(e => {
                console.error("handleBatchErrors, e: " + e);
            });
    }

    handleReset() {
        this.toggleExpanded([
            "dataTable",
            "importButton",
            "importStatus",
            "importResetDiv",
            "resetButton",
            "uploadMessages",
            "progressIndicator"
        ], false);
        this.toggleDisabled([
            "dataTable",
            "fileSelectorInput",
            "importButton",
            "importStatus",
            "importResetDiv",
            "resetButton",
            "uploadMessages"
        ], false);
        this.toggleTheme(["importMessages"], null)
        this.uploadMessages = "";
        this.template.querySelector('[data-id="importMessages"]').innerText = "";
        this.filename = "";
        this.columns = [{}];
        this.data = [{}];
        this.hasError = false;
        this.progressValue = 0;
        this.currentStep = 'submitted';
    }

    processApiErrors(e) {
        console.error("processApiErrors: " + JSON.stringify(e, null, 2));
        this.toggleTheme(["uploadMessagesDiv"], false);
        this.toggleDisabled(["importButton"], true);
        this.toggleExpanded(["uploadMessages", "importResetDiv", "importButton", "resetButton"], true);
        this.uploadMessages = this.label.unexpectedError;
        this.toggleSpinner();
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

    toggleSpinner() {
        this.template.querySelector('[data-id="spinner"]').classList.toggle("slds-hidden");
    }

    toggleExpanded(ids, expanded) {
        for(let id in ids) {
            let elem = this.template.querySelector('[data-id="' + ids[id] + '"]');
            if(expanded) {
                elem.classList.remove("slds-is-collapsed");
                elem.classList.add("slds-is-expanded");
                elem.classList.add("slds-m-top_medium");
            } else {
                elem.classList.remove("slds-is-expanded");
                elem.classList.remove("slds-m-top_medium");
                elem.classList.add("slds-is-collapsed");
            }
        }
    }

    toggleDisabled(ids, disabled) {
        for(let id in ids) {
            let elem = this.template.querySelector('[data-id="' + ids[id] + '"]');
            elem.disabled = disabled;
        }
    }

    generateErrorsObj(ctx) {
        let errors = {};
        errors.rows = {};
        errors.table = {};

        for(let id in ctx.csv.rowErrors) {
            let row = ctx.csv.rowErrors[id];
            let messages = [];
            let fieldNames = [];

            for(let fld in row.fieldNames) {
                fieldNames.push(row.fieldNames[fld]);
            }

            for(let msg in row.messages) {
                messages.push(row.messages[msg]);
            }

            errors.rows[id] = { title : this.label.rowError, fieldNames: fieldNames, messages: messages };
        }

        let tableMessages = []
        for(let id in ctx.csv.csvErrors) {
            tableMessages.push(ctx.csv.csvErrors[id]);
        }
        if(tableMessages.length > 0) {
            errors.table = { title: this.label.fileError, messages: tableMessages };
        }

        return errors;
    }
}