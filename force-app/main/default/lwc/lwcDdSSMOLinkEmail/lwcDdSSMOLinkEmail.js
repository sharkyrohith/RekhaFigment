import { LightningElement,api,wire,track } from 'lwc';
import sendSSMOLink from '@salesforce/apex/CDdSSMOLinkController.sendSSMOLink';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class LwcDdSSMOLinkEmail extends LightningElement {
    @api recordId;
    @api objectName;

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

    sendLink(event) {
        console.log('inside sendLink method ' +this.recordId);
        sendSSMOLink({opportunityId:this.recordId})
        .then((result) => {
            console.log('result is '+result);
            this.launchMessage = false;
            if(result.status == 'success'){
                this.isError = undefined;
                this.errors = [];
                this.success = 'Email has been sent successfully';
            }else{
                this.success = undefined;
                this.isError = true;
                this.errors = result.messages;
            }
            
        })
        .catch((error) => {
            this.launchMessage = false;
            this.errors.push(error);
            this.isError = true;
            this.success = undefined;
            console.log(this.error);
        });
    }

    closeWindow() {
        //this.dispatchEvent(new CloseActionScreenEvent());
        const closeComp = new CustomEvent('close');
        this.dispatchEvent(closeComp);
    }

}