import { LightningElement, track, api, wire} from 'lwc';
import getRelatedAccounts from '@salesforce/apex/CDdCloneOppAndQuote.getRelatedAccounts';
import cloneData from '@salesforce/apex/CDdCloneOppAndQuote.cloneOppandQuote';
import getSelectedAccounts from '@salesforce/apex/CDdCloneOppAndQuote.getSelectedAccounts';
import getSelectedStoreIds from '@salesforce/apex/CDdCloneOppAndQuote.getSelectedStoreIds';

import successLabel from '@salesforce/label/c.Clone_Opp_and_Quote_Success';
import selectAccountLabel from '@salesforce/label/c.Clone_Opp_and_Quote_Select_Account';
import accountClonedLabel from '@salesforce/label/c.Clone_Opp_and_Quote_Account_Cloned';
import noChildLabel from '@salesforce/label/c.Clone_Opp_and_Quote_No_Child';
import noRelatedLabel from '@salesforce/label/c.Clone_Opp_and_Quote_No_Related';
import accountNotFoundLabel from '@salesforce/label/c.Clone_Opp_and_Quote_Account_Not_Found';
import errorCloningLabel from '@salesforce/label/c.Clone_Opp_and_Quote_Error_Cloning';
import selectValuesLabel from '@salesforce/label/c.Clone_Opp_and_Quote_Select_Values';
import csvInstructionsLabel from '@salesforce/label/c.Clone_Opp_and_Quote_CSV_Instructions';
import csvImportErrorLabel from '@salesforce/label/c.Clone_Opp_and_Quote_Import_Error';
import selectedStoresLabel from '@salesforce/label/c.Clone_Opp_and_Quote_Selected_Stores';

const columns = [
    { label: 'Store Name', fieldName: 'Name', sortable: false, hideDefaultActions: true},
    { label: 'Store Id', fieldName: 'RestaurantId', sortable: false, hideDefaultActions: true},
    { label: 'Currently Active', fieldName: 'CurrentlyActive', sortable: false, hideDefaultActions: true},
    { label: 'Is Partner (NIMDA)', fieldName: 'IsPartnerNimda', sortable: false, hideDefaultActions: true},
];

export class TabData {
    constructor() {
        this._dataTable = [];
        this._dataTableCloned = [];
        this._showTable = false;
        this._showTableCloned = false;
        this._showError = false;
        this._errorMessages = [];
        this._cloneDisabled = true;
        this._selectedStores = 0;
    };
    get dataTable() { return this._dataTable; }
    set dataTable(dataTable) { this._dataTable = dataTable; }
    get dataTableCloned() { return this._dataTableCloned; }
    set dataTableCloned(dataTableCloned) { this._dataTableCloned = dataTableCloned; }
    get showTable() { return this._showTable; }
    set showTable(showTable) { this._showTable = showTable; }
    get showTableCloned() { return this._showTableCloned; }
    set showTableCloned(showTableCloned) { this._showTableCloned = showTableCloned; }
    get showError() { return this._showError; }
    set showError(showError) { this._showError = showError; }
    get errorMessages() { return this._errorMessages; }
    set errorMessages(errorMessages) { this._errorMessages = errorMessages; }
    get cloneDisabled() { return this._cloneDisabled; }
    set cloneDisabled(cloneDisabled) { this._cloneDisabled = cloneDisabled; }
    get selectedStores() { return this._selectedStores; }
    set selectedStores(selectedStores) { this._selectedStores = selectedStores; }
};

export default class LwcDdCloneOppAndQuotes extends LightningElement {
    @track errorHeaderMessages = [];
    @api oppId;
    @api oppName;
    @api accountName;
    @api quoteName;
    @api quoteId;
    @api currentStore;
    @api bulkActivation;

    columns = columns;
    working = true;    
    cloneDisabled;
    selectedStores = 0;
    activeTab;
    showSuccess = false;
    showTabs = true;

    returnVariant = 'destructive';
    batchId;        
    accountStoreLabel;
    labels = {
        successLabel,
        selectAccountLabel,
        accountClonedLabel,
        selectValuesLabel,
        csvInstructionsLabel,
        selectedStoresLabel
    };
    selectedAccounts = [];
    selectedAccountdata = [];
    selectedAccountsFromLookUp = [];
    checkBoxBulkActivation = false;
    
    stageValue;
    get stageOptions() {
        return [
            { label: 'Contract Signed', value: 'Contract Signed' },
            { label: 'Closed Won', value: 'Closed Won' },
        ];
    }    

    @track tabDataChild = new TabData();
    @track tabDataRelated = new TabData();
    @track tabDataSearch = new TabData();
    @track tabDataImport = new TabData();
 

    @track searchDataTable = [];
    @track searchDataTableCloned = [];
    @track searchShowTable = false;
    @track searchShowTableCloned = false;
    @track searchShowError = false;
    @track searchErrorMessages = [];

