import { LightningElement, wire } from 'lwc';
import getNimdaFields from '@salesforce/apex/CDdNimdaByPassGroupHelper.getNimdaFields';

// Import custom labels
import fieldAccess from '@salesforce/label/c.DDS2N_BypassToolUplaoderInfo_FieldAccess_Label';
import generateButton from '@salesforce/label/c.DDS2N_BypassToolUplaoderInfo_Button_Label';
import invalidProfile from '@salesforce/label/c.DDS2N_BypassToolUplaoderInfo_InvalidProfile';
import requiredFields from '@salesforce/label/c.DDS2N_BypassToolUplaoderInfo_RequiredFields';
export default class LwcDdS2NBypassToolUploaderInfo extends LightningElement {
    @wire(getNimdaFields)
    availableFields;

    label = {
      fieldAccess, generateButton, invalidProfile, requiredFields
    };

    get modifiedAvailableFields() {
      let modifiedAvailableFields = [];
      modifiedAvailableFields = this.availableFields.data.map(x => {
        let xCopy = Object.assign({}, x);

        if (xCopy.property === 'id') {;
          xCopy.property = 'store_id';
        }
        return xCopy;
      });
      
      return modifiedAvailableFields;
    }

    get displayModifiedAvailableFields() {
      let modifiedAvailableFields = [];
      modifiedAvailableFields = this.availableFields.data.filter(field => {
        if (field.property === 'id') {
          return false;
        }
        return true;
      });
      
      return modifiedAvailableFields;
    }

    get hasAvailableFields() {
      if (this.availableFields.data) {
        return this.availableFields.data.length > 0;
      }
      return false;
    }

    handleClick() {
        const rows = this.getRows();

        let csvContent = rows.map(e => e.join(",")).join("\n");

        // Creating anchor element to download
        let downloadElement = document.createElement('a');

        // This  encodeURI encodes special characters, except: , / ? : @ & = + $ # (Use encodeURIComponent() to encode these characters).
        downloadElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(csvContent);
        downloadElement.target = '_self';
        // CSV File Name
        downloadElement.download = 'sample.csv';
        // below statement is required if you are using firefox browser
        document.body.appendChild(downloadElement);
        // click() Javascript function to download CSV file
        downloadElement.click(); 
    }

    getRows() {
      const rows = [[
        'accountid'
      ]];
      
      this.modifiedAvailableFields.forEach(e => {
        rows[0].push(e.property);
      });

      const priorityRows = {
        'store_id' : 1,
        'accountid' : 1,
      }
      
      for (let i=0; i < rows[0].length; i++) {
        if (priorityRows[rows[0][i]]) {
          let a = rows[0].splice(i,1);   // removes the item
          rows[0].unshift(a[0]); // add the item to the front
        }
      }

      return rows;
    }
}