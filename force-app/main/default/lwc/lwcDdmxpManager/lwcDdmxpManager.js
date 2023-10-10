import { LightningElement, track, wire } from 'lwc';
import saveOOOUser from "@salesforce/apex/CDdMXPManagerController.updateUsersOOO";
import saveAccounts from "@salesforce/apex/CDdMXPManagerController.updateAccountsCRO";
import saveAccountTeam from "@salesforce/apex/CDdMXPManagerController.upsertOrRemoveAccountTeams";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAccountTeamExistingRec from "@salesforce/apex/CDdMXPManagerController.getExistingAcccountTeams";
import removeAccountTeams from "@salesforce/apex/CDdMXPManagerController.removeAccountTeams";
import getUserPerm from "@salesforce/apex/CDdMXPManagerController.getUserPerm";
import updateAccountRecords from "@salesforce/apex/CDdMXPManagerController.updateMxAccountRecords";

const columns = [
    { label: 'Name', fieldName: 'Name', apiName: 'Name', sortable: true },
    { label: 'Active', fieldName: 'IsActive', type: 'boolean', apiName: 'IsActive', sortable: true },
    { label: 'Out of office', fieldName: 'Is_Out_Of_Office__c', type: 'boolean', apiName: 'Is_Out_Of_Office__c', sortable: true, editable: true },
    { label: 'OOO Return Date', fieldName: 'Out_Of_Office_End_Date__c', type: 'date-local', apiName: 'Out_Of_Office_End_Date__c', sortable: true, editable: true },
    { label: 'Email', fieldName: 'Email', type: 'email', apiName: 'Email', sortable: true },
    { label: 'Profile', fieldName: 'ProfileName', apiName: 'Profile.Name', sortable: true },
    { label: 'Role', fieldName: 'UserRoleName', apiName: 'UserRole.Name', sortable: true }
];

const addRemoveUserColumns = [
    { label: 'Name', fieldName: 'Name', sortable: true },
    { label: 'Active', fieldName: 'IsActive', type: 'boolean', sortable: true },
    { label: 'Out of office', fieldName: 'Is_Out_Of_Office__c', type: 'boolean', sortable: true },
    { label: 'OOO Return Date', fieldName: 'Out_Of_Office_End_Date__c', type: 'date-local', sortable: true },
];

const addRemoveUserColumnsTable = [
    { label: 'Name', fieldName: 'Name', apiName: 'Name', sortable: true },
    { label: 'Active', fieldName: 'IsActive', apiName: 'IsActive', type: 'boolean', sortable: true },
    { label: 'Out of office', fieldName: 'Is_Out_Of_Office__c', apiName: 'Is_Out_Of_Office__c', type: 'boolean', sortable: true },
    { label: 'OOO Return Date', fieldName: 'Out_Of_Office_End_Date__c', apiName: 'Out_Of_Office_End_Date__c', type: 'date-local', sortable: true },
    { label: 'Email', fieldName: 'Email', type: 'email', apiName: 'Email', sortable: true },
    { label: 'Profile', fieldName: 'ProfileName', apiName: 'Profile.Name', sortable: true },
    { label: 'Role', fieldName: 'UserRoleName', apiName: 'UserRole.Name', sortable: true }
];

const accountColumns = [
    { label: 'Account Name', fieldName: 'Name', apiName: 'Name', sortable: true },
    { label: 'Business Id', fieldName: 'Business_ID__c', apiName: 'Business_ID__c', sortable: true },
    { label: 'Store Id', fieldName: 'Restaurant_ID__c', apiName: 'Restaurant_ID__c', sortable: true },
];

const accountUserColumns = [
    { label: 'Duplicate', fieldName: 'duplicate', type: 'boolean', sortable: true },
    { label: 'Business Id', fieldName: 'Business_ID__c', sortable: true },
    { label: 'Store Id', fieldName: 'Restaurant_ID__c', sortable: true },
    { label: 'Account Name', fieldName: 'Name', sortable: true },
    { label: 'Agent Name', fieldName: 'username', sortable: true },
];

const resultAtmColumn = [
    { label: 'Status', fieldName: 'status', sortable: true },
    { label: 'Account', fieldName: 'accountname', sortable: true },
    { label: 'Agent', fieldName: 'agentname', sortable: true },
    { label: 'Change', fieldName: 'change', sortable: true },
];

