/**
 * @author Mahesh Chouhan
 * @date  Nov 17, 2022
 * @decription Component to display external links in the quick view panel
 */

/*****************************************************************************************************************************
 *
 * Imports
 *
 *****************************************************************************************************************************/
import { LightningElement, api, wire, track } from 'lwc';
import { TARGET_BLANK } from 'c/lwcDdConst';
import { reduceErrors } from 'c/lwcDdUtils';
import getQuickLinkConfiguration from "@salesforce/apex/CDdQuickLinkPanelController.getQuickLinkConfiguration";

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

export default class LwcDdQuickLinkPanel extends LightningElement {
    /*****************************************************************************************************************************
    *
    * Public Variables
    *
    *****************************************************************************************************************************/
    @api objectApiName;
    @api recordId;
    /*****************************************************************************************************************************
    *
    * Private Variables
    *
    *****************************************************************************************************************************/
    @track merchantQuickLinks;
    @track dasherQuickLinks;
    @track consumerQuickLinks;
    @track deliveryQuickLinks;
    quickLinks;

    /*****************************************************************************************************************************
    *
    * Wires
    *
    *****************************************************************************************************************************/
    @wire(getQuickLinkConfiguration, { objectApiName: '$objectApiName', recordId: '$recordId'})
    wiredGetQuickLinkConfiguration({ data, error }) {
        if (data) {
            this.quickLinks = data;
            for (const quickLink of data) {
                switch (quickLink.customerType) {
                    case CUSTOMER_TYPE_MERCHANT:
                        this.merchantQuickLinks = this.merchantQuickLinks ? this.merchantQuickLinks : [];
                        this.merchantQuickLinks.push(quickLink);
                        break;
                    case CUSTOMER_TYPE_DASHER:
                        this.dasherQuickLinks = this.dasherQuickLinks ? this.dasherQuickLinks : [];
                        this.dasherQuickLinks.push(quickLink);
                        break;
                    case CUSTOMER_TYPE_CONSUMER:
                        this.consumerQuickLinks = this.consumerQuickLinks ? this.consumerQuickLinks : [];
                        this.consumerQuickLinks.push(quickLink);
                        break;
                    default:
                        //Default to Delivery
                        this.deliveryQuickLinks = this.deliveryQuickLinks ? this.deliveryQuickLinks : [];
                        this.deliveryQuickLinks.push(quickLink);
                        break;
                }
            }
            this.hideSpinner();
        }

        if (error) {
            console.log('wiredGetQuickLinkConfiguration wire error - ', reduceErrors(error));
        }
    }

    /*****************************************************************************************************************************
    *
    * Event Handlers
    *
    *****************************************************************************************************************************/
    openURL(event) {
        let quickLinkRecord = this.quickLinks.find(quickLink => {
            return quickLink.id === event.target.dataset.id;
        });
        window.open(quickLinkRecord.url, TARGET_BLANK);
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