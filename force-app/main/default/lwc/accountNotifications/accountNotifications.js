/*****************************************************************************************************************************
*
* Imports
*
*****************************************************************************************************************************/
import { LightningElement,api,wire } from 'lwc';
import { stringIsBlank,stringIsNotBlank,reduceErrors } from 'c/lwcDdUtils'; // import any other method from Util as needed
import { BLANK_STRING,ACCOUNT_PREFIX,CASE_PREFIX } from 'c/lwcDdConst';
import getActiveNotificationsForAccount from '@salesforce/apex/AccountNotificationsController.getActiveNotificationsForAccount';
import { getRecord,getFieldValue } from 'lightning/uiRecordApi';

import CASE_ACCOUNT_FIELD from '@salesforce/schema/Case.AccountId';

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

const ELE_NOTICE = '[data-id="Account_Notification"]';
const ERROR = 'Error';
const WARNING = 'Warning';
const SUCCESS = 'Success';
const INFO = 'Info';

export default class AccountNotifications extends LightningElement {
    /*****************************************************************************************************************************
    *
    * Public Variables
    *
    *****************************************************************************************************************************/

    // {String} (Required) - Any Record Id (supports Case and Account for now, can be extended to Other objects linked to accounts)
    @api recordId;
    @api types = '';

    /*****************************************************************************************************************************
    *
    * Private Variables
    *
    *****************************************************************************************************************************/
    objectName = BLANK_STRING;
    fields = [];
    accountId;
    loading = true;
    wiredResult;
    data = [];
    falseVal = false;
    /*****************************************************************************************************************************
    *
    * LifeCycle Hooks (renderedCallback,connectedCallback,disconnectedCallback)
    *
    *****************************************************************************************************************************/

    connectedCallback() {
        if (stringIsNotBlank(this.recordId)) {
            if (this.recordId.startsWith(ACCOUNT_PREFIX)) {
                this.objectName = 'Account';
                this.accountId = this.recordId;
            }
            if (this.recordId.startsWith(CASE_PREFIX)) {
                this.objectName = 'Case';
                this.fields = [CASE_ACCOUNT_FIELD];
            }
        }
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

    @wire(getRecord, { recordId: '$recordId', fields: '$fields' })
    wiredRecord({ error, data }) {
        if (data) {
            if (this.recordId.startsWith(CASE_PREFIX)) {
                this.accountId = getFieldValue(data, CASE_ACCOUNT_FIELD)
            }
        } else if (error) {
            console.log("error", JSON.stringify(error));
        }
    }

    @wire(getActiveNotificationsForAccount,{accountId:'$accountId',objectName:'$objectName',types:'$types'})
    wiredGetActiveNotificationsForAccount(result) {
        this.wiredResult = result;
        this.loading = false;
        if (result.data && result.data.length) {
            this.data = result.data;
            let variant = BLANK_STRING;
            let isDismissable = true;
            let messageMap = {
                'Error': [],
                'Warning': [],
                'Success': [],
                'Info': []
            };
            let title = BLANK_STRING;
            let setTitle = true;
            for (const item of this.data) {
                if (stringIsBlank(item.title)) {
                    continue;
                }
                if (stringIsBlank(title)) {
                    title = item.title;
                } else if (title !== item.title) {
                    setTitle = false;
                }
            }
            title = setTitle ? title : BLANK_STRING;
            for (const item of this.data) {
                isDismissable = isDismissable && item.isDismissable;
                messageMap[item.severity].push(setTitle || stringIsBlank(item.title)? item.message : `<b>${item.title}</b>: ${item.message}`);
                if (item.severity === ERROR ||
                    (item.severity === WARNING && variant !== ERROR) ||
                    (item.severity === SUCCESS && variant !== ERROR && variant !== WARNING) ||
                    (item.severity === INFO && variant !== ERROR && variant !== WARNING && variant !== SUCCESS)) {
                    variant = item.severity;
                }
            }
            let messages = [...messageMap[ERROR],...messageMap[WARNING],...messageMap[SUCCESS],...messageMap[INFO]];

            let target = this.template.querySelector(ELE_NOTICE);
            if (target) {
                target.show(title,messages.length === 1 ? messages[0] : messages,variant,null,isDismissable);
            }
        } else {
            console.log(reduceErrors(result.error));
        }
    }

    /*****************************************************************************************************************************
    *
    * Event Handlers
    *
    *****************************************************************************************************************************/

    /*****************************************************************************************************************************
    *
    * Logic / Helper methods
    *
    *****************************************************************************************************************************/
}