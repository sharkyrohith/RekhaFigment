/**
 * @author Raju Lakshman
 * @date  June 2022
 * @decription BIZS-1390 - Editor for the Legal CMS content version body.
 */

/*****************************************************************************************************************************
 *
 * Imports
 *
 *****************************************************************************************************************************/
import { LightningElement, api, wire,track } from 'lwc';
import { getRecord, getRecordNotifyChange, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import { stringIsBlank,stringIsNotBlank,isUndefinedOrNull,cloneObject,reduceErrors,getURLParam,chunkStringIntoArray } from 'c/lwcDdUtils';
import { BLANK_STRING,LONG_TEXT_AREA_MAX_SIZE } from 'c/lwcDdConst';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import canEditContentVersion from '@salesforce/apex/CDdLegalCmsVersionController.canEditContentVersion';

import ID_FIELD from '@salesforce/schema/Legal_CMS_Content_Version__c.Id';
import FIELD_BODY_1 from '@salesforce/schema/Legal_CMS_Content_Version__c.Body_1__c';
import FIELD_BODY_2 from '@salesforce/schema/Legal_CMS_Content_Version__c.Body_2__c';
import FIELD_BODY_3 from '@salesforce/schema/Legal_CMS_Content_Version__c.Body_3__c';
import FIELD_BODY_4 from '@salesforce/schema/Legal_CMS_Content_Version__c.Body_4__c';
import FIELD_STATUS from '@salesforce/schema/Legal_CMS_Content_Version__c.Status__c';

/*****************************************************************************************************************************
 *
 * Functional Consts
 *
 *****************************************************************************************************************************/

const FIELDS = [FIELD_STATUS,FIELD_BODY_1,FIELD_BODY_2,FIELD_BODY_3,FIELD_BODY_4];
const READONLY_STATUSES = new Set(['Published','Archived']);

export default class LwcDdLegalContentEditor extends LightningElement {
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
    isReadOnly = true;
    isEditMode = false;
    body = BLANK_STRING;
    bodyBackup = BLANK_STRING;
    canEdit = false;
    /*****************************************************************************************************************************
     *
     * Wires
     *
     *****************************************************************************************************************************/

    //Get the Body of the content version.
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS})
    wiredGetRecord({error,data}) {
        if (data) {
            const status = getFieldValue(data, FIELD_STATUS);
            this.isReadOnly = READONLY_STATUSES.has(getFieldValue(data, FIELD_STATUS));
            this.body = this.bodyBackup =
                this.getFieldVal(data, FIELD_BODY_1) +
                this.getFieldVal(data, FIELD_BODY_2) +
                this.getFieldVal(data, FIELD_BODY_3) +
                this.getFieldVal(data, FIELD_BODY_4);
        } else {
            // handle error
        }
    }

    @wire(canEditContentVersion)
    wiredCanEditContentVersion({error,data}) {
        if (!error) {
            this.canEdit = data;
        }
    }

    /*****************************************************************************************************************************
     *
     * Event Handlers
     *
     *****************************************************************************************************************************/

    // When Body is updated
    handleBodyChange(event) {
        this.body = event.target.value;
    }

    // When Save button is clicked
    handleSaveButtonClick(event) {
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;

        // Divide the content across the long text area fields.
        const bodyChunks = chunkStringIntoArray(this.body,LONG_TEXT_AREA_MAX_SIZE);
        if (bodyChunks.length > 0 && stringIsNotBlank(bodyChunks[0])) {
            fields[FIELD_BODY_1.fieldApiName] = bodyChunks[0];
        }
        if (bodyChunks.length > 1 && stringIsNotBlank(bodyChunks[1])) {
            fields[FIELD_BODY_2.fieldApiName] = bodyChunks[1];
        }
        if (bodyChunks.length > 2 && stringIsNotBlank(bodyChunks[2])) {
            fields[FIELD_BODY_3.fieldApiName] = bodyChunks[2];
        }
        if (bodyChunks.length > 3 && stringIsNotBlank(bodyChunks[3])) {
            fields[FIELD_BODY_4.fieldApiName] = bodyChunks[3];
        }
        const recordInput = { fields };
        updateRecord(recordInput)
        .then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Legal Content Version Body Updated',
                    variant: 'success'
                })
            );
            getRecordNotifyChange([{recordId: this.recordId}]);
            this.isEditMode = false;
            this.bodyBackup = this.body;
        })
        .catch(error => {
            console.log(error,reduceErrors(error));
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Save failed. Please reach out to your System Administrator for assistance.',
                    variant: 'error'
                })
            );
        });
    }

    // When Edit button is clicked
    handleEditButtonClick() {
        this.isEditMode = true;
    }

    // When Cancel button is clicked
    handleCancelButtonClick(event) {
        this.isEditMode = false;
        this.body = this.bodyBackup;
    }

    /*****************************************************************************************************************************
    *
    * Logic / Helper methods
    *
    *****************************************************************************************************************************/

    /**
     * @decription Extends uiRecordApi getFieldValue to send BLANK_STRING if field value does not exist
     * @param   {SObject} data - Content version Record
     * @param   {String} field - Field API name of field to get
     * @return  {String}
     */
    getFieldVal(data,field) {
        const val =  getFieldValue(data, field);
        return (val ? val : BLANK_STRING);
    }
}