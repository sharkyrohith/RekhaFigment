/**
 * @author  : Sugan
 * @date : October 27th 2022
*  @description : A component to show sets of fields under a section header, this is created as a reaplcement to using update quick actions 
on lightning record page to achieve the same objective, The section name is the only input (configured as design attribute) and the fields correspondign to a 
section are maintained and fetched from a JS file - lwcDdCaseUIUtil.js 
*/
/*****************************************************************************************************************************
*
* Imports
*
*****************************************************************************************************************************/
import { LightningElement, wire, api } from 'lwc';
import RECORDTYPEID from '@salesforce/schema/Case.RecordTypeId';
//import the section to field details we created in lwcDdCaseUIUtil.js
import { getFieldsForSection } from './lwcDdDynamicUIUtil';
import { getRecord } from 'lightning/uiRecordApi';

/*****************************************************************************************************************************
*
* CSS Class Consts
*
*****************************************************************************************************************************/



/*****************************************************************************************************************************
*
* Functional Consts
*
*****************************************************************************************************************************/
//fields to fetch using getRecord
const _FIELDS = [RECORDTYPEID];

/*****************************************************************************************************************************
*
* api Picklist Value consts
*
*****************************************************************************************************************************/


export default class LwcDdDynamicRecordPageSection extends LightningElement {
    /*****************************************************************************************************************************
    *
    * Public Variables
    * record id and objectApiName are already set as this compoent is only being used on a record page
    *****************************************************************************************************************************/
   @api sectionName;
   @api recordId;
   @api objectApiName;

   /*****************************************************************************************************************************
    *
    * Other reactive Variables
    *
    *****************************************************************************************************************************/

   isEdit=false;
   isLoading = false;
   section;
   recordTypeIdVal;

   /*****************************************************************************************************************************
    *
    * LifeCycle Hooks (renderedCallback,connectedCallback,disconnectedCallback)
    *
    *****************************************************************************************************************************/
   connectedCallback(){
      this.section = getFieldsForSection(this.objectApiName,this.sectionName);
   }

   /*****************************************************************************************************************************
    *
    * UI Getters - Custom getters for variables in the HTML
    *
    *****************************************************************************************************************************/

    /*****************************************************************************************************************************
    *
    * Wire
    *
    *****************************************************************************************************************************/
   //we need to set record type id to ensure the record type appropriate picklists values show up on edit
   @wire(getRecord, { recordId: '$recordId', fields: _FIELDS })
   setRecordTypeId({ error, data }){
      if(data){
         this.recordTypeIdVal = data.fields.RecordTypeId.value;
      }else if(error){
         let message = 'Unknown error';
         if (Array.isArray(error.body)) {
               message = error.body.map(e => e.message).join(', ');
         } else if (typeof error.body.message === 'string') {
               message = error.body.message;
         }
         console.log('Error occurred while getting record type id: '+message);
      }
   }

   /*****************************************************************************************************************************
    *
    * Event Handlers
    *
    *****************************************************************************************************************************/

   handleEdit(event) {
      this.isEdit = true;
   }
   handleReset(event) {
      const inputFields = this.template.querySelectorAll('lightning-input-field');
      if (inputFields) {
         inputFields.forEach(field => {
               field.reset();
         });
      }
      this.returnToView();
   }
   handleSubmit(event) {
      this.isLoading = true;
   }
   handleSuccess(event) {
      this.returnToView();
   }
   handleError(event) {
      this.isLoading = false;
   }

   /*****************************************************************************************************************************
    *
    * Logic / Helper methods
    *
    *****************************************************************************************************************************/
   //helper to toggle from edit to view
   returnToView() {
      this.isEdit = false;
      this.isLoading = false;
   }  
}