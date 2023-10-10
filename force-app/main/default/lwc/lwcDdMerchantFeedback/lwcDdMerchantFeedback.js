import { LightningElement,api,wire,track } from 'lwc';
import getCategories from '@salesforce/apex/CDdMerchantFeedbackController.getMerchantFeedbackCatagories';
import getWrapperList from '@salesforce/apex/CDdMerchantFeedbackController.getFeedBackEntryWrapperList';
import createRecords from '@salesforce/apex/CDdMerchantFeedbackController.createMerchantFeedbackEntry';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import MFE_OBJECT from '@salesforce/schema/Merchant_Feedback_Entry__c';
import MT_OBJECT from '@salesforce/schema/Merchant_Touchpoint__c';
import STATUS_FIELD from '@salesforce/schema/Merchant_Feedback_Entry__c.Status__c';
import OUTCOME_FIELD from '@salesforce/schema/Merchant_Feedback_Entry__c.Outcome__c';
import COMPETITORS_FIELD from '@salesforce/schema/Merchant_Feedback_Entry__c.Competitors__c';
import TOUCHPOINT_FIELD from '@salesforce/schema/Merchant_Touchpoint__c.Touchpoint__c';
import SENTIMENT_FIELD from '@salesforce/schema/Merchant_Feedback_Entry__c.Sentiment__c';
import TOUCHPOINT_INTERACTION_FIELD from '@salesforce/schema/Merchant_Touchpoint__c.Touchpoint_Interaction__c';

export default class LwcDdMerchantFeedback extends LightningElement {

    @api recId;
    @api objectName;

    @api flexipageRegionWidth;
    @track categories = [];
    @track wrapperList = [];
    @track uiWrappers = [];
    @track touchpoint="";
    @track touchpointDate;
    @track touchpointNotes;
    @track touchpointInteraction="";

    error;
    @track _selected = [];
    @track step1 = true;
    @track step2 = false;
    @track step3 = false;
    @track step4 = false;
    statusOptions;
    outcomeOptions;
    competitorsOptions;
    touchpointOptions;
    sentimentOptions;
    touchpointInteractionOptions;

    tableColumns = [
        { label: 'Category', fieldName: 'category', type: 'text' },
        { label: 'Reason', fieldName: 'reason',type: 'text' },
        { label: 'Outcome', fieldName: 'outcome', type: 'text' },
        { label: 'Status', fieldName: 'status', type: 'text' },
        { label: 'Competitor', fieldName: 'competitors', type: 'text' },
        { label: 'Sentiment', fieldName: 'sentiment', type: 'text' }
    ];

    @wire(getObjectInfo, { objectApiName: MFE_OBJECT })
    mfeMetadata;

    @wire(getObjectInfo, { objectApiName: MT_OBJECT })
    mtMetadata;

    @wire(getPicklistValues,{recordTypeId: '$mfeMetadata.data.defaultRecordTypeId',fieldApiName: STATUS_FIELD})
    statusPicklistValues({ data, error }){
        if(data){
            this.statusOptions = data.values.map(plValue => {
                return {
                    label: plValue.label,
                    value: plValue.value
                };
            });
        }else if(error){
            console.log('Exception:::' + error);
        }
    }

    @wire(getPicklistValues,{recordTypeId: '$mfeMetadata.data.defaultRecordTypeId',fieldApiName: OUTCOME_FIELD})
    outcomePicklistValues({ data, error }){
        if(data){
            this.outcomeOptions = data.values.map(plValue => {
                return {
                    label: plValue.label,
                    value: plValue.value
                };
            });
        }else if(error){
            console.log('Exception:::' + error);
        }
    }

    @wire(getPicklistValues,{recordTypeId: '$mfeMetadata.data.defaultRecordTypeId',fieldApiName: COMPETITORS_FIELD})
    competitorsPicklistValues({ data, error }){
        if(data){
            this.competitorsOptions = data.values.map(plValue => {
                return {
                    label: plValue.label,
                    value: plValue.value
                };
            });
        }else if(error){
            console.log('Exception:::' + error);
        }
    }

    @wire(getPicklistValues,{recordTypeId: '$mtMetadata.data.defaultRecordTypeId',fieldApiName: TOUCHPOINT_FIELD})
    touchpointPicklistValues({ data, error }){
        if(data){
            this.touchpointOptions = data.values.map(plValue => {
                return {
                    label: plValue.label,
                    value: plValue.value
                };
            });
        }else if(error){
            console.log('Exception:::' + error);
        }
    }

    @wire(getPicklistValues,{recordTypeId: '$mfeMetadata.data.defaultRecordTypeId',fieldApiName: SENTIMENT_FIELD})
    sentimentPicklistValues({ data, error }){
        if(data){
            this.sentimentOptions = data.values.map(plValue => {
                return {
                    label: plValue.label,
                    value: plValue.value
                };
            });
        }else if(error){
            console.log('Exception:::' + error);
        }
    }

