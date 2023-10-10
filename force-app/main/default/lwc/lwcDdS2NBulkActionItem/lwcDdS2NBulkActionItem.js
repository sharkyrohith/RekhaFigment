import { api, LightningElement } from 'lwc';

export default class LwcDdS2NBulkActionItem extends LightningElement {

    @api
    action;

    handleSelect(event) {
        event.preventDefault();
        event.stopPropagation();
        const selectEvent = new CustomEvent('selectbulkaction', {
            bubbles: true
        });
        this.dispatchEvent(selectEvent);
    }    
}