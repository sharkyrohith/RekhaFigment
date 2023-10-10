import { api, LightningElement, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import userId from '@salesforce/user/Id';
import getMyApexJobs from '@salesforce/apex/CDdMyApexJobsController.getMyApexJobs';

const columns = [  
    { label: 'Id', fieldName: 'Id' },  
    { label: 'Created Date', fieldName: 'CreatedDate' },  
    { label: 'Status', fieldName: 'Status' },
    { label: 'Total Batches', fieldName: 'TotalJobItems' },  
    { label: 'Batches Processed', fieldName: 'JobItemsProcessed' },  
    { label: 'Failures', fieldName: 'NumberOfErrors' },
    { label: 'Completion Date', fieldName: 'CompletedDate' }     
];

// Import custom labels
import jobs from '@salesforce/label/c.DDS2N_MyApexJobs_Jobs';
import refresh from '@salesforce/label/c.DDS2N_MyApexJobs_Refresh';
import unknownError from '@salesforce/label/c.DDS2N_MyApexJobs_UnknownError';
export default class LwcDdMyApexJobs extends LightningElement {

    @api
    apexClassName

    apexJobs;
    error;
    loading = false;
    columns = columns;
    _getResponse;
    userId = userId;

    label = {
        jobs, refresh, unknownError
    }

    @wire(getMyApexJobs, { userId: '$userId', apexClassName: '$apexClassName' })
    wiredApexJobs(response) {
        this._getResponse = response;
        const { data, error } = response;
        if (data) {
            this.apexJobs = data;
            this.error = undefined;
        } else if (error) {
            this.error = this.label.unknownError;
            if (Array.isArray(error.body)) {
                this.error = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                this.error = error.body.message;
            }
            this.apexJobs = undefined;
        }
    }

    @api 
    handleShowModal() {
        this.template.querySelector('c-lwc-dd-modal').showModal();
    }

    handleRefresh(event){
        event.preventDefault();
        event.stopPropagation();
        this.loading = true;
        refreshApex(this._getResponse)
        .then(() => { this.loading = false; })
        .catch(() => { this.loading = false; });
    }     

    handleCloseMyApexJobs(event){
        event.preventDefault();
        event.stopPropagation();        
        const closedialog = new CustomEvent('closemyapexjobs');
        this.dispatchEvent(closedialog);        
    }    
}