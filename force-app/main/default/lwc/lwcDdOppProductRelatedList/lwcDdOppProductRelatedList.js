import { LightningElement, api, wire, track } from 'lwc';
import getLimitRecords from '@salesforce/apex/CDdOpportunityProductRelListViewClass.getLimitRecords';
import getAllRecords from '@salesforce/apex/CDdOpportunityProductRelListViewClass.getAllRecords';
import { NavigationMixin } from "lightning/navigation";

const COLS = [
    { label: 'Product', fieldName: 'Name', editable: false, typeAttributes: {label: { fieldName: 'Name' }, target: '_self'} },
    { label: 'Order Service Type', fieldName: 'Order_Service_Type__c', sortable: true,
    cellAttributes: { alignment: 'left' }, editable: false },
    { label: 'Target Cx Audience', fieldName: 'Target_Cx_Audience__c', sortable: true,
    cellAttributes: { alignment: 'left' }, editable: false },
    { label: 'Marketing Flat Fee', fieldName: 'Marketing_Flat_Fee__c', sortable: true,
    cellAttributes: { alignment: 'left' }, editable: false }
]

export default class LwcDdOppProductRelatedList extends NavigationMixin(LightningElement) {
    @api recordId;
    columns = COLS;
    relatedFieldApiName = 'OpportunityLineItems';
    sobjectApiName = 'OpportunityLineItem';
    iconName = 'standard:product';
    moreData = false;
    @track dataThere = false;
    @track data;
    @track error;

    handleGotoRelatedList() {
        this[NavigationMixin.Navigate]({
            type: "standard__component",
            attributes: {
                // recordId: this.recordId,
                // relationshipApiName: this.relatedFieldApiName,
                // actionName: "view",
                // objectApiName: this.sobjectApiName
                componentName: "c__LCDdOppProductRelatedListNavigate"
            },
            state: {
                c__recordId: this.recordId
            }
        });
    }

    handleGotoRecordPage(event){
        let strIndex = event.target.dataset.recordId;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: strIndex,
                objectApiName: this.sobjectApiName,
                actionName: 'view'
            }
        });
    }

    @wire(getLimitRecords, { oppId: '$recordId' })
    wiredOppportunityProducts({error, data}){
        if(data){
            this.data = data;
            if(data.length > 0){
                this.dataThere = true;
            }else{
                this.dataThere = false;
            }
            this.error = undefined;
        }else if(error){
            this.error = error;
        }
    };

    @wire(getAllRecords, { oppId: '$recordId' })
    wiredOppportunityProductsAll;
}