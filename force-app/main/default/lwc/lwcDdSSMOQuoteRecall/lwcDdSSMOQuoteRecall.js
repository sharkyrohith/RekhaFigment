import { LightningElement,api,track } from 'lwc';
import recallQuote from '@salesforce/apex/CDdSSMOQuoteController.recallQuote';

export default class LwcDdSSMOQuoteRecall extends LightningElement {
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

    recallQuote(event) {
        this.isSending = true;
        recallQuote({quoteId:this.recordId})
        .then((result) => {
            console.log('result is '+result);
            this.launchMessage = false;
            if(result.status == 'success'){
                this.isError = undefined;
                this.errors = [];
                this.success = 'Quote has been recalled successfully';
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

    closeWindow() {
        const closeComp = new CustomEvent('close');
        this.dispatchEvent(closeComp);
    }

}