import { LightningElement, wire, api } from 'lwc';
import getData from '@salesforce/apex/CDdMxDocumentsController.getData';
import getMasterData from '@salesforce/apex/CDdMxDocumentsController.getMasterData';
import uploadCV from '@salesforce/apex/CDdMxDocumentsController.uploadCV';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import ContentVersion_OBJECT from '@salesforce/schema/ContentVersion';
import CV_Verification_Status_FIELD from '@salesforce/schema/ContentVersion.Mx_Document_Verification_Status__c';
import ID_FIELD from "@salesforce/schema/ContentVersion.Id";
import NOTES_FIELD from "@salesforce/schema/ContentVersion.Mx_Document_Verification_Notes__c";

import BV_Status_FIELD from '@salesforce/schema/Mx_Onboarding__c.Business_Verification_Status__c';
import BV_Notes_FIELD from '@salesforce/schema/Mx_Onboarding__c.Business_Verification_Status_Notes__c';
import BV_ID_FIELD from "@salesforce/schema/Mx_Onboarding__c.Id";
import BV_Status_Reason_FIELD from "@salesforce/schema/Mx_Onboarding__c.Business_Verification_Status_Reason__c";
import UPDATE_TYPE_FIELD from "@salesforce/schema/Mx_Onboarding__c.UpdateType__c";
import hasMxDocumentsPermission from '@salesforce/customPermission/Mx_Documents_Permission';

import ERROR_MSG from '@salesforce/label/c.SSMO_Mx_Document_Upload_Error_Message';
import NO_ACCESS_MSG from '@salesforce/label/c.SSMO_Mx_Document_Upload_No_Access_Message';
import FILE_FORMAT from '@salesforce/label/c.SSMO_Mx_Document_Upload_Formats';
import FILE_UPLOAD_ERROR_MSG from '@salesforce/label/c.SSMO_Mx_Document_File_Upload_Error_Message';

import { updateRecord } from "lightning/uiRecordApi"
const MAX_FILE_SIZE = 3145728;

export default class LwcDdMxDocuments extends LightningElement {

    loaded = true;
    storeId;
    strAccountName;
    storeExisted = false;

    savedBusinessVerificationStatus;
    savedBusinessVerificationStatusReason;
    savedBusinessVerificationStatusNotes;

    contentVersionRecords;

    editContentVersion = false;
    businessVerificationOpen = false;
    documentDetailsOpen = false;

    editedRecordId;
    editedStatus;
    editedNotes;
    editedRecordTitle;
    editedRecordDocType;

    statusToStatusReason = new Map() ;
    statusOptions = [];
    statusReasonOptions = [];

    bvRecordId;
    businessVerificationStatus;
    businessVerificationStatusNotes;
    businessVerificationStatusReason = [];

    base64;
    filename;
    strTitle;
    selectedDocumentType;
    strNotes;
    fileData;
    documentTypeOptions = [];

    error;
    errorMsg;

    newStatus = "Pending Review";

    label = {
        ERROR_MSG,
        NO_ACCESS_MSG,
        FILE_FORMAT,
        FILE_UPLOAD_ERROR_MSG
    };

    @api recId;

    @api recordId;

    // getting the default record type id, if you dont' then it will get master
    @wire(getObjectInfo, { objectApiName: ContentVersion_OBJECT })

    ContentVersionMetadata;

    @wire(getPicklistValues,
        {
            recordTypeId: '$ContentVersionMetadata.data.defaultRecordTypeId',
            fieldApiName: CV_Verification_Status_FIELD

        }
    )
    VerificationStatusPicklistValues;

    get isMxMxDocumentsPermissionEnabled() {
        return hasMxDocumentsPermission;
    }

