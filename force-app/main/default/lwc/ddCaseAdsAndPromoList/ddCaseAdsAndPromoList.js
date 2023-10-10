import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import OPPORTUNITY_ID from '@salesforce/schema/Case.Opportunity_Name__c';
import RECORDTYPE_NAME from '@salesforce/schema/Case.RecordType.Name';
import getOrderItems from '@salesforce/apex/CDdCaseAdsAndPromoListController.getOrderItems';
import validateComponentVisibility from '@salesforce/apex/CDdCaseAdsAndPromoListController.validateComponentVisibility';
const columns =[
    {
        label: 'Name',
        fieldName: 'orderIdUrl',
        type: 'url',
        wrapText: true,
        typeAttributes: {
            label: { fieldName: 'ProductName' },
            target: '_blank',
            tooltip: {fieldName: 'ProductName'}
        },
        hideDefaultActions: true
    }, {
        label: 'Promo Start Date',
        fieldName: 'Promo_Start_Day__c',
        type: 'date',
        hideDefaultActions: true
    }, {
        label: 'Promo End Date',
        fieldName: 'Promo_End_Day__c',
        type: 'date',
        hideDefaultActions: true
    }
];
const showProductsMapKey = 'ShowProducts';
const mileStoneValidityCaseRecordTypes = ['Marketplace Onboarding'];
export default class DdCaseAdsAndPromoList extends LightningElement {
    @api recordId;
    
    orderItems;
    serviceError;
    opportunityid;
    recordTypeName;
    isLoaded = true;
    hasError = false;
    columns = columns;
    showProducts = false;

    @wire(getRecord, { recordId: '$recordId', fields: [OPPORTUNITY_ID, RECORDTYPE_NAME]})
    loadFields({error, data}){
        if(error){
            this.handleError(error);
        } else if(data){
            this.opportunityid = getFieldValue(data, OPPORTUNITY_ID);
            this.recordTypeName = getFieldValue(data, RECORDTYPE_NAME);
            this.determineVisiblity();
        }
    }

    /*@wire(validateComponentVisibility, {caseId:'$recordId'})
    validateVisibility({error, data}) {
        if(data){
            this.showProducts = data[showProductsMapKey];
            this.retrieveOrderItems();
        } else if(error){
            this.handleError(error);
        }
    }*/
    determineVisiblity(){
        if(mileStoneValidityCaseRecordTypes.includes(this.recordTypeName)){
            this.invokeValidateComponentVisibility();
        } else if(this.opportunityid){
            this.showProducts = true;
            this.retrieveOrderItems();
        }
    }
    invokeValidateComponentVisibility(){
        validateComponentVisibility({caseId: this.recordId})
        .then(result => {
            if(result[showProductsMapKey] && this.opportunityid){
                this.showProducts = true;
                this.retrieveOrderItems();
            }
        })
        .catch(error => {
            this.handleError(error);
        })
    }
    retrieveOrderItems(){
        this.isLoaded = false;
        getOrderItems({opportunityId: this.opportunityid})
        .then(result => {
            let tempData = [];
            result.forEach(record => {
                let tempRecord = Object.assign({}, record);
                tempRecord.ProductName = tempRecord.Product2.Name;
                tempRecord.orderIdUrl = '/' + tempRecord.Id;
                tempData.push(tempRecord);
            });
            this.orderItems = tempData;
            if(tempData.length == 0){
                this.showProducts = false;
            }
            this.isLoaded = true;
        })
        .catch(error => {
            this.handleError(error);
        })
    }

    handleError(error){
        this.hasError = true;
        this.isLoaded = true;
        this.serviceError = JSON.stringify(error);
        console.log('service-error', this.serviceError);
    }
}