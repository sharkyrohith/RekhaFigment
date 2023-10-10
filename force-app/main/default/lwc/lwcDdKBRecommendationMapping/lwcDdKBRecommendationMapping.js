import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getKBRecommendation from '@salesforce/apex/CDdKBRecommendationMappingController.getKBRecommendation';
import updateKBRecommendation from '@salesforce/apex/CDdKBRecommendationMappingController.updateKBRecommendation';
import createKBRecommendation from '@salesforce/apex/CDdKBRecommendationMappingController.createKBRecommendation';
import deleteKBRecommendation from '@salesforce/apex/CDdKBRecommendationMappingController.deleteKBRecommendation';

const columns = [
    {   label: 'Name', 
        fieldName: 'Name',
        sortable: "true", 
        editable: true 
    },
    {   label: 'Category', 
        fieldName: 'Case_Category__c',
        sortable: "true", 
        editable: true 
    },
    {   label: 'Subcategory', 
        fieldName: 'Case_Sub_Category__c', 
        sortable: "true", 
        editable: true
    },
    {   label: 'Customer Type', 
        fieldName: 'Customer_Type__c', 
        sortable: "true", 
        editable: true
    },
    {   label: 'Recommended KB Article ID', 
        fieldName: 'Recommended_KB_Article__c', 
        sortable: "true", 
        editable: true
    },
    {type: "button", typeAttributes: {  
        label: 'Delete',  
        name: 'Delete',  
        title: 'Delete',  
        disabled: false,  
        value: 'delete',  
        iconPosition: 'left'  
    }},  
];
export default class LwcDdKBRecommendationMapping extends LightningElement {
    @track kbRecommendationList;
    @track columns = columns;
    @track sortBy;
    @track sortDirection;
    @track name;
    @track category;
    @track subcategory; 
    @track customerType;
    @track articleId;
    @track isModalOpen = false;
    @track error;

    @wire(getKBRecommendation)
    KBRecommendations(result) {
        if (result.data) {
            this.kbRecommendationList = result.data;
            this.error = undefined;

        } else if (result.error) {
            this.error = result.error;
            this.kbRecommendationList = undefined;
        }
    }

    handleSortdata(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(event.detail.fieldName, event.detail.sortDirection);
    }

    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.kbRecommendationList));

        let keyValue = (a) => {
            return a[fieldname];
        };
 
        let isReverse = direction === 'asc' ? 1: -1;

        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';

            return isReverse * ((x > y) - (y > x));
        });

        this.kbRecommendationList = parseData;
    }

    openModal() {
        this.isModalOpen = true;
    }
    closeModal() {
        this.isModalOpen = false;
    }

    handleTextChange(evt){
        if (evt.target.id.startsWith("name")){
            this.name = evt.target.value;
        } else if (evt.target.id.startsWith("category")){
            this.category = evt.target.value;
        } else if (evt.target.id.startsWith("subcategory")){
            this.subcategory = evt.target.value;
        } else if (evt.target.id.startsWith("customerType")){
            this.customerType = evt.target.value;
        } else if (evt.target.id.startsWith("articleId")){
            this.articleId = evt.target.value;
        }
    }

    handleSave(event) {
        updateKBRecommendation({ changedRows : event.detail.draftValues})
            .then(result => {
                window.location.reload(true);
            })
            .catch(error => {
                const evt = new ShowToastEvent({
                    title: 'Error',
                    message: error.body.message,
                    variant: 'error'
                });
                this.dispatchEvent(evt);
            });
        ;
    }

    callRowAction(event) {
        const recId =  event.detail.row.Id;  
        const actionName = event.detail.action.name;  
        if ( actionName === 'Delete' ) {  
            deleteKBRecommendation({ mappingId : recId})
                .then(result => {
                    window.location.reload(true);
                })
                .catch(error => {
                    const evt = new ShowToastEvent({
                        title: 'Error',
                        message: error.body.message,
                        variant: 'error'
                    });
                    this.dispatchEvent(evt);
                });
        }
    }

    handleKBRecCreate(event) {
        createKBRecommendation({name: this.name,
                                category: this.category,
                                subcategory: this.subcategory,
                                customerType: this.customerType,
                                recommendedKBArticleId: this.articleId})
            .then(result => {
                window.location.reload(true);
            })
            .catch(error => {
                const evt = new ShowToastEvent({
                    title: 'Error',
                    message: error.body.message,
                    variant: 'error'
                });
                this.dispatchEvent(evt);
            });
        ;
    }
}