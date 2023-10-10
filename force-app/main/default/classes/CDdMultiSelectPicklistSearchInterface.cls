/**
 * @author Raju Lakshman
 * @date   Sep 16, 2021
 * @decription Interface to implement 'Custom search' type of lwcDdMultiSelectPicklist LWC component
 *             Refer to CDdMultiSelectPicklistCustomExample to see how to implement this interface.
 */
public interface CDdMultiSelectPicklistSearchInterface {
    /**
     * @author Raju Lakshman
     * @date   Sept 16, 2021
     * @decription Accepts Arguments etc, and has custom code to return data back to the UI
     * @param   String searchKeyword - Word to use as a search param
     *          DD_Multi_Select_Picklist_Master__mdt sInfo - Driving CMT which has the config for the search
     *          Set<String> excludeItemsSet - This has list of already selected records in the UI, so that it can be ignored for current search
     *          Map<String, Object> args - Has Arguments passed by the UI for dynamic queries, etc.
     * @return  List<CDdMultiSelectPicklistWrapper> - Resultant Data
     */
    List<CDdMultiSelectPicklistWrapper> getData(String searchKeyword,
        DD_Multi_Select_Picklist_Master__mdt sInfo,
        Set<String> excludeItemsSet,Map<String, Object> args);
}