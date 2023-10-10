/**
 * @author Mahesh Chouhan
 * @date  Oct 2021
 * @decription Component to display Quick View of SObject Records
 */

/*****************************************************************************************************************************
 *
 * Imports
 *
 *****************************************************************************************************************************/
import { LightningElement, api, wire } from 'lwc';
import { BLANK_STRING } from 'c/lwcDdConst';
import { reduceErrors } from 'c/lwcDdUtils';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import getSObjectDetails from '@salesforce/apex/CDdGridReportQuickViewPanelCtrl.getSObjectDetails';

/*****************************************************************************************************************************
 *
 * Functional Const
 *
 *****************************************************************************************************************************/
const OBJ_ACCOUNT = 'Account';
export default class LwcDdGridReportQuickViewPanel extends LightningElement {

   /*****************************************************************************************************************************
    *
    * Public Variables
    *
    *****************************************************************************************************************************/

    // {String} (Required) FieldSet Name to query fields to display in QuickView Panel.
    @api
    fieldSetName;
    // {String} (Required) Record Name or Number to display as header in QuickView Panel.
    @api
    header;
    // {String} (Required) Record Id to display
    @api get recordId() {
        return this.id;
    };
    set recordId(value) {
        this.id = value;
        this.showSpinner = true;
    }

   /*****************************************************************************************************************************
    *
    * Private Variables
    *
    *****************************************************************************************************************************/
    id;
    fields = [];
    showSpinner = false;
    objectName = BLANK_STRING;
    iconName = BLANK_STRING;
    error;
    iconURL;
    iconColor;

    /*****************************************************************************************************************************
    *
    * UI Getters
    *
    *****************************************************************************************************************************/

    get isAccount() {
        return this.objectName === OBJ_ACCOUNT;
    }

    /*****************************************************************************************************************************
    *
    * Wires
    *
    *****************************************************************************************************************************/
    //Get sobject details containing objectLabel, objectName and fields
    @wire(getSObjectDetails, {recordId: '$id', fieldSetName: '$fieldSetName'})
    wiredGetSObjectFieldNames({data , error}) {
        if(data){
            this.objectName = data.objectName;
            this.fields = data.fields;
            this.objectLabel = data.objectLabel;
            this.error = undefined;
        }else if(error) {
            console.log(JSON.stringify(error));
            this.iconURL = undefined;
            this.objectName = undefined;
            this.error = error;
        }
        this.showSpinner = false;
    }

    //Get sobject iconURL and iconColor
    @wire(getObjectInfo, { objectApiName: '$objectName' })
    wiredGetObjectInfo({ error, data }) {
        if (data) {
            this.iconURL = data.themeInfo ? data.themeInfo.iconUrl : null;
            this.iconColor = data.themeInfo ? 'background-color:#' + data.themeInfo.color : '';
        } else if (error) {
            console.log('wiredGetObjectInfo wire error - ', reduceErrors(error));
        }
    }
    /*****************************************************************************************************************************
     *
     * Event Handlers
     *
     *****************************************************************************************************************************/
    // When close button is clicked, hide the QuickView Panel.
    closePanel(event) {
        event.preventDefault();
        event.stopPropagation();
        const evt = new CustomEvent("closequickview");
        this.dispatchEvent(evt);
    }

    // When Open In Console button is clicked, fire event to open record in Console.
    openInConsoleTab(event) {
        event.preventDefault();
        event.stopPropagation();
        const message = {
            recordId: this.id,
            openMode: 'tab'
        };
        const evt = new CustomEvent("navigatetorecord",{
            detail: message,bubbles:true,composed:true
        });
        this.dispatchEvent(evt);
    }
}