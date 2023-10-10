/*****************************************************************************************************************************
*
* Imports
*
*****************************************************************************************************************************/
import { LightningElement, wire,track } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import CSVParser from '@salesforce/resourceUrl/SRDdPapaParse';
import getFilterCriteria from '@salesforce/apex/CDdQueueManagerController.getFilterCriteria';
import getUsers from '@salesforce/apex/CDdQueueManagerController.getUsers';
import updateQueues from '@salesforce/apex/CDdQueueManagerController.updateQueues';
import { cloneObject } from 'c/lwcDdUtils';


/*****************************************************************************************************************************
*
* CSS Class Consts
*
*****************************************************************************************************************************/

const ELE_MODAL = '[data-id="modal"]';

/*****************************************************************************************************************************
*
* Functional Consts
*
*****************************************************************************************************************************/
const userColumns = [
    {   label: 'Email',
        fieldName: 'email'
    },
    {   label: 'Role',
        fieldName: 'role'
    },
    {   label: 'Current Queue',
        fieldName: 'currentQueues'
    }
];

const roleColumns = [
    {   label: 'Role Name',
        fieldName: 'value'
    }
];

const queueColumns = [
    {   label: 'Queue Name',
        fieldName: 'label'
    }
];


const STEP1_SELCTION_OPTIONS = [
    { label: 'Roles', value: 'role' },
    { label: 'Email', value: 'email' },
    { label: 'File', value: 'file' },
];

export default class LWCWizard extends LightningElement {
    /*****************************************************************************************************************************
    *
    * Private Variables
    *
    *****************************************************************************************************************************/

    userColumns = userColumns;
    roleColumns = roleColumns;
    queueColumns = queueColumns;
    activeTabName ='';

    currentRoleList = [];
    initialRoleList = [];
    currentQueueList = [];
    initialQueueList = [];
    usersList = [];
    initialUserList = [];

    showUsers = false;
    selectedQueues = [];
    selectedFileName = "";
    emailList =[];
    userIdsList = [];
    selectedUserByEmail = [];
    selectedRoleItems =[];
    selectedUsers  = [];
    selectedUserIds  = new Set();
    regularSelection = new Set();
    showSelectedUsersOnModal  = [];


    parserInitialized = false;
    errorMsg = '';
    isLoading = false;
    showError = false;
    showSuccess = false;

    isRoleFlow = false;
    isEmailFlow = false;
    isFileFlow = false;
    disableQueueUpdateButton = true;

    showErrorPopUp = false;
    errorMsgPopUp = '';
    currentStep = '1';

    /*****************************************************************************************************************************
    *
    * UI Getters - Custom getters for variables in the HTML
    *
    *****************************************************************************************************************************/
    get options() {
        return STEP1_SELCTION_OPTIONS;
    }

    get isStepOne() {
        return this.currentStep === "1";
    }

    get isStepTwo() {
        return this.currentStep === "2";
    }

    get isStepThree() {
        return this.currentStep === "3";
    }

    get selectedUserTableLabelValue(){
        return "Selected Users " +' - '+ this.showSelectedUsersOnModal.length;
    }
    /*****************************************************************************************************************************
    *
    * LifeCycle Hooks (renderedCallback,connectedCallback)
    *
    *****************************************************************************************************************************/

    connectedCallback() {
        getFilterCriteria({})
            .then(result => {
                this.initialRoleList = result.roleList;
                this.currentRoleList = result.roleList;
                this.currentQueueList = result.queueList;
                this.initialQueueList = result.queueList;
                if(!this.parserInitialized){
                    loadScript(this, CSVParser)
                        .then(() => {
                            this.parserInitialized = true;
                        })
                        .catch(error => {
                            this.showError = true;
                            this.errorMsg = error;
                        });
                }
            })
            .catch(error => {
                this.showError = true;
                this.errorMsg = error.body.message;
            });
    }

    /*****************************************************************************************************************************
    *
    * Event Handlers
    *
    *****************************************************************************************************************************/
    setFlowAttributes(event){
        this.activeTabName = event.target.value;
        if (this.activeTabName == "email"){
            this.isRoleFlow = false;
            this.isFileFlow = false;
            this.isEmailFlow = true;
        }
        if (this.activeTabName == "role"){
            this.isEmailFlow = false;
            this.isFileFlow = false;
            this.isRoleFlow = true;
        }
        if (this.activeTabName == "file"){
            this.isRoleFlow = false;
            this.isEmailFlow = false;
            this.isFileFlow = true;
        }
    }


