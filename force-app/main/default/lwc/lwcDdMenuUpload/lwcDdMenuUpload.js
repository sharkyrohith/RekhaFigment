import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import updateCVDescOnMenuFiles from '@salesforce/apex/CDdMenuUploader.updateCVDescOnMenuFiles';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';

export default class LwcDdMenuUpload extends NavigationMixin(LightningElement) {

    @api recordId;
    contentVersionIds = [];

    handleUploadFinished(event) 
    {
        const files = event.detail.files;
        if (files.length > 0) 
        {
            for (let i = 0; i < files.length; i++) 
            {
                let file = files[i];
                this.contentVersionIds.push(file.contentVersionId);
            }

            if(this.contentVersionIds.length > 0)
            {
                updateCVDescOnMenuFiles({contentVersionIds: this.contentVersionIds}).then(result=>{
                
                    if(result != null || result != undefined)
                    {
                        this.showToaster('Success', 'Files uploaded successfully!!', 'Success');
                        this[NavigationMixin.Navigate]({
                            "type": "standard__webPage",
                            "attributes": {
                                "url": window.location.origin+'/lightning/r/Opportunity/'+this.recordId+'/related/CombinedAttachments/view'
                            }
                            
                        });
                        this.dispatchEvent(new CloseActionScreenEvent());
                    }
                    else{
                        this.showToaster('error', 'An Error occur while uploading the file.', 'error');
                    }
                })
                .catch((error) => {
                    this.showToaster('error', 'An Error occur while uploading the file.', 'error');
                });
            }

        }
    }

    showToaster(titleValue, messageValue, variantValue) {
        this.dispatchEvent(new ShowToastEvent({ title: titleValue, message: messageValue, variant: variantValue }));
    }

    closeAction(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}