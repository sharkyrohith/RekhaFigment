/**
 * @author Praveen Pandem
 * @date  07/15/2022
 *@Description:Address from to accept the shipping information from equipment UI screen.
 *Features:Accept the prepopulated fields from parent component and emits the address information as event to the parent.
 * Each event entire address information will be sent to the parent.
 */
/*****************************************************************************************************************************
 *
 * Imports
 *
 ***********/

import { LightningElement, api } from 'lwc';

export default class LwcDdMxAddressForm extends LightningElement {
   /*****************************************************************************************************************************
    *
    * Public Variables
    *
    *****************************************************************************************************************************/

   @api accountDetails;
   @api updatedAccountDetails = {};

   /*****************************************************************************************************************************
    *
    * Event Handlers
    *
    *****************************************************************************************************************************/

   // close the prepopulated address information so entire address will emite to the parent for each event change.
   connectedCallback() {
      this.updatedAccountDetails = { ...this.accountDetails };
   }
   handleInputChange(event) {
      if (event.target.dataset.id === 'Addressline1') {
         this.updatedAccountDetails = {
            ...this.updatedAccountDetails,
            Addressline1: event.target.value,
         };
      } else if (event.target.dataset.id === 'Addressline2') {
         this.updatedAccountDetails = {
            ...this.updatedAccountDetails,
            Addressline2: event.target.value,
         };
      } else if (event.target.dataset.id === 'City') {
         this.updatedAccountDetails = {
            ...this.updatedAccountDetails,
            City: event.target.value,
         };
      } else if (event.target.dataset.id === 'State') {
         this.updatedAccountDetails = {
            ...this.updatedAccountDetails,
            State: event.target.value,
         };
      } else if (event.target.dataset.id === 'Country') {
         this.updatedAccountDetails = {
            ...this.updatedAccountDetails,
            Country: event.target.value,
         };
      } else if (event.target.dataset.id === 'PostalCode') {
         this.updatedAccountDetails = {
            ...this.updatedAccountDetails,
            PostalCode: event.target.value,
         };
      }
      console.log(' address ' + JSON.stringify(this.updatedAccountDetails));
      const addressUpdateEvent = new CustomEvent('updateaddress', {
         detail: this.updatedAccountDetails,
      });
      this.dispatchEvent(addressUpdateEvent);
   }
}