const resultbulkATMColumns = [
    { label: 'Result', fieldName: 'status', sortable: true },
    { label: 'Account', fieldName: 'AccountName', sortable: true },
    { label: 'Agent', fieldName: 'UserName', sortable: true },
    { label: 'Change', fieldName: 'Change', sortable: true },
];

const resultAccountColumns = [
    { label: 'Result', fieldName: 'status', sortable: true },
    { label: 'AccountId', fieldName: 'AccountId', sortable: true },
    { label: 'Account Name', fieldName: 'AccountName', sortable: true },
    { label: 'Case Routing override', fieldName: 'CaseRouting', sortable: true }
];

const accountTeamColumns = [
    { label: 'Account Name', fieldName: 'AccountName', apiName: 'Account.Name', sortable: true },
    { label: 'User Name', fieldName: 'UserName', apiName: 'User.Name', sortable: true },
    { label: 'Role', fieldName: 'UserUserRole__c', apiName: 'User.UserRole__c', sortable: true },
    { label: 'Business Id', fieldName: 'AccountBusiness_ID__c', apiName: 'Account.Business_ID__c', sortable: true },
    { label: 'Store Id', fieldName: 'AccountRestaurant_ID__c', apiName: 'Account.Restaurant_ID__c', sortable: true }
]

const atmConfirmColumns = [
    { label: 'Account Name', fieldName: 'AccountName', sortable: true },
    { label: 'User Name', fieldName: 'UserName', sortable: true },
    { label: 'Team Role', fieldName: 'TeamMemberRole', sortable: true },
    { label: 'Business Id', fieldName: 'AccountBusiness_ID__c', sortable: true },
    { label: 'Store Id', fieldName: 'AccountRestaurant_ID__c', sortable: true }
]

const accountTeamResultColumns = [
    { label: 'Result', fieldName: 'status', sortable: true },
    { label: 'Account Name', fieldName: 'AccountName', sortable: true },
    { label: 'User Name', fieldName: 'UserName', sortable: true },
    { label: 'Team Role', fieldName: 'TeamMemberRole', sortable: true },
    { label: 'Business Id', fieldName: 'AccountBusiness_ID__c', sortable: true },
    { label: 'Store Id', fieldName: 'AccountRestaurant_ID__c', sortable: true }
]

const accountManualCols = [
    { label: 'Account Name', fieldName: 'Name', apiName: 'Name', sortable: true },
    { label: 'Business Id', fieldName: 'Business_ID__c', apiName: 'Business_ID__c', sortable: true },
    { label: 'Store Id', fieldName: 'Restaurant_ID__c', apiName: 'Restaurant_ID__c', sortable: true },
    { label: 'Case Routing', fieldName: 'Case_Routing_Override__c', apiName: 'Case_Routing_Override__c', sortable: true },
];

export default class LwcDdmxpManager extends LightningElement {
    accountManualCols = accountManualCols;
    accountTeamResultColumns = accountTeamResultColumns;
    atmConfirmColumns = atmConfirmColumns;
    accountTeamColumns = accountTeamColumns;
    operationSelectedValue = 'Manage Staff';
    accountUserColumns = accountUserColumns;
    addRemoveUserColumns = addRemoveUserColumns;
    accountColumns = accountColumns;
    addRemoveUserColumnsTable = addRemoveUserColumnsTable;
    resultAtmColumn = resultAtmColumn;
    resultbulkATMColumns = resultbulkATMColumns;
    resultAccountColumns = resultAccountColumns;
    columns = columns;
    sortDirection = 'asc';
    accountTeamSortDirection = 'asc';
    sortedBy;
    accountTeamSortedBy;
    assigmentValue = 'Add Assignments';
    operationTypeValue = '';
    @track
    draftValues = [];
    @track
    updateUserToSave = [];
    @track
    showSpinner = false;
    displaySelectedAccountUserDatatable = false;
    displayResultAccountUserDatatable = false;
    @track
    selectedUserIds = [];
    @track
    selectedAccountIds = [];
    @track
    selectedAccountRow = [];
    @track
    selectedAccountUserRows = [];
    @track
    bulkAccountTeamMembers = [];
    @track
    resultBulkAccountTeamMembers = [];
    @track
    resultBulkAccounts = [];
    @track
    selectedTeamAccountRows = [];
    pageNo = 1;
    showModal = false;
    @track
    selectedUserRows = [];
    @track
    resultAtmRecords = [];
    @track
    accountTeamRecords = [];
    @track
    confirmUserRecords = [];
    @track
    savedUserRecords = [];
    @track
    selectedAccountTeamIds = [];
    searchfields = ['Name', 'Username', 'Email', 'Profile.Name'];
    resultremovedATMData = [];
    resetUploadCSV = true;
    resetAccountCsv = true;
    resetManulaStaff = true;
    displayManualAddAssignment = true;
    displayManualRemoveDatatable = true;
    duplicateRecords = false;
    bulkTabName;
    @track
    bulkAccountRecords = [];
    @track selectedEditAccountIds = [];
    @track selectedEditAccountRows = [];
    @track savedEditAccountRows = [];
    resetEditAccountCsv = true;

