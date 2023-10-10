import { LightningElement, track, api } from 'lwc';
import getAccountTeamExistingRec from '@salesforce/apex/CDdMXPManagerController.getExistingAcccountTeams';
import getExistingAccountRecords from '@salesforce/apex/CDdMXPManagerController.getExistingAccountRecords';

const columnsRec = [
    { label: 'Status', fieldName: 'status', type: 'text' },
    { label: 'AccountId', fieldName: 'AccountId' },
    { label: 'UserId', fieldName: 'UserId' },
    { label: 'AccountName', fieldName: 'AccountName' },
    { label: 'UserName', fieldName: 'UserName' },
    { label: 'Change', fieldName: 'Change' },
];

const accountColumns = [
    { label: 'Status', fieldName: 'status', type: 'text' },
    { label: 'AccountId', fieldName: 'AccountId' },
    { label: 'AccountName', fieldName: 'AccountName' },
    { label: 'CaseRouting', fieldName: 'CaseRouting' }
];

export default class LwcDdUploadCSV extends LightningElement {
    @track columns = columnsRec;
    @track accountColumns = accountColumns;
    @track data;
    @track accountsAndUserRowsCombination;
    @track showLoadingSpinner = false;
    @api bulktabchange;
    csvFormateMessage = false;
    dataTableVisibility = false;
    MAX_FILE_SIZE = 2000000; //Max file size 2.0 MB
    filesUploaded = [];
    filename;
    accountTeamRecords = [];
    accountRecords = [];
    duplicateRecords = false;
    accountDataVisibility = false;
    @track accountRecordsBulk;

    importcsv(event) {
        if (event.target.files.length > 0) {
            this.duplicateRecords = false;
            this.filesUploaded = event.target.files;
            this.filename = event.target.files[0].name;
            this.readFiles();
            if (this.filesUploaded.size > this.MAX_FILE_SIZE) {
                this.filename = 'File Size is to long to process';
            }
        }
    }
    readFiles() {
        [...this.template
            .querySelector('lightning-input')
            .files
        ].forEach(async file => {
            try {
                if (this.bulktabchange == 'Bulk') {
                    let userIdSet = [];
                    let accountIdSet = [];
                    const result = await this.load(file);
                    // Process the CSV here
                    this.showLoadingSpinner = false;
                    let result2 = this.csvJSON(result);
                    result2 = result2.replace(/\\"/g, "");
                    this.data = JSON.parse(result2);
                    this.accountsAndUserRowsCombination = JSON.parse(JSON.stringify(this.data));
                    for (var i = 0; i < this.accountsAndUserRowsCombination.length; i++) {
                        userIdSet.push(this.accountsAndUserRowsCombination[i].UserId);
                        accountIdSet.push(this.accountsAndUserRowsCombination[i].AccountId);
                    }
                    this.dataTableVisibility = false;
                    getAccountTeamExistingRec({ 'userId': userIdSet, 'accountId': accountIdSet }).then(result => {
                        this.accountTeamRecords = result;
                        this.mergingUserWithAccountTeams();
                        this.dataTableVisibility = true;
                    }).catch(error => {
                        console.log('Exception:::', error);
                        this.handleException(error);
                    });
                } else {
                    this.dataTableVisibility = false;
                    let accountIdArr = [];
                    const result = await this.load(file);
                    // Process the CSV here
                    this.showLoadingSpinner = false;
                    let result2 = this.csvJSON(result);
                    result2 = result2.replace(/\\"/g, "");
                    // this.processData(result);
                    this.data = JSON.parse(result2);
                    this.accountRecordsBulk = JSON.parse(JSON.stringify(this.data));
                    for (var i = 0; i < this.accountRecordsBulk.length; i++) {
                        accountIdArr.push(this.accountRecordsBulk[i].AccountId);
                    }
                    getExistingAccountRecords({ 'accountIds': accountIdArr }).then(result => {
                        this.accountRecords = result;
                        this.checkingAccountsInDatabase();
                        this.accountDataVisibility = true;
                    }).catch(error => {
                        console.log('Exception:::', error);
                        this.handleException(error);
                    });

                }
            } catch (error) {
                // handle file load exception
                console.log('exception....' + error);
                console.log('exception....' + JSON.stringify(error));
                this.handleException(error);
            }
        });
    }

    async load(file) {
        return new Promise((resolve, reject) => {
            this.showLoadingSpinner = true;
            const reader = new FileReader();
            // Read file into memory as UTF-8      
            reader.onload = function () {
                resolve(reader.result);
            };
            reader.onerror = function () {
                reject(reader.error);
            };
            reader.readAsText(file);
        });
    }


    //process CSV input to JSON
    csvJSON(csv) {
        var lines = csv.split(/\r\n|\n/);

        var result = [];
        var headers = lines[0].split(",");

        if(this.bulktabchange == 'Bulk') {
            for(let i = 0; i < this.columns.length; i++) {
                if(!headers.includes(this.columns[i].label) && this.columns[i].label != 'Status') {
                    this.csvFormateMessage = true;
                    break;
                }
                else {
                    this.csvFormateMessage = false;
                }
            }
        }
        else {
            for(let i = 0; i < this.accountColumns.length; i++) {
                if(!headers.includes(this.accountColumns[i].label) && this.accountColumns[i].label != 'Status') {
                    this.csvFormateMessage = true;
                    break;
                }
                else {
                    this.csvFormateMessage = false;
                }
            }
        }

        if(!this.csvFormateMessage) {
            for (var i = 1; i < lines.length - 1; i++) {
                var obj = {};
                var currentline = lines[i].split(",");
                for (var j = 0; j < headers.length; j++) {
                    obj[headers[j]] = currentline[j];
                }
                result.push(obj);
            }
        }

        return JSON.stringify(result);
    }

    mergingUserWithAccountTeams() {
        for (var i = 0; i < this.accountsAndUserRowsCombination.length; i++) {
            if (this.accountTeamRecords[this.accountsAndUserRowsCombination[i].UserId + this.accountsAndUserRowsCombination[i].AccountId]
                && this.accountsAndUserRowsCombination[i].Change == 'Add') {
                this.accountsAndUserRowsCombination[i].status = 'Duplicate';
                this.duplicateRecords = true;
            } else if (!this.accountTeamRecords[this.accountsAndUserRowsCombination[i].UserId + this.accountsAndUserRowsCombination[i].AccountId]
                && this.accountsAndUserRowsCombination[i].Change == 'Remove') {
                this.accountsAndUserRowsCombination[i].status = 'No such record exists';
            }
        }
    }

    checkingAccountsInDatabase() {
        for (var i = 0; i < this.accountRecordsBulk.length; i++) {
            if (this.accountRecords[this.accountRecordsBulk[i].AccountId]) {
                this.accountRecordsBulk[i].status = '';
            } else {
                this.accountRecordsBulk[i].status = 'No such record exists';
            }
        }
    }

    @api
    getAllRows() {
        return this.accountsAndUserRowsCombination;
    }

    @api
    getAllAccountData() {
        return this.accountRecordsBulk;
    }

    handleException(error) {
        this.showToast('error', 'Failed', error.body.message);
    }
}