/**
 * @author Raju Lakshman
 * @date Oct 2021
 * @decription Custom Datatable component which extends ootb datatable with custom cell renderers.
 *             https://developer.salesforce.com/docs/component-library/documentation/en/lwc/lwc.data_table_custom_types
 *             Note: the template.html file should exist in the same folder as this component.
 */
/*****************************************************************************************************************************
*
* Imports
*
*****************************************************************************************************************************/
import LightningDatatable from 'lightning/datatable';
import ddDatatableRecordUrlTemplate from './ddDatatableRecordUrlTemplate.html';

export default class DdDatatable extends LightningDatatable {
    static customTypes = {
        // Displays a custom <a> tag in the UI via the ddDatatableRecordUrl component.
        recordUrl : {
            template: ddDatatableRecordUrlTemplate,
            typeAttributes:['navigateToId','displayValue','openMode','quickViewFieldSetName']
        }
    };
}