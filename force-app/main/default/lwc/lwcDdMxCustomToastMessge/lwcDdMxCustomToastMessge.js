/**
 * @author Praveen Pandem
 * @date  07/15/2022
 *@Description: Display the custom toast message from UI.
 *Feature: This can be addedd as child to the any parent component to post the toast messages.
 */
/*****************************************************************************************************************************
 *
 * Imports
 *
 ***********/

import { LightningElement, api, track } from 'lwc';

export default class LwcDdMxCustomToastMessge extends LightningElement {
   /*****************************************************************************************************************************
    *
    * Public Variables
    *
    *****************************************************************************************************************************/
   type;
   message;
   showToastBar = false;
   @api autoCloseTime = 20000;
   /*****************************************************************************************************************************
    *
    * Event Handlers
    *
    *****************************************************************************************************************************/

   @api
   showToast(type, message) {
      this.type = type;
      this.message = message;
      this.showToastBar = true;
      setTimeout(() => {
         this.closeModel();
      }, this.autoCloseTime);
   }

   closeModel() {
      this.showToastBar = false;
      this.type = '';
      this.message = '';
   }
   /*****************************************************************************************************************************
    *
    * UI Getters
    *
    *****************************************************************************************************************************/

   get getIconName() {
      return 'utility:' + this.type;
   }

   get innerClass() {
      return (
         'slds-icon_container slds-icon-utility-' +
         this.type +
         ' slds-icon-utility-success slds-m-right_small slds-no-flex slds-align-top'
      );
   }

   get outerClass() {
      return 'slds-notify slds-notify_toast slds-theme_' + this.type;
   }
}