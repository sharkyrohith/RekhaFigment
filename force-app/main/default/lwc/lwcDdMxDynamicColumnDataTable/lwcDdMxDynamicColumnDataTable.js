/**
 * @author Praveen Pandem
 * @date  07/15/2022
 *@Description:Dynamic data table component for equipment request screen.
 *Features: One of the column will displayed as URL.
 * Accepts the Columns and query from data table and custom metadata.
 */
/*****************************************************************************************************************************
 *
 * Imports
 *
 ***********/
import { LightningElement, track, wire, api } from 'lwc';
import getDynamicTableDataList from '@salesforce/apex/CDdMxDataTableController.GetTableColumnData';

export default class LwcDdMxDynamicColumnDataTable extends LightningElement {
   /*****************************************************************************************************************************
    *
    * Public Variables
    *
    *****************************************************************************************************************************/

   @track DataTableResponseWrappper;
   @track finalSObjectDataList;
   @api tableName;
   @api urlField;
   @api customFilterField;
   @api customFilterValue;
   @api hideCheckBox;
   @api messageForNoRows;
   tableTitle;
   @api isConsole;

   /*****************************************************************************************************************************
    *
    * Wires
    *
    *****************************************************************************************************************************/
   /**
    * Accepts the table name, record id and api name from parent component, fetch the details from apex controller and disply the table data in the UI
    *
    * @param recordId
    * @param fieldSetName
    */
   @wire(getDynamicTableDataList, {
      tableName: '$tableName',
      customFilterField: '$customFilterField',
      customFilterValue: '$customFilterValue',
   })
   wiredRecords({ error, data }) {
      if (data) {
         let sObjectRelatedFieldListValues = [];
         this.tableTitle = data.TableTitle;
         if (data.lstDataTableData.length === 0) {
            this.tableTitle = this.messageForNoRows;
         }
         for (let row of data.lstDataTableData) {
            const finalSobjectRow = {};
            let rowIndexes = Object.keys(row);
            rowIndexes.forEach((rowIndex) => {
               const relatedFieldValue = row[rowIndex];
               if (relatedFieldValue.constructor === Object) {
                  this._flattenTransformation(relatedFieldValue, finalSobjectRow, rowIndex);
               } else {
                  finalSobjectRow[rowIndex] = relatedFieldValue;
               }
            });
            sObjectRelatedFieldListValues.push(finalSobjectRow);
         }
         let nameUrl;
         this.finalSObjectDataList = sObjectRelatedFieldListValues.map((row) => {
            if (this.isConsole) {
               nameUrl = '/console?tsid=' + `/${row.Id}`;
            } else {
               nameUrl = window.location.origin + `/${row.Id}`;
            }
            return {
               ...row,
               nameUrl,
            };
         });

         this.DataTableResponseWrappper = data.lstDataTableColumns.map((e, index) => {
            if (index === 0) {
               e = {
                  ...e,
                  ...{
                     typeAttributes: {
                        label: {
                           fieldName: `${this.urlField}`,
                        },
                        target: '_blank',
                     },
                  },
               };
            }
            return e;
         });
      } else if (error) {
         this.error = error;
      }
   }
   _flattenTransformation = (fieldValue, finalSobjectRow, fieldName) => {
      let rowIndexes = Object.keys(fieldValue);
      rowIndexes.forEach((key) => {
         let finalKey = fieldName + '.' + key;
         finalSobjectRow[finalKey] = fieldValue[key];
      });
   };
   /*****************************************************************************************************************************
    *
    * Event Handlers
    *
    *****************************************************************************************************************************/

   getSelectedName(event) {
      const selectedRows = event.detail.selectedRows;
      for (let i = 0; i < selectedRows.length; i++) {}
   }
}