import { LightningElement, track, api, wire } from 'lwc';
import findRecords from '@salesforce/apex/CDdMXPSearchRecordsCtrl.findRecords';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';

const options = [
    { label: '5', value: '5' },
    { label: '10', value: '10' },
    { label: '15', value: '15' },
    { label: '20', value: '20' },
    { label: '50', value: '50' }
];

const columns = [
    { label: 'Account Name', fieldName: 'Name', apiName: 'Name', sortable: true },
    { label: 'Business Id', fieldName: 'Business_ID__c', apiName: 'Business_ID__c', sortable: true },
    { label: 'Store Id', fieldName: 'Restaurant_ID__c', apiName: 'Restaurant_ID__c', sortable: true },
    {
        label: 'Case Routing', fieldName: 'Case_Routing_Override__c', type: 'picklist', apiName: 'Case_Routing_Override__c',
        typeAttributes: {
            placeholder: 'Choose Routing',
            options: [], // list of all picklist options
            value: { fieldName: 'Case_Routing_Override__c' }, // default value for picklist
            context: { fieldName: 'Id' }, // binding account Id with context variable to be returned back
            wrapText: true,
        }
    }
];

export default class LwcDdCustomPicklistDatatable extends LightningElement {
    @api objectApiName;
    @api orderBy;
    @track data = [];
    //have this attribute to track data changed
    //with custom picklist or custom lookup
    @track draftValues = [];
    columns = columns;
    accountnameSearchKey = '';
    @track records;
    showLoadingSpinner = true;
    totalNumberOfRecords;
    offSet = 0;
    pageSize = '5';
    currentPage = 1;
    currentPage2 = 1;
    options = options;
    lastSavedData = [];
    allRecords = [];
    @api fieldName = 'Case_Routing_Override__c';
    apiFieldName;
    picklistOptions;
    showDatatable = false;

    get totalPage() {
        let totalPages = [];
        for (let i = this.currentPage; i <= Math.ceil(this.totalNumberOfRecords / parseInt(this.pageSize)) && totalPages.length < 3; i++) {
            totalPages.push(i + '');
        }
        return totalPages;
    }

    get disablePreviousButton() {
        return this.currentPage <= 1;
    }

    get disableNextButton() {
        return this.currentPage + 2 >= Math.ceil(this.totalNumberOfRecords / parseInt(this.pageSize));
    }

    get firstIndex() {
        return this.offSet + 1;
    }

    get lastIndex() {
        let noOfRecords = this.records ? this.records.length : 0;
        return this.offSet + noOfRecords;
    }

    get showTable(){
        return this.showDatatable && !this.showLoadingSpinner;
    }

    @wire(getObjectInfo, { objectApiName: '$objectApiName' })
    getObjectData({ error, data }) {
        if (data) {
            if (this.recordTypeId == null)
                this.recordTypeId = data.defaultRecordTypeId;

            this.apiFieldName = this.objectApiName + '.' + this.fieldName;
        } else if (error) {
            console.log('Exception:::' + error);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: '$apiFieldName' })
    getPicklistValues({ error, data }) {
        if (data) {
            this.picklistOptions = data.values.map(plValue => {
                return {
                    label: plValue.label,
                    value: plValue.value
                };
            });
            this.picklistOptions.unshift({ label: '--None--', value: '' });
            if (this.picklistOptions){
                this.columns[3].typeAttributes.options = this.picklistOptions;
            }
            this.showDatatable = true;
        } else if (error) {
            console.log('Exception:::' + error);
        }
    }

    connectedCallback() {
        this.showLoadingSpinner = true;
        this.getRecords();
        //save last saved copy
        this.lastSavedData = JSON.parse(JSON.stringify(this.data));
    }

    updateDataValues(updateItem) {
        let copyData = [... this.data];
        copyData.forEach(item => {
            if (item.Id === updateItem.Id) {
                for (let field in updateItem) {
                    item[field] = updateItem[field];
                }
            }
        });

        //write changes back to original data
        this.data = [...copyData];
    }

    handleKeyChange(event) {
        if (event.target.name === 'accountname') {
            this.accountnameSearchKey = event.target.value;
        }
    }