    @track importDataTable = [];
    @track importDataTableCloned = [];
    @track importShowTable = false;
    @track importShowTableCloned = false;
    @track importShowError = false;
    @track importErrorMessages = [];

    
    @wire(getRelatedAccounts,{ opportunityId: '$oppId'})
    wiredAccounts({error,data}){      
        if(error){
            this.errorHeader = true;
            if (Array.isArray(error.body)) {
                this.errorHeaderMessages.push(error.body.map(e => e.message));
            } else if (typeof error.body.message === 'string') {
                this.errorHeaderMessages.push(error.body.message);
            }
            this.toggleWorking();
        }else if(data) {            
            this.toggleWorking();
            if(data.length > 0){
                this.tabDataChild.dataTable = data.filter((row) => row.Child == 'true'); 
                this.tabDataRelated.dataTable = data.filter((row) => row.PreviouslyCloned == 'false');       
                this.tabDataRelated.dataTableCloned = data.filter((row) => row.PreviouslyCloned == 'true');       
            } 
            if (this.tabDataChild.dataTable.length == 0) {
                this.tabDataChild.showTable = false;
                this.tabDataChild.showError = true;
                this.tabDataChild.errorMessages.push(noChildLabel + this.accountStoreLabel);
            } else {
                this.tabDataChild.showTable = true;
            }
            if (this.tabDataChild.dataTableCloned.length > 0) {
                this.tabDataChild.showTableCloned = true;
            }            
            if (this.tabDataRelated.dataTable.length == 0) {
                this.tabDataRelated.showTable = false;
                this.tabDataRelated.showError = true;
                this.tabDataRelated.errorMessages.push(noRelatedLabel  + this.accountStoreLabel);
            } else {
                this.tabDataRelated.showTable = true;
            }
            if (this.tabDataRelated.dataTableCloned.length > 0) {
                this.tabDataRelated.showTableCloned = true;
            }            
        }
        this.checkFullDisable();  
    }

    connectedCallback() {
        this.cloneDisabled = true;
        this.activeTab = 0;
        this.accountStoreLabel = ` ${accountName} (Store Id: ${currentStore}).`
        this.checkBoxBulkActivation = this.bulkActivation;
        this.stageValue = 'Contract Signed';
    }

    renderedCallback() {
        let bulkActivationCheckbox = this.template.querySelector('[data-id="BulkActivation"]');
        if (bulkActivationCheckbox != null && this.checkBoxBulkActivation == 'true') {
            bulkActivationCheckbox.checked = this.checkBoxBulkActivation;
        }
    }

    getSelectedRows(){
        if (this.activeTab == 0) {
            return this.template.querySelector('[data-id="Table0"]').getSelectedRows();
        } else if (this.activeTab == 1) {
            return this.template.querySelector('[data-id="Table1"]').getSelectedRows();
        } else if (this.activeTab == 2) {
            return this.template.querySelector('[data-id="Table2"]').getSelectedRows();
        } else if (this.activeTab == 3) {
            return this.template.querySelector('[data-id="Table3"]').getSelectedRows();
        } 
        return null;
    }

    selectedRowHandler(event){
        let currentTabData = new TabData();
        if (this.activeTab == 0) {
            currentTabData = this.tabDataChild;
        } else if (this.activeTab == 1) {
            currentTabData = this.tabDataRelated;
        } else if (this.activeTab == 2) {
            currentTabData = this.tabDataSearch;
        } else if (this.activeTab == 3) {
            currentTabData = this.tabDataImport;
        }

        let details = event.detail;

        if(details.selectedRows.length > 0){
            currentTabData.cloneDisabled = false;
            let storeData = this.getSelectedRows();
            if(storeData) {
                let storeIds = storeData.map(function (store){
                    return store.Id;
                });
                currentTabData.selectedStores = storeIds.length;                
            }
        } else {
            currentTabData.cloneDisabled = true;
            currentTabData.selectedStores = 0;
        }
        this.cloneDisabled = currentTabData.cloneDisabled;
        this.selectedStores = currentTabData.selectedStores;
        this.checkFullDisable();
    }

    handleActive(event) {
        this.activeTab = event.target.value;
        
        let currentTabData = new TabData();
        if (this.activeTab == 0) {
            currentTabData = this.tabDataChild;
        } else if (this.activeTab == 1) {
            currentTabData = this.tabDataRelated;
        } else if (this.activeTab == 2) {
            currentTabData = this.tabDataSearch;
        } else if (this.activeTab == 3) {
            currentTabData = this.tabDataImport;
        }
        this.cloneDisabled = currentTabData.cloneDisabled;
        this.selectedStores = currentTabData.selectedStores;
        this.checkFullDisable(); 
    }

    handleBulkActivationChange(event) {
        this.checkBoxBulkActivation = event.target.checked;
    }

    returnToOpp(){
        window.location.replace('/'+ this.oppId);
    }
    
    toggleWorking(){
        this.working = !this.working;
    } 

    checkFullDisable(){
        if (this.errorHeader || this.showSuccess) {
            this.cloneDisabled = true;
            this.showTabs = false;
        }        
    }