    @wire(getUserPerm) getUserParm;

    get pageNo1() {
        if (this.pageNo == 1)
            return '';

        return 'slds-hide';
    }

    get pageNo2() {
        if (this.pageNo == 2)
            return '';

        return 'slds-hide';
    }

    get pageNo3() {
        if (this.pageNo == 3)
            return '';

        return 'slds-hide';
    }

    get backButtonDisablity() {
        return false;
    }

    get secondaryButtonVisibility() {
        if (this.pageNo == 3 && this.operationSelectedValue == 'Manage Staff'
            || this.pageNo == 2 && this.operationTypeValue == 'Bulk'
            || this.pageNo == 3 && this.operationTypeValue == 'Manual'
            || this.pageNo == 3 && this.operationTypeValue == 'Account Manual'
            || this.pageNo == 2 && this.operationTypeValue == 'Account Bulk') {

            return 'slds-hide';
        }
        return 'slds-button slds-button_neutral';
    }

    get secondaryButtonLabel() {
        if (this.pageNo == 1)
            return 'Cancel';

        return 'Back';
    }

    get primaryButtonLabel() {
        if ((this.pageNo == 2 && this.operationSelectedValue == 'Manage Staff')
            || (this.pageNo == 2
                && this.operationSelectedValue == 'Manage MXP Assignments'
                && this.operationTypeValue == 'Manual'
                && this.assigmentValue == 'Add Assignments')

            || (this.pageNo == 2
                && this.operationSelectedValue == 'Manage MXP Assignments'
                && this.operationTypeValue == 'Manual'
                && this.assigmentValue == 'Remove Assignments')

            || (this.pageNo == 1 && this.operationTypeValue == 'Bulk')
            || (this.pageNo == 1 && this.operationTypeValue == 'Account Bulk')
            || (this.pageNo == 2 && this.operationTypeValue == 'Account Manual')) {

            return 'Save';
        }

        if (this.pageNo == 3 && this.operationSelectedValue == 'Manage Staff'
            || this.pageNo == 2 && this.operationTypeValue == 'Bulk'
            || this.pageNo == 3 && this.operationTypeValue == 'Manual'
            || this.pageNo == 2 && this.operationTypeValue == 'Account Bulk'
            || this.pageNo == 3 && this.operationTypeValue == 'Account Manual') {
            return 'Done';
        }

        return 'Continue';
    }

    get primaryButtonDisablity() {
        if (this.pageNo == 2 && this.operationSelectedValue == 'Manage Staff' && this.updateUserToSave.length == 0)
            return true;
        return false;
    }

    handleTabChangeActive(event) {
        this.pageNo = 1;
        this.operationSelectedValue = event.target.value;
        this.resetManulaStaff = false;
        this.resetAccountCsv = false;
        setTimeout(() => {
            this.resetManulaStaff = true;
            this.resetAccountCsv = true;
        }, 7);
    }

    handleManualBulkTabChange(event) {
        this.pageNo = 1;
        this.operationTypeValue = event.target.value;
        this.resetUploadCSV = false;
        setTimeout(() => {
            this.resetUploadCSV = true;
        }, 7);
    }

