/**
 * @author Mahesh Chouhan
 * @date  June 2023
 * @decription LWC component to make Claim Document Submission Callout
 */

/*****************************************************************************************************************************
 *
 * Imports
 *
 *****************************************************************************************************************************/
import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import syncDocuments from '@salesforce/apex/CDdClaimsCalloutController.syncDocuments';

/*****************************************************************************************************************************
 *
 * Functional Consts
 *
 *****************************************************************************************************************************/
const ERROR = 'Error';
const UNKNOWNN_ERROR = 'Unknown Error'
const SUCCESS_HEADER = 'Successfully Documents Attached!';
const SUCCESS_MESSAGE = 'Documents have been successfully attached to Claim record.';
const TOAST_VARIANT_SUCCESS = 'success';
const TOAST_VARIANT_ERROR = 'error';
export default class LwcDdSyncDocuments extends LightningElement {
    /*****************************************************************************************************************************
     *
     * Public Variables
     *
    *****************************************************************************************************************************/
    //  {String} - Record Id for that object
    @api recordId;

    /*****************************************************************************************************************************
     *
     * Private Variables
     *
    *****************************************************************************************************************************/
    isLoading = false;
    retrievedRecordId = false;
    showError = false;

    /*****************************************************************************************************************************
     *
     * Lifecycle hooks
     *
    *****************************************************************************************************************************/
    renderedCallback() {
        this.handleSyncDocuments();
    }

    async handleSyncDocuments(){
        if(!this.retrievedRecordId && this.recordId){
            this.isLoading = true;
            this.retrievedRecordId = true;
            await syncDocuments({claimId : this.recordId}).then(result => {
                console.log('Here');
                this.showToast(SUCCESS_HEADER, SUCCESS_MESSAGE, TOAST_VARIANT_SUCCESS);
            })
            .catch(error => {
                this.error = UNKNOWNN_ERROR;
                if (Array.isArray(error.body)) {
                    this.error = error.body.map(e => e.message).join(', ');
                } else if (typeof error.body.message === 'string') {
                    this.error = error.body.message;
                }
                this.showToast(ERROR, this.error, TOAST_VARIANT_ERROR);
            });

            await notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
            this.closeAction();
        }
    }
    /*****************************************************************************************************************************
    *
    * Logic / Helper methods
    *
    *****************************************************************************************************************************/
    // show toast notifications
    showToast(title,msg,variant){
        let event = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant,
        });
        this.dispatchEvent(event);
    }
    //close quick action pop up
    closeAction(){
        this.isLoading = false;
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}