    handleUserTableRowAction(event){
        event.stopPropagation();
        const selectedUserRows =  this.template.querySelector('[data-id="userTable"]').selectedRecordObjects;
        this.showSelectedUsersOnModal = [...selectedUserRows];
        this.disableQueueUpdateButton = selectedUserRows.length === 0;
    }

    handleFileChange(event){
        if(event.target.files.length > 0){
            const file = event.target.files[0];
            this.selectedFileName = file.name;
            Papa.parse(file, {
                quoteChar: '"',
                header: 'true',
                complete: (results) => {
                    this.emailList = [];
                    results.data.forEach(element => {
                        if(element.email){
                            this.emailList.push(element.email);
                        } else if (element.Email){
                            this.emailList.push(element.Email);
                        }
                    });
                },
                error: (error) => {
                    this.errorMsg = error;
                }
            })
        }
    }

    // When Filter value is added or removed
    handleUserSearchOnChange(event) {
        event.stopPropagation();
        for (let currentItem of event.detail.selectedOptions) {
            this.userIdsList.push(currentItem.value);
            this.selectedUserByEmail.push(currentItem.dropDownLabel);
        }
    }

    /*****************************************************************************************************************************
    *
    * Logic / Helper methods
    *
    *****************************************************************************************************************************/

    validateGetUsers() {
        this.showError = false;
        this.selectedRoleItems = [];
        this.usersList = [];
        this.emailList = [];
        if(this.isRoleFlow){
            this.selectedFileName = '';
            this.emailList =[];
            this.userIdsList = [];
            this.selectedUserByEmail =[];
            let selectedRows =  this.template.querySelector('c-dd-data-table-with-filter').selectedRecordObjects;
            if(selectedRows.length > 0){
                for (let currentItem of selectedRows) {
                    this.selectedRoleItems.push(currentItem.value);
                }
            }else{
                this.showError = true;
                this.errorMsg = "Please pick a role before proceeding.";
            }
        }
        else if(this.isEmailFlow){
            this.emailList =[];
            this.selectedRoleItems =[];
            this.selectedFileName = '';
            if (this.userIdsList.length === 0){
                this.showError = true;
                this.errorMsg = "User is required for the search.";
            }
        }
        else if(this.isFileFlow){
            this.userIdsList = [];
            this.selectedUserByEmail =[];
            this.selectedRoleItems =[];
            let data = this.template.querySelector('c-lwc-dd-csv-to-data-table-component').tableData;
            for (let currentItem of data) {
                this.emailList.push(currentItem.Email);
            }
            if (this.emailList.length === 0 ){
                this.showError = true;
                this.errorMsg = "No emails in the csv file.";
            }
        }
        if(!this.showError){
            this.currentStep = "2";
            this.isLoading = true;
            getUsers({ roles: this.selectedRoleItems, emails: this.emailList, userIds :this.userIdsList, activeTab : this.activeTabName})
                .then(result => {
                    this.isLoading = false;
                    this.usersList = result;
                    this.initialUserList = result;
                    if (this.usersList.length > 0) {
                        this.showSelectedUsersOnModal = [];
                        if(this.usersList.length == 1){
                            this.showSelectedUsersOnModal.push(this.usersList[0]);
                            this.selectedUsers.push(this.usersList[0].id);
                            this.disableQueueUpdateButton = false;
                        }else{
                            this.selectedUsers =[];
                            this.disableQueueUpdateButton = true;
                        }
                        this.showUsers = true;
                    } else {
                        this.showUsers = false;
                    }
                })
                .catch(error => {
                    this.isLoading = false;
                    this.showError = true;
                    this.errorMsg = error.body.message;
                });
        }
    }

    handlePrev(){
        this.disableQueueUpdateButton = true;
        this.currentRoleList = this.initialRoleList;
        if(this.currentStep == "3"){
            this.currentStep = "2";
        }
        else if(this.currentStep = "2"){
            this.currentStep = "1";
        }
    }


