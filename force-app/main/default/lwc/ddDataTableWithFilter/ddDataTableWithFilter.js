/*****************************************************************************************************************************
*
* Imports
*
*****************************************************************************************************************************/
import { LightningElement,api,track} from 'lwc';
import { cloneObject } from 'c/lwcDdUtils';

export default class DdDataTableWithFilter extends LightningElement {
     /*****************************************************************************************************************************
    *
    * Public Variables
    *
    *****************************************************************************************************************************/
    @api initialRecList = [];
    @api currentRecList =[];
    @api uniqueIdentifier;
    @api tableColumns;
    @api kFieldName;
    @api filterFieldLabel;
    @api filterHolderLabel;
    @api hideCheckBoxColumn;
    @api columnWidthMode;
    @api showFilterBox;
    @api selectedRecords= [];
    @api selectedRecordObjects= [];
    @track allSelectedRecords = new Set();
    @track allSelectedRecordObjects = new Set();
    @track isSearchUsed = false;
    @track searchSelectedRecords = new Set();
    @track regularSelectedRecords = new Set();
    /*****************************************************************************************************************************
    *
    * Event Handlers
    *
    *****************************************************************************************************************************/
    //filter table
    filterTableValues(event) {
        this.isSearchUsed = true;
        const searchKey = event.target.value.toLowerCase();
        if (searchKey) {
            this.currentRecList = this.initialRecList;

            if (this.currentRecList) {
                let searchRecords = [];

                for (let record of this.currentRecList) {
                    let valuesArray = Object.values(record);
                    for (let val of valuesArray) {
                        let strVal = String(val);

                        if (strVal) {

                            if (strVal.toLowerCase().includes(searchKey)) {
                                searchRecords.push(record);
                                break;
                            }
                        }
                    }
                }
                this.currentRecList = searchRecords;
            }
        } else {
            this.currentRecList = this.initialRecList;
            this.isSearchUsed = false;
        }
        this.selectedRecords = [...this.allSelectedRecords];
        this.selectedRecordObjects = [...this.allSelectedRecordObjects];
        this.notifyParent();
    }

    //Row selection event handler
    handleRowSelection(event){
        try{
            const selectedRows = event.detail.selectedRows;
            if(this.isSearchUsed){
                this.searchSelectedRecords = new Set();
                for (let currentItem of selectedRows) {
                    this.searchSelectedRecords.add(currentItem);
                }
            }else{
                this.regularSelectedRecords =new Set();
                for (let currentItem of selectedRows) {
                    this.regularSelectedRecords.add(currentItem);
                }
            }
            this.getFinalList();
        }catch(e){
            console.log('exception is===>'+e);
        }
        this.notifyParent();
    }

    /*****************************************************************************************************************************
    *
    * Logic / Helper methods
    *
    *****************************************************************************************************************************/
     /**
    * @decription Notifies parent of change
    * @param   None
    * @return  None
    */
     notifyParent() {
        const evt = new CustomEvent("change",{
            detail: {
                uniqueIdentifier:'tablechange',
                isRecordSelected : this.allSelectedRecords.size > 0
            }
        });
        this.dispatchEvent(evt);
    }

    /**
    * @decription creates the final list for all selected records
    * @param   None
    * @return  None
    */
    getFinalList(){
        this.selectedRecords =[];
        this.selectedRecordObjects = [];
        this.allSelectedRecords = new Set();
        this.allSelectedRecordObjects = new Set();
        for (let currentItem of this.searchSelectedRecords) {
            this.allSelectedRecords.add(currentItem[this.kFieldName]);
            this.allSelectedRecordObjects.add(currentItem);
        }
        for (let currentItem of this.regularSelectedRecords) {
            this.allSelectedRecords.add(currentItem[this.kFieldName]);
            this.allSelectedRecordObjects.add(currentItem);
        }
        this.searchSelectedRecords = new Set();
        this.selectedRecords = [...this.allSelectedRecords];
        this.selectedRecordObjects = [...this.allSelectedRecordObjects];
    }
}