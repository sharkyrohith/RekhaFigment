/**
 * @author Mahesh Chouhan
 * @date  Nov 18, 2022
 * @decription Component to display Audience Info in the quick view panel
 */

/*****************************************************************************************************************************
 *
 * Imports
 *
 *****************************************************************************************************************************/
import { LightningElement, api, wire, track } from 'lwc';
import { reduceErrors } from 'c/lwcDdUtils';
import getAudienceInfo from '@salesforce/apex/CDdAudienceInfoController.getAudienceInfo';

/*****************************************************************************************************************************
 *
 * CSS Class Consts
 *
 *****************************************************************************************************************************/
 const SLDS_HIDDEN = 'slds-hidden';

/*****************************************************************************************************************************
 *
 * Functional Consts
 *
 *****************************************************************************************************************************/
const CUSTOMER_TYPE_MERCHANT = 'Merchant';
const CUSTOMER_TYPE_DASHER = 'Dasher';
const CUSTOMER_TYPE_CONSUMER = 'Consumer';
const ELEMENT_SPINNER = 'lightning-spinner';

export default class LwcDdAudienceInfo extends LightningElement {
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
    @track consumerAudience;
    @track dasherAudience;
    @track merchantAudience;
    @track delivery;

    /*****************************************************************************************************************************
    *
    * Wires
    *
    *****************************************************************************************************************************/
    @wire(getAudienceInfo, { caseId: '$recordId' })
    wiredGetAudienceInfo({ data, error }) {
        if (data) {
            for (const audience of data) {
                switch (audience.type) {
                    case CUSTOMER_TYPE_MERCHANT:
                        this.merchantAudience = this.merchantAudience ? this.merchantAudience : [];
                        this.merchantAudience.push(audience);
                        break;
                    case CUSTOMER_TYPE_DASHER:
                        this.dasherAudience = this.dasherAudience ? this.dasherAudience : [];
                        this.dasherAudience.push(audience);
                        break;
                    case CUSTOMER_TYPE_CONSUMER:
                        this.consumerAudience = this.consumerAudience ? this.consumerAudience : [];
                        this.consumerAudience.push(audience);
                        break;
                    default:
                        //Default to Delivery
                        this.delivery = this.delivery ? this.delivery : [];
                        this.delivery.push(audience);
                        break;
                }
            }
            this.hideSpinner();
        }

        if (error) {
            console.log('wiredGetAudienceInfo wire error - ', reduceErrors(error));
        }
    }

    /*****************************************************************************************************************************
    *
    * Helper methods
    *
    *****************************************************************************************************************************/
     hideSpinner() {
        let spinner = this.template.querySelector(ELEMENT_SPINNER);
        if (spinner) {
            spinner.classList.add(SLDS_HIDDEN);
        }
    }
}