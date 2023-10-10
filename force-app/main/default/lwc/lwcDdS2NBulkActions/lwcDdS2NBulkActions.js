import { LightningElement, wire } from 'lwc';
import getBulkSteps from "@salesforce/apex/CDdLtngNimdaSyncHomeCtrl.getBulkSteps";

export default class LwcDdS2NBulkActions extends LightningElement {

    @wire(getBulkSteps) actions;

    handleSelectBulkAction(event) {
        event.preventDefault();
        event.stopPropagation();
        const selectEvent = new CustomEvent('selectbulkaction', {
            detail: {
                value : event.target.action.value,
                label: event.target.action.label
            }
        });
        this.dispatchEvent(selectEvent);
    }

}