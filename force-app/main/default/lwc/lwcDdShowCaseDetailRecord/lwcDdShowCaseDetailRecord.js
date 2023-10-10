import { LightningElement,api } from 'lwc';
import  getCaseDetailFieldSet from '@salesforce/apex/CDdShowCaseDetailRecord.getCaseDetailFieldSet';
import { BLANK_STRING } from 'c/lwcDdConst';

export default class LwcDdShowCaseDetailRecord extends LightningElement {

/*****************************************************************************************************************************
 *
 * Public Variables
 *
*****************************************************************************************************************************/
    // {Object[]} - input fieldset for that object
    @api columns = 2;
    // {String} - Record Id for that object
    @api recordId;

/*****************************************************************************************************************************
*
* Private Variables
*
*****************************************************************************************************************************/
    caseDetailRecordId = BLANK_STRING;
    fieldSet = BLANK_STRING;
    sectionName = BLANK_STRING;

/*****************************************************************************************************************************
*
* Lifecycle hooks
*
*****************************************************************************************************************************/
    connectedCallback() {
       this.getRecordData();
    }

/*****************************************************************************************************************************
*
* Helper Methods
*
*****************************************************************************************************************************/
   /**
   * @decription Calls the server to get the record id & Field Set Name
   * @param   None
   * @return  None
   */
   getRecordData(){
       getCaseDetailFieldSet({recordId : this.recordId})
           .then(results => {
                if(results){
                    this.caseDetailRecordId = results.recordId;
                    this.fieldSet = results.fieldSetname;
                    this.sectionName = results.sectionName;
                }
           })
           .catch(error => {
               console.error(error);
           })
   }
}