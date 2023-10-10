/**
 * @author Mahesh Chouhan
 * @date  June 2023
 * @decription LWC component to make Claim Callout
 */

/*****************************************************************************************************************************
 *
 * Imports
 *
 *****************************************************************************************************************************/
import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { notifyRecordUpdateAvailable } from "lightning/uiRecordApi";
import makeClaimAPICallout from '@salesforce/apex/CDdClaimsCalloutController.makeClaimAPICallout';

/*****************************************************************************************************************************
 *
 * Functional Consts
 *
 *****************************************************************************************************************************/
const SUCCESS = 'Success';
const FAILURE = 'Failure';
const ERROR = 'Error';
const UNKNOWNN_ERROR = 'Unknown Error'
const CLAIM_SUCCESS_HEADER = 'Successful Claim Submission !';
const CLAIM_SUCCESS_MESSAGE = 'Claim Number has been successfully updated.';
const TOAST_VARIANT_SUCCESS = 'success';
const TOAST_VARIANT_ERROR = 'error';

export default class LwcDdClaimsCallout extends LightningElement {
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
        this.handleClaimsAPICallout();
    }

    async handleClaimsAPICallout(){
        if(!this.retrievedRecordId && this.recordId){
            this.isLoading = true;
            this.retrievedRecordId = true;
            await makeClaimAPICallout({claimId : this.recordId}).then(result => {
                if(result.status == SUCCESS){
                    this.showToast(CLAIM_SUCCESS_HEADER, CLAIM_SUCCESS_MESSAGE, TOAST_VARIANT_SUCCESS);
                }
                else if(result.status == FAILURE){
                    this.showToast(ERROR, result.message, TOAST_VARIANT_ERROR);
                }
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