import { LightningElement,api,wire,track } from 'lwc';
import validateQuoteAndSendToSSMO from '@salesforce/apex/CDdSSMOQuoteController.validateQuoteAndSendToSSMO';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class LwcDdQuote2SSMO extends LightningElement {

    @api recordId;
    @api objectName;
    @track isSending;

    @api flexipageRegionWidth;
    @track launchMessage;
    isError;
    error = [];
    success;

    connectedCallback() {
        this.launchMessage = true;
    }

    renderedCallback() {
        console.log(' this.recordId  is '+this.recordId);
    }

    validateQuoteData(event) {
        console.log('inside validateQuoteDate method ' +this.recordId);
        this.isSending = true;
        validateQuoteAndSendToSSMO({quoteId:this.recordId})
        .then((result) => {
            console.log('result is '+result);
            this.launchMessage = false;
            if(result.status == 'success'){
                this.isError = undefined;
                this.errors = [];
                this.success = 'Quote sent to SSMO successfully';
            }else{
                this.success = undefined;
                this.isError = true;
                this.errors = result.messages;
            }
            this.isSending = false;
        })
        .catch((error) => {
            this.launchMessage = false;
            this.errors.push(error);
            this.isError = true;
            this.success = undefined;
            this.isSending = false;
            console.log(this.error);
        });
    }

    closeWindow(){
        //this.dispatchEvent(new CloseActionScreenEvent());
        const closeComp = new CustomEvent('close');
        this.dispatchEvent(closeComp);
    }
    
}