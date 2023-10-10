import { LightningElement, api } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import getCase from "@salesforce/apex/CDdCaseLightningComponentCtrl.getSiblingCase";

const STATUS_FIELD_CLASS = "status-field ";

export default class LwcDdStorefrontAndMarketplaceCaseView extends NavigationMixin(LightningElement) {
    @api recordId;
    siblingCase;
    cardTitle;
    caseStatus = "N/A";

    componentLoaded = false;
    hasError = false;
    gridClosed = true;
    statusClass = STATUS_FIELD_CLASS; 

    // DATA TABLE
    milestoneTableColumns = [      
        { label: "Milestone", fieldName: "Milestone_Type__c" },
        { label: "Status", fieldName: "Status__c", type: "text" },
    ];

    connectedCallback() {
        this.loadData();
    }

    loadData() {
        getCase({ caseId : this.recordId })
            .then((result) => {
                this.siblingCase = result;
                this.cardTitle = `${this.siblingCase.caseTypeToShow} Onboarding Case`;
                this.setStatusClass();
                this.componentLoaded = true;
            })
            .catch((error) => {
                this.cardTitle = "Related Case Details"; // default title
                this.componentLoaded = true;

                const LOADING_ERROR = "Error loading Product Details";
                this.errorMessage = LOADING_ERROR;

                this.showError(error, LOADING_ERROR);
            })
    }

    setStatusClass() {
        if(this.siblingCase && this.siblingCase.caseToDisplay && this.siblingCase.caseToDisplay.Status) {
            this.caseStatus = this.siblingCase.caseToDisplay.Status;

            const upperCaseStatus = this.caseStatus.toUpperCase();

            this.statusClass += `${STATUS_FIELD_CLASS} status-field-`;

            if(["OPEN", "IN PROGRESS", "REOPENED", "CLOSED"].includes(upperCaseStatus)) {
                this.statusClass += "green";
            } else if(["BLOCKED", "DEAD"].includes(upperCaseStatus)) {
                this.statusClass += "red";
            } else if(["ESCALATED"].includes(upperCaseStatus)) {
                this.statusClass += "orange";
            } else {
                this.statusClass += "black";
            }
        }
    }

    navigateToRecord(e) {
        e.preventDefault();

        if(this.siblingCase && this.siblingCase.caseToDisplay) {
            this[NavigationMixin.Navigate]({
                type: "standard__recordPage",
                attributes: {
                    recordId: this.siblingCase.caseToDisplay.Id,
                    objectApiName: "Case",
                    actionName: "view"
                }
            });
        }
    }
    
    toggleMilestonesGrid(e) {
        this.gridClosed = !this.gridClosed;
    }

    showError(error) {
        this.hasError = true;

        if(error && error.body) {
            const { message } = error.body;
            console.error(`LWC Error in lwcDdStorefrontAndMarketplaceCaseView: ${message}`);
        } else {
            console.error("LWC Error in lwcDdStorefrontAndMarketplaceCaseView");
        }
    }
}