/**
 * @author Raju Lakshman
 * @date  Oct 22, 2021
 * @decription Component to display account external links in the quick view panel
 */

/*****************************************************************************************************************************
 *
 * Imports
 *
 *****************************************************************************************************************************/
import { LightningElement,api,wire } from 'lwc';
import { BLANK_STRING } from 'c/lwcDdConst';
import { getRecord,getFieldValue } from 'lightning/uiRecordApi';
import BUSINESS_ID_FIELD from '@salesforce/schema/Account.Business_ID_text__c';
import STORE_ID_FIELD from '@salesforce/schema/Account.Restaurant_ID__c';

const TARGET = '_Blank';

export default class LwcDdGridReportQuickViewAccountCustomLinks extends LightningElement {
    /*****************************************************************************************************************************
    *
    * Public Variables
    *
    *****************************************************************************************************************************/

    // {String} (Required) Account Id to display
    @api recordId;

    /*****************************************************************************************************************************
    *
    * Wires
    *
    *****************************************************************************************************************************/

    @wire(getRecord, { recordId: '$recordId', fields: [BUSINESS_ID_FIELD, STORE_ID_FIELD] })
    account;

    /*****************************************************************************************************************************
    *
    * UI Getters
    *
    *****************************************************************************************************************************/

    get mintStorePageLink() {
        const storeId = getFieldValue(this.account.data, STORE_ID_FIELD);
        return storeId ? `https://admin-gateway.doordash.com/mx-tools/store/${storeId}` : BLANK_STRING;
    }

    get mintBusinessPageLink(){
        const businessId = getFieldValue(this.account.data, BUSINESS_ID_FIELD);
        return businessId ? `https://admin-gateway.doordash.com/mx-tools/business/${businessId}` : BLANK_STRING;
    }

    get merchantPortalLink() {
        const storeId = getFieldValue(this.account.data, STORE_ID_FIELD);
        return storeId ? `https://www.doordash.com/merchant/summary?store_id=${storeId}` : BLANK_STRING;
    }

    /*****************************************************************************************************************************
    *
    * Event Handlers
    *
    *****************************************************************************************************************************/
    openMintStorePage() {
        window.open(this.mintStorePageLink,TARGET);
    }

    openMintBusinessPage() {
        window.open(this.mintBusinessPageLink,TARGET);
    }

    openMerchantPortal() {
        window.open(this.merchantPortalLink,TARGET);
    }
}