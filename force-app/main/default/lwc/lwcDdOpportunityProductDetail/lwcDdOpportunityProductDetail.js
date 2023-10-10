/**
    @author: Dan Thoreson
    @date: 16-Sep-2022
    @description: View/Edit form for Product Details on Opportunity. This is used
                  to display a number of fields on the Product_Detail__c object 
                  related to the Opportunity. This component lives on the Opportunity
                  page, and its intended use is to track details related to Storefront.
**/
import { LightningElement, api, track } from "lwc";
import getProductDetailsForOpportunity from "@salesforce/apex/CDdOpportunityProductDetailController.getProductDetailsForOpportunity";
import upsertProductDetail from "@salesforce/apex/CDdOpportunityProductDetailController.upsertProductDetail";
import getProductDetailRecordTypeInfo from "@salesforce/apex/CDdOpportunityProductDetailController.getProductDetailRecordTypeInfo";

const FORM_ELEMENT_CLASS = " slds-form-element";
const ERROR_CLASS = " slds-has-error";

export default class LwcDdOpportunityProductDetail extends LightningElement {
    @api recordId;
    @track recordTypeId;
    recordType;
    productDetailsRecord;
    deckRank;

    dataLoaded = false;
    showSpinner = true;
    saving = false;
    implementationOwnedByDoorDash = false;
    showClickableUrl = false;

    implementationTypeClass = FORM_ELEMENT_CLASS;
    implementationOwnerClass = FORM_ELEMENT_CLASS;
    implementationSubOwnerClass = FORM_ELEMENT_CLASS;
    partnershipTypeClass = FORM_ELEMENT_CLASS;
    salesSegmentClass = FORM_ELEMENT_CLASS;
    countryClass = FORM_ELEMENT_CLASS;
    proposedActivationDateClass = FORM_ELEMENT_CLASS;

    componentErrorMsg;
    implementationTypeErrorMsg = "Please select an Implementation Type.";
    partnershipTypeErrorMsg = "Please select a Partnership Type.";
    implementationOwnerErrorMsg = "Please select an Implementation Owner.";
    implementationSubOwnerErrorMsg = "Please select a team.";
    salesSegmentErrorMsg = "Please select a Storefront Sales Segment.";
    countryErrorMsg = "Please select a Country.";
    proposedActivationDateErrorMsg = "The Storefront Proposed Date of Activation must be at least two weeks from today's date.";

    showMainComponentError = false;
    showImplementationTypeErrorMsg = false;
    showPartnershipTypeErrorMsg = false;
    showImplementationOwnerErrorMsg = false;
    showImplementationSubOwnerErrorMsg = false;
    showSalesSegmentErrorMsg = false;
    showCountryErrorMsg = false;
    showProposedActivationDateErrorMsg = false;

    countries = [
        {"value": "Australia", "label": "Australia"},
        {"value": "Canada", "label": "Canada"},
        {"value": "Japan", "label": "Japan"},
        {"value": "New Zealand", "label": "New Zealand"},
        {"value": "United States", "label": "United States"}
    ];

    connectedCallback() {
        this.loadRecordTypeInfo();
    }

    loadRecordTypeInfo() {
        getProductDetailRecordTypeInfo({ opportunityId : this.recordId})
            .then((result) => {          
                if(result) {
                    this.recordType = result
                    this.recordTypeId = this.recordType.Id;
                    this.loadData();
                } else {
                    throw "Record Type is not defined or accessible";
                }
            })
            .catch((error) => {
                this.showError(error, "Error loading Product Details");
            })
    }

    loadData() {
        getProductDetailsForOpportunity({ recordId : this.recordId })
            .then((result) => {
                this.productDetailsRecord = result;
                this.resetBlankFields();
                this.setDeckRank();

                this.showClickableUrl = !!this.productDetailsRecord.Mx_Website_Link__c;
                
                this.setIsOwnedByDoorDash();
                this.saving = false;
                this.showSpinner = false;
                this.dataLoaded = true;
            })
            .catch((error) => {
                this.showError(error, "Error loading Product Details");
            })
    }

    evaluateOwner(e) {
        this.implementationOwnerClass = FORM_ELEMENT_CLASS;
        this.showImplementationOwnerErrorMsg = false;        

        this.productDetailsRecord.Implementation_Owner__c = e.currentTarget.value;
        this.setIsOwnedByDoorDash();
    }

    changeType(e) {
        this.implementationTypeClass = FORM_ELEMENT_CLASS;
        this.showImplementationTypeErrorMsg = false;

        this.productDetailsRecord.Implementation_Type__c = e.currentTarget.value;
    }

