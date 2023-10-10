/**
 * @author Raju Lakshman
 * @date   Sep 16, 2021
 * @decription Interface to implement to send data to the UI
 */
public interface CDdGridReportInterface {
    /**
     * @author Raju Lakshman
     * @date   Sept 16, 2021
     * @decription  Gets upto 50K records which match the query
     * @param   String filterConfig - JSON of filters
     * @param  CDdGridReportSortWrapper sortConfig - Sort Field and Sort Direction
     * @return  CDdGridReportRecordIdWrapper Wrapper of list of Ids the UI can store and use lazy loading to render
     */
    CDdGridReportHelper.CDdGridReportRecordIdWrapper getRecordIds(List<CDdGridReportFilterWrapper> filterList,CDdGridReportSortWrapper sortConfig);

    /**
     * @author Raju Lakshman
     * @date   Sept 16, 2021
     * @decription  Gets the data for the recordIds
     * @param  List<Id> recordIds - List of ids for which data needs to be retrieved
     * @return String data - JSON form of the data to be returned
     */
    String getData(List<Id> recordIds);
}