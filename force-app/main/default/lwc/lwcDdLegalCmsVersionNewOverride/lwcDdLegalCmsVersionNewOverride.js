/**
 * @author Raju Lakshman
 * @date  June 2022
 * @decription BIZS-1390 - Override for New button for Legal_CMS_Content_Version__c object.
 */

/*****************************************************************************************************************************
 *
 * Imports
 *
 *****************************************************************************************************************************/
import { LightningElement,api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { reduceErrors,stringIsBlank,stringIsNotBlank,chunkArray,isUndefinedOrNull,cloneObject } from 'c/lwcDdUtils';
import { BLANK_STRING,SPACED_HYPHEN,DELIMITER_DOT } from 'c/lwcDdConst';
import getLegalCmsContentWithPublishedVersion from '@salesforce/apex/CDdLegalCmsVersionController.getLegalCmsContentWithPublishedVersion';
import { createRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import CONTENT_VERSION_OBJECT from '@salesforce/schema/Legal_CMS_Content_Version__c';
import CV_NAME_FIELD from '@salesforce/schema/Legal_CMS_Content_Version__c.Name';
import CV_PARENT_FIELD from '@salesforce/schema/Legal_CMS_Content_Version__c.Parent__c';
import CV_STATUS_FIELD from '@salesforce/schema/Legal_CMS_Content_Version__c.Status__c';
import CV_MAJOR_VERSION_FIELD from '@salesforce/schema/Legal_CMS_Content_Version__c.Major_Version__c';
import CV_MINOR_VERSION_FIELD from '@salesforce/schema/Legal_CMS_Content_Version__c.Minor_Version__c';
import CV_VERSION_DESC_FIELD from '@salesforce/schema/Legal_CMS_Content_Version__c.Version_Change_Description__c';
import CV_BODY1_FIELD from '@salesforce/schema/Legal_CMS_Content_Version__c.Body_1__c';
import CV_BODY2_FIELD from '@salesforce/schema/Legal_CMS_Content_Version__c.Body_2__c';
import CV_BODY3_FIELD from '@salesforce/schema/Legal_CMS_Content_Version__c.Body_3__c';
import CV_BODY4_FIELD from '@salesforce/schema/Legal_CMS_Content_Version__c.Body_4__c';
import CV_CLONED_FROM_FIELD from '@salesforce/schema/Legal_CMS_Content_Version__c.Cloned_From__c';
import CV_EFFECTIVE_DATE_FIELD from '@salesforce/schema/Legal_CMS_Content_Version__c.Effective_Date__c';

/*****************************************************************************************************************************
 *
 * Functional Consts
 *
 *****************************************************************************************************************************/

const NEW_BLANK_VERSION = 'New blank version';
const COPY_FROM_VERSION = 'Copy content from published version';
const CLONE_OPTIONS = [
    { label: NEW_BLANK_VERSION, value: NEW_BLANK_VERSION },
    { label: COPY_FROM_VERSION, value: COPY_FROM_VERSION },
];

const VERSION_OPTION_NEW_MAJOR = 'New Major Version';
const VERSION_OPTION_NEW_MINOR = 'New Minor Version';

const VERSION_OPTIONS = [
    { label: VERSION_OPTION_NEW_MAJOR, value: VERSION_OPTION_NEW_MAJOR },
    { label: VERSION_OPTION_NEW_MINOR, value: VERSION_OPTION_NEW_MINOR },
];
const STATUS_DRAFT = 'Draft';

export default class LwcDdLegalCmsVersionNewOverride extends NavigationMixin(LightningElement) {
   /*****************************************************************************************************************************
     *
     * Public Variables
     *
     *****************************************************************************************************************************/
    @api parentId;
    @api enclosingTabId;
    @api parentTabId;

    /*****************************************************************************************************************************
     *
     * Private Variables
     *
     *****************************************************************************************************************************/
    _parentContent;
    _publishedVersion;
    _newVersionOption = VERSION_OPTION_NEW_MAJOR;
    _newVersionDescription;
    _newVersionEffectiveDate;
    _newVersionCloneOption = NEW_BLANK_VERSION;
    _newRecordId;

    /*****************************************************************************************************************************
     *
     * UI Getters
     *
     *****************************************************************************************************************************/
    get newVersionCloneOptions() {
        return CLONE_OPTIONS;
    }

    get newVersionOptions() {
        return VERSION_OPTIONS;
    }

    get currentPublishedVersion() {
        return this._publishedVersion ? `V${this._publishedVersion.Major_Version__c}.${this._publishedVersion.Minor_Version__c}` : BLANK_STRING;
    }

    get disableVersionOptions() {
        return isUndefinedOrNull(this._publishedVersion);
    }

    /*****************************************************************************************************************************
     *
     * LifeCycle Hooks
     *
     *****************************************************************************************************************************/
    dataFetched = false;

    renderedCallback() {
        if (!this.dataFetched) {
            this.dataFetched = true;
            // Using this instead of wire, as cacheable wire is not refreshing these variables; instead getting old values from cache.
            getLegalCmsContentWithPublishedVersion({contentId: this.parentId})
            .then(data => {
                this._parentContent = data;
                if (this._parentContent.Legal_CMS_Content_Versions__r && this._parentContent.Legal_CMS_Content_Versions__r.length) {
                    this._publishedVersion = this._parentContent.Legal_CMS_Content_Versions__r[0];
                }
            })
            .catch(error => {});
        }
    }

    /*****************************************************************************************************************************
     *
     * Event Handlers
     *
     *****************************************************************************************************************************/

    // When any form control on component is updated.
    handleChange(event){
        switch (event.target.dataset.id) {
            case "versionOptions":
                this._newVersionOption = event.detail.value;
                this._newVersionCloneOption = this._newVersionOption === VERSION_OPTION_NEW_MAJOR ?
                    NEW_BLANK_VERSION : COPY_FROM_VERSION;
                break;
            case "newVersionEffectiveDate":
                this._newVersionEffectiveDate = event.target.value;
                break;
            case "newVersionDescription":
                this._newVersionDescription = event.detail.value;
                break;
            case "contentOptions":
                this._newVersionCloneOption = event.detail.value;
                break;
            default:
                break;
        }
    }

    // When Cancel button is clicked.
    handleCancel() {
        // Go back to parent record.
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.parentId,
                actionName: 'view'
            }
        });
        // If called from console app, ask parent aura component to close the tab.
        if (this.enclosingTabId) {
            const evt = new CustomEvent("closeenclosingtab",{
                detail: {tabId:this.enclosingTabId}
            });
            this.dispatchEvent(evt);
        }
    }

    // When Save button is clicked
    handleSave(event) {
        if (!this._parentContent) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Parent Content record is not available.',
                    variant: 'error',
                }),
            );
            return;
        }
        const fields = {};

        // Determine next version
        let newMajorVersion;
        let newMinorVersion;
        if (this._newVersionOption === VERSION_OPTION_NEW_MAJOR) {
            let maxMajorVersion = 0;
            if (stringIsNotBlank(this._parentContent.Max_Version_JSON__c)) {
                const currentMaxVersionInfo = JSON.parse(this._parentContent.Max_Version_JSON__c);
                for (const [key, value] of Object.entries(currentMaxVersionInfo)) {
                    if (parseInt(key) > maxMajorVersion) {
                        maxMajorVersion = parseInt(key);
                    }
                }
            }
            newMajorVersion = maxMajorVersion + 1;
            newMinorVersion = 0;
        } else {
            newMajorVersion = this._publishedVersion.Major_Version__c;
            let maxMinorVersion = 0;
            if (stringIsNotBlank(this._parentContent.Max_Version_JSON__c)) {
                const currentMaxVersionInfo = JSON.parse(this._parentContent.Max_Version_JSON__c);
                if (currentMaxVersionInfo.hasOwnProperty(newMajorVersion.toString())) {
                    maxMinorVersion = parseInt(currentMaxVersionInfo[newMajorVersion.toString()]);
                }
            }
            newMinorVersion = maxMinorVersion + 1;
        }

        let newVersion = `V${newMajorVersion.toString()}.${newMinorVersion.toString()}`;

        const suffix = SPACED_HYPHEN + newVersion;
        let name = this._parentContent.Name + suffix;
        if (name.length > 80) {
            name = this._parentContent.Name.slice(0, (80 - suffix.length)) + suffix;
        }
        fields[CV_NAME_FIELD.fieldApiName] = name;
        fields[CV_PARENT_FIELD.fieldApiName] = this._parentContent.Id;
        fields[CV_STATUS_FIELD.fieldApiName] = STATUS_DRAFT;
        fields[CV_MAJOR_VERSION_FIELD.fieldApiName] = newMajorVersion;
        fields[CV_MINOR_VERSION_FIELD.fieldApiName] = newMinorVersion;
        fields[CV_VERSION_DESC_FIELD.fieldApiName] = this._newVersionDescription;
        fields[CV_EFFECTIVE_DATE_FIELD.fieldApiName] = this._newVersionEffectiveDate;

        if (this._newVersionCloneOption === COPY_FROM_VERSION && this._publishedVersion) {
            fields[CV_BODY1_FIELD.fieldApiName] = this._publishedVersion[CV_BODY1_FIELD.fieldApiName];
            fields[CV_BODY2_FIELD.fieldApiName] = this._publishedVersion[CV_BODY2_FIELD.fieldApiName];
            fields[CV_BODY3_FIELD.fieldApiName] = this._publishedVersion[CV_BODY3_FIELD.fieldApiName];
            fields[CV_BODY4_FIELD.fieldApiName] = this._publishedVersion[CV_BODY4_FIELD.fieldApiName];
            fields[CV_CLONED_FROM_FIELD.fieldApiName] = this._publishedVersion.Id;
        }

        const recordInput = { apiName: CONTENT_VERSION_OBJECT.objectApiName, fields };
        createRecord(recordInput)
        .then(newContentVersion => {
            this._newRecordId = newContentVersion.id;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'New version created',
                    variant: 'success',
                }),
            );
            // If called from console app, then ask parent aura to close this tab, and open new record as a subtab.
            if (this.enclosingTabId) {
                const evt = new CustomEvent("opennewversioninsubtab",{
                    detail: {tabIdToClose:this.enclosingTabId,recordId:this._newRecordId,parentTabId:this.parentTabId}
                });
                this.dispatchEvent(evt);
            } else {
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: this._newRecordId,
                        actionName: 'view'
                    }
                });
            }
        })
        .catch(error => {
            console.log(error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error creating new version record',
                    message: error.body.message,
                    variant: 'error',
                }),
            );
        });
    }
}