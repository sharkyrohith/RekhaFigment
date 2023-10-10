/**
 * @author : Sugan
 * @date : Nov 30th 2022
 * @decription : Controller for converting uploaded CSV and display it as a lightning data table
 */

 /****************************************************************************************************************************
 *
 * Imports
 *
 *****************************************************************************************************************************/
import { LightningElement } from 'lwc';
import runMacroUpdate from  '@salesforce/apex/CDdBulkUpdateMacroController.runMacroUpdateBatchJob';

export default class LwcDdBulkUpdateMacros extends LightningElement {
    /*****************************************************************************************************************************
     *
     * Non public Variables
     *
     *****************************************************************************************************************************/
    isLoading = false;
    ticketNum;
    batchJobId;
    errorMessage;
    /*****************************************************************************************************************************
     *
     * Event Handlers
     *
     *****************************************************************************************************************************/
    handleRun(event){
        let ticket = this.template.querySelector('lightning-input[data-name="ticketNum"]').value;
        let childPl = this.template.querySelector('lightning-input[data-name="childPl"]').value;
        let parentPl = this.template.querySelector('lightning-input[data-name="parentPl"]').value;
        let data = JSON.stringify(this.template.querySelector('c-lwc-dd-csv-to-data-table-component').tableData);
        if(!ticket || !parentPl || !data){
            this.errorMessage = "Please fill out the JIRA ticket number and Parent picklist name and upload a valid CSV document";
            this.batchJobId = null;
            return;
        }
        this.isLoading = true;
        //this.execBatchJob(ticketNum, parentPl, childPl, parentMap, childMap);
        runMacroUpdate({ ticketNum : ticket, parentPicklist:parentPl, childPicklist: childPl, csvData:data })
            .then((result) => {
                if(result.includes("Error")){
                    this.errorMessage = result;
                    this.batchJobId = null;
                    this.isLoading = false;
                }else{
                    this.batchJobId = result;
                    this.errorMessage = null;
                    this.isLoading = false;
                }
            })
            .catch((error) => {
                this.errorMessage = error;
                this.isLoading = false;
            });
    }
    /*********************************************************************************
     * Event Handler to generate and download a CSV template file for picklist mapping
     *********************************************************************************/
    downloadCSVTemplate(){
        let csvString = "OldParentValue,NewParentValue,OldChildValue,NewChildValue"+"\n";
        // Creating anchor element to download
        let downloadElement = document.createElement('a');

        // This  encodeURI encodes special characters, except: , / ? : @ & = + $ # (Use encodeURIComponent() to encode these characters).
        downloadElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(csvString);
        downloadElement.target = '_self';
        // CSV File Name
        downloadElement.download = 'Macro Update template.csv';
        // below statement is required if you are using firefox browser
        document.body.appendChild(downloadElement);
        // click() Javascript function to download CSV file
        downloadElement.click();
    }
}