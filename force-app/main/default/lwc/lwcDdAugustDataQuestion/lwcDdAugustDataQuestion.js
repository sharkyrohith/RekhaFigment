/**
 * @author Mahesh Chouhan
 * @date  Aug 2022
 * @decription Pop up to check if Dasher or Consumer Account is impacted 
 */

/*****************************************************************************************************************************
 *
 * Imports
 *
 *****************************************************************************************************************************/
import { LightningElement, wire, api } from 'lwc';
import checkAccountImpact from '@salesforce/apex/CDdAugustDataQuestionController.checkAccountImpact';

/*****************************************************************************************************************************
 *
 * Functional Consts
 *
 *****************************************************************************************************************************/
const UNAUTHORIZED_USER_ERROR = 'You are not authorized';

export default class LwcDdAugustDataQuestion extends LightningElement {
    /*****************************************************************************************************************************
     *
     * Public Variables
     *
     *****************************************************************************************************************************/
    @api recordId;

    /*****************************************************************************************************************************
     *
     * Private Variables
     *
     *****************************************************************************************************************************/
    isAccountImpacted;
    errorMsg;
    showError;
    hideSpinner;

    /*****************************************************************************************************************************
     *
     * Wire
     *
     *****************************************************************************************************************************/
    @wire(checkAccountImpact, { accountId: '$recordId'})
    wiredCheckAccountImpact({error,data}) {
        if (data !== undefined) {
            this.isAccountImpacted = data;
            this.hideSpinner = true;
            this.showError = false;
        } else if(error) {
            console.error(JSON.stringify(error));
            this.showError = true;
            this.errorMsg = UNAUTHORIZED_USER_ERROR;
            this.hideSpinner = true;
        }
    }
}