import { LightningElement, track } from 'lwc';

export default class LwcDdS2NBulkHome extends LightningElement {
    
    static delegatesFocus = true;

    selectedBulkAction;
    selectedBulkActionLabel;
    hasSelectedBulkAction = false;
 
    constructor() {
        super();
        this.selectedBulkAction = null;
        this.hasSelectedBulkAction = false;
    }

    handleSelectBulkAction(event){
        event.preventDefault();
        event.stopPropagation();
        if (event.detail) {
            this.selectedBulkAction = event.detail.value;
            this.selectedBulkActionLabel = event.detail.label;
        } else {
            this.selectedBulkAction = null;
            this.selectedBulkActionLabel = null;
        }
        this.hasSelectedBulkAction = (this.selectedBulkAction != null);
        this.template.querySelector('c-lwc-dd-s-2-n-bulk-header').setSelectedBulkAction(this.selectedBulkActionLabel);
    }

    get shouldShowBypassToolUploader() {
        return this.selectedBulkAction == "Bypass Bulk Store Update";
    }
}