import { LightningElement, api, wire } from 'lwc';
import { getRecord,getFieldValue } from 'lightning/uiRecordApi';
import STATUS_FIELD from '@salesforce/schema/Lead.Status';
import SUB_STATUS_FIELD from '@salesforce/schema/Lead.Lead_Sub_Status__c';

const ELE_MODAL = '[data-id="modal"]';
export default class LwcDdLeadWarningMessage extends LightningElement {
    @api recordId;
    isShowErrorMessage = false;

    @wire(getRecord, { recordId: '$recordId', fields: [STATUS_FIELD, SUB_STATUS_FIELD], optionalFields: []  })
    leadRecord;

    get leadStatus() {
        this.evaluateModelPopup();
        return getFieldValue(this.leadRecord.data, STATUS_FIELD);
    }
    get leadSubStatus() {
        this.evaluateModelPopup();
        return getFieldValue(this.leadRecord.data, SUB_STATUS_FIELD);
    }

    evaluateModelPopup()
    {
        this.isShowErrorMessage = getFieldValue(this.leadRecord.data, STATUS_FIELD) === 'Unqualified' && getFieldValue(this.leadRecord.data, SUB_STATUS_FIELD) === 'Not Rx or NV';
        if(this.isShowErrorMessage)
        {
            this.showModal();
        }
        else{
            this.hideModal();
        }
    }
    /**
    * @decription Shows Modal
    * @param   None
    * @return  None
    */
     showModal() {
        window.setTimeout(
            ()=> {
            let control = this.template.querySelector(ELE_MODAL);
             console.log('control = ',control);
             if (control) {
                control.show();
             }
            },
            6000
        );
    }

    /**
    * @decription Hides Modal
    * @param   None
    * @return  None
    */
    hideModal() {
        let control = this.template.querySelector(ELE_MODAL);
        if (control) {
            control.hide();
        }
    }
}