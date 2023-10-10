import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import initChatConcurrency from '@salesforce/apex/CDdChatConcurrencyController.initChatConcurrency';
import updateChatConcurrency from '@salesforce/apex/CDdChatConcurrencyController.updateChatConcurrency';

const columns = [
    { label: 'Name', fieldName: 'MasterLabel' },
    {   label: 'Units of Capacity (Original)', 
        fieldName: 'CapacityWeight', 
        type: 'number',
        cellAttributes: { alignment: 'left' }
    },
    {   label: 'Units of Capacity (Edit)', 
        fieldName: 'CapacityWeight', 
        type: 'number', 
        editable: true,
        cellAttributes: { alignment: 'left' }
    }
];

export default class LwcDdChatConcurrency extends LightningElement {
    @track routingConfigList;
    @track columns = columns;

    connectedCallback() {
        initChatConcurrency({})
            .then(result => {
                this.routingConfigList = result;
            })
            .catch(error => {
                console.log(error);
            });
    }

    handleSave(event) {
        updateChatConcurrency({ changedRows : event.detail.draftValues})
            .then(result => {
                window.location.reload(true);
            })
            .catch(error => {
                const evt = new ShowToastEvent({
                    title: 'Error',
                    message: error.body.message,
                    variant: 'error'
                });
                this.dispatchEvent(evt);
            });
        ;
    }
}