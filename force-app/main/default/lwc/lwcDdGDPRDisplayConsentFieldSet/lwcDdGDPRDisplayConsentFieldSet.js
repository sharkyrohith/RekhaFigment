/**
 * @author Ravali Tummala
 * @date  Oct 2021
 * @decription GDPR Constants
 */

/*****************************************************************************************************************************
 *
 * Imports
 *
 *****************************************************************************************************************************/

import { LightningElement,api,wire } from 'lwc';
import  getDatafrom from '@salesforce/apex/CDdGDPRGetConsentFieldSet.getData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { BLANK_STRING } from 'c/lwcDdConst';
import { cloneObject,copyToClipboard } from 'c/lwcDdUtils';
import { subscribe,unsubscribe, MessageContext} from 'lightning/messageService';
import gdprComponentReloadChannel from '@salesforce/messageChannel/mcDdGDPRDisplayConsentFieldSetRefresh__c';

const CLASS_ITEM = "slds-col slds-grid slds-has-flexi-truncate ";
const CLASS_PADDING_LEFT = " slds-var-p-left_small ";
const CLASS_PADDING_RIGHT = " slds-var-p-right_small ";
const CLASS_RECORD_FORM_CONTAINER = "slds-var-p-left_medium slds-var-p-right_medium";
export default class LwcCddDisplayConsentFieldSet extends LightningElement {

/*****************************************************************************************************************************
 *
 * Public Variables
 *
*****************************************************************************************************************************/
    // {Object[]} - input fieldset for that object
    @api fieldSet;
    // {String} - Record Id for that object
    @api recordId;
    // {String} - Label of the section
    @api sectionName;
    // {Integer} - # of columns
    @api columns = 2;

/*****************************************************************************************************************************
 *
 * Private Variables
 *
*****************************************************************************************************************************/
    layoutSize = 6;
    iconName = 'standard:';

    objName = BLANK_STRING;
    isShow = false;
    fields =[];
    lstConsentData= [];
    isEdit = false;
    isLoading = false;

/*****************************************************************************************************************************
 *
 * Lifecycle hooks
 *
*****************************************************************************************************************************/
    connectedCallback() {
        this.layoutSize = 12 / this.columns;
        this.getDataFromServer();
        this.subscribeToMessageChannel();
    }
    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }
/*****************************************************************************************************************************
     *
     * Wires
     *
*****************************************************************************************************************************/
    // Initialize messageContext for Message Service
    @wire(MessageContext)
    messageContext;
/*****************************************************************************************************************************
 *
 * UI Getters
 *
*****************************************************************************************************************************/
    get recordFormContainerClass() {
        return this.columns === 1 ? CLASS_RECORD_FORM_CONTAINER : BLANK_STRING;
    }

/*****************************************************************************************************************************
 *
 * Event Handlers
 *
*****************************************************************************************************************************/
    /**
    * @decription Toggle Field display (show/hide icon) clicked
    */
     showHideConsent(event) {
        let lstConsentData = cloneObject(this.lstConsentData);
        const rowIndex = event.target.dataset.rowindex;
        const columnIndex = event.target.dataset.columnindex;
        lstConsentData[rowIndex][columnIndex].isHidden = !lstConsentData[rowIndex][columnIndex].isHidden;
        this.lstConsentData = lstConsentData;
    }

    /**
    * @decription Copy to clipboard icon clicked
    */
    copy(event) {
        const rowIndex = event.target.dataset.rowindex;
        const columnIndex = event.target.dataset.columnindex;
        copyToClipboard(this.lstConsentData[rowIndex][columnIndex].actualValue);
        this.showToaster(`${this.lstConsentData[rowIndex][columnIndex].fieldLabel} copied to clipboard`,'','success');
    }

    /**
    * @decription Edit Button Clicked
    */
    editFields(){
        this.isEdit = true;
    }

    /**
    * @decription Record Form Edit save is succesful
    */
    handleSuccess(){
        this.getDataFromServer();
    }

    /**
    * @decription Record Form Edit save failed
    */
    handleError(event) {
        this.isEdit = false;
    }
/*****************************************************************************************************************************
 *
 * Helper Methods
 *
*****************************************************************************************************************************/
    /**
    * @decription Calls the server to get the data for the record
    * @param   None
    * @return  None
    */
    getDataFromServer(){
        this.isLoading = true;
        getDatafrom({recordId : this.recordId ,fSet: this.fieldSet,sectionName : this.sectionName})
        .then(result => {
            if(result){
                this.objName = result.strObject;
                this.iconName += this.objName.toLowerCase();
                this.fields = result.lstFields;
                let consentData = [];
                let count = 0;
                let row = [];
                result.lstMaskData.forEach(elem => {
                    elem.isSpecialType = false;
                    elem.isEmail = false;
                    elem.isPhone = false;
                    elem.isReference = false;
                    if (elem.fieldType.toLowerCase() == 'email'){
                        elem.isEmail = true;
                        elem.isSpecialType = true;
                    } else if (elem.fieldType.toLowerCase() == 'phone'){
                        elem.isPhone = true;
                        elem.isSpecialType = true;
                    } else if (elem.fieldType.toLowerCase() == 'reference'){
                        elem.isReference = true;
                        elem.isSpecialType = true;
                        elem.url = elem.referenceId ? '/' + elem.referenceId : BLANK_STRING;
                    }
                    elem.copyToClipboardText = `Copy ${elem.fieldLabel} to Clipboard`;
                    elem.revealText = `Reveal ${elem.fieldLabel}`;
                    elem.hideText = `Hide ${elem.fieldLabel}`;
                    elem.elemClass = CLASS_ITEM;
                    if (count > 0 || this.columns === 1) {
                        elem.elemClass += CLASS_PADDING_LEFT;
                    }
                    if (count < (this.columns - 1) || this.columns === 1) {
                        elem.elemClass += CLASS_PADDING_RIGHT;
                    }
                    row.push(elem);
                    count++;
                    if (count === this.columns) {
                        consentData.push(row);
                        row = [];
                        count = 0;
                    }
                });
                if (row.length !== 0) {
                    consentData.push(row);
                }
                this.lstConsentData = consentData;
                this.isShow = true;
                this.isEdit = false;
            } else {
                this.showToaster('Error', 'No Consent field on this object', 'error');
            }
            this.isLoading = false;
        })
        .catch(error => {
            this.error = error;
            this.isLoading = false;
        });
    }

    /**
    * @decription Show Toast
    * @param   titleValue {String}
    * @param   messageValue {String}
    * @param   variantValue {String} - 'success','error' etc.
    * @return  None
    */
    showToaster(titleValue, messageValue, variantValue) {
        this.dispatchEvent(new ShowToastEvent({ title: titleValue, message: messageValue, variant: variantValue }));
    }

    /**
    * @encapsulate logic for LWC subscribe
    */
     subscribeToMessageChannel() {
        this.subscription = subscribe(
             this.messageContext,
             gdprComponentReloadChannel,
             (message) =>this.handleSuccess(message)
         );
    }
    /**
    * @encapsulate logic for LWC unsubscribe
    */
     unsubscribeToMessageChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }
    
    /**
     *  @Handler for message received by component
     */
     handleMessage(message){
        try{
            if(message.recordId == this.recordId){
                this.handleSuccess();
            }
        }catch(e){
            this.error = error;
            this.isLoading = false;
        }
    }
}