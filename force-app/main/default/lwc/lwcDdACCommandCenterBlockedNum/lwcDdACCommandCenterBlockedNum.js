/**
 * @description       :
 * @author            : Jose Vega
 * @last modified on  : 07-20-2023
 * @last modified by  : Jose Vega
**/
import { LightningElement, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getBlockedNumbers from '@salesforce/apex/AWSCommandCenterController.getBlockedNumbers';
import deleteBlockedNumber from '@salesforce/apex/AWSCommandCenterController.deleteBlockedNumber';
import hasAccess from '@salesforce/apex/AWSCommandCenterController.hasAccess';
import addBlockedNumber from '@salesforce/apex/AWSCommandCenterController.addBlockedNumber';

const columns = [
    { label: 'Phone Number', fieldName: 'phoneNumber', type: 'text', sortable: true },
    { label: 'Actions', type: 'button-icon', initialWidth: 75, typeAttributes: {
        iconName: 'utility:delete', title: 'Delete', name: 'delete', variant: 'border-filled', alternativeText: 'Delete' },
        cellAttributes: {
            class: 'slds-text-align_center'
        }
    }
];

export default class LwcDdACCommandCenterBlockedNum extends LightningElement {
    columns = columns;
    records;
    hoursOfOperation;
    searchTerm = '';
    error;
    showModal = false;
    editValue = '';
    phoneNumber = ''; // Track the phone number input field value
    isPhoneNumberValid = false; // Track the validation result
    phoneNumberErrorMessage = ''; // Track the error message
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

    @wire(getBlockedNumbers)
    wiredRecords(result) {
        if (result.data) {
            this.wiredRecordsResult = result;
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

    get isSubmitButtonDisabled() {
        return !this.isPhoneNumberValid;
    }

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;

        switch (action.name) {
            case 'delete':
                if(confirm('Are you sure you want to delete the phone number: ' + event.detail.row.phoneNumber)) {
                    this.handleDeleteClick(event);
                }
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

    handleDeleteClick(event) {
        const rowPhoneNumber = event.detail.row.phoneNumber;

        deleteBlockedNumber({ payload: rowPhoneNumber })
            .then((result) => {
                this.showModal = false;
                this.loading = true;
                this.showToast('Removed Blocked Number', 'Blocked phone number ' +  rowPhoneNumber + ' has been removed.', 'success');
                // Refresh the datatable to reflect the updated record
                refreshApex(this.wiredRecordsResult);
            })
            .catch((error) => {
                // Handle any errors from the AuraEnabled method
                this.showModal = false;
                this.loading = false;
                console.error(error);
            });
    }

    handleSave() {

        addBlockedNumber({ payload: this.phoneNumber })
            .then((result) => {
                this.showModal = false;
                this.loading = true;
                this.showToast('Added Blocked Number', 'Blocked number ' + this.phoneNumber + ' has been added.', 'success');
                // Refresh the datatable to reflect the updated record
                refreshApex(this.wiredRecordsResult);
            })
            .catch((error) => {
                // Handle any errors from the AuraEnabled method
                this.showModal = false;
                this.loading = false;
            });
    }

    // Method to handle the field changes inside the modal
    handleFieldChange(event) {
        const fieldName = event.target.name;
        const fieldValue = event.target.value;
        this[fieldName] = fieldValue;
        this.validatePhoneNumber();
    }

    validatePhoneNumber() {
        const regex = /^\+(1|61)\d{10}$/;
        this.isPhoneNumberValid = regex.test(this.phoneNumber);

        if (!this.isPhoneNumberValid) {
            this.phoneNumberErrorMessage = 'Invalid phone number format. Please enter a phone number in the format + (Country Code) followed by 10 digits.';
        } else {
            this.phoneNumberErrorMessage = '';
        }
    }

    handleNewBlockedNumber() {
        this.showModal = true;
        this.phoneNumberErrorMessage = '';
        this.phoneNumber = '';
    }

    handleCloseModal() {
        this.phoneNumber = null;
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