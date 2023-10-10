/**
 * @description       : Prompt View for Amazon Connect Command Center
 * @author            : Jose Vega
 * @last modified on  : 07-20-2023
 * @last modified by  : Jose Vega
**/
import { LightningElement, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPrompts from '@salesforce/apex/AWSCommandCenterController.getPrompts';
import updateRecord from '@salesforce/apex/AWSCommandCenterController.awsUpdateRecord';
import hasAccess from '@salesforce/apex/AWSCommandCenterController.hasAccess';

// const actions = [
//     { label: 'Edit', name: 'edit' },
//     { label: 'Delete', name: 'delete' },
// ];

const columns = [
    { label: 'Id', fieldName: 'ID', type: 'text', sortable: true },
    { label: 'Language', fieldName: 'Lang', type: 'text', sortable: true },
    { label: 'Queue Name', fieldName: 'QueueName', type: 'text', sortable: true },
    { label: 'Script', fieldName: 'Script', type: 'text', sortable: true },
    { label: 'Actions', type: 'button-icon', initialWidth: 75, typeAttributes: {
        iconName: 'utility:edit', title: 'Edit', name: 'edit', variant: 'border-filled', alternativeText: 'Edit' },
        cellAttributes: {
            class: 'slds-text-align_center'
        }
    }
    // {
    //     type: 'action',
    //     typeAttributes: { rowActions: actions },
    // },
];

export default class LwcDdACCommandCenterPrompts extends LightningElement {
    columns = columns;
    records;
    searchTerm = '';
    error;
    showModal = false;
    editValue = '';
    editRecord;
    selectedRecordValue = '';
    wiredRecordsResult;
    hasAccess = false;
    accessErrorMessage = 'Retrieving User Information...'
    sortedBy;
    sortedDirection = 'asc';
    currentPage = 1;
    pageSizeOptions = [
        { label: '5', value: '5' },
        { label: '10', value: '10' },
        { label: '25', value: '25' }
    ];
    pageSize = this.pageSizeOptions[1].value; // Set the default page size
    totalPages = 1; // Initialize total pages to 1
    loading = true;

    @wire(getPrompts)
    wiredRecords(result) {
        this.wiredRecordsResult = result;
        if (result.data) {
            this.records = JSON.parse(result.data);
            this.totalPages = Math.ceil(this.records.length / parseInt(this.pageSize, 10));
            this.error = null;
            this.paginateData();
            this.loading = false;
        } else if (result.error) {
            this.error = result.error;
            this.records = null;
        }
    }

    @wire(hasAccess)
    hasAccessWire(result) {
        if (result.data === false || result.data === true) {
            this.hasAccess = result.data;
            if (this.hasAccess === false) {
                this.accessErrorMessage = 'Your user does not have access to the AWS Command Center'
            }
        } else if (result.error) {
            this.error = result.error;
        }
    }

    paginateData() {
        const startIndex = (parseInt(this.currentPage, 10) - 1) * parseInt(this.pageSize, 10);
        const endIndex = startIndex + parseInt(this.pageSize, 10);
        this.data = this.records.slice(startIndex, endIndex);
        this.loading = false;
    }

    get isPagePreviousDisabled() {
        return this.currentPage === 1;
    }

    get isPageNextDisabled() {
        return this.currentPage === this.totalPages || this.totalPages === 0;
    }

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;

        switch (action.name) {
            case 'edit':
                // Handle edit action
                this.handleEditClick(event);
                break;
        }
    }

    handleSearchTermChange(event) {
        this.searchTerm = event.target.value;
        if (this.searchTerm) {
            this.data = this.records.filter((record) => {
                // Iterate over each property/column of the record
                for (let prop in record) {
                    if (record.hasOwnProperty(prop)) {
                        // Check if the value of the property matches the search term
                        if (
                            record[prop] &&
                            record[prop]
                                .toString()
                                .toLowerCase()
                                .includes(this.searchTerm.toLowerCase())
                        ) {
                            return true; // Return true if a match is found
                        }
                    }
                }
                return false; // Return false if no match is found
            });
        } else {
            this.paginateData();
        }
    }

    handleEditClick(event) {
        const rowScript = event.detail.row.Script;
        this.editRecord = event.detail.row;
        // Get the value to be edited based on the rowId
        // and assign it to the editValue property
        this.editValue = rowScript;
        this.showModal = true;
    }

    handleUpdateClick() {
        // Perform update logic here using the this.editValue
        // value captured from the modal text field
        // Once update is done, close the modal
        this.editRecord.Script = this.selectedRecordValue;

        updateRecord({ payload: JSON.stringify(this.editRecord) })
            .then((result) => {
                // Handle the response from the AuraEnabled method
                // You can add any additional logic here

                // Refresh the datatable to reflect the updated record
                this.showModal = false;
                this.loading = true;
                this.showToast('Prompt Updated', 'Prompt ' + this.editRecord.ID + ' has been updated', 'success');
                refreshApex(this.wiredRecordsResult);
            })
            .catch((error) => {
                // Handle any errors from the AuraEnabled method
                this.showModal = false;
                this.loading = false;
            });
    }

    handleModalClose() {
        this.showModal = false;
    }

    handleSort(event) {
        this.loading = true;
        const { fieldName, sortDirection } = event.detail;
        this.sortedBy = fieldName;
        this.sortedDirection = sortDirection;
        this.sortData();
        this.paginateData();
    }

     // Method to perform sorting on the data
    sortData() {
        if (this.sortedBy) {
            this.records.sort((a, b) => {
                let valueA = a[this.sortedBy] || '';
                let valueB = b[this.sortedBy] || '';
                if (typeof valueA === 'string' && typeof valueB === 'string') {
                    valueA = valueA.toLowerCase();
                    valueB = valueB.toLowerCase();
                }
                if (valueA < valueB) {
                    return this.sortedDirection === 'asc' ? -1 : 1;
                } else if (valueA > valueB) {
                    return this.sortedDirection === 'asc' ? 1 : -1;
                }
                return 0;
            });
        }
    }

    handlePagePrevious() {
        if (this.currentPage > 1) {
            this.currentPage--;
        }
    }

    handlePageNext() {
        this.currentPage++;
    }

    handlePageSizeChange(event) {
        this.pageSize = event.detail.value; // Parse the selected value as an integer
        this.currentPage = 1; // Reset the current page to 1
        this.totalPages = Math.ceil(this.records.length / parseInt(this.pageSize, 10)); // Recalculate the total number of pages
        this.paginateData();
    }

    handleTextareaChange(event) {
        this.selectedRecordValue = event.target.value;
    }

    // Method to display a toast message
    showToast(title, message, variant) {
        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(toastEvent);
    }
}