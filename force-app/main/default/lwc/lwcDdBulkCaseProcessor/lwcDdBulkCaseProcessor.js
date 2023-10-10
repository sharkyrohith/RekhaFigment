/**
 * @author Sahil Chaudhry
 * @date  05/17/2022
 * @decription component to accept a CSV and other context to update cases in bulk
 */
/*****************************************************************************************************************************
 *
 * Imports
 *
*****************************************************************************************************************************/
import { LightningElement, track, api } from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import processCases from '@salesforce/apex/CDdBulkCaseProcessor.processCases';
import HEADER_NOTE from '@salesforce/label/c.Bulk_Case_App_Header_Note';

export default class LwcDdBulkCaseProcessor extends LightningElement {
    /*****************************************************************************************************************************
     *
     * Public Variable
     *
    *****************************************************************************************************************************/
    emailBody;
    caseStatus;
    sendEmail = false;
    @api recordId;
    @track error;
    @track data;
    checkboxVal = false;
    @api apexClassName;
    documentId = null;
    caseCloseReason = 'Email Body; Sent to the customer';
    labels = {
        HEADER_NOTE
    };
    activeSections = ['step1', 'step2', 'step3'];

    /*****************************************************************************************************************************
     *
     * UI Getters
     *
     *****************************************************************************************************************************/
    // accepted parameters
    get acceptedFormats() {
        return ['.csv'];
    }

    get statusOptions() {
        return [
            {label: 'Closed', value: 'Closed'},
            {label: 'Solved', value: 'Solved'}
        ];
    }
    /*****************************************************************************************************************************
     *
     * Event Handlers
     *
     *****************************************************************************************************************************/
     handleCaseStatusChange(event) {
        this.caseStatus = event.detail.value;
    }

    handleCheckbox(event) {
        this.sendEmail = event.detail.value;
    }

    handleCaseProcess(event) {
        // calling apex class
        processCases({contentDocId : this.documentId,
                        sendEmail : this.checkboxVal,
                        emailBody : this.emailBody,
                        caseStatus : this.caseStatus})
        .then(result => {
            this.data = result;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'File submitted for Processing!',
                    variant: 'success',
                }),
            );
        })
        .catch(error => {
            this.error = error;
            console.log(error.body.message);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error!!',
                    message: error.body.message,
                    variant: 'error',
                }),
            );     
        })
    }

    handleTextareaupdate(event) {
        this.emailBody = event.detail.value;
    }

    handleCheckbox(event) {
        this.checkboxVal = event.target.checked;
    }

    handleUploadFinished(event) {
        // Get the list of uploaded files
        const uploadedFiles = event.detail.files;
        this.documentId = uploadedFiles[0].documentId;
        if(this.documentId) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'File Uploaded to Salesforce',
                    variant: 'success',
                }),
            );
        } else {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error!!',
                    message: 'Error Uploading File',
                    variant: 'error',
                }),
            );     
        }
    }
}