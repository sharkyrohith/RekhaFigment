import { LightningElement, track, api, wire } from 'lwc';
import getOpportunities from '@salesforce/apex/PSBulkSendController.getOpportunities';
import getContractOptions from '@salesforce/apex/PSBulkSendController.getBulkSendcontracts';
import psLogo from '@salesforce/contentAssetUrl/unknown_content_asset';
import processRequest from '@salesforce/apex/PSBulkSendController.processRequest';

// Send limit for initial launch of PactSafe bulk send.
const sendLimit = 1000;

export default class PactSafeBulkSend extends LightningElement {
  hasRendered = false;
  @track errorMessage;
  psLogoUrl = psLogo;

  @track loaded = false;
  @track errorOccurred = false;

  @track optyData = [];
  @track optyCountAvailable = false;
  @track optyCount = 0;
  @track parentOpty = '';

  @track selectedContractId = null;
  @track selectedContractExpires = false;
  @track selectedContractAutomatedReminders = true;

  @track submitClickedOnce = false;
  @track submitIsDisabled = false;
  @track submitButtonLabel = 'Send Contracts';
  @track submitButtonVariant = 'brand';

  loadedContracts = {};

  @track sentToPactSafe = false;

  @api opportunityIds;

  @wire(getContractOptions)
  contractOptionsData;

  renderedCallback() {
    if (!this.hasRendered) {
      this.hasRendered = true;
      this.submitIsDisabled = true;
      getOpportunities({oppIds: this.opportunityIds })
        .then(result => {
          this.loaded = true;
          if (result.length > 0) {
            if (result.length > sendLimit) throw new Error('Please select less than 1,000 opportunities for bulk sending.');
            this.optyData = result;
            this.optyCount = result.length;
            this.optyCountAvailable = true;
            this.parentOpty = result[0].Parent_Opportunity__r.Name;
          } else {
            throw new Error('Unable to find any opportunities');
          }
        })
        .catch(err => {
          this.loaded = true;
          this.errorOccurred = true;
          this.errorMessage = err;
        });
    }
  }

  get contractOptions() {
    var returnOptions = [];
    if(this.contractOptionsData.data) {
      this.contractOptionsData.data.forEach(ele => {
        const contractOptionsData = {
          name: ele.Label,
          expires: ele.Auto_Expires__c,
          automatedReminders: ele.Automated_Reminders__c
        };
        let contractId = ele.Contract_ID__c;
        this.loadedContracts[contractId] = contractOptionsData;
        returnOptions.push({label:ele.Label, value:ele.Contract_ID__c});
      });
    }
    return returnOptions;
  }

  handleContractChange(event) {
      this.selectedContractId = event.detail.value;

      // Mark whether the contract should expire or not.
      if (this.loadedContracts) {
        this.selectedContractExpires = this.loadedContracts[event.detail.value].expires;
        this.selectedContractAutomatedReminders = this.loadedContracts[event.detail.value].automatedReminders;
      }

      // Ensure a contract ID exists to enable the send button.
      if (this.selectedContractId) {
        this.submitIsDisabled = false;
      }
  }

  handleSubmitClick() {
    // Present verification of intention to send upon first submit click.
    if (!this.submitClickedOnce) {
      this.submitClickedOnce = true;
      this.submitButtonLabel = "Are you sure? Click again to send.";
      return;
    }
    this.submitIsDisabled = true;
    this.submitButtonLabel = 'Sending Contracts...';
    processRequest({ oppIds: this.opportunityIds,
      contractIds: this.selectedContractId,
      selectedContractExpires: this.selectedContractExpires,
      automatedRequestReminders: this.selectedContractAutomatedReminders })
      .then(response => {
        var jsonResponse = JSON.parse(response);
        if (jsonResponse.success) {
          this.submitButtonVariant = 'success';
          this.submitButtonLabel = 'Sent to PactSafe';
          this.sentToPactSafe = true;
        } else {
          this.errorOccurred = true;
          this.errorMessage = JSON.stringify(jsonResponse.message);
        }
      })
      .catch(err => {
        this.errorOccurred = true;
        this.errorMessage = JSON.stringify(err);
      });
  }
}