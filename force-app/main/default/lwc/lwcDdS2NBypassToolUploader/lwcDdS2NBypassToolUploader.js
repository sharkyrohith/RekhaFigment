/* eslint-disable guard-for-in */
import { api, LightningElement, track, wire } from 'lwc';
import Id from "@salesforce/user/Id";
import FORM_ERROR_MESSAGE from "@salesforce/label/c.Bypass_Bulk_Store_Update_Form_Error_Msg"
import uploadCsv from "@salesforce/apex/CDdS2NBypassToolUploaderController.uploadCsv";
import importCsv from "@salesforce/apex/CDdS2NBypassToolUploaderController.importCsv";
import getWarningLabel from "@salesforce/apex/CDdS2NBypassToolUploaderController.getWarningLabel";
import getNimdaFields from '@salesforce/apex/CDdNimdaByPassGroupHelper.getNimdaFields';

// Import custom labels
import reasonLabel from '@salesforce/label/c.DDS2N_BypassToolUploader_InputTextLabel';
import reasonLabelValidation from '@salesforce/label/c.DDS2N_BypassToolUploader_InputTextLabel_Validation';
import overwriteCheckbox from '@salesforce/label/c.DDS2N_BypassToolUploader_CheckboxLabel';
import overwriteWarning from '@salesforce/label/c.DDS2N_BypassToolUploader_CheckboxLabel_Warning';
import fileInstructions from '@salesforce/label/c.DDS2N_BypassToolUploader_FileLabel_Info';
import fileButton from '@salesforce/label/c.DDS2N_BypassToolUploader_FileButton';
import fileInfo from '@salesforce/label/c.DDS2N_BypassToolUploader_FileLabel_Info_2';
import tablePreview from '@salesforce/label/c.DDS2N_BypassToolUploader_Preview';
import tableUploadResults from '@salesforce/label/c.DDS2N_BypassToolUploader_UploadResults';
import importButton from '@salesforce/label/c.DDS2N_BypassToolUploader_Import_Button';
import resetButton from '@salesforce/label/c.DDS2N_BypassToolUploader_Reset_Button';
import settingAccordion from '@salesforce/label/c.DDS2N_BypassToolUploader_Accordion_Settings_Label';
import maxFileError from '@salesforce/label/c.DDS2N_BypassToolUploader_MaxFileSize_Error';
import batchRequest from '@salesforce/label/c.DDS2N_BypassToolUploader_Request_Label';
import rowError from '@salesforce/label/c.DDS2N_BypassToolUploader_Row_Error';
import fileError from '@salesforce/label/c.DDS2N_BypassToolUploader_File_Error';
import importReady from '@salesforce/label/c.DDS2N_BypassToolUploader_Import_Ready_Label';
import resetInstructions from '@salesforce/label/c.DDS2N_BypassToolUploader_ResetInstruction_Label';
import importError from '@salesforce/label/c.DDS2N_BypassToolUplaoder_Import_Error_Label';

export default class LwcDdS2NBypassToolUploader extends LightningElement {

    @api
    msSyncStage;

    @wire(getNimdaFields)
    availableFields;

    label = {
        reasonLabel, reasonLabelValidation, overwriteCheckbox,
        overwriteWarning, fileInstructions, fileButton, fileInfo,
        tablePreview, tableUploadResults, importButton, resetButton,
        settingAccordion, maxFileError, batchRequest, rowError, fileError,
        importReady, resetInstructions, importError
    }

    get shouldShowOverwrite() { 
        let showOverwrite = false;
        if (this.availableFields && this.availableFields.data ) {
            for(let key in this.availableFields.data) {
                if (this.availableFields.data[key].property === 'overwrite_partnership_values') {
                    showOverwrite = true;
                }
            }
        }
        return showOverwrite;
    }

    columns = [{}];
    csvstr;
    @track data = [{}];
    @track errors = [{}];
    filename = '';
    filesize = '';
    hasError = false;
    reason = '';
    overwritePartnership = false;
    uploadMessages = "";
    userId = Id.toString();
    isReasonDisabled = false;

    @wire(getWarningLabel)
    OVERWRITE_WARNING_LABEL
    

    /**
     * Place focus on the reason input field.
     */
    renderedCallback() {
        let reasonInput = this.template.querySelector("[data-id='reason']");
        if (reasonInput) {
            reasonInput.focus();
        }
    }

    onClickHandlerUpload(event) {
        if (!this.reason) {
            event.preventDefault();
            // eslint-disable-next-line no-alert
            alert(FORM_ERROR_MESSAGE);
        }

        event.target.value = null;
        let elems = ["dataTable", "uploadMessages", "importResetDiv",
                    "importButton", "resetButton"];
        this.toggleExpanded(elems, false);
        this.toggleDisabled(elems, false);
    }
    
    onChangeHandlerUpload(event) {
        let that = this;
        let file = event.target.files[0];
        this.toggleSpinner();

        if (file) {
            this.filename = file.name;
            this.filesize = file.size / 1024 / 1024;

            if (this.filesize > 30) {
                alert(this.label.maxFileError);
                this.toggleSpinner();
                return;
            }

            let reader = new FileReader();

            reader.onload = function(onloadEvent) {
                let csv = onloadEvent.target.result;
                that.csvStr = csv;
                that.uploadCsv();
            };

            reader.onerror = function(onErrorEvent) {
                that.processApiErrors(onErrorEvent);
            };

            reader.readAsText(file);
        }
    }

