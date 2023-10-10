/*****************************************************************************************************************************
*
* Imports
*
*****************************************************************************************************************************/
import { LightningElement } from 'lwc';
import getCaseObjectQueues from "@salesforce/apex/CDdCrossSkillingFinderController.getCaseObjectQueues";

export default class LwcDdCrossSkillingFinder extends LightningElement {
    /*****************************************************************************************************************************
    *
    * Private Variables
    *
    *****************************************************************************************************************************/
    showError = false;
    errorMsg = '';
    isLoading = false;

    queueNameOptions = [];
    vendorNameOptions = [];
    mapVendorQueue = new Map();
    mapSelectedVendorQueueUI = [];

    jsonFromMap = '';
    showJson = false;
    showTableSection = false;

    /*****************************************************************************************************************************
    *
    * LifeCycle Hooks (renderedCallback,connectedCallback)
    *
    *****************************************************************************************************************************/

    connectedCallback() {
        getCaseObjectQueues({})
        .then(result => {
            this.queueNameOptions = result.queueOptions;
            this.vendorNameOptions = result.vendorOptions;
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
    //On change Queue dropdown
    handleQueueChange(event){
        this.queueValue = event.target.value;
    }

    //On change of Vendor dropdown
    handleVendorChange(event){
        this.vendorValue = event.target.value;
    }

    handleRemove(event){
        const itemIndex = event.currentTarget.dataset.index;
        const rowData = this.mapSelectedVendorQueueUI[itemIndex];
        this.mapVendorQueue.delete(rowData.key);
        this.getFinalJson();
    }

    handleAdd(){
        this.showError = false;
        this.errorMsg = '';
        if(this.vendorValue && this.queueValue){
            this.mapVendorQueue.set(this.vendorValue,this.queueValue);
            this.getFinalJson();
        }else{
            this.showError = true;
            this.errorMsg = 'Please select both the values';
        }
    }

    getFinalJson(){
        this.mapSelectedVendorQueueUI = [];
        for(let key in Object.fromEntries(this.mapVendorQueue)){
            this.mapSelectedVendorQueueUI.push({value:Object.fromEntries(this.mapVendorQueue)[key], key:key});
        }
        this.jsonFromMap = JSON.stringify(Object.fromEntries(this.mapVendorQueue));
        this.showTableSection = this.mapVendorQueue.size > 0;
    }
}