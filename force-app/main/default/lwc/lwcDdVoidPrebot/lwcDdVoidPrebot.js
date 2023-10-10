import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { updateRecord } from 'lightning/uiRecordApi';

import OPPORTUNITY_ID_FIELD from '@salesforce/schema/Opportunity.Id';
import OPPORTUNITY_STAGENAME_FIELD from '@salesforce/schema/Opportunity.StageName';
import QUOTE_ID_FIELD from '@salesforce/schema/SBQQ__Quote__c.Id';
import QUOTE_STATUS_FIELD from '@salesforce/schema/SBQQ__Quote__c.SBQQ__Status__c';

import callOuttoTray from '@salesforce/apex/CDdVoidPrebotController.callOuttoTray';
import recallApprovalQuote from '@salesforce/apex/CDdVoidPrebotController.recallApprovalQuote';
import getOpportunity from '@salesforce/apex/CDdVoidPrebotController.getOpportunity';
import getSetTimeIntervalValues from '@salesforce/apex/CDdVoidPrebotController.getSetTimeIntervalValues';

import prebotLinkRemoveWaitingMessage from '@salesforce/label/c.Prebot_Link_Remove_Waiting_Message';
import prebotQuoteWaitingtoRecallApprovalMessage from '@salesforce/label/c.Prebot_Quote_Waiting_to_Recall_Approval_Message';
import prebotTimeoutMessage from '@salesforce/label/c.Prebot_Timeout_Message';
import errorMessageforTrayFailure from '@salesforce/label/c.Prebot_Error_Message_for_Tray_Failure';
import prebotQuoteStatusisBeingUpdatedtoDraftMessage from '@salesforce/label/c.Prebot_Quote_Status_is_Being_Updated_to_Draft_Message';
import prebotQuoteOpportunityStageisbeingUpdatedMessage from '@salesforce/label/c.Prebot_Quote_Opportunity_Stage_is_being_Updated_Message';
import prebotVoidLinkSuccessMessage from '@salesforce/label/c.Prebot_Void_Link_Success_Message';
import prebotTimerMessage from '@salesforce/label/c.Prebot_Timer_Message';

const QUOTEFIELDS = ['SBQQ__Quote__c.Name', 'SBQQ__Quote__c.DD_Id_s__c', 'SBQQ__Quote__c.SBQQ__Opportunity2__c'];

export default class LwcDdVoidPrebot extends LightningElement {
    @api recordId;
    opportunityId;
    messageToDisplay;
    isLoading = false;
    isRecursive = false;
    setTimeInterval;
    timer = 0;
    timeIntervalInstance;
    showTimer = false;
    waitingTime;
    timeIntervel;
    prebotTimerMessage = prebotTimerMessage;

    connectedCallback(){
        getSetTimeIntervalValues()
            .then((result) => {
                if (result) {
                    this.timer = result['Prebot_Total_Waiting_Time_Interval_Sec'];
                    this.waitingTime = result['Prebot_Total_Waiting_Time_Interval_Sec']*1000;
                    this.timeIntervel = result['Prebot_Time_Interval_Sec']*1000;
                }
            })
            .catch((error) => {
                this.isLoading = false;
                this.messageToDisplay = error.body.message;
                console.log(error);
            });
    }

    @wire(getRecord, { recordId: '$recordId', fields: QUOTEFIELDS })
    quote({ error, data }) {
        if (data) {
            this.isLoading = true;
            this.opportunityId = data.fields.SBQQ__Opportunity2__c.value;
            if(!this.isRecursive){
                this.isRecursive = true;
                this.trayCallout();
            }
        } else if (error) {
            this.isLoading = false;
            console.log(error);
            let message = '';
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
            this.messageToDisplay = message;
        }
    }

    recallApprovalQuote(){
        recallApprovalQuote({ recordId: this.recordId})
            .then((result) => {
                if(result){
                    this.messageToDisplay = prebotQuoteStatusisBeingUpdatedtoDraftMessage;
                    this.updateQuote();
                }
            })
            .catch((error) => {
                this.isLoading = false;
                this.messageToDisplay = error.body.message;
                console.log(error);
            });
    }
    updateQuote(){
        const fields = {};
        fields[QUOTE_ID_FIELD.fieldApiName] = this.recordId;
        fields[QUOTE_STATUS_FIELD.fieldApiName] = "Draft";

        const recordInput = { fields };

        updateRecord(recordInput)
            .then(() => {
                this.messageToDisplay = prebotQuoteOpportunityStageisbeingUpdatedMessage;
                this.updateOpportunity();
            })
            .catch(error => {
                console.log(error);
                this.isLoading = false;
                this.messageToDisplay = error.body.message;
            });
    }

    updateOpportunity(){
        const fields = {};
        fields[OPPORTUNITY_ID_FIELD.fieldApiName] = this.opportunityId;
        fields[OPPORTUNITY_STAGENAME_FIELD.fieldApiName] = "Ready for Signature";

        const recordInput = { fields };

        updateRecord(recordInput)
            .then(() => {
                this.isLoading = false;
                this.messageToDisplay = prebotVoidLinkSuccessMessage;
            })
            .catch(error => {
                this.isLoading = false;
                this.messageToDisplay = error.body.message;
            });
    }

    trayCallout(){
        this.isLoading = true;
        callOuttoTray({ recordId: this.recordId})
            .then((result) => {
                if(result){
                    this.messageToDisplay = prebotLinkRemoveWaitingMessage;
                    var clearIntervalTime = 0;
                    this.showTimer = true;
                    this.timeIntervalInstance = setInterval(() => {
                        this.timer = this.timer - 1;
                    }, 1000);
                    this.setTimeInterval = setInterval(() => {
                        getOpportunity({ opportunityId: this.opportunityId})
                        .then((result) => {
                            var isLinkRemoved = false;
                            if(!result.Prebot_Link__c){
                                this.showTimer = false;
                                clearInterval(this.setTimeInterval);
                                clearInterval(this.timeIntervalInstance);
                                this.messageToDisplay = prebotQuoteWaitingtoRecallApprovalMessage;
                                isLinkRemoved = true;
                                this.recallApprovalQuote();
                            } else if(result.Prebot_Error__c){
                                this.isLoading = false;
                                this.messageToDisplay = result.Prebot_Error__c;
                                this.showTimer = false;
                                isLinkRemoved = true;
                                clearInterval(this.setTimeInterval);
                                clearInterval(this.timeIntervalInstance);
                            }
                            clearIntervalTime = clearIntervalTime + this.timeIntervel;
                            if(clearIntervalTime >= this.waitingTime && !isLinkRemoved){
                                this.isLoading = false;
                                this.messageToDisplay = prebotTimeoutMessage;
                                this.showTimer = false;
                                clearInterval(this.setTimeInterval);
                                clearInterval(this.timeIntervalInstance);
                            }
                        })
                        .catch((error) => {
                            console.log(error);
                            this.showTimer = false;
                            this.isLoading = false;
                            this.messageToDisplay = error.body.message;
                            clearInterval(this.setTimeIntervals);
                            clearInterval(this.timeIntervalInstance);
                        });
                    }, this.timeIntervel);
                } else{
                    this.isLoading = false;
                    this.messageToDisplay = errorMessageforTrayFailure;
                }
            })
            .catch((error) => {
                this.isLoading = false;
                this.showTimer = false;
                this.messageToDisplay = errorMessageforTrayFailure;
                console.log(error);
            });
    }

    disconnectedCallback(){
        clearInterval(this.setTimeInterval);
        clearInterval(this.timeIntervalInstance);
    }
}