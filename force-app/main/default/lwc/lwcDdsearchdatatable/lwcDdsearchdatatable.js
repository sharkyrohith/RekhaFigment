import { LightningElement, api, track } from 'lwc';
import findRecords from '@salesforce/apex/CDdMXPSearchRecordsCtrl.findRecords';

const options = [
    { label: '5', value: '5' },
    { label: '10', value: '10' },
    { label: '15', value: '15' },
    { label: '20', value: '20' },
    { label: '50', value: '50' }
];

export default class LwcDdsearchdatatable extends LightningElement {
    //Parameters required from Parent Component
    @api objectApiName;
    @api columns;
    @api showCheckbox;
    @api orderBy;
    @api sortOrder = 'ASC';

    @track updateUserToSave = [];
    @track confirmUserRecords = [];
    @track selectedRecordIds = [];
    @track selectedRecords2 = [];
    //Key is Page Number and Value is list of selected record ids
    @track selectedRowMap = new Map();

    usernameSearchKey = '';
    emailSearchKey = '';
    profileSearchKey = '';
    roleSearchKey = '';
    accountnameSearchKey = '';
    statusSearchKey = '';
    businessIdSearchKey = '';
    mxpUserSearchKey = '';
    showSelectedUsers = true;
    @track records;
    showLoadingSpinner = true;
    totalNumberOfRecords;
    offSet = 0;
    @api
    pageSize = '5';
    currentPage = 1;
    currentPage2 = 1;
    options = options;
    validationError = [];
    allRecords = [];

    get isRecordFound() {
        return this.records && this.records.length > 0;
    }

    get showError() {
        return this.validationError.length > 0;
    }

    get showMultipleSearchInputs() {
        return this.objectApiName === 'User' || this.objectApiName === 'AccountTeamMember' || this.objectApiName === 'Case';
    }

    get showCaseFilters() {
        return this.objectApiName === 'Case';
    }

    get showUserORACTFilters() {
        return this.objectApiName === 'User' || this.objectApiName === 'AccountTeamMember';
    }

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

    connectedCallback() {
        this.showLoadingSpinner = true;
        this.getRecords();
    }

    handleKeyChange(event) {
        if (event.target.name === 'username') {
            this.usernameSearchKey = event.target.value;
        }
        else if (event.target.name === 'email') {
            this.emailSearchKey = event.target.value;
        }
        else if (event.target.name === 'profile') {
            this.profileSearchKey = event.target.value;
        }
        else if (event.target.name === 'role') {
            this.roleSearchKey = event.target.value;
        }
        else if (event.target.name === 'accountname') {
            this.accountnameSearchKey = event.target.value;
        }
        else if (event.target.name === 'status') {
            this.statusSearchKey = event.target.value;
        }
        else if (event.target.name === 'businessid') {
            this.businessIdSearchKey = event.target.value;
        }
        else if (event.target.name === 'mxpuser') {
            this.mxpUserSearchKey = event.target.value;
        }
    }

    handleSearch() {
        this.showLoadingSpinner = true;
        this.offSet = 0;
        this.currentPage = 1;
        this.getRecords();
    }

    handleToggleSearch(event) {
        this.showSelectedUsers = event.target.checked;
        this.handleSearch();
    }

    handleNext() {
        this.showValidationError();
        if (this.validationError.length == 0) {
            this.showLoadingSpinner = true;
            this.currentPage = this.currentPage + 1;
            this.currentPage2 = this.currentPage2 + 1;
            this.offSet = this.offSet + parseInt(this.pageSize);
            this.getRecords();
            this.handlePreselectRecords();
        }
    }

    handlePrevious() {
        this.showValidationError();
        if (this.validationError.length == 0) {
            this.showLoadingSpinner = true;
            this.currentPage = this.currentPage - 1;
            this.currentPage2 = this.currentPage2 - 1;
            this.offSet = this.offSet - parseInt(this.pageSize);
            this.getRecords();
            this.handlePreselectRecords();
        }
    }

    handleNavigation(event) {
        this.showValidationError();
        if (this.validationError.length == 0) {
            this.showLoadingSpinner = true;
            this.offSet = parseInt(this.pageSize) * (parseInt(event.target.dataset.pageNumber) - 1);
            this.getRecords();
            this.currentPage2 = parseInt(event.target.dataset.pageNumber);
            this.handlePreselectRecords();
        }
    }

    handlePreselectRecords() {
        let selectedRows = this.template.querySelector('[data-id="userRecords"]').getSelectedRows();
        for (let i = 0; i < selectedRows.length; i++) {
            this.selectedRecords2.push(selectedRows[i]);
        }

        //Set Checkbox for already selected records
        this.selectedRecordIds = this.selectedRowMap.has(this.currentPage2) ? this.selectedRowMap.get(this.currentPage2) : [];
        this.selectedRecordIds = [...new Set(this.selectedRecordIds)];
    }