    handleDownloadCSVFile(){

        let rowEnd = '\n';
        let csvString = '';

        for(let i=0; i < this.userColumns.length; i++){
            if (i > 0){
                csvString += ','
            }
            csvString += this.userColumns[i].label;

        }
        csvString += rowEnd;

        // main for loop to get the data based on key value
        for(let i=0; i < this.usersList.length; i++){
            let colValue = 0;
            for(let j=0; j < this.userColumns.length; j++){
                let columnName = this.userColumns[j].fieldName;
                // add , after every value except the first.
                if(colValue > 0){
                    csvString += ',';
                }
                // If the column is undefined, it as blank in the CSV file.
                let value = this.usersList[i][columnName] === undefined ? '' : this.usersList[i][columnName];
                csvString += '"'+ value +'"';
                colValue++;
            }
            csvString += rowEnd;
        }

        // Creating anchor element to download
        let downloadElement = document.createElement('a');

        // This  encodeURI encodes special characters, except: , / ? : @ & = + $ # (Use encodeURIComponent() to encode these characters).
        downloadElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(csvString);
        downloadElement.target = '_self';
        // CSV File Name
        downloadElement.download = 'users.csv';
        // below statement is required if you are using firefox browser
        document.body.appendChild(downloadElement);
        // click() Javascript function to download CSV file
        downloadElement.click();
    }



    openQueueModal(){
        this.showErrorPopUp = false;
        let control = this.template.querySelector(ELE_MODAL);
        if (control) {
            control.show();
        }
        this.currentQueueList = this.initialQueueList;
    }

    closeRoleModal() {
        this.showSelectedUsersOnModal = [];
        const selectedQueues = this.template.querySelector('[data-id="queueTable"]').selectedRecordObjects;
        let selected = [];
        for (let i = 0; i < selectedQueues.length; i++) {
            selected.push(selectedQueues[i].id);
        }
        this.selectedQueues = selected;
        this.currentQueueList = this.initialQueueList;
        // to close modal set isModalOpen tarck value as false
    }

    submitDetails() {
        this.showErrorPopUp = false;
        //get the selected user Ids
        if(this.showSelectedUsersOnModal.length > 0){
            for (let currentItem of this.showSelectedUsersOnModal) {
                this.selectedUsers.push(currentItem.id);
            }
        }
        //get the selected queue ids
        var selectedQueueRecords =  this.template.querySelector('[data-id="queueTable"]').selectedRecordObjects;
        if(selectedQueueRecords.length > 0){
            for (let currentItem of selectedQueueRecords) {
                this.selectedQueues.push(currentItem.value);
            }
        }

        if(this.selectedQueues.length==0){
            this.showErrorPopUp = true;
            this.errorMsgPopUp = 'Please select queues.';
        }
        if (!this.showErrorPopUp){
            this.isLoading = true;
            updateQueues({ userIds: this.selectedUsers, queueList: this.selectedQueues})
                .then(result => {
                    this.showSuccess = true;
                    getUsers({ roles: [], emails: [], userIds : this.selectedUsers, activeTab : 'refreshData'})
                    .then(result => {
                        this.showSelectedUsersOnModal =[];
                        for (let i = 0; i < result.length; i++) {
                            this.showSelectedUsersOnModal.push(result[i]);
                        }
                        this.isLoading = false;
                        this.currentStep = "3";
                    }).catch(error => {
                        this.isLoading = false;
                        this.showError = true;
                        this.errorMsg = error.body.pageErrors[0].message;
                    });
                })
                .catch(error => {
                    this.isLoading = false;
                    this.showError = true;
                    this.errorMsg = error.body.pageErrors[0].message;
                });
        }
    }

    handleReset(){
        this.currentStep = "1";
        this.selectedFileName = "";
        this.showUsers = false;
        this.usersList = [];
        this.selectedUsers  = [];
        this.showSelectedUsersOnModal  = [];
        this.isRoleFlow = false;
        this.isEmailFlow = false;
        this.isFileFlow = false;
        this.selectedRoleItems =[];
        this.emailList = [];
        this.disableQueueUpdateButton = true;
        this.selectedQueues = [];
        this.showErrorPopUp = false;
        this.errorMsgPopUp = '';
        this.showError = false;
        this.errorMsg ='';
        this.activeTabName ='';
        this.userIdsList = [];
        this.selectedUserByEmail =[];

    }
}