    cloneOppAndQuote(){
        this.toggleWorking();
        this.cloneDisabled = true;
        let storeData = this.getSelectedRows();
        if(storeData){
            let storeIds = storeData.map(function (store){
                return store.Id;
            });
            cloneData({ oppId: this.oppId, storeIds: storeIds, bulkActivation: this.checkBoxBulkActivation, stageName: this.stageValue })
                .then(result => {
                    this.toggleWorking();
                    if(result.status == 'Error'){
                        this.errorHeader = true;
                        this.errorHeaderMessages = result.messages; 
                    } else{                
                        this.returnVariant = 'brand';
                        this.showSuccess = true;
                    }
                })
                .catch(error => {
                    this.toggleWorking();
                    this.errorHeader = true;
                    this.errorHeaderMessages.push(errorCloningLabel + this.accountStoreLabel); 
                })               
        }
        this.checkFullDisable();  
    }

    handleSubmit(event){
        event.preventDefault();       
    }

    handleChange(event) {
        if (event.detail.value[0]) {

            if (!this.selectedAccountsFromLookUp.includes(event.detail.value[0])) {
                this.selectedAccountsFromLookUp.push(event.detail.value[0]);
            }           
            getSelectedAccounts({ accountIds: this.selectedAccountsFromLookUp, quoteId: this.quoteId })
            .then(data => {
                if(data) {              
                    if(data.length > 0){
                        this.searchDataTable = data.filter((row) => row.PreviouslyCloned == 'false');       
                        this.searchDataTableCloned = data.filter((row) => row.PreviouslyCloned == 'true');       
                    }
                    if (this.searchDataTable.length == 0) {
                        this.searchShowTable = false;
                    } else {
                        this.searchShowTable = true;
                    }
                    if (this.searchDataTableCloned.length == 0) {
                        this.searchShowTableCloned = false;
                    } else {
                        this.searchShowTableCloned = true;
                    }
                    this.searchShowError = false;
                    this.searchErrorMessages = [];                               
                }
                else {
                    this.searchShowTable = false;
                    this.searchShowError = true;
                    this.searchErrorMessages.push(accountNotFoundLabel);    
                }
            })
            .catch(error => {
                this.searchShowTable = false;
                this.searchShowError = true;
                if (Array.isArray(error.body)) {
                    this.searchErrorMessages.push(error.body.map(e => e.message));
                } else if (typeof error.body.message === 'string') {
                    this.searchErrorMessages.push(error.body.message);
                }
            })
        }       
    }

    //handle event from child component when a csv has been loaded
    handleFileAdded(event){
        let accountJson = [...event.detail];
        const accountIdObjects = accountJson.filter(row => row.Id != null);
        const storeIdsObjects = accountJson.filter(row => row.StoreId != null);
        
        if ((accountIdObjects && accountIdObjects.length > 0) &&
            (storeIdsObjects && storeIdsObjects.length > 0)) 
        {
            this.importShowTable = false;
            this.importShowTableCloned = false;
            this.importDataTable = [];
            this.importDataTableCloned = [];
            this.importShowError = true;
            this.importErrorMessages.push(csvImportErrorLabel);    
        }
        else if (accountIdObjects && accountIdObjects.length > 0) 
        {
            const accountIds = accountIdObjects.map(row => row.Id);
            getSelectedAccounts({ accountIds: accountIds, quoteId: this.quoteId  })
            .then(data => {
                this.handleImportData(data);
            })
            .catch(error => {
                this.handleImportError(error);
            });
        }
        else if (storeIdsObjects && storeIdsObjects.length > 0) 
        {
            const storeIds = storeIdsObjects.map(row => row.StoreId);
            getSelectedStoreIds({ storeIds: storeIds, quoteId: this.quoteId  })
            .then(data => {
                this.handleImportData(data);
            })
            .catch(error => {
                this.handleImportError(error);
            });
        }
    }

    /**
     * @description Introduced in BZAP-14523 to hide the CSV table when
     *  an imported CSV file is removed with the 'x' button on the UI.
     */
    handleFileRemoved(event) {
        this.importShowTable = false;
        this.importShowTableCloned = false;
        this.importDataTable = [];
        this.importDataTableCloned = [];
    }

    handleImportData(data) {
        if(data.length > 0){
            this.importDataTable = data.filter((row) => row.PreviouslyCloned == 'false');       
            this.importDataTableCloned = data.filter((row) => row.PreviouslyCloned == 'true');       

            if (this.importDataTable.length == 0) {
                this.importShowTable = false;
            } else {
                this.importShowTable = true;
            }
            if (this.importDataTableCloned.length == 0) {
                this.importShowTableCloned = false;
            } else {
                this.importShowTableCloned = true;
            }
            this.importShowError = false;
            this.importErrorMessages = [];    
        } else {
            this.importShowTable = false;
            this.importShowError = true;
            this.importErrorMessages.push(accountNotFoundLabel);    
        }       
    }

    handleImportError(error) {
        this.importShowTable = false;
        this.importShowTableCloned = false;
        this.importShowError = true;
        if (Array.isArray(error.body)) {
            this.importErrorMessages.push(error.body.map(e => e.message));
        } else if (typeof error.body.message === 'string') {
            this.importErrorMessages.push(error.body.message);
        }
    }

    handleFileReadError(event){   }

    handleStageChange(event) {
        this.stageValue = event.detail.value;
    }
}