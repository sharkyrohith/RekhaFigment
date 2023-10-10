/**
 * @author Raju Lakshman
 * @date  June 2022
 * @decription BIZS-1390 - Publish Button Screen Action handler for Legal_CMS_Content_Version__c
 */

/*****************************************************************************************************************************
 *
 * Imports
 *
 *****************************************************************************************************************************/
import { LightningElement,api,wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecord,  getFieldValue, getRecordNotifyChange } from 'lightning/uiRecordApi';
import { stringIsBlank,stringIsNotBlank,isUndefinedOrNull,cloneObject,reduceErrors } from 'c/lwcDdUtils';
import { BLANK_STRING } from 'c/lwcDdConst';
import publishContentVersion from '@salesforce/apex/CDdLegalCmsVersionController.publishContentVersion';
import canPublish from '@salesforce/apex/CDdLegalCmsVersionController.canPublish';

import FIELD_STATUS from '@salesforce/schema/Legal_CMS_Content_Version__c.Status__c';
import FIELD_PARENT from '@salesforce/schema/Legal_CMS_Content_Version__c.Parent__c';
import FIELD_PUBLISHED_DATE from '@salesforce/schema/Legal_CMS_Content_Version__c.Published_Date__c';

/*****************************************************************************************************************************
 *
 * Functional Consts
 *
 *****************************************************************************************************************************/
const FIELDS = [FIELD_STATUS,FIELD_PARENT];
const STATUS_PUBLISHED = 'Published';

export default class LwcDdLegalCmsVersionPublishQuickAction extends LightningElement {
   /*****************************************************************************************************************************
     *
     * Public Variables
     *
     *****************************************************************************************************************************/
    @api recordId;
    @api objectApiName;

    /*****************************************************************************************************************************
     *
     * Private Variables
     *
     *****************************************************************************************************************************/
    parentId;
    currentStatus;
    showError = false;
    userHasAccessToPublish = false;
    /*****************************************************************************************************************************
     *
     * Wires
     *
     *****************************************************************************************************************************/

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS})
    wiredGetRecord({error,data}) {
        if (data) {
            this.parentId = getFieldValue(data, FIELD_PARENT);
            this.currentStatus = this.getFieldVal(data, FIELD_STATUS);
            this.showError = this.currentStatus === STATUS_PUBLISHED;
        } else {
            // handle error
        }
    }

    @wire(canPublish)
    wiredCanPublish({error,data}) {
        if (!error) {
            this.userHasAccessToPublish = data;
        }
    }

    /*****************************************************************************************************************************
     *
     * Event Handlers
     *
     *****************************************************************************************************************************/

    // When Close button is cliked
    handleClose() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    // Whenb Publish button is clicked
    handlePublish() {
        publishContentVersion({
            versionIdToPublish: this.recordId,
            parentId: this.parentId
        })
        .then(result => {
            getRecordNotifyChange([{recordId: this.recordId}]);
            this.dispatchEvent(new CloseActionScreenEvent());
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Version published',
                    variant: 'success'
                })
            );
        })
        .catch(error => {
            console.log(error,reduceErrors(error));
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Publish failed. Please reach out to your System Administrator for assistance.',
                    variant: 'error'
                })
            );
        })
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