    handleImport(event) {
        event.target.disabled = true;
        this.toggleDisabled([
            "dataTable",
            "fileSelectorInput",
            "uploadMessages",
            "importButton"
        ], true);
        this.toggleSpinner();

        // Import CSV returns:
        //      batchId         - associated with the job to import the CSV data
        //      AuraException   - failure to upload file
        importCsv({ userId : this.userId, })
            .then(batchId => {
                this.batchId = batchId;
                this.importStatus = this.label.batchRequest + " : " + batchId;
                this.toggleSpinner();
                this.template.querySelector('c-lwc-dd-s-2-n-batch-status')
                    .startPolling(batchId);
            })
            .catch(e => {
                this.processApiErrors(e);
                this.toggleSpinner();
                this.handleReset();
            });
    }

    onChangeHandlerReason(event) {
        this.reason = event.target.value;
    }

    onChangeHandlerOverwrite(event) {
        this.overwritePartnership = event.target.checked;
    }

    uploadCsv() {
        uploadCsv({
            csv : this.csvStr,
            userId : this.userId,
            msSyncStage : this.msSyncStage,
            reason: this.reason,
            overwrite: this.overwritePartnership,
            filename : this.filename })
        .then(ctx => {
            let context = JSON.parse(JSON.stringify(ctx));
            this.setUploadMessages(context);
            this.setDatatable(ctx);

            this.toggleExpanded([ "dataTable", "importResetDiv" ], true);

            //Keep importButton disabled if the file is not importable.
            if(ctx.csv.isImportable) { 
                this.toggleDisabled([ "importButton", "resetButton" ], false);
                this.isReasonDisabled = true;
            } else {
                this.toggleDisabled([ "importButton" ], true);
                this.toggleDisabled([ "resetButton" ], false);
            }
            this.toggleSpinner();
        })
        .catch(e => {
            this.processApiErrors(e);
        });
    }

    setDatatable(ctx) {
        let context = JSON.parse(JSON.stringify(ctx));
        let columns = [];
        for(let key in context.columns) {
            if (Object.prototype.hasOwnProperty.call(context.columns, key)) {
                let column = context.columns[key];
                columns.push({
                    label: column,
                    fieldName: column,
                    type: 'text',
                    editable: true // needs to be true to show errors
                });
            }
        }

        this.columns = columns;
        this.data = JSON.parse(JSON.stringify(ctx.dataTable));
        this.errors = this.generateDatatableErrorsObj(ctx);
    }

    generateDatatableErrorsObj(ctx) {
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

            errors.rows[id] = {
                title : this.label.rowError,
                fieldNames: fieldNames,
                messages: messages
            };
        }

        let tableMessages = []
        for(let id in ctx.csv.csvErrors) {
            tableMessages.push(ctx.csv.csvErrors[id]);
        }
        if(tableMessages.length > 0) {
            errors.table = {
                title: this.label.fileError,
                messages: tableMessages
            };
        }

        return errors;
    }

    /**
     * Format validation messages and display them in the uploadMessages text area.
     * @param ctx
     */
    setUploadMessages(ctx) {
        console.log(ctx.csv);
        let messages = ctx.csv.numRows + " row(s), "
            + ctx.csv.numCols + " column(s), "
            + ctx.csv.numErrors + " errors(s).\n";

        if(ctx.csv.isImportable) {
            messages = this.label.importReady +
                this.label.resetInstructions + messages;
            this.toggleTheme(["uploadMessagesDiv"], true);
        } else {
            messages = this.label.importError + messages;

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

    processApiErrors(e) {
        let errorMessage;
        // This follows JSON structure of an AuraException
        if ( e.body && e.body.message) {
            errorMessage = e.body.message;
            alert(errorMessage);
        }
        console.log(e);
        console.error("processApiErrors: ", JSON.stringify(e, null, 2));
    }

    toggleExpanded(ids, expanded) {
        for(let id in ids) {
            if (Object.prototype.hasOwnProperty.call(ids, id)) {
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
    }

    toggleDisabled(ids, disabled) {
        for(let id in ids) {
            if (Object.prototype.hasOwnProperty.call(ids, id)) {
                let elem = this.template.querySelector('[data-id="' + ids[id] + '"]');
                elem.disabled = disabled;
            }
        }
    }

    toggleTheme(ids, success) {
        for(let id in ids) {
            if (Object.prototype.hasOwnProperty.call(ids, id)) {
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

    handleReset() {
        this.isReasonDisabled = false;
        this.toggleExpanded([
            "dataTable", "importButton", "importResetDiv", "resetButton",
            "uploadMessages"
        ], false);
        this.toggleDisabled([
            "dataTable", "fileSelectorInput", "importButton", "importResetDiv",
            "resetButton", "uploadMessages"
        ], false);
        // this.toggleTheme(["importMessages"], null)
        this.uploadMessages = "";
        //this.template.querySelector('[data-id="importMessages"]').innerText = "";
        this.filename = "";
        this.columns = [{}];
        this.data = [{}];
        // this.hasError = false;
        this.reason = '';
        this.template.querySelector("[data-id='reason']").value = '';
        this.template.querySelector('c-lwc-dd-s-2-n-batch-status').reset();
    }

    toggleSpinner() {
        this.template.querySelector('[data-id="spinner"]').classList.toggle("slds-hidden");
    }
}