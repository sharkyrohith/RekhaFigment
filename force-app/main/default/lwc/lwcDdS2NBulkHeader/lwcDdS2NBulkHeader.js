import { api, LightningElement, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import NAME_FIELD from '@salesforce/schema/User.Name';
import REPORT_ID from '@salesforce/label/c.Bulk_Uploader_Report_Id';

// Import custom labels
import homeHeader from '@salesforce/label/c.DDS2N_BulkHeader_Home';
import reportHeader from '@salesforce/label/c.DDS2N_BulkHeader_Report';
import jobHeader from '@salesforce/label/c.DDS2N_BulkHeader_Job';
import instructionsHeader from '@salesforce/label/c.DDS2N_BulkHeader_Instructions';

const DELAY = 300;
export default class LwcDdS2NBulkHeader extends LightningElement {

    selectedBulkAction;
    hasSelectedBulkAction;
    showMyApexJobs = false;
    showInstructions = false;
    userName;
    error;

    label = {
        homeHeader, reportHeader, jobHeader, instructionsHeader
    };

    constructor() {
        super();
        this.setSelectedBulkAction(null);
    }

    @wire(getRecord, {recordId: USER_ID, fields: [NAME_FIELD]}) wireuser({error, data}) {
        if (error) {
           this.error = error ; 
        } else if (data) {
            this.userName = data.fields.Name.value;
        }
    }

    @api
    setSelectedBulkAction(value){
        this.selectedBulkAction = value;
        this.hasSelectedBulkAction = (this.selectedBulkAction!=null);
    }

    navigateToHome(event){
        event.preventDefault();
        event.stopPropagation();
        if (this.hasSelectedBulkAction){
            this.setSelectedBulkAction(null);
            const selectEvent = new CustomEvent('selectbulkaction', {
                detail: this.selectedBulkAction
            });
            this.dispatchEvent(selectEvent);
        }
    }

    handleShowBulkInstructions(event){
        event.preventDefault();
        event.stopPropagation();
        this.showInstructions = true;
        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            this.template.querySelector('c-lwc-dd-s-2-n-bulk-instructions').handleShowModal();
        }, DELAY);
    }

    handleCloseBulkInstructions(event){
        event.preventDefault();
        event.stopPropagation();
        this.showInstructions = false;
    }

    handleShowMyApexJobs(event){
        event.preventDefault();
        event.stopPropagation();
        this.showMyApexJobs = true;
        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            this.template.querySelector('c-lwc-dd-my-apex-jobs').handleShowModal();
        }, DELAY);
    }

    handleCloseMyApexJobs(event){
        event.preventDefault();
        event.stopPropagation();
        this.showMyApexJobs = false;
    }

    navigateToReport(event) {
        event.stopPropagation();
        window.open('/lightning/r/Report/' + REPORT_ID + '/view?fv0=' + this.userName, '_blank');
    }
}