import { LightningElement, wire, api, track } from 'lwc';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';

const DEFAULT_HELP_TEXT = "Please select a value.";
const PADDING_PREFIX = "slds-p-around_";
const DEFAULT_PADDING = PADDING_PREFIX + "large";

// This is a picklist component that is filtered by values available for a Record Type
// Object API Name, Field API Name, and Record Type ID are parameters, and this
// component renders a dropdown with fields available to the Record Type for the picklist.
export default class LwcDdPicklistForRecordType extends LightningElement {

    @api objectApiName;
    @api fieldApiName;
    @track fieldLabel;
    @api recordTypeId;
    @api value;
    @api isFieldRequired;
    @api userDefinedHelpText;
    @track options;
    @track fieldLoaded = false;
    fieldPaddingClass = this.fieldPadding || DEFAULT_PADDING;
    apiObjectAndFieldName;
    fieldHelpText;

    @wire(getObjectInfo, { objectApiName: '$objectApiName' })
    getObjectData({ error, data }) {
        if (data) {
            // Use the default RT if one is not specified for some reason
            if (this.recordTypeId == null) {
                this.recordTypeId = data.defaultRecordTypeId;
            }
            
            const fieldAttributes = data.fields[this.fieldApiName];

            this.apiObjectAndFieldName = this.objectApiName + '.' + this.fieldApiName;
            this.fieldLabel = fieldAttributes.label;
            this.fieldLoaded = true;
            this.setFieldHelpText(fieldAttributes.inlineHelpText);
           
        } else if (error) {
            this.showError(error);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: '$apiObjectAndFieldName' })
    getPicklistValues({ error, data }) {
        if (data) {
            // Map picklist values
            this.options = data.values.map(plValue => {
                return {
                    label: plValue.label,
                    value: plValue.value
                };
            });

        } else if (error) {
            this.showError(error);
        }
    }

    // Sets the Help Text tooltip for the field 
    setFieldHelpText(helpTextFromObjectMetadata) {
        // Check if there was custom help text defined by the caller (such as flow definition)
        if(this.userDefinedHelpText) {
            this.fieldHelpText = this.userDefinedHelpText;
        // Otherwise check if there is help text in the field definition from the object metadata
        } else if(helpTextFromObjectMetadata) {
            this.fieldHelpText = helpTextFromObjectMetadata;
        // If neither of those exist, then use our default text from this component
        } else {
            this.fieldHelpText = DEFAULT_HELP_TEXT;
        }        
    }

    handleChange(event) {
        this.value = event.detail.value;
    }

    showError(error) {
        console.error("LWC Error - lwcDdPicklistForRecordType: ");
        console.error(error);
    }

    set fieldPadding(value) {
        this.fieldPaddingClass = PADDING_PREFIX + value;
    }

    @api
    get fieldPadding() {
        return this.fieldPaddingClass;
    }

    // Validates field input when this is implemented via flow
    @api
    validate() {
        // If the field was not set as required OR if we have a value, we're good
        if(!this.isFieldRequired || this.value) {
            return { 
                isValid : true 
            };

        // This means the field was required AND there's no value. 
        } else {
            return {
                isValid: false,
                errorMessage: "Please select a value."
            };
        }
    }
}