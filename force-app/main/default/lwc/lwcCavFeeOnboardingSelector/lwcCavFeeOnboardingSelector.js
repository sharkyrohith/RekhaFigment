/**
 * Created by Jeremy S. Johnson, Perficient Inc., on 7/1/2020.
 *
 * Implements: BZAP-8198 Create Lightning Component for Caviar / Online Ordering STN
 */

import { LightningElement, track, api } from "lwc";
import getProgramsAndFees from "@salesforce/apex/CDdFeeOnboardingController.getProgramsAndFees";
import createProgramsAndFees from "@salesforce/apex/CDdFeeOnboardingController.createProgramsAndFees";

// Import custom labels
import errorMessage from '@salesforce/label/c.DDS2N_FeeOnboarding_Error_Message';
import successMessage from '@salesforce/label/c.DDS2N_FeeOnboarding_Success_Message';
import errorTitle from '@salesforce/label/c.DDS2N_FeeOnboarding_Error';
import tableColumn1 from '@salesforce/label/c.DDS2N_FeeOnboarding_Column_2';
import tableColumn2 from '@salesforce/label/c.DDS2N_FeeOnboarding_Column_1';
import title from '@salesforce/label/c.DDS2N_Fee_Onboarding_Title';
import buttonText from '@salesforce/label/c.DDS2N_FeeOnboarding_Button'

export default class LwcCavFeeOnboardingSelector extends LightningElement {
    @api recordId;
    data = [];
    selectedRows = [];
    disableButton = false;
    hasRendered = false;

    label = {
        title, tableColumn1, tableColumn2, errorTitle, successMessage,
        errorMessage, buttonText
    }

    columns = [
        { type: "text", fieldName: "programLabel", label: this.label.tableColumn1, initialWidth: 250, },
        { type: "text", fieldName: "feeLabel", label: this.label.tableColumn2, initialWidth: 300, }, ];

    renderedCallback() {
        const that = this;
        if (!that.hasRendered) {
            that.hasRendered = true;
            that.toggleSpinner();

            getProgramsAndFees({ opportunityId : this.recordId })
                .then(programsAndFees => {
                    that.toggleSpinner();
                    if (programsAndFees.length === 0) {
                        that.showResult(this.label.errorTitle, null);
                        that.disableButton = true;

                    } else {
                        that.data = programsAndFees;
                        let selected = [];
                        for (let key in programsAndFees) {
                            selected.push(programsAndFees[key].feeId);
                        }
                        that.selectedRows = selected;
                    }
                })
                .catch(error => {
                    that.toggleSpinner();
                    that.showResult(error, false);
                })
        }
    }

    createProgramsAndFees() {
        const that = this;
        const table = this.template.querySelector("lightning-datatable");
        this.toggleSpinner();
        this.disableButton = true;

        createProgramsAndFees({ opportunityId : this.recordId, feeIds : table.getSelectedRows().map(a => a.feeId) })
            .then(response => {
                that.toggleSpinner();
                if (response.messages.length > 0) {
                    that.showResult(that.label.successMessage + ":<br>" + response.messages.join("<br>"), true);
                }

                if (response.errors.length > 0) {
                    that.showResult(that.label.errorMessage  + ":<br>" + response.errors.join("<br>"), false);
                }
            })
            .catch(error => {
                that.toggleSpinner();
                that.showResult(error, false);
            })
    }

    toggleSpinner() {
        this.template.querySelector('[data-id="spinner"]').classList.toggle("slds-hidden");
    }

    showResult(message, isSuccess) {
        const resultDiv = this.template.querySelector('[data-id="resultDiv"]');
        const errorDiv = this.template.querySelector('[data-id="errorDiv"]');

        if (isSuccess === null) {
            //do nothing
        } else if (isSuccess) {
            resultDiv.innerHTML = message;
            resultDiv.classList.remove("slds-theme_error");
            resultDiv.classList.add("slds-theme_success");
        } else {
            errorDiv.innerHTML = this.getStringErrorMessage(message);
            errorDiv.classList.remove("slds-theme_success");
            errorDiv.classList.add("slds-theme_error");
        }
    }

    getStringErrorMessage(error) {
        if (typeof error === 'object' && error !== null) {
            if ('body' in error && 'message' in error.body) {
                return error.body.message;
            }
        }
        return error;
    }
}