	connectedCallback() {

        if(this.recId){

            this.loaded = false;
            this.statusoptions = [];

            getMasterData({recordIdCase: this.recId })
            .then((result) => {

                if(result){
                    console.log('@@@result',result);
                    if(result.mapStatusToStatusReason){
                        let statusdata = result.mapStatusToStatusReason;
                        for (var status in statusdata) {
                            let statusreasons = [];
                            for (var statusreason in statusdata[status]) {
                                statusreasons.push(statusdata[status][statusreason]);
                            }
                            this.statusToStatusReason.set(status,statusreasons)
                            console.log('key', status, statusdata[status]);
                            this.statusoptions.push({ label:status, value:status  });
                        }
                    }
                    if(result.lstDocTypeName){
                        let docdata = result.lstDocTypeName;
                        for (var objdocname in docdata) {
                            this.documentTypeOptions.push({ label:docdata[objdocname], value:docdata[objdocname]  });
                        }

                    }

                    this.loadData();
                }

                this.error = undefined;
            })
            .catch((error) => {
                this.error = error;
                this.contentVersionRecords = undefined;
            }) .finally(() => {
                this.loaded = true;
            });

        }
    }

    loadData(){
        this.loaded = false;
        getData
        ({
            recordIdCase: this.recId
        })
        .then((result) => {

            if(result){

            this.businessVerificationStatusReason = [];

            let data = result;

            console.log('@@@data',data);

            this.storeExisted = true;

            this.storeId = data.StoreId;

            this.strAccountName = data.accountName;

            this.businessVerificationStatus = data.Status;

            this.savedBusinessVerificationStatus = data.Status;

            this.savedBusinessVerificationStatusNotes = data.StatusNotes;

            this.businessVerificationStatusNotes = data.StatusNotes;

            this.bvRecordId = data.businessVerificationId;

            this.savedBusinessVerificationStatusReason = data.StatusReason;

            if(this.savedBusinessVerificationStatus){
                this.populateStatusReasonOptions(this.savedBusinessVerificationStatus);
                if(data.StatusReason){
                    this.businessVerificationStatusReason = data.StatusReason.split('; ');
                }

            }


            console.log('@@@data.lstContentVersion',data.lstContentVersion);

            if(data.lstContentVersion){
                this.contentVersionRecords  = data.lstContentVersion;

                    let tempRecs = [];
                    data.lstContentVersion.forEach( ( record ) => {
                            let tempRec = Object.assign( {}, record );
                            //tempRec.url = '/sfc/servlet.shepherd/document/download/'+record.ContentDocumentId;
                            tempRec.url = '/'+record.ContentDocumentId;
                            tempRecs.push( tempRec );
                    });
                    if(tempRecs.length > 0){
                        this.contentVersionRecords = tempRecs;
                    }
            }

            this.error = undefined;

            }

        })
        .catch((error) => {
            this.error = error;
            this.contentVersionRecords = undefined;
        })
        .finally(() => {
            this.loaded = true;
        });

    }

    handleContentVersionEdit(event){
        this.editContentVersion = true;
        const itemIndex = event.currentTarget.dataset.index;
        const rowData = this.contentVersionRecords[itemIndex];

        this. editedRecordId = rowData.Id;
        this.editedRecordTitle = rowData.Title;
        this.editedRecordDocType = rowData.Mx_Document_Type__c;
        let status = rowData.Mx_Document_Verification_Status__c;
        this.editedStatus = status;
        this.editedNotes =  rowData.Mx_Document_Verification_Notes__c;

        console.log(rowData);
    }


    handleBusinessVerification(){
        this.businessVerificationOpen = true;
    }

    handleBUNotesChange(event){
        this.savedBusinessVerificationStatusNotes = event.detail.value;
    }

    saveBusinessVerification(){
        this.loaded = false;
        this.businessVerificationOpen = false;

        const fields = {};

        fields[BV_ID_FIELD.fieldApiName] = this.bvRecordId;
        fields[BV_Status_FIELD.fieldApiName] = this.businessVerificationStatus;
        fields[UPDATE_TYPE_FIELD.fieldApiName] = 'Inbound';
        fields[BV_Notes_FIELD.fieldApiName] = this.savedBusinessVerificationStatusNotes;

        if(this.businessVerificationStatusReason){
            let strBusinessVerificationStatusReason =  this.businessVerificationStatusReason.toString().replaceAll(',','; ');
            fields[BV_Status_Reason_FIELD.fieldApiName] = strBusinessVerificationStatusReason;
        }
        else{
            fields[BV_Status_Reason_FIELD.fieldApiName] = '';
        }

        const recordInput = {
            fields: fields
        };

        updateRecord(recordInput).then((record) => {
         console.log(record);
         this.loadData();
        });

    }