    getRecords() {
        let selectFields = [];
        this.columns.forEach((field) => {
            if (field.apiName != 'MXPName') {
                selectFields.push(field.apiName);
            }
            if (field.apiName == 'Account.Name') {
                selectFields.push('AccountId');
            }
        });

        let random = (this.objectApiName == 'AccountTeamMember' || this.objectApiName == 'User') ? Math.random() : 7;

        let parameterObject = {
            usernameSearchKey: this.usernameSearchKey,
            emailSearchKey: this.emailSearchKey,
            profileSearchKey: this.profileSearchKey,
            roleSearchKey: this.roleSearchKey,
            accountnameSearchKey: this.accountnameSearchKey,
            objectApiName: this.objectApiName,
            statusSearchKey: this.statusSearchKey,
            businessIdSearchKey: this.businessIdSearchKey,
            mxpUserSearchKey: this.mxpUserSearchKey,
            offSet: this.offSet,
            selectFields: selectFields,
            orderBy: this.orderBy,
            pageSize: this.pageSize,
            showSelectedUsers: this.showSelectedUsers,
            sortOrder: this.sortOrder,
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
                    if (result.mxpNames) {
                        if (result.mxpNames[rowData.Id]) {
                            rowData.MXPName = result.mxpNames[rowData.Id];
                        }
                    }

                    if (rowData.AccountName) {
                        rowData.AccountUrl = '/' + row.AccountId;
                    }

                    if (rowData.CaseNumber) {
                        rowData.CaseUrl = '/' + rowData.Id ;
                    }
                    currentData.push(rowData);
                });

                this.records = currentData;
                this.totalNumberOfRecords = result.totalNumberOfRecords;
                this.offSet = result.offSet;
                this.error = undefined;
                this.selectedRecordIds = [...new Set(this.selectedRecordIds)];
                this.allRecords.push(...this.records);
                this.showLoadingSpinner = false;
            })
            .catch((error) => {
                console.log(JSON.stringify(error));
                this.error = error;
                this.records = undefined;
            });
    }

    handleItemPerPageChange(event) {
        this.showLoadingSpinner = true;
        this.pageSize = event.detail.value;
        this.offSet = 0;
        this.currentPage = 1;
        this.getRecords();
    }

    handleRecordSelection(event) {
        let selectedRows = event.detail.selectedRows;
        let allSelectedRowIds = [];

        for (let k = 0; k < selectedRows.length; k++) {
            allSelectedRowIds.push(selectedRows[k].Id);
        }

        this.selectedRecordIds = [...new Set(allSelectedRowIds)];
        this.selectedRowMap.set(this.currentPage2, this.selectedRecordIds);
    }

    handleCellchange(event) {
        let userObj = event.detail.draftValues[0];
        let isMerged = false;
        let updateUserClone = [];
        this.updateUserToSave.forEach(function (rec) {
            if (rec.Id == userObj.Id) {
                let merged = { ...rec, ...userObj };
                rec = merged;
                isMerged = true;
                updateUserClone.push(rec);
            } else {
                updateUserClone.push(rec);
            }
        });
        if (!isMerged) {
            this.updateUserToSave.push(userObj);
        } else {
            this.updateUserToSave = updateUserClone;
        }
    }

    @api getSelectedRows() {
        this.showValidationError();
        if (this.validationError.length == 0) {
            let selectedRows = this.template.querySelector('[data-id="userRecords"]').getSelectedRows();
            for (let i = 0; i < selectedRows.length; i++) {
                this.selectedRecords2.push(selectedRows[i]);
            }

            let selectedRecords = new Map();
            this.selectedRecords2.forEach((row) => {
                selectedRecords.set(row.Id, row);
            });

            this.selectedRecords2 = [];
            for (let record of selectedRecords.values()) {
                this.selectedRecords2.push(record);
            }

            let selectedRecords2 = [];
            for (let record of this.selectedRowMap.values()) {
                selectedRecords2.push(...record);
            }

            this.selectedRecords2 = this.selectedRecords2.filter((rec) => {
                return selectedRecords2.includes(rec.Id);
            });

            return this.selectedRecords2;
        }
        else return null;
    }

    @api getChangedUserRecords() {
        this.showValidationError();
        if (this.validationError.length == 0) {
            if (this.updateUserToSave.length == 0) return;

            this.confirmUserRecords = this.updateUserToSave.map((item, i) => Object.assign({}, this.allRecords.find(function (element) { return element.Id == item.Id; }), item));
            return this.confirmUserRecords;
        }
        else return null;
    }

    showValidationError() {
        this.validationError = [];
        let confirmUserRecords = this.updateUserToSave.map((item, i) => Object.assign({}, this.records.find(function (element) { return element.Id == item.Id; }), item));
        for (var i = 0; i < confirmUserRecords.length; i++) {
            if (confirmUserRecords[i].Is_Out_Of_Office__c && !confirmUserRecords[i].Out_Of_Office_End_Date__c) {
                this.validationError.push('Please Update OOO Return Date for Users with Out Of Office selected');
            }
            if (confirmUserRecords[i].Is_Out_Of_Office__c == false && confirmUserRecords[i].Out_Of_Office_End_Date__c) {
                this.validationError.push('Please Select Out Of Office for Users with OOO Return Date');
            }
            let oooDate = new Date(confirmUserRecords[i].Out_Of_Office_End_Date__c);
            let today = new Date();
            today.setHours(0, 0, 0, 0);
            if (confirmUserRecords[i].Out_Of_Office_End_Date__c && oooDate < today) {
                this.validationError.push('OOO Return Date must be today or in future date.');
            }
        }
        this.validationError = [...new Set(this.validationError)];
    }
}