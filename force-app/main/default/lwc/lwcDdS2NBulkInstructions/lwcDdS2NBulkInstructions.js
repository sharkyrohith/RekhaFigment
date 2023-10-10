import { wire, LightningElement, api } from 'lwc';
import getHelpText from "@salesforce/apex/CDdUploaderController.helpText";

// Import custom labels
import titleHeader from '@salesforce/label/c.DDS2N_BulkInstructions_Title';
import accordionHeader from '@salesforce/label/c.DDS2N_BulkInstructions_Accordion_Title';
import heading from '@salesforce/label/c.DDS2N_BulkInstructions_Heading';
import process from '@salesforce/label/c.DDS2N_BulkInstructions_Process';
import processStep1 from '@salesforce/label/c.DDS2N_BulkInstructions_Process_Step_1';
import processStep2 from '@salesforce/label/c.DDS2N_BulkInstructions_Process_Step_2';
import processStep3 from '@salesforce/label/c.DDS2N_BulkInstructions_Process_Step_3';
import processStep4 from '@salesforce/label/c.DDS2N_BulkInstructions_Process_Step_4';
import processStep5 from '@salesforce/label/c.DDS2N_BulkInstructions_Process_Step_5';
import processStep6 from '@salesforce/label/c.DDS2N_BulkInstructions_Process_Step_6';
import processPost1 from '@salesforce/label/c.DDS2N_BulkInstructions_Post_1';
import processPost2 from '@salesforce/label/c.DDS2N_BulkInstructions_Post_2';
import validations from '@salesforce/label/c.DDS2N_BulkInstructions_Validations';
import validationsPre from '@salesforce/label/c.DDS2N_BulkInstructions_Validations_Pre';
import validationsStep1 from '@salesforce/label/c.DDS2N_BulkInstructions_Validations_Step_1';
import validationsStep2 from '@salesforce/label/c.DDS2N_BulkInstructions_Validations_Step_2';
import validationsStep3 from '@salesforce/label/c.DDS2N_BulkInstructions_Validations_Step_3';
import validationsStep4 from '@salesforce/label/c.DDS2N_BulkInstructions_Validations_Step_4';
import validationsStep5 from '@salesforce/label/c.DDS2N_BulkInstructions_Validations_Step_5';
import validationsStep6 from '@salesforce/label/c.DDS2N_BulkInstructions_Validations_Step_6';
import validationsStep7 from '@salesforce/label/c.DDS2N_BulkInstructions_Validations_Step_7';
import importTitle from '@salesforce/label/c.DDS2N_BulkInstructions_Import';
import importPre from '@salesforce/label/c.DDS2N_BulkInstructions_Import_Pre';
import importPost from '@salesforce/label/c.DDS2N_BulkInstructions_Import_Post';
import supportedFields from '@salesforce/label/c.DDS2N_BulkInstructions_SupportedFields';
import commonIssues from '@salesforce/label/c.DDS2N_BulkInstructions_CommonIssues';
import commonIssuesException from '@salesforce/label/c.DDS2N_BulkInstructions_CommonIssues_Exception';
import commonIssuesExceptionDesc from '@salesforce/label/c.DDS2N_BulkInstructions_CommonIssues_Exception_Desc';
import commonIssuesFLS from '@salesforce/label/c.DDS2N_BulkInstructions_CommonIssues_FLS';
import commonIssuesFLSDesc from '@salesforce/label/c.DDS2N_BulkInstructions_CommonIssues_FLS_Desc';
import commonIssuesFormula from '@salesforce/label/c.DDS2N_BulkInstructions_CommonIssues_Formula';
import commonIssuesFormulaDesc from '@salesforce/label/c.DDS2N_BulkInstructions_CommonIssues_Formula_Desc';
import commonIssuesObject from '@salesforce/label/c.DDS2N_BulkInstructions_CommonIssues_Object';
import commonIssuesObjectDesc from '@salesforce/label/c.DDS2N_BulkInstructions_CommonIssues_Object_Desc';
import commonIssuesInvalidId from '@salesforce/label/c.DDS2N_BulkInstructions_CommonIssues_InvalidId';
import commonIssuesInvalidIdDesc from '@salesforce/label/c.DDS2N_BulkInstructions_CommonIssues_InvalidId_Desc';
import commonIssuesNotSupported from '@salesforce/label/c.DDS2N_BulkInstructions_CommonIssues_NotSupported';
import commonIssuesNotSupportedDesc from '@salesforce/label/c.DDS2N_BulkInstructions_CommonIssues_NotSupported_Desc';
import commonIssuesMissingField from '@salesforce/label/c.DDS2N_BulkInstructions_CommonIssues_MissingField';
import commonIssuesMissingFieldDesc from '@salesforce/label/c.DDS2N_BulkInstructions_CommonIssues_MissingField_Desc';
import commonIssuesOpportunityWon from '@salesforce/label/c.DDS2N_BulkInstructions_CommonIssues_OpportunityWon';
import commonIssuesOpportunityWonDesc from '@salesforce/label/c.DDS2N_BulkInstructions_CommonIssues_OpportunityWon_Desc';
import commonIssuesConvertValue from '@salesforce/label/c.DDS2N_BulkInstructions_CommonIssues_ConvertValue';
import commonIssuesConvertValueDesc from '@salesforce/label/c.DDS2N_BulkInstructions_CommonIssues_ConvertValue_Desc';

const DELAY = 100;

export default class LwcDdS2NBulkInstructions extends LightningElement {
    activeSections=['A'];
    helpText;
    error;

    label = {
        titleHeader, accordionHeader, heading, process, processStep1,
        processStep2, processStep3, processStep4, processStep5, processStep6,
        processPost1, processPost2, validations, validationsPre, validationsStep1,
        validationsStep2, validationsStep3, validationsStep4, validationsStep5,
        validationsStep6, validationsStep7, importTitle, importPre, importPost,
        supportedFields, commonIssues, commonIssuesException, commonIssuesExceptionDesc,
        commonIssuesFLS, commonIssuesFLSDesc, commonIssuesFormula, commonIssuesFormulaDesc,
        commonIssuesObject, commonIssuesObjectDesc, commonIssuesInvalidId, 
        commonIssuesInvalidIdDesc, commonIssuesNotSupported, commonIssuesNotSupportedDesc,
        commonIssuesMissingField, commonIssuesMissingFieldDesc, commonIssuesOpportunityWon,
        commonIssuesOpportunityWonDesc, commonIssuesConvertValue, commonIssuesConvertValueDesc
    }

    constructor() {
        super();
        this.getHelpText();
    }

    getHelpText() {
        getHelpText()
            .then(result => {
                this.helpText = result;
            })
            .catch(error => {
                this.error = error;
            });
    }        

    @api 
    handleShowModal() {
        this.template.querySelector('c-lwc-dd-modal').showModal();
        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            let elem = this.template.querySelector('[data-id="helpText"]');
            elem.innerHTML = this.helpText;
            this.template.querySelector('.modalContent').scrollTop=0;
        }, DELAY);        
    }

    handleCloseBulkInstructions(event){
        event.preventDefault();
        event.stopPropagation();        
        const closedialog = new CustomEvent('closebulkinstructions');
        this.dispatchEvent(closedialog);        
    }    

}