    changeSubOwner(e) {
        this.implementationSubOwnerClass = FORM_ELEMENT_CLASS;
        this.showImplementationSubOwnerErrorMsg = false;        

        this.productDetailsRecord.DoorDash_Implementation_Owner__c = e.currentTarget.value;
    }

    changeWebsiteCreationNeeded(e) {
        this.implementationTypeClass = FORM_ELEMENT_CLASS;

        this.productDetailsRecord.Website_Creation_Needed__c = e.currentTarget.checked;
    }

    changePartnershipType(e) {
        this.partnershipTypeClass = FORM_ELEMENT_CLASS;
        this.showPartnershipTypeErrorMsg = false;

        this.productDetailsRecord.Partnership_Type__c = e.currentTarget.value;
    }

    changeSalesSegment(e) {
        this.salesSegmentClass = FORM_ELEMENT_CLASS;
        this.showSalesSegmentErrorMsg = false;
        this.productDetailsRecord.Storefront_Sales_Segment__c = e.currentTarget.value;
    }

    changeCountry(e) {
        this.countryClass = FORM_ELEMENT_CLASS;
        this.showCountryErrorMsg = false;
        
        this.productDetailsRecord.Billing_Country__c = e.currentTarget.value;
    }

    changeWebProvider(e) {
        this.productDetailsRecord.Web_Provider__c = e.currentTarget.value;
    }

    changeProposedActivationDate(e) {
        this.proposedActivationDateClass = FORM_ELEMENT_CLASS;
        this.showProposedActivationDateErrorMsg = false;

        if(e.currentTarget.value) {
            this.productDetailsRecord.Storefront_Proposed_Date_of_Activation__c = new Date(e.currentTarget.value);

            if(!this.proposedActivationDateIsValid()) {
                this.showProposedActivationDateErrorMsg = true;
                this.proposedActivationDateClass = this.getErrorClassForField();
            }
        } else {
            this.productDetailsRecord.Storefront_Proposed_Date_of_Activation__c = null;
        }
    }

    changeWebsiteLink(e) {
        this.productDetailsRecord.Mx_Website_Link__c = e.currentTarget.value;
    }

    editWebsiteLink() {
        this.showClickableUrl = !this.showClickableUrl;
    }

    setIsOwnedByDoorDash() {
        this.implementationOwnedByDoorDash = this.productDetailsRecord.Implementation_Owner__c 
                                                && this.productDetailsRecord.Implementation_Owner__c.toUpperCase() === "DOORDASH";
        
        // Clear out the dependent field ("DoorDash_Implementation_Owner") when the controlling field ("Implementation_Owner") is nulled
        if(!this.implementationOwnedByDoorDash) {
            this.productDetailsRecord.DoorDash_Implementation_Owner__c = null;
        }
    }

    // Validations:
        // - Implementation Type should be required
        // - Implementation Owner should be required
        // - Require "DD Implementation Owner" if "Implementation Owner" is DD
        // Partnership Type is required
    isValid() {
        let formIsValid = true;

        if(!this.productDetailsRecord.Implementation_Type__c) {
            this.showImplementationTypeErrorMsg = true;
            this.implementationTypeClass = this.getErrorClassForField();
            formIsValid = false;
        }

        if(!this.productDetailsRecord.Partnership_Type__c) {
            this.showPartnershipTypeErrorMsg = true;
            this.partnershipTypeClass = this.getErrorClassForField();
            formIsValid = false;
        }

        if(!this.productDetailsRecord.Billing_Country__c) {
            this.showCountryErrorMsg = true;
            this.countryClass = this.getErrorClassForField();
            formIsValid = false;
        }

        if(!this.productDetailsRecord.Storefront_Sales_Segment__c) {
            this.showSalesSegmentErrorMsg = true;
            this.salesSegmentClass = this.getErrorClassForField();
            formIsValid = false;
        }

        if(!this.productDetailsRecord.Implementation_Owner__c) {
            this.showImplementationOwnerErrorMsg = true;
            this.implementationOwnerClass = this.getErrorClassForField();
            formIsValid = false;

        } else if(this.productDetailsRecord.Implementation_Owner__c.toUpperCase() === "DOORDASH" && !this.productDetailsRecord.DoorDash_Implementation_Owner__c) {
            this.showImplementationSubOwnerErrorMsg = true;
            this.implementationSubOwnerClass = this.getErrorClassForField();
            formIsValid = false;
        }

        if(!this.proposedActivationDateIsValid()) {
            this.showProposedActivationDateErrorMsg = true;
            this.proposedActivationDateClass = this.getErrorClassForField();
            formIsValid = false;
        }

        return formIsValid;
    }

