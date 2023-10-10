import { LightningElement,api } from 'lwc';
import  getFields from '@salesforce/apex/CDdShowLightningRecordForm.getFields';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { BLANK_STRING } from 'c/lwcDdConst';

/*****************************************************************************************************************************
 *
 * Functional Consts
 *
 *****************************************************************************************************************************/
const ICONNAME = 'standard:case';
const READONLY_MODE = 'readonly';
const EDIT_MODE = 'edit';

export default class ddShowLightningRecordForm extends LightningElement {

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
    // {String} -  Icon name for Lighting Cart
    @api iconName = ICONNAME;

/*****************************************************************************************************************************
 *
 * Private Variables
 *
*****************************************************************************************************************************/

objName = BLANK_STRING;
isShow = false;
fields =[];
isMode = READONLY_MODE;
isLoading = false;

/*****************************************************************************************************************************
 *
 * Lifecycle hooks
 *
*****************************************************************************************************************************/
    connectedCallback() {
        this.getFieldFromServer();
    }

/*****************************************************************************************************************************
 *
 * Event Handlers
 *
*****************************************************************************************************************************/
    /**
    * @decription Edit Button Clicked
    */
    editFields(){
        this.isMode = EDIT_MODE;
    }

    /**
    * @decription Record Form Edit save is succesful
    */
    handleSuccess(){
        this.isMode = READONLY_MODE;
    }

    /**
    * @decription Record Form Edit save failed
    */
    handleError(event) {
        this.showToaster('Error', event.detail.detail, 'error');
    }
/*****************************************************************************************************************************
 *
 * Helper Methods
 *
*****************************************************************************************************************************/
    /**
    * @decription Calls the server to get the field set for the record
    * @param   None
    * @return  None
    */
    getFieldFromServer(){
        this.isLoading = true;
        getFields({recordId : this.recordId ,fSet: this.fieldSet,sectionName : this.sectionName})
        .then(result => {
            if(result){
                this.objName = result.strObject;
                this.fields = result.lstFields;
                this.isShow = true;
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
}