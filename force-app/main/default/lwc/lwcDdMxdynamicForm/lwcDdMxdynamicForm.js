/**
 * @author Praveen Pandem
 * @date  07/15/2022
 * @decription Equipment request child component to create the contact.
 */

/*****************************************************************************************************************************
 *
 * Imports
 *
 ***********/

import { LightningElement, api, wire } from 'lwc';
import getFieldSetMetadata from '@salesforce/apex/CDdMxFieldSetController.getFields';
import validateContactowner from '@salesforce/apex/CDdMxFieldSetController.validateContactOwner';

export default class LwcDdMxdynamicForm extends LightningElement {
   /*****************************************************************************************************************************
    *
    * Private and public Variables
    *
    *****************************************************************************************************************************/

   @api objectName;
   @api fieldSetName;
   @api recordId;
   fields = [];
   @api mode;
   @api isnew;
   @api accountId;
   @api title;
   contactValidation;

   /*****************************************************************************************************************************
    *
    * Wires
    *
    *****************************************************************************************************************************/

   /**
    * Get the SObjectType and the Fields
    * wire method to load the field set from apex controller. field diapled as form in the UI.
    * @param recordId
    * @param fieldSetName
    */

   @wire(getFieldSetMetadata, {
      objectName: '$objectName',
      fieldSetName: '$fieldSetName',
   })
   wiredFieldSetMetadata({ error, data }) {
      this.isLoading = true;
      if (data) {
         console.log('at wire ' + JSON.stringify(data));
         this.fields = data.fieldsMetadata;
         //this.fields = this.fieldss;
      } else if (error) {
         console.log('Error while fetching contact info ' + JSON.stringify(error));
      }
   }
   /*****************************************************************************************************************************
    *
    * Event Handlers
    *
    *****************************************************************************************************************************/

   async handleSubmit(event) {
      event.preventDefault(); // stop the form from submitting
      const fields = event.detail.fields;
      await this.validateContactowner();
      if(this.contactValidation.noActiveOwnerFound === true){
         this.notifyUser('error', 'No active user found on ADR owner on account or active owner for parent account. Please change the account ADR owner to active user before creating or updating contact.');
         return;
      }
      fields.AccountId = this.contactValidation.accountId;
      if (!fields.FirstName || !fields.LastName || !fields.Phone || !fields.Email) {
       this.notifyUser('error', 'Please input all fields');
         return;
      }
      this.template.querySelector('lightning-record-form').submit(fields);
   }
   empty(e) {
      switch (e) {
         case null:
         case '':
            return true;
         default:
            return false;
      }
   }

   handleSuccess(event) {
      const searchEvent = new CustomEvent('contactcreation', {
         detail: {
            searchTerm: '',
            rawSearchTerm: '',
            searchTermObject: this.objectName,
            //selectedIds: this._curSelection.map((element) => element.id)
         },
      });
      this.dispatchEvent(searchEvent);
   }
   notifyUser(title, message) {
      this.template.querySelector('c-lwc-dd-mx-custom-toast-messge').showToast(title, message);
   }
   async validateContactowner() {
		this.contactValidation = await validateContactowner({ accountId: this.accountId, contactId: this.recordId});
	}
}