    proposedActivationDateIsValid() {
        // BASD-48770 - TEMPORARILY REMOVING VALIDATION - 11 MAY 2023, DAN THORESON
        // Our ultimate goal is to only require this two-week minimum for Bundle Mx (Storefront & Marketplace).
        // However, we are temporarily disabling this validation to unblock Sales, per BASD-48770.
        // Commenting this code out for now so we can bring it back and repurpose it to consider Bundle Mx.

        // if(this.productDetailsRecord && this.productDetailsRecord.Storefront_Proposed_Date_of_Activation__c) {
        //     let twoWeeksFromNow = new Date();
        //     twoWeeksFromNow.setDate(twoWeeksFromNow.getDate() + 14);

        //     let selectedDate = new Date(this.productDetailsRecord.Storefront_Proposed_Date_of_Activation__c);

        //     return selectedDate > twoWeeksFromNow;
        // }

        return true;
    }

    saveProductDetails(e) {
        this.componentErrorMsg = null;
        this.showMainComponentError = false;

        if(this.isValid()) {
            this.saving = true;

            // CALL SAVE
            upsertProductDetail({ opportunityId : this.recordId, details : this.productDetailsRecord })
                .then((result) => {
                    this.productDetailsRecord = result;

                    this.saving = false;
                    this.showClickableUrl = true;
                })
                .catch((error) => {
                    this.showError(error, "Error saving Product Details");
                })
        }
    }

    cancelEdits(e) {
        this.componentErrorMsg = null;
        this.showMainComponentError = false;
        this.saving = true;

        this.loadData();
    }

    setDeckRank() {
        if(this.productDetailsRecord && this.productDetailsRecord.Opportunity__r) {
            this.deckRank = this.productDetailsRecord.Opportunity__r.DRN__c || this.productDetailsRecord.Opportunity__r.Parent_Account_Deck_Rank__c;
        }

        if(!this.deckRank) {
            this.deckRank = "None";
        }
    }

    resetBlankFields() {
        // Reset dropdown fields if missing
        if(!this.productDetailsRecord.Web_Provider__c) {
            this.productDetailsRecord.Web_Provider__c = null;
        }

        if(!this.productDetailsRecord.Implementation_Owner__c) {
            this.productDetailsRecord.Implementation_Owner__c = null;
        }

        if(!this.productDetailsRecord.DoorDash_Implementation_Owner__c) {
            this.productDetailsRecord.DoorDash_Implementation_Owner__c = null;
        }

        if(!this.productDetailsRecord.Implementation_Type__c) {
            this.productDetailsRecord.Implementation_Type__c = null;
        }

        if(!this.productDetailsRecord.Website_Creation_Needed__c) {
            this.productDetailsRecord.Website_Creation_Needed__c = null;
        }

        if(!this.productDetailsRecord.Partnership_Type__c) {
            this.productDetailsRecord.Partnership_Type__c = null;
        }

        if(!this.productDetailsRecord.Storefront_Sales_Segment__c) {
            this.productDetailsRecord.Storefront_Sales_Segment__c = null;
        }

        if(!this.productDetailsRecord.Billing_Country__c) {
            this.productDetailsRecord.Billing_Country__c = (this.country) ? this.country : null;
        }

        if(!this.productDetailsRecord.Web_Provider__c) {
            this.productDetailsRecord.Web_Provider__c = null;
        }

        if(!this.productDetailsRecord.Storefront_Proposed_Date_of_Activation__c) {
            this.productDetailsRecord.Storefront_Proposed_Date_of_Activation__c = null;
        }        
    }

    showError(e, errorPrefix) {
        let errorString;

        if(errorPrefix) {
            errorString = e && e.message ? `${errorPrefix}: ${e.message}` : `${errorPrefix}`;
        } else {
            errorString = e && e.message ? `${e.message}` : `Error in Product Detail component. Please try again.`;
        }

        console.error(`LWC ERROR (lwcDdOpportunityProductDetail) - ${errorString}`);
        
        this.componentErrorMsg = errorString
        this.showMainComponentError = true;
        this.showSpinner = false;
        this.dataLoaded = false;
        this.saving = false;
    }

    getErrorClassForField() {
        return FORM_ELEMENT_CLASS + ERROR_CLASS;
    }
}