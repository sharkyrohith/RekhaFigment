/**
 * @author   Raju Lakshman
 * @date  Sept 2021
 * @decription Controller for lwcDdGridReport Lightning Web Component
 *
 */

 public without sharing class CDdGridReportCtrl {

    public static final String ERROR_MSG = 'There was an error fetching the report data and the error has been logged. Please contact your system administrator for assistance.';

    /*****************************************************************************************************************************
     *
     * Public Methods
     *
     *****************************************************************************************************************************/
    /**
     * @author Raju Lakshman
     * @date  Sept 2021
     * @decription Returns the CMT with the Grid Report Detail
     * @param   {String} reportName - Developer name of DD_Grid_Report_Master__mdt
     * @return  DD_Grid_Report_Master__mdt
     */

    @AuraEnabled(cacheable=true)
    public static DD_Grid_Report_Master__mdt getReportDefinition(String reportName){
        List<DD_Grid_Report_Master__mdt> reports =
            [SELECT Id, Label, Apex_Class__c, DeveloperName,
                    (SELECT Id,
                            DeveloperName,
                            Type__c,
                            MultiSelect_Ref__c,
                            MultiSelect_Ref__r.DeveloperName,
                            MultiSelect_Ref__r.Field_Label__c,
                            Query_Field_API_Names__c,
                            Label__c,
                            Sequence__c,
                            isExpanded__c,
                            Toggle_Default__c,
                            MultiSelect_Query_Operator__c,
                            Toggle_Filter_Required__c,
                            Number_Date_Has_IS_BLANK_IS_NOT_BLANK__c
                       FROM DD_Grid_Report_Filters__r
                      WHERE isActive__c = true
                   ORDER BY Sequence__c asc),
                    (SELECT Id,
                            API_Name__c,
                            Cell_Attributes_JSON__c,
                            Default_Sort__c,
                            Default_Sort_Direction__c,
                            Field_Name__c,
                            Initial_Width__c,
                            isActive__c,
                            Label__c,
                            Sequence__c,
                            Sortable__c,
                            Type__c,
                            Type_Attributes_JSON__c,
                            Sort_Nulls_Config__c
                       FROM DD_Grid_Report_Fields__r
                      WHERE isActive__c = true
                   ORDER BY Sequence__c asc)
               FROM DD_Grid_Report_Master__mdt
              WHERE DeveloperName = :reportName];
        return reports.isEmpty() ? null : reports[0];
    }

    /**
     * @author Raju Lakshman
     * @date  Sept 2021
     * @decription Send a list of upto 50k record ids to the UI, UI can call later to get the actual data
     * @param   {String} apexClass - Name of the apex class implementing the CDdGridReportInterface, which will process the filter config and return the ids
     * @param   {String} filterConfig - JSON of the filter values and configuration
     * @return  List<Id>
     */
    @AuraEnabled
    public static CDdGridReportHelper.CDdGridReportRecordIdWrapper getRecordIds(String apexClass,String filterConfig,String sortConfig) {
        Type iType = null;
        CDdGridReportInterface iClass = null;
        CDdGridReportHelper.CDdGridReportRecordIdWrapper retVal = new CDdGridReportHelper.CDdGridReportRecordIdWrapper();

        if (String.isBlank(apexClass) || String.isBlank(filterConfig)) {
            return retVal;
        }

        CDdGridReportSortWrapper sortWrapper = String.isBlank(sortConfig) ?
            null : (CDdGridReportSortWrapper)JSON.deserialize(sortConfig, CDdGridReportSortWrapper.class);
        // Call the Apex class via the interface
        try {
            iType = Type.forName(apexClass);
        } catch (Exception e) {
            CDdErrorUtilities.publishException('Grid Report Framework','CDdGridReportCtrl',null,
                CDdErrorUtilities.getFormattedException('getRecordIds Type Not Found -- ClassName: ' + apexClass,e));
            throw new AuraHandledException(ERROR_MSG);
        }
        try {
            iClass = (CDdGridReportInterface) iType.newInstance();
            retVal = iClass.getRecordIds(CDdGridReportHelper.getFilterWrapper(filterConfig),sortWrapper);
        } catch (Exception e) {
            CDdErrorUtilities.publishException('Grid Report Framework','CDdGridReportCtrl',null,
                CDdErrorUtilities.getFormattedException('getRecordIdsFail -- ClassName: ' + apexClass + '\nFilter Config: ' + filterConfig + '\nSort Config: ' + sortConfig,e));
            throw new AuraHandledException(ERROR_MSG);
        }
        return retVal;
    }

    /**
     * @author Raju Lakshman
     * @date  Sept 2021
     * @decription Send a list of upto 50k record ids to the UI, UI can call later to get the actual data
     * @param   {String} apexClass - Name of the apex class implementing the CDdGridReportInterface, which will process the filter config and return the ids
     *          {List<Id>} recordIds - Ids to fetch data for
     * @return  {String} JSON string with data to return back to the Grid. The JSON string can be created from List<sObject>/List<Map<String,Object>>/List<Custom Wrapper>.
     */
    @AuraEnabled
    public static String getData(String apexClass,List<Id> recordIds) {
        Type iType = null;
        CDdGridReportInterface iClass = null;
        String retval = '[]';

        // Call the Apex class via the interface
        try {
            iType = Type.forName(apexClass);
        } catch (Exception e) {
            CDdErrorUtilities.publishException('Grid Report Framework','CDdGridReportCtrl',null,
                CDdErrorUtilities.getFormattedException('getData Type Not Found -- ClassName: ' + apexClass,e));
            throw new AuraHandledException(ERROR_MSG);
        }
        try {
            iClass = (CDdGridReportInterface) iType.newInstance();
            retVal = iClass.getData(recordIds);
        } catch (Exception e) {
            CDdErrorUtilities.publishException('Grid Report Framework','CDdGridReportCtrl',null,
                CDdErrorUtilities.getFormattedException('getData -- ClassName: ' + apexClass + '\nRecord Ids: ' + String.join(recordIds,CDdCoreConstants.DELIMITER_COMMA),e));
            throw new AuraHandledException(ERROR_MSG);
        }
        return retVal;
    }

    /**
     * @author Mahesh Chouhan
     * @date  Jan 2022
     * @decription Provides a list of DD Grid Report Saved Search for a particular DD Grid Report
     * @param   {String} reportName - Name of the DD Grid Report for which Saved Search records need to be retrieved
     * @return  List<DD_Grid_Report_Saved_Search__c> Returns a list of DD Grid Report Saved Search
     */
    @AuraEnabled(cacheable=true)
    public static List<DD_Grid_Report_Saved_Search__c> getDDGridReportSavedSearchForCurrentUser(String reportName){
        List<DD_Grid_Report_Saved_Search__c> ddGridReportSavedSearches = new List<DD_Grid_Report_Saved_Search__c>();
        ddGridReportSavedSearches = [SELECT ID,Name, Owner.Name, Report_Name__c, Type__c, Config__c 
                                        FROM DD_Grid_Report_Saved_Search__c
                                        WHERE OwnerId =: UserInfo.getUserId() AND Report_Name__c =: reportName];
        return ddGridReportSavedSearches;
    }
}