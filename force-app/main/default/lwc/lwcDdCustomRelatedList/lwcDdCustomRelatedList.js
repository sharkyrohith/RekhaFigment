/**
 * @description:  BZAP-12416 A dynamic component to put on a flexipage as a custom related list view (not on a page layout section) without edit or delete row actions.  
 * Define which columns/fields to display for the object based on custom metadata records.
 *
 * 
 */
import { LightningElement, api, track } from 'lwc';
import getAllRecords from '@salesforce/apex/CDdCustomRelatedListCtrl.getAllRecords';
import getFields from '@salesforce/apex/CDdCustomRelatedListCtrl.getFields';
import getPluralLabel from '@salesforce/apex/CDdCustomRelatedListCtrl.getPluralLabel';
import viewAllLabel from '@salesforce/label/c.Custom_Related_List_View_All';
import viewLessLabel from '@salesforce/label/c.Custom_Related_List_View_Less';

export default class LwcDdCustomRelatedList extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api parentFieldName;
    @api childRelationshipObject;
    @api numRowsVisible;
    @api iconName;
    @api orderBy;
    @track columns = [];
    totalRecords;
    allRecords;
    visibleRecords;   
    fields = [];
    urlFields = [];
    percentFields = [];
    baseURL;
    hasData = false;
    relatedListLabel;
    viewLabel;
    viewMore = true;
    working = false;

    connectedCallback(){
        this.baseURL = window.location.origin;
        this.getData();
        
    }

    getData(){
        this.working = true;
        this.visibleRecords = [];
        this.totalRecords = 0;
        this.fields = [];
        this.urlFields = [];
        this.percentFields = [];
        this.viewLabel = '';
        getFields({childObject: this.childRelationshipObject})
            .then(fields =>{
                this.fields = fields;                
                //Build dynamic columns and assign to columns object
                this.buildDynamicColumns();
                //Get related records
                const queryFieldSet = this.getQueryFields();
                getAllRecords({ recordId: this.recordId, 
                    parentFieldName: this.parentFieldName, 
                    childObjectName: this.childRelationshipObject, 
                    fields: Array.from(queryFieldSet),
                    orderByField: this.orderBy
                })
                .then(records =>{                    
                    this.totalRecords = records.length;
                    this.allRecords = records;
                    records.forEach(record => {                        
                        //format percent fields to correct scale
                        if(this.percentFields){
                            this.percentFields.forEach(percentField =>{
                                record[percentField] = record[percentField]/100;
                            })
                        }
                        //build dynamic url
                        let urlIndex = 1;
                        if(this.urlFields){
                            this.urlFields.forEach(urlField =>{
                                //dynamically build a url based on field mappings and put it into a new prop stored on the record
                                //The column in the lightning-datatable references a dynamically created field called URL1, URL2, etc.. 
                                record['URL' + urlIndex] = this.baseURL + '/lightning/r/' + record[urlField] + '/view'; 
                                urlIndex ++;
                            });                            
                        };                        
                    });              
                    //Get object schema information for display
                    getPluralLabel({childObjectName: this.childRelationshipObject})
                    .then( pluralLabel => {
                        this.relatedListLabel = pluralLabel;
                         //If the number of records available is less than what was defined to display update the label and show all records
                        if(this.numRowsVisible >= this.totalRecords){
                            this.visibleRecords = this.allRecords;
                            this.relatedListLabel += ' (' + this.totalRecords + ')';
                        } else {
                            //If the number of records available is more than what was defined to display update the label and show only the specified amount of records
                            this.visibleRecords = this.allRecords.slice(0, this.numRowsVisible);
                            this.relatedListLabel += ' (' + this.numRowsVisible + '+)';
                        }
                    });
                    this.viewLabel = viewAllLabel + ' (' + this.allRecords.length + ')';
                    this.hasData = true;
                });
            });  
        this.working = false;
    }
    /**
     * @description: Based on the metadata mappings for each field to display build the lightning-datatable columns to the correct type
     */
    buildDynamicColumns(){
        let columns = [];
        let urlCount = 1;
        this.fields.forEach(field =>{
            //Define base props of the column
            let column = {
                label: field.MasterLabel, 
                fieldName: field.Field_Name__c, 
                editable: false, 
                hideDefaultActions: true,
                cellAttributes: { alignment: 'left' }
            }
            //define dynamic props based on the type defined in the metadata field mapping
            switch(field.LWC_Data_Table_Type__c) {
                case 'boolean':
                    column['type'] = 'boolean';
                    break;
                case 'currency':
                    column['type'] = 'currency';
                    column['typeAttributes'] = { 
                        currencyCode: { fieldName: 'CurrencyIsoCode' }, 
                        currencyDisplayAs: "code"
                    };
                    break;
                case 'date':
                    column['type'] = 'date';
                    column['typeAttributes'] = { 
                        year: 'numeric',
                        month: 'numeric',
                        day: 'numeric'
                    }
                    if(field.Show_Date_Time__c){
                        column['typeAttributes'].hour = '2-digit';
                        column['typeAttributes'].minute = '2-digit';
                        column['typeAttributes'].second = '2-digit';
                    }
                    break;
                case 'decimal':
                    column['type'] = 'decimal';
                    column['typeAttributes'] = { 
                        minimumFractionDigits: field.Decimal_Places__c,
                        maximumFractionDigits: field.Decimal_Places__c
                    };
                    break;
                case 'number':
                    column['type'] = 'number';
                    column['typeAttributes'] = { 
                        minimumFractionDigits: field.Decimal_Places__c,
                        maximumFractionDigits: field.Decimal_Places__c
                    };
                    break;
                case 'percent':
                    column['type'] = 'percent';
                    column['typeAttributes'] = {
                        step: '0.01',
                        minimumFractionDigits: field.Decimal_Places__c,
                        maximumFractionDigits: field.Decimal_Places__c
                    };
                    this.percentFields.push(field.Field_Name__c);
                    break;                    
                case 'text':
                  column['type'] = 'text';
                  break;                
                case 'url':
                    column['type'] = 'url';
                    //Use a dynamically generated prop to get the url on the record
                    column['fieldName'] = 'URL' + urlCount;
                    column['typeAttributes'] = {
                        //pass a field name to use it as the label for the URL 
                        label: { fieldName: field.URL_Display_Field__c},
                        target: '_blank' 
                    };
                    //Store the field name to use later when building the dynamic urls for each record
                    this.urlFields.push(field.URL_Id__c);
                    urlCount ++;                    
                    break;
                default:
                    column['type'] = 'text';
              }
            columns.push(column);
        });
        this.columns = columns;
    }

    toggleRecordView(){
        if(this.viewMore){
            this.visibleRecords = this.allRecords;
            this.viewLabel = viewLessLabel;
            this.viewMore = false;
        } else {
            this.visibleRecords = this.allRecords.slice(0, this.numRowsVisible);
            this.viewLabel = viewAllLabel + ' (' + this.allRecords.length + ')';
            this.viewMore = true;
        }
    }

    getQueryFields(){
        const queryFieldSet = new Set();
        this.fields.forEach(field => {
            if(field.Field_Name__c){
                queryFieldSet.add(field.Field_Name__c);
            }
            if(field.URL_Display_Field__c){
                queryFieldSet.add(field.URL_Display_Field__c);
            }
            if(field.URL_Id__c){
                queryFieldSet.add(field.URL_Id__c);
            }
        });
        return queryFieldSet;
    }
}