    updateDraftValues(updateItem) {
        let draftValueChanged = false;
        let copyDraftValues = [...this.draftValues];
        //store changed value to do operations
        //on save. This will enable inline editing &
        //show standard cancel & save button
        copyDraftValues.forEach(item => {
            if (item.Id === updateItem.Id) {
                for (let field in updateItem) {
                    item[field] = updateItem[field];
                }
                draftValueChanged = true;
            }
        });

        if (draftValueChanged) {
            this.draftValues = [...copyDraftValues];
        } else {
            this.draftValues = [...copyDraftValues, updateItem];
        }
    }

    //listener handler to get the context and data
    //updates datatable
    picklistChanged(event) {
        event.stopPropagation();
        let dataRecieved = event.detail.data;
        let updatedItem = { Id: dataRecieved.context, 'Case_Routing_Override__c': dataRecieved.value };
        this.updateDraftValues(updatedItem);
        this.updateDataValues(updatedItem);
    }

    handleSearch() {
        this.showLoadingSpinner = true;
        this.offSet = 0;
        this.currentPage = 1;
        this.getRecords();
    }

    handleNext() {
        this.showLoadingSpinner = true;
        this.currentPage = this.currentPage + 1;
        this.currentPage2 = this.currentPage2 + 1;
        this.offSet = this.offSet + parseInt(this.pageSize);
        this.getRecords();
    }

    handlePrevious() {
        this.showLoadingSpinner = true;
        this.currentPage = this.currentPage - 1;
        this.currentPage2 = this.currentPage2 - 1;
        this.offSet = this.offSet - parseInt(this.pageSize);
        this.getRecords();
    }

    handleNavigation(event) {
        this.showLoadingSpinner = true;
        this.offSet = parseInt(this.pageSize) * (parseInt(event.target.dataset.pageNumber) - 1);
        this.getRecords();
        this.currentPage2 = parseInt(event.target.dataset.pageNumber);
    }

    getRecords() {
        let selectFields = [];
        this.columns.forEach((field) => {
            selectFields.push(field.apiName);
        });

        let random = Math.random();

        let parameterObject = {
            usernameSearchKey: this.usernameSearchKey,
            emailSearchKey: this.emailSearchKey,
            profileSearchKey: this.profileSearchKey,
            roleSearchKey: this.roleSearchKey,
            accountnameSearchKey: this.accountnameSearchKey,
            objectApiName: this.objectApiName,
            offSet: this.offSet,
            selectFields: selectFields,
            orderBy: this.orderBy,
            pageSize: this.pageSize,
            random: random
        };

        findRecords({ searchParameters: parameterObject })
            .then((result) => {
                let currentData = [];
                result.records.forEach((row) => {
                    let rowData = {};

                    this.columns.forEach((field) => {
                        rowData.Id = row.Id;
                        if (row[field.apiName] && field.apiName.indexOf('.') === -1) {
                            rowData[field.apiName] = row[field.apiName];
                        }

                        if (field.apiName.indexOf('.') !== -1) {
                            let innerFields = field.apiName.split('.');
                            if (row[innerFields[0]] && row[innerFields[0]][innerFields[1]]) {
                                rowData[innerFields[0] + innerFields[1]] = row[innerFields[0]][innerFields[1]];
                            }
                        }

                    });

                    currentData.push(rowData);
                });

                this.records = currentData;
                this.totalNumberOfRecords = result.totalNumberOfRecords;
                this.offSet = result.offSet;
                this.selectedRecordIds = [...new Set(this.selectedRecordIds)];
                this.allRecords.push(...this.records);
                if (this.picklistOptions){
                    this.columns[3].typeAttributes.options = this.picklistOptions;
                }
                this.showLoadingSpinner = false;
            })
            .catch((error) => {
                console.log(JSON.stringify(error));
                this.records = undefined;
            });
    }

    @api getChangedUserRecords() {
        if (this.draftValues.length == 0) return;

        let confirmUserRecords = this.draftValues.map((item, i) => Object.assign({}, this.allRecords.find(function (element) { return element.Id == item.Id; }), item));
        return confirmUserRecords;
    }

    handleItemPerPageChange(event) {
        this.showLoadingSpinner = true;
        this.pageSize = event.detail.value;
        this.offSet = 0;
        this.currentPage = 1;
        this.getRecords();
    }
}