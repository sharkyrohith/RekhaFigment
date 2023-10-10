/*
 * @author: Raju Lakshman
 * @date : October 2021
 * @description: Wrapper for Grid Report Filters.
 *               Depending on the type (definition.Type__c), value can be Boolean/Array of various other wrappers (multiselect / date / number)
 */
public without sharing class CDdGridReportFilterWrapper {
    public String name {get;set;}
    public DD_Grid_Report_Filter__mdt definition {get;set;}
    public Object value {get;set;}
}