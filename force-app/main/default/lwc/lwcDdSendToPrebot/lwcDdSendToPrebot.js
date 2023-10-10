import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import isBbotSeller from '@salesforce/customPermission/Prebot_Buttons';

import getSetTimeIntervalValues from '@salesforce/apex/CDdSendToPrebotController.getSetTimeIntervalValues';
import getOpportunity from '@salesforce/apex/CDdSendToPrebotController.getOpportunity';
import callOuttoTray from '@salesforce/apex/CDdSendToPrebotController.callOuttoTray';

import SendToPrebotErrorMessage from '@salesforce/label/c.Prebot_Quote_is_Ineligible_to_Send_to_Prebot_Error_Message';
import prebotLinkWaitingMessage from '@salesforce/label/c.Prebot_Link_Generate_Waiting_Message';
import errorMessageforTrayFailure from '@salesforce/label/c.Prebot_Error_Message_for_Tray_Failure';
import prebotTimeoutMessage from '@salesforce/label/c.Prebot_Timeout_Message';
import prebotGenerateLinkSuccessMessage from '@salesforce/label/c.Prebot_Generate_Link_Success_Message';
import prebotTimerMessage from '@salesforce/label/c.Prebot_Timer_Message';

const QUOTEFIELDS = ['SBQQ__Quote__c.Name', 'SBQQ__Quote__c.DD_Id_s__c', 'SBQQ__Quote__c.SBQQ__Opportunity2__c'];
const OPPORTUNITYFIELDS = ['Opportunity.Name', 'Opportunity.Prebot_Link__c', 'Opportunity.Prebot_Error__c'];

export default class LwcDdSendToPrebot extends LightningElement {
    @api recordId;
    opportunityId;
    prebotLink;
    isLoading = false;
    setTimeInterval;
    messageToDisplay;
    timer = 0;
    timeIntervalInstance;
    showTimer = false;
    waitingTime;
    timeIntervel;
    isRetryTrayCallout = false;
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
                console.log(error);
                this.messageToDisplay = error.body.message;
            });
    }

    @wire(getRecord, { recordId: '$recordId', fields: QUOTEFIELDS })
    quote({ error, data }) {
        if (data) {
            if(isBbotSeller){
                if(data.fields.DD_Id_s__c.value != null){
                    var ddId = data.fields.DD_Id_s__c.value.substring(0, data.fields.DD_Id_s__c.value.length - 1);
                    var ddIds = ddId.split(", ");
                    var filteredBBOTList = ddIds.filter(item => item.includes("BBOT"));
                    if(filteredBBOTList.length != ddIds.length){
                        this.isLoading = false;
                        this.messageToDisplay = SendToPrebotErrorMessage;
                    } else{
                        this.isLoading = true;
                        this.opportunityId = data.fields.SBQQ__Opportunity2__c.value;
                    }
                } else{
                    this.isLoading = false;
                    this.messageToDisplay = SendToPrebotErrorMessage;
                }
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

    @wire(getRecord, { recordId: '$opportunityId', fields: OPPORTUNITYFIELDS })
    opportunity({ error, data }) {
        if (data) {
            if(data.fields.Prebot_Link__c.value){
                this.isLoading = false;
                this.prebotLink = data.fields.Prebot_Link__c.value;
                this.messageToDisplay = prebotGenerateLinkSuccessMessage;
            } else if(data.fields.Prebot_Error__c.value){
                this.isLoading = false;
                this.isRetryTrayCallout = true;
                this.messageToDisplay = data.fields.Prebot_Error__c.value;
            }else{
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

    trayCallout(){
        this.isLoading = true;
        this.isRetryTrayCallout = false;
        var newOpportunity = null;
        var oldOpportunity = {};
        var skipforFirstTime = true;
        callOuttoTray({ recordId: this.recordId})
            .then((result) => {
                if(result){
                    this.messageToDisplay = prebotLinkWaitingMessage;
                    var clearIntervalTime = 0;
                    this.showTimer = true;
                    this.timeIntervalInstance = setInterval(() => {
                        this.timer = this.timer - 1;
                    }, 1000);
                    this.setTimeInterval = setInterval(() => {
                        getOpportunity({ opportunityId: this.opportunityId})
                        .then((result) => {
                            if(newOpportunity != null){
                                oldOpportunity = newOpportunity;
                            }
                            newOpportunity = result;
                            var isLinkGenerated = false;
                            if(result.Prebot_Link__c){
                                this.isLoading = false;
                                this.prebotLink = result.Prebot_Link__c;
                                this.messageToDisplay = prebotGenerateLinkSuccessMessage;
                                this.showTimer = false;
                                isLinkGenerated = true;
                                clearInterval(this.setTimeInterval);
                                clearInterval(this.timeIntervalInstance);
                            }
                            if(oldOpportunity.Prebot_Error__c != result.Prebot_Error__c && result.Prebot_Error__c && !skipforFirstTime){
                                this.isLoading = false;
                                this.messageToDisplay = result.Prebot_Error__c;
                                this.showTimer = false;
                                isLinkGenerated = true;
                                clearInterval(this.setTimeInterval);
                                clearInterval(this.timeIntervalInstance);
                            }
                            skipforFirstTime = false;
                            clearIntervalTime = clearIntervalTime + this.timeIntervel;
                            if(clearIntervalTime >= this.waitingTime && !isLinkGenerated){
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
                this.messageToDisplay = error.body.message;
                console.log(error);
            });
    }

    disconnectedCallback(){
        clearInterval(this.setTimeInterval);
        clearInterval(this.timeIntervalInstance);
    }
}