    handleAddRemoveTabChange(event) {
        this.pageNo = 1;
        this.assigmentValue = event.target.value;
    }

    handleAccountTabChange(event) {
        this.pageNo = 1;
        this.operationTypeValue = event.target.value;
        this.resetAccountCsv = false;
        setTimeout(() => {
            this.resetAccountCsv = true;
        }, 7);
    }

    // Used to sort the 'Age' column
    sortBy(field, reverse, primer) {
        const key = primer
            ? function (x) {
                return primer(x[field]);
            }
            : function (x) {
                return x[field];
            };

        return function (a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    }

    onConfirmUserRecordsSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.confirmUserRecords];
        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.confirmUserRecords = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }

    onSavedUserRecordsSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.savedUserRecords];
        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.savedUserRecords = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }


    onresultBulkATMSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.resultBulkAccountTeamMembers];
        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.resultBulkAccountTeamMembers = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }


    onresultAtmRecordsSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.resultAtmRecords];
        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.resultAtmRecords = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }

    onAccountTeamHandleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.selectedAccountUserRows];
        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.selectedAccountUserRows = cloneData;
        this.accountTeamSortDirection = sortDirection;
        this.accountTeamSortedBy = sortedBy;
    }

    //remove
    handleCellchange(event) {

        let userObj = event.detail.draftValues[0];
        let isMerged = false;
        let updateUserClone = [];
        this.updateUserToSave.forEach(function (rec) {
            if (rec.id == userObj.id) {
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

    continueClick() {
        //Flow No 1 : Manage Staff 
        if (this.operationSelectedValue == 'Manage Staff') {
            if (this.pageNo == 1) {
                this.getChangedUserRecords();
                if (!this.confirmUserRecords) {
                    return;
                }
            } else if (this.pageNo == 2) {
                this.saveUser();
            } else {
                this.goToHomePage();
                return;
            }
            this.pageNo++;
        }
        else if (this.operationSelectedValue == 'Manage MXP Assignments') {
            //Flow No 2 : Manage MXP Assignments - Manual
            if (this.operationTypeValue == 'Manual') {
                if (this.assigmentValue == 'Add Assignments') {
                    if (this.pageNo == 1) {
                        this.getSelectedUserFromDatatable();
                        this.getSelectedAccountFromDatatable();
                        this.mergeTableOfAccountAndUser();
                    } else if (this.pageNo == 2) {
                        this.saveAccountTeamMember();
                    } else {
                        this.goToHomePage();
                        return;
                    }
                } else if (this.assigmentValue == 'Remove Assignments') {
                    if (this.pageNo == 1) {
                        this.getSelectedAccountTeamFromDatatable();
                    } else if (this.pageNo == 2) {
                        this.deleteAccountTeams();
                    } else {
                        this.goToHomePage();
                        return;
                    }

                }
            }//Flow No 3 : Manage MXP Assignments - Bulk
            else if (this.operationTypeValue == 'Bulk') {
                if (this.pageNo == 1) {
                    this.getuploadCSVrecord();
                    this.mixAccountTeamMember();
                } else {
                    this.goToHomePage();
                    return;
                }
            }
            this.pageNo++;
        } else if (this.operationSelectedValue == 'Manage MXP Accounts') {
            if (this.operationTypeValue == 'Account Bulk') {
                if (this.pageNo == 1) {
                    this.getUploadAccountCSV();
                    this.updateBulkAccounts();
                } else {
                    this.goToHomePage();
                    return;
                }
            } else if (this.operationTypeValue == 'Account Manual') {
                if (this.pageNo == 1) {
                    this.getEditedAccountFromDatatable();
                } else if (this.pageNo == 2) {
                    this.saveCaseRoutingUser();
                } else {
                    this.goToHomePage();
                    return;
                }
            }
            this.pageNo++;
        }
    }


    getChangedUserRecords() {
        this.confirmUserRecords = this.template.querySelector('[data-id="userSelectionDatatable2Id"]').getChangedUserRecords();
        this.updateUserToSave = this.template.querySelector('[data-id="userSelectionDatatable2Id"]').getChangedUserRecords();
    }

    getuploadCSVrecord() {
        let selectedUserRow = this.template.querySelector('[data-id="uploadcsv"]').getAllRows();
        this.bulkAccountTeamMembers = selectedUserRow;
    }

    getUploadAccountCSV() {
        let accountRecords = this.template.querySelector('[data-id="uploadAccountcsv"]').getAllAccountData();
        this.bulkAccountRecords = accountRecords;
    }

    getSelectedUserFromDatatable() {
        let selectedUserRow = this.template.querySelector('[data-id="userSelectionDatatableId"]').getSelectedRows();
        this.selectedUserRows = selectedUserRow;
        selectedUserRow.forEach(function (rec) {
            this.selectedUserIds.push(rec.Id);
        }.bind(this));
    }

    getEditedAccountFromDatatable() {
        let selectedEditAccountRows = this.template.querySelector('[data-id="accountEditDatatableId"]').getChangedUserRecords();
        this.selectedEditAccountRows = selectedEditAccountRows;
        selectedEditAccountRows.forEach(function (rec) {
            this.selectedEditAccountIds.push(rec.Id);
        }.bind(this));
    }

    getSelectedAccountFromDatatable() {

        let selectedAccountRow = this.template.querySelector('[data-id="accountSelectionDatatableId"]').getSelectedRows();
        this.selectedAccountRows = selectedAccountRow;
        selectedAccountRow.forEach(function (rec) {
            this.selectedAccountIds.push(rec.Id);
        }.bind(this));
        this.selectedAccountRow = selectedAccountRow;
    }

    getSelectedAccountTeamFromDatatable() {
        let selectedTeamAccountRows = this.template.querySelector('[data-id="accountTeamSelectionDatatableId"]').getSelectedRows();
        this.selectedTeamAccountRows = selectedTeamAccountRows;
        selectedTeamAccountRows.forEach(function (rec) {
            this.selectedAccountTeamIds.push(rec.Id);
        }.bind(this));
    }

    deleteAccountTeams() {
        this.showSpinner = true;
        this.displayManualRemoveDatatable = false;
        removeAccountTeams({ accountTeamIds: this.selectedAccountTeamIds }).then(data => {
            this.displayManualRemoveDatatable = true;
            let resultremovedATMData = this.selectedTeamAccountRows;
            resultremovedATMData.forEach(function (rec) {
                rec.status = 'Success';
            });
            this.resultremovedATMData = resultremovedATMData;
            this.showToast('success', 'Success', 'Records Deleted Successfully!');
            this.showSpinner = false;
        }).catch(error => {
            console.log('Exception:::', error);
            let resultremovedATMData = this.selectedTeamAccountRows;
            resultremovedATMData.forEach(function (rec) {
                rec.status = 'Failed';
            });
            this.resultremovedATMData = resultremovedATMData;
            this.handleException(error);
        });
    }

    mergeTableOfAccountAndUser() {
        let userIdSet = [];
        let accountIdSet = [];
        let selectedAccountUserRows = [];
        let accountsAndUserRowsSelected = [];

        this.selectedUserRows.forEach(function (userRec) {
            this.selectedAccountRow.forEach(function (rec) {
                rec.username = userRec.Name;
                rec.userid = userRec.Id;
                selectedAccountUserRows.push(JSON.parse(JSON.stringify(rec)));
            });
        }.bind(this));

        this.selectedAccountUserRows = selectedAccountUserRows;
        accountsAndUserRowsSelected = JSON.parse(JSON.stringify(this.selectedAccountUserRows));
        for (var i = 0; i < accountsAndUserRowsSelected.length; i++) {
            userIdSet.push(accountsAndUserRowsSelected[i].userid);
            accountIdSet.push(accountsAndUserRowsSelected[i].Id);
        }

        this.displaySelectedAccountUserDatatable = false;
        getAccountTeamExistingRec({ 'userId': userIdSet, 'accountId': accountIdSet }).then(result => {
            this.accountTeamRecords = result;
            this.mergingUserWithAccountTeams();
        }).catch(error => {
            this.displaySelectedAccountUserDatatable = true;
            console.log('Exception:::', error);
            this.handleException(error);
        });
    }

    mergingUserWithAccountTeams() {
        for (var i = 0; i < this.selectedAccountUserRows.length; i++) {
            if (this.accountTeamRecords[this.selectedAccountUserRows[i].userid + this.selectedAccountUserRows[i].Id]) {
                this.selectedAccountUserRows[i].duplicate = true;
                this.duplicateRecords = true;
            } else {
                this.selectedAccountUserRows[i].duplicate = false;
            }
        }
        this.displaySelectedAccountUserDatatable = true;
    }

    saveUser() {
        if (this.updateUserToSave.length > 0) {
            this.updateUserToSave.forEach(function (userRec) {
                userRec.Out_Of_Office_End_Date__c = userRec.Out_Of_Office_End_Date__c && userRec.Out_Of_Office_End_Date__c.length > 0 ? userRec.Out_Of_Office_End_Date__c.split('T')[0] : null;
            });
            this.showSpinner = true;
            this.resetManulaStaff = false;
            saveOOOUser({ usersDataString: JSON.stringify(this.updateUserToSave) }).then(data => {
                this.showSpinner = false;
                this.resetManulaStaff = true;
                this.showToast('success', 'Success', 'Records Saved Successfully!');
                this.savedUserRecords = data.users;
            }).catch(error => {
                console.log('Exception:::', error);
                this.handleException(error);
            });
        }
    }

    saveAccountTeamMember() {
        this.displayResultAccountUserDatatable = false;
        let atmRecs = [];
        let idNameMap = {};
        let operation = '';
        this.selectedAccountUserRows.forEach(function (record) {
            if (record.duplicate == false) {
                atmRecs.push({ AccountId: record.Id, UserId: record.userid, teamMemberRole: 'MXP' });
                idNameMap[record.Id] = record.Name;
                idNameMap[record.userid] = record.username;
            }
        });

        operation = this.assigmentValue == 'Add Assignments' ? 'Add' : 'Remove';

        this.showSpinner = true;
        this.displayManualAddAssignment = false;
        saveAccountTeam({ accTeamMembStr: JSON.stringify(atmRecs), operation: operation }).then(data => {
            this.showSpinner = false;
            this.displayManualAddAssignment = true;
            let resultATMRecs = [];
            data.atmStr.forEach(function (atmRec) {
                if (this.assigmentValue == 'Add Assignments') {
                    atmRec.status = atmRec.Id ? 'Success' : 'Failed';
                } else {
                    atmRec.status = atmRec.Id ? 'Success' : 'Failed';
                }
                atmRec.accountname = idNameMap[atmRec.AccountId];
                atmRec.agentname = idNameMap[atmRec.UserId];
                atmRec.change = this.assigmentValue == 'Add Assignments' ? 'Add' : 'Remove';
                resultATMRecs.push(atmRec);
            }.bind(this));

            this.resultAtmRecords = resultATMRecs;
            this.displayResultAccountUserDatatable = true;
            if (operation == 'Add') {
                this.showToast('success', 'Success', 'Records Saved Successfully!');
            }
        }).catch(error => {
            console.log('Exception:::', error);
            this.handleException(error);
        });

    }

    mixAccountTeamMember() {
        this.showSpinner = true;
        this.resetUploadCSV = false;
        let bulkAccountTeamsWithoutStatus = [];
        let bulkAccountTeamsWithStatus = [];
        for (var i = 0; i < this.bulkAccountTeamMembers.length; i++) {
            if (this.bulkAccountTeamMembers[i].status == null) {
                bulkAccountTeamsWithoutStatus.push(this.bulkAccountTeamMembers[i]);
            } else {
                bulkAccountTeamsWithStatus.push(this.bulkAccountTeamMembers[i]);
            }
        }

        saveAccountTeam({ accTeamMembStr: JSON.stringify(bulkAccountTeamsWithoutStatus), operation: 'mix' }).then(data => {
            this.showSpinner = false;
            this.resetUploadCSV = true;
            let request = JSON.parse(JSON.parse(JSON.stringify(data.request)));
            request.forEach(function (rec) {
                rec.status = 'Success';
            });
            this.resultBulkAccountTeamMembers = request;
        }).catch(error => {
            console.log('Exception:::', error);
            this.showSpinner = false;
            this.resetUploadCSV = true;
            let request = JSON.parse(JSON.stringify(bulkAccountTeamsWithoutStatus));
            request.forEach(function (rec) {
                rec.status = 'Error';
            });
            this.resultBulkAccountTeamMembers = request;
            this.handleException(error);
        });
    }

    updateBulkAccounts() {
        this.showSpinner = true;

        let bulkAccountWithoutStatus = [];
        let bulkAccountWithStatus = [];
        for (var i = 0; i < this.bulkAccountRecords.length; i++) {
            if (this.bulkAccountRecords[i].status == '') {
                bulkAccountWithoutStatus.push(this.bulkAccountRecords[i]);
            } else {
                bulkAccountWithStatus.push(this.bulkAccountRecords[i]);
            }
        }
        this.resetAccountCsv = false;
        updateAccountRecords({ mxAccRecStr: JSON.stringify(bulkAccountWithoutStatus) }).then(data => {
            this.showSpinner = false;
            this.resetAccountCsv = true;
            let request = JSON.parse(JSON.stringify(bulkAccountWithoutStatus));
            request.forEach(function (rec) {
                rec.status = 'Success';
            });
            this.resultBulkAccounts = request;
            this.showToast('success', 'Success', 'Records Saved Successfully!');
        }).catch(error => {
            console.log('Exception:::', error);
            this.showSpinner = false;
            this.resetAccountCsv = true;
            let request = JSON.parse(JSON.stringify(bulkAccountWithoutStatus));
            request.forEach(function (rec) {
                rec.status = 'Error';
            });
            this.resultBulkAccounts = request;
            this.handleException(error);
        });
    }

    secondaryBtnClick() {
        if (this.pageNo == 1) {
            this.closeModal();
            return;
        }
        this.pageNo--;
    }

    async handleSave(event) {
        const updatedFields = event.detail.draftValues;
    }

    closeModal() {
        this.showModal = false;
    }

    goToHomePage() {
        this.resetValues();
        this.navigateFirstPage();
    }

    resetValues() {
        this.sortDirection = 'asc';
        this.sortedBy;
        this.accountTeamSortedBy;
        this.draftValues = [];
        this.updateUserToSave = [];
        this.showSpinner = false;
        this.displaySelectedAccountUserDatatable = false;
        this.displayResultAccountUserDatatable = false;
        this.selectedUserIds = [];
        this.selectedAccountIds = [];
        this.selectedAccountRow = [];
        this.selectedAccountUserRows = [];
        this.bulkAccountTeamMembers = [];
        this.resultBulkAccountTeamMembers = [];
        this.resultBulkAccounts = [];
        this.pageNo = 1;
        this.selectedUserRows = [];
        this.resultAtmRecords = [];
        this.selectedTeamAccountRows = [];
        this.selectedAccountTeamIds = [];
        this.duplicateRecords = false;
        this.bulkAccountRecords = [];
        this.selectedEditAccountRows = [];
    }

    navigateFirstPage() {
        this.pageNo = 1;
    }

    openModal() {
        this.showModal = true;
    }

    showToast(variant, title, message) {
        const event = new ShowToastEvent({
            title: title,
            variant: variant,
            message: message,
        });
        this.dispatchEvent(event);
    }

    saveCaseRoutingUser() {
        if (this.selectedEditAccountRows.length > 0) {
            this.showSpinner = true;
            this.resetEditAccountCsv = false;
            let accs = [];
            this.selectedEditAccountRows.forEach(function(rec){
                accs.push({'Id': rec.Id, 'Case_Routing_Override__c':rec.Case_Routing_Override__c});
            });
            saveAccounts({ accountRecordString: JSON.stringify(accs) })
                .then(data => {
                    this.showSpinner = false;
                    this.resetEditAccountCsv = true;
                    this.savedEditAccountRows = data.accounts;
                    this.showToast('success', 'Success', 'Records Saved Successfully!');
                }).catch(error => {
                    console.log('Exception:::', error);
                    this.showError(error.body.fieldErrors['Case_Routing_Override__c'][0].message);
                    this.showSpinner = false;
                    this.handleException(error);
                });
        }
    }

    showError(message) {
        this.showToast('error', 'Failed', message);
    }

    handleException(error) {
        this.showToast('error', 'Failed', error.body.message);
    }
}