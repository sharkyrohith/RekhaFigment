/**
 * @description       : Queue Command Center View
 * @author            : Jose Vega
 * @last modified on  : 08-02-2023
 * @last modified by  : Jose Vega
**/
import { LightningElement, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getQueues from '@salesforce/apex/AWSCommandCenterController.getQueues';
import saveQueue from '@salesforce/apex/AWSCommandCenterController.saveQueue';
import getHoursOfOperations from '@salesforce/apex/AWSCommandCenterController.getHoursOfOperations';
import hasAccess from '@salesforce/apex/AWSCommandCenterController.hasAccess';
import getUserVertical from '@salesforce/apex/AWSCommandCenterController.getUserVertical';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const columns = [
    { label: 'Name', fieldName: 'name', type: 'text', sortable: true },
    { label: 'Description', fieldName: 'description', type: 'text', sortable: true },
    { label: 'ARN', fieldName: 'arn', type: 'text', sortable: true },
    { label: 'Hours of Operation', fieldName: 'hoursOfOperation', type: 'text', sortable: true },
    { label: 'Tags', fieldName: 'tags', type: 'text', sortable: true },
];

export default class LwcDdACCommandCenter extends LightningElement {
    columns = columns;
    records;
    hoursOfOperation;
    searchTerm = '';
    error;
    showModal = false;
    editValue = '';
    selectedRecordValue = '';
    wiredRecordsResult;
    hasAccess = false;
    userVertical;
    accessErrorMessage = 'Retrieving User Information...'
    newQueue = {};
    sortedBy;
    sortedDirection = 'asc';
    currentPage = 1;
    pageSizeOptions = [
        { label: '5', value: '5' },
        { label: '10', value: '10' },
        { label: '25', value: '25' }
    ];
    verticals = [
        { label: 'Cx', value: 'Cx' },
        { label: 'Mx', value: 'Mx' },
        { label: 'Dx', value: 'Dx' }
    ]
    pageSize = this.pageSizeOptions[1].value; // Set the default page size
    totalPages = 1; // Initialize total pages to 1
    loading = true;
    isFormValid = false; // Track the overall form validity
    isSubmitDisabled = true; // Track the disabled state of the submit button

    @wire(getHoursOfOperations)
    handleHoursOfOperation(result) {
        if (result.data) {
            this.hoursOfOperation = JSON.parse(result.data).HoursOfOperationSummaryList;
            this.businessHoursOptions = this.hoursOfOperation.map(function(x) {
                return {'label': x.Name, 'value': x.Arn};
            });
            this.error = null;
        } else if (result.error) {
            this.error = result.error;
            this.hoursOfOperation = null;
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

    @wire(getUserVertical)
    getUserVerticalWire(result) {
        if (result.data) {
            this.userVertical = result.data;
        } else if (result.error) {
            this.error = result.error;
        }
    }

    @wire(getQueues)
    wiredRecords(result) {
        this.wiredRecordsResult = result;
        if (result.data) {
            this.records = JSON.parse(result.data);
            this.totalPages = Math.ceil(this.records.length / this.pageSize);
            this.error = null;
            this.loading = false;
            this.paginateData();
        } else if (result.error) {
            this.error = result.error;
            this.records = null;
        }
    }

    paginateData() {
        const startIndex = (parseInt(this.currentPage, 10) - 1) * parseInt(this.pageSize, 10);
        const endIndex = startIndex + parseInt(this.pageSize, 10);
        this.data = this.records.slice(startIndex, endIndex);
        this.loading = false;
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

    get isPagePreviousDisabled() {
        return this.currentPage === 1;
    }

    get isPageNextDisabled() {
        return this.currentPage === this.totalPages || this.totalPages === 0;
    }

    get hasAllAccess() {
        return this.userVertical === 'ALL';
    }

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;

        switch (action.name) {
            case 'edit':
                // Handle edit action
                this.handleEditClick(event);
                break;
            case 'delete':
                // Handle delete action
                break;
            // Add more cases for additional row actions if needed
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
        //const rowScript = event.detail.row.Script;
        // Get the value to be edited based on the rowId
        // and assign it to the editValue property
        //this.editValue = rowScript;
        this.showModal = true;
    }

    handleSave() {
        saveQueue({ payload: JSON.stringify(this.newQueue) })
            .then((result) => {
                this.showModal = false;
                this.showToast('Added New Queue', 'A new queue has been created: ' + this.newQueue.name, 'success');
                refreshApex(this.wiredRecordsResult);
            })
            .catch((error) => {
                this.showModal = false;
                this.loading = false;
                console.error(error);
            });
    }

    // Method to handle the field changes inside the modal
    handleFieldChange(event) {
        const fieldName = event.target.name;
        const fieldValue = event.target.value;

        if (fieldName == 'businessHours') {
            const optionSelected = event.target.options.find(option => option.value === fieldValue);
            this.newQueue['businessHoursName'] = optionSelected.label;
        }

        this.newQueue[fieldName] = fieldValue;
        this.validateForm();
    }


    validateForm() {
        const keywordPattern = /.*[A-Za-z]{3,4}-\d{3,5}.*/;
        const isDescriptionValid = keywordPattern.test(this.newQueue.description);

        this.isFormValid = this.newQueue.businessHours && this.newQueue.name && isDescriptionValid;
        this.isSubmitDisabled = !this.isFormValid;
    }

    handleNewQueue() {
        this.showModal = true;
    }

    handleCloseModal() {
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

    handlePagePrevious() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.paginateData();
        }
    }

    handlePageNext() {
        this.currentPage++;
        this.paginateData();
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