    closeModal(){
        this.businessVerificationOpen = false;
        this.documentDetailsOpen = false;
		this.editContentVersion = false;
    }


    handleBusinessVerStatusReasonChange(event) {
        this.businessVerificationStatusReason = event.detail.value;
    }


    handleStatusChange(event) {
        this.editedStatus = event.detail.value;
    }


    handleNotesChange(event){
        this.editedNotes = event.detail.value;
    }

    saveEditedInfo(event){

        this.loaded = false;
        this.editContentVersion = false;

        const fields = {};

        fields[ID_FIELD.fieldApiName] = this.editedRecordId;
        fields[CV_Verification_Status_FIELD.fieldApiName] = this.editedStatus;
        fields[NOTES_FIELD.fieldApiName] = this.editedNotes;

        const recordInput = {
            fields: fields
        };

        updateRecord(recordInput).then((record) => {
         console.log(record);
         this.loadData();
        });
    }

    handleBusinessVerStatusChange(event){
        this.businessVerificationStatus = event.detail.value;
        this.populateStatusReasonOptions(this.businessVerificationStatus);
    }


    populateStatusReasonOptions(selBusinessVerStatus){

        if(this.statusToStatusReason){
            if(this.statusToStatusReason.has(selBusinessVerStatus)){
                let statusreason = this.statusToStatusReason.get(selBusinessVerStatus);
                console.log('@@@statusreason',statusreason);
                this.statusReasonOptions = [];
                statusreason.forEach((value) => {
                    this.statusReasonOptions.push({ label: value, value: value });
               });
            }
        }
    }


    handleDocumentUpload(){
        this.documentDetailsOpen = true;
        this.fileData = null;
        this.base64 = null;
        this.filename = null;
        this.selectedDocumentType = null;
        this.strNotes = null;
        this.strTitle = null;
        this.errorMsg = null;

    }

    get acceptedFormats() {
        //return ['.xlsx','.xls','.csv','.png','.doc','.docx','.pdf','.jpg','.jpeg','.gif','.svg'];
        return this.label.FILE_FORMAT.split(';')
    }

    handleTitleChange(event){
        this.strTitle =  event.detail.value;
    }
    handleDocumentTypeChange(event){
        this.selectedDocumentType = event.detail.value;
    }

    handleNewNotesChange(event){
        this.strNotes = event.detail.value;
    }

    openFileUpload(event) {
        this.errorMsg = null;
        const file = event.target.files[0];
        if(file.size >= MAX_FILE_SIZE){
            this.errorMsg = this.label.FILE_UPLOAD_ERROR_MSG;
            this.fileData = null;
        }
        else{
            var reader = new FileReader()
            reader.onload = () => {
                var base64 = reader.result.split(',')[1];
                this.base64 = base64;
                this.filename = file.name;
                this.fileData = {
                    'filename': file.name,
                    'base64': base64,
                    'recordId': this.recId
                }
                console.log(this.fileData)
            }
            reader.readAsDataURL(file);

            if(this.base64){
                this.errorMsg = null;
            }
        }
    }

    saveCV(){

        let isValid = true;
        let inputFields = this.template.querySelectorAll('.validate');
        inputFields.forEach(inputField => {
            if(!inputField.checkValidity()) {
                inputField.reportValidity();
                isValid = false;
            }
        });

        if(isValid){

            if(this.base64){
                this.loaded = false;
                this.documentDetailsOpen = false;

                uploadCV({
                    base64 : this.base64,
                    filename : this.filename,
                    storeId : this.storeId,
                    strDocumentType : this.selectedDocumentType,
                    strNotes : this.strNotes,
                    strVerificationStatus : this.newStatus,
                    strTitle : this.strTitle

                })
                .then(result => {
                    this.loadData();
                    this.fileData = null;
                    this.strTitle = null;
                    this.selectedDocumentType = null;
                    this.strNotes = null;
                })
                .catch(error => {
                    this.loaded = true;

                });
            }
            else{
                this.errorMsg = 'Please upload file';
            }

        }
    }
}