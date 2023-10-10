import { LightningElement, api, wire, track } from 'lwc';
import getAllRecords from '@salesforce/apex/CDdOpportunityProductRelListViewClass.getAllRecords';
import { NavigationMixin } from "lightning/navigation";


const COLS = [
    { label: 'Product', fieldName: 'prodName', type:'url', typeAttributes: {label: { fieldName: 'Product_Name__c' }, target: '_self'}, editable: false },
    { label: 'Order Service Type', fieldName: 'Order_Service_Type__c', sortable: true,
    cellAttributes: { alignment: 'left' }, editable: false },
    { label: 'Target Cx Audience', fieldName: 'Target_Cx_Audience__c', sortable: true,
    cellAttributes: { alignment: 'left' }, editable: false },
    { label: 'Marketing Flat Fee', fieldName: 'Marketing_Flat_Fee__c', sortable: true,
    cellAttributes: { alignment: 'left' }, editable: false },
    { label: 'Order Cart Minimum', fieldName: 'Order_Cart_Minimum__c', sortable: true,
    type: 'currency', cellAttributes: { alignment: 'left' }, editable: false },
    { label: 'Flat Discount Amount for Consumer', fieldName: 'Flat_Discount_Amount_for_Consumer__c', sortable: true,
    type: 'currency', cellAttributes: { alignment: 'left' }, editable: false },
    { label: 'Discount Percentage for Consumer', fieldName: 'Discount_Percentage__c', sortable: true,
    type: 'percent', typeAtrributes: {step: '0.01', maximumFractionDigits: '2'}, cellAttributes: { alignment: 'left' }, editable: false },
    { label: 'Quote Line', fieldName: 'quoteLine', type:'url', typeAttributes: {label: { fieldName: 'quotelineName' }, target: '_self'}, sortable: true,
    cellAttributes: { alignment: 'left' }, editable: false}

]
export default class Testlwc extends NavigationMixin(LightningElement) {
    @api recordId;
    @api oppName;
    columns = COLS;
    relatedFieldApiName = 'OpportunityLineItems';
    sobjectApiName = 'OpportunityLineItem';
    iconName = 'standard:product';
    sortedBy;
    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    
    @track data;
    @track error;

    _wiredResult;
    numOfItems;

    handleNavigateToOppRecordPage(event){
        event.preventDefault();
        window.location.href = '/lightning/r/' + this.recordId + '/view';
    }
    handleNavigateToOppListView(event){
        event.preventDefault();
        window.location.href = '/lightning/o/Opportunity/home';
    }

    handleGotoRelatedList() {
        this[NavigationMixin.Navigate]({
            type: "standard__recordRelationshipPage",
            attributes: {
                recordId: this.recordId,
                relationshipApiName: this.relatedFieldApiName,
                actionName: "view",
                objectApiName: this.sobjectApiName
            }
        });
    }

    @wire(getAllRecords, { oppId: '$recordId' })
    wiredOppportunityProductsAll ({ error, data }){
        if(data){
            let tempDataList = [];
            this._wiredResult = data;
            this.numOfItems = data.length;
            data.forEach((record) => {
                let tempRec = Object.assign({}, record);
                tempRec.prodName = '/' + tempRec.Id;
                tempRec.quoteLine = '/'+ tempRec.SBQQ__QuoteLine__c;
                tempRec.quotelineName  = tempRec.SBQQ__QuoteLine__r.Name;
                tempDataList.push(tempRec);
                this.oppName = tempRec.Opportunity.Opportunity_Name_External_Use__c;
            });
            this.data = tempDataList;
            this.error = undefined;
        } else if(error){
            this.error = error;
        }
    };

    handleSort(event){
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.data];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.data = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }
    
    sortBy(field, reverse, primer){
        const key = primer
            ? function(x){
                return primer(x[field]);
            }
            : function(x){
                return x[field];
            };
        
        return function(a, b){
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    }
}