    @wire(getPicklistValues,{recordTypeId: '$mtMetadata.data.defaultRecordTypeId',fieldApiName: TOUCHPOINT_INTERACTION_FIELD})
    touchpointInteractionPicklistValues({ data, error }){
        if(data){
            this.touchpointInteractionOptions = data.values.map(plValue => {
                return {
                    label: plValue.label,
                    value: plValue.value
                };
            });
        }else if(error){
            console.log('Exception:::' + error);
        }
    }

    @wire(getCategories)
    wiredCategories({ error, data }){
        if (data) {
            this.error = undefined;
            data.forEach(category => {
                this.categories.push({label:category.Name, value:category.Id});
            });
        }else if (error) {
            this.error = error;
            this.contacts = undefined;
        }
    }

    get selected() {
        return this._selected.length ? this._selected : 'none';
    }

    handleChange(e) {
        this._selected = e.detail.value;
    }
    touchpointChange(event){
        this.touchpoint= event.detail.value;
    }
    touchpointDateChange(event){
        this.touchpointDate= event.detail.value;
    }
    touchpointNotesChange(event){
        this.touchpointNotes= event.detail.value;
    }
    touchpointInteractionChange(event){
        this.touchpointInteraction= event.detail.value;
    }

    opportunityChange(event){
        this.uiWrappers[event.target.dataset.index].selectedOppty = event.target.value;
    }
    reasonChange(event){
        this.uiWrappers[event.target.dataset.index].selectedReason = event.detail.value;
        this.uiWrappers[event.target.dataset.index].reason = event.target.options.find(opt => opt.value === event.detail.value).label;
    }
    statusChange(event){
        this.uiWrappers[event.target.dataset.index].status = event.target.value;
    }
    outcomeChange(event){
        this.uiWrappers[event.target.dataset.index].outcome = event.target.value;
    }
    competitorsChange(event){
        this.uiWrappers[event.target.dataset.index].competitorSelected = event.detail.value;
        let selectedComp = event.detail.value;
        this.uiWrappers[event.target.dataset.index].competitors = selectedComp.join(';');
    }

    sentimentChange(event){
        this.uiWrappers[event.target.dataset.index].sentiment = event.target.value;
    }
    notesChange(event){
        this.uiWrappers[event.target.dataset.index].notes = event.target.value;

    }
    nextstepsChange(event){
        this.uiWrappers[event.target.dataset.index].nextsteps = event.target.value;

    }

    getCategoryReason(event) {

       if(this._selected.length == 0 || this.touchpoint === "" || !this.touchpointDate){
            this.error = 'Please select/enter value for required fields marked with (*)';
            return 0;
        }
        this.error = undefined;
        this.step1 = false;
        this.step2 = true;

        getWrapperList({ categoryIds: this._selected, recId: this.recId, objectName: this.objectName})
        .then((result) => {
            this.wrapperList = result;
            this.error = undefined;

            this.wrapperList.forEach(wrap => {
                this.uiWrappers.push(
                    {   category:wrap.category,
                        reasons:wrap.reasons,
                        keyValue:wrap.keyValue,
                        selectedReason:null,
                        status:null,
                        outcome:null,
                        competitorSelected:null,
                        competitors:null,
                       // touchpoint:null,
                        sentiment:null,
                        notes:null,
                        nextsteps:null,
                        reason:null,
                        opportunities:wrap.opportunities,
                        selectedOppty:null
                    }
                );

            });
        })
        .catch((error) => {
            this.error = error;
            this.contacts = undefined;
            console.log(this.error);
        });

    }

    showTable(event){

        for(let index=0;index<this.uiWrappers.length;index++){
            if( this.uiWrappers[index].selectedReason == null || this.uiWrappers[index].selectedReason === "" ||
                this.uiWrappers[index].status == null || this.uiWrappers[index].status === "" ||
                this.uiWrappers[index].outcome == null || this.uiWrappers[index].outcome === "" ||
                this.uiWrappers[index].sentiment == null || this.uiWrappers[index].sentiment === ""){

                this.error = 'Please select/enter value for required fields marked with (*)';
                return 0;
            }
        }
        this.error = undefined;
        this.step2 = false;
        this.step3 = true;
    }

    confirm(event){
        this.step3 = false;
        this.step4 = true;

        createRecords({ wrapperList: this.wrapperList,updatedWrapperList:this.uiWrappers, touchPoint:this.touchpoint,touchpointDate:this.touchpointDate,touchpointNotes:this.touchpointNotes,touchpointInteraction:this.touchpointInteraction})
        .then((result) => {

        })
        .catch((error) => {
            this.error = error;
            this.contacts = undefined;
            console.log(this.error);
        });

    }

    gotoStep1(event){
    //    this.step1 = true;
    //    this.step2 = false;
    }
    gotoStep2(event){
        this.step2 = true;
        this.step3 = false;
    }
}