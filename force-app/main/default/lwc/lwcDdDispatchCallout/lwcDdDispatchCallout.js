/**
 * @author Raja Valeti
 * @date  Nov 2022
 * @decription Dispacth Callout from lightning
 */

/*****************************************************************************************************************************
 *
 * Imports
 *
 *****************************************************************************************************************************/
 import { LightningElement, api, wire} from 'lwc';
 import { ShowToastEvent } from 'lightning/platformShowToastEvent';
 import { CloseActionScreenEvent } from 'lightning/actions';
 import { getRecordNotifyChange } from "lightning/uiRecordApi";
 import {MessageContext, publish} from 'lightning/messageService';
 import makeDeliveryCallout from '@salesforce/apex/CDdDispatchCalloutCtrl.makeDeliveryCallout';
 import gdprfieldsetmessagechannel from "@salesforce/messageChannel/mcDdGDPRDisplayConsentFieldSetRefresh__c";

export default class LwcDdDispatchCallout extends LightningElement {

/*****************************************************************************************************************************
 *
 * Public Variables
 *
*****************************************************************************************************************************/
    //  {String} - Record Id for that object
    @api recordId;

    @wire(MessageContext)
    messageContext;

/*****************************************************************************************************************************
 *
 * Private Variables
 *
*****************************************************************************************************************************/
    isLoading = false;
    retrievedRecordId = false;
/*****************************************************************************************************************************
 *
 * Lifecycle hooks
 *
*****************************************************************************************************************************/
    connectedCallback() {
        //code
    }
    renderedCallback(){
        //code
        if(!this.retrievedRecordId && this.recordId){
            //Prevent multiple Apex Server calls
            this.retrievedRecordId = true;
            this.isLoading=true;
            let params= {
                "caseId": this.recordId
            };
            makeDeliveryCallout(params).then(result => {
                this.isLoading=false;
                this.startToast('Success!','The call to Dispatch was completed successfully and the case has been updated.','success');
                this.closeAction();
                const messaage = {
                    recordId: this.recordId
                };
                publish(this.messageContext, gdprfieldsetmessagechannel, messaage);
                getRecordNotifyChange([{ recordId: this.recordId }]);
            })
            .catch(error => {
                this.isLoading=false;
                this.error = 'Unknown error';
                if (Array.isArray(error.body)) {
                    this.error = error.body.map(e => e.message).join(', ');
                } else if (typeof error.body.message === 'string') {
                    this.error = error.body.message;
                }
                this.startToast('Error!',this.error,'error');
                this.closeAction();
            });
        }   
    }
/*****************************************************************************************************************************
*
* Logic / Helper methods
*
*****************************************************************************************************************************/

    // show toast notifications
    startToast(title,msg,variant){
        let event = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant,
        });
        this.dispatchEvent(event);
    }
    //close quick action pop up
    closeAction(){
         this.dispatchEvent(new CloseActionScreenEvent());
    }
}