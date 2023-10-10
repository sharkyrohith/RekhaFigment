/*****************************************************************************************************************************
*
* Imports
*
*****************************************************************************************************************************/
import { LightningElement } from 'lwc';
import getOmniEnabledQueues from "@salesforce/apex/CDdCrossSkillingFinderController.getOmniEnabledQueues";
import findCrossSkilling from "@salesforce/apex/CDdCrossSkillingFinderController.findCrossSkilling";

/*****************************************************************************************************************************
*
* Functional Consts
*
*****************************************************************************************************************************/
const userColumns = [
    {   label: 'Id',
        fieldName: 'id'
    },
    {   label: 'Email',
        fieldName: 'email'
    }
];

export default class LwcDdCrossSkillingFinder extends LightningElement {
    /*****************************************************************************************************************************
    *
    * Private Variables
    *
    *****************************************************************************************************************************/
    showError = false;
    errorMsg = '';
    isLoading = false;

    userColumns = userColumns;

    queueNameOptions = [];
    vendorNameOptions = [];
    //New email domain for this vendor
    mapNewDomainUserCount = [];
    //This will have agents from different vendor in this queue
    mapDifferentDomainUsers = [];
    //This will have agents from this queue in different Vendor Queues
    mapUsersInDifferentQueues = [];
    usersList = [];
    showStatusSection = false;
    showNewDomainSection = false;
    showDiffDomainSection = false;
    showAgentsInDiffVendorSection = false;
    vendorValue;
    queueValue;
    statusMsg = '';
    showStatusMsg = false;

    /*****************************************************************************************************************************
    *
    * LifeCycle Hooks (renderedCallback,connectedCallback)
    *
    *****************************************************************************************************************************/

    connectedCallback() {
        getOmniEnabledQueues({})
        .then(result => {
            this.queueNameOptions = result.queueOptions;
            this.vendorNameOptions = result.vendorOptions;
        })
        .catch(error => {
            this.handleError(error.body.message);
        });
    }


    /*****************************************************************************************************************************
    *
    * Event Handlers
    *
    *****************************************************************************************************************************/
    //On change Queue dropdown
    handleQueueChange(event){
        this.queueValue = event.target.value;
        this.resetValues();
    }

    //On change of Vendor dropdown
    handleVendorChange(event){
        this.vendorValue = event.target.value;
        this.resetValues();
    }

    /*****************************************************************************************************************************
    *
    * Logic / Helper methods
    *
    *****************************************************************************************************************************/
    //Validate the Queue Hygiene
    validateQueueSkilling(){
        this.resetError();
        if(!this.queueValue){
            this.handleError('Queue name is required');
        }
        if(!this.queueValue){
            this.handleError('Vendor name is required');
        }
        if(!this.errorMsg){
            this.resetError();
            this.resetValues();
            this.isLoading = true;
            findCrossSkilling({ queueDevName: this.queueValue, vendorName: this.vendorValue})
                .then(result => {
                    this.isLoading = false;
                    this.usersList = result.lstUserWrapper;

                    var newDomainData = result.mapNewDomainWithUserCount;
                    for(let key in newDomainData) {
                        this.mapNewDomainUserCount.push({value:newDomainData[key], key:key});
                    }

                    var differentDomainData = result.mapDiffDomainWithUsers;
                    for(let key in differentDomainData) {
                        this.mapDifferentDomainUsers.push({value:differentDomainData[key], key:key});
                    }

                    var agentsInDifferentVendors = result.mapAgentsAddedToDifferentQueues;
                    for(let key in agentsInDifferentVendors) {
                        this.mapUsersInDifferentQueues.push({value:agentsInDifferentVendors[key], key:key});
                    }
                    this.showNewDomainSection = this.mapNewDomainUserCount.length > 0 ;
                    this.showDiffDomainSection = this.mapDifferentDomainUsers.length > 0 ;
                    this.showAgentsInDiffVendorSection = this.mapUsersInDifferentQueues.length > 0 ;
                    this.showStatusSection = this.showNewDomainSection || this.showDiffDomainSection || this.showAgentsInDiffVendorSection ;
                    if(this.showStatusSection == false){
                        this.statusMsg = 'Queue setup looks good.';
                        this.showStatusMsg = true;
                    }
                })
                .catch(error => {
                    this.handleError(JSON.stringify(error));
                });
        }
        this.isLoading = false;
    }

    //Export functionality
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
        downloadElement.download = 'CrossSkilledUsersFor_'+this.vendorValue + this.queueValue + '.csv';
        // below statement is required if you are using firefox browser
        document.body.appendChild(downloadElement);
        // click() Javascript function to download CSV file
        downloadElement.click();
    }

    handleError(errMsg){
        this.isLoading = false;
        this.showError = true;
        this.errorMsg = errMsg;
    }

    resetError(){
        this.showError = false;
        this.errorMsg = '';
    }

    resetValues(){
        this.mapNewDomainUserCount = [];
        this.mapDifferentDomainUsers = [];
        this.mapUsersInDifferentQueues = [];
        this.statusMsg = '';
        this.showStatusSection = false;
        this.showStatusMsg = false;
    }
}