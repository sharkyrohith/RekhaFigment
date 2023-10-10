import { LightningElement } from 'lwc';

const columns = [
    { label: 'MXP Name', fieldName: 'MXPName', apiName: 'MXPName' },
    { label: 'Account Name', fieldName: 'AccountUrl', apiName: 'Account.Name', type: 'url', typeAttributes: {label: { fieldName: 'AccountName' }, target: '_blank'}},
    { label: 'Case Number', fieldName: 'CaseUrl', apiName: 'CaseNumber', type: 'url', typeAttributes: {label: { fieldName: 'CaseNumber' }, target: '_blank'} },
    { label: 'Business Id', fieldName: 'AccountBusiness_ID__c', apiName: 'Account.Business_ID__c' },
    { label: 'Case Owner', fieldName: 'OwnerName', apiName: 'Owner.Name' },
    { label: 'Created Date', fieldName: 'CreatedDate', apiName: 'CreatedDate', type: 'date' },
    { label: 'Last Modified Date', fieldName: 'LastModifiedDate', apiName: 'LastModifiedDate', type: 'date' },
    { label: 'Status', fieldName: 'Status', apiName: 'Status' },
    { label: 'Subject', fieldName: 'Subject', apiName: 'Subject' }
];

export default class LwcDdMxpCaseReporting extends LightningElement {
    columns = columns;
}